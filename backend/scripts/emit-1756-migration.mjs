// Compose an honest documented blank for each MD orphan and emit migration 1756.
//
// 🔴 WHAT MAKES THIS LEGITIMATE RATHER THAN GAMING THE GATE. The carve-out fires on a leading
// "Researched YYYY-MM-DD", so prefixing that date to a row that still asserts a position would exempt a
// row nobody should exempt -- the carve-out would become a way to hide characterisations instead of a
// way to recognise honest blanks. The prefix is only earned here because the looking is ON THE RECORD:
// migrations 1731/1732/1734/1736 read every candidate bill behind these rows (counts per row below,
// ~2,765 in the 1736 pass alone) and recorded why each failed. This script transcribes an adjudicated
// finding into the row it belongs to. It refuses to emit a row it cannot ground.
//
// The old prose is what makes these dangerous: "Harris represents a district with significant immigrant
// communities. He supports immigrant protections" infers a position from DISTRICT DEMOGRAPHICS, and
// "Rosapepe ... As a former Democratic leader, he strongly backs voter access" is a PARTY prior --
// the attribute-prior class migration 1521 retired. Assign a chair to any of these pairs and
// Citations.jsx publishes that sentence verbatim under "Why this position?".
import { readFileSync, writeFileSync } from 'node:fs';

const g = JSON.parse(readFileSync('data/stance-retirement/2026-08-14-md-orphan-grounding.json', 'utf8'));
if (g.unmatched.length) throw new Error(`${g.unmatched.length} MD orphan(s) are ungrounded — refusing`);

// 1734 recorded counts per row but reasons only in its header, and only for the three rows where the
// member's OWN record pushes back. Those three get the specific finding; the rest get 1734's general
// one, which is a true statement about what the reading found, not a guess about why.
const WHY_1734 = {
  // Arthur Ellis / Environmental Protection vs. Development
  '4754dede-4a3b-4280-a8b1-7497530107f7|1935979c-b290-42e4-baa5-8cb0138b4ffa':
    'counter-evidence rather than absence — a plausible co-sponsored candidate (SB0203, 2019, no-net-loss at 40%) is outweighed by the lead bill SB0663 (2021), which EXEMPTS Charles County cemeteries from sediment control, stormwater management and forest conservation, the opposite of requiring developers to fully offset environmental impact',
  // William C. Smith, Jr. / Criminal Justice
  'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc|9db07b16-1076-4b7d-ad89-ebe7b51f4336':
    'the record fails the must-beat-every-rival test rather than lacking evidence — the lead restorative bill SB0766 (2019) states discipline’s purpose is "rehabilitative, restorative, AND educational", so it cannot pick this chair over its neighbour',
  // Alonzo T. Washington / Economic Development Incentives
  '8c8b0896-dfd0-4d3c-8492-e594d93b78ca|eb3d1247-0de1-4b7f-baec-7259861efd53':
    'targeted incentives for specific industries are richly evidenced (One Maryland credits, RISE zones, the Aerospace Commission, all LEAD), but nothing evidences the community-benefit or job-quality clause, leaving this chair tied with its neighbour',
};
const GENERAL_1734 = 'nothing in that record describes the seated chair';

// The recorded findings are transcribed verbatim except here: 1732's note for Rosapepe carries a
// gendered pronoun. These rows are voter-facing, and nothing in the corpus states this person's
// pronouns, so the possessive is dropped rather than carried forward. The finding is unchanged.
const PRONOUN_FREE = {
  '9c400214-f007-4a8d-92fe-5f5d23b3838e|d1792200-1d3b-4955-a0b7-0e6980d7a7b2': (w) =>
    w.replace('his Universal Voter Registration Act', 'the Universal Voter Registration Act'),
};

const DATE = '2026-08-12';
// The gate's own carve-out predicates, transcribed. A composed string that fails either one would leave
// the row in the cohort -- the wording bug that put Kim/Taxes back in the queue on 2026-08-07.
const CARVE_DATE = /^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}/i;
const CARVE_PROSE = /no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)/i;

const out = [];
for (const m of g.matched) {
  const key = `${m.politician_id}|${m.topic_id}`;
  let why = m.why ?? WHY_1734[key] ?? (m.mig === '1734' ? GENERAL_1734 : null);
  if (why && PRONOUN_FREE[key]) {
    const fixed = PRONOUN_FREE[key](why);
    if (fixed === why) throw new Error(`pronoun rewrite for ${m.name} matched nothing — recorded text changed`);
    why = fixed;
  }
  if (!why) throw new Error(`no grounded reason for ${m.name} / ${m.topic} (mig ${m.mig}) — refusing`);
  if (m.candidates_read == null) throw new Error(`no candidates_read for ${m.name} / ${m.topic} — refusing`);

  const n = m.candidates_read;
  const reasoning =
    `Researched ${DATE} — ${n} candidate bill${n === 1 ? '' : 's'} read from the complete Maryland ` +
    `General Assembly sponsorship record: ${why}. No scorable public record was found for this chair.`;

  if (!CARVE_DATE.test(reasoning) || !CARVE_PROSE.test(reasoning)) {
    throw new Error(`composed text would still be counted by the gate: ${m.name} / ${m.topic}`);
  }
  out.push({ ...m, new_reasoning: reasoning });
}

