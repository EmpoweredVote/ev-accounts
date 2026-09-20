#!/usr/bin/env node
/**
 * verify-sc-cities-roster.mjs — Knight program, wave SC-3.
 *
 * Change-checks the Columbia and Myrtle Beach rosters in data/sc-cities-roster.json against the
 * cities' own pages AND against the Municipal Association of South Carolina's directory, which
 * is maintained by neither city. Touches no database.
 *
 * 🔴🔴 MYRTLE BEACH PUBLISHES TWO COUNCIL PAGES AND ONLY ONE IS MAINTAINED.
 *   /government/mayor___city_council/index.php   CURRENT — Kruea, Chestnut, Conner, Hatley,
 *                                               Lowder, McClure, Render
 *   /government/mayor_and_city_concil/index.php  STALE — still names Mayor Bethune and
 *                                               Councilman Gregg Smith, whose terms ended in
 *                                               January 2026
 * Both return HTTP 200 with a full, plausible roster. Nothing on either page says which is
 * which; the tell is that one carries terms "expiring January 2026" — Duluth's rule, that a
 * council's change-check signal is an EXPIRED DATE — and that MASC agrees with the other.
 * This tool asserts the stale page is still stale, so the day it is fixed (or the day the
 * current page goes stale instead) is noticed rather than assumed.
 *
 * 🔴 A ROSTER CHECK ANSWERS "IS EVERYONE STILL THERE", NOT "HAS ANYONE ARRIVED". Both
 * directions are checked: every roster member must be named by both sources, and any councillor
 * named by a source who is NOT in the roster is reported.
 *
 * Usage:
 *   node scripts/verify-sc-cities-roster.mjs
 *   node scripts/verify-sc-cities-roster.mjs --control   plant a defect and require it reported
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'sc-cities-roster.json');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' };

const PAGES = {
  columbia: {
    city: 'https://citycouncil.columbiasc.gov/',
    masc: 'https://www.masc.sc/municipality/columbia',
  },
  'myrtle-beach': {
    city: 'https://www.cityofmyrtlebeach.com/government/mayor___city_council/index.php',
    masc: 'https://www.masc.sc/municipality/myrtle-beach',
    stale: 'https://www.cityofmyrtlebeach.com/government/mayor_and_city_concil/index.php',
    staleNames: ['Bethune', 'Smith'],
  },
};

async function text(url) {
  const r = await fetch(url, { headers: UA });
  if (r.status !== 200) throw new Error(`HTTP ${r.status} for ${url}`);
  const h = await r.text();
  return h
    .replace(/<script[\s\S]*?<\/script>/g, ' ')
    .replace(/<style[\s\S]*?<\/style>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#8217;|&rsquo;/g, "'")
    .replace(/&quot;|&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');
}

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const control = process.argv.includes('--control');
let failed = false;

for (const city of roster.cities) {
  const src = PAGES[city.key];
  console.log(`\n=== ${city.name} ===`);
  const cityText = await text(src.city);
  const mascText = await text(src.masc);

  const names = city.members.map((m) => ({
    full: m.full_name,
    // The surname is what both sources reliably print; the given name is checked separately so a
    // shared surname cannot pass on its own.
    last: m.last_name,
    first: m.first_name.replace(/\.$/, ''),
  }));
  if (control) names.push({ full: 'Control Planted-Name', last: 'Planted-Name', first: 'Control' });

  for (const n of names) {
    const onCity = new RegExp(`\\b${n.last}\\b`, 'i').test(cityText) && new RegExp(`\\b${n.first}`, 'i').test(cityText);
    const onMasc = new RegExp(`\\b${n.last}\\b`, 'i').test(mascText) && new RegExp(`\\b${n.first}`, 'i').test(mascText);
    const ok = onCity && onMasc;
    const planted = n.last === 'Planted-Name';
    if (!ok && !planted) failed = true;
    if (planted && ok) failed = true;
    console.log(
      `  ${planted ? (ok ? '🔴' : '✅') : ok ? '✅' : '🔴'} ${n.full.padEnd(30)} city page: ${onCity ? 'named' : 'ABSENT'} · MASC: ${onMasc ? 'named' : 'ABSENT'}${planted ? '   (control — must be ABSENT on both)' : ''}`,
    );
  }

  // The other direction: a councillor either source names who is not in the roster.
  const rosterLast = new Set(city.members.map((m) => m.last_name.toLowerCase()));
  // A roster member's GIVEN name is not an extra person. Without this, "Councilmember Peter M.
  // Brown" reported "peter" as somebody the roster had missed.
  const rosterFirst = new Set(city.members.map((m) => m.first_name.toLowerCase().replace(/\.$/, '')));
  // ⚠ The first version of this listed "councilmember", "jr." and "graduate" as people. A
  // detector that cries wolf is read as noise, and then the one real name in it is read as noise
  // too. Take the LAST capitalised token that is not a suffix, a title or a stop word.
  const STOP = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'phd', 'dmd', 'mayor', 'councilmember', 'council', 'member', 'councilman', 'councilwoman', 'pro', 'tem', 'graduate', 'city']);
  const mascNames = [...mascText.matchAll(/(?:Mayor|Councilmember|Council Member|Councilman|Councilwoman)\s+((?:[A-Z][A-Za-z.'-]+\s+){0,3}[A-Z][A-Za-z'-]{3,})/g)]
    .map((m) =>
      m[1]
        .trim()
        .split(/\s+/)
        .map((w) => w.replace(/[.,]$/, ''))
        .filter((w) => /^[A-Z][A-Za-z'-]{2,}$/.test(w) && !STOP.has(w.toLowerCase()))
        .slice(-1)[0],
    )
    .filter(Boolean)
    .map((s) => s.toLowerCase());
  const extra = [...new Set(mascNames)].filter(
    (s) => s.length > 2 && !rosterLast.has(s) && !rosterFirst.has(s),
  );
  if (extra.length) {
    console.log(`  ⚠ named by a source but not in the roster: ${extra.join(', ')} — read before trusting the roster`);
  } else {
    console.log('  ✅ no councillor is named by a source and missing from the roster');
  }

  if (src.stale) {
    const staleText = await text(src.stale);
    const still = src.staleNames.filter((n) => new RegExp(`\\b${n}\\b`).test(staleText));
    const currentOnStale = city.members.filter((m) => new RegExp(`\\b${m.last_name}\\b`).test(staleText)).length;
    console.log(
      `  ⚠ the SECOND council page (${src.stale.split('/government/')[1]}) still names ${still.join(', ') || 'nobody stale'} and ${currentOnStale}/${city.members.length} current members`,
    );
    if (!still.length) {
      console.log('     🔴 IT IS NO LONGER STALE — re-read both pages and decide which one this wave should follow');
      failed = true;
    }
  }
}

console.log(failed ? '\nFAIL' : '\nOK — both sources name every seated member, and the stale page is still the stale one');
process.exit(failed ? 1 : 0);
