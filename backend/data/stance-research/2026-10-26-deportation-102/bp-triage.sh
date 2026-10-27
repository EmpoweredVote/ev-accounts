#!/usr/bin/env bash
# Triage the 102 against Ballotpedia: does this person have a Candidate Connection
# survey (the one source type proven to reach an own-words ladder)?
#
# Lessons from the 2026-10-26 title sweep, applied here:
#   - the temp file is PID-scoped and DELETED every iteration, so a failed fetch
#     yields empty fields rather than the PREVIOUS person's page;
#   - the HTTP status is recorded beside every value and only 200 rows mean anything;
#   - identity is NOT assumed from the name: the state and office are checked on the
#     page itself and reported as flags for a human to read.
set -u
IN="$1"
OUT="$2"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
TMP="/tmp/bp-$$.html"

printf 'name\tstate\toffice\tlevel\turl\thttp\tstate_on_page\toffice_word_on_page\tsurvey\n' > "$OUT"

tail -n +2 "$IN" | while IFS=$'\t' read -r name state office level imm depstate depreason pid; do
  [ -z "$name" ] && continue
  slug=$(printf '%s' "$name" | sed 's/[[:space:]]\+/_/g')
  url="https://ballotpedia.org/$slug"
  rm -f "$TMP"
  code=$(curl -sL -A "$UA" -m 25 -w '%{http_code}' -o "$TMP" "$url" 2>/dev/null)
  st_hit=""; off_hit=""; survey=""
  if [ "$code" = "200" ] && [ -s "$TMP" ]; then
    st_hit=$(grep -c -F -- "$state" "$TMP" 2>/dev/null || echo 0)
    w=$(printf '%s' "$office" | awk '{print $1}')
    off_hit=$(grep -ic -- "$w" "$TMP" 2>/dev/null || echo 0)
    if grep -q "did not complete" "$TMP"; then
      survey="not completed"
    elif grep -qi "completed Ballotpedia's 20[0-9][0-9] Candidate Connection survey" "$TMP"; then
      survey="COMPLETED"
    else
      survey="unclear"
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$state" "$office" "$level" "$url" "$code" "$st_hit" "$off_hit" "$survey" >> "$OUT"
  rm -f "$TMP"
  sleep 1
done
rm -f "$TMP"
