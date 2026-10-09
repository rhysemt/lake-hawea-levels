#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal chart endpoints from a GitHub runner; outputs land in probe/.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
CK='disclaimer=accepted'
n=0
post() { n=$((n+1)); echo "## $n POST $1 $2" >> log.txt
  curl -sS -L -m 300 -A "$UA" -b "$CK" -H 'X-Requested-With: XMLHttpRequest' -o "t$n.out" -w "HTTP %{http_code} %{size_download}B %{content_type}\n" -X POST --data "$2" "$B/$1" >> log.txt 2>&1
  head -c 300 "t$n.out" >> log.txt; echo >> log.txt; }
getx() { n=$((n+1)); echo "## $n GET $1 $2" >> log.txt
  curl -sS -L -m 300 -A "$UA" -b "$CK" -H 'X-Requested-With: XMLHttpRequest' -o "t$n.out" -w "HTTP %{http_code} %{size_download}B %{content_type}\n" --get --data "$2" "$B/$1" >> log.txt 2>&1
  head -c 300 "t$n.out" >> log.txt; echo >> log.txt; }
post Data/Dataset_Chart "dataset=252849&interval=Latest&alldata=false&timezone=720&calendar=CALENDARYEAR"
post Data/Dataset_Chart "dataset=252849&interval=Custom&date=2025-01-01&endDate=2025-03-01&alldata=false&timezone=720&calendar=CALENDARYEAR"
post Data/Dataset_Chart "dataset=252849&interval=Custom&date=1930-01-01&endDate=2026-12-31&alldata=true&timezone=720&calendar=CALENDARYEAR"
post Data/Dataset_Chart "dataset=252849&interval=Years&date=1990-01-01&alldata=false&timezone=720&calendar=CALENDARYEAR"
for f in t*.out; do wc -c $f; done >> log.txt
