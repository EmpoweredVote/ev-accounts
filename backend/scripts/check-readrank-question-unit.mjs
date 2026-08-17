#!/usr/bin/env node
/**
 * Fail if any race/topic pair serves quotes for MORE THAN ONE question.
 *
 * WHY THIS EXISTS. Migration 1377 made the QUESTION the unit of comparison in Read & Rank, and one
 * topic can legitimately host several questions — LA Mayor's economic-development topic hosts a
 * film/TV question and a downtown question. The player path did not follow: getRaceBlindQuotes
 * bucketed by lower(topic_key), so two questions in one topic merged into a single card that paired
 * answers to DIFFERENT questions under whichever question text arrived first (the ORDER BY was on
 * topic title, leaving intra-topic row order unspecified). getPlayableRaces made the same mistake
 * in reverse, counting the merged pair as one rankable unit.
 *
 * Both are fixed. This guard exists because NOTHING IN THE SCHEMA CAN EXPRESS THE INVARIANT.
 * migration 293's partial unique index was keyed (politician_id, lower(topic_key)) — it blocked one
 * candidate holding two selected quotes in a topic, but candidate A on question 1 plus candidate B
 * on question 2 satisfied it and still corrupted the card. 1820 re-keyed that index to
 * (politician_id, question_id), which is correct for the new model and deliberately permits two
 * questions in one topic. So the remaining risk is a state no constraint rejects.
 *
 * 🔴 WHAT THIS ACTUALLY PROTECTS TODAY. The backend is question-keyed, but the read-rank game
 * client (separate repo, src/store/useReadRankStore.ts) still builds progress as
 * `topics[t.topicKey] = {...}` — a Record keyed by topicKey. Two cards sharing a topicKey collide:
 * the second overwrites the first, topicOrder lists the key twice, and the player sees one question
 * rendered twice while the other's quotes are never shown. The payload now carries
 * `topics[].key` for the client to group on; until it does, a split topic must not go live.
 *
 * ZERO TOLERANCE, NO BASELINE FILE. The correct count is 0, and there is exactly one row in prod
 * that could ever produce a violation (LA Mayor general, economic-development, 3 questions — the
 * only race/topic pair of 2429 hosting more than one, measured 2026-08-17). A baseline would just
 * be somewhere for a real merged card to hide.
 *
 * MIRRORS THE PLAYER PATH, not the whole table: a quote only reaches a card if its candidate is a
 * live candidate in that race and its Compass topic is not retired. Flagging rows the game would
 * never serve would make this noisy and, worse, teachable-to-ignore.
 *
 * Needs a live DB, so like check:child-county this does NOT run on PRs — it runs on master pushes
 * and on the daily schedule (.github/workflows/ci.yml), and skips itself when DATABASE_URL is
 * absent (forks) rather than failing.
 *
 * Usage:
 *   node scripts/check-readrank-question-unit.mjs            # gate
 *   node scripts/check-readrank-question-unit.mjs --verbose  # list every question in each pair
 */
import 'dotenv/config';
import { Pool } from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Served = readrank_selected + deidentified_text present (the API never falls back to quote_text),
// candidate live in THIS race, Compass topic not retired. The is_live predicate sits in the WHERE,
// not the LEFT JOIN's ON clause: in the ON clause a retired topic would fail to match, yield
// ct.topic_key IS NULL, and survive as an "unknown" topic — inverting the kill switch. Same
// reasoning as readrankService.ts.
const VIOLATIONS_SQL = `
  WITH served AS (
    SELECT rq.race_id,
           rq.topic_key,
           rq.id            AS question_id,
           rq.question_text,
           count(DISTINCT q.politician_id) AS answering_candidates
      FROM essentials.readrank_questions rq
      JOIN essentials.quotes q
        ON q.question_id = rq.id
       AND q.readrank_selected
       AND q.deidentified_text IS NOT NULL
      JOIN essentials.race_candidates rc
        ON rc.race_id = rq.race_id
       AND rc.politician_id = q.politician_id
       AND essentials.is_live_candidate(rc.candidate_status, rc.result)
      LEFT JOIN inform.compass_topics ct
        ON ct.topic_key = lower(rq.topic_key)
     WHERE (ct.topic_key IS NULL OR ct.is_live = true)
     GROUP BY rq.race_id, rq.topic_key, rq.id, rq.question_text
  )
  SELECT s.race_id,
         s.topic_key,
         r.position_name,
         e.name AS election_name,
         count(*) AS n_questions,
         jsonb_agg(
           jsonb_build_object(
             'question_id', s.question_id,
             'question_text', s.question_text,
             'answering_candidates', s.answering_candidates
           ) ORDER BY s.question_text
         ) AS questions
    FROM served s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   GROUP BY s.race_id, s.topic_key, r.position_name, e.name
  HAVING count(*) > 1
   ORDER BY r.position_name, s.topic_key
`;

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const { rows } = await pool.query(VIOLATIONS_SQL);
  await pool.end();

  if (rows.length === 0) {
    console.log('Read & Rank question-unit OK — no race/topic pair serves quotes for more than one question.');
    process.exit(0);
  }

  console.error(
    `FAIL: ${rows.length} race/topic pair(s) serve quotes for more than one question.\n\n` +
    'The read-rank game client keys race progress by topicKey (useReadRankStore.ts:\n' +
    '`topics[t.topicKey] = {...}`), so two cards sharing a topicKey collide — one question is\n' +
    "rendered twice and the other's quotes are never shown.\n",
  );

  for (const row of rows) {
    console.error(`  ${row.position_name} — ${row.election_name}`);
    console.error(`    race ${row.race_id}  topic ${row.topic_key}  (${row.n_questions} questions serving)`);
    if (VERBOSE) {
      for (const q of row.questions) {
        console.error(
          `      ${q.question_id}  ${q.answering_candidates} candidate(s)  ${JSON.stringify(q.question_text)}`,
        );
      }
    }
  }

  console.error(
    '\nFIX — pick one:\n' +
    '  a. Unselect the quotes on all but one question in each pair (admin Read & Rank quotes page,\n' +
    '     per-question "Clear selection"). This is the right move if the split was accidental.\n' +
    '  b. Ship the read-rank client change first: group cards on the payload\'s `topics[].key`\n' +
    '     (question id, or `topic:<topic_key>` for compass-era rows) instead of `topicKey`, in\n' +
    '     buildRaceProgress/refreshRaceContent and anything reading BallotEntry.perTopic. Then\n' +
    '     relax this guard to match what the client can actually render.\n' +
    '\nBackground: .planning/todos/2026-08-17-readrank-question-as-unit-vs-topic.md\n' +
    '            backend/migrations/1820_readrank_one_selected_per_question.sql\n',
  );
  if (!VERBOSE) console.error('Re-run with --verbose to list each question and its answering candidates.\n');
  process.exit(1);
})().catch((err) => {
  console.error('check-readrank-question-unit failed:', err);
  process.exit(1);
});
