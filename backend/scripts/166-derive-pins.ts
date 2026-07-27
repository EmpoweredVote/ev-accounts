/**
 * 166-derive-pins.ts — Phase 166 read-only LIVE pin derivation harness.
 *
 * The five per-phase Wave-3 gates froze their pin lists at their own authoring dates
 * (161 + 162 on 2026-07-04/05, 163 on 2026-07-06, 164 + 165 on 2026-07-07). Today is
 * 2026-07-26. Filings, withdrawals, culls and the 164.2-04 FL/CA candidate-field repairs
 * (2026-07-22) have all landed since. A consolidated gate built on those snapshots would
 * be green for the wrong reasons — so every pin the Phase-166 gate carries is re-derived
 * here, live, against production.
 *
 * SELECT-only against essentials/inform. The single write is the local artifact
 * `backend/scripts/166-pins.generated.sql`, consumed verbatim by 166-03 and 166-04.
 *
 * Scope: the SAME 42 elections and 38 two-digit FIPS geo prefixes 166-verify.sql uses.
 * A scope mismatch here would silently produce pins for the wrong universe.
 *
 * Run:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
 *     node --import tsx scripts/166-derive-pins.ts
 */
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { pool } from '../src/lib/db.js';

const DERIVED_AT = '2026-07-26';

// ---------------------------------------------------------------------------
// The 38 general elections. `districts` is the expected NATIONAL_LOWER district
// count for the state across ALL 42 in-scope elections — MO's 8 is 3 under its
// general plus 5 still held behind the MO Polygon Pending marker election.
// `band` is [lo, hi] with lo the MORE NEGATIVE endpoint (SQL BETWEEN lo AND hi).
// ---------------------------------------------------------------------------
interface StateCfg {
  st: string;
  fips: string;
  election: string;
  districts: number;
  band: [number, number];
  sourceGate: string;
  /**
   * Additional in-scope elections beyond the state's general. Only WI needs one, and it is
   * a LIVE-DERIVATION CORRECTION to the 42-election scope Phase 166 was planned against:
   *
   * Phase 163 seeded WI onto the 8 'WI 2026 Statewide General' races on 2026-07-05. On
   * 2026-07-25 — nineteen days after 163's gate froze — a party-split
   * 'WI 2026 Partisan Primary' election (2026-08-11, still upcoming) was created and WI's
   * field was moved onto it. Today the general holds 5 active candidates with 4 of its 8
   * races EMPTY, while the primary holds 32 active including 7 incumbents.
   *
   * Scoping WI to the general alone would assert USHC3-06 coverage over 5 candidates and
   * silently ignore 32 — green for exactly the reason this plan exists to prevent
   * ("a scope mismatch here silently produces pins for the wrong universe").
   *
   * IN and UT also have primary-election House races, but theirs are PAST (2026-05-05 and
   * 2026-06-23) and hold only 3 and 5 primary-only politicians, nearly all UUID-keyed.
   * Those are concluded contests, correctly excluded from a forward-looking general gate.
   */
  extraElections?: string[];
}

const STATES: StateCfg[] = [
  // --- 161 ---------------------------------------------------------------
  { st: 'AZ', fips: '04', election: 'AZ 2026 Statewide General', districts: 9, band: [-40901, -40101], sourceGate: '161' },
  { st: 'WA', fips: '53', election: 'WA 2026 Statewide General', districts: 10, band: [-531005, -530101], sourceGate: '161' },
  { st: 'TN', fips: '47', election: 'TN 2026 Statewide General', districts: 9, band: [-470910, -470101], sourceGate: '161' },
  { st: 'MA', fips: '25', election: '2026 Massachusetts General Election', districts: 9, band: [-250902, -250101], sourceGate: '161' },
  // --- 162 ---------------------------------------------------------------
  { st: 'IN', fips: '18', election: 'IN 2026 Statewide General', districts: 9, band: [-180999, -180101], sourceGate: '162' },
  { st: 'MD', fips: '24', election: '2026 Maryland General Election', districts: 8, band: [-240899, -240101], sourceGate: '162' },
  { st: 'MN', fips: '27', election: 'MN 2026 Statewide General', districts: 8, band: [-270899, -270101], sourceGate: '162' },
  { st: 'MO', fips: '29', election: 'MO 2026 Statewide General', districts: 8, band: [-290899, -290101], sourceGate: '162' },
  // --- 163 ---------------------------------------------------------------
  { st: 'WI', fips: '55', election: 'WI 2026 Statewide General', districts: 8, band: [-550899, -550101], sourceGate: '163', extraElections: ['WI 2026 Partisan Primary'] },
  { st: 'CO', fips: '08', election: 'CO 2026 Statewide General', districts: 8, band: [-80899, -80101], sourceGate: '163' },
  { st: 'AL', fips: '01', election: 'AL 2026 Statewide General', districts: 7, band: [-10799, -10101], sourceGate: '163' },
  { st: 'SC', fips: '45', election: 'SC 2026 Statewide General', districts: 7, band: [-450799, -450101], sourceGate: '163' },
  { st: 'LA', fips: '22', election: 'LA 2026 Statewide General', districts: 6, band: [-220699, -220101], sourceGate: '163' },
  // --- 164 ---------------------------------------------------------------
  { st: 'KY', fips: '21', election: 'KY 2026 Statewide General', districts: 6, band: [-210899, -210101], sourceGate: '164' },
  { st: 'OR', fips: '41', election: 'OR 2026 General', districts: 6, band: [-410699, -410101], sourceGate: '164' },
  { st: 'CT', fips: '09', election: 'CT 2026 Statewide General', districts: 5, band: [-90599, -90101], sourceGate: '164' },
  { st: 'OK', fips: '40', election: 'OK 2026 Statewide General', districts: 5, band: [-400599, -400101], sourceGate: '164' },
  { st: 'AR', fips: '05', election: 'AR 2026 Statewide General', districts: 4, band: [-50499, -50101], sourceGate: '164' },
  { st: 'IA', fips: '19', election: 'IA 2026 Statewide General', districts: 4, band: [-190499, -190101], sourceGate: '164' },
  { st: 'KS', fips: '20', election: 'KS 2026 Statewide General', districts: 4, band: [-200499, -200101], sourceGate: '164' },
  { st: 'MS', fips: '28', election: 'MS 2026 Statewide General', districts: 4, band: [-280499, -280101], sourceGate: '164' },
  // --- 165 ---------------------------------------------------------------
  { st: 'NV', fips: '32', election: 'NV 2026 Statewide General', districts: 4, band: [-320499, -320101], sourceGate: '165' },
  { st: 'UT', fips: '49', election: 'UT 2026 Statewide General', districts: 4, band: [-490499, -490101], sourceGate: '165' },
  { st: 'NM', fips: '35', election: 'NM 2026 Statewide General', districts: 3, band: [-350399, -350101], sourceGate: '165' },
  { st: 'NE', fips: '31', election: 'NE 2026 Statewide General', districts: 3, band: [-310399, -310101], sourceGate: '165' },
  { st: 'WV', fips: '54', election: 'WV 2026 Statewide General', districts: 2, band: [-540299, -540101], sourceGate: '165' },
  { st: 'ID', fips: '16', election: 'ID 2026 Statewide General', districts: 2, band: [-160299, -160101], sourceGate: '165' },
  { st: 'HI', fips: '15', election: 'HI 2026 Statewide General', districts: 2, band: [-150299, -150101], sourceGate: '165' },
  { st: 'ME', fips: '23', election: '2026 Maine General Election', districts: 2, band: [-230299, -230101], sourceGate: '165' },
  { st: 'NH', fips: '33', election: 'NH 2026 Statewide General', districts: 2, band: [-330299, -330101], sourceGate: '165' },
  { st: 'RI', fips: '44', election: 'RI 2026 Statewide General', districts: 2, band: [-440299, -440101], sourceGate: '165' },
  { st: 'MT', fips: '30', election: 'MT 2026 Statewide General', districts: 2, band: [-300299, -300101], sourceGate: '165' },
  { st: 'AK', fips: '02', election: 'AK 2026 Statewide General', districts: 1, band: [-20099, -20001], sourceGate: '165' },
  { st: 'DE', fips: '10', election: 'DE 2026 Statewide General', districts: 1, band: [-100099, -100001], sourceGate: '165' },
  { st: 'ND', fips: '38', election: 'ND 2026 Statewide General', districts: 1, band: [-380099, -380001], sourceGate: '165' },
  { st: 'SD', fips: '46', election: 'SD 2026 Statewide General', districts: 1, band: [-460099, -460001], sourceGate: '165' },
  { st: 'VT', fips: '50', election: 'VT 2026 Statewide General', districts: 1, band: [-500099, -500001], sourceGate: '165' },
  { st: 'WY', fips: '56', election: 'WY 2026 Statewide General', districts: 1, band: [-560099, -560001], sourceGate: '165' },
];

