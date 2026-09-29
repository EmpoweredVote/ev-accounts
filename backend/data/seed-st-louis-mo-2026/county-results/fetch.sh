#!/usr/bin/env bash
# Re-fetch the certified CSVs, and do not stop until each is byte-complete.
# A short file is a WRONG answer, not a small one. See FETCH.md.
set -u
cd "$(dirname "$0")"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
fetch () {  # fetch <local-name> <url>
  local out=$1 url=$2 want have
  want=$(curl -sI --max-time 40 -A "$UA" "$url" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}')
  [ -z "${want:-}" ] && { echo "$out: no Content-Length from $url"; return 1; }
  have=$(stat -c%s "$out" 2>/dev/null || echo 0)
  [ "$have" = "$want" ] && { echo "$out OK $have (already complete)"; return 0; }
  for try in 1 2 3 4 5 6; do
    curl -sL -C - --max-time 300 -A "$UA" -o "$out" "$url" >/dev/null 2>&1
    have=$(stat -c%s "$out" 2>/dev/null || echo 0)
    [ "$have" = "$want" ] && { echo "$out OK $have"; return 0; }
    echo "$out try$try $have/$want"
  done
  echo "$out FAILED $have/$want"; return 1
}
B=https://extcontent.stlouisco.com/BOE/eResults
fetch csv-201103.csv "$B/el201103/112020Detailed.csv"   # note: NOT CSV.csv
fetch csv-220802.csv "$B/el220802/CSV.csv"
fetch csv-221108.csv "$B/el221108/CSV.csv"
fetch csv-240806.csv "$B/el240806/CSV.csv"
fetch csv-241105.csv "$B/el241105/CSV.csv"
fetch csv-260804.csv "$B/el260804/CSV.csv"
