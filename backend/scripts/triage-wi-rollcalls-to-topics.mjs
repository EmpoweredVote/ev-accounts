// Triage WI roll calls to candidate compass topics by subject keyword.
//
// Usage:  node scripts/triage-wi-rollcalls-to-topics.mjs
//
// Writes data/stance-research/wi-2026-state-leg/wi_rollcall_topic_triage.csv
//
// ============================ WHAT THIS IS AND IS NOT ============================
// This is a SHORTLISTING step, not evidence. A keyword hit says "this roll call MIGHT bear on this
// topic" — nothing more. It does NOT establish that the bill is chair-shaped, and a keyword match
// must never be turned into a stance value.
//
// Every row lands with chair_shaped / chair_if_yes / chair_if_no BLANK. A human reads the bill and
// fills them in, or discards the row. Only adjudicated rows may feed a stance payload.
//
// Rationale (see project_stance_evidence_shape_over_type): a vote pins a chair only when the BILL
// is chair-shaped. An oppositional No vote rules out the far end and nothing more. So the unit of
// review is the bill, adjudicated ONCE, then reused across every member who voted on it — which is
// why this file is bill-keyed rather than person-keyed.
// ================================================================================
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const DIR = join('data', 'stance-research', 'wi-2026-state-leg');

// Only the 26 topics prod scopes to role_scope='state' are eligible. The 44-topic
// _TOPIC_SCALE_FULL.txt is the full LIVE topic list and includes 8 judicial and several
// city-only topics that must never be asked of a state legislator.
const STATE_SCOPE_TOPICS = [
  'abortion', 'ai-regulation', 'campaign-finance', 'childcare', 'civil-rights', 'climate-change',
  'data-centers', 'deportation', 'economic-development', 'fossil-fuels', 'growth-and-development',
  'healthcare', 'homelessness', 'immigration', 'jail-capacity', 'medicare/aid', 'misinformation',
  'redistricting', 'religious-freedom', 'rent-regulation', 'same-sex-marriage', 'school-vouchers',
  'taxes', 'trans-athletes', 'transportation-priorities', 'voting-rights',
];

// Deliberately narrow. A false negative costs one shortlisted row; a false positive invites
// someone to read a keyword hit as a finding.
const KEYWORDS = {
  abortion: ['ABORTION', 'UNBORN', 'PREGNANCY TERMINATION', 'FETAL'],
  'ai-regulation': ['ARTIFICIAL INTELLIGENCE', 'SYNTHETIC MEDIA', 'DEEPFAKE', 'AUTOMATED DECISION'],
  'campaign-finance': ['CAMPAIGN FINANCE', 'CAMPAIGN CONTRIBUTION', 'POLITICAL CONTRIBUTION', 'ELECTIONEERING'],
  childcare: ['CHILD CARE', 'CHILDCARE', 'DAY CARE', 'EARLY CHILDHOOD'],
  'civil-rights': ['CIVIL RIGHTS', 'DISCRIMINATION', 'AFFIRMATIVE ACTION', 'DIVERSITY EQUITY'],
  'climate-change': ['CLIMATE', 'GREENHOUSE GAS', 'CARBON EMISSION', 'RENEWABLE ENERGY', 'CLEAN ENERGY'],
  'data-centers': ['DATA CENTER'],
  deportation: ['DEPORTATION', 'IMMIGRATION ENFORCEMENT', 'SANCTUARY'],
  'economic-development': ['ECONOMIC DEVELOPMENT', 'TAX INCREMENT', 'ENTERPRISE ZONE', 'BUSINESS DEVELOPMENT', 'JOB CREATION'],
  'fossil-fuels': ['FOSSIL FUEL', 'NATURAL GAS', 'COAL', 'PIPELINE', 'PETROLEUM'],
  'growth-and-development': ['ZONING', 'REZONING', 'LAND USE', 'SUBDIVISION', 'COMPREHENSIVE PLAN', 'DEVELOPMENT MORATORIUM'],
  healthcare: ['HEALTH INSURANCE', 'HEALTH CARE', 'HEALTHCARE', 'PRESCRIPTION DRUG', 'HOSPITAL', 'MENTAL HEALTH', 'HEALTH SERVICES', 'EMERGENCY MEDICAL SERVICES'],
  homelessness: ['HOMELESS*', 'SHELTER*'],
  immigration: ['IMMIGRA*', 'REFUGEE*', 'NONCITIZEN*', 'ALIEN', 'UNLAWFULLY PRESENT', 'UNDOCUMENTED'],
  'jail-capacity': ['JAIL*', 'PRISON*', 'CORRECTIONAL', 'INCARCERAT*'],
  'medicare/aid': ['MEDICAID', 'MEDICARE', 'BADGERCARE'],
  misinformation: ['MISINFORMATION', 'DISINFORMATION'],
  redistricting: ['REDISTRICTING', 'LEGISLATIVE DISTRICT', 'APPORTIONMENT'],
  'religious-freedom': ['RELIGIOUS', 'CONSCIENCE', 'FAITH-BASED', 'PLACES OF WORSHIP', 'FREEDOM TO GATHER'],
  'rent-regulation': ['RENT', 'LANDLORD', 'TENANT', 'EVICTION'],
  'same-sex-marriage': ['SAME-SEX', 'MARRIAGE'],
  'school-vouchers': ['VOUCHER', 'CHOICE SCHOOL', 'PARENTAL CHOICE', 'CHARTER SCHOOL', 'INDEPENDENT CHARTER'],
  taxes: ['TAX', 'TAXATION', 'INCOME TAX', 'PROPERTY TAX', 'SALES TAX', 'TAX CREDIT', 'TAX EXEMPTION'],
  'trans-athletes': ['TRANSGENDER', 'GENDER IDENTITY', 'INTERSCHOLASTIC ATHLETIC', 'GENDER TRANSITION'],
  'transportation-priorities': ['TRANSPORTATION', 'HIGHWAY', 'TRANSIT', 'RAIL', 'BICYCLE', 'ROAD'],
  'voting-rights': ['ELECTION', 'VOTER', 'VOTING', 'ABSENTEE', 'BALLOT', 'VOTER IDENTIFICATION'],
};

