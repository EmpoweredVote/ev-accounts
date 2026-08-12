#!/usr/bin/env node
/**
 * TEXAS class-C sourcing: what did each member actually author or co-author, on topic?
 *
 * 🔑 THE SAME SHAPE AS THE MARYLAND PASS, on Texas Legislature Online. TLO publishes per-member,
 * per-session bill lists — reports/report.aspx?LegSess=<sess>&ID=author|coauthor&Code=<code> — which
 * is TLO's OWN attribution, so it cannot mis-credit a surname twin. Identity is the member CODE.
 *
 * 🔴 TEXAS NEVER EXPANDED MEDICAID. So "backed Medicaid expansion" here cannot mean a vote for an
 * enacted expansion; at most it means authoring or co-authoring an expansion BILL. Those bills exist
 * and are identifiable — 89R SB 45 is "Relating to the expansion of eligibility for Medicaid ... under
 * the federal Patient Protection and Affordable Care Act" (Authors Zaffirini | Cook, Coauthor Blanco),
 * with named companions HB 197 and HB 726. A member who is on one of those is genuinely evidenced; a
 * member who is not is carrying template text.
 *
 * 🔴🔴 AND MANY TEXAS ROWS ARE NOT DEFECTIVE AT ALL. Of the 55 rows carrying the phrase, 9 at chair 4-5
 * say the member OPPOSED expansion — correct, and consistent with an anti-pole chair. The phrase is
 * not the defect; the pairing of PRO wording with NO evidence is. Rows at chair >= 3 are excluded from
 * sponsorship sourcing entirely (see the chair gate in md-medicaid-proposals.mjs).
 *
 * 🔴 Reads only.
 *   node scripts/tx-member-legislation.mjs --out <report.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { UA } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-tx-member-legislation.json');
const MAX_CHAIR = parseFloat(flag('--max-chair', '2'));

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/txlege';
const REPORTS = path.join(CACHE, 'reports');
const ROSTER = path.join(CACHE, 'roster');
for (const d of [REPORTS, ROSTER]) fs.mkdirSync(d, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Regular sessions to read. 89R is current; earlier ones cover the members' tenure. */
const SESSIONS = ['89R', '88R', '87R', '86R', '85R'];

/**
 * ⚠ \b-BOUNDED, for the reason recorded in lib/md-topic-nets.mjs: unbounded substrings put
 * "app-RENT-iceship" and "PREMIUM cigar lounge" at the top of real reading queues.
 */
const NET = {
  'Healthcare Access': /\bmedicaid\b|\bmedicare\b|\bhealth insurance\b|\bhealth benefit|\bhealth care coverage\b|\bhealth coverage\b|\buninsured\b|\bchildren'?s health insurance\b|\bCHIP\b|\bhealth care\b|\bhealth plan\b|\bmanaged care\b|\bpremium|\bcost.sharing\b|\bcopay/i,
  'Medicare / Medicaid': /\bmedicaid\b|\bmedicare\b|\bmedical assistance\b|\bmanaged care\b|\bchildren'?s health insurance\b|\bCHIP\b|\blong.term care\b|\bwaiver\b/i,
};
/** what may actually be CITED — a caption-shape test, not a keyword list */
const STRICT = {
  'Healthcare Access': /\bmedicaid\b|\bmedicare\b|\bhealth insurance\b|\bhealth benefit plan|\bhealth care coverage\b|\bchildren'?s health insurance\b|\buninsured\b/i,
  'Medicare / Medicaid': /\bmedicaid\b|\bmedicare\b|\bmedical assistance\b|\bchildren'?s health insurance\b/i,
};

async function get(url, file) {
  if (fs.existsSync(file) && fs.statSync(file).size > 2000) return fs.readFileSync(file, 'utf8');
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  const body = await res.text();
  await sleep(1100);
  // ⚠ a short body is an error page, never an empty report — never cache it as truth
  if (!res.ok || body.length < 2000) return null;
  fs.writeFileSync(file, body);
  return body;
}

/**
 * TLO roster per chamber: SURNAME -> member code.
 * ⚠ The first attempt required links shaped `MemberInfo.aspx?Leg=..&Chamber=..&Code=..` and matched
 * NOTHING, so every member "was not found in the roster" — an absence manufactured by my own regex.
 * The real links only carry `Code=`, and the link text is the surname alone.
 */
