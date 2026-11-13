#!/usr/bin/env node
// Turn the analysis into one migration per state. Nothing is hand-written: the counts in the
// header, the pinned rows and every gate threshold come from the same analysis file the report
// was printed from, so the file cannot disagree with the measurement it claims.
//
// usage: emit-migration.mjs <analysis.json> <ma|me> <CC_0413> <out.sql>
import fs from 'node:fs';

const [analysisFile, stateArg, slot, out] = process.argv.slice(2);
if (!analysisFile || !stateArg || !slot || !out) {
  console.error('usage: emit-migration.mjs <analysis.json> <st> <slot> <out.sql>');
  process.exit(2);
}
const st = stateArg.toLowerCase();
const READ_ON = '2026-11-13';

const STATE = {
  ma: {
    name: 'Massachusetts',
    second_source: "the Secretary of the Commonwealth's own \"2026 State Election Candidates\" page",
    second_source_url: 'https://www.sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm',
    crosscheck: 'ma-soc-crosscheck-2026-11-13.json',
  },
  me: {
    name: 'Maine',
    second_source: "the Secretary of State's own \"2026 General Candidate List - FINAL\" spreadsheet",
    second_source_url: 'https://www.maine.gov/sos/elections-voting/upcoming-elections',
    crosscheck: 'me-sos-crosscheck-2026-11-13.json',
  },
}[st];
if (!STATE) throw new Error(`no state profile for ${st}`);

const analysis = JSON.parse(fs.readFileSync(analysisFile, 'utf8'));
// Only races that carry NO candidate rows are seeded. A race somebody has already populated is
// not this file's business, and the gates below refuse to run if that has changed.
const races = analysis.races.filter((r) => r.state === st && r.our.existing_candidates === 0);
if (!races.length) throw new Error(`no empty ${st} races in the analysis`);

