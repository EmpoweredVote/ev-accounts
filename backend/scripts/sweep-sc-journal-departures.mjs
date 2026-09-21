#!/usr/bin/env node
/**
 * sweep-sc-journal-departures.mjs — Knight program, wave SC-2.
 *
 * Reads every House and Senate Journal day of the 126th General Assembly and reports every
 * sentence that announces a member LEAVING — a resignation, a vacancy, a seat declared vacant,
 * a death. Writes data/seed-sc-legislature-2026/departures.json. Touches no database.
 *
 * 🔴🔴 WHY THIS EXISTS. SC-2's change-check read all 170 member pages, and every one named the
 * member the chamber's list assigned to that district — including SD-15, whose senator had
 * RESIGNED on 2026-06-22 to run for Congress. The chamber's list, the member's own page, Open
 * States AND the state's GIS layer all still showed him. MN-2's rule said a roster LIST page is
 * not a change-check and sent us to the member's own page; South Carolina shows that the
 * member's own page is not one either. The body's own JOURNAL is the record that cannot be
 * stale, because the resignation is read into it.
 *
 * ⚠ A journal sweep answers "who left", never "who arrived" — pair it with
 * find-sc-oath-dates.mjs, which reads the other half of the same record.
 *
 * Usage:
 *   node scripts/sweep-sc-journal-departures.mjs [--from 2025-01-01] [--to <today>]
 *   node scripts/sweep-sc-journal-departures.mjs --control
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = path.join(HERE, '..', 'data', 'seed-sc-legislature-2026');
const OUT = path.join(DATA, 'departures.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

function sessionFolder(year) {
  const start = year % 2 === 1 ? year : year - 1;
  const num = 126 - (2025 - start) / 2;
  return `sess${num}_${start}-${start + 1}`;
}

export function journalUrl(chamber, ymd) {
  const dir = (chamber === 'house' ? 'hj' : 'sj') + ymd.slice(2, 4);
  return `https://www.scstatehouse.gov/${sessionFolder(Number(ymd.slice(0, 4)))}/${dir}/${ymd}.htm`;
}

async function journalText(url) {
  try {
    const r = await fetch(url, { headers: UA });
    if (r.status !== 200) return null;
    const h = await r.text();
    return h
      .replace(/<script[\s\S]*?<\/script>/g, ' ')
      .replace(/<style[\s\S]*?<\/style>/g, ' ')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/\s+/g, ' ');
  } catch {
    return null;
  }
}

/** Deliberately broad. Every hit is READ; nothing is auto-cleared, because "vacancy" appears in
 *  committee names and bill titles and a narrow pattern is how a real one gets missed. */
export const DEPARTURE_RE =
  /\b(resignation|resigned|has resigned|tendered his resignation|tendered her resignation|declared vacant|seat (?:is|was) vacant|vacancy (?:in|exists)|died|passed away|deceased)\b/gi;

export function extract(text) {
  const out = [];
  for (const m of text.matchAll(DEPARTURE_RE)) {
    const at = m.index;
    out.push({ word: m[0], quote: text.slice(Math.max(0, at - 220), at + 220).trim() });
  }
  return out;
}

function days(from, to) {
  const out = [];
  for (const d = new Date(from); d <= to; d.setUTCDate(d.getUTCDate() + 1)) {
    const dow = d.getUTCDay();
    if (dow === 0 || dow === 6) continue;
    out.push(d.toISOString().slice(0, 10).replace(/-/g, ''));
  }
  return out;
}

async function control() {
  let ok = true;
  const say = (p, w) => {
    if (!p) ok = false;
    console.log(`  ${p ? 'PASS' : '🔴 FAIL'}  ${w}`);
  };
  const t = await journalText(journalUrl('house', '20260113'));
  say(!!t, 'a known journal day fetches');
  say(journalText(journalUrl('house', '20260104')) !== null, 'a non-session day is handled, not thrown');
  say(extract('the Speaker announced that Mr. X has resigned effective June 22').length === 1, 'a resignation sentence is extracted');
  say(extract('serves on the Vacancy Board Committee').length === 0, 'a committee name alone is not a departure word');
  say(extract('a vacancy exists in District No. 15').length === 1, '"vacancy exists" is extracted');
  say(extract('nothing of interest here').length === 0, 'clean text yields nothing — the sweep can return empty');
  return ok;
}

const argv = process.argv.slice(2);
if (argv.includes('--control')) {
  console.log('control — the extractor must hit AND miss on the right inputs:');
  process.exit((await control()) ? 0 : 1);
}

const fromArg = argv[argv.indexOf('--from') + 1];
const toArg = argv[argv.indexOf('--to') + 1];
const from = new Date(`${argv.includes('--from') ? fromArg : '2025-01-01'}T00:00:00Z`);
const to = new Date(`${argv.includes('--to') ? toArg : new Date().toISOString().slice(0, 10)}T00:00:00Z`);

const results = [];
for (const chamber of ['house', 'senate']) {
  const list = days(new Date(from), new Date(to));
  let sat = 0;
  const CONC = 8;
  for (let i = 0; i < list.length; i += CONC) {
    const batch = list.slice(i, i + CONC);
    const texts = await Promise.all(batch.map((d) => journalText(journalUrl(chamber, d))));
    texts.forEach((t, k) => {
      if (!t) return;
      sat++;
      for (const hit of extract(t)) {
        results.push({ chamber, date: `${batch[k].slice(0, 4)}-${batch[k].slice(4, 6)}-${batch[k].slice(6)}`, url: journalUrl(chamber, batch[k]), ...hit });
      }
    });
    process.stdout.write(`\r  ${chamber}: ${Math.min(i + CONC, list.length)}/${list.length} days probed, ${sat} sat, ${results.filter((r) => r.chamber === chamber).length} hit(s)`);
  }
  process.stdout.write('\n');
}

fs.mkdirSync(DATA, { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(results, null, 2) + '\n');
console.log(`\nwrote ${OUT} — ${results.length} sentence(s) to read`);
