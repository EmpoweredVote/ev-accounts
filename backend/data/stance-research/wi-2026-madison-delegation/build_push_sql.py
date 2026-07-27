#!/usr/bin/env py
"""Generate push_wi_madison.sql from the reviewed batch CSVs.

Hand-transcribing 22 rows of multi-sentence reasoning into SQL is how quoting
bugs and copy errors get introduced, so the accept-list lives here as data and
the SQL is generated. The list below IS the review decision record: a row not
named here is not pushed.

Run from the wave directory:  py build_push_sql.py

Follows the AZ wave's audit-only push pattern (see
../az-2026-state-leg/push_H1.sql): writes only inform.politician_answers and
inform.politician_context, resolves topic_id live from
inform.compass_topics.topic_key, and is idempotent via ON CONFLICT.
Deliberately NOT a numbered migration -- stance data is data, and prior waves
(AZ/VA/ME) all shipped this way.
"""
import csv
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

FILES = {
    "A": "2026-07-27-wi-madison-batch-A.csv",
    "B": "2026-07-27-wi-madison-batch-B.csv",
    "C": "2026-07-27-wi-madison-batch-C.csv",
    "D": "2026-07-27-wi-madison-pass2-D.csv",
    "E": "2026-07-27-wi-madison-pass2-E.csv",
    "F": "2026-07-27-wi-madison-pass2-F.csv",
}

# (batch, full_name, topic_key, override_value_or_None, appended_note_or_None)
# override_value is used ONLY where the orchestrator changed the chair on
# review. Where a value is overridden an explanatory note is MANDATORY --
# otherwise the stored reasoning would argue for a different number than the
# stored value, which is worse than either alone.
DOWNGRADE_NOTE = (
    " [ORCHESTRATOR REVIEW 2026-07-27: value corrected from 2 to 3. Chair 2 reads "
    "'lower Medicare age to 55 AND expand Medicaid significantly' -- a compound chair "
    "whose Medicare-age element no state legislator can evidence, since Medicare is "
    "federal. The same bill (SB23) was independently scored chair 2 by two research "
    "passes and chair 3 by a third; the chair-3 reading is adopted because it is the "
    "only one that applies the compound-chair rule. Chair 3, 'improve current programs', "
    "is what a benefit extension does. The evidence cited above is unchanged and still "
    "supports the row -- only the chair mapping was corrected.]"
)

ACCEPTED = [
    # ---- pass 1, batch A ----
    ("A", "Joan Fitzgerald",   "school-vouchers",  None, None),
    ("A", "Randy Udell",       "civil-rights",     None, None),
    ("A", "Andrew Hysell",     "housing",          None, None),
    ("A", "Francesca Hong",    "data-centers",     None, None),
    # ---- pass 1, batch B ----
    ("B", "Renuka Mayadev",    "civil-rights",     None, None),
    ("B", "Renuka Mayadev",    "childcare",        None, None),
    ("B", "Lisa Subeck",       "campaign-finance", None, None),
    ("B", "Shelia Stubbs",     "medicare/aid",     3,    DOWNGRADE_NOTE),
    # ---- pass 1, batch C ----
    ("C", "Alex Joers",        "childcare",        None, None),
    ("C", "Alex Joers",        "ai-regulation",    None, None),
    ("C", "Kelda Roys",        "ai-regulation",    None, None),
    ("C", "Kelda Roys",        "data-centers",     None, None),
    ("C", "Kelda Roys",        "civil-rights",     None, None),
    # ---- pass 2, batch D ----
    ("D", "Mike Bare",         "housing",          None, None),
    ("D", "Mike Bare",         "medicare/aid",     None, None),
    ("D", "Lisa Subeck",       "data-centers",     None, None),
    ("D", "Lisa Subeck",       "medicare/aid",     None, None),
    ("D", "Lisa Subeck",       "childcare",        None, None),
    # ---- pass 2, batch E ----
    ("E", "Kelda Roys",        "abortion",         None, None),
    ("E", "Dianne Hesselbein", "medicare/aid",     3,    DOWNGRADE_NOTE),
    # ---- pass 2, batch F ----
    ("F", "Randy Udell",       "healthcare",       None, None),
    ("F", "Randy Udell",       "voting-rights",    None, None),
]


def load_roster():
    ids, order = {}, {}
    with open(os.path.join(HERE, "_ROSTER.csv"), encoding="utf-8-sig", newline="") as f:
        for i, r in enumerate(csv.DictReader(f)):
            if r["full_name"].strip():
                ids[r["full_name"].strip()] = (
                    r["politician_id"].strip(), r["chamber"].strip(), r["district"].strip())
                order[r["full_name"].strip()] = i
    return ids, order


