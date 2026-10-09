#!/usr/bin/env bash
# One-off probe of ORC AQUARIUS WebPortal from a GitHub runner.
set -u
B=https://envdata.orc.govt.nz/AQWebPortal
mkdir -p probe && cd probe
UA='Mozilla/5.0 lake-hawea-levels'
get() { echo "=== $1"; curl -sS -L -m 60 -A "$UA" -c jar -b jar -o "$2" -w 'HTTP %{http_code} %{size_download}B %{content_type} -> %{url_effective}\n' "$1"; }
get "$B/Disclaimer" disc.html
echo "--- disclaimer forms"; grep -iE '<form|<input|<button|action=' disc.html | head -30
get "$B/bundles/aqPortal.js?v=dnptTFHSJzabrnoP9vs6HlE-wUk" portal.js
echo "--- endpoints in portal.js"; grep -oE '"/?(Data|Export|Disclaimer|api)[A-Za-z0-9/_{}.-]*"|[A-Za-z]+Url *[:=] *"[^"]*"' portal.js | sort -u | head -150
echo "--- export snippets"; grep -oE '.{0,120}Export/[A-Za-z]+.{0,200}' portal.js | head -20
echo "--- disclaimer snippets"; grep -oE '.{0,150}[Dd]isclaimer.{0,150}' portal.js | head -10
