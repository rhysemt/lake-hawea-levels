#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal from a GitHub runner; outputs land in probe/.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
get() { echo "=== $1" >> log.txt; curl -sS -L -m 60 -A "$UA" -c jar -b jar -o "$2" -w 'HTTP %{http_code} %{size_download}B %{content_type} -> %{url_effective}\n' "$1" >> log.txt 2>&1; }
get "$B/Disclaimer" disc.html
curl -sS -L -m 60 -A "$UA" -c jar -b jar -o accept.html -w 'ACCEPT HTTP %{http_code} -> %{url_effective}\n' --data-urlencode "returnUrl=/AQWebPortal/Data/Location/Summary/Location/EM507/Interval/Latest" "$B/AcceptDisclaimer" >> log.txt 2>&1
get "$B/Data/Location/Summary/Location/EM507/Interval/Latest" summary.html
get "$B/Data/Location/Dashboard/480/Location/EM507/Interval/Latest" dash.html
get "$B/bundles/aqPortalMin.js?v=PEUT6IZnvJiBqme68jcW-Ue7hHg" portalmin.js
get "$B/bundles/admin.js?v=oV0emqwl3o0tUfG78_xEYr0WX8k" admin.js
cp jar jar.txt
