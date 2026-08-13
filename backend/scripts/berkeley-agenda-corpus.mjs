#!/usr/bin/env node
/**
 * Build the COMPLETE Berkeley City Council record for the five members who hold owed chairs.
 *
 * 🔑 THE POINT: Maryland taught that a row can never be decided from the documents the original
 * author happened to cite. The mgaleg "sponsored bills" list was what made MD decidable; Berkeley's
 * equivalent is the ANNOTATED AGENDA, which names the Author and Co-Sponsors of every council item
 * and records the roll-call vote. Downloading every one of them gives the same complete list.
 *
 * ⚠ Closed-session meetings are personnel/litigation and carry no policy items — skipped, and that
 * is a deliberate exclusion, not a gap: they are the only meetings excluded.
 *
 *   node scripts/berkeley-agenda-corpus.mjs --fetch    — download every annotated agenda
 *   node scripts/berkeley-agenda-corpus.mjs --index    — parse authorship + votes into JSON
 */
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const CACHE = path.join(process.env.TEMP || '/tmp', 'ev-stance-cache', 'berkeley');
const PDFS = path.join(CACHE, 'pdf');
const TXT = path.join(CACHE, 'txt');
const argv = process.argv.slice(2);
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';

const MONTHS = {
  january: 1, february: 2, march: 3, april: 4, may: 5, june: 6,
  july: 7, august: 8, september: 9, october: 10, november: 11, december: 12,
};

function meetingDates() {
  const lines = fs.readFileSync(path.join(CACHE, 'all-meetings.txt'), 'utf8').split(/\r?\n/).filter(Boolean);
  const dates = new Set();
  for (const l of lines) {
    if (/closed/.test(l) || /^\/cancelled/.test(l)) continue; // no policy items in closed session
    const m = l.match(/eagenda-([a-z]+)-(\d{1,2})-(\d{4})$/);
    if (!m) continue;
    const mo = MONTHS[m[1]];
    if (!mo) continue;
    dates.add(`${m[3]}-${String(mo).padStart(2, '0')}-${String(+m[2]).padStart(2, '0')}`);
  }
  return [...dates].sort();
}

if (argv.includes('--fetch')) {
  fs.mkdirSync(PDFS, { recursive: true });
  fs.mkdirSync(TXT, { recursive: true });
  const dates = meetingDates();
  console.log(`${dates.length} open meetings ${dates[0]} → ${dates.at(-1)}`);
  const missing = [];
  for (const d of dates) {
    const pdf = path.join(PDFS, `${d}.pdf`);
    if (!fs.existsSync(pdf) || fs.statSync(pdf).size < 5000) {
      const url = `https://berkeleyca.gov/sites/default/files/city-council-meetings/${d}%20Annotated%20Agenda%20-%20Council.pdf`;
      try {
        execFileSync('curl', ['-sfL', '-A', UA, '-o', pdf, url], { stdio: 'pipe' });
      } catch {
        missing.push(d);
        if (fs.existsSync(pdf)) fs.unlinkSync(pdf);
        continue;
      }
    }
    const txt = path.join(TXT, `${d}.txt`);
    if (!fs.existsSync(txt)) {
      try { execFileSync('pdftotext', ['-layout', pdf, txt], { stdio: 'pipe' }); } catch { missing.push(d); }
    }
  }
  // 🔴 A meeting with no annotated agenda is an UNREAD meeting, and Maryland's rule applies: an
  // absence finding over an incomplete record is not a finding. Record them explicitly.
  fs.writeFileSync(path.join(CACHE, 'missing-agendas.json'), JSON.stringify(missing, null, 1));
  console.log(`downloaded: ${dates.length - missing.length}   NO ANNOTATED AGENDA: ${missing.length}`);
  if (missing.length) console.log(missing.join(' '));
}

