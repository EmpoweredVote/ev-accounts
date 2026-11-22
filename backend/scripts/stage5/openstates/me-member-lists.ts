/**
 * me-member-lists — write src/lib/maineLegislatureMembers.ts: the full names of each Maine Legislature's senators, and
 * each Legislature's House roster, which the Maine roll-call reader (stateRollCallEvidence.ts) uses to name the members
 * a roll-call PDF prints by surname only.
 *
 *   npx tsx scripts/stage5/openstates/me-member-lists.ts --extract <Open States extract dir, me> --cache <dir>
 *
 * Senate (128th to 132nd): the Senate's own member page on legislature.maine.gov (an allowed path; robots.txt disallows
 * /LawMakerWeb only). The live page shows the current Legislature alone, so each earlier Legislature is read from the
 * Internet Archive's copy of the same page, taken while that Legislature sat: two copies a Legislature, one early and one
 * late, so a senator seated in mid-term is listed too. Each copy must name the Legislature it is filed under, and list 30
 * to 35 senators with no name twice.
 *
 * House (128th to 130th, whose PDFs print surnames only): our Open States extract's House memberships, each with its
 * dates, kept for every person whose membership overlaps the Legislature. Open States holds some members twice ("Will
 * Tuell" and "William R. Tuell"): two people of one family name whose given names agree (the same first given name, a
 * nickname of it, or its initial) are kept as one member. The reader names a printed surname from the members seated on
 * the vote's day, and refuses a surname two of them share.
 *
 * 1 second between requests; bodies are kept under --cache, so a second run asks for nothing it already has. Writes
 * nothing else, and nothing to the database.
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { gunzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { getNameVariants } from '../../../src/lib/legiscan/helpers.js';
import { EMPOWERED_VOTE_UA } from '../../../src/lib/verificationFetch.js';

const OUT = fileURLToPath(new URL('../../../src/lib/maineLegislatureMembers.ts', import.meta.url));
const LIVE = 'https://legislature.maine.gov/senate/senators/9536';
const wb = (ts: string, url: string): string => `https://web.archive.org/web/${ts}id_/${url}`;

/** Each Legislature's member pages: an early and a late copy, and for the 132nd the live page too. */
const SENATE_PAGES: { legislature: number; url: string; layout: 'alpha' | 'district' | 'list' }[] = [
  { legislature: 128, url: wb('20170126211749', 'http://legislature.maine.gov/senate/128th-senators/9332'), layout: 'alpha' },
  { legislature: 128, url: wb('20181004072646', 'http://legislature.maine.gov/senate/128th-senators/9332'), layout: 'alpha' },
  { legislature: 129, url: wb('20190420084930', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'district' },
  { legislature: 129, url: wb('20200430223609', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'district' },
  { legislature: 130, url: wb('20210606160112', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'list' },
  { legislature: 130, url: wb('20220811202725', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'list' },
  { legislature: 131, url: wb('20230527173533', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'list' },
  { legislature: 131, url: wb('20240315075855', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'list' },
  { legislature: 132, url: wb('20250715170506', 'http://legislature.maine.gov/senate/senators/9536'), layout: 'list' },
  { legislature: 132, url: LIVE, layout: 'list' },
];
/** Each Legislature's span, from the day it convened to the day the next one did. */
const HOUSE_LEGISLATURES: Record<number, [string, string]> = {
  128: ['2016-12-07', '2018-12-04'],
  129: ['2018-12-05', '2020-12-01'],
  130: ['2020-12-02', '2022-12-06'],
};

const ent = (s: string): string => s.replace(/&nbsp;?/g, ' ').replace(/&amp;/g, '&').replace(/&#39;|&rsquo;/g, "'").replace(/&quot;/g, '"')
  .replace(/&#(\d+);/g, (_m, n: string) => String.fromCodePoint(Number(n)));
const squash = (s: string): string => s.replace(/\s+/g, ' ').trim();
const fold = (s: string): string => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/['’.]/g, '').replace(/[^a-z -]/g, ' ').replace(/\s+/g, ' ').trim();
/** A name with any generational suffix dropped ("James J. Campbell, Sr." -> "James J. Campbell"). */
const bare = (s: string): string => squash(s.replace(/,?\s+(?:Jr|Sr|II|III|IV)\.?$/i, ''));
const ordinal = (n: number): string => `${n}${n % 100 >= 11 && n % 100 <= 13 ? 'th' : ['th', 'st', 'nd', 'rd'][n % 10] ?? 'th'}`;

let last = 0;
async function get(url: string, cache: string): Promise<string> {
  const file = path.join(cache, createHash('sha1').update(url).digest('hex').slice(0, 24));
  if (existsSync(file)) return readFileSync(file, 'utf8');
  const wait = last + 1_000 - Date.now();
  if (wait > 0) await new Promise((r) => setTimeout(r, wait));
  last = Date.now();
  const res = await fetch(url, { headers: { 'User-Agent': EMPOWERED_VOTE_UA, 'Accept-Encoding': 'identity' } });
  if (res.status !== 200) throw new Error(`${url}: HTTP ${res.status}`);
  let bytes = Buffer.from(await res.arrayBuffer());
  // the Archive hands an original that was stored gzipped back as it was stored
  if (bytes[0] === 0x1f && bytes[1] === 0x8b) bytes = gunzipSync(bytes);
  const body = bytes.toString('utf8');
  if (!/<html/i.test(body)) throw new Error(`${url}: not an HTML page`);
  writeFileSync(file, body);
  return body;
}

/** One page's senators, in full ("Shenna Bellows"). Throws when the page does not name its Legislature, or lists too few or too many. */
export function senatePage(html: string, legislature: number, layout: 'alpha' | 'district' | 'list'): string[] {
  const nth = ordinal(legislature);
  let names: string[];
  if (layout === 'alpha') {
    // "128th Senators" heading; each senator as "Bellows, Shenna", linked to /128th-senators/senator-... (the President: president-...)
    if (!new RegExp(`<title>\\s*${nth} Senators \\|`).test(html)) throw new Error(`not the ${nth} Senators page`);
    names = [...html.matchAll(new RegExp(`<a href="/${nth}-senators/(?:senator|president)-[a-z-]+">\\s*([^<,]+),\\s*([^<]+?)\\s*</a>`, 'g'))]
      .map((m) => squash(`${ent(m[2])} ${ent(m[1])}`));
  } else if (layout === 'district') {
    // "All members of the 129th Maine Senate"; "District 19 - State Senator James Hamper (R - Oxford)"
    if (!new RegExp(`All members of the ${nth} Maine Senate`).test(ent(html))) throw new Error(`not the ${nth} Senate's member page`);
    names = [...ent(html).matchAll(/District (\d+) - State Senator ([^<(]+?)\s*\(/g)].map((m) => squash(m[2]));
  } else {
    // "<strong>130th Maine Senators</strong>", then each senator as a link in a paragraph, down to the end of the content
    const head = new RegExp(`<strong>\\s*${nth} Maine Senators\\s*</strong>`).exec(html);
    if (!head) throw new Error(`not the ${nth} Maine Senators list`);
    const rest = html.slice(head.index + head[0].length).split(/<!-- end content -->|<\/div>/)[0];
    names = [...rest.matchAll(/<p>\s*<a href="[^"]+">([^<]+)<\/a>/g)].map((m) => squash(ent(m[1])));
  }
  names = [...new Set(names)];
  if (names.length < 30 || names.length > 35) throw new Error(`the ${nth} page lists ${names.length} senators`);
  if (new Set(names.map(fold)).size !== names.length) throw new Error(`the ${nth} page lists a name twice`);
  return names;
}

/** Two names of one person: the same family name and the same first given name, a nickname of it, or its initial. */
function samePerson(a: string, b: string): boolean {
  const wa = fold(bare(a)).split(' ');
  const wb2 = fold(bare(b)).split(' ');
  if (wa[wa.length - 1] !== wb2[wb2.length - 1]) return false;
  const ga = wa[0];
  const gb = wb2[0];
  if (ga === gb) return true;
  if ((ga.length === 1 && gb.startsWith(ga)) || (gb.length === 1 && ga.startsWith(gb))) return true;
  // a short form that begins the other once a doubled last letter is dropped ("Gregg" and "Gregory"), of three letters or more
  const [short, long] = ga.length <= gb.length ? [ga, gb] : [gb, ga];
  const stem = short.replace(/(.)\1$/, '$1');
  if (stem.length >= 3 && long.startsWith(stem)) return true;
  return getNameVariants(ga).includes(gb) || getNameVariants(gb).includes(ga);
}

/** Copies of one Legislature's list union into one: a senator seated in mid-term is listed; one person under two names once (the longer). */
function unionNames(lists: string[][]): string[] {
  const out: string[] = [];
  for (const n of lists.flat()) {
    const k = out.findIndex((o) => samePerson(o, n));
    if (k < 0) out.push(n); else if (n.length > out[k].length) out[k] = n;
  }
  return out.sort((a, b) => a.localeCompare(b));
}

interface Member { name: string; family: string; also: string[]; from: string | null; to: string | null }

function tsv(file: string): Record<string, string>[] {
  const [head, ...lines] = readFileSync(file, 'utf8').split('\n').filter(Boolean);
  const cols = head.split('\t');
  return lines.map((l) => Object.fromEntries(l.split('\t').map((v, i) => [cols[i], v === '\\N' ? '' : v])));
}

/** Each Legislature's House members from the extract's memberships, one person kept once. */
export function houseRosters(extract: string): Record<number, Member[]> {
  const lower = new Set(tsv(path.join(extract, 'organization.tsv')).filter((o) => o.classification === 'lower').map((o) => o.id));
  if (lower.size !== 1) throw new Error(`the extract holds ${lower.size} House organizations`);
  const person = new Map(tsv(path.join(extract, 'person.tsv')).map((p) => [p.id, p]));
  const ms = tsv(path.join(extract, 'membership.tsv')).filter((m) => lower.has(m.organization_id) && person.has(m.person_id));
  const out: Record<number, Member[]> = {};
  for (const [leg, [a, b]] of Object.entries(HOUSE_LEGISLATURES)) {
    const members: Member[] = [];
    for (const m of ms.filter((x) => (!x.start_date || x.start_date <= b) && (!x.end_date || x.end_date >= a))) {
      const p = person.get(m.person_id)!;
      const name = squash(p.name);
      const family = squash(p.family_name || name.split(' ').slice(-1)[0]);
      if (!fold(bare(name)).endsWith(fold(family))) throw new Error(`${name}: the family name ${family} is not the end of the name`);
      const from = m.start_date || null;
      const to = m.end_date || null;
      const k = members.findIndex((x) => fold(x.family) === fold(family) && (x.name === name || x.also.includes(name) || samePerson(x.name, name)));
      if (k < 0) { members.push({ name, family, also: [], from, to }); continue; }
      const x = members[k];
      if (name !== x.name && !x.also.includes(name)) {
        if (name.length > x.name.length) { x.also.push(x.name); x.name = name; } else x.also.push(name);
      }
      x.from = x.from === null || from === null ? null : (from < x.from ? from : x.from);
      x.to = x.to === null || to === null ? null : (to > x.to ? to : x.to);
    }
    out[Number(leg)] = members.sort((p, q) => p.family.localeCompare(q.family) || p.name.localeCompare(q.name));
  }
  return out;
}

async function main(): Promise<void> {
  const arg = (k: string): string => {
    const i = process.argv.indexOf(k);
    if (i < 0 || !process.argv[i + 1]) throw new Error(`usage: me-member-lists.ts --extract <dir> --cache <dir> (missing ${k})`);
    return process.argv[i + 1];
  };
  const extract = arg('--extract');
  const cache = arg('--cache');
  mkdirSync(cache, { recursive: true });
  const senate: Record<number, { sources: string[]; names: string[] }> = {};
  const byLeg = new Map<number, { sources: string[]; lists: string[][] }>();
  for (const p of SENATE_PAGES) {
    const names = senatePage(await get(p.url, cache), p.legislature, p.layout);
    const e = byLeg.get(p.legislature) ?? { sources: [], lists: [] };
    e.sources.push(p.url);
    e.lists.push(names);
    byLeg.set(p.legislature, e);
    console.log(`Senate ${ordinal(p.legislature)}: ${names.length} senators  ${p.url}`);
  }
  for (const [leg, e] of byLeg) {
    senate[leg] = { sources: e.sources, names: unionNames(e.lists) };
    console.log(`Senate ${ordinal(leg)}: ${senate[leg].names.length} senators kept from ${e.sources.length} copies`);
  }
  const house = houseRosters(extract);
  const meta = JSON.parse(readFileSync(path.join(extract, 'extract.json'), 'utf8')) as { dump?: string };
  for (const [leg, ms] of Object.entries(house)) {
    const merged = ms.filter((m) => m.also.length).length;
    console.log(`House ${ordinal(Number(leg))}: ${ms.length} members (${merged} held twice by Open States, kept once)`);
  }
  const lines = [
    '// GENERATED by scripts/stage5/openstates/me-member-lists.ts — do not edit by hand; run it again.',
    '//',
    '// The Maine roll-call reader (stateRollCallEvidence.ts) names a member its PDF prints by surname only from these lists.',
    '// Senate: each Legislature\'s senators in full, from the Senate\'s own member page (legislature.maine.gov/senate/senators/9536,',
    '// and for the 128th /senate/128th-senators/9332), read live for the current Legislature and from the Internet Archive\'s',
    '// copies of the same page for earlier ones; each copy names the Legislature it is filed under.',
    `// House (128th to 130th): our Open States extract's House memberships (dump ${meta.dump ?? 'unknown'}), each with its dates`,
    '// (null: not given); one person Open States holds twice is kept once, with the other name under also.',
    '',
    'export interface MeSenateList { sources: string[]; names: string[] }',
    'export interface MeHouseMember { name: string; family: string; also: string[]; from: string | null; to: string | null }',
    '',
    `export const ME_SENATE_LISTS: Record<number, MeSenateList> = ${JSON.stringify(senate, null, 2)};`,
    '',
    `export const ME_HOUSE_ROSTERS: Record<number, MeHouseMember[]> = ${JSON.stringify(house, null, 2)};`,
    '',
  ];
  writeFileSync(OUT, lines.join('\n'));
  console.log(`-> ${OUT}`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((e) => { console.error(e instanceof Error ? e.message : e); process.exit(1); });
}
