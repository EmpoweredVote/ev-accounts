// Generate the gun-policy extension rows from the AWB / Background Check clusters.
//
// The claim each row makes is "this senator put their name on this bill, and this is
// what the bill does", so each row cites the two records that carry those two halves:
//
//   BILLS-*.htm      the bill TEXT — what the measure would do, in its own words
//   BILLSTATUS-*.xml the structured record — the sponsor and the FULL cosponsor roll
//
// 🔴 THE VERIFIER DOES NOT CHECK THAT THE SENATOR IS ON THE BILL. It checks that the
// reasoning's terms appear on a cited page. So the surname gate below is the check that
// makes extending a reviewed chair by bill safe, and every row has to pass it.
//
// ⚠ THE GATE READS BILLSTATUS, NOT THE BILL TEXT, AND THE DIFFERENCE COST THREE ROWS.
// govinfo's "Introduced in Senate" print names only the signatures the bill carried ON
// INTRODUCTION. S. 1531 was introduced 2025-04-30 with 41 of them; Schatz joined
// 2025-07-23 and Ossoff 2025-05-05, and Cortez Masto joined S. 25 on 2023-05-01. All
// three are real cosponsors who are genuinely absent from the introduced text, so a
// gate reading that text refused them — correctly, given what it was reading. The
// structured record carries the whole roll and clears all three.
//
// This is CC_0076's rule applied one step earlier: the STRUCTURED RECORD settles who is
// on a bill, not a press release and not a snapshot of the text. CC_0076 had to rewrite
// published prose because a role came from a summary; the reasoning here makes no role
// claim at all — it describes only what the bill does — so sponsor and cosponsor sit on
// the same words and that error class cannot recur through this generator.
import { readFileSync, writeFileSync } from 'fs';

//
// RUN:
//   node scripts/cohort-worksheet.mjs --tier=federal --cohort=senate --topics=all out/
//   node scripts/federal-pass-gun-policy-rows.mjs //     --leads=data/federal-pass/2026-09-05-senate-leads.csv //     --owed=out/rows.csv --billdir=out/bills  out/gun-policy-rows.csv
//
// --billdir holds the bill text and status records, fetched once:
//   for id in 119s1531is 118s25is 118hr698ih 119s3214is 118s494is 119s65is 118s214pcs; do
//     curl -so "$dir/$id.html" //       "https://www.govinfo.gov/content/pkg/BILLS-$id/html/BILLS-$id.htm"; done
//   for id in 119s1531 118s25 118hr698 119s3214 118s494 119s65 118s214; do
//     curl -so "$dir/BS-$id.xml" //       "https://www.govinfo.gov/bulkdata/BILLSTATUS/${id:0:3}/s/BILLSTATUS-$id.xml"; done
const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const LEADS = flag('leads');
const OWED = flag('owed');
const BILLDIR = flag('billdir');
const OUT = args.find((a) => !a.startsWith('--'));
if (!LEADS || !OWED || !BILLDIR || !OUT) {
  console.error('usage: node scripts/federal-pass-gun-policy-rows.mjs --leads=<leads.csv> --owed=<rows.csv> --billdir=<dir> <out.csv>');
  process.exit(1);
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') inQ = false;
      else field += c;
    } else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); if (row.some((f) => f.trim())) rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  row.push(field);
  if (row.some((f) => f.trim())) rows.push(row);
  return rows;
}
const readTable = (p) => {
  const rows = parseCsv(readFileSync(p, 'utf8'));
  const h = rows.shift();
  return rows.map((r) => Object.fromEntries(h.map((k, i) => [k, r[i] ?? ''])));
};

