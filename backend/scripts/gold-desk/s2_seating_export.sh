#!/bin/zsh
# Read-only export for s2_seating_analysis.py. Usage: s2_seating_export.sh <out-dir>
# Needs DATABASE_URL (backend/.env). Every statement runs in a read-only transaction.
set -euo pipefail
OUT=${1:?out dir}; mkdir -p "$OUT"
export PGOPTIONS='-c default_transaction_read_only=on'
q() { psql "$DATABASE_URL" -X -q -At -c "$1"; }
q "select json_agg(x) from (select l.id, l.batch_id, l.politician_id, p.full_name, l.office_id, t.topic_key, l.coder_slot, l.level, l.model, l.codebook_version, l.value, l.blank_reason, l.valid, l.rests_on, l.source_codes, l.quote_codes, l.needs_source, l.raw_output, l.created_at, l.served_revision_id from inform.stance_coder_labels l join essentials.politicians p on p.id=l.politician_id join inform.compass_topics t on t.id=l.topic_id) x" > "$OUT/labels.json"
q "select json_agg(x) from (select g.*, t.topic_key, p.full_name from inform.stance_gold_labels g join inform.compass_topics t on t.id=g.topic_id join essentials.politicians p on p.id=g.politician_id) x" > "$OUT/gold.json"
q "select json_agg(x) from (select a.politician_id, t.topic_key, s.name season, a.value, a.created_at, a.editor_id from inform.politician_answers a join inform.compass_topics t on t.id=a.topic_id join inform.seasons s on s.id=a.season_id) x" > "$OUT/answers.json"
q "select json_agg(x) from (select r.id rev_id, t.topic_key, sr.value, sr.text from inform.compass_stance_revisions sr join inform.compass_topic_revisions r on r.id=sr.topic_revision_id join inform.compass_topics t on t.id=r.topic_id) x" > "$OUT/rungs.json"
q "select json_object_agg(pid, lvl) from (select distinct on (p.id) p.id pid, case when d.district_type like 'NATIONAL_JUD%' or d.district_type='JUDICIAL' then 'judicial' when d.district_type like 'NATIONAL%' then 'federal' when d.district_type like 'STATE%' then 'state' when d.district_type='SCHOOL' then 'school' when d.district_type is null then 'none' else 'local' end lvl from essentials.politicians p left join essentials.office_terms ot on ot.politician_id=p.id left join essentials.offices o on o.id=ot.office_id left join essentials.districts d on d.id=o.district_id order by p.id, (ot.term_end is null) desc, ot.term_start desc nulls last) x" > "$OUT/levels.json"
echo "exported to $OUT"
