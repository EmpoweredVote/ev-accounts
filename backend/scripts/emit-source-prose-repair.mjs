#!/usr/bin/env node
/**
 * Classify and repair rows whose `sources` array was damaged by a comma-splitting ingestion step.
 *
 * THE BUG, AND WHY IT IS NOT ONE BUG. A value was split on commas into the sources array. Depending
 * on WHAT was split, the damage takes different shapes that need OPPOSITE repairs, and the first
 * version of this tool nearly applied one repair to all of them:
 *
 *   SPLIT_URL       A URL containing a comma was torn in half. 🔴 THE WORST CASE: the surviving
 *                   half is a TRUNCATED, BROKEN LINK that a voter clicks today, and the gate cannot
 *                   see it because the truncated half still parses as a URL.
 *                   ballotpedia.org/Monica_Garcia_(Los_Angeles_Unified_School_District_Board_of_Education
 *                   + "_District_2)"  ->  rejoin with "," to restore the real page.
 *   WHITESPACE      A stray "\r" or blank. Carries nothing. Drop it; `reasoning` is intact.
 *   REASONING_SPLIT The reasoning STRING was split: the first fragment stayed in `reasoning` (leaving
 *                   it truncated mid-sentence) and the rest became "sources". Rejoin with ", ".
 *   OTHER_PROSE     Quotes and names in sources on rows whose reasoning is COMPLETE ("Susan Collins",
 *                   "Don't gut education..."). A different ingestion fault. Refused for hand review.
 *   NO_URL_LEFT     Nothing url-shaped survives. Repairing would empty `sources`, and EMPTY_SOURCES
 *                   is a ZERO-TOLERANCE gate class. Refused.
 *
 * 🔴 REJOINING A "\r" ONTO VOTER-FACING TEXT, OR DROPPING HALF A URL, ARE BOTH SILENT VANDALISM.
 * That is why every entry is classified before anything is written, and why SPLIT_URL repairs are
 * PROVEN BY FETCHING both halves rather than argued structurally: on Lara the truncated URL
 * (ballotpedia.org/California_Proposition_21) is itself a perfectly plausible page, so structure
 * alone cannot tell you the citation was damaged. Only the network can.
 *
 * Usage (from backend/):
 *   node scripts/emit-source-prose-repair.mjs --verify \
 *     --sql migrations/1527_repair_split_sources.sql \
 *     --rollback data/stance-retirement/2026-08-01-prose-sources-rollback.json \
 *     --md data/stance-retirement/2026-08-01-prose-sources-repair.md
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';
import { fetchPage, pooled } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
const SQL = flag('--sql'); const ROLLBACK = flag('--rollback'); const MD = flag('--md');
const VERIFY = has('--verify');

const isUrl = (s) => /^https?:\/\//i.test(s.trim()) || /^[a-z0-9.-]+\.[a-z]{2,}(\/|$)/i.test(s.trim());
const isBlank = (s) => s.replace(/[\s ]/g, '') === '';
const truncated = (s) => !/[.!?]["')\]]?\s*$/.test((s ?? '').trim());
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** Walk the array left to right; every non-URL entry gets exactly one label. */
function classify(row) {
  const out = { urls: [], drop: [], merges: [], frags: [], other: [] };
  const src = row.sources;
  for (let i = 0; i < src.length; i += 1) {
    const s = src[i];
    if (isUrl(s)) { out.urls.push({ i, url: s.trim() }); continue; }
    if (isBlank(s)) { out.drop.push({ i, s }); continue; }
    // A no-whitespace fragment right after a URL is a torn URL, not prose.
    const prev = out.urls.length ? out.urls[out.urls.length - 1] : null;
    if (prev && prev.i === i - 1 && !/\s/.test(s) && !/\s/.test(`${prev.url},${s}`)) {
      out.merges.push({ i, onto: prev.i, joined: `${prev.url},${s.trim()}`, piece: s.trim() });
      continue;
    }
    if (/\s/.test(s) && truncated(row.reasoning)) { out.frags.push({ i, s: s.trim() }); continue; }
    out.other.push({ i, s });
  }
  return out;
}

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const { rows } = await pool.query(`
    SELECT pc.politician_id::text AS pid, pc.topic_id::text AS tid,
           p.first_name || ' ' || p.last_name AS name,
           coalesce(t.short_title, t.title) AS topic, pc.sources, pc.reasoning
      FROM inform.politician_context pc
      JOIN inform.politician_answers pa
        ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
      JOIN essentials.politicians p ON p.id = pc.politician_id
      LEFT JOIN inform.compass_topics t ON t.id = pc.topic_id
     WHERE pa.value <> 0 AND pc.sources IS NOT NULL
       AND EXISTS (SELECT 1 FROM unnest(pc.sources) x
                    WHERE x !~* '^https?://' AND x !~ '^[a-z0-9.-]+\\.[a-z]{2,}(/|$)')`);
  await pool.end();

  const plans = rows.map((r) => ({ r, c: classify(r) }));

  // ---- prove every SPLIT_URL against the network before trusting it.
  const merges = plans.flatMap(({ r, c }) => c.merges.map((m) => ({ r, m })));
  if (VERIFY && merges.length) {
    console.log(`verifying ${merges.length} candidate split URL(s) against the network…`);
    await pooled(merges, 5, async ({ m }) => {
      const [a, b] = await Promise.all([
        fetchPage(m.joined, { minBody: 1, cacheTtlHours: 24 }),
        fetchPage(plansUrlAt(m), { minBody: 1, cacheTtlHours: 24 }),
      ]);
      m.joinedStatus = a.status; m.truncStatus = b.status;
      // Repair only when rejoining demonstrably HELPS: joined resolves and truncated does not.
      m.proven = a.status === 200 && b.status !== 200;
    });
  }
  function plansUrlAt(m) { return m.joined.slice(0, m.joined.length - m.piece.length - 1); }

  const emit = []; const held = [];
  for (const { r, c } of plans) {
    const provenMerges = c.merges.filter((m) => (VERIFY ? m.proven : false));
    const unprovenMerges = c.merges.filter((m) => !provenMerges.includes(m));
    if (c.other.length) { held.push({ r, why: `prose in sources on a row whose reasoning is complete: ${JSON.stringify(c.other[0].s).slice(0, 70)}` }); continue; }
    if (unprovenMerges.length) { held.push({ r, why: `split-URL candidate not proven by fetch (joined=${unprovenMerges[0].joinedStatus ?? 'unchecked'}, truncated=${unprovenMerges[0].truncStatus ?? 'unchecked'})` }); continue; }
    if (!c.urls.length && !provenMerges.length) { held.push({ r, why: 'no URL survives — repairing would empty sources (EMPTY_SOURCES is zero-tolerance)' }); continue; }
    if (!c.drop.length && !c.frags.length && !provenMerges.length) continue; // nothing to do

    // Rebuild sources: merged URLs replace their base, everything else kept in order.
    const mergedOnto = new Map(provenMerges.map((m) => [m.onto, m.joined]));
    const newSources = c.urls.map((u) => mergedOnto.get(u.i) ?? u.url);
    const newReasoning = c.frags.length
      ? [(r.reasoning ?? '').replace(/[\s,;]+$/, ''), ...c.frags.map((f) => f.s)].join(', ')
      : r.reasoning;
    if (!newSources.length) { held.push({ r, why: 'rebuild produced no sources' }); continue; }
    emit.push({ ...r, newSources, newReasoning, kinds: {
      split_url: provenMerges.length, whitespace: c.drop.length, reasoning_frag: c.frags.length } });
  }

  const tally = emit.reduce((a, e) => {
    for (const [k, v] of Object.entries(e.kinds)) if (v) a[k] = (a[k] ?? 0) + 1;
    return a;
  }, {});
  console.log(`\nrows with a damaged sources array: ${rows.length}`);
  console.log(`  repairable: ${emit.length}`);
  for (const [k, v] of Object.entries(tally)) console.log(`    ${k}: ${v} row(s)`);
  console.log(`  held for hand review: ${held.length}`);
  const byWhy = held.reduce((a, h) => { const k = h.why.split(':')[0]; a[k] = (a[k] ?? 0) + 1; return a; }, {});
  for (const [k, v] of Object.entries(byWhy)) console.log(`    ${k}: ${v}`);

  if (ROLLBACK) {
    writeFileSync(ROLLBACK, `${JSON.stringify({
      generated: { scanned: rows.length, repairable: emit.length, held: held.length, tally },
      rows: emit.map(({ pid, tid, name, topic, sources, reasoning, newSources, newReasoning, kinds }) =>
        ({ pid, tid, name, topic, was: { sources, reasoning }, now: { sources: newSources, reasoning: newReasoning }, kinds })),
      held: held.map(({ r, why }) => ({ pid: r.pid, tid: r.tid, name: r.name, topic: r.topic, sources: r.sources, why })),
    }, null, 2)}\n`);
    console.log(`rollback -> ${ROLLBACK}`);
  }

  if (MD) {
    const L = ['# Damaged `sources` arrays — classification and repair\n'];
    L.push(`${rows.length} rows scanned · **${emit.length} repaired** · ${held.length} held for hand review.\n`);
    L.push('A comma-splitting ingestion step damaged these arrays. The damage takes several shapes that');
    L.push('need OPPOSITE repairs, so each entry is classified before anything is written.\n');
    const split = emit.filter((e) => e.kinds.split_url);
    if (split.length) {
      L.push(`\n## 🔴 SPLIT URL — ${split.length} row(s): a broken link a voter clicks today\n`);
      L.push('A URL containing a comma was torn in half. The surviving half still *parses* as a URL, so');
      L.push('the gate cannot see it — but it 404s. Each repair below was proven by fetching both halves:');
      L.push('the rejoined URL returns 200 and the truncated one does not.\n');
      for (const e of split) {
        L.push(`- **${e.name} / ${e.topic}**`);
        L.push(`  - was: \`${e.sources.join('` , `')}\``);
        L.push(`  - now: \`${e.newSources.join('` · `')}\``);
      }
    }
    const frag = emit.filter((e) => e.kinds.reasoning_frag);
    if (frag.length) {
      L.push(`\n## REASONING SPLIT — ${frag.length} row(s): truncated voter-facing text restored\n`);
      for (const e of frag.slice(0, 25)) {
        L.push(`- **${e.name} / ${e.topic}**`);
        L.push(`  - was: ${e.reasoning}`);
        L.push(`  - now: ${e.newReasoning}`);
      }
      if (frag.length > 25) L.push(`\n_… ${frag.length - 25} more in the rollback JSON._`);
    }
    const ws = emit.filter((e) => e.kinds.whitespace && !e.kinds.reasoning_frag && !e.kinds.split_url);
    if (ws.length) L.push(`\n## WHITESPACE — ${ws.length} row(s): a stray "\\r" dropped, reasoning untouched\n`);
    if (held.length) {
      L.push(`\n## ⚠ Held for hand review — ${held.length} row(s)\n`);
      for (const h of held.slice(0, 30)) L.push(`- **${h.r.name} / ${h.r.topic}** — ${h.why}`);
      if (held.length > 30) L.push(`\n_… ${held.length - 30} more in the rollback JSON._`);
    }
    writeFileSync(MD, `${L.join('\n')}\n`);
    console.log(`review   -> ${MD}`);
  }

  if (SQL && emit.length) {
    const L = ['-- 1527_repair_split_sources.sql', '--',
      '-- GENERATED by scripts/emit-source-prose-repair.mjs --verify. Do not hand-edit; regenerate.', '--',
      '-- A comma-splitting ingestion step damaged these sources arrays in several different ways, so',
      '-- each entry was classified before anything was written here:', '--',
      `--   SPLIT_URL       ${tally.split_url ?? 0} row(s) — a URL containing a comma was torn in half. The surviving`,
      '--                   half still parses as a URL, so the gate cannot see it, but it 404s: a voter',
      '--                   clicks a broken link TODAY. Rejoined with "," and PROVEN BY FETCH — the',
      '--                   rejoined URL returns 200 and the truncated one does not. Structure alone is',
      '--                   not enough: ballotpedia.org/California_Proposition_21 is a plausible page.',
      `--   REASONING_SPLIT ${tally.reasoning_frag ?? 0} row(s) — the reasoning string was split, leaving voter-facing text`,
      '--                   truncated mid-sentence and its tail rendering as citations. Rejoined with ", ".',
      `--   WHITESPACE      ${tally.whitespace ?? 0} row(s) — a stray "\\r" dropped. Reasoning untouched.`, '--',
      `-- ⚠ ${held.length} further rows are HELD for hand review and deliberately not touched, including`,
      '-- rows whose reasoning is complete but which carry quotes/names in sources, and rows where no URL',
      '-- survives at all (repairing those would empty sources, and EMPTY_SOURCES is zero-tolerance).',
      '--   Rollback: data/stance-retirement/2026-08-01-prose-sources-rollback.json',
      '--   Review:   data/stance-retirement/2026-08-01-prose-sources-repair.md', '', 'BEGIN;', ''];
    for (const e of emit) {
      L.push(`-- ${e.name} / ${e.topic}  [${Object.entries(e.kinds).filter(([, v]) => v).map(([k]) => k).join(', ')}]`);
      L.push('UPDATE inform.politician_context SET');
      L.push(`       sources = ARRAY[${e.newSources.map(q).join(', ')}]::text[]${e.newReasoning !== e.reasoning ? ',' : ''}`);
      if (e.newReasoning !== e.reasoning) L.push(`       reasoning = ${q(e.newReasoning)}`);
      L.push(` WHERE politician_id = '${e.pid}' AND topic_id = '${e.tid}';`);
    }
    const ids = emit.map((e) => `('${e.pid}','${e.tid}')`).join(', ');
    L.push('', 'DO $$', 'DECLARE v_n int;', 'BEGIN',
      '  -- No repaired row may still carry a non-URL entry.',
      '  SELECT count(*) INTO v_n FROM inform.politician_context pc',
      `   WHERE (pc.politician_id::text, pc.topic_id::text) IN (${ids})`,
      "     AND EXISTS (SELECT 1 FROM unnest(pc.sources) x WHERE x !~* '^https?://' AND x !~ '^[a-z0-9.-]+\\.[a-z]{2,}(/|$)');",
      "  IF v_n <> 0 THEN RAISE EXCEPTION '% repaired row(s) still contain a non-URL source', v_n; END IF;", '',
      '  -- ...and none may have been left without any source at all.',
      '  SELECT count(*) INTO v_n FROM inform.politician_context pc',
      `   WHERE (pc.politician_id::text, pc.topic_id::text) IN (${ids})`,
      '     AND coalesce(cardinality(pc.sources), 0) = 0;',
      "  IF v_n <> 0 THEN RAISE EXCEPTION '% repaired row(s) ended up with empty sources', v_n; END IF;",
      'END $$;', '', 'COMMIT;');
    writeFileSync(SQL, `${L.join('\n')}\n`);
    console.log(`sql      -> ${SQL}  (${emit.length} updates)`);
  }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });
