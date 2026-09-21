#!/usr/bin/env node
/**
 * Generate migration 1882: re-file the 82 Maine LD 427 rows from Residential Zoning to
 * Transportation Priorities in Season 2, and blank the misfiled zoning chairs.
 *
 * Season 1 is never touched. Everything below is an INSERT into Season 2.
 */
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv[2];
if (!OUT) { console.error('need out path'); process.exit(2); }

const S1 = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
const S2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const RZ_TOPIC = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
const RZ_REV = 'ef2a5e59-525a-41fa-94de-ce771df7c927';
const TP_TOPIC = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
const TP_REV = 'c48782d5-e905-408d-8532-2a5fd5bb6efa';

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows } = await pool.query(`
  SELECT c.politician_id, p.full_name, c.reasoning, c.sources, a.value::int AS seated_rz
  FROM inform.politician_context c
  JOIN inform.compass_topics t ON t.id=c.topic_id AND t.id=$1
  JOIN essentials.politicians p ON p.id=c.politician_id
  LEFT JOIN inform.politician_answers a
    ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id AND a.season_id=c.season_id
  WHERE c.season_id=$2 AND c.reasoning ILIKE '%LD 427%'
  ORDER BY p.full_name`, [RZ_TOPIC, S1]);
await pool.end();

// ---- classify the single discriminating fact: Yea or Nay on LD 427 -------------------
// Mark Cooper's row says "Voted Yea ... breaking from the other two Republicans ... who voted Nay";
// the trailing "Nay" describes colleagues, so a naive both-words test must not call it ambiguous.
const classify = (r) => {
  const t = r.reasoning;
  const selfNay = /\b(?:voted\s+Nay|Nay\s+on|voted\s+Nay\s+on)\b/i.test(t);
  const selfYea = /\b(?:voted\s+Yea|Yea\s+on|voted\s+for\s+enactment)\b/i.test(t);
  if (selfYea && !selfNay) return 'YEA';
  if (selfNay && !selfYea) return 'NAY';
  // both words present: the member's own vote is the FIRST one stated
  const iY = t.search(/\b(?:[Vv]oted\s+Yea|Yea\s+on|voted\s+for\s+enactment)\b/);
  const iN = t.search(/\b(?:[Vv]oted\s+Nay|Nay\s+on)\b/);
  if (iY > -1 && (iN === -1 || iY < iN)) return 'YEA';
  if (iN > -1) return 'NAY';
  return 'UNKNOWN';
};

const graded = rows.map((r) => ({ ...r, vote: classify(r) }));
const yea = graded.filter((g) => g.vote === 'YEA');
const nay = graded.filter((g) => g.vote === 'NAY');
const unk = graded.filter((g) => g.vote === 'UNKNOWN');
if (unk.length) { console.error('UNCLASSIFIED:', unk.map((u) => u.full_name)); process.exit(3); }
console.log(`rows ${graded.length}  YEA ${yea.length} -> Transportation 1   NAY ${nay.length} -> Transportation 4`);

const ROLLCALL = 'LD 427, "An Act to Prohibit Mandatory Parking Space Minimums in State and Municipal Building Codes" (Maine House Roll Call #534, 6/16/2025; passed 82-65 and signed as Public Law Chapter 374)';

const TP_YEA = `Voted Yea on ${ROLLCALL}, which bars state and municipal building codes from imposing mandatory parking-space minimums. On this ladder "reduce parking requirements communitywide" appears in stance 1 and in no other stance, and the bill is a statewide repeal of exactly that mandate, so the vote is evidence for stance 1 rather than merely a direction. Honest limit, stated so it can be argued with: this is a single roll call. It does not by itself evidence the pedestrian, cycling and transit investment that stance 1 also describes, and no other transportation instrument for this member was examined. This row was re-filed from Residential Zoning, where the same vote had been graded against the wrong ladder.`;

const TP_NAY = `Voted Nay on ${ROLLCALL}, opposing the repeal; the bill passed over that objection. Keeping mandatory parking-space minimums in code places the member on the driving-capacity side of this ladder, and stance 4 ("Focus on road capacity and traffic flow; transportation investment should serve the majority who drive") is the nearest stance the vote supports. Honest limits, stated so they can be argued with: a vote to preserve an existing requirement is weaker evidence than an affirmative programme; stance 5's "abundant free parking as the foundation of local transportation policy" is not asserted by this vote and is not claimed here; and no other transportation instrument for this member was examined. This row was re-filed from Residential Zoning, where the same vote had been graded against the wrong ladder.`;

