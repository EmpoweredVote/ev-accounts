#!/usr/bin/env node
/**
 * congress-sponsorship-leads.mjs — turn a member's legislative record into
 * research LEADS for the open season's topics.
 *
 * ── WHAT PROBLEM THIS SOLVES ─────────────────────────────────────────────────
 *
 * The federal research pass was stuck on "topic → bill number". You cannot ask
 * for a topic's bill and you must not guess its number — the Assault Weapons Ban
 * of 2025 is NOT S. 25 in this Congress (that is the Polluters Pay Climate Fund
 * Act), and a guessed number cites a real bill about the wrong subject.
 *
 * This inverts the question. Ask instead: what has this senator actually put
 * their name on? Pull the whole record once, then read the topics off it. The
 * cohort already carries every bioguide id, so the two halves join directly.
 *
 * 🔴 congress.gov WAS NEVER BLOCKED — THE WEBSITE IS BOT-WALLED, THE API IS OPEN.
 * The pass spent a day treating 403s from www.congress.gov as "this source is
 * unavailable". api.congress.gov answers the same questions with an api.data.gov
 * key, and the 403 from api.gsa.gov that looked identical turned out to be a
 * missing key too. A 403 is worth one attempt with a key before it is believed.
 *
 * ── LEADS, NOT EVIDENCE. THIS SCRIPT SEATS NOTHING. ──────────────────────────
 *
 * A title keyword match is the weakest thing in the evidence hierarchy: it says
 * a bill's NAME mentions a subject, not what the bill does, and certainly not
 * which of five chairs the member sits in. Everything here is a pointer for a
 * human to open and read. Two failure modes it cannot see on its own:
 *
 *   · a bill whose title matches but whose substance is orthogonal — "Protect
 *     American Values Act" tells you nothing until you read it
 *   · a member who cosponsored a bill and later withdrew, or who leads a
 *     competing bill in the other direction
 *
 * The chair still comes from reading the instrument. What changes is that the
 * researcher now starts from the member's real record instead of a search box.
 *
 * ── PAGINATION IS MANDATORY ──────────────────────────────────────────────────
 *
 * A senator can carry many hundreds of cosponsorships and the API returns them
 * newest-first in pages. Reading only the first page silently loses the older
 * ones — verified the hard way: Schiff's first page does not contain S. 1332,
 * the Raise the Wage Act, which he demonstrably cosponsors. Every page is walked
 * here, and a truncated run is reported rather than quietly returned.
 *
 * RUN: node scripts/congress-sponsorship-leads.mjs --cohort=senate
 *      node scripts/congress-sponsorship-leads.mjs --bioguide=S001150 --all-bills
 *      node scripts/congress-sponsorship-leads.mjs --cohort=senate --out=leads.csv
 *
 * Needs DATABASE_URL, and CONGRESS_API_KEY for anything but a spot check —
 * DEMO_KEY is rate-limited to a handful of requests and a 100-senator sweep is
 * hundreds. Free instant key: https://api.data.gov/signup/
 */
import 'dotenv/config';
import { writeFileSync } from 'fs';
import pg from 'pg';
import { SITTING_SENATOR_SQL } from './lib/office-tiers.mjs';
import { TOPIC_PATTERNS, matchTopics } from './lib/topic-lead-patterns.mjs';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const cohort = flag('cohort');
const bioguide = flag('bioguide');
const outFile = flag('out');
const ALL_BILLS = args.includes('--all-bills');

if (!cohort && !bioguide) {
  console.error('usage: congress-sponsorship-leads.mjs (--cohort=senate | --bioguide=XNNNNNN) [--all-bills] [--out=leads.csv]');
  process.exit(1);
}
if (!process.env.DATABASE_URL) { console.error('leads: DATABASE_URL is not set.'); process.exit(1); }

const API_KEY = process.env.CONGRESS_API_KEY || 'DEMO_KEY';
if (API_KEY === 'DEMO_KEY') {
  console.warn('⚠ CONGRESS_API_KEY is not set — falling back to DEMO_KEY, which is rate-limited to');
  console.warn('  a handful of requests per hour. Fine for one --bioguide spot check; a cohort sweep');
  console.warn('  WILL be throttled part-way through. Free key: https://api.data.gov/signup/\n');
}

// The patterns, and the decision about what a title is about, live in
// lib/topic-lead-patterns.mjs — pure, and tested without an API key or a database.

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** One API page, with a single retry on the throttle response. */
async function getPage(url) {
  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await fetch(url);
    if (res.status === 429) {
      if (attempt === 0) { console.warn('   throttled (429) — waiting 20s'); await sleep(20_000); continue; }
      throw new Error('rate limited (429) — set CONGRESS_API_KEY to a real key');
    }
    if (res.status === 403) throw new Error('403 — the api_key was rejected; check CONGRESS_API_KEY');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  }
}

/**
 * Every page of one endpoint. Returns { items, complete } — `complete` is false
 * when the walk stopped early, so a partial record is never mistaken for a full
 * one. See PAGINATION IS MANDATORY above.
 */
