#!/bin/sh
# Store snapshots, store the Opus label, and queue each unanimous chair, for every batch named. Run from backend/.
#   sh data/stance-research/library-s3-2026-10-15/finish.sh lib-ward lib-jackson ...
export ADMIN_INGEST_TOKEN=x
for n in "$@"; do
  d=data/stance-research/2026-10-15-shadow-$n
  [ -f "$d/labels/coder-1.json" ] || { echo "$n: NO LABEL"; continue; }
  npx tsx scripts/store-snapshots.ts --dir "$d" --apply 2>&1 | tail -1
  npx tsx scripts/code-stance-batch.ts --dir "$d" --season draft --models "opus" --apply 2>&1 | grep -E "^would|^stored|ERROR"
  npx tsx scripts/queue-coded-batch.ts --dir "$d" --season draft --apply 2>&1 | grep -E "^queue|^skip|^queued|ERROR"
done
