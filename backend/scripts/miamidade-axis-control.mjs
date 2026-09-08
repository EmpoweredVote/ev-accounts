#!/usr/bin/env node
/**
 * miamidade-axis-control.mjs — ask what a lead pattern MISSED, which the leads file cannot answer.
 *
 * ── WHY THIS EXISTS ──────────────────────────────────────────────────────────
 *
 * `miamidade-sponsorship-leads.jsonl` stores only matters a topic pattern already matched. So
 * inside it, "the pattern found nothing on-axis" and "nothing on-axis exists" are the SAME
 * OBSERVATION. That is not a hypothetical gap:
 *
 *   · `local-environment` (2026-09-08) produced 43 matters, 32 of them Biscayne Bay water quality
 *     and board appointments, while being blind to the Chapter 24 / 33 / 15 ordinances that are the
 *     county's actual instrument on that ladder. A whole-Board pass nearly concluded "no instrument
 *     exists". This control found two.
 *   · `residential-zoning` matched a state submerged-lands lease on the words "LAND USE PLAN" and
 *     put it in NINE commissioners' leads, while the Rapid Transit Zone ordinances — the county's
 *     principal density instrument — matched only `transportation-priorities`.
 *
 * So before trusting a whole-Board refusal, re-fetch every commissioner's FULL sponsor report and
 * grep the raw titles for the vocabulary the LADDER turns on, not the vocabulary the pattern
 * happens to carry.
 *
 * ── 🔴 IT CARRIES ITS OWN POSITIVE CONTROL, AND WILL NOT REPORT A ZERO WITHOUT ONE ──
 *
 * A blind scan and a genuine absence look identical. Every run also counts a term certain to appear
 * ("resolution"/"ordinance"); if that comes back zero the scan is broken and the tool says so
 * instead of reporting your regex found nothing.
 *
 * RUN:
 *   node scripts/miamidade-axis-control.mjs --cache            # fetch + cache the raw titles
 *   node scripts/miamidade-axis-control.mjs --grep="tree canopy|mitigation bank"
 *   node scripts/miamidade-axis-control.mjs --topic=residential-zoning   # what the live pattern gets
 *
 * `--cache` writes data/stance-research/_miamidade-all-titles.json (gitignored scratch); the grep
 * modes reuse it, so a retune can be measured repeatedly without re-fetching.
 *
 * Needs DATABASE_URL for the cohort. No API key.
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import pg from 'pg';
import { resolveCodes, parseOfficeHolders, parseSponsorReport } from './miamidade-sponsorship-leads.mjs';
import { LOCAL_TOPIC_PATTERNS } from './lib/topic-lead-patterns.mjs';

const BASE = 'https://www.miamidade.gov/govaction';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
const MIAMI_DADE_GOVERNMENT_ID = 'd31ea899-f015-4456-8370-b727e3bef271';
const CACHE = 'data/stance-research/_miamidade-all-titles.json';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const since = flag('since') ?? '2025-01-01';
const until = flag('until') ?? '2026-09-05';
const usDate = (iso) => { const [y, m, d] = iso.split('-'); return `${m}/${d}/${y}`; };
const get = async (url) => (await fetch(url, { headers: { 'User-Agent': UA } })).text();

/** The term that proves the scan can see titles at all. Never remove it. */
const POSITIVE_CONTROL = /resolution|ordinance/i;

async function buildCache() {
  const { Pool } = pg;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const { rows: cohort } = await pool.query(
    `SELECT p.full_name FROM essentials.governments g
       JOIN essentials.chambers c ON c.government_id = g.id
       JOIN essentials.offices o ON o.chamber_id = c.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE g.id = $1 AND c.name IN ('Board of County Commissioners', 'Office of the Mayor')
      ORDER BY p.full_name`, [MIAMI_DADE_GOVERNMENT_ID]);
  await pool.end();

  const holders = parseOfficeHolders(await get(`${BASE}/ReportMenu.asp?ReportName=Sponsor.asp`));
  const out = [];
  for (const person of cohort) {
    // 🔴 FULL SET of codes, not the first — Regalado is B744 AND B779.
    const { codes } = resolveCodes(person.full_name, holders);
    if (!codes.length) { console.warn(`  ⚠ no office-holder code for ${person.full_name} — SKIPPED, not guessed`); continue; }
    const matters = new Map();
    for (const { code } of codes) {
      const url = `${BASE}/Sponsor.asp?begdate=${encodeURIComponent(usDate(since))}&enddate=${encodeURIComponent(usDate(until))}`
        + `&OfficeHolders=${code}&MatterType=AllMatters&submit1=Submit`;
      for (const m of parseSponsorReport(await get(url))) matters.set(m.matter_id, m);
    }
    for (const m of matters.values()) {
      out.push({ full_name: person.full_name, matter_id: m.matter_id, subject: m.subject ?? '', title: m.title ?? '' });
    }
    console.log(`  ${person.full_name.padEnd(26)} ${String(matters.size).padStart(4)}`);
  }
  mkdirSync(dirname(CACHE), { recursive: true });
  writeFileSync(CACHE, JSON.stringify(out));
  console.log(`\ncached ${out.length} (member, matter) rows -> ${CACHE}`);
  return out;
}

function load() {
  if (!existsSync(CACHE)) { console.error(`no cache — run with --cache first`); process.exit(1); }
  return JSON.parse(readFileSync(CACHE, 'utf8'));
}

function report(rows, re, label) {
  let control = 0;
  const hits = [];
  for (const r of rows) {
    const text = `${r.subject} ${r.title}`;
    if (POSITIVE_CONTROL.test(text)) control++;
    if (re.test(text)) hits.push(r);
  }
  const distinct = new Set(hits.map((h) => h.matter_id)).size;
  console.log(`\nswept ${rows.length} (member, matter) rows, ${new Set(rows.map((r) => r.matter_id)).size} distinct matters — UNFILTERED`);
  console.log(`positive control: ${control} hits — ${control > 0 ? 'the scan can see titles' : '🔴 SCAN IS BLIND, the count below means nothing'}`);
  if (control === 0) process.exit(2);
  console.log(`\n${label}: ${hits.length} leads / ${distinct} distinct matters`);
  const seen = new Set();
  for (const h of hits) {
    if (seen.has(h.matter_id)) continue;
    seen.add(h.matter_id);
    console.log(`  ${h.matter_id}  ${h.subject.slice(0, 76)}`);
  }
}

if (args.includes('--cache')) {
  await buildCache();
} else if (flag('grep')) {
  report(load(), new RegExp(flag('grep'), 'i'), `/${flag('grep')}/i`);
} else if (flag('topic')) {
  const re = LOCAL_TOPIC_PATTERNS[flag('topic')];
  if (!re) { console.error(`unknown topic ${flag('topic')}`); process.exit(1); }
  report(load(), re, `LOCAL_TOPIC_PATTERNS['${flag('topic')}']`);
} else {
  console.error('need --cache, --grep=<regex> or --topic=<topic_key>');
  process.exit(1);
}
