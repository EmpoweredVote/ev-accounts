#!/usr/bin/env bash
# Pull each member's own immigration issues page and show every sentence that
# mentions removal. Status recorded beside every value; temp file PID-scoped and
# deleted each iteration so a failed fetch can never show the previous page's text.
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
TMP="/tmp/hi-$$.html"

for host in "$@"; do
  for path in "/issues/immigration" "/immigration" "/issues/immigration-and-border-security" "/issues/border-security"; do
    url="https://$host$path"
    rm -f "$TMP"
    code=$(curl -sL -A "$UA" -m 25 -w '%{http_code}' -o "$TMP" "$url" 2>/dev/null)
    if [ "$code" = "200" ] && [ -s "$TMP" ]; then
      txt=$(sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<[^>]*>/ /g' -e 's/&nbsp;/ /g' -e 's/&#39;/'"'"'/g' -e 's/&quot;/"/g' "$TMP" \
            | tr '\n' ' ' | tr -s ' ' | sed 's/\. /.\n/g' \
            | grep -i "deport\|remov\|amnesty\|those here illegally\|already here" | head -6)
      printf '=== %s  HTTP %s\n%s\n\n' "$url" "$code" "${txt:-(page fetched, no sentence mentions removal)}"
      rm -f "$TMP"
      break
    else
      printf '=== %s  HTTP %s\n' "$url" "$code"
    fi
    rm -f "$TMP"
  done
done
rm -f "$TMP"