const unknown = Object.keys(KEYWORDS).filter((k) => !STATE_SCOPE_TOPICS.includes(k));
if (unknown.length) throw new Error(`keyword set references non-state-scope topics: ${unknown.join(', ')}`);

// Matching must anchor the START of the keyword to a word boundary, but allow a trailing stem.
//
// Plain substring matching produced a worksheet full of nonsense — every bad hit was a MID-word
// match: RENT inside "PARENTS"/"APPRENTICES", TRANSIT inside "GENDER TRANSITION", ROAD inside
// "BROADBAND". Anchoring both ends instead over-filtered, silently dropping plurals: "ABORTIONS",
// "DATA CENTERS". So: \b at the front, [A-Z]* at the back. A trailing '*' is accepted for
// readability but is now the default behaviour.
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const wordRe = new Map();
function matchesWord(hay, word) {
  if (!wordRe.has(word)) {
    const body = esc(word.replace(/\*$/, '')).replace(/\\?\s+/g, '\\s+');
    wordRe.set(word, new RegExp(`\\b${body}[A-Z]*`, 'i'));
  }
  return wordRe.get(word).test(hay);
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) { if (c === '"') { if (text[i+1] === '"') { field += '"'; i++; } else inQ = false; } else field += c; }
    else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  const cols = rows.shift();
  return rows.filter((r) => r.length === cols.length).map((r) => Object.fromEntries(cols.map((c, i) => [c, r[i]])));
}

