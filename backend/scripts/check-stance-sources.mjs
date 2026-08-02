#!/usr/bin/env node
/**
 * CI gate: a published compass stance must cite something better than a Ballotpedia bio.
 *
 * WHY THIS EXISTS. Migrations 1494, 1507 and 1508 retired 1,157 stance answers between them. Every
 * one of those rows was written by a process that treated "a URL exists" as a source check, and
 * nothing in the repo stopped it — `validate-stance-quotes.py` is per-payload and voluntary, so it
 * only runs when someone remembers. Without a gate this backlog regenerates on the next wave, and the
 * work of retiring it was spent for nothing. That is the single reason this file exists: it is not
 * here to find the remaining bad rows (the audit scripts do that), it is here so the count cannot grow.
 *
 * THE PREDICATE IS THE OPERATOR'S, NOT MINE: **Ballotpedia cannot be the only source.** It is
 * deliberately mechanical. Ballotpedia is a fine pointer and a poor citation — its bios routinely do
 * not contain the claim a row credits to them, which is precisely what the A1 Oregon audit measured
 * page by page. A row that also cites the legislature, a roll call, a scorecard or a news report is
 * untouched by this check no matter how much Ballotpedia it additionally cites.
 *
 * A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS. The first version of this file
 * learned that the hard way: `BARE_DOMAIN_ONLY` was a true statement about 602 rows and a false
 * description of 601 of them, because it never asked whose domain it was. One GROUP BY on the domain
 * settled it. The class is now split by whether the bare root belongs to the SUBJECT (repairable --
 * add the path) or to a reference site covering everybody (unsupportable). Same shape, opposite
 * remedy. Before adding a check here, group the rows it would catch and read a sample of them.
 *
 * WHAT THIS CANNOT DO. It reads the shape of `sources`, never the content of the cited page. A row
 * citing olis.oregonlegislature.gov for a vote the member never cast passes here and is still false.
 * Content is the article-body test's job and needs a fetch. Do not read a green run as "stances are
 * sourced" — read it as "no row cites Ballotpedia and nothing else".
 *
 * WHY BASELINED AND NOT ZERO. 596 live rows violate the Ballotpedia-only rule today (the backlog's
 * Workstream A). Failing red on day one trains people to ignore the gate — the same reasoning as
 * check-address-reachability, and the same per-bucket shape so growth in one state still fires while
 * the global number is worked down.
 *
 * Buckets are per STATE, deliberately not per visibility. Whether a politician is seated or on a
 * candidate card changes as elections pass, so a visibility bucket would churn on the calendar and
 * report drift where nothing changed. State is stable.
 *
 * TWO CHECKS ARE ZERO-TOLERANCE because prod is genuinely at zero and there is no honest reason to
 * regress: an answer with no context row at all, and a context row with an empty `sources` array.
 * Those were 963 of migration 1494's 969 deletions. Verified 0/0 against prod 2026-07-31 before
 * being written as zero-tolerance rather than assumed.
 *
 * Needs a live DB, so like check:reachability this runs on master pushes and on a schedule, not on
 * every PR, and skips itself when DATABASE_URL is absent.
 *
 * Usage (from backend/):
 *   node scripts/check-stance-sources.mjs
 *   node scripts/check-stance-sources.mjs --verbose            # list offending rows
 *   node scripts/check-stance-sources.mjs --update-baseline
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BASELINE = path.join(HERE, '..', 'data', 'stance-source-baseline.json');

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const UPDATE = argv.includes('--update-baseline');

const ZERO_TOLERANCE = new Set(['ANSWER_WITHOUT_CONTEXT', 'EMPTY_SOURCES']);

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/**
 * One row per violation. `seat` is a LIMIT-1 lateral, not a join: office_current_holder is one row per
 * OFFICE and people hold two, so joining it on politician_id fans the result set out and would
 * double-count a dual-office holder into two violations. Same trap as CLAUDE.md's is_vacant note.
 */
