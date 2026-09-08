#!/usr/bin/env node
/**
 * miamidade-voting-record.mjs — how each commissioner VOTED, per matter.
 *
 * The companion to miamidade-sponsorship-leads.mjs, and it exists because that
 * one hit a wall. Read its header first for the shared context: the dead Legistar
 * instance, the U+FFFD corruption, and why the county's own Legislative
 * Information Center is the live source.
 *
 * ── WHY SPONSORSHIP WAS NOT ENOUGH ───────────────────────────────────────────
 *
 * A sponsorship report finds what a commissioner INITIATES. Miami-Dade's biggest
 * land-use decisions are not initiated by commissioners at all — they are
 * APPLICATIONS filed by landowners to amend the Comprehensive Development Master
 * Plan or move the Urban Development Boundary, which the Board then hears and
 * votes on. Nobody sponsors them.
 *
 * That is not hypothetical. Cohen Higgins' growth-and-development row was refused
 * on 2026-09-07 because her sponsorship record established direction without
 * pinning a rung, and the discriminator — how she votes on CDMP applications —
 * was not in the data. Her voting record on that one body holds 106 matters.
 *
 * ── 🔴 THE OFFICE-HOLDER CODES ARE NOT THE SAME AS THE SPONSOR REPORT'S ──────
 *
 * Sponsor.asp wants `B775`. Votingrecord.asp wants `775`. Same person, same
 * numeric core, different format, and the wrong one returns a clean empty report
 * rather than an error. The codes are always resolved from THIS report's own
 * form, never carried over.
 *
 * ── 🔴🔴 "ADOPTED" DOES NOT MEAN THE DEVELOPMENT WAS APPROVED ────────────────
 *
 * A CDMP application is disposed of by an ordinance "PROVIDING DISPOSITION OF
 * APPLICATION NO. CDMP20230018". The disposition can be a DENIAL. So a row
 * reading `Adopted` with `VOTED: Yes` may be a vote to REFUSE the development —
 * the opposite of what the row looks like. **A vote's direction on a land-use
 * application cannot be read from the action and the vote alone; the ordinance's
 * disposition has to be read.** This is the same defect class as citing a bill by
 * its title: the instrument's shape decides what the vote means, not its label.
 *
 * `direction_is_unread: true` is set on every land-use disposition row for
 * exactly this reason. Do not seat a chair off one without reading the ordinance.
 *
 * ── BODY FILTER: THE MOST USEFUL KNOB HERE ───────────────────────────────────
 *
 * `BodyType` narrows to the committee that heard the matter, which is a far
 * better topic proxy than any keyword:
 *
 *   CDMZ  BCC - Comprehensive Development Master Plan & Zoning   <- growth, zoning
 *   HOUS  Housing Committee                                      <- housing, rent
 *   TRNS  Transportation Cmte                                    <- transportation
 *   IEIC  Intergovernmental and Economic Impact Committee         <- economic dev
 *   RTRC  Recreation, Tourism, and Resiliency                     <- local environment
 *   SHC   Safety and Health Committee                             <- public safety
 *   CC    Board of County Commissioners (the full board)
 *
 * RUN: node scripts/miamidade-voting-record.mjs --body=CDMZ --since=2025-01-01
 *      node scripts/miamidade-voting-record.mjs --body=CDMZ --name="Danielle Cohen Higgins"
 *      node scripts/miamidade-voting-record.mjs --body=HOUS --since=2024-01-01 --resume
 *
 * Needs DATABASE_URL. No API key.
 */