async function roster(chamber) {
  const f = path.join(ROSTER, `${chamber}.html`);
  const h = await get(`https://capitol.texas.gov/Members/Members.aspx?Chamber=${chamber}`, f);
  if (!h) return {};
  const out = {};
  // ⚠ no literal quote after the code — TLO writes `Code=A1315&amp;...` — and entities must be
  // decoded first. Requiring `Code=A1315"` matched zero members and reported the whole chamber absent.
  for (const m of h.replace(/&amp;/g, '&').matchAll(/Code=([A-Z]\d+)[^>]*>\s*([^<]{2,50}?)\s*</g)) {
    const name = m[2].replace(/\s+/g, ' ').trim();
    // ⚠ COMMAS ARE THE FORMAT, not noise: TLO writes "Garcia Hernandez, Cassandra". Excluding commas
    // dropped every full "Surname, First" entry and left only the bare-surname ones, which is why the
    // full-name match could not fire and the wrong Hernandez was nearly used.
    if (!/^[A-Za-zÀ-ÿ'’.,\- ]+$/.test(name) || !/[A-Za-z]/.test(name)) continue;
    (out[name.toLowerCase()] ||= []).push({ code: m[1], chamber });
  }
  return out;
}

/** bills a member authored / co-authored in one session, with captions */
async function memberBills(code, sess) {
  const rows = [];
  for (const kind of ['author', 'coauthor']) {
    const f = path.join(REPORTS, `${sess}-${kind}-${code}.html`);
    const h = await get(`https://capitol.texas.gov/reports/report.aspx?LegSess=${sess}&ID=${kind}&Code=${code}`, f);
    if (!h) continue;
    // ⚠ TLO writes its hrefs with HTML entities — `...&amp;Bill=HB182` — so a regex demanding a literal
    // `&Bill=` matches nothing and every member reads as having authored no bills. Decode first.
    const html = h.replace(/&amp;/g, '&');
    const text = html.replace(/<[^>]*>/g, '\n').replace(/&nbsp;/g, ' ');
    for (const m of html.matchAll(/BillLookup\/History\.aspx\?LegSess=([^&"]+)&Bill=([A-Z]{2}\d+)/g)) {
      if (!rows.some((r) => r.bill === m[2] && r.session === m[1] && r.kind === kind)) {
        rows.push({ session: m[1], bill: m[2], kind });
      }
    }
    // the caption follows the bill number a few lines later in the flattened text
    const lines = text.split('\n').map((s) => s.trim()).filter(Boolean);
    for (let i = 0; i < lines.length; i++) {
      const bm = lines[i].match(/^([HS]B)\s?(\d+)$/);
      if (!bm) continue;
      // ⚠ the caption sits EIGHT lines after the bill number ("HB 182 / Author / : / Meza / Last
      // Action: / <date> / Caption / : / Relating to ..."). A 7-line window found none of them and
      // every member read as having no on-topic bills — another absence made by my own parser.
      const caption = lines.slice(i + 1, i + 12).find((s) => s.length > 30 && /^Relating to/i.test(s));
      if (!caption) continue;
      const hit = rows.find((r) => r.bill === `${bm[1]}${bm[2]}` && r.kind === kind);
      if (hit && !hit.caption) hit.caption = caption;
    }
  }
  return rows;
}

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });
const { rows: targets } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name AS name, t.title AS topic, a.value AS chair,
         c.reasoning, c.sources, o.title AS office
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    LEFT JOIN essentials.offices o ON o.id = p.office_id
    LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
    LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
   WHERE c.reasoning ILIKE '%Medicaid expansion%' AND o.representing_state = 'TX'
     AND a.value <= $1 AND t.title IN ('Healthcare Access','Medicare / Medicaid')
   ORDER BY p.full_name`, [MAX_CHAIR]);
await pool.end();
console.log(`${targets.length} Texas rows at chair <= ${MAX_CHAIR} on a health topic\n`);

const rosters = {};
for (const ch of ['H', 'S']) rosters[ch] = await roster(ch);
console.log(`roster: House ${Object.keys(rosters.H).length}, Senate ${Object.keys(rosters.S).length}`);

/**
 * 🔴🔴 A STORED CITATION IS NOT IDENTITY EITHER. The first version preferred whatever member Code the
 * row already cited — and Cassandra Garcia Hernandez's row cites `A3155`, which is **Ana Hernandez**,
 * a different member. Trusting it would have sourced her compass row from another woman's legislative
 * record. The correct code, `A4495`, is in the roster as "Garcia Hernandez, Cassandra".
 *
 * So the ROSTER decides, matched on the FULL NAME (TLO writes "Surname, First", and comparing token
 * sets handles "Cassandra Garcia Hernandez" vs "Garcia Hernandez, Cassandra"). A stored code that
 * disagrees with the roster is reported as a WRONG-PERSON CITATION, not silently used.
 */
const fold = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
const tokens = (s) => new Set(fold(s).replace(/[.,]/g, ' ').split(/\s+/)
  .filter((w) => w && !/^(jr|sr|ii|iii|iv)$/.test(w)));
const subset = (a, b) => [...a].every((w) => b.has(w));

function resolveCode(r) {
  const fromSrc = (r.sources || []).map((s) => (s.match(/Code=([A-Z]\d+)/) || [])[1]).filter(Boolean)[0];
  const ch0 = /senator/i.test(r.office || '') ? 'S' : 'H';
  const mine = tokens(r.name);
  // full-name match: every roster token is in our name, or every one of ours is in the roster entry
  // ⚠ "Hernandez" is a subset of "Cassandra Garcia Hernandez" just as "Garcia Hernandez, Cassandra"
  // is, so a uniqueness test alone finds TWO matches and gives up — landing back on the wrong member.
  // Rank by how MUCH of the name matched and take the most specific, but only when it is strictly
  // more specific than the runner-up; a tie is still ambiguous and must not be guessed.
  const full = Object.entries(rosters[ch0])
    .map(([n, v]) => ({ n, t: tokens(n), v }))
    .filter(({ t }) => subset(t, mine) || subset(mine, t))
    .sort((a, b) => b.t.size - a.t.size);
  if (full.length && (full.length === 1 || full[0].t.size > full[1].t.size)) {
    const code = full[0].v[0].code;
    if (fromSrc && fromSrc !== code) {
      return { code, how: `roster full-name match; ⚠ STORED SOURCE CITES ${fromSrc}, A DIFFERENT MEMBER`, wrongStored: fromSrc };
    }
    return { code, how: 'roster full-name match' };
  }
  const ch = ch0;
  // ⚠ ACCENTS. Our "Mary Gonzalez" is TLO's "González" and "Mary Ann Perez" is "Pérez"; matching on
  // raw lowercase reported them absent from a roster they are in. Fold diacritics on both sides.
  const last = r.name.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop();
  const hits = Object.entries(rosters[ch]).filter(([n]) => fold(n) === fold(last)).flatMap(([, v]) => v);
  // ⚠ a shared surname is not identity — leave it unresolved rather than guess
  if (hits.length === 1) return { code: hits[0].code, how: `roster ${ch} unique surname` };
  return { code: null, how: hits.length ? `AMBIGUOUS surname in ${ch} roster (${hits.length})` : `not found in ${ch} roster` };
}

const out = [];
for (const r of targets) {
  const { code, how, wrongStored } = resolveCode(r);
  if (!code) { out.push({ ...r, code: null, how, wrong_stored_code: null, candidates: [], n_on_topic: 0 }); console.log(`  ⚠ ${r.name}: ${how}`); continue; }
  const all = [];
  for (const s of SESSIONS) all.push(...(await memberBills(code, s)));
  const net = NET[r.topic], strict = STRICT[r.topic];
  const onTopic = all.filter((b) => b.caption && net.test(b.caption));
  const citable = onTopic.filter((b) => strict.test(b.caption));
  out.push({ ...r, code, how, wrong_stored_code: wrongStored || null, n_bills_seen: all.length, n_on_topic: onTopic.length,
    candidates: citable.map((b) => ({ ...b, url: `https://capitol.texas.gov/BillLookup/History.aspx?LegSess=${b.session}&Bill=${b.bill}` })) });
  console.log(`  ${String(citable.length).padStart(3)} citable / ${String(onTopic.length).padStart(3)} on-topic / ${String(all.length).padStart(4)} seen   ${r.name} [${code}] ${r.topic.slice(0, 18)}`);
}

fs.writeFileSync(OUT, JSON.stringify({ pass: 'TX member authored/coauthored bills, on-topic', rows: out }, null, 1));
console.log(`\nwrote ${OUT}`);
