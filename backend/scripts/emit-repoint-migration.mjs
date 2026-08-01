#!/usr/bin/env node
/**
 * Emit migration 1512 from the PRIMARY_SITE_NO_PATH repair proposal, plus its rollback record.
 *
 * Applies ONLY the verdicts where the claim was verified on a more specific URL on the SAME host:
 * DEEP_PAGE and HOMEPAGE_ANCHOR. DEEP_PAGE_WEAK (one term, no quote) is deliberately excluded --
 * it is probably right and "probably" is not the bar for writing to prod.
 *
 * 🔴 THIS MIGRATION NEVER DELETES AND NEVER CHANGES HOSTS. Every statement swaps one string in the
 * sources array for a longer string on the same domain. If a proposal's new URL is not on the cited
 * host, this generator refuses to emit it.
 *
 * Usage (from backend/):
 *   node scripts/emit-repoint-migration.mjs
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const IN = 'data/stance-retirement/2026-07-31-primary-site-paths.json';
const SQL = 'migrations/1512_repoint_primary_site_citations.sql';
const ROLLBACK = 'data/stance-retirement/2026-07-31-primary-site-paths-rollback.json';
const APPLY = new Set(['DEEP_PAGE', 'HOMEPAGE_ANCHOR']);

const host = (u) => { try { return new URL(u).hostname.replace(/^www\./, ''); } catch { return null; } };
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

const proposal = JSON.parse(readFileSync(IN, 'utf8'));
const all = proposal.rows.filter((r) => APPLY.has(r.verdict));

/**
 * 🔴 A HOST CHANGE IS NOT A PATH REPAIR, EVEN WHEN IT IS RIGHT. jessicaandersonforva.com 301s to
 * jess4va.com -- the campaign renamed its site -- so the crawler followed the redirect and proposed a
 * URL on the new domain. That is very likely the correct citation, and it is still a different source
 * than the one on the row. This migration's whole warrant is "same site, more specific page"; the
 * moment it starts changing hosts it needs a human to agree the two hosts are the same campaign.
 * Held out, reported, not silently applied and not silently dropped.
 */
const held = all.filter((r) => !host(r.url) || host(r.url) !== host(r.cited));
// And anything that is not actually longer than what it replaces adds no precision.
const notLonger = all.filter((r) => !held.includes(r)
  && r.url.replace(/\/$/, '').length <= r.cited.replace(/\/$/, '').length);
if (notLonger.length) {
  console.error(`REFUSING: ${notLonger.length} proposal(s) are not more specific than the bare root:`);
  for (const r of notLonger.slice(0, 5)) console.error(`  ${r.name}: ${r.cited} -> ${r.url}`);
  process.exit(1);
}
const rows = all.filter((r) => !held.includes(r));
if (held.length) {
  console.log(`HELD (host change -- needs a human): ${held.length}`);
  for (const r of held) console.log(`  ${r.name} | ${r.topic}: ${r.cited} -> ${r.url}`);
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: before } = await pool.query(
  `SELECT politician_id::text AS pid, topic_id::text AS tid, sources
     FROM inform.politician_context
    WHERE (politician_id::text, topic_id::text) IN (${rows.map((r) => `(${q(r.pid)},${q(r.tid)})`).join(',')})`,
);
await pool.end();

const beforeBy = new Map(before.map((b) => [`${b.pid}|${b.tid}`, b.sources]));
const missing = rows.filter((r) => !beforeBy.has(`${r.pid}|${r.tid}`));
if (missing.length) { console.error(`REFUSING: ${missing.length} target row(s) not in prod`); process.exit(1); }

writeFileSync(ROLLBACK, `${JSON.stringify({
  _comment: 'Rollback record for migration 1512. `before` is the exact sources array as it stood in '
    + 'prod immediately before the migration was generated; restoring it undoes the re-pointing.',
  generated_from: IN,
  held_host_change: held.map((r) => ({
    pid: r.pid, tid: r.tid, name: r.name, topic: r.topic, cited: r.cited, proposed: r.url,
    note: 'cited host redirects to proposed host; needs a human to confirm they are the same campaign',
  })),
  rows: rows.map((r) => ({
    pid: r.pid, tid: r.tid, name: r.name, topic: r.topic, verdict: r.verdict,
    before: beforeBy.get(`${r.pid}|${r.tid}`), after: r.url, evidence: r.evidence,
  })),
}, null, 2)}\n`);

const byVerdict = rows.reduce((a, r) => { a[r.verdict] = (a[r.verdict] ?? 0) + 1; return a; }, {});
const partial = rows.filter((r) => r.partial).length;