import 'dotenv/config';
import { writeFileSync, appendFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import pg from 'pg';
import { normalizeName, resolveCodes } from './miamidade-sponsorship-leads.mjs';
import { matchLocalTopics } from './lib/topic-lead-patterns.mjs';

const BASE = 'https://www.miamidade.gov/govaction';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
const MIAMI_DADE_GOVERNMENT_ID = 'd31ea899-f015-4456-8370-b727e3bef271';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const since = flag('since') ?? '2025-01-01';
const until = flag('until') ?? new Date().toISOString().slice(0, 10);
const body = flag('body') ?? 'AllBodies';
const onlyName = flag('name');
const outFile = flag('out') ?? `data/stance-research/miamidade-votes-${(flag('body') ?? 'all').toLowerCase()}.jsonl`;
const RESUME = args.includes('--resume');

const usDate = (iso) => { const [y, m, d] = iso.split('-'); return `${m}/${d}/${y}`; };

/**
 * Action phrases this report actually prints, longest first.
 *
 * Longest-first matters: "Adopted as amended" must win over "Adopted", and
 * "Approved with conditions" over "Approved". Anything unrecognised is left as
 * null with the raw text kept — a mis-split action would misreport a vote.
 */
const ACTIONS = [
  'Adopted as amended', 'Approved with conditions', 'Approved as amended',
  'Forwarded to BCC with a favorable recommendation', 'Forwarded to BCC',
  'No action taken', 'Carried over', 'Substituted', 'Withdrawn', 'Deferred',
  'Rejected', 'Approved', 'Adopted', 'Denied', 'Amended', 'Failed', 'Passed', 'Tabled',
  // Added 2026-09-07 after the first real run left 120 of 318 actions unlabelled.
  // The list was written from the sponsor report's vocabulary and this report
  // uses its own. ⚠ 'Approved staff recommendation' alone was 102 of the 120,
  // and it is NOT a direction: the staff recommendation it approves may be a
  // denial. Two of the six are denials whose text does not end in "Denied", so
  // the endsWith matcher rightly refused to guess at them.
  'Approved staff recommendation', 'Deferred to the BCC following a public hearing',
  'Deferred following a public hearing', 'Denied without prejudice',
  'Adopted on first reading', 'Motion to deny',
].sort((a, b) => b.length - a.length);

/** Land-use dispositions, whose vote direction cannot be read off the action. */
const LAND_USE = /comprehensive development master plan|\bCDMP\b|providing disposition of application|urban development boundary|\bUDB\b|^PH NO|district boundary change/i;

async function get(url) {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
  return new TextDecoder('utf-8').decode(await r.arrayBuffer());
}

const stripTags = (s) => s
  .replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, '')
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&#8217;/g, "'")
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
  .replace(/[ \t]+/g, ' ').trim();

/**
 * Office holders offered by the VOTING RECORD form. Bare numeric codes — see the
 * header. Kept separate from the sponsorship parser rather than parameterised,
 * because the two formats are a live trap and a shared function invites reuse of
 * the wrong one.
 */
