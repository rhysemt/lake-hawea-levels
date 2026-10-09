#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal export from a GitHub runner; outputs land in probe/.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
CK='disclaimer=accepted'
for loc in EM507 278; do
  for dr in Days7 EntirePeriodOfRecord; do
    q="Location=$loc&DateRange=$dr&ExportFormat=csv"
    tok=$(curl -sS -m 60 -A "$UA" -b "$CK" -X POST -H 'Content-Length: 0' "$B/Export/LocationToken?$q")
    echo "loc=$loc dr=$dr token-resp=${tok:0:200}" >> log.txt
    t=$(echo "$tok" | python3 -c 'import sys,json;print(json.load(sys.stdin)["Token"])' 2>/dev/null)
    curl -sS -L -m 300 -A "$UA" -b "$CK" -o "loc_${loc}_$dr.out" -w "HTTP %{http_code} %{size_download}B %{content_type}\n" --get --data-urlencode "Token=$t" "$B/Export/Location?$q" >> log.txt 2>&1
    file "loc_${loc}_$dr.out" >> log.txt
  done
done