def load_rows():
    out = {}
    for tag, fname in FILES.items():
        path = os.path.join(HERE, fname)
        with open(path, encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                if not (r.get("full_name") or "").strip():
                    continue
                out[(tag, r["full_name"].strip(), r["topic_key"].strip())] = r
    return out


def q(s: str) -> str:
    """Dollar-quote; $ctx$ matches the AZ wave's convention."""
    if "$ctx$" in s:
        sys.exit("FATAL: reasoning contains the dollar-quote delimiter")
    return f"$ctx$" + s + "$ctx$"


def main() -> int:
    ids, order = load_roster()
    rows = load_rows()
    out, seen, n = [], set(), 0

    for tag, name, topic, override, note in ACCEPTED:
        key = (tag, name, topic)
        if key not in rows:
            sys.exit(f"FATAL: accepted row not found in CSV: {key}")
        if (name, topic) in seen:
            sys.exit(f"FATAL: duplicate (politician, topic) accepted: {name}/{topic}")
        seen.add((name, topic))
        if name not in ids:
            sys.exit(f"FATAL: {name} not in _ROSTER.csv")

        r = rows[key]
        pid, chamber, district = ids[name]
        value = override if override is not None else int(r["value"])
        reasoning = (r["reasoning"] or "").strip() + (note or "")
        srcs = [s.strip() for s in
                (r.get("source_url_1"), r.get("source_url_2"), r.get("source_url_3"))
                if s and s.strip()]
        if not srcs:
            sys.exit(f"FATAL: no sources for {name}/{topic}")
        arr = "ARRAY[" + ",".join("'" + s.replace("'", "''") + "'" for s in srcs) + "]::text[]"
        flag = "  [VALUE CORRECTED ON REVIEW]" if override is not None else ""

        out.append(f"""
-- ----- {name} ({chamber} District {district}) / {topic} = {value} -----  [batch {tag}]{flag}
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '{pid}', ct.id, {value}.0
FROM inform.compass_topics ct WHERE ct.topic_key = '{topic}'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '{pid}', ct.id, {q(reasoning)},
       {arr}
FROM inform.compass_topics ct WHERE ct.topic_key = '{topic}'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
""")
        n += 1

    members = sorted({name for _, name, _, _, _ in ACCEPTED}, key=lambda x: order[x])
    header = f"""-- ============================================================================
-- WI Madison-delegation stance wave 2026-07-27 -- {n} rows / {len(members)} of 12 legislators
--
-- AUDIT-ONLY / unregistered. Touches ONLY inform.politician_answers and
-- inform.politician_context. Deliberately not a numbered migration: stance data
-- is data, and the AZ/VA/ME waves all shipped this way.
--
-- GENERATED by build_push_sql.py -- do not hand-edit; change the accept-list
-- in that script and regenerate. The accept-list is the review decision record.
--
-- Provenance: two research passes, 41 rows produced, 15 dropped and 2 values
-- corrected on orchestrator review. Reasons per row in _REVIEW_FLAGS.md;
-- evidence-type analysis in _EVIDENCE_TYPE_ANALYSIS.md.
-- Melissa Ratcliff is deliberately absent: both her candidate rows failed a
-- same-source chair-disagreement check. An empty compass is the honest result.
--
-- politician_ids from _ROSTER.csv (resolved via office/district join, never
-- bare full_name). topic_ids resolved live from inform.compass_topics.topic_key.
-- Idempotent: re-running updates in place and never double-writes.
--
-- DRY RUN FIRST -- wrap in BEGIN; ... ROLLBACK; and confirm the rollback
-- actually reverted before trusting it.
-- ============================================================================

BEGIN;
"""
    gate = f"""
-- ---- post-verify gate: fail loudly rather than half-apply ----
DO $$
DECLARE a int; c int;
BEGIN
  SELECT count(*) INTO a FROM inform.politician_answers pa
   WHERE pa.politician_id IN ({','.join("'" + ids[m][0] + "'" for m in members)});
  SELECT count(*) INTO c FROM inform.politician_context pc
   WHERE pc.politician_id IN ({','.join("'" + ids[m][0] + "'" for m in members)});
  IF a <> {n} THEN
    RAISE EXCEPTION 'expected {n} answer rows for this cohort, found %', a;
  END IF;
  IF c <> {n} THEN
    RAISE EXCEPTION 'expected {n} context rows for this cohort, found %', c;
  END IF;
  RAISE NOTICE 'OK: {n} answers + {n} context rows across {len(members)} legislators';
END $$;

COMMIT;
"""
    path = os.path.join(HERE, "push_wi_madison.sql")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(header + "".join(out) + gate)
    print(f"wrote {path}\n  {n} rows across {len(members)} legislators")
    for m in members:
        cnt = sum(1 for _, nm, _, _, _ in ACCEPTED if nm == m)
        print(f"    {m:22s} {cnt}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
