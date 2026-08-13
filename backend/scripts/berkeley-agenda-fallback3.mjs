#!/usr/bin/env node
/**
 * Third and last route for meetings with neither an annotated nor a plain agenda PDF: the eagenda
 * WEB PAGE, which renders the whole agenda inline.
 *
 * ⚠ Same provenance rule as fallback2 — this is the agenda as PUBLISHED, so authorship is readable
 * and outcomes are NOT. Tagged `agenda_only`.
 * 🔑 Several of these are special meetings carrying real Action and Consent calendars, so treating
 * "no PDF" as "no policy items" would have silently dropped them from every member's record.
 */
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const CACHE = path.join(process.env.TEMP || '/tmp', 'ev-stance-cache', 'berkeley');
const TXT = path.join(CACHE, 'txt');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
const MONTHS = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];

const missing = JSON.parse(fs.readFileSync(path.join(CACHE, 'missing-agendas.json'), 'utf8'));
const slugs = fs.readFileSync(path.join(CACHE, 'all-meetings.txt'), 'utf8').split(/\r?\n/).filter(Boolean);
const agendaOnly = JSON.parse(fs.readFileSync(path.join(CACHE, 'agenda-only.json'), 'utf8'));

const still = [];
for (const d of missing) {
  const [y, m, dd] = d.split('-');
  const human = `${MONTHS[+m - 1]}-${+dd}-${y}`;
  const pages = slugs.filter((s) => s.endsWith(`-eagenda-${human}`) && !/closed/.test(s));
  let text = '';
  for (const p of pages) {
    let html = '';
    try { html = execFileSync('curl', ['-sfL', '-A', UA, `https://berkeleyca.gov${p}`], { encoding: 'utf8', maxBuffer: 3e7 }); } catch { continue; }
    const body = html
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<\/(p|div|li|tr|h\d)>/gi, '\n')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#39;/g, "'").replace(/&quot;/g, '"')
      .replace(/[ \t]+/g, ' ')
      .replace(/\n\s*\n\s*\n+/g, '\n\n');
    if (body.length > text.length) text = body;
  }
  if (text.length > 3000) {
    fs.writeFileSync(path.join(TXT, `${d}.AGENDA-ONLY.txt`), text);
    agendaOnly.push(d);
  } else {
    still.push(d);
  }
}

fs.writeFileSync(path.join(CACHE, 'missing-agendas.json'), JSON.stringify(still, null, 1));
fs.writeFileSync(path.join(CACHE, 'agenda-only.json'), JSON.stringify([...new Set(agendaOnly)].sort(), null, 1));
console.log(`recovered from web eagenda: ${missing.length - still.length}`);
console.log(`\nSTILL WHOLLY UNREAD: ${still.length}`);
console.log(still.join(' '));
