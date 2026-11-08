#!/usr/bin/env node
// Emit CC_0381 from the committed analysis. The migration is generated rather than typed
// because 809 pinned rows cannot be hand-checked, but every row it writes is addressed BY UUID
// and the gates re-assert each pin against production before a single value changes.
import fs from 'node:fs';

const analysisFile = process.argv[2];
const outFile = process.argv[3];
if (!analysisFile || !outFile) { console.error('usage: emit-migration.mjs <analysis.json> <out.sql>'); process.exit(2); }

const a = JSON.parse(fs.readFileSync(analysisFile, 'utf8'));
const writable = a.plan.filter((r) => !r.skip);
const rows = [];
for (const r of writable) {
  for (const w of r.writes) {
    rows.push({
      state: r.state, district: r.district_label, office: r.office_title,
      race_id: r.race_id, rc_id: w.rc_id, seats: r.seats,
      our_name: w.our_name, ap_name: w.ap_name,
      ap_race_id: r.ap_race_id, ap_candidate_id: w.ap_candidate_id,
      party: w.party, votes: w.votes, pct: w.pct,
      called_at: r.writes.find((x) => x.outcome === 'won')?.called_at || null,
      outcome: w.outcome, match_basis: w.match_basis,
      prior_result: w.prior_result || null,
      ap_incumbent: w.ap_incumbent,
    });
  }
}
const q = (s) => s === null || s === undefined ? 'NULL' : "'" + String(s).replace(/'/g, "''") + "'";
const uuid = (s) => "'" + s + "'::uuid";

const won = rows.filter((r) => r.outcome === 'won').length;
const lost = rows.filter((r) => r.outcome === 'lost').length;
const races = new Set(rows.map((r) => r.race_id)).size;
const priorAdvanced = rows.filter((r) => r.prior_result === 'advanced').length;
const byState = {};
for (const r of rows) {
  if (!byState[r.state]) byState[r.state] = { races: new Set(), won: 0, lost: 0 };
  byState[r.state].races.add(r.race_id);
  byState[r.state][r.outcome]++;
}
const basis = {};
for (const r of rows) basis[r.match_basis] = (basis[r.match_basis] || 0) + 1;
const holderRows = rows.filter((r) => r.match_basis === 'holder');
const uncalled = a.plan.filter((r) => r.skip && r.skip !== 'blocked').length;

const stateTable = Object.keys(byState).sort().map((s) =>
  `--     ${s.toUpperCase()}  ${String(byState[s].races.size).padStart(3)} races   ${String(byState[s].won).padStart(3)} won   ${String(byState[s].lost).padStart(3)} lost`).join('\n');

const values = rows.map((r) =>
  `  (${q(r.state)}, ${q(r.district)}, ${q(r.office)}, ${uuid(r.race_id)}, ${uuid(r.rc_id)}, ${r.seats}, ` +
  `${q(r.our_name)}, ${q(r.ap_name)}, ${q(r.ap_race_id)}, ${q(r.ap_candidate_id)}, ${q(r.party)}, ` +
  `${r.votes}, ${r.pct}, ${q(r.outcome)}, ${q(r.match_basis)}, ${q(r.prior_result)}, ${r.ap_incumbent ? 'true' : 'false'})`).join(',\n');

const sql = `-- CC_0381 — 2026-11-03 state legislatures: record the ${races} races the Associated Press
--           has called in the nine states where we hold candidates, and the losers on those
--           same ballots.
--
-- WHY THIS FILE EXISTS. The state legislatures are the largest tier in the post-election
--   programme — 1,114 races against 2,340 in all — and until this file they hold ZERO recorded
--   winners. Every other worked tier is nearly finished; this one had not been started.
--
-- 🔴🔴 THE REASON IT HAD NOT BEEN STARTED WAS A BELIEF ABOUT AP, AND THE BELIEF WAS WRONG.
--   Every earlier pass read AP's NATIONAL file, results/national/{metadata,progress}.json, and
--   this repo's notes enumerate its catalogue: U.S. House, Governor, U.S. Senate, Attorney
--   General, Secretary of State, Lieutenant Governor, Mayor, U.S. Delegate, Railroad
--   Commissioner. No state-legislative contest appears in it, anywhere.
--   AP publishes them PER STATE, at results/races/<ST>/{metadata,progress}.json — 6,938 races
--   across the 51 files against the national file's 645, of which 5,759 are state-legislative
--   and 5,439 are already called, with officeID 'Y' for the lower chamber and 'Z' for the upper.
--   ▶ THE CATALOGUE OF A SOURCE IS A PROPERTY OF THE ENDPOINT, NOT OF THE SOURCE. "AP does not
--     carry this" was true of the file we were reading and false of AP. That is CC_0380's
--     lesson — an absence you did not look for is not a finding — met again one endpoint out.
--   ⚠ It also means the recorded ceiling "no treasurer, comptroller, auditor or superintendent
--     race ANYWHERE" is a statement about the national file only: the per-state files carry 24
--     Treasurer, 14 Auditor, 5 Comptroller and 3 Controller races, among much else.
--
-- WHAT IT WRITES: ${rows.length} existing candidacies UPDATED across ${races} races — ${won} won, ${lost} lost, every
--   one result_certainty = 'called'. No politician, race, office, district or term is created,
--   deleted or re-seated. RECORDING A RESULT SEATS NOBODY: these members take office in January
--   and the post-verify asserts that not one office_terms row moved.
--
${stateTable}
--
-- 🔴 PRIOR VALUES, BECAUSE AN UPDATE IS FINAL AND THERE IS NO HISTORY TABLE.
--   ${String(rows.length - priorAdvanced).padStart(3)} rows carry NULL in all four columns this file touches.
--   ${String(priorAdvanced).padStart(3)} rows carry result = 'advanced' with a real state citation in result_source —
--       Arizona's Secretary of State candidate list and Washington's August top-two primary
--       canvass, which in Washington is a TRUE AND LOAD-BEARING FACT: 'advanced' there means
--       the candidate came through the top-two primary onto this November ballot.
--   ▶ Those citations are APPENDED, never overwritten, exactly as CC_0350 did for the 51 House
--     rows in the same position, and the UPDATE reads the live value rather than this file's
--     copy of it. A gate asserts every one of the ${priorAdvanced} survives verbatim.
--
-- 🔴 WHAT IS DELIBERATELY NOT WRITTEN.
--   ${String(uncalled).padStart(3)} matched races are UNCALLED by AP and get no row at all (AZ 6, CA 21, CO 3,
--       UT 13, WA 27). They are not a backlog: these seats turn over in January.
--    43 of our candidacies sit in recorded races and are NOT on AP's ballot, so they are left
--       untouched — 33 already read 'not_nominated' (Washington's top-two primary losers, who
--       were never on this ballot), one 'withdrew', nine carry no result. 🔴 A LOSER IS
--       RECORDED BECAUSE AP'S BALLOT NAMES THEM, NEVER BECAUSE THEY ARE NOT THE WINNER.
--     3 people on AP's ballots have no candidacy row of ours (MA Suffolk & Middlesex "Brandon
--       Wood", UT House 57 "Nancy Peterson", WA House 28 "Kerry Hills"). All three LOST, so no
--       winner is missed; seeding a person is a separate act and is not done here.
--
-- 🔴🔴 THE NAME MATCH IS THE DANGEROUS STEP AND IT IS DONE ON FOUR NAMED BASES, NOT ONE FUZZY
--   RULE. ${basis['exact-full-name'] || 0} rows matched on an identical full name and ${basis['exact-first-last'] || 0} on identical first-plus-last.
--   The rest disagreed in spelling, and a comparison relaxed until they matched is how this
--   repo once shipped Mark Harris as NC-8:
--     'holder'            ${String(basis.holder || 0).padStart(3)} rows. AP flags the candidate as that seat's incumbent AND
--                             essentials.office_current_holder independently names the politician
--                             our row links to, for that same office. Two facts, neither a name.
--                             This alone settled 19 disagreements including "Quang Nguyen" for
--                             our "Quang H Nguyen" and "Mia Gregerson" for "Mia Su-Ling Gregerson".
--     'first-last-tokens' ${String(basis['first-last-tokens'] || 0).padStart(3)} rows. First token and last token equal once nicknames in
--                             quotes or parentheses, generational suffixes and punctuation are
--                             removed, landing on exactly ONE unmatched row in that contest. It
--                             never relaxes the surname. All ${basis['first-last-tokens'] || 0} are losers and all ${basis['first-last-tokens'] || 0} were read.
--     'reviewed'          ${String(basis.reviewed || 0).padStart(3)} row, hand-checked, with its evidence in name-overrides.json.
--   🔴 THE ONE REVIEWED ROW IS THE ONE WHERE THE FIRST NAME ITSELF DIFFERS: AP's "Patricia
--     Contreras" against our "Patty Contreras" in Arizona Senate LD12. Arizona seats TWO
--     Contrerases, so the surname is ambiguous — azleg.gov's own Member Roster gives Patty
--     Contreras as the District 12 House member and Lupe Contreras as District 22. THE DISTRICT
--     DISAMBIGUATES WHAT THE SURNAME COULD NOT. A diminutive alone would not have been enough.
--
-- 🟢 WASHINGTON IS READ TWICE, AND THAT IS WHAT MAKES THE RELAXED MATCHES EVIDENCE RATHER THAN
--   CONVENIENCE. The Secretary of State publishes its own canvass through the API its public
--   results site reads (results.votewa.gov/results/public/api/elections/washington/20261103/data).
--   It is authoritative for the BALLOT and the COUNT and publishes NO winner flag at all — every
--   isWinner is null, because a state canvasses and does not call. All 122 AP contests join to
--   it, and ALL 25 of Washington's name variants carry THE SAME VOTE COUNT on both sources:
--   AP's "Kim Harless" and the state's "Kim D. Harless" are both 41,205. See verify-wa-sos.mjs.
--   ⚠ The two disagree on 117 of 225 COUNTS — AP publishes 0 for every candidate in the 19
--     unopposed contests and lags the canvass elsewhere. We store no vote counts, so this
--     changes nothing we write; it is why no number here is quoted as a canvassed total.
--   ⚠ The state's ballot carries one extra line per contest, all 122 of them the "Write-in"
--     aggregate — the twin of AP's "Total Write-ins" (id 100008) and Nevada's "None of These
--     Candidates" (100013). Both AP ids are excluded by id before anything is counted.
--
-- 🔴 A TOP-VOTE-GETTER CROSS-CHECK OVER AN ALL-ZERO BALLOT COMPARES NOTHING AND PASSES.
--   AP calls an unopposed race on the BALLOT, not the count, and publishes 0 votes for everyone
--   in it. The cross-check is therefore applied only where AP had a choice to make — more
--   candidates than winners — and the analyser blocks any all-zero race that has one. Arizona's
--   four all-zero House races have exactly 2 candidates for 2 seats, so no ordering decision
--   exists in them at all. ⚠ Arizona's House elects TWO members per district: 24 of these races
--   carry seats = 2 and two winners, so a one-winner-per-race gate would be WRONG here. The
--   gate compares the winner count against races.seats.
--
-- SOURCING. AP's own feed, read 2026-11-08, committed raw in ap-2026-11-08/. The call is AP's
--   and is labelled as such in every result_source; result_certainty = 'called' NEVER
--   'certified'. AP reports isCertified = false on every one of these races, and the states
--   canvass through November and December. ⚠ A CALL AND A CANVASS ARE TWO FACTS.
--
-- Slot CC_0381 reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  state            text NOT NULL,
  district         text NOT NULL,
  office_title     text NOT NULL,
  race_id          uuid NOT NULL,
  rc_id            uuid PRIMARY KEY,
  seats            int  NOT NULL,
  our_name         text NOT NULL,   -- as our row reads today
  ap_name          text NOT NULL,   -- as AP prints it
  ap_race_id       text NOT NULL,
  ap_candidate_id  text NOT NULL,
  party            text,
  votes            int  NOT NULL,
  pct              numeric NOT NULL,
  outcome          text NOT NULL CHECK (outcome IN ('won', 'lost')),
  match_basis      text NOT NULL CHECK (match_basis IN ('exact-full-name', 'exact-first-last', 'holder', 'first-last-tokens', 'reviewed')),
  prior_result     text,            -- the value this row carries BEFORE this file runs
  ap_incumbent     boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO called (state, district, office_title, race_id, rc_id, seats, our_name, ap_name,
                    ap_race_id, ap_candidate_id, party, votes, pct, outcome, match_basis,
                    prior_result, ap_incumbent) VALUES
${values};

-- The citation each row carries before this file touches it, captured from PRODUCTION so the
-- survival gate below compares against the live value and not against this file's own copy.
CREATE TEMP TABLE before_image AS
  SELECT rc.id AS rc_id, rc.result AS result, rc.result_source AS result_source,
         rc.result_certainty AS result_certainty, rc.is_incumbent AS is_incumbent,
         rc.first_name, rc.last_name, rc.full_name
    FROM essentials.race_candidates rc
    JOIN called c ON c.rc_id = rc.id;

-- Occupancy as it stands before the write, for every office this file touches. Compared after,
-- because "recording a result seats nobody" is a claim and a claim needs a gate.
CREATE TEMP TABLE occupancy_before AS
  SELECT och.office_id, och.politician_id
    FROM essentials.office_current_holder och
   WHERE och.office_id IN (SELECT r.office_id FROM essentials.races r JOIN called c ON c.race_id = r.id);

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  -- 🔴 unaccent is NOT installed on prod and AP returns accents Ballotpedia drops
  --    (Elda Luna-Nájera, Aaron Márquez). Fold them here, in the application's own terms.
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçÝý',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCcYy')),
           '[^A-Z0-9]', '', 'g')
$f$;

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> ${rows.length} THEN RAISE EXCEPTION 'expected ${rows.length} measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> ${races} THEN RAISE EXCEPTION 'expected ${races} races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'won';
  IF n <> ${won} THEN RAISE EXCEPTION 'expected ${won} winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'lost';
  IF n <> ${lost} THEN RAISE EXCEPTION 'expected ${lost} losers, the file carries %', n; END IF;

  -- POSITIVE CONTROL. Every "no mismatch found" below is vacuous if the comparison cannot see
  -- anything at all, so prove it can before trusting its silence.
  PERFORM 1 FROM essentials.race_candidates
   WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Mia Su-Ling Gregerson');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist — every name gate below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM before_image;
  IF n <> ${rows.length} THEN RAISE EXCEPTION 'the before-image sees % of the ${rows.length} rows this file names — a gate that reads the wrong rows proves nothing', n; END IF;

  -- 🔴 EVERY ROW IS ADDRESSED BY uuid AND THE NAME BESIDE IT DOES NOT FIND IT. A mistyped id
  --   would otherwise move a win to another seat in silence, so the pin is re-asserted against
  --   production: the row must exist, sit in the stated race, and carry the stated name.
  SELECT count(*) INTO n FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% pinned candidacies do not exist', n; END IF;
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned candidacies sit in a different race: %', txt; END IF;

  -- 🔴 CC_0359 GATE D: the name is compared against THE DATABASE ROW, never against another
  --   column of this file, because a file that checks itself agrees with itself.
  SELECT string_agg(c.our_name || ' <> ' || rc.full_name, ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.our_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned rows do not carry the name this file states: %', txt; END IF;

  -- the race must be a 2026-11-03 state-legislative race, or this file is writing somewhere else
  SELECT count(*) INTO n
    FROM called c JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03' OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION '% pinned rows are not in a 2026-11-03 state-legislative race', n; END IF;

  -- 🔴 WINNERS PER RACE MUST EQUAL races.seats, NEVER ONE. Arizona's House elects two members
  --   per district and 24 of these races carry two winners.
  SELECT string_agg(x.district || ' (' || x.w || ' winners, seats ' || x.seats || ')', ', ') INTO txt
    FROM (SELECT c.district, c.seats, count(*) FILTER (WHERE c.outcome = 'won') AS w
            FROM called c GROUP BY c.race_id, c.district, c.seats) x
   WHERE x.w <> x.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'winner count does not match races.seats: %', txt; END IF;
  SELECT string_agg(c.district, ', ') INTO txt
    FROM called c JOIN essentials.races r ON r.id = c.race_id
   WHERE r.seats <> c.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file states a seat count production disagrees with: %', txt; END IF;

  -- 🔴🔴 THE WINNERS MUST BE THE TOP VOTE-GETTERS, AND THIS IS THE ONLY GATE THAT CAN CATCH A
  --   TRANSPOSED WIN. Every other check here reads the outcome column beside the name, so a
  --   file that has swapped two outcomes agrees with itself perfectly — the write reads this
  --   table and the post-verify reads this table. AP publishes the winner FLAG and the VOTE
  --   COUNT as independent fields, so requiring that the rows marked 'won' are exactly the top
  --   "seats" rows by votes brings in a second fact the tamper would also have to forge.
  --   ⚠ Valid only because not one of these races is ranked-choice and none is a Louisiana-style
  --     two-round contest; the analyser refuses to make a race writable if AP flags it
  --     rankedChoice, precisely because a later-round winner need not lead on first preferences.
  --   ⚠ Ties are not special-cased: there are none here, and a tie would RAISE rather than pass.
  SELECT string_agg(x.district || ' (' || x.our_name || ')', ', ') INTO txt FROM (
    SELECT c.district, c.our_name, c.outcome,
           rank() OVER (PARTITION BY c.race_id ORDER BY c.votes DESC) AS vote_rank,
           c.seats
      FROM called c
  ) x
   WHERE (x.outcome = 'won') <> (x.vote_rank <= x.seats);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the rows marked won are not the top vote-getters of their race: %', txt; END IF;

  -- 🔴 NOTHING THIS FILE WRITES MAY ALREADY BE DECIDED. A row reading won, not_nominated or
  --   withdrew is a different claim that this file would be destroying.
  SELECT string_agg(b.full_name || ' = ' || b.result, ', ') INTO txt
    FROM before_image b WHERE b.result IN ('won', 'lost', 'not_nominated', 'withdrew', 'runoff');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows this file writes already carry a decided result: %', txt; END IF;

  -- and the prior value must be exactly the one recorded in the header, or somebody has
  -- written here since the analysis was taken
  SELECT string_agg(b.full_name || ': file says ' || coalesce(c.prior_result, 'NULL')
                    || ', production says ' || coalesce(b.result, 'NULL'), ', ') INTO txt
    FROM called c JOIN before_image b ON b.rc_id = c.rc_id
   WHERE coalesce(b.result, '') <> coalesce(c.prior_result, '');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior values have moved since this file was generated: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced';
  IF n <> ${priorAdvanced} THEN RAISE EXCEPTION 'expected ${priorAdvanced} rows carrying advanced, production has %', n; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced' AND coalesce(result_source, '') = '';
  IF n <> 0 THEN RAISE EXCEPTION '% advanced rows carry no citation to preserve', n; END IF;

  -- 🔴 THE 'holder' BASIS IS ONLY SOUND IF PRODUCTION STILL AGREES WITH IT. Every row matched
  --   that way is re-checked here against office_current_holder: AP called the candidate the
  --   seat's incumbent, and our own view must name the same politician for that same office.
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE c.match_basis = 'holder'
     AND (och.politician_id IS NULL OR rc.politician_id IS NULL OR och.politician_id <> rc.politician_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows matched on the incumbent basis are no longer the seat holder: %', txt; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder';
  IF n <> ${basis.holder || 0} THEN RAISE EXCEPTION 'expected ${basis.holder || 0} rows on the incumbent basis, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder' AND NOT ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '% rows claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  RAISE NOTICE 'pre-checks passed: % candidacies across % races, % won, % lost',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called),
    (SELECT count(*) FROM called WHERE outcome = 'won'), (SELECT count(*) FROM called WHERE outcome = 'lost');
END $$;

-- ─── 3. The write ───
-- 🔴 The existing citation is APPENDED, read from the LIVE column rather than from this file's
--    copy of it, so a row somebody has re-cited since the analysis keeps whatever it now says.
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Associated Press race call for the 2026-11-03 general election, read '
         || '2026-11-08 from AP''s own per-state results feed '
         || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/races/'
         || upper(c.state) || '/, race ' || c.ap_race_id || ', candidate ' || c.ap_candidate_id
         || '): ' || c.ap_name || coalesce(' (' || c.party || ')', '') || ' '
         || c.votes || ' votes, ' || c.pct || '%, recorded as ' || c.outcome
         || '. This is AP''s call and NOT the state canvass; AP reports this race as not yet '
         || 'certified. Matched to our row on basis ''' || c.match_basis || '''.'
         || CASE WHEN coalesce(rc.result_source, '') <> ''
                 THEN ' — the citation this row already carried is retained verbatim: ' || rc.result_source
                 ELSE '' END,
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NOT DISTINCT FROM c.prior_result;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result = c.outcome AND rc.result_certainty = 'called';
  IF n <> ${rows.length} THEN RAISE EXCEPTION 'expected ${rows.length} rows written, % carry the outcome this file states', n; END IF;

  -- every row must cite the AP race it came from, by id
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE position(c.ap_race_id in coalesce(rc.result_source, '')) = 0;
  IF n <> 0 THEN RAISE EXCEPTION '% written rows do not name the AP race they came from', n; END IF;

  -- 🔴 THE ${priorAdvanced} PRESERVED CITATIONS MUST SURVIVE VERBATIM. There is no history table: if
  --   this fails after a change to the UPDATE, those citations are gone for good.
  SELECT string_agg(b.full_name, ', ') INTO txt
    FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> ''
     AND position(b.result_source in coalesce(rc.result_source, '')) = 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior citations were destroyed rather than appended: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> '' AND position(b.result_source in rc.result_source) > 0;
  IF n <> ${priorAdvanced} THEN RAISE EXCEPTION 'expected ${priorAdvanced} preserved citations, found %', n; END IF;

  -- 🔴 RECORDING A RESULT SEATS NOBODY. These members take office in January; if this file has
  --   moved an officeholder, it has done something it does not claim to do.
  SELECT count(*) INTO n FROM occupancy_before;
  IF n = 0 THEN RAISE EXCEPTION 'the occupancy snapshot is empty — the comparison below would pass vacuously'; END IF;
  SELECT string_agg(x.office_id::text, ', ') INTO txt FROM (
    SELECT coalesce(b.office_id, a.office_id) AS office_id
      FROM occupancy_before b
      FULL OUTER JOIN (
        SELECT och.office_id, och.politician_id
          FROM essentials.office_current_holder och
         WHERE och.office_id IN (SELECT r.office_id FROM essentials.races r JOIN called c ON c.race_id = r.id)
      ) a ON a.office_id = b.office_id
     WHERE a.office_id IS NULL OR b.office_id IS NULL
        OR a.politician_id IS DISTINCT FROM b.politician_id
  ) x;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the current officeholder changed for office(s) % — this file seats nobody', txt; END IF;

  -- nothing outside the pinned set may have been written
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.result_certainty = 'called'
     AND rc.id NOT IN (SELECT rc_id FROM called);
  IF n <> 0 THEN RAISE EXCEPTION '% state-legislative rows outside this file carry a call', n; END IF;

  -- the tier's own number, which is what this file exists to move
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER') AND rc.result = 'won';
  IF n <> ${won} THEN RAISE EXCEPTION 'expected ${won} state-legislative winners after this file, found %', n; END IF;

  -- 🔴 THE OCCUPANCY DRIFT BASELINE. This file creates no office, so the unflagged count must
  --   not have moved. It is asserted rather than assumed because a baseline nobody checks is a
  --   baseline that moves under the next author.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;

  RAISE NOTICE 'CC_0381 done: % candidacies across % races, % won / % lost; occupancy % / % / %',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called),
    ${won}, ${lost}, total, flagged, unflagged;
END $$;

DROP TABLE IF EXISTS before_image;
DROP TABLE IF EXISTS occupancy_before;

COMMIT;
`;

fs.writeFileSync(outFile, sql);
console.log('wrote ' + outFile);
console.log(rows.length + ' candidacies, ' + races + ' races, ' + won + ' won, ' + lost + ' lost, ' + priorAdvanced + ' carrying a prior citation');
console.log('match bases: ' + JSON.stringify(basis));
console.log('holder-basis rows: ' + holderRows.length);