// The 4 withheld / Polygon Pending marker elections. Migrations 1247 (TN), 1248 (AL)
// and 1249 (LA) emptied three of them; only MO should still hold races.
const MARKER_ELECTIONS: { st: string; name: string }[] = [
  { st: 'TN', name: 'TN 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'MO', name: 'MO 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'AL', name: 'AL 2026 Congressional Redistricting - Polygon Pending' },
  { st: 'LA', name: 'LA 2026 Congressional Redistricting - Polygon Pending' },
];

const EXPECTED_TOTAL_DISTRICTS = 178;

// ---------------------------------------------------------------------------
// FROZEN BASELINES — transcribed verbatim from the five source gate files so the
// delta is COMPUTED, never asserted from memory.
//
// Headshot pins were pure derivation ("who lacks a politician_images row"), so the
// live list below is regenerated from scratch and these ids serve only as the delta
// baseline. 161's 167 + 162's 110 + 163's 95 + 164's 85 + 165's 109 = 566.
// ---------------------------------------------------------------------------
const FROZEN_IMG_SKIP: Record<string, number[]> = {
  '161': [
    -40901, -40802, -40801, -40701, -40603, -40601, -40506, -40505, -40504, -40502, -40501, -40404,
    -40403, -40401, -40301, -40203, -40202, -40110, -40109, -40107, -40105, -40104, -40103, -40102,
    -531005, -531004, -531003, -531002, -531001, -530904, -530903, -530901, -530805, -530804,
    -530803, -530802, -530801, -530703, -530702, -530701, -530604, -530603, -530602, -530601,
    -530511, -530510, -530509, -530508, -530507, -530506, -530505, -530504, -530503, -530502,
    -530501, -530410, -530409, -530408, -530407, -530406, -530405, -530404, -530403, -530402,
    -530401, -530308, -530307, -530306, -530304, -530303, -530302, -530301, -530203, -530202,
    -530201, -530106, -530105, -530104, -530103, -530102, -530101, -470910, -470909, -470908,
    -470905, -470904, -470903, -470902, -470901, -470810, -470809, -470808, -470807, -470806,
    -470805, -470804, -470803, -470802, -470801, -470706, -470705, -470704, -470703, -470701,
    -470611, -470610, -470609, -470608, -470607, -470606, -470605, -470604, -470603, -470602,
    -470601, -470508, -470507, -470506, -470505, -470504, -470503, -470502, -470501, -470410,
    -470409, -470408, -470407, -470406, -470405, -470404, -470403, -470402, -470401, -470307,
    -470306, -470305, -470304, -470303, -470302, -470301, -470203, -470202, -470201, -470108,
    -470107, -470106, -470105, -470104, -470103, -470102, -470101, -250902, -250901, -250802,
    -250801, -250607, -250605, -250603, -250602, -250601, -250502, -250501, -250402, -250401,
    -250301, -250102, -250101,
  ],
  '162': [
    -180902, -180801, -180702, -180701, -180601, -180501, -180401, -180301, -180202, -180201,
    -180101, -240802, -240801, -240701, -240602, -240503, -240502, -240501, -240401, -240301,
    -240201, -270804, -270803, -270802, -270801, -270702, -270701, -270603, -270602, -270601,
    -270509, -270508, -270507, -270506, -270505, -270504, -270503, -270502, -270501, -270404,
    -270403, -270402, -270401, -270302, -270301, -270207, -270206, -270204, -270202, -270104,
    -270103, -270102, -270101, -290805, -290804, -290803, -290802, -290801, -290704, -290703,
    -290702, -290701, -290609, -290608, -290607, -290606, -290605, -290604, -290603, -290602,
    -290601, -290507, -290506, -290505, -290504, -290503, -290502, -290501, -290410, -290409,
    -290408, -290407, -290406, -290405, -290404, -290403, -290402, -290401, -290306, -290305,
    -290304, -290303, -290302, -290301, -290210, -290209, -290208, -290207, -290206, -290205,
    -290204, -290203, -290202, -290201, -290107, -290106, -290105, -290104, -290103, -290102,
  ],
  '163': [
    -550803, -550802, -550801, -550707, -550706, -550705, -550704, -550703, -550702, -550701,
    -550605, -550604, -550603, -550602, -550601, -550501, -550404, -550403, -550402, -550401,
    -550303, -550301, -550201, -550104, -550103, -550102, -550101, -450701, -450602, -450601,
    -450503, -450502, -450501, -450402, -450401, -450302, -450301, -450202, -450201, -450104,
    -450103, -450101, -220605, -220604, -220603, -220602, -220601, -220513, -220512, -220511,
    -220510, -220509, -220508, -220507, -220506, -220505, -220504, -220501, -220404, -220403,
    -220402, -220401, -220303, -220302, -220301, -220201, -220102, -220101, -80701, -80601,
    -80501, -80401, -80301, -80201, -80102, -10702, -10701, -10605, -10604, -10603, -10602,
    -10601, -10501, -10401, -10301, -10206, -10205, -10204, -10203, -10202, -10201, -10105,
    -10104, -10103, -10101,
  ],
  '164': [
    -410601, -410501, -410402, -410401, -410301, -410201, -410114, -400503, -400502, -400501,
    -400402, -400401, -400301, -400202, -400201, -400145, -280402, -280302, -280301, -280202,
    -280201, -280102, -280101, -210604, -210603, -210602, -210503, -210502, -210501, -210404,
    -210403, -210402, -210301, -210300, -210202, -210201, -200410, -200409, -200408, -200407,
    -200406, -200405, -200404, -200403, -200402, -200401, -200305, -200304, -200303, -200302,
    -200301, -200212, -200211, -200210, -200106, -200105, -200104, -200103, -190402, -190401,
    -190204, -190203, -190202, -190102, -90504, -90503, -90502, -90501, -90405, -90404, -90403,
    -90402, -90401, -90303, -90302, -90301, -90201, -90104, -90103, -50401, -50302, -50301,
    -50201, -50102, -50101,
  ],
  '165': [
    -560013, -560012, -560011, -560010, -560009, -560008, -560007, -560006, -560005, -560004,
    -560003, -540203, -540202, -540201, -540102, -540101, -500008, -500007, -500006, -490402,
    -490401, -490304, -490303, -490302, -490301, -490203, -490202, -490201, -490103, -490102,
    -490101, -460001, -440202, -440201, -440102, -440101, -380001, -350382, -350251, -350126,
    -330204, -330203, -330202, -330201, -330146, -330145, -330144, -330143, -330142, -330141,
    -330139, -330138, -330137, -330136, -330135, -330134, -330133, -320480, -320479, -320301,
    -320251, -320175, -320174, -310361, -310360, -310203, -310202, -310201, -310102, -310101,
    -300286, -300285, -300103, -300101, -230103, -160205, -160204, -160203, -160202, -160201,
    -160103, -160102, -160101, -150206, -150205, -150203, -150202, -150201, -150107, -150106,
    -150105, -150104, -150102, -150101, -100048, -20018, -20017, -20016, -20015, -20014, -20013,
    -20012, -20011, -20010, -20009, -20008, -20007, -20006, -20005,
  ],
};

/**
 * Whole-record stance honest-skips frozen by the five source gates. Unlike headshot pins
 * these are JUDGMENT — each carries a documented search trail in its phase SUMMARY, and a
 * trail cannot be regenerated by a query. So the reason text is carried across VERBATIM and
 * a pin only survives if the candidate is still 0-stance today.
 * 161's 59 + 162's 24 + 163's 10 + 164's 13 + 165's 18 = 124.
 */