// Bill label in the leads file → the govinfo package that carries its text.
// Preference order per cluster: the current Congress first, then the prior one, then
// the House companion a member cosponsored while still serving in the House.
const AWB_BILLS = [
  { match: /^S\.\s*1531$/i, pkg: '119s1531is', status: '119s1531', label: 'S. 1531 — Assault Weapons Ban of 2025' },
  { match: /^S\.\s*25$/i, pkg: '118s25is', status: '118s25', label: 'S. 25 — Assault Weapons Ban of 2023' },
  { match: /^HR\.\s*698$/i, pkg: '118hr698ih', status: '118hr698', label: 'H.R. 698 — Assault Weapons Ban of 2023' },
];
// 🔴 THE CARRY CLUSTER EXISTS BECAUSE THE LADDER CHANGED, NOT BECAUSE THE RECORD
// DID. Under Season 2's original rung 4 — "keep current gun laws, adding no new
// restrictions" — these senators had no home: that rung is a status-quo position
// and they are legislating a change, while rung 5 wants major restrictions
// repealed AND permitless carry, which reciprocity does neither of. CA_0104
// reworded rung 4 on 2026-09-08 to "add no new restrictions, and at most loosen
// rules on carrying, such as honoring permits across state lines", which is this
// bill described. The 4-vs-5 line is now whether the major federal gun laws stay.
//
// ⚠ THE 2023 BILL'S TEXT IS `pcs`, NOT `is`, AND THE `is` URL IS WORSE THAN A 404.
// S. 214's only text version is "Placed on Calendar Senate". Requesting
// BILLS-118s214is 302s to a govinfo landing page that returns HTTP 200 with 44kB
// of site chrome — a citation that looks alive and carries none of the bill.
const CCC_BILLS = [
  { match: /^S\.\s*65$/i, pkg: '119s65is', status: '119s65', label: 'S. 65 — Constitutional Concealed Carry Reciprocity Act of 2025' },
  { match: /^S\.\s*214$/i, pkg: '118s214pcs', status: '118s214', label: 'S. 214 — Constitutional Concealed Carry Reciprocity Act of 2023' },
];
const BCE_BILLS = [
  { match: /^S\.\s*3214$/i, pkg: '119s3214is', status: '119s3214', label: 'S. 3214 — Background Check Expansion Act' },
  { match: /^S\.\s*494$/i, pkg: '118s494is', status: '118s494', label: 'S. 494 — Background Check Expansion Act' },
];

const REASONING = {
  2: 'A bill to regulate assault weapons and to ensure that the right to keep and bear arms is not unlimited. It is unlawful to import, sell, manufacture, transfer, or possess a semiautomatic assault weapon or large capacity ammunition feeding device; a firearm specified in Appendix A is exempt.',
  3: 'A bill to require a background check for every firearm sale. It is unlawful for a person who is not a licensed importer, licensed manufacturer, or licensed dealer to transfer a firearm to another person who is not so licensed, unless a licensee has first taken possession of the firearm for the purpose of complying with the background check requirements.',
  4: 'A bill to allow reciprocity for the carrying of certain concealed firearms: an individual who is not prohibited by Federal law from possessing a firearm, and who is carrying a valid license or permit issued pursuant to the law of a State, may carry a concealed handgun in any State other than the State of residence of the individual that allows residents to obtain licenses or permits to carry concealed firearms.',
};
const url = (pkg) => `https://www.govinfo.gov/content/pkg/BILLS-${pkg}/html/BILLS-${pkg}.htm`;
const statusUrl = (id) => `https://www.govinfo.gov/bulkdata/BILLSTATUS/${id.slice(0, 3)}/${id.slice(3).replace(/[0-9]+$/, '')}/BILLSTATUS-${id}.xml`;

// ── Bill texts, and the block that names who introduced and cosponsored ──────
const strip = (s) => s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
const deaccent = (s) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
const roll = {};
for (const b of [...AWB_BILLS, ...BCE_BILLS, ...CCC_BILLS]) {
  // 🔑 THE ROLL IS KEYED BY BIOGUIDE ID, NOT BY SURNAME. Every <bioguideId> in a
  // BILLSTATUS document sits in a sponsor or cosponsor entry — S. 1531 carries 43 of
  // them, one sponsor and 42 cosponsors, and 42 <sponsorshipDate> elements confirm the
  // split — so presence of the id IS the signature, with no container scoping needed.
  //
  // ⚠ A SURNAME GATE WORKED AND WAS STILL THE WRONG KEY. It needed hand-maintained
  // spellings for Lujan, Cortez Masto, Van Hollen and Blunt Rochester, and every future
  // two-word or accented surname would have been a silent miss waiting to happen. The
  // leads file already carries bioguide_id for exactly this reason, and the id is what
  // api.congress.gov joins on.
  const xml = readFileSync(`${BILLDIR}/BS-${b.status}.xml`, 'utf8');
  const ids = [...xml.matchAll(/<bioguideId>\s*([A-Z][0-9]{6})\s*<\/bioguideId>/gi)].map((m) => m[1].toUpperCase());
  roll[b.status] = new Set(ids);
  if (!roll[b.status].size) throw new Error(`no bioguide ids parsed out of BS-${b.status}.xml`);
}

