#!/bin/zsh
# write-batch — run topic:stage5-write for one batch with its held and moved codes set aside (STAGE5 step 7).
#
#   zsh scripts/stage5/write-batch.sh <stage5 dir> <batch dir> <topic> <units> [N]    # dry run N (default 0)
#   zsh scripts/stage5/write-batch.sh <stage5 dir> <batch dir> <topic> <units> apply  # 🛑 only after the runner's yes
#
# Moves <stage5>/codes/<id>.json aside for every id in <batch>/held.txt and <batch>/moved.txt (either may be absent),
# runs the writer from this worktree's backend (its .env must link to ev-accounts/backend/.env), then puts the codes
# back, even when the writer fails. A dry run writes <batch>/research-stage5-N.csv and dry-run-N.txt; apply writes
# stage5-write-apply.txt. Exit 3 with "WROTE" in the apply output is fine.
set -u
S=${1:?stage5 dir}; W=${2:?batch dir}; T=${3:?topic}; U=${4:?units, e.g. state:in}; M=${5:-0}
BACKEND=${0:A:h:h:h}
ASIDE=$S/codes-aside-${W:t}
ids=( ${(f)"$(cat $W/held.txt $W/moved.txt 2>/dev/null | sed '/^[[:space:]]*$/d')"} )
mkdir -p $ASIDE
restore() { for p in $ids; do [[ -f $ASIDE/$p.json ]] && mv $ASIDE/$p.json $S/codes/; done; print "restored; left aside: $(ls $ASIDE | wc -l | tr -d ' ')"; }
trap restore EXIT INT TERM
for p in $ids; do [[ -f $S/codes/$p.json ]] && mv $S/codes/$p.json $ASIDE/; done
cd $BACKEND
export ADMIN_INGEST_TOKEN=placeholder
if [[ $M == apply ]]; then
  npx tsx --env-file=.env scripts/topic-stage5-write.ts --topic $T --research ${S:h} --season draft --units $U --apply > $W/stage5-write-apply.txt 2>&1
else
  npx tsx --env-file=.env scripts/topic-stage5-write.ts --topic $T --research ${S:h} --season draft --units $U --csv-out $W/research-stage5-$M.csv > $W/dry-run-$M.txt 2>&1
fi
rc=$?
print "writer exit $rc (output in ${W:t}/$([[ $M == apply ]] && print stage5-write-apply.txt || print dry-run-$M.txt))"
exit $rc