const FROZEN_STANCE_SKIP: { ext: number; reason: string; gate: string }[] = [
  // --- 161: AZ 4 (161-03) ------------------------------------------------
  { ext: -40301, gate: '161', reason: 'Alan Aversa AZ-3 -- no Candidate Connection survey, no site/socials beyond LinkedIn' },
  { ext: -40405, gate: '161', reason: 'John Fillmore AZ-4 -- no survey/site; only decade-old bill titles with no summaries' },
  { ext: -40603, gate: '161', reason: 'Jereme Peters AZ-6 -- no survey; Ballotpedia Contact section entirely absent' },
  { ext: -40701, gate: '161', reason: 'Daniel Butierez AZ-7 -- 2024 platform quoted by Ballotpedia is off-topic/too vague; live site failed to load' },
  // --- 161: WA 14 (161-05) -----------------------------------------------
  { ext: -531005, gate: '161', reason: 'Chris D. Chung WA-10 -- no 2026 survey, parked GoDaddy site, 0 OpenFEC results' },
  { ext: -531004, gate: '161', reason: 'Derek Maynes WA-10 -- Ballotpedia content is a 2015 unrelated-office statement; no 2026 survey/site' },
  { ext: -530901, gate: '161', reason: 'Jacob Perasso WA-9 -- 2026 survey section exists with no submitted answers; no site' },
  { ext: -530802, gate: '161', reason: 'Spencer Meline WA-8 -- completed 2026 survey read in full, entirely generic bio, no chair match' },
  { ext: -530703, gate: '161', reason: 'Gwen Kirkland WA-7 -- no survey; only a walled LinkedIn link' },
  { ext: -530701, gate: '161', reason: 'David W. Blomstrom WA-7 -- extensive but incoherent/conspiratorial record, no usable federal-24 position' },
  { ext: -530410, gate: '161', reason: 'Elpidia Saavedra WA-4 -- no survey; only a walled Facebook link' },
  { ext: -530405, gate: '161', reason: 'Favian Valencia WA-4 -- site is marketing-level headlines only, no elaborating text' },
  { ext: -530404, gate: '161', reason: 'John C. Hughs WA-4 -- no survey; only a walled Facebook link' },
  { ext: -530401, gate: '161', reason: 'Jacek "Jack" Kobiesa WA-4 -- completed 2026 survey read in full, populist rhetoric, no chair match' },
  { ext: -530307, gate: '161', reason: 'Austin Braswell WA-3 -- no survey, no campaign website found' },
  { ext: -530302, gate: '161', reason: 'John P. Roco WA-3 -- IDENTITY RISK: Ballotpedia page dominated by an apparent 2016 Hawaii Senate run (cross-state homonym); no 2026 survey' },
  { ext: -530105, gate: '161', reason: 'Mary Silva WA-1 -- completed 2026 survey + 2024 statement read in full, entirely conspiratorial content, no chair match' },
  { ext: -530103, gate: '161', reason: 'James Etzkorn WA-1 -- completed 2026 survey read in full, detailed platform genuinely does not intersect any federal-24 topic' },
  // --- 161: TN 21 (161-07, TN-1..5) --------------------------------------
  { ext: -470105, gate: '161', reason: 'Richard G. Baker TN-1 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470106, gate: '161', reason: 'Chris Campbell TN-1 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470107, gate: '161', reason: 'Billy Cody TN-1 -- bare stub; Facebook page is slogan-only, no policy content' },
  { ext: -470108, gate: '161', reason: 'Tyler Brice Mitchell McClain TN-1 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470302, gate: '161', reason: 'Bryan Martin TN-3 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470303, gate: '161', reason: 'Dean Arnold TN-3 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470305, gate: '161', reason: 'Rodney Joe King TN-3 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470307, gate: '161', reason: 'Edward John Roland TN-3 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470503, gate: '161', reason: 'DeVante R. Hill TN-5 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470507, gate: '161', reason: 'James A. Johnson TN-5 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470508, gate: '161', reason: "Micheal (Me-Haul) O'Leary TN-5 -- bare Ballotpedia stub, no campaign website found" },
  { ext: -470202, gate: '161', reason: 'Bruce Fine TN-2 -- survey + site checked, "fiscal responsibility"/debt concern with no specifics matching a chair' },
  { ext: -470203, gate: '161', reason: 'Adam Heimerman TN-2 -- survey checked, generic subsidy-redirection/due-process content, no chair match' },
  { ext: -470306, gate: '161', reason: 'Donnie Lynn Ownby TN-3 -- survey checked, term limits/education/foreign-aid generalities, no chair match' },
  { ext: -470304, gate: '161', reason: 'Jean Howard-Hill TN-3 -- only an incomplete 2024 survey; Facebook page has no policy content' },
  { ext: -470401, gate: '161', reason: 'Thomas E. Davis TN-4 -- survey checked, bare topic-name bullets with no elaboration matching a chair' },
  { ext: -470403, gate: '161', reason: 'Harold "Rocky" Jones TN-4 -- survey checked, term limits/insider-trading-ban content, none are federal-24 topics' },
  { ext: -470405, gate: '161', reason: 'Mike Cortese TN-4 -- site /issues 404s, /policies has only a donation page' },
  { ext: -470410, gate: '161', reason: 'Clay Faircloth TN-4 -- only a stale 2024 survey for a different district/party, context-mismatched' },
  { ext: -470501, gate: '161', reason: 'Charlie Hatcher TN-5 -- no 2026 survey; site is branding-only, no policy elaboration' },
  { ext: -470502, gate: '161', reason: 'Yolanda Cooper-Sutton TN-5 -- no 2026 survey; site content is generic, no specific mechanism' },
  // --- 161: TN 19 (161-09, TN-6..9) --------------------------------------
  { ext: -470607, gate: '161', reason: 'Christopher Martin Finley TN-6 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470608, gate: '161', reason: 'Miriam Leibowitz TN-6 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470611, gate: '161', reason: 'Angus Purdy TN-6 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470705, gate: '161', reason: 'Andrew J. Koontz TN-7 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470706, gate: '161', reason: 'Lowell Reynolds TN-7 -- 2026 survey checked, generic constitutional-accountability themes, no chair match' },
  { ext: -470806, gate: '161', reason: 'Wendell "Wells" Blankenship TN-8 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470807, gate: '161', reason: 'Antonio Futch TN-8 -- bare Ballotpedia stub, no campaign website found' },
  { ext: -470810, gate: '161', reason: 'Henry J. Ward, III TN-8 -- bare Ballotpedia stub (both slug variants), no campaign website found' },
  { ext: -470910, gate: '161', reason: 'Michelle Davis Head TN-9 -- bare Ballotpedia stub, BallotReady profile has no issue content' },
  { ext: -470601, gate: '161', reason: 'Natisha Brooks TN-6 -- 2020 survey (Senate run) + site content (2023 Mayor run) both context-mismatched' },
  { ext: -470606, gate: '161', reason: 'Mike Croley TN-6 -- 2025 survey checked, personal biography/values content, no chair match' },
  { ext: -470701, gate: '161', reason: 'Darden Copeland TN-7 -- 2025 survey checked, biography/term-limits content only, no chair match' },
  { ext: -470703, gate: '161', reason: 'Saletta Holloway TN-7 -- no 2026 survey; site /issues page empty/JS-blocked' },
  { ext: -470803, gate: '161', reason: 'Heidi Kuhn TN-8 -- 2026 survey checked, generic priority-list content; detailed content found is for a different race' },
  { ext: -470804, gate: '161', reason: 'Leonard Perkins TN-8 -- 2024+2026 surveys checked, bare topic-name lists with no elaboration' },
  { ext: -470808, gate: '161', reason: 'Pamela Jeanine "P." Moses TN-8 -- surveys focus on felon voting-rights restoration, no federal-24 chair addresses that specifically' },
  { ext: -470809, gate: '161', reason: 'Horace Taylor TN-8 -- 2026 survey checked, topic-label list only, no chair-matching direction' },
  { ext: -470903, gate: '161', reason: 'Jeremy Thompson TN-9 -- generic campaign-website content, no chair match' },
  { ext: -470905, gate: '161', reason: 'M. LaTroy A-Williams TN-9 -- local economic-development content across 3 cycles (2016-2026), no completed survey' },
  // --- 161: MA 1 (161-10) ------------------------------------------------
  { ext: -250902, gate: '161', reason: 'R. Tyler MacAllister MA-9 -- 4 own-site pages + Ballotpedia (no survey) + local news all biography/single-word issue labels, no chair match' },
  // --- 162: MN 4 (162-06) ------------------------------------------------
  { ext: -270207, gate: '162', reason: 'Christopher Mosel MN-2 -- no site (West St. Paul Reader "[No response]"), $0 FEC, no survey/socials/news' },
  { ext: -270501, gate: '162', reason: 'DeVelle L. Jackson MN-5 -- no site/FEC/news; isidewith hit was a different GA-Senate Develle Jackson' },
  { ext: -270505, gate: '162', reason: 'Abbey Zieska MN-5 -- pre-infrastructure; Hometown Source noted "did not have websites" at filing' },
  { ext: -270507, gate: '162', reason: 'Abena A. McKenzie MN-5 -- site is local-community-services framing, nothing maps to the 24 federal topics' },
  // --- 162: MD 1 (162-10) ------------------------------------------------
  { ext: -240502, gate: '162', reason: 'Jonathan Burruss MD-5 -- campaign site is an empty Wix placeholder; Ballotpedia 403/451; no socials/news/positions' },
  // --- 162: MO 19 (162-04) -----------------------------------------------
  { ext: -290103, gate: '162', reason: 'Carl E. Henderson MO-1 -- Civoren/GoodParty boilerplate only' },
  { ext: -290104, gate: '162', reason: 'Alissa Murphy MO-1 -- BallotReady bio only, no positions' },
  { ext: -290106, gate: '162', reason: 'Andrew Jones MO-1 -- Civoren vague growth language only' },
  { ext: -290201, gate: '162', reason: 'Elizabeth Sparks-Holmes MO-2 -- site themes only, no scale-mappable position' },
  { ext: -290302, gate: '162', reason: 'Mike Conner MO-3 -- FEC-confirmed, no site/news/social' },
  { ext: -290303, gate: '162', reason: 'Tommy Holstein MO-3 -- FEC-confirmed, no working site/news' },
  { ext: -290305, gate: '162', reason: 'Paul Wilson MO-3 -- JS-placeholder Wix platform, no extractable text' },
  { ext: -290306, gate: '162', reason: 'Jim Higgins MO-3 -- only stale 2012-2015 gubernatorial coverage' },
  { ext: -290401, gate: '162', reason: 'Heather Shelton MO-4 -- Civoren vague pledges only' },
  { ext: -290402, gate: '162', reason: 'Scott Vera MO-4 -- FEC-confirmed, no site/content' },
  { ext: -290403, gate: '162', reason: 'Jeanette Cass MO-4 -- Civoren generic phrases, unmappable' },
  { ext: -290404, gate: '162', reason: 'Hartzell Gray MO-4 -- FEC-confirmed, no policy content' },
  { ext: -290405, gate: '162', reason: 'Jordan Herrera MO-4 -- Civoren meta-political statements only' },
  { ext: -290407, gate: '162', reason: 'G Rick MO-4 -- Civoren: no bio/policy submitted' },
  { ext: -290410, gate: '162', reason: 'Thomas Holbrook MO-4 -- FEC-confirmed, ideology label only' },
  { ext: -290505, gate: '162', reason: 'Berton A. Knox MO-5 -- BallotReady-confirmed, no content' },
  { ext: -290507, gate: '162', reason: 'Randall Langkraehr MO-5 -- FEC-confirmed, unclaimed/placeholder profiles' },
  { ext: -290701, gate: '162', reason: 'John Casey MO-7 -- no site; unquotable YouTube ref only' },
  { ext: -290805, gate: '162', reason: 'Rebecca Sharpe Lombard MO-8 -- bio only, all sources walled/404' },
  // --- 163: WI 1 / AL 1 / SC 3 / LA 5 ------------------------------------
  { ext: -550402, gate: '163', reason: 'Purnima Nath WI-4 (R) -- identity/culture-war site content, nothing maps to the 24 federal topics' },
  { ext: -10101, gate: '163', reason: 'Lucas Burger AL-1 (R) -- no campaign site; Ballotpedia/BallotReady/GoodParty profiles empty of policy content' },
  { ext: -450104, gate: '163', reason: 'Margo Ellis SC-1 (Alliance) -- no site, Ballotpedia blank, trackers stubs, dormant socials' },
  { ext: -450202, gate: '163', reason: 'Dayna Alane Smith SC-2 (Workers) -- only evidence was the SC Workers Party platform (party-inference; operator-ruled skip 2026-07-06)' },
  { ext: -450402, gate: '163', reason: 'Jessica Ethridge SC-4 (Libertarian) -- 3-plank Wix template too vague to pin; 2022 Lt-Gov positions do not map to the 24 keys' },
  { ext: -220101, gate: '163', reason: 'Randall Arrington LA-1 (R) -- only party self-ID, no policy content; no site, trackers "no positions"' },
  { ext: -220102, gate: '163', reason: 'Jim Long LA-1 (D) -- zero issue content anywhere; collision-avoided a diff-spelled "Jim Lange"' },
  { ext: -220201, gate: '163', reason: 'Renada Collins LA-2 (D) -- one-page shell site (/issues,/platform,/about all 404); one dignity quote, no scale fit' },
  { ext: -220303, gate: '163', reason: 'Caleb Walker LA-3 -- no site; socials login-walled; only an indirect "Patients Over Profits" pledge' },
  { ext: -220604, gate: '163', reason: 'Peter Williams LA-6 (R) -- identity well-verified but only generic constituent-advocacy language, no scale-mappable specifics' },
  // --- 164: 13 ------------------------------------------------------------
  { ext: -200304, gate: '164', reason: 'Gavin Solomon KS-3 -- serial multi-state filer, zero KS footprint' },
  { ext: -200305, gate: '164', reason: 'Blake Stanley KS-3 -- FEC committee terminated, no site/social/positions' },
  { ext: -200401, gate: '164', reason: 'Michael Gaynor KS-4 -- fringe filer, no web presence/platform' },
  { ext: -200408, gate: '164', reason: 'Daniel Schneider KS-4 -- withdrew to a KS state-house race' },
  { ext: -90403, gate: '164', reason: 'Luz Helena Bueno CT-4 -- FEC-filed but no reachable primary source' },
  { ext: -90405, gate: '164', reason: 'Damon Lawrence Cerreta CT-4 -- FEC-filed but only generic language, unmappable' },
  { ext: -410301, gate: '164', reason: 'Loran Ayles OR-3 -- no campaign site, $0 FEC, no web presence' },
  { ext: -210403, gate: '164', reason: 'Mohammad Wael Ahmad KY-4 -- no site/questionnaire/verified social' },
  { ext: -210502, gate: '164', reason: 'Gerardo Serrano KY-5 -- no usable position evidence located' },
  { ext: -400202, gate: '164', reason: 'Ronnie Hopkins OK-2 -- 2026 site 404, only stale inferred foreign-aid line' },
  { ext: -400402, gate: '164', reason: 'Rocco Bonacci OK-4 -- no FEC/site, disability-advocacy coverage only' },
  { ext: -400503, gate: '164', reason: 'Austin Nieves OK-5 -- no FEC/site, prior run withdrawn' },
  { ext: -50302, gate: '164', reason: 'Bobby Wilson AR-3 -- positions do not map to any of the 24 scales without over-inferring' },
  // --- 165: 18 ------------------------------------------------------------
  { ext: -320479, gate: '165', reason: 'Russell Best NV-4 -- perennial IAP filer, dead domain, blank questionnaires, $6k lifetime' },
  { ext: -320480, gate: '165', reason: 'William Johnson NV-4 -- no-party filer, no FEC/site/social/news anywhere' },
  { ext: -490203, gate: '165', reason: 'Robert M. Moesinger UT-2 -- single-issue electoral-structure platform, maps to no tracked scale' },
  { ext: -490304, gate: '165', reason: 'Michael R. Stoddard UT-3 -- audits/sound-money/militia planks map to no tracked scale' },
  { ext: -20007, gate: '165', reason: 'John E. Foddrill Sr. AK -- TX whistleblower content only, no policy positions' },
  { ext: -20012, gate: '165', reason: 'Yaquelin Reynoso AK -- out-of-state MA filer, zero policy content' },
  { ext: -20013, gate: '165', reason: 'David Richey AK -- in-state but logistics-only coverage, no positions' },
  { ext: -20014, gate: '165', reason: 'Melanie A. Salazar AK -- out-of-state SF filer, explicit no-positions pages' },
  { ext: -20017, gate: '165', reason: 'John B. Williams AK -- Fairbanks teacher, filed-only, zero policy quotes' },
  { ext: -540202, gate: '165', reason: 'Pat Carney WV-2 -- $0-raised fringe filer (FEC H6WV02176), zero footprint' },
  { ext: -540203, gate: '165', reason: 'Chris Whitcomb WV-2 -- $0-raised fringe filer (FEC H6WV02168), zero footprint' },
  { ext: -160102, gate: '165', reason: 'Brendan Gomez ID-1 -- $0 FEC, no survey across 3 cycles, meme-only social' },
  { ext: -160203, gate: '165', reason: 'Carta Sierra ID-2 -- perennial candidate (legal name Idaho Law), zero policy content' },
  { ext: -150205, gate: '165', reason: 'Edward Codelia HI-2 -- survey answered but mechanism-free, no placeable chair' },
  { ext: -150206, gate: '165', reason: 'Randall Terry HI-2 -- identity unresolved vs national activist; HI-local sources silent' },
  { ext: -560005, gate: '165', reason: 'Richard Dodson WY -- Candidate Connection answered but entirely non-directional' },
  { ext: -560011, gate: '165', reason: 'Elena Del Real WY -- bio-only presence, no policy content anywhere' },
  { ext: -560013, gate: '165', reason: 'Daniel Workman WY -- FEC filer (H6WY01108), zero policy content' },
];

/** The literal reason every newly-detected 0-stance candidate carries. Never a judgment. */
const QUEUE_167_REASON =
  'new/unresearched 0-stance banded candidate detected at 166 authoring (2026-07-26); stance research queued to Phase 167';

// FIPS -> state abbreviation. 42 elections make the CASE-on-election_id form used by
// 152 and 162 unmanageable, so the state is derived from substr(geo_id,1,2) instead.
const FIPS_TO_ST: Record<string, string> = Object.fromEntries(STATES.map((s) => [s.fips, s.st]));
const GEO_PREFIXES = STATES.map((s) => s.fips);

interface HouseRow {
  fips: string;
  st: string;
  geo_id: string;
  race_id: string;
  election_id: string;
  description: string | null;
  primary_party: string | null;
  rc_id: string | null;
  politician_id: string | null;
  full_name: string | null;
  candidate_status: string | null;
  is_incumbent: boolean | null;
  external_id: string | null;
}

/** True when `ext` falls inside any of the 38 Phase-166 new-candidate bands. */
function inAnyBand(ext: number): boolean {
  return STATES.some((s) => ext >= s.band[0] && ext <= s.band[1]);
}

/**
 * Which state's band claims `ext`. When this differs from the state the candidate is
 * actually racing in, the id is a CROSS-STATE BAND COLLISION — a legacy record whose
 * external_id happens to fall inside another state's Wave-3 seeding band (CLAUDE.md:
 * "new external_id bands can be POLLUTED -> scope via race_candidates joins, not raw
 * band"). Every id here entered through a race_candidates join, so it is in scope; the
 * label just must not claim it was seeded by the band's owner.
 */
function bandOwner(ext: number): string | null {
  return STATES.find((s) => ext >= s.band[0] && ext <= s.band[1])?.st ?? null;
}

async function resolveElections(): Promise<{
  generals: Map<string, string>;
  markers: Map<string, string>;
  extras: Map<string, string>;
}> {
  const generals = new Map<string, string>();
  const markers = new Map<string, string>();
  const extras = new Map<string, string>();
  const missing: string[] = [];

  for (const s of STATES) {
    const r = await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [s.election]);
    if (!r.rows.length) missing.push(`${s.st} general: ${s.election}`);
    else generals.set(s.st, r.rows[0].id);
    for (const extra of s.extraElections ?? []) {
      const x = await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [extra]);
      if (!x.rows.length) missing.push(`${s.st} extra: ${extra}`);
      else extras.set(extra, x.rows[0].id);
    }
  }
  for (const m of MARKER_ELECTIONS) {
    const r = await pool.query('SELECT id FROM essentials.elections WHERE name = $1', [m.name]);
    if (!r.rows.length) missing.push(`${m.st} marker: ${m.name}`);
    else markers.set(m.st, r.rows[0].id);
  }
  const expected = STATES.length + MARKER_ELECTIONS.length + STATES.reduce((n, s) => n + (s.extraElections?.length ?? 0), 0);
  if (missing.length) {
    throw new Error(
      `FAIL setup: ${missing.length} of ${expected} election name(s) did not resolve:\n  ${missing.join('\n  ')}`
    );
  }
  return { generals, markers, extras };
}