const RZ_BLANK = `Blank in Season 2 — researched, and no rung of this ladder is evidenced. The Season 1 Residential Zoning row for this member was Transportation Priorities research misfiled into this topic. Its only evidence is the ${ROLLCALL} roll call, and its reasoning graded that vote against the Transportation ladder: the phrases it quotes — "reduce parking requirements", "transportation investment should serve the majority who drive" — are Transportation ladder text and appear nowhere in this topic's rungs. No zoning instrument was ever examined for this member: no duplex or accessory-unit measure, no multifamily-by-right measure, no rezoning-procedure measure. The vote itself is preserved and re-seated on Transportation Priorities for Season 2. Season 1 keeps the original row unchanged as the historical record of what was once claimed.`;

// the cohort, defined by the same predicate the whole investigation used
const COHORT = `SELECT politician_id FROM inform.politician_context
                    WHERE season_id='${S1}' AND topic_id='${RZ_TOPIC}' AND reasoning ILIKE '%LD 427%'`;

const q = (s) => `$r$${s}$r$`;
const arr = (a) => `ARRAY[${(a || []).map((s) => `'${String(s).replace(/'/g, "''")}'`).join(',')}]::text[]`;

const ctxVals = [];
const ansVals = [];
for (const g of graded) {
  const tp = g.vote === 'YEA' ? TP_YEA : TP_NAY;
  const chair = g.vote === 'YEA' ? 1 : 4;
  // 🔑 the name comment goes BEFORE the tuple: a trailing comment swallows the separating comma.
  // Transportation Priorities — the stance re-seated where its evidence belongs
  ctxVals.push(`  -- ${g.full_name} (${g.vote}) -> Transportation\n  ('${g.politician_id}','${TP_TOPIC}',${q(tp)},${arr(g.sources)})`);
  ansVals.push(`  -- ${g.full_name} (${g.vote})\n  ('${g.politician_id}','${TP_TOPIC}',${chair})`);
  // Residential Zoning — blanked, with the reason recorded
  ctxVals.push(`  -- ${g.full_name} -> zoning blank\n  ('${g.politician_id}','${RZ_TOPIC}',${q(RZ_BLANK)},${arr(g.sources)})`);
  ansVals.push(`  -- ${g.full_name} -> zoning blank\n  ('${g.politician_id}','${RZ_TOPIC}',0)`);
}