const sql = `-- 1512_repoint_primary_site_citations.sql
--
-- Point ${rows.length} stance citations at the page that carries the claim instead of at the front door
-- of the same site. NOTHING IS DELETED AND NO CITATION CHANGES HOST -- every statement below swaps one
-- string in inform.politician_context.sources for a longer string on the same domain.
--   Evidence:        ${IN}
--   Rollback record: ${ROLLBACK}
--                    (carries the exact prior sources array for all ${rows.length} rows)
--
-- WHY THESE ROWS EXIST. They are part of the 601-row PRIMARY_SITE_NO_PATH class -- answers whose only
-- citation is a bare root with no path. That class was first written up as "indefensible on their
-- face, retire as a class". Measured against prod 2026-07-31 that description fits exactly ONE row:
-- 596 cite the candidate's own campaign site and 5 an officeholder's own .gov office site. The
-- citation is imprecise, not absent, and 367 of the 601 are live on candidate cards. Retiring the
-- class would have deleted ~596 true, sourced rows.
--
-- WHAT WAS ACTUALLY REPAIRABLE, AND WHY IT IS A SMALL SHARE OF 601. Each site was crawled and each
-- row's quote re-tested page by page:
--   DEEP_PAGE        ${String(byVerdict.DEEP_PAGE ?? 0).padStart(3)}  the claim verifies on an interior page (/issues, /platform, /priorities)
--   HOMEPAGE_ANCHOR  ${String(byVerdict.HOMEPAGE_ANCHOR ?? 0).padStart(3)}  single-page site; the claim sits in a named section with a topical id
-- Everything else is NOT applied here and is not a defect to be fixed by this migration:
--   HOMEPAGE_ONLY    265  the claim IS on the homepage and the site has nothing more specific to
--                         point at. These citations are already as precise as the source permits.
--   NOT_FOUND        130  the verbatim quote is not on the site as fetched -- a HUMAN READ, never a
--                         retirement. Hand-checked: some are inexact quotation over substance that is
--                         plainly present (voteforpedrori.com says "Dissolve AIPAC. No Foreign-Interest
--                         Lobby Money"; the row compresses it to "No AIPAC Money. No Foreign-Interest
--                         Lobby Money"), others are genuine absences (shannontaylorva.com has no
--                         occurrence of "tariff" at all).
--   UNREADABLE       112  client-rendered shells -- 1,027k of HTML yielding 7k of text. An unread page
--                         is NOT an absent claim; same false negative as the silent HTTP-202.
--   DEAD_SITE         16  the campaign site 404s. Wayback is the likely remedy, not deletion.
--   UNTESTABLE        23  no quote and no distinctive term survived extraction.
--   DEEP_PAGE_WEAK     9  one matching term, no quote. Probably right; "probably" is not the bar for
--                         writing to prod, so they are held for a human.
--
-- 🔴 ${partial} OF THE ${rows.length} MATCHED SOME BUT NOT ALL OF THEIR QUOTES. One verified quote is enough to
-- locate the page -- a row legitimately draws on more than one -- but it is NOT a verdict on the row.
-- Whether every quote holds is the citation audit's job, and re-pointing does not settle it.
--
-- 🔴 AN ANCHOR IS ONLY CITED WHEN ITS NAME SAYS WHAT IT POINTS AT. Three rounds of filtering generated
-- ids (#comp-jtv6vr22, then #page/#PAGES_CONTAINER, then #zi245S/#ui-id-6/#container02) each just moved
-- the junk, so the rule is now an allow-list: the id must contain a topical word and enclose under 40%
-- of the page. Structural ids move when the owner edits the page and would rot the citation silently.

BEGIN;

CREATE TEMP TABLE _repoint_1512 (
  politician_id uuid,
  topic_id      uuid,
  old_root      text,
  new_url       text
) ON COMMIT DROP;

INSERT INTO _repoint_1512 (politician_id, topic_id, old_root, new_url) VALUES
${rows.map((r, i) => `  (${q(r.pid)}, ${q(r.tid)}, ${q(r.cited)}, ${q(r.url)})${i === rows.length - 1 ? '' : ','}  -- ${r.name}: ${r.topic}`).join('\n')}
;

-- Match on the trailing-slash-normalised element so a stored "https://site.com/" is found by a
-- proposal recorded as "https://site.com". Ordinality keeps the array in its original order.
UPDATE inform.politician_context pc
   SET sources = (
     SELECT array_agg(CASE WHEN btrim(s, '/') = r.old_root THEN r.new_url ELSE s END ORDER BY ord)
       FROM unnest(pc.sources) WITH ORDINALITY AS u(s, ord))
  FROM _repoint_1512 r
 WHERE pc.politician_id = r.politician_id
   AND pc.topic_id = r.topic_id;

DO $$
DECLARE
  v_target   int;
  v_unfixed  int;
  v_lost     int;
BEGIN
  SELECT count(*) INTO v_target FROM _repoint_1512;
  IF v_target <> ${rows.length} THEN
    RAISE EXCEPTION 'expected ${rows.length} targeted rows, found %', v_target;
  END IF;

  -- Every targeted row must now carry at least one source with a path. If one does not, the old_root
  -- did not match what was stored and the row was silently left behind.
  SELECT count(*) INTO v_unfixed
    FROM inform.politician_context pc
    JOIN _repoint_1512 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE NOT EXISTS (
     SELECT 1 FROM unnest(pc.sources) s
      WHERE btrim(s, '/') !~* '^https?://(www\\.)?[a-z0-9.-]+$');
  IF v_unfixed <> 0 THEN
    RAISE EXCEPTION '% targeted rows still cite only a bare domain -- old_root did not match', v_unfixed;
  END IF;

  -- Nothing may lose a source. This migration substitutes; it never drops.
  SELECT count(*) INTO v_lost
    FROM inform.politician_context pc
    JOIN _repoint_1512 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_lost <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_lost;
  END IF;
END $$;

COMMIT;
`;

writeFileSync(SQL, sql);
console.log(`wrote ${SQL} (${rows.length} rows: ${JSON.stringify(byVerdict)}, ${partial} partial-quote)`);
console.log(`wrote ${ROLLBACK}`);
