#!/usr/bin/env node
/**
 * Build a local corpus of EVERY Maryland bill number + title, per session/chamber,
 * from mgaleg's session index pages.
 *
 * WHY: stance reasoning cites named Acts ("Climate Solutions Now Act"). The cited
 * member page carries only ONE session, so it cannot confirm them. A complete local
 * title corpus turns "does this Act exist?" into an exact lookup instead of a guess.
 *
 * Writes: md-bill-corpus.json  { bills: [{session, chamber, number, title, sponsor}] }
 * Caches raw HTML so re-runs are free.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const OUT_DIR = process.argv[2];
if (!OUT_DIR) { console.error('usage: node build-md-bill-corpus.mjs <outdir>'); process.exit(2); }
const CACHE = path.join(OUT_DIR, 'mga-cache');
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const SESSIONS = [];
for (let y = 2012; y <= 2026; y++) SESSIONS.push(`${y}RS`);
const CHAMBERS = ['senate', 'house'];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getIndex(chamber, session) {
  const file = path.join(CACHE, `${chamber}-${session}.html`);
  if (fs.existsSync(file) && fs.statSync(file).size > 50_000) {
    return { html: fs.readFileSync(file, 'utf8'), cached: true };
  }
  const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Index/${chamber}?ys=${session}`;
  const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const html = await res.text();
  // A dead session redirects to /Error/NotFound but still answers 200 -- check the landing URL.
  const bad = /Error\/NotFound/i.test(res.url) || html.length < 50_000;
  if (bad) return { html: null, cached: false, status: res.status, landed: res.url, len: html.length };
  fs.writeFileSync(file, html);
  return { html, cached: false, status: res.status };
}

function parseIndex(html, chamber, session) {
  const root = parse(html);
  const out = [];
  for (const tr of root.querySelectorAll('tr')) {
    const tds = tr.querySelectorAll('td');
    if (tds.length < 3) continue;
    const link = tds[0].querySelector('a[href*="Legislation/Details/"]');
    if (!link) continue;
    const number = link.text.trim();
    if (!/^[SH]B\d+/i.test(number)) continue;
    const title = tds[1].text.replace(/\s+/g, ' ').trim();
    const sponsor = tds[2].text.replace(/\s+/g, ' ').trim();
    const slug = (link.getAttribute('href') || '').match(/Details\/([a-z0-9]+)/i)?.[1] ?? null;
    if (title) out.push({ session, chamber, number, slug, title, sponsor });
  }
  return out;
}

const bills = [];
const report = [];
for (const session of SESSIONS) {
  for (const chamber of CHAMBERS) {
    const r = await getIndex(chamber, session);
    if (!r.html) {
      report.push(`SKIP ${chamber} ${session} (landed=${r.landed} len=${r.len})`);
      await sleep(1200);
      continue;
    }
    const rows = parseIndex(r.html, chamber, session);
    bills.push(...rows);
    report.push(`OK   ${chamber} ${session}: ${rows.length} bills${r.cached ? ' (cached)' : ''}`);
    console.log(report[report.length - 1]);
    if (!r.cached) await sleep(1500);
  }
}

fs.writeFileSync(path.join(OUT_DIR, 'md-bill-corpus.json'), JSON.stringify({ built: 'session-index', sessions: SESSIONS, count: bills.length, bills }, null, 1));
console.log(`\nTOTAL ${bills.length} bills across ${SESSIONS.length} sessions`);
console.log(report.filter((l) => l.startsWith('SKIP')).join('\n') || 'no skipped sessions');
