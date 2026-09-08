#!/usr/bin/env node
/**
 * miamidade-sponsorship-leads.mjs — turn a Miami-Dade commissioner's own
 * legislative record into research LEADS for the open season's local topics.
 *
 * The county analogue of congress-sponsorship-leads.mjs, and it exists for the
 * same reason: stop searching for "topic → instrument" and ask instead what this
 * person has actually put their name on.
 *
 * ── 🔴 MIAMI-DADE'S LEGISTAR IS DEAD. DO NOT USE IT. ─────────────────────────
 *
 * https://webapi.legistar.com/v1/miamidade answers HTTP 200 with real, correctly
 * shaped JSON, so it reads as live. It is frozen:
 *
 *   · newest event 2018-06-19 (Seattle's control instance: 2026-09-11)
 *   · 67 persons, and they are the 2014 commission — Jordan, Monestime,
 *     Edmonson, Barreiro, Sosa, Bovo
 *   · NOT ONE of the thirteen sitting commissioners appears in it
 *   · miamidade.legistar.com/Calendar.aspx loads and says "No records were found"
 *
 * A 200 with plausible data is not evidence a source is current. Probe RECENCY
 * first — it is one request and it is the only question that matters.
 *
 * The live record is the county's own Legislative Information Center, which
 * covers June 1996 to present and is richer than Legistar anyway: it publishes
 * Matter Sponsor, Voting Record and Legislative Index reports per office holder.
 *
 * ── LEADS, NOT EVIDENCE. THIS SCRIPT SEATS NOTHING. ──────────────────────────
 *
 * Everything here is a pointer for a human to open and read. Three failure modes
 * it cannot see on its own, all observed in the first real pull:
 *
 *   · 🔴 THE SPONSOR REPORT INCLUDES ITEMS THE PERSON DID NOT SPONSOR. Hardemon's
 *     report carries an item whose own notes read "CUA - No sponsor". The report
 *     appears to include matters routed through a commissioner's office as well
 *     as ones they sponsored, so `notes_flag_no_sponsor` is surfaced per item and
 *     ATTRIBUTION MUST BE CHECKED ON THE ITEM PAGE, never inherited from the
 *     report you asked for.
 *
 *     🔴🔴 AND `notes_flag_no_sponsor` UNDER-DETECTS — IT IS NECESSARY, NOT
 *     SUFFICIENT. Measured 2026-09-07 while reading Bastien's housing leads:
 *     matter 261305, SAME DAY PERMIT PROGRAM, sits in HER report with the flag
 *     FALSE, and its matter page reads "Sponsors: Anthony Rodriguez, Prime
 *     Sponsor". The flag only fires when a clerk happened to type "no sponsor"
 *     in the notes. **The only thing that settles attribution is the Sponsors
 *     field on the matter page**, which also states who is PRIME sponsor. Never
 *     seat a chair on a lead whose Sponsors field you have not read.
 *   · a title that matches a pattern but whose substance is orthogonal — a
 *     "density" match is as often a plat correction as a housing policy
 *   · sponsoring an item is not holding its chair: a commissioner may sponsor the
 *     administration's item, or one they later voted against. The Voting Record
 *     report is the check, and it is a separate report.
 *
 * ── 🔴 THE SOURCE SERVES CORRUPTED QUOTATION MARKS, AND WE DO NOT REPAIR THEM ─
 *
 * The only non-ASCII bytes in these pages are EF BF BD — U+FFFD REPLACEMENT
 * CHARACTER, stored that way upstream. No re-decoding recovers the original:
 * `(�ARSHT CENTER�)` was a quote pair, `CENTER�S` was an
 * apostrophe, and nothing in the bytes distinguishes them. Guessing would put
 * invented punctuation into text that ends up voter-facing, so the raw text is
 * stored verbatim and `text_has_lost_characters` is raised for a human to fix at
 * the point of quoting. Leads may be imperfect; published prose may not.
 *
 * ── 🔴 ONE NAME CAN CARRY TWO OFFICE-HOLDER CODES ────────────────────────────
 *
 * `Raquel A. Regalado` is listed TWICE, as B744 and B779. Taking the first match
 * silently drops half a record. Every name is resolved to the FULL SET of codes
 * and each is fetched; a name resolving to none is reported and skipped, never
 * guessed. Matching folds diacritics (René → Rene), strips honorifics ("Sen.")
 * and suffixes ("III"), and ignores nicknames in quotes ("JC").
 *
 * ── MEASURED ON THE FIRST FULL SWEEP (2025-01-01 → 2026-09-05) ──────────────
 *
 * 14 people, 2,704 sponsored matters, 598 with a topic lead, across 20 of the
 * season's local ladders. Housing (145), transportation (108) and economic
 * development (100) dominate; local-immigration surfaced once.
 *
 * 🔴 THE MAYOR SPONSORS NOTHING, AND THAT IS A FACT ABOUT THE OFFICE. Levine
 * Cava's code returns 0 matters for 2025-26 and 1,349 for 2015-19, when she sat
 * on the Board. The control is what makes the zero readable: the code works, the
 * office simply does not sponsor Board legislation. She needs a different route
 * — `MatterType=MV` is Mayoral Veto, which IS her instrument, plus the items her
 * administration requests. Do not report her as "no record".
 *
 * ⚠ THE CEREMONIAL FILTER REMOVED 0 OF 598. This report returns only Resolution,
 * Ordinance and Report; the birthday scrolls live under a different report. The
 * filter is kept for the next jurisdiction, but it is NOT load bearing here and
 * nobody should assume it is doing work.
 *
 * ⚠ 39 of 598 leads (7%) carry `notes_flag_no_sponsor`, and 406 (73%) carry
 * `text_has_lost_characters`. Both are per-item flags, both need a human.
 *
 * ── READING A LEAD: THE ITEM PAGE NEEDS THREE EXTRA PARAMS ──────────────────
 *
 * `source_url` is the stable, citable form and it is the one to publish. But
 * fetching it gives a 302 to a JavaScript bounce page — 492 bytes containing
 * only `window.open` — so a naive fetch of a matter looks like an empty record.
 * The report itself wants the params back on the original path, with a year
 * folder derived from the matter number's first two digits:
 *
 *   matter.asp?matter=251003&file=false&fileAnalysis=false&yearFolder=Y2025
 *
 * That page carries what the sweep cannot: **Sponsors** (with "Prime Sponsor"),
 * Requester, the full Title, the Reference (the enacted R- or O- number) and a
 * Legislative History table with a Pass/Fail column.
 *
 * RUN: node scripts/miamidade-sponsorship-leads.mjs --since=2025-01-01
 *      node scripts/miamidade-sponsorship-leads.mjs --name="Keon Hardemon"
 *      node scripts/miamidade-sponsorship-leads.mjs --since=2024-01-01 --resume
 *
 * Needs DATABASE_URL. No API key — the reports are public GET forms.
 */
