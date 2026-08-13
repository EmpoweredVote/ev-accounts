#!/usr/bin/env node
/**
 * Second route for the 40 meetings with no ANNOTATED agenda: the plain agenda.
 *
 * 🔴🔴 PROVENANCE MATTERS AND IS NOT COSMETIC. A plain agenda carries the "From: Councilmember X
 * (Author)" line but NOT the Action or the Vote — it says what was PROPOSED, never what was
 * ADOPTED. Files landed here are tagged `agenda_only` so nothing downstream can cite a vote that
 * this document cannot support. Berkeley items are routinely amended or dropped on the floor.
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

const agendaOnly = [];
const still = [];
for (const d of missing) {
  const [y, m, dd] = d.split('-');
  const human = `${MONTHS[+m - 1]}-${+dd}-${y}`;
  const pages = slugs.filter((s) => s.endsWith(`-eagenda-${human}`));
  let got = false;
  for (const p of pages) {
    let html = '';
    try { html = execFileSync('curl', ['-sfL', '-A', UA, `https://berkeleyca.gov${p}`], { encoding: 'utf8', maxBuffer: 3e7 }); } catch { continue; }
    const links = [...html.matchAll(/href="([^"]+\.pdf)"/gi)].map((x) => x[1]);
    // The whole-meeting agenda, not a per-item attachment: "<date> Agenda - Council.pdf".
    const cand = links.find((l) => /\d{4}-\d{2}-\d{2}%20Agenda%20-%20/i.test(l) || /\d{4}-\d{2}-\d{2}\s+Agenda\s+-\s+/i.test(decodeURIComponent(l)));
    if (!cand) continue;
    const url = cand.startsWith('http') ? cand : `https://berkeleyca.gov${cand}`;
    const pdf = path.join(PDFS, `${d}.AGENDA-ONLY.pdf`);
    try {
      execFileSync('curl', ['-sfL', '-A', UA, '-o', pdf, url], { stdio: 'pipe' });
      if (fs.statSync(pdf).size < 5000) throw new Error('stub');
      execFileSync('pdftotext', ['-layout', pdf, path.join(TXT, `${d}.AGENDA-ONLY.txt`)], { stdio: 'pipe' });
      agendaOnly.push(d);
      got = true;
      break;
    } catch { if (fs.existsSync(pdf)) fs.unlinkSync(pdf); }
  }
  if (!got) still.push(d);
}

fs.writeFileSync(path.join(CACHE, 'missing-agendas.json'), JSON.stringify(still, null, 1));
fs.writeFileSync(path.join(CACHE, 'agenda-only.json'), JSON.stringify(agendaOnly, null, 1));
console.log(`agenda-only (authorship readable, VOTES NOT): ${agendaOnly.length}`);
console.log(agendaOnly.join(' '));
console.log(`\nSTILL WHOLLY UNREAD: ${still.length}`);
console.log(still.join(' '));
