"""
build_push_sql.py — emit push_wi_stateleg_rollcall_wave1.sql from the adjudicated roll calls.

  py data/stance-research/wi-2026-state-leg/build_push_sql.py

Only the roll calls marked chair_shaped=yes in wi-rollcall-adjudications.json are eligible, and
only members who cast an explicit "Yes". This file IS the review decision record: a row not
derivable from the ADJUDICATED map below is not pushed.

Why a vote is sufficient evidence here: both bills were adjudicated as CHAIR-SHAPED, meaning the
bill's entire purpose is to set a posture that matches one chair's literal text. The chair is named
by the bill and the source is the member's own recorded vote, independently — which is the bar.

Deliberate exclusions:
  * "No" votes. An oppositional No rules out the far end and pins nothing.
  * "No Vote" — that is ABSENT, not opposition.
  * "Paired For" / "Paired Against" (1 each on av0182). A pairing is a parliamentary arrangement,
    not an unambiguous affirmative. Costs one row; avoids asserting a stance from a procedure.
"""

import csv
import json
import os

DIR = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(DIR, 'push_wi_stateleg_rollcall_wave1.sql')

# vote_id -> (topic_key, topic_id, chair, tally, chamber_label)
ADJUDICATED = {
    'av0137': ('civil-rights', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5, '54-45', '2025 Assembly Vote 137'),
    'sv0140': ('civil-rights', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5, '18-15', '2025 Senate Vote 140'),
    'av0182': ('data-centers', '4559b513-0fd8-4ed1-babd-f3b554162f40', 2, '53-44', '2025 Assembly Vote 182'),
}

REASONING = {
    'civil-rights': (
        "Voted Yes on 2025 Assembly Joint Resolution 102 (second consideration), a proposed "
        "constitutional amendment creating Article I, Section 27, under which no governmental entity "
        "“may not discriminate against, or grant preferential treatment to, any individual or group on "
        "the basis of race, sex, color, ethnicity, or national origin in public employment, public "
        "education, public contracting, or public administration.” “Governmental entity” is defined to "
        "cover the state, its political subdivisions, the UW and Technical College Systems, every "
        "public school district, the legislature and the courts. The amendment's entire purpose is to "
        "end race- and sex-conscious government programs, which is what the most restrictive position "
        "on this scale describes: eliminating affirmative action and all race-based government "
        "programs. Recorded vote: {vote}, {tally}."
    ),
    'data-centers': (
        "Voted Yes on 2025 Assembly Bill 840, which directs the Public Service Commission to ensure in "
        "its rate-making orders that “no costs associated with the construction or extension of electric "
        "infrastructure that primarily serves the load of a data center are allocated to or recovered "
        "from any other customer,” and requires that any renewable energy facility primarily serving a "
        "data center be located at the data center site. The bill also mandates closed-loop cooling, "
        "annual water-use reporting to the DNR, and a reclamation bond. Those first two provisions are "
        "precisely the two clauses of this scale's second position: requiring data centers to fund "
        "their own dedicated power generation, and barring utilities from passing data center "
        "infrastructure costs through to other customers. Recorded vote: {vote}, {tally}."
    ),
}

BILL_TEXT = {
    'civil-rights': 'https://docs.legis.wisconsin.gov/document/proposaltext/2025/REG/AJR102',
    'data-centers': 'https://docs.legis.wisconsin.gov/document/proposaltext/2025/REG/AB840',
}


def read_csv(path):
    with open(path, encoding='utf-8') as f:
        return list(csv.DictReader(f))