import 'dotenv/config';
import { writeFileSync, appendFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import pg from 'pg';
import { matchLocalTopics } from './lib/topic-lead-patterns.mjs';

const BASE = 'https://www.miamidade.gov/govaction';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

/** Miami-Dade County government, seeded by CC_0017. */
const MIAMI_DADE_GOVERNMENT_ID = 'd31ea899-f015-4456-8370-b727e3bef271';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const since = flag('since') ?? '2025-01-01';
const until = flag('until') ?? new Date().toISOString().slice(0, 10);
const onlyName = flag('name');
const outFile = flag('out') ?? 'data/stance-research/miamidade-sponsorship-leads.jsonl';
const RESUME = args.includes('--resume');
const ALL_MATTERS = args.includes('--all-matters');

/**
 * Ceremonial and administrative matter types, dropped unless --all-matters.
 *
 * A commissioner's raw sponsorship list is mostly proclamations: without this
 * filter the signal is buried under birthday scrolls. These are the report's own
 * type labels, matched against the type word the report prints per item.
 */
const CEREMONIAL = /^(birthday scroll|commendation|congratulatory certificate|certificate of appreciation|distinguished visitor|citizen'?s presentation|proclamation|presentation|special presentation)$/i;

/** MM/DD/YYYY, which is the only date format the report's form accepts. */
const usDate = (iso) => { const [y, m, d] = iso.split('-'); return `${m}/${d}/${y}`; };

/** Fold a display name to something two lists can be compared on. */
export function normalizeName(name) {
  return name
    .normalize('NFD').replace(/[̀-ͯ]/g, '') // René → Rene; marks DELETED, not spaced
    .replace(/"[^"]*"|“[^”]*”/g, ' ')     // drop "JC", “Pepe”
    .replace(/\b(sen|rep|hon|honorable|dr|mr|mrs|ms|comm|commissioner|mayor)\b\.?/gi, ' ')
    .replace(/\b(jr|sr|ii|iii|iv)\b\.?/gi, ' ')
    .replace(/[.,]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

/**
 * Every office-holder code belonging to one person, and how sure we are.
 *
 * 🔴 THE ANSWER IS A SET, NEVER A FIRST MATCH. Regalado is B744 and B779.
 *
 * Exact means the folded names are equal. Our roster says "Oliver Gilbert" and
 * the county says "Oliver G. Gilbert, III", so a middle initial alone would
 * strand a sitting commissioner — that falls to a FUZZY match on first and last
 * token, which is reported for a human to confirm rather than trusted silently.
 * Fuzzy refuses whenever it would collapse two different people: "Higgins" is
 * both Danielle Cohen Higgins and Eileen Higgins on this very list.
 */
export function resolveCodes(fullName, holders) {
  const want = normalizeName(fullName);
  const exact = holders.filter((h) => normalizeName(h.name) === want);
  if (exact.length) return { codes: exact, match: 'exact' };

  const [first, ...rest] = want.split(' ');
  const last = rest[rest.length - 1];
  if (!first || !last) return { codes: [], match: 'none' };

  const near = holders.filter((h) => {
    const t = normalizeName(h.name).split(' ');
    return t[0] === first && t[t.length - 1] === last;
  });
  const distinct = new Set(near.map((h) => normalizeName(h.name)));
  if (near.length && distinct.size === 1) return { codes: near, match: 'fuzzy' };
  return { codes: [], match: distinct.size > 1 ? 'ambiguous' : 'none', candidates: [...distinct] };
}

async function get(url) {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error(`HTTP ${r.status} for ${url}`);
  // Declared iso-8859-1; the bytes are ASCII plus literal U+FFFD sequences, so
  // utf-8 is the correct read and the corruption survives it intact, by design.
  return new TextDecoder('utf-8').decode(await r.arrayBuffer());
}

const stripTags = (s) => s
  .replace(/<br\s*\/?>/gi, '\n')
  .replace(/<[^>]+>/g, '')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'")
  .replace(/[ \t]+/g, ' ')
  .trim();

/** Every office holder the Matter Sponsor form offers, as {code, name}. */
export function parseOfficeHolders(html) {
  const sel = /name=["']?OfficeHolders["']?[^>]*>([\s\S]*?)<\/select>/i.exec(html);
  if (!sel) throw new Error('OfficeHolders select not found — the form changed');
  return [...sel[1].matchAll(/<option[^>]*value=["']?([^"'>\s]+)["']?[^>]*>([^<]*)/gi)]
    .map((m) => ({ code: m[1], name: stripTags(m[2]) }))
    .filter((o) => o.code && /^B\d+$/.test(o.code));
}

/**
 * Every matter in one Matter Sponsor report.
 *
 * The report is one flat table. A matter opens with a row carrying the type, a
 * link to matter.asp, the subject and the status; the next row carries the
 * agenda date, the item code and the full operative title; rows after that are
 * routing history until the next matter opens. Splitting on the matter link is
 * what makes this robust to the history rows varying in number.
 */
export function parseSponsorReport(html) {
  const chunks = html.split(/(?=<b>\s*(?:Resolution|Ordinance|Report|Resolution\/Ordinance)\s*<\/b>\s*(?:&nbsp;)*\s*<a href="matter\.asp)/i);
  const out = [];
  for (const chunk of chunks) {
    const link = /<a href="matter\.asp\?matter=(\d+)"[^>]*>\s*<b>\s*([^<]+?)\s*<\/b>/i.exec(chunk);
    if (!link) continue;
    const typeM = /<b>\s*(Resolution|Ordinance|Report|Resolution\/Ordinance)\s*<\/b>\s*(?:&nbsp;)*\s*<a href="matter\.asp/i.exec(chunk);
    const statusM = /<b>\s*Status:\s*<\/b>([\s\S]*?)<\/font>/i.exec(chunk);
    const subjectM = /<td[^>]*colspan="3"[^>]*>[\s\S]*?<b>([\s\S]*?)<\/[bB]>/i.exec(chunk);
    const agendaM = /Agenda Date:\s*<br>\s*([\d/]+)/i.exec(chunk);
    const enactedM = /\b([RO]-\d+-\d+)\b/.exec(chunk);
    // The operative text is the widest cell in the matter's second row.
    const titleM = /<td[^>]*colspan="6"[^>]*>\s*<font[^>]*>([\s\S]*?)<\/font>/i.exec(chunk);

    const title = titleM ? stripTags(titleM[1]) : '';
    const subject = subjectM ? stripTags(subjectM[1]) : '';
    const haystack = `${subject}\n${title}`;

    out.push({
      matter_id: link[1],
      matter_number: stripTags(link[2]),
      matter_type: typeM ? typeM[1] : null,
      subject,
      title,
      status: statusM ? stripTags(statusM[1]) : null,
      agenda_date: agendaM ? agendaM[1] : null,
      enacted_number: enactedM ? enactedM[1] : null,
      source_url: `${BASE}/matter.asp?matter=${link[1]}`,
      // 🔴 The report is not proof of sponsorship — see the header.
      notes_flag_no_sponsor: /no sponsor/i.test(chunk),
      text_has_lost_characters: haystack.includes('�'),
      topics: matchLocalTopics(haystack),
    });
  }
  return out;
}

async function main() {
  const { Pool } = pg;
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  // The cohort comes from the occupancy view, never from a hardcoded list — a
  // commissioner who leaves must drop out of the sweep without an edit here.
  const { rows: cohort } = await pool.query(
    `SELECT p.id::text AS politician_id, p.full_name, o.title
       FROM essentials.governments g
       JOIN essentials.chambers c   ON c.government_id = g.id
       JOIN essentials.offices o    ON o.chamber_id = c.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id
      WHERE g.id = $1
        AND c.name IN ('Board of County Commissioners', 'Office of the Mayor')
      ORDER BY p.full_name`,
    [MIAMI_DADE_GOVERNMENT_ID],
  );
  await pool.end();

  const targets = onlyName
    ? cohort.filter((c) => normalizeName(c.full_name) === normalizeName(onlyName))
    : cohort;
  if (!targets.length) { console.error(`no cohort match for ${onlyName ?? '(all)'}`); process.exit(1); }

  const holders = parseOfficeHolders(await get(`${BASE}/ReportMenu.asp?ReportName=Sponsor.asp`));
  console.log(`office holders offered by the form: ${holders.length}`);

  mkdirSync(dirname(outFile), { recursive: true });
  const done = new Set();
  if (RESUME && existsSync(outFile)) {
    for (const line of readFileSync(outFile, 'utf8').split('\n').filter(Boolean)) {
      try { done.add(JSON.parse(line).politician_id); } catch { /* partial line */ }
    }
    console.log(`resuming — ${done.size} politician(s) already written`);
  } else if (!RESUME) {
    writeFileSync(outFile, '');
  }

  const unresolved = [];
  for (const person of targets) {
    if (done.has(person.politician_id)) continue;

    // 🔴 FULL SET, not first match — Regalado is B744 AND B779.
    const { codes, match, candidates } = resolveCodes(person.full_name, holders);
    if (!codes.length) {
      unresolved.push(`${person.full_name} (${match}${candidates?.length ? ': ' + candidates.join(' / ') : ''})`);
      console.warn(`  ⚠ SKIP ${person.full_name} — ${match === 'ambiguous' ? 'AMBIGUOUS, refusing to guess' : 'no office-holder code'}`);
      continue;
    }
    if (match === 'fuzzy') console.warn(`  ⚠ ${person.full_name} matched FUZZILY to "${codes[0].name}" — confirm this is the same person`);
    if (codes.length > 1) console.warn(`  ⚠ ${person.full_name} has ${codes.length} codes (${codes.map((c) => c.code).join(', ')}) — fetching all`);

    const matters = new Map();
    for (const { code } of codes) {
      const url = `${BASE}/Sponsor.asp?begdate=${encodeURIComponent(usDate(since))}&enddate=${encodeURIComponent(usDate(until))}`
        + `&OfficeHolders=${code}&MatterType=AllMatters&submit1=Submit`;
      for (const m of parseSponsorReport(await get(url))) {
        matters.set(m.matter_id, { ...m, office_holder_code: code });
      }
    }

    const all = [...matters.values()];
    const kept = ALL_MATTERS ? all : all.filter((m) => !CEREMONIAL.test(m.matter_type ?? ''));
    const withTopics = kept.filter((m) => m.topics.length);

    // Written per person, as we go, so a run that dies mid-sweep resumes.
    appendFileSync(outFile, JSON.stringify({
      politician_id: person.politician_id,
      full_name: person.full_name,
      office_title: person.title,
      office_holder_codes: codes.map((c) => c.code),
      window: { since, until },
      counts: { fetched: all.length, after_ceremonial_filter: kept.length, with_topic_lead: withTopics.length },
      leads: withTopics,
    }) + '\n');

    console.log(`  ${person.full_name.padEnd(28)} ${String(all.length).padStart(4)} matters → ${String(kept.length).padStart(4)} substantive → ${String(withTopics.length).padStart(3)} with a topic lead`);
  }

  if (unresolved.length) console.warn(`\n⚠ UNRESOLVED (reported, not guessed): ${unresolved.join('; ')}`);
  console.log(`\nwrote ${outFile}`);
  console.log('🔴 These are LEADS. Open matter.asp for each before citing it, and confirm the person actually sponsored it.');
}

// Run as a CLI; stay silent when a test imports the pure halves above.
if (/miamidade-sponsorship-leads\.mjs$/.test(process.argv[1] ?? '')) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
