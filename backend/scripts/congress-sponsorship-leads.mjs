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
import { writeFileSync, appendFileSync, readFileSync, existsSync } from 'fs';
import pg from 'pg';
import { SITTING_SENATOR_SQL } from './lib/office-tiers.mjs';
import { TOPIC_PATTERNS, matchTopics } from './lib/topic-lead-patterns.mjs';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const cohort = flag('cohort');
const bioguide = flag('bioguide');
const outFile = flag('out');
const ALL_BILLS = args.includes('--all-bills');
const RESUME = args.includes('--resume');

/**
 * Only bills introduced in or after this year become leads. Default 2023 — the
 * 118th and 119th Congresses.
 *
 * 🔴 WITHOUT THIS THE OUTPUT IS UNUSABLE, AND NOT BY A LITTLE. A member's record
 * runs their whole career: Schiff alone returns 234 leads reaching back to 2003,
 * so a 100-senator sweep is roughly twenty thousand rows, most of them House-era
 * matches from Congresses that no longer describe anybody's current position.
 *
 * ⚠ IT IS A DEFAULT, NOT A RULE. The methodology says recent actions outrank old
 * ones "unless the older action is more definitive" — a career-defining vote from
 * 2013 can still be the best evidence there is. `--since=0` returns everything;
 * the count of what was filtered is always printed, so the old rows are never
 * silently gone.
 */
const SINCE = (() => {
  const raw = flag('since');
  if (raw === null) return 2023;
  const n = Number.parseInt(raw, 10);
  if (!Number.isInteger(n) || n < 0 || n > 2999) {
    console.error(`leads: --since must be a year (or 0 for all) — got "${raw}"`);
    process.exit(1);
  }
  return n;
})();

