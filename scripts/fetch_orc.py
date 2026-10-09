#!/usr/bin/env python3
"""Fetch Lake Hāwea level and Hāwea River flow from ORC and maintain daily CSVs.

The ORC AQUARIUS WebPortal serves chart data as JSON from /Data/Dataset_Chart,
thinned to ~2000 points per request. One calendar year per request gives roughly
five points a day, which we average into one value per NZ date.

Usage:
  fetch_orc.py              # refresh the current and previous year; backfill any missing file
  fetch_orc.py --backfill   # rebuild every series from the start of its record
"""
import argparse
import csv
import datetime as dt
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict

BASE = "https://envdata.orc.govt.nz/AQWebPortal"
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
# name: (dataset id, first year, output file, value column)
SERIES = {
    # Lake Level.Telemetry@EM507, Lake Hawea at Dam
    "level": ("252849", 1930, "hawea_daily.csv", "level_m"),
    # Discharge.Hydrotel.NIWA@EM218, Hawea River at Camphill Bridge
    "flow": ("148023", 1968, "hawea_flow_daily.csv", "flow_m3s"),
}
HEADERS = {
    "User-Agent": "lake-hawea-levels (https://github.com/rhysemt/lake-hawea-levels)",
    "Cookie": "disclaimer=accepted",
    "X-Requested-With": "XMLHttpRequest",
}


def fetch_year(dataset_id, year):
    """Return {date: [values]} for one calendar year (NZST)."""
    body = urllib.parse.urlencode({
        "dataset": dataset_id,
        "interval": "Custom",
        "date": f"{year}-01-01",
        "endDate": f"{year + 1}-01-01",
        "alldata": "false",
        "timezone": "720",
        "calendar": "CALENDARYEAR",
    }).encode()
    req = urllib.request.Request(f"{BASE}/Data/Dataset_Chart", data=body, headers=HEADERS)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                payload = json.load(r)
            break
        except Exception as e:  # network blips: retry with backoff
            if attempt == 3:
                raise
            print(f"  {year}: {e}; retrying", file=sys.stderr)
            time.sleep(2 ** (attempt + 1))
    days = defaultdict(list)
    for series in payload.get("Series") or []:
        for p in series.get("Data") or []:
            v = p.get("Value")
            # Times are already NZST despite the trailing Z.
            d = p["Time"][:10]
            if v is not None and d.startswith(str(year)):
                days[d].append(float(v))
    return days


def load(path, col):
    if not os.path.exists(path):
        return {}
    with open(path, newline="") as f:
        return {r["date"]: r[col] for r in csv.DictReader(f)}


def save(path, col, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", col])
        for d in sorted(rows):
            w.writerow([d, rows[d]])


def update(name, backfill, now):
    dataset_id, first_year, filename, col = SERIES[name]
    path = os.path.join(DATA_DIR, filename)
    backfill = backfill or not os.path.exists(path)
    years = range(first_year, now.year + 1) if backfill else range(now.year - 1, now.year + 1)
    rows = {} if backfill else load(path, col)
    for y in years:
        days = fetch_year(dataset_id, y)
        for d, vals in days.items():
            rows[d] = f"{sum(vals) / len(vals):.3f}"
        print(f"{name} {y}: {len(days)} days")
        time.sleep(1)  # be polite to ORC
    if not rows:
        sys.exit(f"{name}: no data fetched")
    save(path, col, rows)
    last = max(rows)
    print(f"{name}: saved {len(rows)} days, latest {last} = {rows[last]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--backfill", action="store_true")
    args = ap.parse_args()
    now = dt.datetime.now(dt.timezone(dt.timedelta(hours=12)))
    for name in SERIES:
        update(name, args.backfill, now)


if __name__ == "__main__":
    main()