async function loadHouse(electionIds: string[]): Promise<HouseRow[]> {
  const q = await pool.query(
    `SELECT substr(d.geo_id, 1, 2) AS fips,
            d.geo_id,
            r.id            AS race_id,
            r.election_id   AS election_id,
            r.description,
            r.primary_party,
            rc.id           AS rc_id,
            rc.politician_id,
            rc.full_name,
            rc.candidate_status,
            rc.is_incumbent,
            p.external_id
     FROM essentials.races r
     JOIN essentials.offices   o ON o.id = r.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
     LEFT JOIN essentials.politicians     p  ON p.id = rc.politician_id
     WHERE r.election_id = ANY($1::uuid[])
       AND d.district_type = 'NATIONAL_LOWER'
       AND substr(d.geo_id, 1, 2) = ANY($2::text[])`,
    [electionIds, GEO_PREFIXES]
  );
  return q.rows.map((r) => ({ ...r, st: FIPS_TO_ST[r.fips] })) as HouseRow[];
}

// ---------------------------------------------------------------------------
// Task 1 — scope layer: per-state census + band-filter delta.
// ---------------------------------------------------------------------------
interface Scope {
  house: HouseRow[];
  /** distinct politician_id, banded + active (the SUPERSET filter the gate uses) */
  bandedActive: Map<string, number>;
  /** distinct politician_id, banded + active + is_incumbent=false (165's stricter form) */
  bandedActiveChallengers: Map<string, number>;
  stateOf: Map<string, string>;
}