if (out.length !== g.n_orphans) throw new Error(`composed ${out.length}, expected ${g.n_orphans}`);

// Dollar-quoted so the recorded findings can keep their real quotes and apostrophes. Storing a doubled
// apostrophe instead of a real quote mark is how the extractor silently loses a quotation.
const values = out
  .map((r) => `  ('${r.politician_id}','${r.topic_id}',$md$${r.new_reasoning}$md$)`)
  .join(',\n');

const sql = `-- 1756_md_orphan_context_blanks.sql
-- The Maryland reasoning left behind when 1731/1732/1734/1736 blanked the answers.
--
-- 🔴 THESE ARE NOT HONEST BLANKS AND THAT IS THE POINT. The answers were correctly deleted -- the
-- record did not place these people -- but the prose stayed, and the prose still ASSERTS a position:
--   · "Harris represents a district with significant immigrant communities. He supports immigrant
--     protections" -- a position inferred from DISTRICT DEMOGRAPHICS.
--   · "Rosapepe served as US Ambassador to Romania ... He supports US assistance to Ukraine" -- a
--     BIOGRAPHY prior. "As a former Democratic leader, he strongly backs voter access" -- a PARTY prior,
--     the class flagged as still-open since 2026-08-01 and never worked.
--   · Economic Development Incentives is 10 near-identical sentences with the county name swapped;
--     Taxes is 11 more. Template output, no instrument, no source for the claim.
-- That is the attribute-prior class migration 1521 retired. Assign a chair to any of these pairs and
-- Citations.jsx publishes the sentence verbatim under "Why this position?".
--
-- 🔑 WHY A BLANK IS EARNED HERE AND WAS NOT EARNED FOR THE JUDICIAL COHORT (mig 1755). There the
-- question did not apply to the subject at all, so writing "we looked and found nothing" would have
-- asserted an untested absence. Here the topics genuinely apply -- a Maryland legislator can hold a
-- position on Taxes or Immigration -- and the looking is ON THE RECORD: 1736 read every candidate
-- behind its rows (~2,765 titles), 1734 read 1,471 unique titles across its non-judicial rows, and
-- both recorded the count per row. Same gate, same shape, opposite remedy.
--
-- ⚠ THE CARVE-OUT IS EARNED BY TRUTH, NOT BY WORDING. The gate exempts a leading "Researched
-- YYYY-MM-DD", so this prefix could exempt anything. It is used only because each row carries a count
-- of what was read and a reason it failed, taken from the migration that blanked it -- per-row where
-- 1731/1732/1736 recorded one, and from 1734's header for the three rows whose own record pushes back.
-- Nothing here is a fresh judgement about a politician.
--
-- 🔑 MAGNITUDE IS THE SINGLE BIGGEST GROUP, AND IT IS A REAL FINDING, NOT A GAP. Every Taxation row
-- sits at chair 2 -- "MODERATELY raise taxes ... to fund EXISTING services" -- which differs from chair
-- 1 only in degree. Alonzo Washington LEADS the Digital Advertising Gross Revenues tax (HB0695, 2020);
-- Kagan co-sponsored carried-interest repeal and the Corporate Tax Fairness Act. Every one proves
-- DIRECTION and not one can prove "moderately". A bill citation proves direction, never magnitude.
--
-- ▶ OWED, recorded so it is not lost with the prose: four rows are RE-SEAT candidates whose own record
-- points at a different chair -- Rosapepe / Voting Rights (the Universal Voter Registration Act is
-- chair 1's language), and 1736's Hester / AI Oversight, Kramer / Medicare-Medicaid and Kagan /
-- Campaign Finance. Moving a chair is a decision, not a re-sourcing. The blanks below say the seated
-- chair is unevidenced; they do not say the person has no view.
--
-- SOURCES ARE NOT TOUCHED. They record what was checked, which is exactly what a documented blank
-- should cite -- the same shape as the 80 cited blanks the gate already carves out.
--
-- Rollback: data/stance-retirement/2026-08-14-md-orphan-context-1756-rollback.json
BEGIN;

CREATE TEMP TABLE mob_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE mob_new (pid uuid, tid uuid, reasoning text) ON COMMIT DROP;
INSERT INTO mob_new VALUES
${values};

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mob_new;
  IF n <> ${out.length} THEN RAISE EXCEPTION 'pre-check: % rows, expected ${out.length}', n; END IF;

  -- Every target must still exist AND still be an orphan. If one acquired an answer since the grounding
  -- was captured, someone has since decided the record DOES place them, and overwriting their reasoning
  -- with a blank would contradict a live published chair.
  SELECT count(*) INTO n FROM mob_new m
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=m.pid AND c.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) no longer exist', n; END IF;

  SELECT count(*) INTO n FROM mob_new m
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=m.pid AND a.topic_id=m.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) acquired an answer since capture', n; END IF;
END $$;

UPDATE inform.politician_context c
   SET reasoning = m.reasoning
  FROM mob_new m
 WHERE c.politician_id = m.pid AND c.topic_id = m.tid;

-- Guard 1: nothing was created or destroyed. This pass rewrites text and touches nothing else.
DO $$
DECLARE ctx_after int; ans_after int; s record;
BEGIN
  SELECT * INTO s FROM mob_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1: context moved % -> %', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers moved % -> %', s.ans_before, ans_after; END IF;
END $$;

-- Guard 2: every rewritten row now reads as a documented blank under BOTH of the gate's carve-out
-- predicates, and every one kept its sources. A blank with no citation of what was checked is a worse
-- row than the one it replaced.
DO $$
DECLARE not_blank int; lost_sources int;
BEGIN
  SELECT count(*) INTO not_blank FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE c.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}';
  IF not_blank > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) miss the date carve-out', not_blank; END IF;

  SELECT count(*) INTO not_blank FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE c.reasoning !~* 'no scorable';
  IF not_blank > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) miss the prose carve-out', not_blank; END IF;

  SELECT count(*) INTO lost_sources FROM inform.politician_context c JOIN mob_new m
    ON m.pid=c.politician_id AND m.tid=c.topic_id
   WHERE coalesce(cardinality(c.sources),0) = 0;
  IF lost_sources > 0 THEN RAISE EXCEPTION 'guard 2: % row(s) lost their sources', lost_sources; END IF;
END $$;

-- Guard 3: Maryland is now clear of gate-visible orphans, and no answer anywhere lost its context.
DO $$
DECLARE md_left int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO md_left
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
    LEFT JOIN LATERAL (
      SELECT ofc.representing_state, d.state FROM essentials.office_current_holder och
        JOIN essentials.offices ofc ON ofc.id = och.office_id
        LEFT JOIN essentials.districts d ON d.id = ofc.district_id
       WHERE och.politician_id = pc.politician_id ORDER BY ofc.title LIMIT 1) seat ON true
    LEFT JOIN LATERAL (
      SELECT lower(e.state::text) AS state FROM essentials.race_candidates rc
        JOIN essentials.races r ON r.id = rc.race_id
        JOIN essentials.elections e ON e.id = r.election_id
       WHERE rc.politician_id = pc.politician_id AND rc.candidate_status = 'active'
       ORDER BY e.election_date DESC LIMIT 1) cand ON true
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
     AND lower(coalesce(seat.state, seat.representing_state, cand.state, '')) = 'md';
  IF md_left <> 0 THEN RAISE EXCEPTION 'guard 3: % MD orphan(s) remain', md_left; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) now have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'md orphan blanks: ${out.length} rewritten, 0 MD orphans left';
END $$;

COMMIT;
`;

writeFileSync('migrations/1756_md_orphan_context_blanks.sql', sql);
writeFileSync(
  'data/stance-retirement/2026-08-14-md-orphan-context-1756-rollback.json',
  JSON.stringify(
    {
      pass: 'MD orphan context — attribute-prior characterisations rewritten as documented blanks',
      migration: '1756_md_orphan_context_blanks.sql',
      note:
        'reasoning REPLACED, sources untouched, no answer created or deleted. prior_reasoning is ' +
        'verbatim; restoring is an UPDATE from this file. Each new text carries the count of candidate ' +
        'bills read and the reason recorded by the migration that blanked the answer.',
      n_rows: out.length,
      rows: out.map((r) => ({
        politician_id: r.politician_id,
        topic_id: r.topic_id,
        name: r.name,
        topic: r.topic,
        blanked_by: r.mig,
        candidates_read: r.candidates_read,
        prior_reasoning: r.reasoning,
        new_reasoning: r.new_reasoning,
        sources: r.sources,
      })),
    },
    null,
    1,
  ),
);

console.log(`emitted 1756 with ${out.length} rewrites\n`);
for (const r of out) console.log(`${r.name} — ${r.topic}\n  ${r.new_reasoning}\n`);