export function parseVotingOfficeHolders(html) {
  const sel = /<select[^>]*name=["']?OfficeHolders["']?[^>]*>([\s\S]*?)<\/select>/i.exec(html);
  if (!sel) throw new Error('OfficeHolders select not found — the voting-record form changed');
  return [...sel[1].matchAll(/<option[^>]*value=["']?(\d+)["']?[^>]*>([^<]*)/gi)]
    .map((m) => ({ code: m[1], name: stripTags(m[2]) }))
    .filter((o) => o.name);
}

/** Split "4/23/2026BCC - Comprehensive Development Master Plan & ZoningAdopted". */
export function splitActionLine(text) {
  const t = stripTags(text);
  const d = /^(\d{1,2}\/\d{1,2}\/\d{4})/.exec(t);
  const date = d ? d[1] : null;
  let rest = d ? t.slice(d[1].length).trim() : t;
  for (const a of ACTIONS) {
    if (rest.toLowerCase().endsWith(a.toLowerCase())) {
      return { date, body: rest.slice(0, rest.length - a.length).trim(), action: a, action_raw: rest };
    }
  }
  return { date, body: null, action: null, action_raw: rest };
}

/**
 * Every matter in one Voting Record report.
 *
 * Each entry is three rows: the matter link with subject and voting type; the
 * enacted number with the full description; then one row per recorded action
 * carrying the date, body, action and this member's vote.
 */
export function parseVotingRecord(html) {
  const chunks = html.split(/(?=<td[^>]*>\s*<b>\s*<a href="matter\.asp\?matter=\d+")/i);
  const out = [];
  for (const chunk of chunks) {
    const link = /<a href="matter\.asp\?matter=(\d+)"[^>]*>\s*([^<]+?)\s*<\/a>/i.exec(chunk);
    if (!link) continue;
    const cells = [...chunk.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((m) => stripTags(m[1]));
    const subject = cells[1] ?? '';
    const votingType = cells[2] ?? '';
    const enacted = cells[3] ?? '';
    const description = cells[4] ?? '';

    const actions = [];
    for (const m of chunk.matchAll(/VOTED:\s*([A-Za-z ]+)/gi)) {
      const before = chunk.slice(0, m.index);
      const cell = [...before.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].pop();
      const parsed = splitActionLine(cell ? cell[1] : '');
      actions.push({ ...parsed, voted: m[1].trim() });
    }

    const haystack = `${subject}\n${description}`;
    out.push({
      matter_id: link[1],
      matter_number: link[2].trim(),
      subject,
      voting_type: votingType || null,
      enacted_number: enacted || null,
      description,
      actions,
      source_url: `${BASE}/matter.asp?matter=${link[1]}`,
      // 🔴 See the header. On a land-use disposition, action + vote do not say
      // which way the development went.
      direction_is_unread: LAND_USE.test(haystack),
      text_has_lost_characters: haystack.includes('�'),
      topics: matchLocalTopics(haystack),
    });
  }
  return out;
}

async function main() {
  const { Pool } = pg;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const { rows: cohort } = await pool.query(
    `SELECT p.id::text AS politician_id, p.full_name, o.title
       FROM essentials.governments g
       JOIN essentials.chambers c   ON c.government_id = g.id
       JOIN essentials.offices o    ON o.chamber_id = c.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE g.id = $1 AND c.name = 'Board of County Commissioners'
      ORDER BY p.full_name`,
    [MIAMI_DADE_GOVERNMENT_ID],
  );
  await pool.end();

  const targets = onlyName
    ? cohort.filter((c) => normalizeName(c.full_name) === normalizeName(onlyName))
    : cohort;
  if (!targets.length) { console.error(`no cohort match for ${onlyName ?? '(all)'}`); process.exit(1); }

  const holders = parseVotingOfficeHolders(await get(`${BASE}/ReportMenu.asp?ReportName=Votingrecord.asp`));
  console.log(`voting-record form offers ${holders.length} office holders; body=${body}`);

  mkdirSync(dirname(outFile), { recursive: true });
  const done = new Set();
  if (RESUME && existsSync(outFile)) {
    for (const line of readFileSync(outFile, 'utf8').split('\n').filter(Boolean)) {
      try { done.add(JSON.parse(line).politician_id); } catch { /* partial line */ }
    }
    console.log(`resuming — ${done.size} already written`);
  } else if (!RESUME) writeFileSync(outFile, '');

  const unresolved = [];
  for (const person of targets) {
    if (done.has(person.politician_id)) continue;
    const { codes, match, candidates } = resolveCodes(person.full_name, holders);
    if (!codes.length) {
      unresolved.push(`${person.full_name} (${match}${candidates?.length ? ': ' + candidates.join(' / ') : ''})`);
      console.warn(`  ⚠ SKIP ${person.full_name} — ${match === 'ambiguous' ? 'AMBIGUOUS, refusing to guess' : 'no office-holder code'}`);
      continue;
    }
    if (match === 'fuzzy') console.warn(`  ⚠ ${person.full_name} matched FUZZILY to "${codes[0].name}" — confirm same person`);
    if (codes.length > 1) console.warn(`  ⚠ ${person.full_name} has ${codes.length} codes (${codes.map((c) => c.code).join(', ')}) — fetching all`);

    const matters = new Map();
    for (const { code } of codes) {
      const url = `${BASE}/Votingrecord.asp?begdate=${encodeURIComponent(usDate(since))}`
        + `&enddate=${encodeURIComponent(usDate(until))}&OfficeHolders=${code}`
        + `&MatterType=AllMatters&BodyType=${body}&submit1=Submit`;
      for (const m of parseVotingRecord(await get(url))) matters.set(m.matter_id, { ...m, office_holder_code: code });
    }

    const all = [...matters.values()];
    const tally = {};
    for (const m of all) for (const a of m.actions) tally[a.voted] = (tally[a.voted] ?? 0) + 1;

    appendFileSync(outFile, JSON.stringify({
      politician_id: person.politician_id,
      full_name: person.full_name,
      office_title: person.title,
      office_holder_codes: codes.map((c) => c.code),
      body, window: { since, until },
      counts: {
        matters: all.length,
        with_topic_lead: all.filter((m) => m.topics.length).length,
        direction_unread: all.filter((m) => m.direction_is_unread).length,
        votes_by_value: tally,
      },
      votes: all,
    }) + '\n');

    const t = Object.entries(tally).map(([k, v]) => `${k}=${v}`).join(' ');
    console.log(`  ${person.full_name.padEnd(28)} ${String(all.length).padStart(4)} matters  [${t}]`);
  }

  if (unresolved.length) console.warn(`\n⚠ UNRESOLVED: ${unresolved.join('; ')}`);
  console.log(`\nwrote ${outFile}`);
  console.log('🔴 A vote is not a chair. On land-use dispositions, read the ordinance before reading the vote.');
}

if (/miamidade-voting-record\.mjs$/.test(process.argv[1] ?? '')) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