function deriveScope(house: HouseRow[]): Scope {
  // The 178 assertion is about DISTRICTS, not races. Those coincided in every prior gate
  // because each state ran one race per district — but WI now carries a general race plus
  // two party-split primary races per district, so counting race_id would read 24 for WI
  // and blow past 178 while nothing is actually wrong. Count distinct geo_id; report the
  // race count alongside it so a genuine race explosion is still visible.
  const byState = new Map<string, { districts: Set<string>; races: Set<string>; active: number; banded: Set<string> }>();
  for (const s of STATES) byState.set(s.st, { districts: new Set(), races: new Set(), active: 0, banded: new Set() });

  const bandedActive = new Map<string, number>();
  const bandedActiveChallengers = new Map<string, number>();
  const stateOf = new Map<string, string>();

  for (const row of house) {
    const bucket = byState.get(row.st);
    if (!bucket) throw new Error(`FAIL scope: geo prefix ${row.fips} (geo_id ${row.geo_id}) maps to no in-scope state`);
    bucket.districts.add(row.geo_id);
    bucket.races.add(row.race_id);
    if (row.candidate_status !== 'active') continue;
    bucket.active++;
    if (row.external_id === null || row.politician_id === null) continue;
    const ext = Number(row.external_id);
    if (!inAnyBand(ext)) continue;
    bucket.banded.add(row.politician_id);
    bandedActive.set(row.politician_id, ext);
    stateOf.set(row.politician_id, row.st);
    if (row.is_incumbent === false) bandedActiveChallengers.set(row.politician_id, ext);
  }

  console.log('=== PER-STATE CENSUS (live, %s) ===', DERIVED_AT);
  console.log('ST  FIPS  districts  races  active  banded-new');
  const mismatches: string[] = [];
  let total = 0;
  for (const s of STATES) {
    const b = byState.get(s.st)!;
    total += b.districts.size;
    const flag = b.races.size !== b.districts.size ? `  <- ${b.races.size / b.districts.size}x races/district` : '';
    console.log(
      `${s.st}  ${s.fips}      ${String(b.districts.size).padStart(3)}    ${String(b.races.size).padStart(3)}    ${String(b.active).padStart(4)}      ${String(b.banded.size).padStart(4)}${flag}`
    );
    if (b.districts.size !== s.districts) mismatches.push(`${s.st}: ${b.districts.size} districts (expected ${s.districts})`);
  }
  if (mismatches.length) {
    throw new Error(`FAIL scope: ${mismatches.length} state(s) with wrong district count:\n  ${mismatches.join('\n  ')}`);
  }
  console.log(`TOTAL DISTRICTS: ${total}`);
  if (total !== EXPECTED_TOTAL_DISTRICTS) {
    throw new Error(`FAIL scope: total districts=${total} (expected ${EXPECTED_TOTAL_DISTRICTS})`);
  }

  // Band-filter delta. The gate uses the SUPERSET `active` form (161/162/163/164) rather
  // than 165's `active AND is_incumbent=false`, because a superset demands an image-or-pin
  // from strictly MORE candidates — the safe direction for a gate. Enumerate the difference
  // so the choice is auditable rather than asserted.
  const diff = [...bandedActive.entries()].filter(([pid]) => !bandedActiveChallengers.has(pid));
  diff.sort((a, b) => b[1] - a[1]);
  console.log(
    `\nBAND FILTER DELTA: active=${bandedActive.size} active+is_incumbent=false=${bandedActiveChallengers.size} difference=${diff.length}`
  );
  let collisions = 0;
  for (const [pid, ext] of diff) {
    const racingIn = stateOf.get(pid)!;
    const owner = bandOwner(ext);
    const collided = owner !== racingIn;
    if (collided) collisions++;
    const nameRow = house.find((h) => h.politician_id === pid && h.candidate_status === 'active');
    console.log(
      `  +${racingIn} ${ext} ${nameRow?.full_name ?? '?'} — active INCUMBENT` +
        (collided
          ? `; CROSS-STATE BAND COLLISION: this id sits inside ${owner}'s band, not ${racingIn}'s (legacy record, entered via the race_candidates join)`
          : `; genuinely inside ${racingIn}'s own band`)
    );
  }
  console.log(
    `BAND FILTER DELTA DETAIL: all ${diff.length} are active incumbents; ${collisions} are cross-state band collisions, ` +
      `${diff.length - collisions} sit inside their own state's band. The gate uses the SUPERSET (active) form, so all ${diff.length} ` +
      `must carry an image-or-pin — strictly more demanding than 165's active+is_incumbent=false form.`
  );

  return { house, bandedActive, bandedActiveChallengers, stateOf };
}

