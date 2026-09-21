#!/usr/bin/env node
/**
 * Generate migration 1889: re-source the six Texas Deportation Priorities rows that migration 1888
 * deliberately left standing. Each was seated in Season 1 on one thin member-specific leg. All six
 * were re-researched on 2026-09-21 from sources that were actually fetched; four now rest on the
 * member's own words or their own filed legislation, and two become dated, sourced blanks.
 * Season 1 is never touched.
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv[2];
if (!OUT) { console.error('need out path'); process.exit(2); }

const S1 = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
const S2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const TOPIC = '44905f3b-e105-4f6c-afc7-5d223813dbac';   // Deportation Priorities
const REV_S2 = '55c3167e-3ad8-425d-a699-b2e91552d912';  // its Season 2 pin

// The Season 2 ladder this pin carries, read from compass_stance_revisions (never from the frozen
// compass_stances.text): 1 stop deportations entirely / 2 only those convicted of serious violent
// crimes / 3 recent arrivals only, long-settled left in place / 4 all undocumented, starting with
// those who have criminal records / 5 a mass-deportation programme including long-settled families
// and workers.
//
// ⚠ Every URL below was FETCHED (HTTP 200) during the research pass and the quoted text was read off
// the fetched body. No citation here is a reconstructed slug.
// ⚠ No row names a party: party is never displayed by this product and must not be derived from.
const ROWS = [
  {
    name: 'Mayes Middleton', s1: 5, value: 5,
    reasoning:
      'Middleton stated the position himself, while outlining his priorities as a candidate for attorney general: '
      + '"We have to deport all illegal immigrants. Not some. All." He named backing federal deportation efforts as his '
      + 'top priority, and pledged to use the state ban on sanctuary cities to sue local officials for civil and criminal '
      + 'penalties and removal from office if they obstruct federal immigration operations (KLTV, 2026-02-01). '
      + '"Not some. All" rules out any partial or prioritised removal, and that is precisely what separates this rung from '
      + 'deporting everyone without legal status while starting with those who have criminal records. In the 89th '
      + 'Legislature he also coauthored SB 8, the enacted requirement that sheriffs in larger counties seek 287(g) '
      + 'agreements with Immigration and Customs Enforcement, and SJR 1, a proposed constitutional amendment denying bail '
      + 'to people without legal status charged with a felony.',
    sources: [
      'https://www.kltv.com/2026/02/02/republican-candidate-attorney-general-pledges-sanctuary-city-crackdowns-transgender-sports-ban/',
      'https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=SB8',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A1350',
    ],
  },
  {
    name: 'Jared Patterson', s1: 4, value: 4,
    reasoning:
      'Patterson described the state’s removal authority approvingly and in his own words, claiming credit for it: '
      + '"We passed the strongest border security bill in the country, where law enforcement can now collect and deport '
      + 'illegal immigrants from across the state, along with $6.6 billion in funding for border security" (FOX 4 '
      + 'Dallas-Fort Worth, 2024-01-21). Endorsing the collection and removal of undocumented immigrants generally and '
      + 'statewide rules out the rungs limited to people convicted of serious violent crimes or to recent arrivals. He '
      + 'does not describe a mass programme reaching long-settled families and workers, so this sits at deporting everyone '
      + 'without legal status, starting with those who have criminal records, rather than at the top rung. His filing '
      + 'record in the 89th Legislature contains no removal instrument, so this chair rests on the statement.',
    sources: [
      'https://www.fox4news.com/news/texas-the-issue-is-republican-in-fighting',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A3655',
    ],
  },
  {
    name: 'Lois Kolkhorst', s1: 4, value: 4,
    reasoning:
      'Kolkhorst coauthored SB 8 of the 89th Legislature, signing on 2025-03-19 — "agreements between certain sheriffs '
      + 'and the United States Immigration and Customs Enforcement to enforce federal immigration law and a grant program '
      + 'to cover the costs of implementing those agreements", which requires sheriffs in counties above 100,000 people to '
      + 'seek a 287(g) agreement. It was enacted, effective 2026-01-01. Committing county jails statewide to cooperate in '
      + 'federal removal reaches everyone booked into them rather than only people convicted of serious violent crimes, '
      + 'and it sorts by criminal contact rather than by how long someone has lived here — which places her at '
      + 'deporting everyone without legal status, starting with those who have criminal records. This chair rests on that '
      + 'instrument and not on a statement of her own: no first-person statement about how far removal should go was '
      + 'found. Her other immigration-adjacent bills that session concern real property, voter registration and state '
      + 'employment, none of which is a removal instrument.',
    sources: [
      'https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=SB8',
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB8',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A1105',
    ],
  },
  {
    name: 'Katrina Pierson', s1: 5, value: 4,
    reasoning:
      'Pierson is a listed joint author of HB 1832 of the 89th Legislature, which raises criminal penalties for illegal '
      + 'entry into and reentry to the state. The committee’s own bill analysis states that it "seeks to ... increase '
      + 'the penalties for illegal entry and reentry for those with prior criminal" convictions, enhancing the penalty for '
      + 'reentry after a removal that followed a felony offence against the person. She also coauthored HB 2361, which '
      + 'would have provided for agreements between local law enforcement agencies and Immigration and Customs Enforcement '
      + 'to enforce federal immigration law. Neither bill passed. Together these place her at the enforcement end of this '
      + 'question, and because both are keyed to criminal conduct rather than to length of residence, they support '
      + 'deporting everyone without legal status starting with those who have criminal records — not a mass programme '
      + 'reaching long-settled families and workers, which the explicit prioritisation in her own bill argues against. '
      + 'This chair rests on her filed legislation rather than on a statement of her own.',
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1832',
      'https://capitol.texas.gov/tlodocs/89R/analysis/html/HB01832H.htm',
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2361',
    ],
  },
  {
    name: 'Don McLaughlin', s1: 4, value: 0,
    reasoning:
      'Blank in Season 2 — researched on 2026-09-21, and nothing on record reaches any rung of this ladder. Asked '
      + 'directly in an October 2024 candidate questionnaire what policies he would advocate on border security and '
      + 'immigration reform, McLaughlin answered at length: prioritise strong border security, and "common-sense '
      + 'immigration reform that strengthens legal immigration, respects the rule of law, and protects American jobs", by '
      + '"securing the border first, streamlining the legal immigration process for those who wish to contribute to our '
      + 'economy, and ensuring that those who break the law face the appropriate consequences." That answers the question '
      + 'put to him without saying how far removal should go: "appropriate consequences" does not distinguish deporting '
      + 'only people convicted of serious crimes from deporting everyone without legal status. His filing record in the '
      + '89th Legislature contains no removal instrument either — his immigration-related filings concern a border '
      + 'security commission, real property, voter registration, bail for people charged with felonies, and land use in '
      + 'border counties. The sources on this row are the pages that were examined and found insufficient. Season 1 keeps '
      + 'the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that '
      + 'the opposite is true: it says the question has not been answered on this person, and it is re-researchable from '
      + 'here.',
    sources: [
      'https://www.lmtonline.com/local/article/election-q-a-texas-house-district-80-don-19829550.php',
      'https://www.lmtonline.com/local/article/texas-house-district-80-r-don-mclaughlin-jr-18663878.php',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A4655',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4655',
    ],
  },
  {
    name: 'Jeffrey Barry', s1: 4, value: 0,
    reasoning:
      'Blank in Season 2 — researched on 2026-09-21, and nothing on record reaches any rung of this ladder. Barry’s '
      + 'own campaign platform treats immigration entirely as interdiction at the border. Its single immigration section '
      + 'reads: "What crosses our southern border doesn’t stay there. Cartels and smugglers are moving fentanyl and '
      + 'trafficking human beings straight into our communities", and promises to "make border security a top priority by '
      + 'increasing our border security resources and putting more law enforcement on the front lines." The independent '
      + 'record of his issue stances adds only expanding the wall, increasing border patrols and strengthening ports of '
      + 'entry. None of that is a position on removing people who already live here. His filing record in the 89th '
      + 'Legislature includes no authored immigration bill at all, and only two immigration-adjacent coauthorships, on '
      + 'real property and on voter registration. The sources on this row are the pages that were examined and found '
      + 'insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This '
      + 'is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, '
      + 'and it is re-researchable from here.',
    sources: [
      'https://www.votejeffbarry.com/issues',
      'https://www.ballotready.org/people/jeffrey-barry',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A4405',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4405',
    ],
  },
];

const NAMES = ROWS.map((r) => r.name);

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: db } = await pool.query(`
  SELECT p.id, p.full_name, a.value::int AS s1_chair
  FROM essentials.politicians p
  JOIN inform.politician_answers a ON a.politician_id=p.id AND a.topic_id=$2 AND a.season_id=$3
  WHERE p.full_name = ANY($1::text[])
  ORDER BY p.full_name`, [NAMES, TOPIC, S1]);
await pool.end();

if (db.length !== NAMES.length) {
  console.error(`resolved ${db.length} of ${NAMES.length} — refusing to generate`);
  console.error('missing:', NAMES.filter((n) => !db.some((r) => r.full_name === n)));
  process.exit(3);
}
const dupes = db.map((r) => r.full_name).filter((n, i, a) => a.indexOf(n) !== i);
if (dupes.length) { console.error('ambiguous names:', dupes); process.exit(3); }

// The Season 1 chair each row claims must be the Season 1 chair the database actually holds —
// otherwise the prose in this migration is describing a row that has since moved.
for (const r of ROWS) {
  const hit = db.find((d) => d.full_name === r.name);
  r.id = hit.id;
  if (hit.s1_chair !== r.s1) {
    console.error(`${r.name}: expected Season 1 chair ${r.s1}, database holds ${hit.s1_chair} — refusing`);
    process.exit(3);
  }
}
// Every row must carry at least one source, and no row may consist only of bare-root URLs
// (PRIMARY_SITE_NO_PATH is baselined at an exact number and would grow).
for (const r of ROWS) {
  if (!r.sources.length) { console.error(`${r.name}: no sources`); process.exit(3); }
  const hasPath = r.sources.some((s) => /^https?:\/\/[^/]+\/.+/.test(s));
  if (!hasPath) { console.error(`${r.name}: every source is a bare root`); process.exit(3); }
  const bad = r.sources.filter((s) => !/^https?:\/\//.test(s));
  if (bad.length) { console.error(`${r.name}: non-URL source(s)`, bad); process.exit(3); }
}
const seated = ROWS.filter((r) => r.value > 0);
const blanks = ROWS.filter((r) => r.value === 0);
console.log(`${ROWS.length} rows — ${seated.length} seated (${seated.map((r) => `${r.name} ${r.s1}->${r.value}`).join(', ')}), ${blanks.length} blank (${blanks.map((r) => r.name).join(', ')})`);

const q = (s) => `$r$${s}$r$`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const ctx = ROWS.map((r) => `  -- ${r.name} (S1 chair ${r.s1} -> ${r.value === 0 ? 'blank' : `chair ${r.value}`})\n  ('${r.id}',${q(r.reasoning)},${arr(r.sources)})`);
const ans = ROWS.map((r) => `  -- ${r.name}\n  ('${r.id}',${r.value})`);
const ids = ROWS.map((r) => `'${r.id}'`).join(',');

const sql = `-- 1889_tx_deportation_resource_six_season2.sql
-- Re-source the six Texas Deportation Priorities rows that migration 1888 deliberately left standing.
-- 6 context rows + 6 answer rows INSERTED in Season 2. Nothing updated, nothing deleted.
-- SEASON 1 IS NOT TOUCHED.
--
-- Migration 1888 blanked 9 of the 16 rows in this cohort and left 7 alone: Janie Lopez held on her
-- own platform, and these six each carried exactly one thin member-specific leg -- a vague "voiced
-- concern", a Wikipedia characterisation, an unquoted campaign platform, an unsourced Trump-agenda
-- association, a $6bn border-security appropriation, and an endorsement blurb about an unnamed bill.
-- Too thin for the chairs they held, but re-sourcing work rather than blanks. This is that work.
--
-- 🔴 EVERY URL CITED HERE WAS ACTUALLY FETCHED (HTTP 200) AND THE QUOTED TEXT WAS READ OFF THE
-- FETCHED BODY. No citation is a reconstructed slug -- that is the failure mode this corpus has paid
-- for repeatedly. Two candidate sources were FOUND AND DELIBERATELY DISCARDED, which is the part
-- worth keeping:
--   * Pierson's 2016 Fox News "O'Reilly Factor" appearance, where she speaks as the Trump campaign's
--     national spokesperson describing HIS policy ("Mr. Trump wants to prioritize this process").
--     A spokesperson relaying a principal's platform ten years ago is not her own position, and
--     seating a chair on it would reproduce the exact defect this audit exists to correct.
--   * Everything said by **Tricia McLaughlin**, a federal homeland-security official who speaks
--     about deportations constantly and is NOT Don McLaughlin. An identity trap with a live payload.
--
-- ✅ TWO ROWS NOW REST ON THE MEMBER'S OWN WORDS -- which is what this ladder needs and almost never
-- gets:
--   * **Mayes Middleton (chair 5 CONFIRMED, and now evidenced)**: *"We have to deport all illegal
--     immigrants. Not some. All."* -- KLTV, 2026-02-01. "Not some. All" explicitly rejects any
--     prioritised or partial removal, and that is exactly what separates rung 5 from rung 4. His
--     chair was previously seated on a Trump endorsement blurb praising an unnamed border bill plus
--     his "most conservative" record. The chair was right; the reasoning was not.
--   * **Jared Patterson (chair 4 CONFIRMED)**: *"We passed the strongest border security bill in the
--     country, where law enforcement can now collect and deport illegal immigrants from across the
--     state..."* -- FOX 4 Dallas-Fort Worth, 2024-01-21.
--
-- ⚖ TWO ROWS KEEP A CHAIR THAT NOW RESTS ON THE MEMBER'S OWN FILED LEGISLATION, and each says so in
-- its own reasoning rather than implying a statement exists:
--   * **Lois Kolkhorst (chair 4, re-sourced)**: coauthor of **SB 8 (89R)**, signed on 2025-03-19 --
--     the sheriff/287(g) ICE-agreement mandate, **ENACTED, effective 2026-01-01**. This replaces the
--     "$6 billion for border security" figure sourced only to her own senate profile page. SB 8 is
--     the instrument the audit already recorded as genuinely topical and sound (87 rows rest on it).
--   * **Katrina Pierson (chair 5 REFUTED -> chair 4)**: joint author of **HB 1832 (89R)**. 🔑 READ
--     THE ANALYSIS, NOT THE CAPTION: the caption says "illegal entry into or illegal presence", but
--     the committee's own bill analysis says it "seeks to ... increase the penalties for illegal
--     entry and reentry **for those with prior criminal**" convictions. It is explicitly
--     criminal-record-prioritised, which is rung 4's logic and the direct opposite of rung 5's
--     "including long-settled families and workers". Also coauthor of HB 2361 (local law enforcement
--     / ICE agreements). Neither bill passed, and the reasoning says so.
--
-- 🔴 TWO ROWS BECOME DATED, SOURCED BLANKS (value 0). Both are evidence OF ABSENCE, not merely
-- absence of evidence -- the member answers an immigration question directly, or publishes a full
-- immigration platform, and neither reaches any rung:
--   * **Don McLaughlin**: asked point-blank in an Oct 2024 candidate questionnaire what he would do
--     on border security and immigration reform, he answered at length and never said how far
--     removal should go. "Those who break the law face the appropriate consequences" does not
--     distinguish rung 2 from rung 4. His 89R filing record holds no removal instrument.
--   * **Jeffrey Barry**: his own issues page treats immigration purely as cartels, fentanyl,
--     trafficking and more patrols. He has **no authored immigration bill at all** in the 89th and
--     only two immigration-adjacent coauthorships, on real property and voter registration.
--
-- 🔑 THE LADDER WAS READ FROM \`compass_stance_revisions\` VIA THIS ROW'S OWN PIN, never from the
-- frozen \`compass_topics.title\` / \`compass_stances.text\`. Season 1's pin (673c3758) and Season 2's
-- (${REV_S2.slice(0, 8)}) carry semantically identical rungs here -- wording polish only -- so no rung is being
-- carried across a re-scale.
--
-- ⚠ SIDE FINDING, RECORDED SO IT IS NOT LOST: **Dennis Paul**, blanked by migration 1888, is a
-- coauthor of **HB 2361** -- genuinely topical conduct that his Season 1 row never cited and that
-- this pass only surfaced because he appears on Pierson's coauthor list. The blank stands (it records
-- that the evidence ON RECORD reached no rung, and is re-researchable), but Paul belongs on the
-- re-source queue rather than being treated as closed. Others among 1888's nine may be the same;
-- only a filed-record sweep would show it.
--
-- 🔴 \`stance sourcing\` NEVER RUNS ON A PULL REQUEST (\`if: github.event_name != 'pull_request'\`), so
-- \`npm run check:stance-sources\` was run BY HAND from \`backend/\` before merge. Every source here is
-- path-bearing, so PRIMARY_SITE_NO_PATH cannot grow; none is a Ballotpedia citation.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND politician_id IN (${ids});
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1889: expected ${ROWS.length} Season 1 chairs for this cohort, found %', n;
  END IF;

  -- the Season 1 chairs this migration's prose describes must be the chairs actually on record
${ROWS.map((r) => `  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND politician_id='${r.id}' AND value=${r.s1};
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: ${r.name.replace(/'/g, "''")} is no longer at Season 1 chair ${r.s1}';
  END IF;`).join('\n')}

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids});
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND topic_revision_id='${REV_S2}';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Season 2 does not pin revision ${REV_S2} for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '${TOPIC}'::uuid, '${S2}'::uuid, '${REV_S2}'::uuid, NULL, v.reasoning, v.sources
FROM (VALUES
${ctx.join(',\n')}
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, '${TOPIC}'::uuid, '${S2}'::uuid, '${REV_S2}'::uuid, NULL, v.value
FROM (VALUES
${ans.join(',\n')}
) AS v(pid, value);

DO $$
DECLARE n int;
BEGIN
  -- every row landed, with the chair intended
${ROWS.map((r) => `  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id='${r.id}' AND value=${r.value};
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: ${r.name.replace(/'/g, "''")} did not land at ${r.value === 0 ? 'blank' : `chair ${r.value}`}';
  END IF;`).join('\n')}

  -- every one carries a context row...
  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id='${TOPIC}' AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: % Season 2 answer(s) carry no context row', n;
  END IF;

  -- ...and every context row carries sources (EMPTY_SOURCES is zero-tolerance and PR-invisible)
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: % new row(s) shipped with empty sources', n;
  END IF;

  -- 🔴 Season 1 must be untouched: every one of these still holds its original non-blank chair
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND politician_id IN (${ids}) AND value <> 0;
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1889: Season 1 changed -- % still non-blank, expected ${ROWS.length}', n;
  END IF;
END $$;

COMMIT;
`;
fs.writeFileSync(OUT, sql);
console.log(`wrote ${OUT}`);
