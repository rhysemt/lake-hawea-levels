#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal and EMI endpoints from a GitHub runner.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
get() { echo "=== $1"; curl -sS -L -m 60 -A 'Mozilla/5.0 lake-hawea-levels' -c jar -b jar -o "$2" -w 'HTTP %{http_code} %{size_download}B %{content_type} -> %{url_effective}\n' "$1"; }
get "$B/Data/Location/Dashboard/480/Location/EM507/Interval/Latest" dash.html
get "$B/Data/Location/Summary/Location/EM507/Interval/Latest" summary.html
for f in dash.html summary.html; do
  echo "--- links in $f"; grep -oE '(href|src|data-[a-z-]+)="[^"]*"' "$f" | grep -viE '\.(css|png|svg|ico|woff)' | sort -u | head -80
  echo "--- dataset-ish strings in $f"; grep -oiE '[A-Za-z ]{0,30}(DataSet|Dataset|Export)[^"<>]{0,120}' "$f" | sort -u | head -60
  echo "--- json-ish in $f"; grep -oE '\{[^{}]*(Identifier|Label|Parameter)[^{}]*\}' "$f" | head -20
done
for ds in "Lake%20Level.Primary%40EM507" "Lake%20Level.Lake%20Level%40EM507" "Water%20Level.Primary%40EM507" "Stage.Primary%40EM507"; do
  get "$B/Export/DataSet?DataSet=$ds&DateRange=Days7&ExportFormat=csv&Compressed=false&RoundData=False&Timezone=12&Calendar=CALENDARYEAR&IntervalPoints=PointsAsRecorded&Conversion=Instantaneous&Step=1" "exp.csv"; head -c 600 exp.csv; echo
done
get "https://www.emi.ea.govt.nz/Environment/Datasets/HydrologicalModellingDataset/3_StorageAndSpill_20241231/3_1_Storage/SI_HWE_Storage_LakeHawea.csv" emi.csv
file emi.csv; head -12 emi.csv; echo ...; tail -3 emi.csv; wc -l emi.csv
