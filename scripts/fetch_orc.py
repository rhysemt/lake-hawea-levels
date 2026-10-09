#!/usr/bin/env python3
"""Fetch Lake Hāwea level (ORC site EM507) and maintain data/hawea_daily.csv.

The ORC AQUARIUS WebPortal serves chart data as JSON from /Data/Dataset_Chart,
thinned to ~2000 points per request. One calendar year per request gives roughly
five points a day, which we average into one value per NZ date.

Usage:
  fetch_orc.py              # refresh the current and previous year
  fetch_orc.py --backfill   # rebuild from the start of the record (1930)
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
DATASET_ID = "252849"  # Lake Level.Telemetry@EM507 (Lake Hawea at Dam)
FIRST_YEAR = 1930
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "hawea_daily.csv")
HEADERS = {
    "User-Agent": "lake-hawea-levels (https://github.com/rhysemt/lake-hawea-levels)",
    "Cookie": "disclaimer=accepted",
    "X-Requested-With": "XMLHttpRequest",
}


def fetch_year(year):
    """Return {date: [values]} for one calendar year (NZST)."""
    body = urllib.parse.urlencode({
        "dataset": DATASET_ID,
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


def load(path):
    if not os.path.exists(path):
        return {}
    with open(path, newline="") as f:
        return {r["date"]: r["level_m"] for r in csv.DictReader(f)}


def save(path, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "level_m"])
        for d in sorted(rows):
            w.writerow([d, rows[d]])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--backfill", action="store_true")
    args = ap.parse_args()
    now = dt.datetime.now(dt.timezone(dt.timedelta(hours=12)))
    years = range(FIRST_YEAR, now.year + 1) if args.backfill else range(now.year - 1, now.year + 1)
    rows = {} if args.backfill else load(OUT)
    for y in years:
        days = fetch_year(y)
        for d, vals in days.items():
            rows[d] = f"{sum(vals) / len(vals):.3f}"
        print(f"{y}: {len(days)} days")
        time.sleep(1)  # be polite to ORC
    if not rows:
        sys.exit("no data fetched")
    save(OUT, rows)
    last = max(rows)
    print(f"saved {len(rows)} days, latest {last} = {rows[last]} m")


if __name__ == "__main__":
    main()
