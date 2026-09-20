#!/usr/bin/env node
/**
 * find-sc-oath-dates.mjs — Knight program, wave SC-2.
 *
 * Dates the arrival of every South Carolina legislator whose own page says they were elected
 * to fill an unexpired term, by finding the OATH in that chamber's own journal. Writes
 * data/seed-sc-legislature-2026/oath-dates.json. Touches no database.
 *
 * 🔴🔴 THE ELECTION DATE IS NOT THE TERM START, AND IN SOUTH CAROLINA THE GAP CAN BE SEVEN
 * MONTHS. HD-50's page says "Elected in Special Election June 3, 2025"; the House Journal
 * records his oath on 2026-01-13, because the House was not sitting in between. A member-elect
 * is not a member. Writing the election date would overstate occupancy by more than half a
 * year, and "first elected" is already known to fail in both directions (it hid a resignation
 * by 9 years and an appointment by 6 weeks in one Knight wave).
 *
 * 🔴 THE TWO CHAMBERS RECORD THE SAME EVENT IN DIFFERENT WORDS. The House writes
 * "MEMBER-ELECT SWORN IN … Member-elect from District No. N … the oath of office was
 * administered"; the Senate writes "Senator X presented himself at the Bar and the oath of
 * office was administered by PRESIDENT …". A regex built from one chamber's formula returns a
 * confident NOT FOUND for the other — which is what it did here, on SD-12, until the Senate's
 * wording was read.
 *
 * 🔴 AN ARRIVAL LINE CAN DATE THE OTHER CHAMBER'S SEAT. SD-26's page carries "Elected in
 * Special Election October 29, 2013 to fulfill the unexpired term of Harry L. Ott, Jr." — that
 * was a HOUSE seat, ten years before he entered the Senate. So the search is run against the
 * journal of the chamber the member sits in TODAY: a line that belongs to the other chamber
 * simply finds nothing, and is reported rather than used.
 *
 * Usage:
 *   node scripts/find-sc-oath-dates.mjs                 read arrivals, search, write JSON
 *   node scripts/find-sc-oath-dates.mjs --extract       re-read all 170 member pages for arrival
 *                                                      lines first (automatic if arrivals.json
 *                                                      is absent)
 *   node scripts/find-sc-oath-dates.mjs --control       prove the search can fail and can hit
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DATA = path.join(HERE, '..', 'data', 'seed-sc-legislature-2026');
const ARRIVALS = path.join(DATA, 'arrivals.json');
const OUT = path.join(DATA, 'oath-dates.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const MONTHS = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12,
};

/** Session directory name: the journals are filed by CALENDAR year, hj25 / hj26, inside the
 *  two-year session folder. Both are derived, never guessed one at a time. */
function sessionFolder(year) {
  // The 126th General Assembly is 2025-2026; each assembly spans an odd year and the next.
  const start = year % 2 === 1 ? year : year - 1;
  const num = 126 - (2025 - start) / 2;
  return `sess${num}_${start}-${start + 1}`;
}

