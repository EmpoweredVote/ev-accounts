#!/usr/bin/env node
/**
 * Close the annotated agendas the direct URL pattern misses.
 *
 * 🔴 WHY THIS EXISTS: 44 of 157 meetings had no PDF at the canonical
 * `<date> Annotated Agenda - Council.pdf` path. Maryland's unreadable-session trap was exactly
 * this shape — a page that returns nothing is not the same as a record that contains nothing — so
 * every miss gets a second route before any of them is called absent.
 */
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const CACHE = path.join(process.env.TEMP || '/tmp', 'ev-stance-cache', 'berkeley');
const PDFS = path.join(CACHE, 'pdf');
const TXT = path.join(CACHE, 'txt');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
const MONTHS = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];

const missing = JSON.parse(fs.readFileSync(path.join(CACHE, 'missing-agendas.json'), 'utf8'));
const slugs = fs.readFileSync(path.join(CACHE, 'all-meetings.txt'), 'utf8').split(/\r?\n/).filter(Boolean);

const still = [];
const recovered = [];
for (const d of missing) {
  const [y, m, dd] = d.split('-');
  const human = `${MONTHS[+m - 1]}-${+dd}-${y}`;
  const pages = slugs.filter((s) => s.endsWith(`-eagenda-${human}`));
  let got = false;
  for (const p of pages) {
    let html = '';
    try { html = execFileSync('curl', ['-sfL', '-A', UA, `https://berkeleyca.gov${p}`], { encoding: 'utf8', maxBuffer: 3e7 }); } catch { continue; }
    // Any PDF on the page whose link text or filename says annotated agenda / minutes.
    const links = [...html.matchAll(/href="([^"]+\.pdf)"/gi)].map((x) => x[1]);
    const cand = links.find((l) => /annotated/i.test(decodeURIComponent(l)))
              || links.find((l) => /minutes/i.test(decodeURIComponent(l)));
    if (!cand) continue;
    const url = cand.startsWith('http') ? cand : `https://berkeleyca.gov${cand}`;
    const pdf = path.join(PDFS, `${d}.pdf`);
    try {
      execFileSync('curl', ['-sfL', '-A', UA, '-o', pdf, url], { stdio: 'pipe' });
      if (fs.statSync(pdf).size < 5000) throw new Error('stub');
      execFileSync('pdftotext', ['-layout', pdf, path.join(TXT, `${d}.txt`)], { stdio: 'pipe' });
      recovered.push([d, decodeURIComponent(url.split('/').pop())]);
      got = true;
      break;
    } catch { if (fs.existsSync(pdf)) fs.unlinkSync(pdf); }
  }
  if (!got) still.push(d);
}

fs.writeFileSync(path.join(CACHE, 'missing-agendas.json'), JSON.stringify(still, null, 1));
console.log(`recovered ${recovered.length}:`);
for (const [d, f] of recovered) console.log(`  ${d}  ${f}`);
console.log(`\nSTILL UNREAD: ${still.length}`);
console.log(still.join(' '));