const QUERY = `
  WITH v AS (
    SELECT
      pa.politician_id,
      pa.topic_id,
      CASE
        WHEN pc.politician_id IS NULL                              THEN 'ANSWER_WITHOUT_CONTEXT'
        WHEN coalesce(cardinality(pc.sources), 0) = 0              THEN 'EMPTY_SOURCES'
        -- A "source" that is not a URL at all cannot be opened, checked or believed.
        --
        -- 🔴 THIS CLASS WAS INVISIBLE TO THIS GATE UNTIL 2026-08-01, AND THE REASON IS STRUCTURAL:
        -- every other branch below classifies by the SHAPE OF THE HOST PART, so a value with no host
        -- falls through all of them and lands in the ELSE NULL. It surfaced only because a
        -- reachability sweep tried to FETCH each cited host and hit "hosts" like
        -- "prioritizes balanced budgets" and "SB0438 pharmacy benefits".
        --
        -- Cause: an ingestion step split a value on commas into the array. 316 entries across 279
        -- rows, in three shapes needing opposite repairs -- a reasoning string split (which ALSO left
        -- the voter-facing reasoning truncated mid-sentence), stray carriage returns, and 11 cases
        -- where a URL containing a comma was torn in half so the surviving fragment 404s WHILE STILL
        -- PARSING AS A URL. 1527 repaired 257; the remainder are baselined so they cannot grow.
        -- (NB: this is a JS template literal -- every backslash here must be doubled or Postgres
        -- receives a control character. A literal CR in this comment broke the query once already.)
        WHEN EXISTS (
          SELECT 1 FROM unnest(pc.sources) s
           WHERE s !~* '^https?://' AND s !~ '^[a-z0-9.-]+\\.[a-z]{2,}(/|\$)'
        )                                                          THEN 'NON_URL_SOURCE'
        -- Every source is a bare domain with no path. Whether that is fatal depends ENTIRELY on
        -- WHOSE domain it is, and the first version of this check did not ask. Measured 2026-07-31:
        -- of the 602 rows here, 596 cite the candidate's OWN campaign site, 5 an officeholder's own
        -- .gov office site, and exactly 1 a multi-subject reference root. Six of six sampled campaign
        -- homepages contained the claim the row credits to them -- these sites put their issues
        -- content on the front page, so the citation is imprecise, not absent. Retiring them as a
        -- class (the original recommendation) would have deleted ~596 true, sourced rows, 367 of
        -- them live on candidate cards.
        --
        -- So: a bare root belonging to the SUBJECT can support a claim about the subject and needs a
        -- path for precision. A bare root belonging to a reference site that covers everybody cannot,
        -- and never will.
        WHEN NOT EXISTS (
          SELECT 1 FROM unnest(pc.sources) s
           WHERE btrim(s, '/') !~* '^https?://(www\.)?[a-z0-9.-]+$'
        ) THEN CASE
          WHEN NOT EXISTS (
            SELECT 1 FROM unnest(pc.sources) s
             WHERE lower(regexp_replace(btrim(s, '/'), '^https?://(www\.)?', '')) NOT IN (
               'ballotpedia.org', 'wikipedia.org', 'en.wikipedia.org', 'vote411.org', 'votesmart.org',
               'ontheissues.org', 'opensecrets.org', 'followthemoney.org', 'govtrack.us',
               'legiscan.com', 'congress.gov', 'senate.gov', 'house.gov', 'ourcampaigns.com')
          )                                                        THEN 'BARE_AGGREGATOR_DOMAIN'
          ELSE                                                          'PRIMARY_SITE_NO_PATH'
        END
        -- A scraping proxy is a tool artifact, not a citation: r.jina.ai/https://... is the fetch
        -- wrapper the research step used, and it 403s now. The real source is the wrapped URL.
        WHEN EXISTS (
          SELECT 1 FROM unnest(pc.sources) s
           WHERE s ILIKE '%r.jina.ai%' OR s ILIKE '%webcache.googleusercontent%'
              OR s ILIKE '%translate.goog%' OR s ILIKE '%12ft.io%'
        )                                                          THEN 'PROXY_URL_AS_SOURCE'
        -- ...unless the Ballotpedia citation is a deep link into the candidate's own words. A
        -- Candidate Connection survey response is WRITTEN BY THE CANDIDATE and published nowhere
        -- else -- Ballotpedia is the primary source, not a conduit, and there is nothing upstream to
        -- re-point to. Measured 2026-07-31: 231 of the 557 rows in this bucket rest on exactly that.
        -- Without this carve-out the gate pressures whoever works the backlog into either deleting a
        -- well-sourced survey row or bolting on a second citation that is not really the source.
        -- The anchor is required: a bare /Name page is still just a bio. #Campaign_themes is where
        -- Ballotpedia renders survey responses (verified against live pages, not assumed).
        WHEN NOT EXISTS (
          SELECT 1 FROM unnest(pc.sources) s
           WHERE s NOT ILIKE '%ballotpedia%'
              OR s ~* 'ballotpedia\.org/[^#]+#Campaign_themes'
              OR s ILIKE '%Candidate_Connection%'
        )                                                          THEN 'BALLOTPEDIA_ONLY'
        ELSE NULL
      END AS chk,
      pc.sources
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
    WHERE pa.value <> 0
  )
  SELECT
    v.chk,
    v.politician_id,
    v.sources,
    p.first_name || ' ' || p.last_name       AS name,
    coalesce(t.short_title, t.title, v.topic_id::text) AS topic,
    lower(coalesce(seat.state, seat.representing_state, cand.state, '')) AS st
  FROM v
  JOIN essentials.politicians p ON p.id = v.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = v.topic_id
  LEFT JOIN LATERAL (
    SELECT o.representing_state, d.state
    FROM essentials.office_current_holder och
    JOIN essentials.offices o        ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE och.politician_id = v.politician_id
    ORDER BY o.title
    LIMIT 1
  ) seat ON true
  -- Fallback for politicians holding no seat. Without it 443 of the 596 baseline rows collapse into a
  -- single stateless bucket, which is the largest group and therefore the one where a per-state gate
  -- matters most: growth in any one of them would be hidden by the size of the others. These rows are
  -- NOT invisible — compassService surfaces non-incumbent active candidates in upcoming races — so
  -- their election's state is the right bucket.
  LEFT JOIN LATERAL (
    SELECT lower(e.state::text) AS state
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE rc.politician_id = v.politician_id
      AND rc.candidate_status = 'active'
    ORDER BY e.election_date DESC
    LIMIT 1
  ) cand ON true
  WHERE v.chk IS NOT NULL`;

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const { rows } = await pool.query(QUERY);

  const observed = {};
  for (const r of rows) {
    const bucket = r.st || '-';
    observed[r.chk] ??= {};
    observed[r.chk][bucket] = (observed[r.chk][bucket] ?? 0) + 1;
  }

  if (UPDATE) {
    const payload = {
      _comment:
        'Baseline for check-stance-sources.mjs, keyed check -> state -> count. The gate fires on ' +
        'GROWTH in a state or on ANY new state. BALLOTPEDIA_ONLY is the Workstream A backlog and these ' +
        'numbers should only ever go DOWN — never raise one without saying why in the commit message. ' +
        'ANSWER_WITHOUT_CONTEXT and EMPTY_SOURCES are zero-tolerance and ignore this file.',
      _updated: new Date().toISOString().slice(0, 10),
      counts: observed,
    };
    writeFileSync(BASELINE, `${JSON.stringify(payload, null, 2)}\n`);
    console.log(`baseline written to ${path.relative(process.cwd(), BASELINE)}`);
    for (const [chk, buckets] of Object.entries(observed)) {
      const total = Object.values(buckets).reduce((a, b) => a + b, 0);
      console.log(`  ${chk.padEnd(24)} ${String(total).padStart(4)}  ${JSON.stringify(buckets)}`);
    }
    await pool.end();
    process.exit(0);
  }

  let baseline = { counts: {} };
  try {
    baseline = JSON.parse(readFileSync(BASELINE, 'utf8'));
  } catch {
    console.error(
      `FAIL: no baseline at ${path.relative(process.cwd(), BASELINE)}.\n` +
      'Run with --update-baseline once, review the numbers, and commit the file.',
    );
    await pool.end();
    process.exit(2);
  }

  const violations = [];
  const checks = new Set([...Object.keys(observed), ...Object.keys(baseline.counts ?? {})]);
  for (const chk of checks) {
    const obs = observed[chk] ?? {};
    const base = ZERO_TOLERANCE.has(chk) ? {} : (baseline.counts?.[chk] ?? {});
    for (const [bucket, n] of Object.entries(obs)) {
      const allowed = base[bucket] ?? 0;
      if (n > allowed) violations.push({ chk, bucket, n, allowed, isNew: !(bucket in base) });
    }
  }

  console.log(`stance sources — ${rows.length} offending row(s) across ${checks.size} check(s)`);
  for (const chk of [...checks].sort()) {
    const total = Object.values(observed[chk] ?? {}).reduce((a, b) => a + b, 0);
    const baseTotal = Object.values(baseline.counts?.[chk] ?? {}).reduce((a, b) => a + b, 0);
    const tag = ZERO_TOLERANCE.has(chk) ? 'must be 0' : `baseline ${baseTotal}`;
    console.log(`  ${chk.padEnd(24)} observed ${String(total).padStart(4)}   (${tag})`);
  }

  if (VERBOSE) {
    console.log('\nper-row detail:');
    for (const r of rows) {
      console.log(`  ${r.chk.padEnd(24)} ${(r.st || '-').padEnd(3)} ${r.name} — ${r.topic}  [${(r.sources ?? []).join(' ')}]`);
    }
  }

  if (violations.length === 0) {
    console.log('\nOK — no stance row cites Ballotpedia and nothing else beyond the recorded backlog.');
    await pool.end();
    process.exit(0);
  }

  console.error('\nFAIL — stance sourcing regressed:\n');
  for (const v of violations) {
    const why = ZERO_TOLERANCE.has(v.chk)
      ? 'zero-tolerance check'
      : v.isNew ? 'NEW state — this state was clean before' : `grew from ${v.allowed}`;
    console.error(`  ${v.chk}  ${v.bucket}  observed ${v.n} (${why})`);
  }
  // Remediation differs by check and getting it wrong is expensive: telling someone to "cite the roll
  // call" for a PRIMARY_SITE_NO_PATH row invites them to replace a good citation instead of finishing
  // it, which is how ~596 true rows nearly got retired as a class on 2026-07-31.
  const FIX = {
    ANSWER_WITHOUT_CONTEXT: 'Write the reasoning and sources row, or retire the answer.',
    EMPTY_SOURCES:          'Cite what the chair actually rests on, or retire the answer.',
    BALLOTPEDIA_ONLY:       'Cite the roll call, scorecard, filing or report the bio draws on. If the ' +
                            'claim rests on the candidate\'s own Candidate Connection answers, deep-link ' +
                            '#Campaign_themes -- that counts.',
    BARE_AGGREGATOR_DOMAIN: 'A reference site\'s front page says nothing about one person. Cite the page.',
    PRIMARY_SITE_NO_PATH:   'The site is right, the path is missing -- link the issues page that carries ' +
                            'the claim. Do NOT swap in a different source, and do not retire the row.',
    PROXY_URL_AS_SOURCE:    'Store the wrapped URL, not the r.jina.ai fetch wrapper.',
  };
  console.error('');
  for (const chk of [...new Set(violations.map((v) => v.chk))]) {
    console.error(`  ${chk}: ${FIX[chk] ?? 'Cite what the chair actually rests on.'}`);
  }
  console.error(
    '\nRe-run with --verbose to see the rows. If growth is intentional and understood, update the\n' +
    'baseline in the SAME commit and explain it in the message.',
  );
  await pool.end();
  process.exit(1);
})().catch(async (err) => {
  console.error('FAIL: check-stance-sources errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});
