#!/usr/bin/env bash
#
# Resumable chunk driver for sweep-fabricated-articles.mjs.
#
# WHY THIS EXISTS AS A COMMITTED FILE. The 2026-08-05 findings doc told the next session to "resume with
# sweep-wide.sh" — and the script was not in the repo. It had been a throwaway in someone's shell, which
# is the same way this workstream lost its tooling before (backend/scripts/_* is gitignored). A resume
# instruction that names a file only works if the file is committed.
#
# Usage (from backend/):
#   scripts/sweep-wide.sh <from-index> <to-index> [chunk-size] [-- extra sweep args]
#   scripts/sweep-wide.sh 7500 11728                 # resume the undated sweep to the end
#   scripts/sweep-wide.sh 0 2000 250 -- --dated-only
#
# Indices are positions in the sweep's own ORDER BY (rows_citing DESC, url), the same ones --from/--to
# take. The historical "chunk N" numbering is just N*250, so chunks 30..46 == indices 7500..11728.
#
# RESUMABLE BY ARTIFACT, NOT BY A STATE FILE. A chunk is skipped when its artifact already exists, so an
# interrupted run is resumed by re-issuing the identical command. There is no bookkeeping to get out of
# sync with what was actually written.
#
# ⚠ The tail chunk is short (11728 is not a multiple of 250) and the sweep names its artifact after the
# ACTUAL slice length, so the completion check globs on the start index rather than predicting the name.
set -uo pipefail

FROM=${1:?usage: sweep-wide.sh <from-index> <to-index> [chunk-size] [-- extra args]}
TO=${2:?usage: sweep-wide.sh <from-index> <to-index> [chunk-size] [-- extra args]}
SIZE=${3:-250}
shift $(( $# >= 3 ? 3 : 2 ))
[ "${1:-}" = "--" ] && shift
EXTRA=("$@")

HERE="$(cd "$(dirname "$0")" && pwd)"
OUTDIR="$HERE/../data/stance-retirement"
LOGDIR="$HERE/../data/stance-retirement"

# --skip-dated is the default slice: the dated URLs were swept and second-method verified on 2026-08-05.
# It also decides the artifact filename, so it must match what the completion check globs for.
TAG=undated
for a in "${EXTRA[@]:-}"; do
  [ "$a" = "--dated-only" ] && TAG=dated
done
case " ${EXTRA[*]:-} " in
  *" --dated-only "*) SLICE_ARG=() ;;
  *)                  SLICE_ARG=(--skip-dated) ;;
esac

echo "sweep-wide: indices ${FROM}..${TO} in steps of ${SIZE}, slice=${TAG}"
echo "sweep-wide: extra args: ${EXTRA[*]:-(none)}"

failed=0
for (( start=FROM; start<TO; start+=SIZE )); do
  end=$(( start + SIZE ))
  [ "$end" -gt "$TO" ] && end=$TO

  # shellcheck disable=SC2086
  existing=$(ls "$OUTDIR"/fabricated-article-sweep-${TAG}-${start}-*.json 2>/dev/null | head -1)
  if [ -n "$existing" ]; then
    echo "sweep-wide: SKIP ${start}-${end} (already have $(basename "$existing"))"
    continue
  fi

  echo "sweep-wide: RUN  ${start}-${end}  $(date '+%H:%M:%S')"
  if node "$HERE/sweep-fabricated-articles.mjs" "${SLICE_ARG[@]}" --from "$start" --to "$end" \
       "${EXTRA[@]:-}" >>"$LOGDIR/sweep-wide-${TAG}.log" 2>&1; then
    tail -1 "$LOGDIR/sweep-wide-${TAG}.log"
  else
    # ⚠ Do NOT abort the whole sweep on one bad chunk. A chunk that dies writes no artifact, so the next
    # resume re-runs exactly that chunk; stopping here would instead strand every later chunk behind it.
    echo "sweep-wide: 🔴 chunk ${start}-${end} FAILED (see sweep-wide-${TAG}.log) — continuing"
    failed=$(( failed + 1 ))
  fi
done

echo "sweep-wide: done. ${failed} chunk(s) failed and wrote no artifact; re-run the same command to retry them."
exit 0
