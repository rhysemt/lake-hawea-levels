#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal dataset export from a GitHub runner; outputs land in probe/.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
CK='disclaimer=accepted'
DS='Lake Level.Telemetry@EM507'
n=0
try() { n=$((n+1)); echo "## $n $1 $2" >> log.txt
  curl -sS -L -m 300 -A "$UA" -b "$CK" -o "t$n.out" -w "HTTP %{http_code} %{size_download}B %{content_type}\n" --get --data-urlencode "DataSet=$DS" $2 "$B/$1" >> log.txt 2>&1
  file "t$n.out" >> log.txt; head -c 400 "t$n.out" | strings | head -8 >> log.txt; }
try Export/Dataset "-d DateRange=Days7 -d ExportFormat=csv"
try Export/DataSet "-d DateRange=Days7 -d ExportFormat=csv -d Compressed=false -d RoundData=False -d Timezone=12 -d Calendar=CALENDARYEAR -d IntervalPoints=PointsAsRecorded -d Step=1"
try api/v1/export/data-set "-d DateRange=Days7 -d Calendar=CALENDARYEAR -d IntervalPoints=PointsAsRecorded -d Step=1 -d Timezone=12 -d RoundData=False"
try Export/Dataset "-d DateRange=EntirePeriodOfRecord -d ExportFormat=csv"
try api/v1/export/data-set "-d DateRange=Custom -d StartTime=2026-01-01%2000:00:00 -d EndTime=2026-01-03%2000:00:00 -d Calendar=CALENDARYEAR -d IntervalPoints=PointsAsRecorded -d Step=1 -d Timezone=12"
# token flavour
tok=$(curl -sS -m 60 -A "$UA" -b "$CK" -X POST -H 'Content-Length: 0' "$B/Export/DataSetToken?DataSet=Lake%20Level.Telemetry%40EM507&DateRange=EntirePeriodOfRecord&ExportFormat=csv&Compressed=false&Calendar=CALENDARYEAR&IntervalPoints=PointsAsRecorded&Step=1&Timezone=12")
echo "token resp: ${tok:0:300}" >> log.txt
t=$(echo "$tok" | python3 -c 'import sys,json;print(json.load(sys.stdin)["Token"])' 2>/dev/null)
try Export/DataSet "-d DateRange=EntirePeriodOfRecord -d ExportFormat=csv -d Compressed=false -d Calendar=CALENDARYEAR -d IntervalPoints=PointsAsRecorded -d Step=1 -d Timezone=12 --data-urlencode Token=$t"
for f in t*.out; do wc -c $f; done >> log.txt