// ---------------------------------------------------------------------------
// Task 2 — the two pin derivations. They are treated differently because they are
// epistemically different: headshot pins are pure derivation, stance pins are judgment.
// ---------------------------------------------------------------------------
interface Pins {
  imgSkip: { ext: number; st: string }[];
  stanceSurviving: { ext: number; st: string; reason: string; gate: string }[];
  stanceQueue167: { ext: number; st: string }[];
}

/** Descending by external_id is ascending by seq, which is how the gates lay pins out. */
const byExtDesc = (a: { ext: number }, b: { ext: number }) => b.ext - a.ext;

function groupByState(rows: { ext: number; st: string }[]): Map<string, number[]> {
  const g = new Map<string, number[]>();
  for (const r of rows) {
    if (!g.has(r.st)) g.set(r.st, []);
    g.get(r.st)!.push(r.ext);
  }
  return g;
}

async function derivePins(scope: Scope): Promise<Pins> {
  const pids = [...scope.bandedActive.keys()];

  // --- Headshot pins: pure derivation, regenerated from scratch. -----------
  const withImage = new Set<string>(
    (
      await pool.query(
        'SELECT DISTINCT pi.politician_id FROM essentials.politician_images pi WHERE pi.politician_id = ANY($1::uuid[])',
        [pids]
      )
    ).rows.map((r) => r.politician_id)
  );

  const imgSkip = pids
    .filter((pid) => !withImage.has(pid))
    .map((pid) => ({ ext: scope.bandedActive.get(pid)!, st: scope.stateOf.get(pid)! }))
    .sort(byExtDesc);

  console.log(`\n=== HEADSHOT PINS (live): ${imgSkip.length} ===`);
  const imgByState = groupByState(imgSkip);
  for (const s of STATES) {
    const ids = imgByState.get(s.st);
    if (ids?.length) console.log(`  ${s.st} (${ids.length})`);
  }

  const frozenImg = new Set(Object.values(FROZEN_IMG_SKIP).flat());
  const liveImg = new Set(imgSkip.map((r) => r.ext));
  const imgDropped = [...frozenImg].filter((e) => !liveImg.has(e)).sort((a, b) => b - a);
  const imgAdded = [...liveImg].filter((e) => !frozenImg.has(e)).sort((a, b) => b - a);
  console.log(
    `\nHEADSHOT DELTA vs frozen ${frozenImg.size}: dropped=${imgDropped.length} added=${imgAdded.length}`
  );
  if (imgDropped.length) {
    console.log('  dropped (was frozen-pinned; now has an image, or is no longer active/in-band):');
    for (const e of imgDropped) console.log(`    ${e}`);
  }
  if (imgAdded.length) {
    console.log('  added (newly lacks an image):');
    for (const e of imgAdded) console.log(`    ${scope.stateOf.get([...scope.bandedActive].find(([, x]) => x === e)![0])} ${e}`);
  }

  // --- Stance pins: judgment. A trail cannot be regenerated by a query. ----
  const answerCounts = new Map<string, number>(
    (
      await pool.query(
        'SELECT a.politician_id, COUNT(*)::int AS n FROM inform.politician_answers a WHERE a.politician_id = ANY($1::uuid[]) GROUP BY 1',
        [pids]
      )
    ).rows.map((r) => [r.politician_id, r.n])
  );

  const liveZero = new Map<number, string>(); // external_id -> state
  for (const [pid, ext] of scope.bandedActive) {
    if ((answerCounts.get(pid) ?? 0) < 1) liveZero.set(ext, scope.stateOf.get(pid)!);
  }

  const stanceSurviving: Pins['stanceSurviving'] = [];
  const stanceRetired: { ext: number; reason: string; gate: string }[] = [];
  for (const f of FROZEN_STANCE_SKIP) {
    if (liveZero.has(f.ext)) {
      stanceSurviving.push({ ext: f.ext, st: liveZero.get(f.ext)!, reason: f.reason, gate: f.gate });
    } else {
      stanceRetired.push(f);
    }
  }
  stanceSurviving.sort(byExtDesc);

  const stanceQueue167 = [...liveZero.entries()]
    .filter(([ext]) => !FROZEN_STANCE_SKIP.some((f) => f.ext === ext))
    .map(([ext, st]) => ({ ext, st }))
    .sort(byExtDesc);

  console.log(`\n=== STANCE PINS surviving: ${stanceSurviving.length} of frozen ${FROZEN_STANCE_SKIP.length} ===`);
  for (const s of stanceSurviving) console.log(`  [${s.gate}] ${s.st} ${s.ext} — ${s.reason}`);

  // Classify each retired pin: acquired a stance, or left the in-scope universe.
  console.log(`\n=== STANCE retired: ${stanceRetired.length} ===`);
  if (stanceRetired.length) {
    const retiredExts = stanceRetired.map((r) => r.ext);
    const status = new Map<number, { answers: number; activeRows: number; exists: boolean }>(
      (
        await pool.query(
          `SELECT p.external_id,
                  (SELECT COUNT(*)::int FROM inform.politician_answers a WHERE a.politician_id = p.id) AS answers,
                  (SELECT COUNT(*)::int FROM essentials.race_candidates rc
                    WHERE rc.politician_id = p.id AND rc.candidate_status = 'active') AS active_rows
           FROM essentials.politicians p
           WHERE p.external_id = ANY($1::bigint[])`,
          [retiredExts]
        )
      ).rows.map((r) => [Number(r.external_id), { answers: r.answers, activeRows: r.active_rows, exists: true }])
    );
    const inScope = new Set(scope.bandedActive.values());
    for (const r of stanceRetired) {
      const s = status.get(r.ext);
      let why: string;
      if (!s) why = 'politician row no longer exists under this external_id';
      else if (inScope.has(r.ext)) why = `still in-scope but has since acquired ${s.answers} stance row(s)`;
      else if (s.activeRows === 0) why = `no longer an active candidate anywhere (${s.answers} stance row(s))`;
      else why = `active elsewhere but outside the Phase-166 banded in-scope universe (${s.answers} stance row(s))`;
      console.log(`  [${r.gate}] ${r.ext} — ${why}  <<${r.reason}>>`);
    }
  }

  console.log(`\n=== STANCE queue-167: ${stanceQueue167.length} ===`);
  for (const q of stanceQueue167) console.log(`  ${q.st} ${q.ext} — ${QUEUE_167_REASON}`);

  if (stanceSurviving.length + stanceRetired.length !== FROZEN_STANCE_SKIP.length) {
    throw new Error(
      `FAIL stance partition: surviving ${stanceSurviving.length} + retired ${stanceRetired.length} <> frozen ${FROZEN_STANCE_SKIP.length}`
    );
  }

  return { imgSkip, stanceSurviving, stanceQueue167 };
}