// ── Who is in which cluster ──────────────────────────────────────────────────
const leads = readTable(LEADS).filter((r) => r.topic_key === 'gun-policy');
const owed = readTable(OWED).filter((r) => r.topic_key === 'gun-policy');

const pick = (pid, bills) => {
  for (const b of bills) {
    if (leads.some((l) => l.politician_id === pid && b.match.test(l.bill.trim()))) return b;
  }
  return null;
};

const out = [];
const skipped = [];
const unsigned = [];
const conflicted = [];

for (const row of owed) {
  const awb = pick(row.politician_id, AWB_BILLS);
  const bce = pick(row.politician_id, BCE_BILLS);
  const ccc = pick(row.politician_id, CCC_BILLS);

  // 🔴 A RESTRICTION AND A CARRY EXPANSION CANNOT BOTH SEAT ONE PERSON, so a
  // senator on both is REFUSED rather than resolved by the order of these ifs.
  // Measured 2026-09-05 the overlap was zero across all 100 senators, which is
  // what makes the clusters a clean partition — but "currently empty" is not a
  // reason to let a precedence rule decide it silently later. The chairs are two
  // rungs apart and a wrong pick is a published claim in the wrong direction.
  if ((awb || bce) && ccc) {
    conflicted.push(`${row.full_name} is on BOTH a restriction bill and carry reciprocity — needs a human read`);
    continue;
  }

  const bill = awb ?? bce ?? ccc;
  const value = awb ? 2 : bce ? 3 : ccc ? 4 : null;
  if (!bill) { skipped.push(row.full_name); continue; }

  const bioguide = (leads.find((l) => l.politician_id === row.politician_id)?.bioguide_id ?? '').toUpperCase();
  if (!bioguide) { unsigned.push(`${row.full_name} has no bioguide_id in the leads file`); continue; }
  if (!roll[bill.status].has(bioguide)) {
    unsigned.push(`${row.full_name} (${bioguide}) is not in the roll of ${bill.label}`);
    continue;
  }
  out.push({
    ...row, value, reasoning: REASONING[value],
    source_url_1: url(bill.pkg), status_url: statusUrl(bill.status), cluster: bill.label,
  });
}

const esc = (v) => { const s = String(v ?? ''); return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
const COLS = ['politician_id', 'full_name', 'topic_key', 'value', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3'];
const csv = [COLS.join(',')];
// 🔴 BILLSTATUS IS THE GATE, NOT A CITATION, AND THAT IS DELIBERATE. Citing the XML
// failed all 45 rows: verify-reresearch-rows.mjs reads a page through crawlSite, which
// extracts nothing from a document with no HTML body and reports "thin body 0c" —
// UNREADABLE, which it refuses to treat as evidence. It is right to. So the structured
// record authorises the row HERE, at generation, and the migration header records its
// URL for a reviewer; the citation a voter sees is the bill text, which is readable and
// which is what the reasoning actually quotes.
for (const r of out) csv.push([r.politician_id, r.full_name, r.topic_key, r.value, r.reasoning, r.source_url_1, '', ''].map(esc).join(','));
writeFileSync(OUT, `${csv.join('\n')}\n`, 'utf8');

const byCluster = {};
for (const r of out) byCluster[r.cluster] = (byCluster[r.cluster] || 0) + 1;
console.log(`${out.length} row(s) written to ${OUT}\n`);
for (const [k, v] of Object.entries(byCluster).sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(3)}  chair ${out.find((r) => r.cluster === k).value}  ${k}`);
console.log(`\n  bioguide id found in the BILLSTATUS sponsor/cosponsor roll for all ${out.length} row(s)`);
if (conflicted.length) { console.log(`
🔴 ${conflicted.length} row(s) REFUSED as contradictory:`); for (const c of conflicted) console.log(`     ${c}`); }
if (unsigned.length) { console.log(`\n🔴 ${unsigned.length} row(s) DROPPED — named on a lead but not in the bill's roll:`); for (const u of unsigned) console.log(`     ${u}`); }
console.log(`\n  ${skipped.length} owed senator(s) in neither cluster, left for individual research: ${skipped.join(', ')}`);