function toCsv(rows) {
  if (rows.length === 0) return '';
  const cols = Object.keys(rows[0]);
  const esc = (v) => {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [cols.join(','), ...rows.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n') + '\n';
}

const rollcalls = parseCsv(readFileSync(join(DIR, 'wi_rollcalls.csv'), 'utf8'));

// Human adjudications are merged in from a TRACKED sidecar. This CSV is regenerable and gitignored,
// so decisions recorded only in its cells vanish the moment anyone re-runs this script — which would
// silently reset reviewed roll calls to "not yet adjudicated" and invite them to be re-reviewed.
const ADJ_FILE = join(DIR, 'wi-rollcall-adjudications.json');
let ADJUDICATIONS = {};
try {
  ADJUDICATIONS = JSON.parse(readFileSync(ADJ_FILE, 'utf8')).adjudications || {};
} catch (e) {
  // Absent is legitimate (nothing adjudicated yet); malformed is not.
  if (e.code !== 'ENOENT') {
    console.error(`FATAL: ${ADJ_FILE} exists but could not be parsed: ${e.message}`);
    console.error('Refusing to run — continuing would silently discard completed adjudications.');
    process.exit(1);
  }
}

// A near-unanimous vote cannot separate legislators from one another, so it cannot pin a chair
// for an individual. Keep the threshold explicit and reported rather than silently filtering.
const MIN_MINORITY = 10;
const divided = rollcalls.filter((r) => Number(r.minority) >= MIN_MINORITY);

// Procedural motions do NOT express a position on the subject matter. A vote to table or reject an
// amendment, or to uphold the chair's ruling, is a floor-management vote — treating it as a policy
// position is exactly the "evidence type over bill shape" error. The WI budget bills (AB 50/SB 45)
// generate dozens of these, so they dominate the divided pool if left unclassified.
const PROCEDURAL = [
  'TABLE AMENDMENT', 'REJECT AMENDMENT', 'SHALL THE DECISION OF THE CHAIR STAND',
  'SUSPEND RULES', 'TABLE EN MASSE', 'REFUSAL TO CONCUR', 'MESSAGE FROM',
  'ASSEMBLY OFFICERS AND ORGANIZATION', 'COMMITTEE STRUCTURE', 'SESSION SCHEDULE',
  'SENATE OFFICERS AND ORGANIZATION', 'APPEAL', 'ADJOURN',
  // Added 2026-07-28 after the calibration batch: these all reached the "usable pool" and are
  // just as procedural as tabling an amendment.
  //   REFER TO COMMITTEE  — sends a bill away; not a position on its subject (AB 840 av0178)
  //   LAY ON TABLE        — same family as TABLE AMENDMENT, different wording (AB 472 av0189)
  //   SUSPENSION OF A RULE— a rules motion (AB 13/14/15 av0013-15)
  //   SERGEANT AT ARMS    — electing an internal chamber officer, matched only because the word
  //                         "ELECTION" fires the voting-rights keyword (SR 5 sv0030/sv0031)
  'REFER TO COMMITTEE', 'LAY ON TABLE', 'SUSPENSION OF A RULE', 'SERGEANT AT ARMS',
];
const motionClass = (heading) =>
  PROCEDURAL.some((p) => (heading || '').toUpperCase().includes(p)) ? 'procedural' : 'substantive';

const out = [];
let matchedCount = 0;
for (const rc of divided) {
  const hay = (rc.heading || '').toUpperCase();
  const hits = [];
  for (const [topic, words] of Object.entries(KEYWORDS)) {
    const matched = words.filter((w) => matchesWord(hay, w));
    if (matched.length) hits.push({ topic, matched });
  }
  if (hits.length) matchedCount++;
  out.push({
    vote_id: rc.vote_id,
    chamber: rc.chamber,
    bill: rc.bill,
    motion_class: motionClass(rc.heading),
    heading: rc.heading,
    ayes: rc.ayes,
    nays: rc.nays,
    minority: rc.minority,
    candidate_topics: hits.map((h) => h.topic).join('; '),
    matched_keywords: hits.map((h) => `${h.topic}:${h.matched.join('/')}`).join(' | '),
    n_candidate_topics: hits.length,
    // --- filled in by a human, from reading the bill. Blank = not yet adjudicated. ---
    // Populated from the tracked adjudication sidecar when a verdict exists for this roll call.
    chair_shaped: ADJUDICATIONS[rc.vote_id]?.chair_shaped ?? '',
    topic_final: ADJUDICATIONS[rc.vote_id]?.topic_final ?? '',
    chair_if_yes: ADJUDICATIONS[rc.vote_id]?.chair_if_yes ?? '',
    chair_if_no: ADJUDICATIONS[rc.vote_id]?.chair_if_no ?? '',
    reviewer_note: ADJUDICATIONS[rc.vote_id]?.reviewer_note ?? '',
    bill_url: rc.bill ? `https://docs.legis.wisconsin.gov/2025/proposals/${rc.bill.replace(/\s+/g, '').toLowerCase()}` : '',
  });
}

out.sort((a, b) => b.n_candidate_topics - a.n_candidate_topics || Number(b.minority) - Number(a.minority));
writeFileSync(join(DIR, 'wi_rollcall_topic_triage.csv'), toCsv(out));

// The usable pool is the intersection: divided AND substantive AND on-topic.
const substantive = out.filter((r) => r.motion_class === 'substantive');
const usable = substantive.filter((r) => r.n_candidate_topics > 0);
const perTopic = {};
for (const r of usable) for (const t of r.candidate_topics.split('; ').filter(Boolean)) perTopic[t] = (perTopic[t] || 0) + 1;

console.log(`roll calls total:                 ${rollcalls.length}`);
console.log(`divided (losing side >= ${MIN_MINORITY}):       ${divided.length}   <- only these can separate members`);
console.log(`  of those, procedural:           ${divided.length - substantive.length}  (tabling/rejecting amendments, chair rulings — pin NOTHING)`);
console.log(`  of those, substantive:          ${substantive.length}`);
console.log(`    with >=1 candidate topic:     ${usable.length}   <-- THE USABLE POOL`);
console.log(`    with NO candidate topic:      ${substantive.length - usable.length}  (off-compass subject, or keywords too narrow)`);
console.log(`  ambiguous (>1 candidate topic): ${usable.filter((r) => r.n_candidate_topics > 1).length}`);
console.log(`\nshortlisted roll calls per topic (UN-ADJUDICATED — a keyword hit is not evidence):`);
for (const t of STATE_SCOPE_TOPICS) {
  const n = perTopic[t] || 0;
  console.log(`  ${t.padEnd(28)} ${String(n).padStart(3)}${n === 0 ? '   <- no roll-call route; needs candidate-stated sources' : ''}`);
}
const adjudicated = out.filter((r) => r.chair_shaped).length;
const adjInPool = usable.filter((r) => r.chair_shaped).length;
console.log(`\nadjudications merged from wi-rollcall-adjudications.json: ${adjudicated} (${adjInPool} of the ${usable.length}-row usable pool)`);
console.log(`  still to adjudicate in the usable pool: ${usable.length - adjInPool}`);
console.log(`wrote wi_rollcall_topic_triage.csv — unadjudicated rows have BLANK chair_shaped/topic_final/chair_if_* by design`);