// ---------------------------------------------------------------------------
// Task 3 — the PROVISIONAL and withheld censuses, then the consumable artifact.
// ---------------------------------------------------------------------------
interface Censuses {
  provMarked: { st: string; races: number }[];
  provUnmarked: { st: string; races: number }[];
  totalRaces: number;
  withheld: { st: string; races: number; geoIds: string[] }[];
}

function deriveCensuses(house: HouseRow[], markers: Map<string, string>): Censuses {
  // --- PROVISIONAL census -------------------------------------------------
  // Phases 161, 162 and 163 authored NO PROVISIONAL assertion at all, so this is a
  // genuinely new derivation and the only authority for what 166-verify.sql may assert.
  // Phase 167 clears these flags per primary-date cluster, so the gate asserts TODAY's
  // state and 167 will move states between the two lists.
  const raceMarked = new Map<string, { st: string; marked: boolean }>();
  for (const row of house) {
    if (raceMarked.has(row.race_id)) continue;
    raceMarked.set(row.race_id, { st: row.st, marked: (row.description ?? '').includes('PROVISIONAL:') });
  }
  const perState = new Map<string, { marked: number; unmarked: number }>();
  for (const s of STATES) perState.set(s.st, { marked: 0, unmarked: 0 });
  for (const { st, marked } of raceMarked.values()) {
    const b = perState.get(st)!;
    if (marked) b.marked++;
    else b.unmarked++;
  }

  const provMarked: { st: string; races: number }[] = [];
  const provUnmarked: { st: string; races: number }[] = [];
  const provMixed: string[] = [];
  for (const s of STATES) {
    const b = perState.get(s.st)!;
    if (b.marked > 0) provMarked.push({ st: s.st, races: b.marked });
    if (b.unmarked > 0) provUnmarked.push({ st: s.st, races: b.unmarked });
    if (b.marked > 0 && b.unmarked > 0) provMixed.push(`${s.st} (${b.marked} marked / ${b.unmarked} unmarked)`);
  }
  const totalRaces = raceMarked.size;
  const accounted = provMarked.reduce((n, x) => n + x.races, 0) + provUnmarked.reduce((n, x) => n + x.races, 0);

  console.log(
    `\nPROVISIONAL CENSUS: marked=${provMarked.map((x) => `${x.st}:${x.races}`).join(' ')} | ` +
      `unmarked=${provUnmarked.map((x) => `${x.st}:${x.races}`).join(' ')}`
  );
  console.log(
    `PROVISIONAL TOTALS: ${provMarked.reduce((n, x) => n + x.races, 0)} marked + ` +
      `${provUnmarked.reduce((n, x) => n + x.races, 0)} unmarked = ${accounted} of ${totalRaces} in-scope races ` +
      `(0 unaccounted). Those ${totalRaces} races span the ${EXPECTED_TOTAL_DISTRICTS} in-scope districts — ` +
      `WI alone contributes 24 races over 8 districts (general + two party primaries).`
  );
  if (accounted !== totalRaces) {
    throw new Error(`CENSUS MISMATCH: PROVISIONAL accounted ${accounted} of ${totalRaces} races`);
  }
  if (provMixed.length) {
    console.log(
      `PROVISIONAL SPLIT STATES (cannot be asserted whole-state; 166-verify.sql must assert these per-race): ${provMixed.join(', ')}`
    );
  }

  // --- Withheld census ----------------------------------------------------
  // Expected after migrations 1247 (TN), 1248 (AL) and 1249 (LA): those three marker
  // elections hold 0 races, and only MO's still holds any — exactly 2902..2906.
  const markerById = new Map([...markers.entries()].map(([st, id]) => [id, st]));
  const withheldMap = new Map<string, Set<string>>();
  for (const m of MARKER_ELECTIONS) withheldMap.set(m.st, new Set());
  const withheldRaces = new Map<string, Set<string>>();
  for (const m of MARKER_ELECTIONS) withheldRaces.set(m.st, new Set());
  for (const row of house) {
    const st = markerById.get(row.election_id);
    if (!st) continue;
    withheldMap.get(st)!.add(row.geo_id);
    withheldRaces.get(st)!.add(row.race_id);
  }

  const withheld = MARKER_ELECTIONS.map((m) => ({
    st: m.st,
    races: withheldRaces.get(m.st)!.size,
    geoIds: [...withheldMap.get(m.st)!].sort(),
  }));

  // Reported in TN / AL / LA / MO order — the three emptied markers first, then the one
  // that legitimately still holds races.
  const REPORT_ORDER = ['TN', 'AL', 'LA', 'MO'];
  const summary = REPORT_ORDER.map((st) => `${st} ${withheld.find((w) => w.st === st)!.races}`).join(' / ');
  console.log(`\nWITHHELD CENSUS: ${summary}`);
  for (const w of withheld) {
    if (w.geoIds.length) console.log(`  ${w.st} geo_ids: ${w.geoIds.join(', ')}`);
  }

  const mo = withheld.find((w) => w.st === 'MO')!;
  const expectedMo = ['2902', '2903', '2904', '2905', '2906'];
  const emptyOnes = withheld.filter((w) => w.st !== 'MO');
  const badEmpty = emptyOnes.filter((w) => w.races !== 0);
  const moOk = mo.geoIds.length === expectedMo.length && mo.geoIds.every((g, i) => g === expectedMo[i]);
  if (badEmpty.length || !moOk) {
    console.error(
      `CENSUS MISMATCH: expected TN 0 / AL 0 / LA 0 / MO 5 with geo_ids ${expectedMo.join(', ')}; ` +
        `got ${summary} with MO geo_ids ${mo.geoIds.join(', ') || '(none)'}`
    );
    throw new Error('CENSUS MISMATCH — refusing to emit a fragment that encodes a wrong world');
  }

  return { provMarked, provUnmarked, totalRaces, withheld };
}

/** Single-quote escaping for a SQL string literal. */
const sq = (s: string) => `'${s.replace(/'/g, "''")}'`;