export function journalUrl(chamber, ymd) {
  const year = Number(ymd.slice(0, 4));
  const dir = (chamber === 'house' ? 'hj' : 'sj') + ymd.slice(2, 4);
  return `https://www.scstatehouse.gov/${sessionFolder(year)}/${dir}/${ymd}.htm`;
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

/**
 * Both chambers' formulas. Each returns the matched sentence, and the caller asserts the
 * member's surname appears in a window around it — the district number alone is not identity,
 * and a surname alone is not a seat.
 */
export function findOath(text, district, surname) {
  const patterns = [
    // House, and the Senate when it uses the same shape.
    new RegExp(`(?:Member|Senator)-elect from District No\\.? ${district}\\b[^;]{0,220}?oath of office was administered`, 'i'),
    // Senate: no district number in the sentence at all, so the surname carries the identity.
    // 🔴 The journal renders a compound surname in full — "Senator BRIGHT MATTHEWS" — so the
    // pattern must allow the leading token(s) it prints before the name being matched. Without
    // this, SD-45 read as NOT FOUND across 84 journal days, which is a confident wrong answer.
    new RegExp(`Senator (?:[A-Z][A-Za-z'’-]*\\s+){0,2}${surname.toUpperCase()}\\b[^;]{0,200}?oath of office was administered`, 'i'),
  ];
  for (const re of patterns) {
    const m = text.match(re);
    if (!m) continue;
    const at = text.indexOf(m[0]);
    const window = text.slice(Math.max(0, at - 140), at + m[0].length);
    if (!new RegExp(surname, 'i').test(window)) continue;
    return { quote: m[0].replace(/\s+/g, ' ').slice(0, 240), window: window.slice(-320) };
  }
  return null;
}

/** Every calendar day from the election forward, for `months` months. A member elected in a
 *  recess takes the oath when the body next sits, and that can be the following session. */
function daysAfter(elected, months = 10) {
  const m = elected.match(/([A-Za-z]+)\.?\s+(\d{1,2}),?\s+(\d{4})/);
  if (!m) return [];
  const start = new Date(Date.UTC(Number(m[3]), (MONTHS[m[1].slice(0, 3).toLowerCase()] ?? 1) - 1, Number(m[2])));
  const out = [];
  const end = new Date(start);
  end.setUTCMonth(end.getUTCMonth() + months);
  for (const d = new Date(start); d <= end; d.setUTCDate(d.getUTCDate() + 1)) {
    const dow = d.getUTCDay();
    if (dow === 0 || dow === 6) continue; // neither chamber sits at a weekend
    out.push(d.toISOString().slice(0, 10).replace(/-/g, ''));
  }
  return out;
}

async function search(member) {
  const days = daysAfter(member.elected);
  const surname = member.name.replace(/"[^"]*"/g, ' ').trim().split(/\s+/).filter((w) => !/^(Jr\.?|Sr\.?|I{1,3})$/i.test(w)).slice(-1)[0];
  let scanned = 0;
  const CONC = 6;
  for (let i = 0; i < days.length; i += CONC) {
    const batch = days.slice(i, i + CONC);
    const texts = await Promise.all(batch.map((d) => journalText(journalUrl(member.chamber, d))));
    for (let k = 0; k < batch.length; k++) {
      if (!texts[k]) continue;
      scanned++;
      const hit = findOath(texts[k], member.district, surname);
      if (hit) {
        const ymd = batch[k];
        return {
          ...member,
          surname,
          oath_date: `${ymd.slice(0, 4)}-${ymd.slice(4, 6)}-${ymd.slice(6)}`,
          journal_url: journalUrl(member.chamber, ymd),
          quote: hit.quote,
          journals_scanned: scanned,
        };
      }
    }
  }
  return { ...member, surname, oath_date: null, journals_scanned: scanned, days_probed: days.length };
}

// ── controls ─────────────────────────────────────────────────────────────────

async function control() {
  let ok = true;
  const say = (pass, what) => {
    if (!pass) ok = false;
    console.log(`  ${pass ? 'PASS' : '🔴 FAIL'}  ${what}`);
  };
  const house = await journalText(journalUrl('house', '20260113'));
  const senate = await journalText(journalUrl('senate', '20260113'));
  say(!!house && !!senate, 'both journals for 2026-01-13 fetch');
  say(!!findOath(house, 21, 'Mitchell'), 'the HOUSE formula is found for HD-21 Mitchell');
  say(!!findOath(house, 50, 'Scott'), 'a name carrying an initial is found — "Keishan M. Scott"');
  say(!!findOath(senate, 12, 'Bright'), 'the SENATE formula is found for SD-12 Bright, which the House pattern misses');
  // 🔴 The failing half. A district that took no oath that day must return nothing, and a
  // surname that is not there must return nothing even when the district formula matches.
  say(!findOath(house, 1, 'Whitmire'), 'a district with no oath that day returns nothing');
  say(!findOath(house, 21, 'Nobody'), 'the district formula alone does NOT satisfy it — the surname must be in the window');
  say(daysAfter('June 3, 2025').length > 150, 'the day list spans months, not the election week');
  say(journalUrl('house', '20220517').includes('sess124_2023-2024') === false, 'an older date resolves to its own session folder');
  console.log(`  (journalUrl 2022-05-17 -> ${journalUrl('house', '20220517')})`);
  return ok;
}

// ── main ─────────────────────────────────────────────────────────────────────

if (process.argv.includes('--control')) {
  console.log('control — the search must be able to hit AND to fail:');
  process.exit((await control()) ? 0 : 1);
}

if (process.argv.includes('--extract') || !fs.existsSync(ARRIVALS)) {
  // Rebuild arrivals.json from the roster: read every member page and keep the sentence that
  // dates an arrival. Deliberately WIDER than a departure-word scan keyed on "resigned" — that
  // narrower pattern found 12 of these 18, and a seat vacated by death would have been among the
  // six it missed. The count is the tell.
  const roster = JSON.parse(fs.readFileSync(path.join(HERE, '..', 'data', 'sc-legislature-roster.json'), 'utf8'));
  const members = Object.entries(roster.chambers).flatMap(([k, c]) => c.members.map((m) => ({ ...m, chamber: k })));
  const ARRIVAL_RE =
    /((?:Special )?Election(?:ed)?[^.]{0,40}?|Elected[^.]{0,40}?)\b((?:Jan|Feb|Mar|Apr|May|June|July|Aug|Sept|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+\d{4})([^.]{0,160}?(?:unexpired term|vacancy|to fill)[^.]{0,120})/i;
  const out = [];
  const CONC = 6;
  for (let i = 0; i < members.length; i += CONC) {
    await Promise.all(
      members.slice(i, i + CONC).map(async (m) => {
        const r = await fetch(m.bio_url, { headers: UA });
        if (r.status !== 200) {
          out.push({ chamber: m.chamber, district: m.district, name: m.full_name, error: `HTTP ${r.status}` });
          return;
        }
        const t = (await r.text())
          .replace(/<script[\s\S]*?<\/script>/g, ' ')
          .replace(/<style[\s\S]*?<\/style>/g, ' ')
          .replace(/<[^>]+>/g, ' ')
          .replace(/&nbsp;/g, ' ')
          .replace(/\s+/g, ' ');
        const hit = t.match(ARRIVAL_RE);
        if (hit) out.push({ chamber: m.chamber, district: m.district, name: m.full_name, elected: hit[2].trim(), line: hit[0].trim().slice(0, 190) });
      }),
    );
    process.stdout.write(`\r  extracting arrivals: ${Math.min(i + CONC, members.length)}/${members.length}`);
  }
  process.stdout.write('\n');
  out.sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? -1 : 1));
  fs.mkdirSync(DATA, { recursive: true });
  fs.writeFileSync(ARRIVALS, JSON.stringify(out, null, 2) + '\n');
  console.log(`wrote ${ARRIVALS} — ${out.length} member(s) publish a dated arrival\n`);
}

const arrivals = JSON.parse(fs.readFileSync(ARRIVALS, 'utf8')).filter((a) => a.elected);
console.log(`${arrivals.length} member(s) publish an election date; searching each chamber's journals for the oath.\n`);
const results = [];
for (const a of arrivals) {
  const r = await search(a);
  results.push(r);
  console.log(
    r.oath_date
      ? `  ✅ ${r.chamber} ${r.district} ${r.name}: elected ${r.elected} → OATH ${r.oath_date} (${r.journals_scanned} journal days read)`
      : `  ⚠ ${r.chamber} ${r.district} ${r.name}: elected ${r.elected} → no oath found in ${r.journals_scanned} journal days — left UNDATED`,
  );
}
fs.writeFileSync(OUT, JSON.stringify(results, null, 2) + '\n');
const dated = results.filter((r) => r.oath_date).length;
console.log(`\nwrote ${OUT} — ${dated} dated, ${results.length - dated} left undated`);
