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
 * 🔴 THE ONE EXCEPTION IS FABRICATED_SOURCE, AND IT IS ONLY HALF AN EXCEPTION. That check does concern
 * whether a page exists, but it cannot DECIDE that — it matches a denylist of URLs and hosts already
 * proven absent (`data/fabricated-sources.json`). Discovery needs a fetch plus an archive probe with a
 * period control, which archive.org rate-limits and 504s, so it lives in
 * `scripts/sweep-fabricated-articles.mjs` and runs on demand. Six migrations' worth of fabricated
 * citations (1539, 1540, 1548, 1558, 1562) passed this gate green while they were live. A green run
 * means no KNOWN fabrication has come back, not that none exists.
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
 * 🔴 ORPHAN_CONTEXT NEEDED ITS OWN QUERY, AND THAT IS THE WHOLE POINT OF IT. Every check above reads
 * `FROM politician_answers LEFT JOIN politician_context`, so a context row with NO answer is outside
 * this gate's universe by construction -- not missed by a loose predicate, unreachable by any
 * predicate. 542 such rows sat in prod undetected until 2026-08-07 while the gate ran green. The
 * second branch of the UNION reverses the join. Diagnosis:
 * `data/stance-retirement/2026-08-07-orphan-context-findings.md`.
 *
 * GENERALISE BEFORE ADDING THE NEXT CHECK: when a class seems invisible, ask whether the FROM clause
 * can reach it at all before adding another CASE branch. The same shape hid the landing-page class
 * (1558) and the scheme-less citations (1549).
 *
 * WHY IT IS NOT ZERO-TOLERANCE, AND WHY IT CARVES OUT DOCUMENTED BLANKS. An orphan is not per se a
 * defect: a documented blank ("we looked, found nothing, here is what we checked") has no chair, so
 * it correctly has no answer row. 404 orphans carry an empty `sources` array and are exactly the
 * cohort ruled legitimate on 2026-08-07 -- those are excluded on SHAPE. Another 80 carry a citation
 * to what was checked and are the same honest class, distinguishable only by their prose, so they
 * are carved out by marker.
 *
 * ⚠ THAT MARKER IS A CARVE-OUT, NEVER A CONDEMNATION -- the same posture as the #Campaign_themes
 * exemption above. Reading prose to EXEMPT a class fails safe: if it under-fires an honest blank gets
 * flagged and a human reads it; if it over-fires a characterisation goes unreported, which is exactly
 * the status quo it replaces. Never invert this into a predicate that retires rows.
 *
 * What is left is 58 rows on 25 politicians: reasoning that describes a position with no chair
 * recorded. Two of them narrate a score that does not exist ("her leans-slow-growth score reflects
 * ..."), which is the signature -- the topic was scored, the prose was stored, the answer was not.
 * None of the 542 is voter-visible today (verified through all three serving paths), so the harm is
 * LATENT: write an answer for one of these pairs and Citations.jsx immediately renders prose nobody
 * re-read under "Why this position?". Baselined so it cannot grow while the 58 are worked down.
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
const FABRICATED = path.join(HERE, '..', 'data', 'fabricated-sources.json');

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const UPDATE = argv.includes('--update-baseline');

// NON_URL_SOURCE joined the zero-tolerance set on 2026-08-02, once 1527-1530 had driven it to 0.
// It was baselined at 279 -> 22 -> 9 only while the backlog was being worked; no legitimate row has
// ever had prose in `sources`, so any future occurrence is a regression, not a backlog item.
// FABRICATED_SOURCE joined the zero-tolerance set on 2026-08-05. Prod held 0 citations to every entry
// in data/fabricated-sources.json when it was added (verified, not assumed), so any occurrence is a
// regression that re-introduces a citation a migration already proved does not exist.
const ZERO_TOLERANCE = new Set([
  'ANSWER_WITHOUT_CONTEXT', 'EMPTY_SOURCES', 'NON_URL_SOURCE', 'FABRICATED_SOURCE',
]);

/**
 * Confirmed-fabricated hosts and URLs. Loaded from disk so the sweep can extend the list without
 * touching this file, and so the denylist is reviewable in a diff on its own.
 *
 * ⚠ THIS CHECK CANNOT DISCOVER THE CLASS, ONLY RE-DETECT IT. Deciding that a cited article never
 * existed requires fetching the path and querying an archive with a period control — network work that
 * archive.org rate-limits and 504s, so it must not run in CI. That is
 * `scripts/sweep-fabricated-articles.mjs`, run on demand; this gate only stops what it confirmed from
 * coming back. A green run here does NOT mean no fabricated citations exist.
 */
function loadFabricated() {
  try {
    const f = JSON.parse(readFileSync(FABRICATED, 'utf8'));
    return {
      hosts: (f.hosts ?? []).map((h) => h.host.toLowerCase()),
      urls: (f.urls ?? []).map((u) => u.url),
    };
  } catch {
    // A missing denylist must not silently disable the check — that is how a gate rots.
    console.error(`FAIL: cannot read ${path.relative(process.cwd(), FABRICATED)}. The FABRICATED_SOURCE check needs it.`);
    process.exit(2);
  }
}

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
        -- A citation to a page that was PROVEN not to exist. Checked before every other class because
        -- it is the most severe: the others say a citation is weak, this one says it is imaginary.
        --
        -- 🔴 WHY A DENYLIST AND NOT A PREDICATE. There is no shape that distinguishes a fabricated
        -- article from a real one. lowellsun.com/2023/09/21/lowell-council-rent-stabilization/ is
        -- well-formed, on a live real newspaper, with a plausible date and a house-style slug; the only
        -- (NB: no backticks in this comment -- it is inside a JS template literal and they close it.)
        -- thing wrong with it is that the article was never published. Deciding that needs a fetch plus
        -- an archive probe with a period control, so this branch can only re-detect what the sweep
        -- already confirmed. See sweep-fabricated-articles.mjs.
        --
        -- Two match modes, and the distinction is load-bearing:
        --   HOST  — the outlet itself never existed (medfordmirror.com). Any path on it is fabricated.
        --   URL   — the outlet is REAL and live and only the article is fake (lowellsun.com). Blocking
        --           the host would block legitimate future citations to the same paper, so these match
        --           exactly. Hosts are compared with www. stripped; URLs are not normalised, because a
        --           fabricated path is fabricated at the exact string that was invented.
        WHEN EXISTS (
          SELECT 1 FROM unnest(pc.sources) s
           WHERE s = ANY($1::text[])
              OR lower(regexp_replace(s, '^https?://(www\\.)?([^/]+).*\$', '\\2')) = ANY($2::text[])
        )                                                          THEN 'FABRICATED_SOURCE'
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

    UNION ALL

    -- THE JOIN IS REVERSED HERE ON PURPOSE. See ORPHAN_CONTEXT in the header: driven from answers,
    -- these rows cannot appear at all. Every column must line up with the branch above.
    SELECT
      pc.politician_id,
      pc.topic_id,
      'ORPHAN_CONTEXT' AS chk,
      pc.sources
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
    WHERE pa.politician_id IS NULL
      -- Empty sources = a documented blank, which is SUPPOSED to have no answer. Excluded on shape,
      -- so this branch never re-reports the 404 rows closed on 2026-08-07.
      AND coalesce(cardinality(pc.sources), 0) > 0
      -- ...and the same class again, but diligent enough to cite what it checked. Carve-out only:
      -- a miss here costs a human read, never a deletion. (Template literal -- double every
      -- backslash; [0-9] is used instead of \\d to keep the escaping shallow.)
      AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
      AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
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

  const deny = loadFabricated();
  const { rows } = await pool.query(QUERY, [deny.urls, deny.hosts]);

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
  // Zero-tolerance checks are printed even at 0. A check that vanishes from the output when it passes
  // is indistinguishable from a check that is not running — and FABRICATED_SOURCE is expected to sit at
  // 0 forever, so it would be invisible for its entire useful life.
  for (const chk of ZERO_TOLERANCE) checks.add(chk);
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
    ORPHAN_CONTEXT:         'Reasoning describing a position with no chair recorded. It is NOT published ' +
                            'today, so there is no emergency -- but do NOT assign a chair to this pair ' +
                            'without re-reading the existing reasoning first, because saving an answer ' +
                            'publishes this prose verbatim under "Why this position?". Re-read and rewrite ' +
                            'it, or delete the context row. If the row honestly records that no stance was ' +
                            'found, say so in the reasoning and it stops being counted.',
    EMPTY_SOURCES:          'Cite what the chair actually rests on, or retire the answer.',
    BALLOTPEDIA_ONLY:       'Cite the roll call, scorecard, filing or report the bio draws on. If the ' +
                            'claim rests on the candidate\'s own Candidate Connection answers, deep-link ' +
                            '#Campaign_themes -- that counts.',
    BARE_AGGREGATOR_DOMAIN: 'A reference site\'s front page says nothing about one person. Cite the page.',
    PRIMARY_SITE_NO_PATH:   'The site is right, the path is missing -- link the issues page that carries ' +
                            'the claim. Do NOT swap in a different source, and do not retire the row.',
    PROXY_URL_AS_SOURCE:    'Store the wrapped URL, not the r.jina.ai fetch wrapper.',
    FABRICATED_SOURCE:      'This citation points at a page PROVEN not to exist (data/fabricated-sources.json ' +
                            'records which migration retired it). Do NOT re-point it -- there is nothing ' +
                            'upstream to re-point to. Re-research the row from a source you fetched, or ' +
                            'retire it. If you believe the denylist entry is wrong, re-verify with a ' +
                            'period control and say so in the commit.',
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