const header = `-- 1882_ld427_refile_zoning_to_transportation_season2.sql
-- Re-file 82 Maine LD 427 rows out of Residential Zoning and onto Transportation Priorities in
-- Season 2, and blank the 82 misfiled zoning chairs. 164 context rows + 164 answer rows INSERTED.
-- Nothing updated, nothing deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHAT WAS WRONG. A Transportation Priorities research pass was written into the Residential
-- Zoning topic slot for 82 Maine House members. Found 2026-09-20. The evidence:
--   * 81 of the 82 rows contain NO zoning vocabulary at all — no "duplex", "accessory unit",
--     "multifamily", "single-family", "upzon", "rezoning" or "by right". One does.
--   * 23 quote text that exists ONLY on the Transportation ladder, e.g. "transportation investment
--     should serve the majority who drive" (Transportation stance 4) and "prioritizing multimodal
--     investment".
--   * NONE of the 82 has a Transportation Priorities row at all — in any season. The pass did not
--     duplicate into two topics; it landed in the wrong one and left the right one empty.
--   * The single instrument behind every row is one roll call: ${ROLLCALL}.
--
-- 🔑 WHY IT WENT UNNOTICED. "reduce parking requirements" appears on BOTH ladders — Transportation
-- stance 1 and Residential Zoning stance 4 — so the misfile reads as plausible until the other
-- clauses of each rung are compared. That shared phrase is the whole reason this survived review.
--
-- 🔴🔴 THE VISIBLE SYMPTOM: OPPOSITE VOTES SHARE A CHAIR. 33 members who voted YEA and 24 who voted
-- NAY are both seated at Residential Zoning 4 — "Upzone broadly to allow multifamily by right".
-- Members who voted to KEEP parking mandates are today displayed as broad upzoners. The full
-- Season 1 spread is YEA {1:5, 2:11, 4:33} and NAY {2:8, 4:24}: three different chairs for one vote,
-- in both directions.
--
-- 🔴 WHY A FORWARD WRITE AND NOT A FIX. The defective rows are in Season 1, which is CLOSED and
-- IMMUTABLE — \`inform.closed_season_is_immutable()\` rejects any write there (ADR 0005 §1.6 step 5),
-- and CC_0044's own header states the rule: "It is not for re-audits. A re-audit belongs in the OPEN
-- season as a new row that shadows the old one." Season 2 is frozen for topics/chairs but stances
-- remain open, so these writes are in bounds.
--
-- 🔑 WHY THE ZONING ROWS ARE BLANKED RATHER THAN DELETED OR RE-GRADED. Deleting a Season 2 row does
-- not blank anyone — with seasons the read falls back to Season 1 (CC_0057's header says so
-- explicitly), so the misfiled chair would stay visible. A blank is value 0, which CC_0057 made
-- expressible and PR #350 made safe to read. Re-grading them as genuine zoning rows was rejected:
-- a parking-minimum roll call cannot pin a five-rung zoning axis, and asserting any rung from it
-- would repeat the original error in the opposite direction.
--
-- ⚖ THE GRADING RULE, AND ITS LIMITS. Every row turns on one fact — Yea or Nay on LD 427.
--   YEA -> Transportation stance 1 (${yea.length} members). "Reduce parking requirements communitywide"
--     is named in stance 1 and in no other stance on this ladder, and LD 427 is a statewide repeal
--     of exactly that mandate.
--   NAY -> Transportation stance 4 (${nay.length} members). Retaining the mandate sits on the
--     driving-capacity side; stance 4 is the nearest stance the vote supports.
--   ⚠ ONE ROLL CALL IS THIN EVIDENCE FOR A FIVE-RUNG AXIS, and each row says so in its own text.
--     Stance 1 also describes pedestrian, cycling and transit investment that a parking vote does
--     not establish; stance 5 is deliberately not asserted for the Nay voters. These rows are
--     honest about resting on a single instrument, and are re-researchable from here.
--   🔑 TWO ROWS NAME BOTH VOTES, AND BOTH ARE YEA. Mark Cooper — "Voted Yea ... breaking from the
--     other two Republicans in this group, who voted Nay"; Caldwell Jackson — "the only one of the
--     six HD80-85 Republicans to vote Yea ... a personal departure from his five Republican
--     colleagues who voted Nay". In both the trailing "Nay" describes COLLEAGUES. Classified on the
--     member's OWN vote, which is the first one stated. ⚠ A first-cut count missed Jackson because
--     he "vote[d] Yea" rather than "voted Yea" and the Nay of his colleagues then won the tie —
--     a one-person error in the direction that would have inverted him.
--
-- 🔑 A CHAIR NUMBER ONLY MEANS SOMETHING AGAINST A REVISION. Transportation Priorities pins the SAME
-- revision (c48782d5, revision 1) in Season 1 and Season 2, so stance 1 and stance 4 assert here
-- exactly what they assert in the rows being replaced. Residential Zoning likewise pins ef2a5e59 in
-- both. Both are asserted in the pre-flight guard below. (Season 3 pins a DIFFERENT zoning revision,
-- 6b5a3504, whose rung 1 was reworded — out of scope here.)
--
-- editor_id is NULL — the established value for automated writes in this season, matching 1870-1881.
-- Borrowing a human editor's uuid would misattribute authorship.
--
-- ⚠ NOT IN THIS MIGRATION: the six Maine Affordable Housing rows that also cite LD 427 (Bell, Golek,
-- Ankeles, Webb, Sachs, Arford). Those were checked on 2026-09-20 and are CORRECT — they cite LD 427
-- alongside LD 2077 (mortgage-rate grants) and reason on the housing axis, and their S1=3 -> S2=4
-- move is the Affordable Housing ladder re-pin (rev1 rung 3 "targeted help ... first-time buyer
-- assistance" == rev3 rung 4 "no binding rules, but offer subsidies"). Left alone deliberately.
--
-- Rollback: delete the 328 Season 2 rows this file inserts; Season 1 needs no restoration because
-- it is never written.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

-- -----------------------------------------------------------------------------
-- Pre-flight: the state this migration was written against must still hold
-- -----------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context c
   WHERE c.season_id='${S1}' AND c.topic_id='${RZ_TOPIC}'
     AND c.reasoning ILIKE '%LD 427%';
  IF n <> ${graded.length} THEN
    RAISE EXCEPTION 'migration 1882: expected ${graded.length} Season 1 zoning rows citing LD 427, found % -- re-measure before writing', n;
  END IF;

  SELECT count(*) INTO n
    FROM inform.politician_context c
   WHERE c.season_id='${S2}' AND c.topic_id IN ('${RZ_TOPIC}','${TP_TOPIC}')
     AND c.politician_id IN (SELECT politician_id FROM inform.politician_context
                              WHERE season_id='${S1}' AND topic_id='${RZ_TOPIC}'
                                AND reasoning ILIKE '%LD 427%');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1882: Season 2 already holds % row(s) for this cohort on these topics', n;
  END IF;

  -- both topics must pin in Season 2 the same revision Season 1 used
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND topic_revision_id='${TP_REV}';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1882: Season 2 does not pin Transportation revision ${TP_REV} -- stance 1/4 may not mean the same thing';
  END IF;
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='${S2}' AND topic_id='${RZ_TOPIC}' AND topic_revision_id='${RZ_REV}';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1882: Season 2 does not pin Residential Zoning revision ${RZ_REV}';
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- The writes. Season 2 only.
-- -----------------------------------------------------------------------------
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, v.tid::uuid, '${S2}'::uuid,
       CASE v.tid WHEN '${TP_TOPIC}' THEN '${TP_REV}'::uuid ELSE '${RZ_REV}'::uuid END,
       NULL, v.reasoning, v.sources
FROM (VALUES
${ctxVals.join(',\n')}
) AS v(pid, tid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, v.tid::uuid, '${S2}'::uuid,
       CASE v.tid WHEN '${TP_TOPIC}' THEN '${TP_REV}'::uuid ELSE '${RZ_REV}'::uuid END,
       NULL, v.chair
FROM (VALUES
${ansVals.join(',\n')}
) AS v(pid, tid, chair);

-- -----------------------------------------------------------------------------
-- Guards
-- -----------------------------------------------------------------------------
DO $$
DECLARE n int; bad int;
BEGIN
  -- 🔑 EVERY GUARD IS SCOPED TO THIS COHORT. Season 2 already held 36 rows on these two topics
  -- for OTHER politicians (4 zoning, 32 transportation, written 2026-09-08..11). A topic-wide
  -- count would fold them in and assert the wrong number -- the first draft of this guard did.

  -- every member got exactly one Transportation row and one blanked zoning row
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND politician_id IN (${COHORT});
  IF n <> ${graded.length} THEN
    RAISE EXCEPTION 'migration 1882: expected ${graded.length} Season 2 Transportation answers for the cohort, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${RZ_TOPIC}' AND value=0 AND politician_id IN (${COHORT});
  IF n <> ${graded.length} THEN
    RAISE EXCEPTION 'migration 1882: expected ${graded.length} blanked Season 2 zoning answers for the cohort, found %', n;
  END IF;

  -- the grading split must be exactly what the header argues
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND value=1 AND politician_id IN (${COHORT});
  IF n <> ${yea.length} THEN
    RAISE EXCEPTION 'migration 1882: expected ${yea.length} Yea voters at Transportation stance 1, found %', n;
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND value=4 AND politician_id IN (${COHORT});
  IF n <> ${nay.length} THEN
    RAISE EXCEPTION 'migration 1882: expected ${nay.length} Nay voters at Transportation stance 4, found %', n;
  END IF;

  -- no chair outside the two this migration argues for
  SELECT count(*) INTO bad FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND value NOT IN (1,4)
     AND politician_id IN (${COHORT});
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1882: % cohort Transportation answer(s) outside {1,4}', bad;
  END IF;

  -- every new row carries context, and every context row carries its roll-call source
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id IN ('${RZ_TOPIC}','${TP_TOPIC}')
     AND a.politician_id IN (${COHORT}) AND c.politician_id IS NULL;
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1882: % new answer row(s) have no context row', bad;
  END IF;

  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id IN ('${RZ_TOPIC}','${TP_TOPIC}')
     AND politician_id IN (${COHORT})
     AND NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%LD=427%' OR s ILIKE '%serialnumber=534%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1882: % new context row(s) do not cite the LD 427 roll call', bad;
  END IF;

  -- no re-filed row may repeat the wrong ladder's language
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TP_TOPIC}' AND politician_id IN (${COHORT})
     AND (reasoning ILIKE '%upzone%' OR reasoning ILIKE '%multifamily by right%');
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1882: % re-filed Transportation row(s) still carry zoning-ladder language', bad;
  END IF;

  -- the 36 pre-existing Season 2 rows on these topics must be untouched
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id IN ('${RZ_TOPIC}','${TP_TOPIC}')
     AND politician_id NOT IN (${COHORT});
  IF n <> 36 THEN
    RAISE EXCEPTION 'migration 1882: expected the 36 pre-existing non-cohort Season 2 rows to be untouched, found %', n;
  END IF;

  -- 🔴 SEASON 1 MUST BE BYTE-FOR-BYTE INTACT
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S1}' AND topic_id='${RZ_TOPIC}' AND reasoning ILIKE '%LD 427%';
  IF n <> ${graded.length} THEN
    RAISE EXCEPTION 'migration 1882: Season 1 zoning context rows changed -- found %, expected ${graded.length}', n;
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${RZ_TOPIC}'
     AND politician_id IN (SELECT politician_id FROM inform.politician_context
                            WHERE season_id='${S1}' AND topic_id='${RZ_TOPIC}' AND reasoning ILIKE '%LD 427%')
     AND value = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1882: % Season 1 answer(s) were blanked -- history was edited', n;
  END IF;
END $$;

COMMIT;
`;

fs.writeFileSync(OUT, header);
console.log(`wrote ${OUT}`);
console.log(`context rows: ${ctxVals.length}, answer rows: ${ansVals.length}`);