async function fetchAll(bioguideId, kind) {
  const items = [];
  const LIMIT = 250;
  let offset = 0;
  for (let page = 0; page < 40; page++) {
    const url = `https://api.congress.gov/v3/member/${bioguideId}/${kind}`
      + `?api_key=${encodeURIComponent(API_KEY)}&format=json&limit=${LIMIT}&offset=${offset}`;
    const json = await getPage(url);
    const batch = json[kind === 'sponsored-legislation' ? 'sponsoredLegislation' : 'cosponsoredLegislation'] ?? [];
    items.push(...batch);
    if (batch.length < LIMIT) return { items, complete: true };
    offset += LIMIT;
    await sleep(250);
  }
  return { items, complete: false };
}

function billLabel(it) {
  const n = it.number ?? it.amendmentNumber;
  return `${it.type ?? '?'}. ${n ?? '?'}`;
}

try {
  let people;
  if (bioguide) {
    const { rows } = await pool.query(
      'SELECT id, full_name, bioguide_id FROM essentials.politicians WHERE bioguide_id = $1', [bioguide]);
    if (!rows.length) { console.error(`leads: no politician with bioguide_id ${bioguide}`); process.exit(1); }
    people = rows;
  } else if (cohort === 'senate') {
    const { rows } = await pool.query(`
      SELECT DISTINCT p.id, p.full_name, p.bioguide_id
        FROM essentials.politicians p
        LEFT JOIN essentials.office_current_holder h ON h.politician_id = p.id
        LEFT JOIN essentials.offices  o ON o.id = COALESCE(p.office_id, h.office_id)
        LEFT JOIN essentials.districts d ON d.id = o.district_id
       WHERE p.is_active AND NOT COALESCE(p.is_vacant, false)
         AND ${SITTING_SENATOR_SQL}
         AND p.bioguide_id IS NOT NULL
       ORDER BY p.full_name`);
    people = rows;
  } else {
    console.error(`leads: --cohort must be "senate" (got "${cohort}")`);
    process.exit(1);
  }

  console.log(`${people.length} member(s); matching titles against ${Object.keys(TOPIC_PATTERNS).length} topics\n`);

  const leads = [];
  let incomplete = 0;

  for (const p of people) {
    let sponsored, cosponsored;
    try {
      sponsored = await fetchAll(p.bioguide_id, 'sponsored-legislation');
      cosponsored = await fetchAll(p.bioguide_id, 'cosponsored-legislation');
    } catch (e) {
      console.error(`  ${p.full_name}: ${e.message}`);
      break;
    }
    if (!sponsored.complete || !cosponsored.complete) incomplete++;

    const tagged = [
      ...sponsored.items.map((i) => ({ ...i, role: 'sponsor' })),
      ...cosponsored.items.map((i) => ({ ...i, role: 'cosponsor' })),
    ];

    const hits = [];
    for (const it of tagged) {
      const title = it.title ?? '';
      for (const topic of matchTopics(title)) {
        hits.push({ topic, role: it.role, bill: billLabel(it), title, date: it.introducedDate ?? '' });
        leads.push({
          politician_id: p.id, full_name: p.full_name, bioguide_id: p.bioguide_id,
          topic_key: topic, role: it.role, bill: billLabel(it),
          introduced: it.introducedDate ?? '', title,
        });
      }
    }

    const byTopic = new Set(hits.map((h) => h.topic));
    console.log(`${p.full_name.padEnd(26)} ${String(tagged.length).padStart(4)} bills → `
      + `${String(hits.length).padStart(3)} leads across ${byTopic.size}/9 topics`);
    if (ALL_BILLS) {
      for (const h of hits.sort((a, b) => a.topic.localeCompare(b.topic))) {
        console.log(`    ${h.topic.padEnd(22)} ${h.role.padEnd(9)} ${h.bill.padEnd(10)} ${h.date}  ${h.title.slice(0, 80)}`);
      }
    }
  }

  console.log(`\n${leads.length} lead(s) for ${people.length} member(s).`);
  if (incomplete) {
    console.warn(`⚠ ${incomplete} member(s) hit the page ceiling — their records are INCOMPLETE and a`);
    console.warn('  missing lead here is indistinguishable from a member who never touched the topic.');
  }
  console.log('\n🔴 These are LEADS, not evidence. A title match is not a chair — open the bill,');
  console.log('   read what it does, and seat the chair from the instrument.');

  if (outFile) {
    const esc = (s) => (/[",\n]/.test(s) ? `"${String(s).replace(/"/g, '""')}"` : s);
    const csv = ['politician_id,full_name,bioguide_id,topic_key,role,bill,introduced,title'];
    for (const l of leads) {
      csv.push([l.politician_id, l.full_name, l.bioguide_id, l.topic_key, l.role, l.bill, l.introduced, l.title]
        .map((v) => esc(v ?? '')).join(','));
    }
    writeFileSync(outFile, `${csv.join('\n')}\n`, 'utf8');
    console.log(`\nwrote ${outFile}`);
  }
} finally {
  await pool.end();
}