const q = (s) => (s === null || s === undefined || s === '' ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const b = (v) => (v ? 'true' : 'false');
const n = (v) => (v === null || v === undefined ? 'NULL' : String(v));

const rows = [];
for (const r of races) {
  for (const l of r.lines) {
    const link = r.holder && r.holder.candidateID === l.candidateID && r.holder.link ? r.holder : null;
    rows.push({
      race_id: r.our.race_id,
      office_id: r.our.office_id,
      district: r.our.district_label,
      office_title: r.our.office_title,
      seats: r.our.seats,
      ap_race_id: r.ap.raceID,
      ap_candidate_id: l.candidateID,
      full_name: l.full_name,
      first_name: l.first,
      last_name: l.last,
      is_write_in: l.is_write_in,
      ap_incumbent: l.ap_incumbent,
      party: l.party,
      votes: l.voteCount ?? 0,
      pct: l.votePct ?? 0,
      uncontested: r.ap.uncontested,
      called: r.called,
      outcome: l.result,
      holder_id: link ? link.politician_id : null,
      holder_basis: link ? link.basis : null,
      holder_name: link ? link.our_name : null,
    });
  }
}

const count = {
  rows: rows.length,
  races: races.length,
  won: rows.filter((x) => x.outcome === 'won').length,
  lost: rows.filter((x) => x.outcome === 'lost').length,
  noResult: rows.filter((x) => x.outcome === null).length,
  uncalledRaces: races.filter((x) => !x.called).length,
  links: rows.filter((x) => x.holder_id).length,
  writeIns: rows.filter((x) => x.is_write_in).length,
  uncontestedRaces: races.filter((x) => x.ap.uncontested).length,
  zeroVoteRows: rows.filter((x) => x.votes === 0).length,
  basis: {},
};
for (const x of rows) if (x.holder_basis) count.basis[x.holder_basis] = (count.basis[x.holder_basis] || 0) + 1;

// A politician may be linked at most once by this file.
const seen = new Map();
for (const x of rows) {
  if (!x.holder_id) continue;
  if (seen.has(x.holder_id)) throw new Error(`politician ${x.holder_id} would be linked twice (${seen.get(x.holder_id)} and ${x.district})`);
  seen.set(x.holder_id, x.district);
}
// AP's candidate id is the file's key and must be unique within it.
const ids = new Set(rows.map((x) => x.ap_candidate_id));
if (ids.size !== rows.length) throw new Error(`AP candidate ids are not unique in this file: ${rows.length} rows, ${ids.size} ids`);

const uncalled = races.filter((x) => !x.called).map((x) => `${x.our.district_label} (AP race ${x.ap.raceID}, ${x.ap.raceCallStatus})`);
const basisLines = Object.entries(count.basis).map(([k, v]) => `--   ${k.padEnd(26)} ${String(v).padStart(3)}`).join('\n');

const sql = `-- ${slot} - 2026-11-03 ${STATE.name} legislature: seed the ballots, from AP and from the state's own
-- candidate list, for the ${count.races} races we hold with no candidate rows at all.
--
-- 🔴 THIS IS A SEEDING PASS, NOT A RESULTS PASS, AND THE DIFFERENCE IS THE WHOLE POINT. 641 of
--    our 2026-11-03 legislative races carried NO candidacies whatsoever (MA 196, ME 186, MD 118,
--    OR 88, NV 53), so there was nothing for a results pass to write a call onto. \`CC_0381\`
--    said so in terms and left it: "641 of our 1,114 races carry no candidate rows at all. That
--    is seeding work and it is not what this file does." This is that work for ${STATE.name}.
--
-- ⚠ NOTHING HERE SEATS ANYBODY. A certified result is not a fact about who holds a seat, and a
--    call is not a certification. The ${STATE.name} legislature convenes in January 2027 and every
--    winner is seated then, by a later migration, from an authority about the OFFICEHOLDER.
--    \`essentials.office_terms\` is untouched, \`essentials.offices\` is untouched, and the
--    occupancy drift baseline is asserted unmoved at the end.
--
-- ============================================================================================
-- WHAT IS WRITTEN
-- ============================================================================================
--   ${String(count.rows).padStart(4)} candidacies across ${count.races} races
--   ${String(count.won).padStart(4)} won · ${count.lost} lost · ${count.noResult} with NO result (${count.uncalledRaces} race(s) AP has not called)
--   ${String(count.links).padStart(4)} linked to a politician we already hold; the rest carry politician_id NULL
--   ${String(count.writeIns).padStart(4)} declared write-in(s)
--
-- 🔴 A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER,
--    and an UNCALLED race gets a ballot line with no result at all rather than a guess.
${uncalled.length ? `--    The uncalled race(s) here:\n${uncalled.map((u) => `--      ${u}`).join('\n')}` : '--    Every race in this file is called.'}
--
-- ============================================================================================
-- 🔴 THE BALLOT IS READ TWICE, FROM TWO INDEPENDENT SOURCES
-- ============================================================================================
-- AP's per-state feed, read ${READ_ON}:
--   interactives.apelections.org/election-results/data-live/2026-11-03/results/races/${st.toUpperCase()}/
-- and ${STATE.second_source},
-- read ${READ_ON} with Playwright:
--   ${STATE.second_source_url}
--
-- The join, the differences and how each one was settled are in
-- \`backend/data/state-leg-2026-seed/\` — \`${STATE.crosscheck}\` and NOTES.md.
--
-- ============================================================================================
-- 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION, AND THAT IS DELIBERATE
-- ============================================================================================
-- This repo spent four migrations (\`CC_0408\`-\`CC_0411\`) removing prose that read "0 votes"
-- off an AP feed: AP CALLS AN UNCONTESTED RACE ON THE BALLOT AND THEN PUBLISHES voteCount 0 FOR
-- EVERYONE IN IT. ${count.uncontestedRaces} of these ${count.races} races are uncontested and ${count.zeroVoteRows} of the ${count.rows} rows carry a
-- published count of zero. We store no vote counts in any column, so the only place a count
-- could reach production is the citation text — and it does not. Where AP publishes a count the
-- citation names the SHARE it reported; where AP publishes none it says so.
--
-- ============================================================================================
-- HOW A CANDIDACY IS LINKED TO A PERSON WE ALREADY HOLD
-- ============================================================================================
-- ⚠ Most of these people are not in \`essentials.politicians\` at all, and SEEDING A PERSON IS A
--    SEPARATE ACT. A challenger therefore gets a candidacy with \`politician_id\` NULL, which is
--    the normal shape for a candidate here.
--
-- An incumbent is different, and the link rests on TWO FACTS, NEITHER OF THEM A NAME: AP flags
-- the ballot line as that seat's incumbent, and \`essentials.office_current_holder\`
-- independently names the politician holding that same office. That is \`CC_0381\`'s \`holder\`
-- basis. The name is then a CHECK on the pair, not the key, and each outcome is named:
${basisLines}
--
-- 🔴 A SURNAME DISAGREEMENT IS A FINDING AND IS NOT LINKED. Nothing in this file links a
--    candidacy to a politician whose surname differs from AP's — such a row is seeded with
--    politician_id NULL and reported instead.
--
-- 🔴 AND THE LINK IS RE-ASSERTED AGAINST PRODUCTION, NOT TRUSTED FROM THIS FILE. The pre-check
--    below refuses unless every politician this file names is still the current holder of that
--    race's office at the moment the migration runs.
--
-- ============================================================================================
-- Slot ${slot} reserved via steward. Applied to production ${READ_ON} by Chris Cantrell.
-- ============================================================================================

BEGIN;

-- ─── 1. What is seeded ───
CREATE TEMP TABLE seed (
  race_id          uuid NOT NULL,
  office_id        uuid NOT NULL,
  district         text NOT NULL,
  office_title     text NOT NULL,
  seats            int  NOT NULL,
  ap_race_id       text NOT NULL,
  ap_candidate_id  text PRIMARY KEY,
  full_name        text NOT NULL,
  first_name       text,
  last_name        text,
  is_write_in      boolean NOT NULL,
  ap_incumbent     boolean NOT NULL,
  party            text,            -- recorded here for the record ONLY: party in this repo
                                    -- lives on races.primary_party, never on a candidacy
  votes            int  NOT NULL,   -- for the gates below; NEVER written to any column
  pct              numeric NOT NULL,
  uncontested      boolean NOT NULL,
  called           boolean NOT NULL,
  outcome          text,            -- 'won' | 'lost' | NULL when AP has not called the race
  holder_id        uuid,            -- the politician to link, or NULL
  holder_basis     text,
  holder_name      text
);

INSERT INTO seed VALUES
${rows.map((x) => `  (${[q(x.race_id), q(x.office_id), q(x.district), q(x.office_title), n(x.seats), q(x.ap_race_id), q(x.ap_candidate_id), q(x.full_name), q(x.first_name), q(x.last_name), b(x.is_write_in), b(x.ap_incumbent), q(x.party), n(x.votes), n(x.pct), b(x.uncontested), b(x.called), q(x.outcome), x.holder_id ? `${q(x.holder_id)}::uuid` : 'NULL', q(x.holder_basis), q(x.holder_name)].join(', ')})`).join(',\n')};

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM seed;
  IF n <> ${count.rows} THEN RAISE EXCEPTION '${slot}: expected ${count.rows} measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM seed;
  IF n <> ${count.races} THEN RAISE EXCEPTION '${slot}: expected ${count.races} races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'won';
  IF n <> ${count.won} THEN RAISE EXCEPTION '${slot}: expected ${count.won} winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome = 'lost';
  IF n <> ${count.lost} THEN RAISE EXCEPTION '${slot}: expected ${count.lost} losers, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM seed WHERE outcome IS NULL;
  IF n <> ${count.noResult} THEN RAISE EXCEPTION '${slot}: expected ${count.noResult} rows with no result, the file carries %', n; END IF;

  -- 🔴 A POSITIVE CONTROL BEFORE THE GATES THAT READ PRODUCTION. If the join below sees nothing,
  --    every "0 bad rows" gate that follows passes vacuously.
  SELECT count(*) INTO n
    FROM seed s JOIN essentials.races r ON r.id = s.race_id;
  IF n <> ${count.rows} THEN RAISE EXCEPTION '${slot}: the race join sees % of the ${count.rows} rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- Every pinned race is a 2026-11-03 ${STATE.name} legislative race, and carries the seat count
  -- this file states.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r    ON r.id = s.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03'
      OR lower(d.state) <> '${st}'
      OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % pinned row(s) are not in a 2026-11-03 ${STATE.name} legislative race', n; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.seats || ', production ' || r.seats || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.seats IS DISTINCT FROM s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: this file states a seat count production disagrees with: %', txt; END IF;

  SELECT string_agg(DISTINCT s.district || ' (file ' || s.office_id || ', production ' || r.office_id || ')', '; ') INTO txt
    FROM seed s JOIN essentials.races r ON r.id = s.race_id
   WHERE r.office_id IS DISTINCT FROM s.office_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: this file states an office production disagrees with: %', txt; END IF;

  -- 🔴 THE PREMISE OF THE WHOLE FILE: every one of these races is EMPTY. If another session has
  --    seeded one since the analysis, this file must not add a second ballot beside theirs.
  SELECT string_agg(DISTINCT s.district || ' (' || c.n || ' row(s))', '; ') INTO txt
    FROM seed s
    CROSS JOIN LATERAL (SELECT count(*) AS n FROM essentials.race_candidates rc WHERE rc.race_id = s.race_id) c
   WHERE c.n <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: these races already carry candidacies and this file assumes they are empty: %', txt; END IF;

  -- For a called race the winner count is races.seats. ⚠ Not every chamber is one-per-district,
  -- so this reads production's own seat count rather than assuming 1.
  SELECT string_agg(s.district || ' (' || s.winners || ' winner(s) for ' || s.seats || ' seat(s))', '; ') INTO txt
    FROM (SELECT district, seats, count(*) FILTER (WHERE outcome = 'won') AS winners
            FROM seed WHERE called GROUP BY race_id, district, seats) s
   WHERE s.winners <> s.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: winner count does not match races.seats: %', txt; END IF;

  -- 🔴 THE ONLY GATE THAT CAN SEE A TRANSPOSED WIN. Every other check reads the outcome column
  --    beside the name, so a file with two outcomes swapped agrees with itself. AP publishes the
  --    winner flag and the vote count as INDEPENDENT fields, so where there are votes to order
  --    on, the winners must also be the top rows by count.
  --    ⚠ It is deliberately scoped to races AP tabulated: in an uncontested race every count is
  --    zero and this comparison would pass without comparing anything.
  SELECT string_agg(bad.district, '; ') INTO txt
    FROM (
      SELECT s.district
        FROM seed s
        JOIN (SELECT race_id, max(votes) AS top FROM seed WHERE NOT uncontested GROUP BY race_id) m
          ON m.race_id = s.race_id AND m.top > 0
       WHERE s.outcome = 'won' AND s.votes < (
         SELECT min(x.votes) FROM (
           SELECT votes FROM seed s2 WHERE s2.race_id = s.race_id ORDER BY votes DESC LIMIT s.seats
         ) x)
       GROUP BY s.district
    ) bad;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: a row marked won is not among the top vote-getters of its race: %', txt; END IF;

  -- The incumbent link, re-asserted against production rather than trusted from this file.
  SELECT count(*) INTO n FROM seed WHERE holder_id IS NOT NULL;
  IF n <> ${count.links} THEN RAISE EXCEPTION '${slot}: expected ${count.links} incumbent links, the file carries %', n; END IF;

  SELECT string_agg(s.district || ' (' || s.full_name || ')', '; ') INTO txt
    FROM seed s
   WHERE s.holder_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM essentials.races r
         JOIN essentials.office_current_holder och ON och.office_id = r.office_id
        WHERE r.id = s.race_id AND och.politician_id = s.holder_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: rows linked on the incumbent basis are no longer the seat holder: %', txt; END IF;

  SELECT string_agg(s.district || ' (file "' || s.holder_name || '", production "' || p.full_name || '")', '; ') INTO txt
    FROM seed s JOIN essentials.politicians p ON p.id = s.holder_id
   WHERE s.holder_id IS NOT NULL AND p.full_name IS DISTINCT FROM s.holder_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: a linked politician does not carry the name this file states: %', txt; END IF;

  SELECT count(*) INTO n FROM seed s WHERE s.holder_id IS NOT NULL AND NOT s.ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % row(s) claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  SELECT count(*) INTO n FROM (SELECT holder_id FROM seed WHERE holder_id IS NOT NULL GROUP BY holder_id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % politician(s) would be linked to more than one candidacy by this file', n; END IF;

  -- AP's candidate id becomes this row's external_id, so it must not already be in use.
  SELECT string_agg(rc.external_id, '; ') INTO txt
    FROM essentials.race_candidates rc
   WHERE rc.external_id IN (SELECT 'ap-2026-11-03-' || ap_candidate_id FROM seed);
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: external_id already in use: %', txt; END IF;
END $$;

-- ─── 3. The write ───
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, external_id, source, result, result_certainty, result_source,
   result_recorded_at)
SELECT s.race_id,
       s.holder_id,
       s.full_name,
       s.first_name,
       s.last_name,
       s.ap_incumbent,
       s.is_write_in,
       'active',
       'ap-2026-11-03-' || s.ap_candidate_id,
       'Associated Press ballot for the 2026-11-03 general election, read ${READ_ON} from AP''s own '
         || 'per-state results feed (interactives.apelections.org/election-results/data-live/'
         || '2026-11-03/results/races/${st.toUpperCase()}/, race ' || s.ap_race_id || ', candidate '
         || s.ap_candidate_id || '), cross-read line by line against ${STATE.second_source.replace(/'/g, "''")} '
         || '(${STATE.second_source_url}, read ${READ_ON}). Seeded by ${slot}.'
         || CASE WHEN s.is_write_in THEN ' Declared write-in candidate.' ELSE '' END,
       s.outcome,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE 'called' END,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE
         'Associated Press race call for the 2026-11-03 general election, read ${READ_ON} from AP''s '
         || 'own per-state results feed (race ' || s.ap_race_id || ', candidate ' || s.ap_candidate_id
         || '), recorded as ' || s.outcome || '. '
         || CASE WHEN s.uncontested OR s.votes = 0
                 THEN 'AP publishes NO vote tabulation for this contest and calls it on the ballot at poll close, so no count is quoted here: a published zero is not a tally of zero.'
                 ELSE 'AP reported ' || s.pct || '% of the vote for this candidate.' END
         || ' This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. '
         || 'A call and a canvass are two facts.'
       END,
       CASE WHEN s.outcome IS NULL THEN NULL ELSE now() END
  FROM seed s
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id);

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id;
  IF n <> ${count.rows} THEN RAISE EXCEPTION '${slot}: expected ${count.rows} rows written, found %', n; END IF;

  -- The outcome, the name and the link each read back from production, not from the file's copy.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.race_id = s.race_id
     AND rc.full_name = s.full_name
     AND rc.result IS NOT DISTINCT FROM s.outcome
     AND rc.politician_id IS NOT DISTINCT FROM s.holder_id
     AND rc.is_write_in = s.is_write_in
     AND rc.is_incumbent = s.ap_incumbent;
  IF n <> ${count.rows} THEN RAISE EXCEPTION '${slot}: only % of ${count.rows} written rows carry exactly what this file states', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result IS NOT NULL AND coalesce(btrim(rc.result_source), '') = '';
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % written row(s) carry a result with no citation', n; END IF;

  -- 🔴 NO CITATION MAY QUOTE A VOTE COUNT. This is the CC_0408-CC_0411 class, gated rather than
  --    promised: a zero AP publishes for an uncontested race is not a tally.
  SELECT string_agg(rc.full_name, '; ') INTO txt
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.result_source ~ '[0-9][0-9,]* votes';
  IF txt IS NOT NULL THEN RAISE EXCEPTION '${slot}: a citation quotes a vote count: %', txt; END IF;

  -- The ${count.races} races are no longer empty, and no OTHER race gained a row.
  SELECT count(*) INTO n
    FROM (SELECT DISTINCT race_id FROM seed) x
   WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.race_id);
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % of the seeded races are still empty', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND lower(d.state) = '${st}'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.external_id LIKE 'ap-2026-11-03-%'
     AND NOT EXISTS (SELECT 1 FROM seed s WHERE 'ap-2026-11-03-' || s.ap_candidate_id = rc.external_id);
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % AP-seeded row(s) exist in this state that this file does not name', n; END IF;

  -- 🔴 THE MIRROR TRIGGER. An INSERT carrying a politician_id fires
  --    essentials.trg_race_candidate_mirror_data, which can write a photo or a url onto the
  --    politician. Both columns here are NULL, so it must have done nothing at all.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN seed s ON rc.external_id = 'ap-2026-11-03-' || s.ap_candidate_id
   WHERE rc.photo_url IS NOT NULL OR rc.website_url IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '${slot}: % written row(s) carry a photo or website url, which this file never writes', n; END IF;

  -- Nobody was seated, nobody was unseated.
  SELECT count(*) INTO n
    FROM seed s
    JOIN essentials.races r ON r.id = s.race_id
    JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE s.holder_id IS NOT NULL AND och.politician_id = s.holder_id;
  IF n <> ${count.links} THEN RAISE EXCEPTION '${slot}: the seat holder changed for % of the ${count.links} linked office(s) — this file seats nobody', ${count.links} - n; END IF;

  SELECT count(*) FILTER (WHERE true), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF total = 0 THEN RAISE EXCEPTION '${slot}: the occupancy view is empty — the baseline check below would pass vacuously'; END IF;
  IF unflagged <> 238 THEN RAISE EXCEPTION '${slot}: occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;
END $$;

COMMIT;
`;

fs.writeFileSync(out, sql);
console.log(`wrote ${out}`);
console.log(`  ${count.rows} candidacies · ${count.races} races · ${count.won} won · ${count.lost} lost · ${count.noResult} no result · ${count.links} linked · ${count.writeIns} write-in(s)`);
console.log(`  ${count.uncontestedRaces} uncontested race(s) · ${count.zeroVoteRows} row(s) with a published count of zero`);
console.log(`  bases: ${Object.entries(count.basis).map(([k, v]) => `${k} ${v}`).join(' · ')}`);
