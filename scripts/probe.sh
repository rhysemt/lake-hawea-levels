#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal from a GitHub runner; outputs land in probe/.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
C="curl -sS -L -m 90 -A $UA -c jar -b jar"
get() { echo "=== $1" >> log.txt; curl -sS -L -m 90 -A "$UA" -c jar -b jar -o "$2" -w 'HTTP %{http_code} %{size_download}B %{content_type} -> %{url_effective}\n' "$1" >> log.txt 2>&1; }
get "$B/Disclaimer" disc.html
TOK=$(grep -oE '__RequestVerificationToken" type="hidden" value="[^"]+' disc.html | sed 's/.*value="//')
R=/AQWebPortal/Data/Location/Summary/Location/EM507/Interval/Latest
curl -sS -m 60 -A "$UA" -c jar -b jar -o accept.html -D accept.hdr -w 'ACCEPT HTTP %{http_code}\n' \
  --data-urlencode "returnUrl=$R" --data-urlencode "__RequestVerificationToken=$TOK" "$B/AcceptDisclaimer" >> log.txt 2>&1
get "$B/Data/Location/Summary/Location/EM507/Interval/Latest" summary.html
get "$B/Data/Location/Dashboard/480/Location/EM507/Interval/Latest" dash.html
get "$B/Data/Location/EM507" loc.html
cp jar jar.txt
get "$B/bundles/aqPortal.js?v=dnptTFHSJzabrnoP9vs6HlE-wUk" portal.js
