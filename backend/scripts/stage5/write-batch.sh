#!/bin/zsh
# write-batch — run topic:stage5-write for one batch, leaving out its held and moved people (STAGE5 step 7).
#
#   zsh scripts/stage5/write-batch.sh <stage5 dir> <batch dir> <topic> <units> [N]    # dry run N (default 0)
#   zsh scripts/stage5/write-batch.sh <stage5 dir> <batch dir> <topic> <units> apply  # 🛑 only after the runner's yes
#
# Writes <batch>/skip-ids.txt (every id in <batch>/held.txt and <batch>/moved.txt; either may be absent) and passes it
# to the writer as --skip-ids, so those people are left out without touching <stage5>/codes. (Until 2026-11-12 their
# code files were moved aside and back, which a session's permission check refused in mo-01, and which another
# session's run could catch half done.) Runs the writer from this worktree's backend (its .env must link to
# ev-accounts/backend/.env). A dry run writes <batch>/research-stage5-N.csv and dry-run-N.txt; apply writes
# stage5-write-apply.txt. Exit 3 with "WROTE" in the apply output is fine. Every run also writes
# <batch>/pids-write.txt (pids.txt minus held and moved ids), the list readback.ts reads after the write.
set -u
S=${1:?stage5 dir}; W=${2:?batch dir}; T=${3:?topic}; U=${4:?units, e.g. state:in}; M=${5:-0}
BACKEND=${0:A:h:h:h}
ids=( ${(f)"$(cat $W/held.txt $W/moved.txt 2>/dev/null | sed '/^[[:space:]]*$/d')"} )
print -l -- $ids > $W/skip-ids.txt
if [[ -f $W/pids.txt ]]; then
  if (( ${#ids} )); then grep -vxF -f $W/skip-ids.txt $W/pids.txt > $W/pids-write.txt; else cp $W/pids.txt $W/pids-write.txt; fi
fi
cd $BACKEND
export ADMIN_INGEST_TOKEN=placeholder
skip=(--skip-ids ${W:A}/skip-ids.txt)
if [[ $M == apply ]]; then
  npx tsx --env-file=.env scripts/topic-stage5-write.ts --topic $T --research ${S:A:h} --season draft --units $U $skip --apply > $W/stage5-write-apply.txt 2>&1
else
  npx tsx --env-file=.env scripts/topic-stage5-write.ts --topic $T --research ${S:A:h} --season draft --units $U $skip --csv-out ${W:A}/research-stage5-$M.csv > $W/dry-run-$M.txt 2>&1
fi
rc=$?
print "writer exit $rc (left out ${#ids} held/moved id(s); output in ${W:t}/$([[ $M == apply ]] && print stage5-write-apply.txt || print dry-run-$M.txt))"
exit $rc
