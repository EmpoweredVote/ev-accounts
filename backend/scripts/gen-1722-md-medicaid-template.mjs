#!/usr/bin/env node
/**
 * Migration 1722 — replace the "backed Medicaid expansion" TEMPLATE on the Maryland rows.
 *
 * 🔴 THE PHRASE IS A TEMPLATE, NOT A CLAIM. It sits on 368 rows across 288 politicians in 44 states,
 * 360 of them with no bill citation of any kind. Maryland expanded Medicaid in 2013, so for members
 * seated afterwards the sentence is not merely unsourced — it is impossible. This migration does the
 * Maryland slice: 53 rows across 51 politicians, a WIDER and DIFFERENT cohort than migration 1714's,
 * which is the "the cohort itself was the defect" lesson again.
 *
 * 🔑 CHAIRS ARE NOT TOUCHED.
 *
 * 🔴🔴 THE CHAIR GATE — 9 ROWS REFUSED ON PURPOSE. On these 1-5 scales 1-2 is the PRO pole and 4-5 the
 * ANTI pole, so a citation to a bill the member SPONSORED can only ever evidence a PRO chair. Nine
 * rows sit at chair 3-5 and are left completely alone:
 *   · chair 5, pro-worded: Benjamin F. Kramer and Jeff Waldstreicher. Both were in the migration-1714
 *     bad batch for OTHER topics while their Healthcare Access rows were never flagged — so this looks
 *     like the 1714 inversion defect SURVIVING in rows that cohort never covered. They need the CHAIR
 *     pass, not a sourcing pass.
 *   · chair 4: Chris West, Jason C. Gallion, Johnny Mautz, Mary Beth Carozza, Nicholaus R. Kipke.
 *   · chair 3: Bryan W. Simonaire, Jack Bailey.
 * ⚠ Attaching sponsorship evidence to those rows would make the dot and the text contradict each
 * other. This workstream shipped exactly that once (mig 1712, Sara Love / Same-Sex Marriage) and had
 * to revert it.
 *
 * 🔑 THE CITATION QUOTES THE BILL'S OFFICIAL TITLE rather than paraphrasing its synopsis. Across 40
 * rows every paraphrase is a chance to overstate, and Maryland titles are descriptive enough to carry
 * the claim on their own. The generator re-checks the title, the chapter number and the sponsor slug
 * against the live bill page, so a citation cannot drift from what the page says.
 *
 *   node scripts/gen-1722-md-medicaid-template.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { UA, sponsorSlugs } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const BILLS = path.join(CACHE, 'bill-cache');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Rows recovered by the widened second look — STRICT applied to the FULL candidate list rather than
 * to a shortlist of three. Without this they would have been recorded as "no on-topic bill", an
 * absence manufactured by the order of my own steps.
 */
const WIDENED = {
  'Brooke Lierman|Healthcare Access': '2020RS:hb0930',
  'Edith J. Patterson|Healthcare Access': '2026RS:hb0393',
  'Mark S. Chang|Healthcare Access': '2023RS:hb0726',
  'Ron Watson|Healthcare Access': '2022RS:sb0621',
  'Adrienne A. Jones|Medicare / Medicaid': '2017RS:hb1158',
  'Bill Ferguson|Medicare / Medicaid': '2014RS:sb0721',
};

/** Left alone, with the reason recorded rather than glossed. */
const OWED = [
  ['Benjamin F. Kramer', 'Healthcare Access', 'chair 5 with pro-worded reasoning — looks like the mig-1714 inversion defect in a row that cohort never covered; needs the CHAIR pass'],
  ['Jeff Waldstreicher', 'Healthcare Access', 'chair 5 with pro-worded reasoning — same as Kramer; needs the CHAIR pass'],
  ['Chris West', 'Healthcare Access', 'chair 4 (anti pole) — sponsorship cannot evidence it'],
  ['Jason C. Gallion', 'Healthcare Access', 'chair 4 (anti pole) — sponsorship cannot evidence it'],
  ['Johnny Mautz', 'Healthcare Access', 'chair 4 (anti pole), and his member record returned no readable session'],
  ['Mary Beth Carozza', 'Healthcare Access', 'chair 4 (anti pole) — already recorded in the 1714 notes as a member whose co-sponsorships point the other way'],
  ['Nicholaus R. Kipke', 'Healthcare Access', 'chair 4 (anti pole) — sponsorship cannot evidence it'],
  ['Bryan W. Simonaire', 'Healthcare Access', 'chair 3 (middle option) — a pro-side sponsorship does not evidence it'],
  ['Jack Bailey', 'Healthcare Access', 'chair 3 (middle option) — a pro-side sponsorship does not evidence it'],
  ['Dalya Attar', 'Healthcare Access', 'no bill passed the STRICT title test in any readable session'],
  ['Aruna Miller', 'Healthcare Access', 'no readable session — tenure unparsed on her mgaleg page (now Lt. Governor)'],
  ['Karen Toles', 'Healthcare Access', 'no readable session — her tenure reads "Maryland General Assembly", which names no chamber, so no session could be resolved'],
  ['Brian J. Feldman', 'Medicare / Medicaid', 'no mgaleg member slug in sources (only a Wikipedia link), so no record could be read'],
];

