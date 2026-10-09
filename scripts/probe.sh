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
getx Data/Location_Summary/ "id=278"
getx Data/Location_Summary/278 ""
post Data/Location_Summary/ "id=278"
getx Data/DataSets/ "location=278"
getx Data/Datasets/ "locationId=278"
getx Data/LocationBase/ "id=278"
post Data/Dataset_Chart "dataset=Lake%20Level.Telemetry%40EM507&interval=Latest&alldata=false&timezone=720&calendar=CALENDARYEAR"
grep -oE 'data-(dataset|id|datasetid)[a-z-]*="[^"]+"' t*.out | sort -u | head -40 >> log.txt
grep -oE '(DataSetId|DatasetId|datasetId)[^,]{0,40}' t*.out | sort -u | head -20 >> log.txt