if (argv.includes('--index')) {
  const MEMBERS = ['Kesarwani', 'Taplin', 'Bartlett', 'Tregub', 'Blackaby'];
  const items = [];
  for (const f of fs.readdirSync(TXT).sort()) {
    const date = f.replace(/\.(AGENDA-ONLY\.)?txt$/, '').replace(/\.AGENDA-ONLY$/, '');
    const agendaOnly = /AGENDA-ONLY/.test(f);
    // 🔴 pdftotext breaks words across lines with a hyphen, so "(Co-\n Sponsor)" is NOT the string
    // "(Co-Sponsor)". Un-wrap BEFORE any matching or every co-sponsorship silently reads as absent.
    // ⚠ The line may carry TRAILING SPACES before the break ("Co-   \n   Sponsor"), so anchoring on
    // "-\n" alone still lost 55 co-sponsorships across the corpus — 14 of Blackaby's own.
    let raw = fs.readFileSync(path.join(TXT, f), 'utf8').replace(/-[ \t]*\r?\n[ \t]*/g, '-');
    // 🔴🔴 CUT THE TRAILING "Communications" SECTION FIRST. It reprints each item's heading AND its
    // "From:" line to log public correspondence. Left in, those reprints bleed into the PRECEDING
    // item's chunk, and a co-sponsor named in the reprint gets attributed to the wrong item —
    // a fabricated sponsorship, not merely a duplicate. It also double-counts every member's record.
    const commIdx = raw.search(/\n\s*Adjourn(ed|ment)[\s\S]{0,400}?\n\s*Communications\s*\n/);
    if (commIdx > -1) raw = raw.slice(0, raw.indexOf('\nCommunications', commIdx));
    const chunks = raw.split(/\n(?=\s{0,8}\d{1,3}\.\s+\S)/);
    for (const c of chunks) {
      const num = c.match(/^\s{0,8}(\d{1,3})\.\s+(.+)/);
      if (!num) continue;
      // ⚠ Agendas end with a numbered list of PUBLIC SPEAKERS that looks exactly like an item list.
      // A real item always carries a From:/Recommendation:/Action: block; a speaker name never does.
      if (!/\b(From:|Recommendation:|Action:|Contact:)/.test(c)) continue;
      const title = num[2].trim() + ' ' + (c.split('\n')[1] || '').trim();
      const from = (c.match(/From:\s*([\s\S]*?)(?=\n\s*(Recommendation|Financial|Contact|Submitted)|$)/) || [])[1] || '';
      const roles = {};
      for (const m of MEMBERS) {
        // "Councilmember Tregub (Author)" / "(Co-Sponsor)" — authorship is stated on the From: line.
        const re = new RegExp(`${m}\\s*\\((Author|Co-?Sponsor)\\)`, 'i');
        const hit = from.replace(/\s+/g, ' ').match(re);
        if (hit) roles[m] = /author/i.test(hit[1]) ? 'author' : 'cosponsor';
        // Late co-sponsorship is recorded in the Action line, not the From: line.
        else if (new RegExp(`Councilmembers?[^.]{0,80}\\b${m}\\b[^.]{0,60}added as (a )?co-sponsors?`, 'i').test(c.replace(/\s+/g, ' '))) roles[m] = 'cosponsor';
      }
      const action = (c.match(/Action:\s*([\s\S]*?)(?=\n\s*\n|$)/) || [])[1] || '';
      const vote = (c.match(/Vote:\s*([\s\S]*?)(?=\n\s*\n|$)/) || [])[1] || '';
      items.push({
        date, agenda_only: agendaOnly, item: +num[1], title: title.replace(/\s+/g, ' ').slice(0, 300),
        from: from.replace(/\s+/g, ' ').trim().slice(0, 300),
        roles, action: action.replace(/\s+/g, ' ').trim().slice(0, 700),
        vote: vote.replace(/\s+/g, ' ').trim().slice(0, 400),
        text: c.replace(/\s+/g, ' ').trim().slice(0, 2500),
      });
    }
  }
  // Belt and braces: one row per (meeting, item). Keep the first, which is the item proper.
  const seen = new Set();
  const deduped = items.filter((i) => {
    const k = `${i.date}#${i.item}`;
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
  const dropped = items.length - deduped.length;
  items.length = 0;
  items.push(...deduped);
  const out = path.join(CACHE, 'berkeley-items.json');
  fs.writeFileSync(out, JSON.stringify(items, null, 1));
  console.log(`${items.length} council items indexed (${dropped} duplicate item headings dropped) → ${out}`);
  for (const m of MEMBERS) {
    const a = items.filter((i) => i.roles[m] === 'author').length;
    const c = items.filter((i) => i.roles[m] === 'cosponsor').length;
    console.log(`  ${m.padEnd(11)} author ${String(a).padStart(4)}   co-sponsor ${String(c).padStart(4)}`);
  }
}
