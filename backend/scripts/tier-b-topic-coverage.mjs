#!/usr/bin/env node
/**
 * TIER B, second cut -- does the cited encyclopaedia article say ANYTHING about this row's topic?
 *
 * 🔑 WHY THE FIRST CUT IS NOT ENOUGH: "has a Political positions section" only SORTS. Gavin Newsom's
 * Wikipedia article has NO positions section at all -- its headings are purely biographical -- yet it
 * discusses his policy record at length inside "Governor of California". So "no positions section"
 * is not a verdict; absence of the TOPIC is.
 *
 * 🔑 MEASURED ON RAW HTML with deliberately GENEROUS keywords, and a topic counts absent only when
 * EVERY keyword occurs ZERO times. Nav, infobox and category furniture all count as present, so the
 * test is strictly conservative and immune to extraction bugs -- the discipline that made MD pass 2
 * trustworthy after its first, extraction-based cut reported 109 absences against a true 82.
 *
 * 🔴 Reads only. Emits an audit; nothing here is a delete list.
 *   node scripts/tier-b-topic-coverage.mjs --audit <tier-b-audit.json> --cache <dir> --out <out.json>
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const AUDIT = flag('--audit'), CACHE = flag('--cache'), OUT = flag('--out');
if (!AUDIT || !CACHE || !OUT) { console.error('need --audit --cache --out'); process.exit(2); }

// Generous on purpose. A single hit anywhere in the raw HTML keeps the row.
const KW = {
  'Access to Justice': ['legal aid', 'access to justice', 'public defender', 'court fee'],
  'Affordable Housing': ['housing', 'affordable home', 'rent', 'zoning', 'homeless'],
  'Artificial Intelligence Oversight': ['artificial intelligence', 'a.i.', ' ai ', 'algorithm'],
  'Bail and Pretrial Decisions': ['bail', 'pretrial', 'pre-trial', 'detention'],
  'Campaign Finance Reform': ['campaign finance', 'dark money', 'citizens united', 'super pac', 'donor'],
  'Childcare Affordability & Access': ['child care', 'childcare', 'pre-k', 'prekindergarten', 'day care'],
  'City Sanitation and Cleanliness': ['sanitation', 'trash', 'garbage', 'litter', 'street clean'],
  'Civil Rights and Social Justice': ['civil right', 'discriminat', 'racial', 'lgbt', 'equity'],
  'Climate Change and Environmental Protection': ['climate', 'environment', 'emission', 'greenhouse', 'renewable'],
  'Criminal Justice Approach': ['criminal justice', 'sentencing', 'incarcerat', 'prison', 'crime'],
  'Criminalization of Homelessness': ['homeless', 'encampment', 'vagran'],
  'Data Center Development & Energy Costs': ['data center', 'data centre', 'energy cost', 'electricity rate'],
  'Deportation Priorities': ['deport', 'immigration enforcement', 'ice ', 'removal proceeding'],
  'Economic Development Incentives': ['economic development', 'tax incentive', 'job creation', 'business'],
  'Environmental Protection vs. Development': ['environment', 'development', 'conservation', 'land use'],
  'Fossil Fuel Policy': ['fossil fuel', 'oil', 'gas', 'coal', 'pipeline', 'drilling'],
  'Growth and Development Pace': ['growth', 'development', 'sprawl', 'density'],
  'Healthcare Access': ['health care', 'healthcare', 'insurance', 'medicaid', 'medicare', 'uninsured'],
  'Homelessness Response': ['homeless', 'shelter', 'encampment', 'housing first'],
  'Immigration and Treatment of Immigrants': ['immigra', 'undocumented', 'sanctuary', 'asylum', 'refugee'],
  'Jail Capacity and Incarceration Alternatives': ['jail', 'incarcerat', 'diversion', 'prison'],
  'Judicial & Prosecutorial Discretion': ['prosecut', 'discretion', 'judicial'],
  'Judicial Interpretation': ['originalis', 'constitution', 'judicial', 'supreme court', 'precedent'],
  'Local Immigration Enforcement': ['immigra', 'sanctuary', 'ice ', '287(g)'],
  'Medicare / Medicaid': ['medicare', 'medicaid', 'health insurance', 'entitlement'],
  'Misinformation and the Role of Algorithms in Democracy': ['misinformation', 'disinformation', 'algorithm', 'social media'],
  'Police Accountability': ['police', 'law enforcement', 'qualified immunity', 'misconduct'],
  'Prosecution Priorities': ['prosecut', 'district attorney', 'charging'],
  'Public Safety Approach': ['public safety', 'police', 'crime', 'violence'],
  'Religious Freedom': ['religio', 'faith', 'first amendment', 'conscience'],
  'Rent Regulation': ['rent', 'tenant', 'eviction', 'landlord', 'rent control'],
  'Reproductive Rights and Abortion Access': ['abortion', 'reproductive', 'roe v', 'pro-choice', 'pro-life', 'pregnan'],
  'Residential Zoning': ['zoning', 'housing', 'single-family', 'density', 'land use'],
  'Same-Sex Marriage': ['same-sex', 'marriage equality', 'gay marriage', 'lgbt'],
  'School Vouchers & Public Education Funding': ['voucher', 'school', 'education fund', 'charter'],
  'Social Security': ['social security', 'retirement benefit', 'entitlement'],
  'State Redistricting and Gerrymandering': ['redistrict', 'gerrymander', 'districting', 'census'],
  'Taxation and Public Spending': ['tax', 'revenue', 'budget', 'spending'],
  'Transgender Athletes': ['transgender', 'trans athlete', 'gender identity'],
  'Transparency in Legal Proceedings': ['transparen', 'open court', 'public record', 'sealed'],
  'Transportation Priorities': ['transit', 'transportation', 'highway', 'rail', 'bus'],
  'Ukraine - Russia Conflict': ['ukrain', 'russia', 'zelensky', 'putin'],
  'United States Tariff Policy': ['tariff', 'trade war', 'import duty', 'protectionis'],
  'Voting Rights and Electoral Integrity': ['voting', 'voter', 'election', 'ballot', 'registration'],
};

const audit = JSON.parse(fs.readFileSync(AUDIT, 'utf8'));
const fileFor = (u) => path.join(CACHE, encodeURIComponent(u).replace(/[^A-Za-z0-9%._-]/g, '_').slice(-180) + '.html');

const htmlCache = new Map();
function lowerHtml(u) {
  if (htmlCache.has(u)) return htmlCache.get(u);
  const f = fileFor(u);
  const v = fs.existsSync(f) ? fs.readFileSync(f, 'utf8').toLowerCase() : null;
  htmlCache.set(u, v);
  return v;
}

let noKw = 0;
const out = audit.rows.map((r) => {
  if (r.verdict === 'ARTICLE_DOES_NOT_EXIST') return { ...r, coverage: 'ARTICLE_DEAD' };
  const kws = KW[r.topic];
  if (!kws) { noKw++; return { ...r, coverage: 'NO_KEYWORDS_DEFINED' }; }
  const h = lowerHtml(r.article);
  if (!h) return { ...r, coverage: 'NOT_CACHED' };
  const hits = kws.filter((k) => h.includes(k));
  return {
    ...r,
    coverage: hits.length ? 'TOPIC_PRESENT' : 'TOPIC_ABSENT',
    matched_keywords: hits.slice(0, 4),
  };
});

// The cross of the two cuts is what actually ranks the queue.
const cross = {};
for (const r of out) {
  const k = `${r.verdict} | ${r.coverage}`;
  cross[k] = (cross[k] || 0) + 1;
}
const tally = out.reduce((m, r) => { m[r.coverage] = (m[r.coverage] || 0) + 1; return m; }, {});

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'Tier B second cut - does the cited article mention the topic at all?',
  method: 'Raw-HTML keyword test, generous keyword sets, ZERO hits required to call a topic absent. '
        + 'Nav/infobox/category furniture counts as present, so the test is conservative by design.',
  tally, cross, rows: out,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
console.log('\ncross-tab (positions-section | topic-coverage):');
for (const [k, v] of Object.entries(cross).sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(5)}  ${k}`);
if (noKw) console.log(`\n⚠ ${noKw} row(s) had no keyword set defined -- excluded from any verdict.`);
