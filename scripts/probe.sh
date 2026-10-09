#!/usr/bin/env bash
# One-off probe: find the Hawea River flow dataset on ORC's portal.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
H=(-A "$UA" -b 'disclaimer=accepted' -H 'X-Requested-With: XMLHttpRequest')
n=0
getx() { n=$((n+1)); echo "## $n GET $1 $2" >> log.txt
  curl -sS -L -m 120 "${H[@]}" -o "t$n.out" -w "HTTP %{http_code} %{size_download}B %{content_type}\n" --get --data "$2" "$B/$1" >> log.txt 2>&1
  head -c 3000 "t$n.out" >> log.txt; echo >> log.txt; }
getx Data/Location/Dashboard/813/Location/EM507/Interval/Latest ""
getx Data/GetDashboard "id=813"
getx Data/SearchLocations/ "term=Hawea"
getx Data/SearchLocations/ "term=hawea"
for f in t*.out; do grep -oE '(data-(id|widget|dataset)[a-z-]*="[^"]+"|Location/[A-Z0-9]+|[A-Za-z ]+\.[A-Za-z ]+@[A-Z0-9]+)' $f | sort -u | head -40 | sed "s/^/$f: /"; done >> log.txt