const textOf = (h) => h.replace(/<[^>]*>/g, ' ').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ');
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop();

async function billHtml(slug, session) {
  const f = path.join(BILLS, `${slug}-${session}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) return fs.readFileSync(f, 'utf8');
  const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`, { headers: { 'User-Agent': UA } });
  const body = await res.text(); await sleep(1100);
  if (!res.ok || body.length < 20000) return null;
  fs.writeFileSync(f, body); return body;
}

const PROPS = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-medicaid-proposals.json', 'utf8'));
const LEG = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-medicaid-legislation.json', 'utf8'));
const corpus = JSON.parse(fs.readFileSync(path.join(CACHE, 'md-bill-corpus.json'), 'utf8'));
const meta = {};
for (const b of corpus.bills) if (b.title && b.title.length > 5) meta[`${b.session}:${b.slug}`] = b;
const leadOf = (k) => (meta[k] ? (meta[k].sponsor || '') : '');

const owedKeys = new Set(OWED.map(([n, t]) => `${n}|${t}`));
const work = [];
for (const r of PROPS.rows) {
  const key = `${r.name}|${r.topic}`;
  if (owedKeys.has(key)) continue;
  const billKey = r.proposal ? r.proposal.key : WIDENED[key];
  if (!billKey) throw new Error(`${key}: neither a proposal nor a widened pick, and not in OWED`);
  work.push({ ...r, billKey });
}
console.log(`${work.length} rows to re-source; ${OWED.length} left owed (of ${PROPS.rows.length}).`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });

const updates = [], rollback = [];
for (const w of work) {
  const [session, slug] = w.billKey.split(':');
  const m = meta[w.billKey];
  if (!m) throw new Error(`${w.billKey} not in the corpus`);
  const html = await billHtml(slug, session);
  if (!html) throw new Error(`${w.billKey}: bill page unavailable`);
  const t = textOf(html);

  // 🔑 identity, at write time, from the page's own sponsor hyperlink
  const leg = LEG.rows.find((x) => x.politician_id === w.politician_id && x.topic_id === w.topic_id);
  if (!sponsorSlugs(html).some((s) => s.slug === leg.member_slug)) {
    throw new Error(`${w.name} / ${w.billKey}: member slug ${leg.member_slug} is not on the sponsor list`);
  }
  // 🔑 the quoted title must be the page's title, and the chapter must be the page's chapter
  const sp = t.indexOf('Sponsored by');
  const status = sp > -1 ? t.slice(t.indexOf('Status', sp) + 6, t.indexOf('Status', sp) + 150) : '';
  const chap = (status.match(/Chapter\s+(\d+)/i) || [])[1];
  const title = m.title.replace(/\s+/g, ' ').trim();
  if (!t.includes(title.slice(0, 40))) throw new Error(`${w.billKey}: corpus title not found on the page`);

  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, tp.title
       FROM inform.politician_context c
       JOIN essentials.politicians p ON p.id = c.politician_id
       LEFT JOIN inform.compass_topics tp ON tp.id = c.topic_id
       LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
      WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.politician_id, w.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${w.name}/${w.topic}, got ${got.length}`);
  const live = got[0];
  if (live.full_name !== w.name || live.title !== w.topic) throw new Error(`identity mismatch for ${w.name}`);
  if (live.reasoning !== w.old_reasoning) throw new Error(`reasoning changed since the scan for ${w.name}/${w.topic}`);
  if (!/Medicaid expansion/i.test(live.reasoning)) throw new Error(`${w.name}: row no longer carries the template phrase`);

  const isLead = new RegExp(`^(Delegate|Senator)s?\\s+${surnameOf(w.name)}$`, 'i').test(leadOf(w.billKey).trim());
  const year = session.slice(0, 4);
  const why = `${surnameOf(w.name)} ${isLead ? 'was the lead sponsor of' : 'co-sponsored'} ${m.number} (${year}), "${title}"`
    + (chap ? `, enacted as Chapter ${chap} of ${year}.` : '.');
  const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`;
  const old = live.sources || [];
  const sources = [url, ...old.filter((s) => s !== url)];

  updates.push({ ...w, new_reasoning: why, new_sources: sources, isLead, chapter: chap || null });
  rollback.push({ politician_id: w.politician_id, topic_id: w.topic_id, name: w.name, topic: w.topic,
    old_reasoning: live.reasoning, old_sources: old, chair_untouched: Number(live.value) });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'MD medicaid-template re-sourcing (1722)', rows: rollback }, null, 1));