function emitFragment(scope: Scope, pins: Pins, censuses: Censuses, house: HouseRow[]): string {
  const L: string[] = [];
  const frozenImg = new Set(Object.values(FROZEN_IMG_SKIP).flat());
  const liveImg = new Set(pins.imgSkip.map((r) => r.ext));
  const dropped = [...frozenImg].filter((e) => !liveImg.has(e));
  const added = [...liveImg].filter((e) => !frozenImg.has(e));
  const retired = FROZEN_STANCE_SKIP.length - pins.stanceSurviving.length;

  L.push('-- === 166 CENSUS HEADER ===');
  L.push(`-- Generated by backend/scripts/166-derive-pins.ts against production on ${DERIVED_AT}.`);
  L.push('-- Read-only derivation. Pasted verbatim into 166-verify.sql (166-03) and consumed by');
  L.push('-- 166-verify-invariants.sql (166-04). Contains only comments and INSERTs into the three');
  L.push('-- temp tables the gate declares; no DDL of its own, and nothing that writes essentials/inform.');
  L.push('--');
  L.push('-- SCOPE: 43 elections — 38 state generals, 4 Polygon Pending markers, and');
  L.push("--   'WI 2026 Partisan Primary'. That last one is a LIVE CORRECTION to the 42 the plan");
  L.push('--   listed from the 163 snapshot: the WI primary election row was created 2026-07-25 and');
  L.push("--   now holds WI's field (32 active, 7 incumbents) while the WI general holds 5 with 4 of");
  L.push('--   8 races empty. IN and UT also have House primaries, but theirs are past (2026-05-05,');
  L.push('--   2026-06-23) and hold only concluded contests, so they stay out.');
  L.push('--');
  L.push('-- 1. PER-STATE DISTRICT CENSUS (districts / races / active / banded-new)');
  const byState = new Map<string, { d: Set<string>; r: Set<string>; a: number; b: Set<string> }>();
  for (const s of STATES) byState.set(s.st, { d: new Set(), r: new Set(), a: 0, b: new Set() });
  for (const row of house) {
    const x = byState.get(row.st)!;
    x.d.add(row.geo_id);
    x.r.add(row.race_id);
    if (row.candidate_status === 'active') x.a++;
    if (row.politician_id && scope.bandedActive.has(row.politician_id)) x.b.add(row.politician_id);
  }
  for (const s of STATES) {
    const x = byState.get(s.st)!;
    L.push(`--   ${s.st} ${s.fips}: ${x.d.size} districts / ${x.r.size} races / ${x.a} active / ${x.b.size} banded-new`);
  }
  L.push(`--   TOTAL DISTRICTS: ${[...byState.values()].reduce((n, x) => n + x.d.size, 0)} (across ${censuses.totalRaces} races)`);
  L.push('--');
  L.push('-- 2. BAND FILTER DELTA');
  L.push(
    `--   active=${scope.bandedActive.size} vs active+is_incumbent=false=${scope.bandedActiveChallengers.size}; ` +
      `difference=${scope.bandedActive.size - scope.bandedActiveChallengers.size}, all active incumbents.`
  );
  L.push('--   The gate uses the SUPERSET (active) form 161-164 used, not 165\'s stricter form:');
  L.push('--   a superset demands an image-or-pin from strictly more candidates. 12 of the difference');
  L.push('--   are cross-state band collisions (4 KS incumbents inside AK\'s band, 8 MA inside KS\'s);');
  L.push('--   all entered via the race_candidates join, so all are legitimately in scope.');
  L.push('--');
  L.push('-- 3. HEADSHOT DELTA');
  L.push(`--   live=${pins.imgSkip.length} vs frozen ${frozenImg.size} (161:167 + 162:110 + 163:95 + 164:85 + 165:109)`);
  L.push(`--   dropped=${dropped.length} (acquired an image, or no longer active/in-band); added=${added.length}`);
  L.push('--');
  L.push('-- 4. STANCE PIN PARTITION');
  L.push(`--   surviving=${pins.stanceSurviving.length} of frozen ${FROZEN_STANCE_SKIP.length} (reasons carried VERBATIM from the source gates)`);
  L.push(`--   retired=${retired}; queue_167=${pins.stanceQueue167.length}`);
  L.push('--   queue_167 candidates are 0-stance TODAY but carry no documented search trail. They are');
  L.push('--   deliberately NOT merged into _stance_skip — nobody made that research judgment.');
  L.push('--');
  L.push('-- 5. PROVISIONAL CENSUS (asserts TODAY; Phase 167 clears flags per primary-date cluster,');
  L.push('--    so states will move between these two lists)');
  L.push(`--   marked:   ${censuses.provMarked.map((x) => `${x.st}:${x.races}`).join(' ') || '(none)'}`);
  L.push(`--   unmarked: ${censuses.provUnmarked.map((x) => `${x.st}:${x.races}`).join(' ') || '(none)'}`);
  L.push('--');
  L.push('-- 6. WITHHELD CENSUS (Polygon Pending markers; migrations 1247/1248/1249 emptied TN/AL/LA)');
  for (const w of censuses.withheld) {
    L.push(`--   ${w.st}: ${w.races} race(s)${w.geoIds.length ? ` — geo_ids ${w.geoIds.join(', ')}` : ''}`);
  }
  L.push('-- === END 166 CENSUS HEADER ===');
  L.push('');

  // --- _img_skip ----------------------------------------------------------
  L.push(`-- Headshot honest-skips: ${pins.imgSkip.length} banded active candidates with no`);
  L.push('-- essentials.politician_images row, regenerated live (pure derivation, not judgment).');
  L.push('-- Grouped by state in Wave-3 order; within a group ordered by external_id DESCENDING,');
  L.push('-- which reads as ascending district then seq. Ten ids per line.');
  L.push('INSERT INTO _img_skip (external_id) VALUES');
  const imgByState = groupByState(pins.imgSkip);
  const groups = STATES.filter((s) => (imgByState.get(s.st)?.length ?? 0) > 0);
  groups.forEach((s, gi) => {
    const ids = imgByState.get(s.st)!;
    L.push(`  -- ${s.st} (${ids.length})`);
    for (let i = 0; i < ids.length; i += 10) {
      const chunk = ids.slice(i, i + 10).map((e) => `(${e})`).join(',');
      const isLastLine = gi === groups.length - 1 && i + 10 >= ids.length;
      L.push(`  ${chunk}${isLastLine ? '' : ','}`);
    }
  });
  L.push(';');
  L.push('');

  // --- _stance_skip -------------------------------------------------------
  L.push(`-- Whole-record stance honest-skips: ${pins.stanceSurviving.length} of the 124 frozen across`);
  L.push('-- 161-165 that are STILL 0-stance and still in the banded in-scope universe. Each reason is');
  L.push('-- carried verbatim from its source gate file — a documented search trail cannot be');
  L.push('-- regenerated by a query, so these are intersected, never recomputed.');
  L.push('INSERT INTO _stance_skip (external_id, reason) VALUES');
  pins.stanceSurviving.forEach((s, i) => {
    L.push(`  (${s.ext}, ${sq(s.reason)})${i === pins.stanceSurviving.length - 1 ? '' : ','}  -- [${s.gate}] ${s.st}`);
  });
  L.push(';');
  L.push('');

  // --- _stance_queue_167 --------------------------------------------------
  L.push(`-- Phase-167 queue: ${pins.stanceQueue167.length} banded active candidate(s) that are 0-stance today but`);
  L.push('-- carry NO documented search trail. Kept separate from _stance_skip on purpose: recording a');
  L.push('-- dated state of the world is honest, asserting a research judgment nobody made is not.');
  if (!pins.stanceQueue167.length) {
    L.push('-- (empty)');
  } else {
    L.push('INSERT INTO _stance_queue_167 (external_id, reason) VALUES');
    pins.stanceQueue167.forEach((q, i) => {
      L.push(`  (${q.ext}, ${sq(QUEUE_167_REASON)})${i === pins.stanceQueue167.length - 1 ? '' : ','}  -- ${q.st}`);
    });
    L.push(';');
  }
  L.push('');

  return L.join('\n');
}

async function main() {
  const { generals, markers, extras } = await resolveElections();
  const allElectionIds = [...generals.values(), ...markers.values(), ...extras.values()];
  console.log(
    `Resolved ${allElectionIds.length} elections (${generals.size} generals + ${markers.size} Polygon Pending markers + ` +
      `${extras.size} live-correction extra${extras.size === 1 ? '' : 's'}: ${[...extras.keys()].join(', ') || 'none'}).`
  );
  console.log(
    `SCOPE CORRECTION: the plan specified 42 elections from the 163 snapshot. 'WI 2026 Partisan Primary' ` +
      `(2026-08-11, election row created 2026-07-25) now holds WI's field — 32 active incl. 7 incumbents — ` +
      `while the WI general holds 5 with 4 of 8 races empty. Scoping WI to the general alone would ignore 32 candidates.\n`
  );

  const house = await loadHouse(allElectionIds);
  const scope = deriveScope(house);
  const pins = await derivePins(scope);
  const censuses = deriveCensuses(house, markers);

  const outPath = new URL('166-pins.generated.sql', import.meta.url);
  writeFileSync(outPath, emitFragment(scope, pins, censuses, house), 'utf8');
  console.log(`\nWROTE ${fileURLToPath(outPath)}`);

  await pool.end();
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