if (!cohort && !bioguide) {
  console.error('usage: congress-sponsorship-leads.mjs (--cohort=senate | --bioguide=XNNNNNN)\n'
    + '         [--since=YYYY|0] [--all-bills] [--out=leads.csv] [--resume]');
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

    // ── Stop once the record is older than we asked for ──────────────────────
    //
    // The endpoint returns newest-first, so once a WHOLE page falls before
    // --since, every remaining page does too and fetching them is pure waste.
    // This is the difference between a sweep that finishes and one that does
    // not: Markey carries 11,680 bills (47 pages per endpoint) and only the
    // first handful are in scope, and it was members like him — not rate
    // limits, which never fired — that stalled the cohort run at 31 of 100.
    //
    // ⚠ THE TEST IS A WHOLE PAGE, NOT THE FIRST OLD ITEM, on purpose. Stopping
    //    at the first pre-cutoff date would trust the ordering to be perfect;
    //    requiring every item on a 250-row page to be old tolerates local
    //    disorder while still cutting the tail. With --since=0 nothing is
    //    skipped and the walk is exhaustive, exactly as before.
    if (SINCE) {
      const newest = batch
        .map((it) => Number.parseInt((it.introducedDate ?? '').slice(0, 4), 10))
        .filter(Number.isInteger);
      if (newest.length === batch.length && Math.max(...newest) < SINCE) {
        return { items, complete: true };
      }
    }

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

  // ── Resume, and write as we go ──────────────────────────────────────────────
  //
  // 🔴 A COHORT SWEEP IS LONG ENOUGH THAT IT WILL BE INTERRUPTED, AND THE FIRST
  //    ONE WAS. Buffering every lead in memory and writing once at the end meant
  //    a run stopped after 24 of 100 senators produced NOTHING — twenty-odd
  //    minutes of API calls discarded because the write step was never reached.
  //    The record is large (Schumer alone returns 10,568 bills, Grassley 10,082),
  //    so this is the normal case, not bad luck.
  //
  //    Each member's leads are now appended the moment that member is done, and
  //    --resume skips anyone already in the file. An interrupted sweep costs the
  //    member in flight, never the ones already paid for.
  const doneIds = new Set();
  if (outFile && RESUME && existsSync(outFile)) {
    for (const line of readFileSync(outFile, 'utf8').split('\n').slice(1)) {
      const id = line.split(',')[0];
      if (id) doneIds.add(id);
    }
    const before = people.length;
    people = people.filter((p) => !doneIds.has(p.id));
    console.log(`resuming: ${doneIds.size} member(s) already recorded in ${outFile}; `
      + `${before - people.length} skipped, ${people.length} to go\n`);
  }

  const CSV_HEADER = 'politician_id,full_name,bioguide_id,topic_key,role,bill,introduced,title';
  const esc = (s) => (/[",\n]/.test(String(s)) ? `"${String(s).replace(/"/g, '""')}"` : String(s));
  if (outFile && !(RESUME && existsSync(outFile))) writeFileSync(outFile, `${CSV_HEADER}\n`, 'utf8');

  console.log(`${people.length} member(s); matching titles against ${Object.keys(TOPIC_PATTERNS).length} topics\n`);

  let leadCount = 0;
  let incomplete = 0;
  let filtered = 0;
  let undated = 0;

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
      // Year off introducedDate.
      //
      // 🔴 AN UNDATED ITEM IS DROPPED WHEN --since IS SET, AND IT USED TO BE KEPT.
      // The old comment here reasoned that dropping it "would hide a lead for a
      // reason that has nothing to do with its age". The 2026-09-05 Senate sweep
      // falsified that: ALL 17 undated leads it produced are old, and provably so
      // without needing the date at all. Every one is an HR/HJRES/HCONRES/HRES —
      // a HOUSE measure — carried by one of the two members with a long House
      // career, and a House bill cannot postdate the House service that produced
      // it. Grassley left the House in 1981, Markey in 2013.
      //
      // What the missing date actually marks is the Congress API's thin coverage
      // of pre-1990 records, which is to say age is EXACTLY the reason. Three of
      // the 17 are 1980s resolutions imploring the USSR to let named refuseniks
      // emigrate to Israel; the pattern files them under israel-military-aid, and
      // a researcher opening that lead learns nothing about a 2026 senator's view
      // on military aid.
      //
      // ⚠ THEY ARE COUNTED AND PRINTED SEPARATELY, never silently discarded. The
      // concern in the old comment was real — a lead lost for a bookkeeping reason
      // must not vanish quietly — so the answer is visibility, not retention.
      // --since=0 keeps them, as it keeps everything.
      const year = Number.parseInt((it.introducedDate ?? '').slice(0, 4), 10);
      if (SINCE && !Number.isInteger(year)) { undated++; continue; }
      if (SINCE && year < SINCE) { filtered++; continue; }
      for (const topic of matchTopics(title)) {
        // ⚠ `date` IS THE MEMBER'S OWN ACTION DATE, NOT ALWAYS THE BILL'S. For a sponsor
        // or an ORIGINAL cosponsor the two coincide, so the column reads like a bill
        // date and was long assumed to be one. For a member who signs on later it is
        // the day THEY joined: S. 1531 was introduced 2025-04-30 with 41 signatures,
        // and the sweep carries it at 2025-07-23 for Schatz and 2025-05-05 for Ossoff.
        //
        // This is the right semantic for --since, which asks what a member has done
        // lately rather than which bills are recent. It is a trap for anything that
        // joins a lead to the bill's own text: govinfo's "Introduced in Senate" print
        // names only the signatures the bill had ON INTRODUCTION, so a later cosponsor
        // is genuinely absent from it and a surname check against it will — correctly —
        // refuse to confirm them.
        hits.push({ topic, role: it.role, bill: billLabel(it), title, date: it.introducedDate ?? '' });
      }
    }
    leadCount += hits.length;

    // Appended per member, not buffered to the end — see the note above.
    if (outFile) {
      const rows = hits.map((h) => [p.id, p.full_name, p.bioguide_id, h.topic, h.role, h.bill, h.date, h.title]
        .map(esc).join(','));
      // A member with zero hits still needs a mark, or --resume re-does them
      // every run. The sentinel row carries no topic and is trivially filtered.
      if (!rows.length) rows.push([p.id, p.full_name, p.bioguide_id, '', '', '', '', ''].map(esc).join(','));
      appendFileSync(outFile, `${rows.join('\n')}\n`, 'utf8');
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

  console.log(`\n${leadCount} lead(s) for ${people.length} member(s) this run.`);
  if (SINCE) {
    console.log(`${filtered} bill(s) skipped as introduced before ${SINCE} — --since=0 keeps them.`);
    if (undated) {
      console.log(`${undated} bill(s) skipped as UNDATED — the API carries no introducedDate for them.`);
      console.log('  These are pre-1990 House records in every case seen so far, not modern bills.');
    }
  }
  if (incomplete) {
    console.warn(`⚠ ${incomplete} member(s) hit the page ceiling — their records are INCOMPLETE and a`);
    console.warn('  missing lead here is indistinguishable from a member who never touched the topic.');
  }
  console.log('\n🔴 These are LEADS, not evidence. A title match is not a chair — open the bill,');
  console.log('   read what it does, and seat the chair from the instrument.');

  if (outFile) console.log(`\nappended to ${outFile} (--resume continues where this stopped)`);
} finally {
  await pool.end();
}