console.log(`  lead-sponsored: ${updates.filter((u) => u.isLead).length}; co-sponsored: ${updates.filter((u) => !u.isLead).length}; enacted: ${updates.filter((u) => u.chapter).length}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- REPLACE THE "backed Medicaid expansion" TEMPLATE — the Maryland slice.`);
L.push(`--`);
L.push(`-- The phrase sits on 368 rows across 288 politicians in 44 states, 360 with NO bill citation of`);
L.push(`-- any kind. Maryland expanded Medicaid in 2013, so for members seated afterwards the sentence is`);
L.push(`-- not merely unsourced, it is impossible. 53 Maryland rows across 51 politicians — a WIDER and`);
L.push(`-- DIFFERENT cohort than migration 1714's, which is the "the cohort itself was the defect" lesson.`);
L.push(`--`);
L.push(`-- 🔑 CHAIRS ARE NOT TOUCHED.`);
L.push(`--`);
L.push(`-- 🔴🔴 THE CHAIR GATE — 9 ROWS REFUSED ON PURPOSE. 1-2 is the PRO pole and 4-5 the ANTI pole, so a`);
L.push(`-- citation to a bill the member SPONSORED can only ever evidence a PRO chair. Attaching one to a`);
L.push(`-- chair-4/5 row would make the dot and the text contradict each other; this workstream shipped`);
L.push(`-- exactly that once (mig 1712) and had to revert it.`);
L.push(`-- ⚠ Kramer and Waldstreicher sit at chair 5 with PRO-worded reasoning. Both were in the 1714 bad`);
L.push(`-- batch for other topics while their Healthcare Access rows were never flagged — the inversion`);
L.push(`-- defect surviving in rows that cohort never covered. They need the CHAIR pass.`);
L.push(`--`);
L.push(`-- 🔑 THE CITATION QUOTES THE BILL'S OFFICIAL TITLE instead of paraphrasing its synopsis: across 40`);
L.push(`-- rows every paraphrase is a chance to overstate. Title, chapter number and sponsor slug are all`);
L.push(`-- re-checked against the live bill page at generation time.`);
L.push(`--`);
L.push(`-- ${OWED.length} rows left owed, with reasons:`);
for (const [n, t, why] of OWED) L.push(`--   · ${n} / ${t}: ${why}`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE mt_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before,`);
L.push(`       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;`);
L.push(``);
L.push(`CREATE TEMP TABLE mt_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;`);
L.push(`INSERT INTO mt_intent (pid, tid, reasoning, sources) VALUES`);
updates.forEach((u, i) => {
  L.push(`-- ${u.name} / ${u.topic} (chair ${u.chair}) — ${u.isLead ? 'lead' : 'cosp'} on ${u.billKey}`);
  L.push(`(${q(u.politician_id)}, ${q(u.topic_id)}, ${q(u.new_reasoning)}, ${arr(u.new_sources)})${i === updates.length - 1 ? ';' : ','}`);
});
L.push(``);
L.push(`UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources`);
L.push(`FROM mt_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;`);
L.push(``);
L.push(`-- Guard 1: intended text landed, an mgaleg bill page is cited, and the template phrase is GONE.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM mt_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid`);
L.push(`  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources`);
L.push(`     OR c.reasoning ILIKE '%Medicaid expansion%'`);
L.push(`     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${updates.length} rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM mt_snapshot;`);
L.push(`  SELECT count(*) INTO n FROM mt_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;`);
L.push(`  IF n <> ${updates.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${updates.length}', n; END IF;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  RAISE NOTICE 'medicaid template ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}\nwrote ${ROLLBACK}`);
