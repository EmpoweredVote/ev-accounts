#!/usr/bin/env bash
# Fetch the official identity of every cited malegislature.gov bill page.
# TSV per bill: <bill_path>\t<http_status>\t<header>\t<title>
#   header = the page <h1>: "Bill H.2983 194th (Current)" or "Order H.4933 192nd (2021 - 2022)".
#            It is what says whether the cited document is a BILL or a mere ORDER, and which court.
#   title  = the first <h2> inside #contentContainer, which is the official title.
set -u
SP="$1"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
OUT="$SP/ma-bill-titles.tsv"
: > "$OUT"
n=0
while IFS= read -r path; do
  [ -z "$path" ] && continue
  n=$((n+1))
  tmp="$SP/.pg-$$.html"
  code=$(curl -sS -A "$UA" --max-time 40 -w '%{http_code}' -o "$tmp" "https://malegislature.gov${path}" 2>/dev/null)
  header=$(tr '\n' ' ' < "$tmp" 2>/dev/null | awk -v RS='<h1' 'NR==2{sub(/<\/h1>.*/,""); gsub(/<[^>]*>/," "); gsub(/  +/," "); gsub(/^[ >]+|[ ]+$/,""); print}' | head -c 120)
  title=$(awk '/contentContainer/{seen=1} seen && /<h2>/{sub(/.*<h2>/,""); sub(/<\/h2>.*/,""); gsub(/<[^>]*>/,""); print; exit}' "$tmp" 2>/dev/null | head -c 300)
  printf '%s\t%s\t%s\t%s\n' "$path" "$code" "$header" "$title" >> "$OUT"
  rm -f "$tmp"
  sleep 0.35
done < "$SP/ma-bill-paths.txt"
echo "DONE fetched=$n -> $OUT"