def main():
    adj = json.load(open(os.path.join(DIR, 'wi-rollcall-adjudications.json'), encoding='utf-8'))['adjudications']
    # Guard: never emit a row for a roll call that is not adjudicated chair_shaped=yes.
    for vid in ADJUDICATED:
        a = adj.get(vid)
        if not a or a['chair_shaped'] != 'yes':
            raise SystemExit(f'{vid} is not adjudicated chair_shaped=yes — refusing to emit')
        if a['topic_final'] != ADJUDICATED[vid][0] or str(a['chair_if_yes']) != str(ADJUDICATED[vid][2]):
            raise SystemExit(f'{vid} disagrees with the adjudication sidecar — refusing to emit')

    votes = read_csv(os.path.join(DIR, 'wi_legis_votes.csv'))
    pid = {(r['chamber'], int(r['district'])): r['politician_id']
           for r in read_csv(os.path.join(DIR, 'wi_headshot_import_manifest.csv'))}

    rows = []
    for r in votes:
        vid = r['vote_url'].rsplit('/', 1)[-1]
        if vid not in ADJUDICATED or r['position'] != 'Yes':
            continue
        key = (r['chamber'], int(r['district']))
        if key not in pid:
            raise SystemExit(f'no politician_id for {key} — refusing to emit a partial wave')
        topic_key, topic_id, chair, tally, votelabel = ADJUDICATED[vid]
        rows.append({
            'politician_id': pid[key],
            'topic_id': topic_id,
            'topic_key': topic_key,
            'chair': chair,
            'member': r['member'],
            'seat': f"{r['chamber']} {r['district']}",
            'reasoning': REASONING[topic_key].format(vote=votelabel, tally=tally),
            'sources': [r['vote_url'], BILL_TEXT[topic_key]],
        })

    # A person must not get two different chairs on one topic from this wave.
    seen = {}
    for x in rows:
        k = (x['politician_id'], x['topic_id'])
        if k in seen and seen[k] != x['chair']:
            raise SystemExit(f'chair disagreement within the wave for {x["member"]} on {x["topic_key"]}')
        seen[k] = x['chair']

    q = lambda s: "'" + s.replace("'", "''") + "'"
    out = [f"""-- WI state-legislature stance wave 1 — roll-call derived, {len(rows)} rows
--
-- NOT a numbered migration: stance data is data, and the AZ/VA/ME/WI-Madison waves shipped the same
-- way. Generated by build_push_sql.py; that script's ADJUDICATED map is the review decision record.
--
-- Source of every row: a roll call adjudicated CHAIR-SHAPED in wi-rollcall-adjudications.json, plus
-- the member's own recorded Yes vote. Two bills qualified out of 10 adjudicated (25%):
--   AJR 102 (av0137 Assembly 54-45, sv0140 Senate 18-15) -> civil-rights chair 5
--   AB 840  (av0182 Assembly 53-44)                      -> data-centers chair 2
--
-- {len([r for r in rows if r['topic_key'] == 'civil-rights'])} civil-rights + {len([r for r in rows if r['topic_key'] == 'data-centers'])} data-centers rows across {len({r['politician_id'] for r in rows})} of 132 legislators.
--
-- Excluded by design: No votes (an oppositional No pins nothing), "No Vote" (that is ABSENT), and
-- Paired For/Against (a parliamentary arrangement, not an unambiguous affirmative).
--
-- politician_id resolved via office_current_holder on (chamber, district) and confirmed on FIRST AND
-- LAST name against the official roster — never on bare full_name.
-- Idempotent: every write is NOT EXISTS-guarded, so re-running is a no-op and no existing row is
-- overwritten. Verified before generating that none of these 125 (person, topic) pairs already has a
-- row: the 6 pre-existing civil-rights/data-centers rows all belong to members who voted No.

BEGIN;
"""]

    for x in rows:
        out.append(f"""-- {x['seat']} {x['member']} — {x['topic_key']} chair {x['chair']}
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '{x['politician_id']}'::uuid, '{x['topic_id']}'::uuid, {x['chair']}
WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers
                   WHERE politician_id = '{x['politician_id']}'::uuid AND topic_id = '{x['topic_id']}'::uuid);
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '{x['politician_id']}'::uuid, '{x['topic_id']}'::uuid, {q(x['reasoning'])},
       ARRAY[{', '.join(q(s) for s in x['sources'])}]::text[]
WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context
                   WHERE politician_id = '{x['politician_id']}'::uuid AND topic_id = '{x['topic_id']}'::uuid);""")

    ids = sorted({r['politician_id'] for r in rows})
    idlist = ', '.join(f"'{i}'::uuid" for i in ids)
    out.append(f"""
-- Stamp research recency. The coverage tracker computes `researched` from this column, so answers
-- without it show as 0 researched on the dashboard despite existing.
UPDATE essentials.politicians
   SET last_stances_researched_at = now()
 WHERE id IN ({idlist})
   AND last_stances_researched_at IS NULL;

-- Post-verify gate.
DO $$
DECLARE ans int; ctx int; unsourced int;
BEGIN
  SELECT count(*) INTO ans FROM inform.politician_answers
   WHERE (politician_id, topic_id) IN (VALUES {', '.join(f"('{x['politician_id']}'::uuid,'{x['topic_id']}'::uuid)" for x in rows)});
  IF ans <> {len(rows)} THEN
    RAISE EXCEPTION 'push wave 1: expected {len(rows)} answers, found %', ans;
  END IF;

  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (VALUES {', '.join(f"('{x['politician_id']}'::uuid,'{x['topic_id']}'::uuid)" for x in rows)});
  IF ctx <> {len(rows)} THEN
    RAISE EXCEPTION 'push wave 1: expected {len(rows)} context rows, found %', ctx;
  END IF;

  -- Every answer in this wave must have a paired context row whose first source is a URL.
  SELECT count(*) INTO unsourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context c
      ON c.politician_id = pa.politician_id AND c.topic_id = pa.topic_id
   WHERE (pa.politician_id, pa.topic_id) IN (VALUES {', '.join(f"('{x['politician_id']}'::uuid,'{x['topic_id']}'::uuid)" for x in rows)})
     AND (c.politician_id IS NULL OR c.sources[1] IS NULL OR c.sources[1] NOT LIKE 'http%');
  IF unsourced <> 0 THEN
    RAISE EXCEPTION 'push wave 1: % answer(s) lack a sourced context row', unsourced;
  END IF;
END $$;

COMMIT;""")

    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out) + '\n')
    cr = len([r for r in rows if r['topic_key'] == 'civil-rights'])
    dc = len([r for r in rows if r['topic_key'] == 'data-centers'])
    print(f'wrote {OUT}')
    print(f'  {len(rows)} rows ({cr} civil-rights, {dc} data-centers) across {len(ids)} legislators')


if __name__ == '__main__':
    main()
