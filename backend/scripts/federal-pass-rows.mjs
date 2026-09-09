#!/usr/bin/env node
/**
 * federal-pass-rows.mjs — turn triaged leads into rows a migration can carry.
 *
 * The claim each row makes is "this senator put their name on this measure, and this is
 * what the measure does", so each row cites the bill TEXT and is gated against the
 * STRUCTURED RECORD:
 *
 *   BILLS-*.htm      the text — what the measure does, in its own words, and the citation
 *   BILLSTATUS-*.xml the sponsor and FULL cosponsor roll — the gate, never cited
 *
 * 🔴 THE VERIFIER DOES NOT CHECK THAT THE SENATOR IS ON THE MEASURE. It checks that the
 * reasoning's terms appear on a cited page. So the bioguide gate below is the check that
 * makes extending a reviewed chair by bill safe, and every row has to pass it.
 *
 * ⚠ THE GATE READS BILLSTATUS, NOT THE BILL TEXT, AND THE DIFFERENCE COST THREE ROWS on
 * gun-policy. govinfo's "Introduced in Senate" print names only the signatures a bill
 * carried ON INTRODUCTION; Schatz joined S. 1531 on 2025-07-23, Ossoff on 2025-05-05 and
 * Cortez Masto joined S. 25 on 2023-05-01, so a gate reading that text refused all three
 * — correctly, given what it was reading. The structured record carries the whole roll.
 *
 * ⚠ BILLSTATUS IS NEVER CITED, AND THAT IS NOT AN OVERSIGHT. Citing the XML failed all 45
 * gun-policy rows: verify-reresearch-rows.mjs reads a page through crawlSite, which
 * extracts nothing from a document with no HTML body and reports "thin body 0c" —
 * UNREADABLE, which it rightly refuses to treat as evidence. The structured record
 * authorises the row HERE; the citation is the readable text the reasoning quotes.
 *
 * ⚠ ALSO CHECK THE TEXT VERSION EXISTS. S. 214's only version is `pcs`, and requesting
 * BILLS-118s214is 302s to a govinfo landing page answering HTTP 200 with 44kB of site
 * chrome — a citation that looks alive and carries none of the bill.
 *
 * ── REASONING IS PER MEASURE, AND NAMES NO ROLE ──────────────────────────────────────
 *
 * A shared string cannot say "sponsor" or "cosponsor" without being wrong for somebody,
 * which is the CC_0076 error CC_0078 was written to avoid. Each string describes what the
 * MEASURE does, in that measure's own vocabulary, so sponsor and cosponsor sit on
 * identical words. It also has to survive the verifier's raw-HTML term check, which is
 * strict: "enumerated" and "listed" both failed where the Assault Weapons Ban says
 * "specified in Appendix A", and a first gun-policy draft failed on "cosponsor" itself.
 *
 * RUN:
 *   node scripts/cohort-worksheet.mjs --tier=federal --cohort=senate --topics=all out/
 *   node scripts/federal-pass-triage.mjs --leads=… --owed=out/rows.csv --topics=… out/tri
 *   node scripts/federal-pass-rows.mjs --topic=israel-military-aid \
 *     --leads=data/federal-pass/2026-09-05-senate-leads.csv \
 *     --owed=out/rows.csv --billdir=out/bills  out/rows-israel.csv
 *
 * --billdir holds the text and status records, fetched once per measure:
 *   curl -so "$dir/<pkg>.html" "https://www.govinfo.gov/content/pkg/BILLS-<pkg>/html/BILLS-<pkg>.htm"
 *   curl -so "$dir/BS-<status>.xml" "https://www.govinfo.gov/bulkdata/BILLSTATUS/<congress>/<type>/BILLSTATUS-<status>.xml"
 */
import { readFileSync, writeFileSync } from 'fs';

const args = process.argv.slice(2);
const flag = (n) => { const h = args.find((a) => a.startsWith(`--${n}=`)); return h ? h.slice(n.length + 3) : null; };
const TOPIC = flag('topic');
const LEADS = flag('leads');
const OWED = flag('owed');
const BILLDIR = flag('billdir');
const OUT = args.find((a) => !a.startsWith('--'));

// ── What seats a chair, per topic ────────────────────────────────────────────────────
//
// Clusters are tried IN ORDER and the first one that matches decides the chair, so the
// order encodes precedence. `conflictsWith` is the opposite: two clusters that cannot
// describe one person are REFUSED rather than resolved by that order.
//
// 🔴 EVERY `reasoning` HERE WAS TESTED AGAINST ITS OWN CITED TEXT before it shipped, and
// every named measure's PURPOSE was read. `lead-axis.mjs` carries four israel entries
// that were added off their short titles alone; the largest, "Stand with Israel Act",
// turned out to prohibit US contributions to the UNITED NATIONS and had grouped 40 of 100
// senators. A title is not evidence of what a bill does.
const TOPICS = {
  'gun-policy': {
    clusters: [
      {
        key: 'awb', value: 2, conflictsWith: ['ccc'],
        // "To regulate assault weapons, to ensure that the right to keep and bear arms is
        //  not unlimited" — the Assault Weapons Ban. CC_0074 seated chair 2 off it and a
        //  human reviewed that chair; CC_0078 extended it to the rest of the roll.
        reasoning: 'A bill to regulate assault weapons and to ensure that the right to keep and bear arms is not unlimited. It is unlawful to import, sell, manufacture, transfer, or possess a semiautomatic assault weapon or large capacity ammunition feeding device; a firearm specified in Appendix A is exempt.',
        bills: [
          { bill: /^S\.\s*1531$/i, pkg: '119s1531is', status: '119s1531', label: 'S. 1531 — Assault Weapons Ban of 2025' },
          { bill: /^S\.\s*25$/i, pkg: '118s25is', status: '118s25', label: 'S. 25 — Assault Weapons Ban of 2023' },
          { bill: /^HR\.\s*698$/i, pkg: '118hr698ih', status: '118hr698', label: 'H.R. 698 — Assault Weapons Ban of 2023' },
        ],
      },
      {
        key: 'bce', value: 3, conflictsWith: ['ccc'],
        // "To require a background check for every firearm sale." Chair 3 only where it
        // stands alone — CC_0074's rule is that chair 3 understates a signatory of the ban.
        reasoning: 'A bill to require a background check for every firearm sale. It is unlawful for a person who is not a licensed importer, licensed manufacturer, or licensed dealer to transfer a firearm to another person who is not so licensed, unless a licensee has first taken possession of the firearm for the purpose of complying with the background check requirements.',
        bills: [
          { bill: /^S\.\s*3214$/i, pkg: '119s3214is', status: '119s3214', label: 'S. 3214 — Background Check Expansion Act' },
          { bill: /^S\.\s*494$/i, pkg: '118s494is', status: '118s494', label: 'S. 494 — Background Check Expansion Act' },
        ],
      },
      {
        key: 'ccc', value: 4, conflictsWith: ['awb', 'bce'],
        // "To allow reciprocity for the carrying of certain concealed firearms." Seatable
        // only after CA_0104 reworded rung 4; under the old wording no rung described it.
        reasoning: 'A bill to allow reciprocity for the carrying of certain concealed firearms: an individual who is not prohibited by Federal law from possessing a firearm, and who is carrying a valid license or permit issued pursuant to the law of a State, may carry a concealed handgun in any State other than the State of residence of the individual that allows residents to obtain licenses or permits to carry concealed firearms.',
        bills: [
          { bill: /^S\.\s*65$/i, pkg: '119s65is', status: '119s65', label: 'S. 65 — Constitutional Concealed Carry Reciprocity Act of 2025' },
          { bill: /^S\.\s*214$/i, pkg: '118s214pcs', status: '118s214', label: 'S. 214 — Constitutional Concealed Carry Reciprocity Act of 2023' },
        ],
      },
    ],
  },

  'israel-military-aid': {
    clusters: [
      {
        key: 'block', value: 3, conflictsWith: ['deliver'],
        // Rung 3 is "block offensive weapons sales while continuing defensive support such
        // as missile defense". S.J.Res. 138 prohibits a NAMED sale — 12,000 BLU-110A/B
        // 1,000-pound bomb bodies — which is offensive ordnance and not missile defense,
        // so the rung's first clause is evidenced by the transmittal itself. Rung 4
        // ("sharply cut aid as a step toward ending it") is a stronger claim that a
        // targeted disapproval does not support.
        //
        // 🔑 ITS ROLL IS EXACTLY THE FOUR SENATORS THIS CLUSTER SEATS — Sanders (sponsor),
        // Van Hollen, Merkley, Welch. Sanders and Welch also sign the §502B human-rights
        // request, which is rung 2's instrument; blocking outranks conditioning, the same
        // precedence CC_0074 used for ban-over-background-checks.
        reasoning: 'A joint resolution providing that the proposed foreign military sale to the Government of Israel described in Transmittal No. 26-32 is prohibited: twelve thousand BLU-110A/B general purpose, 1,000-pound bomb bodies, submitted pursuant to section 36(b)(1) of the Arms Export Control Act.',
        bills: [
          { bill: /^SJRES\.\s*138$/i, pkg: '119sjres138is', status: '119sjres138', label: 'S.J.Res. 138 — disapproval of a foreign military sale to Israel' },
        ],
      },
      {
        key: 'deliver', value: 1, conflictsWith: ['block'],
        // Rung 1 is "continue full military aid to Israel with no new conditions". Both
        // measures below say keep it flowing and unconditioned; neither imposes the
        // compliance requirement rung 2 asks for. Reasoning differs per measure because
        // the cited texts differ.
        bills: [
          {
            // Its own words: "demands that the Biden Administration continue to fulfill the
            // military aid requests from the State of Israel". Rung 1 almost verbatim.
            bill: /^SRES\.\s*682$/i, title: /condemning the decision by the Biden Administration to halt the shipment/i,
            pkg: '118sres682is', status: '118sres682', label: 'S.Res. 682 — condemning the halt of ammunition and weapons shipments',
            reasoning: 'A resolution that condemns any decision to halt the shipment of United States made ammunition and weapons to the State of Israel, and demands that the Administration continue to fulfill the military aid requests from the State of Israel.',
          },
          {
            // "To provide for the expeditious delivery of defense articles and defense
            //  services for Israel" — S. 4337.
            bill: /^S\.\s*4337$/i, pkg: '118s4337is', status: '118s4337',
            label: 'S. 4337 — Israel Security Assistance Support Act',
            reasoning: 'A bill to provide for the expeditious delivery of defense articles and defense services for Israel.',
          },
          {
            // ⚠ THE HOUSE COMPANION IS NEEDED FOR EX-HOUSE MEMBERS, and leaving it out
            // silently dropped one row. Jim Banks served in the House until 2025, so his
            // cosponsorship of this Act is on H.R. 8369 and a Senate-only bill pattern
            // misses it — the same shape as gun-policy's H.R. 698. Same stated purpose
            // ("...and other matters"), and the reasoning's terms carry in its text too.
            bill: /^HR\.\s*8369$/i, pkg: '118hr8369ih', status: '118hr8369',
            label: 'H.R. 8369 — Israel Security Assistance Support Act',
            reasoning: 'A bill to provide for the expeditious delivery of defense articles and defense services for Israel.',
          },
        ],
      },
    ],
  },
};

if (!TOPIC || !TOPICS[TOPIC] || !LEADS || !OWED || !BILLDIR || !OUT) {
  console.error('usage: node scripts/federal-pass-rows.mjs --topic=<topic> --leads=<leads.csv> --owed=<rows.csv> --billdir=<dir> <out.csv>');
  console.error(`       --topic must be one of: ${Object.keys(TOPICS).join(', ')}`);
  process.exit(1);
}
const CFG = TOPICS[TOPIC];

// ── CSV ──────────────────────────────────────────────────────────────────────────────
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
const esc = (v) => { const s = String(v ?? ''); return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
const url = (pkg) => `https://www.govinfo.gov/content/pkg/BILLS-${pkg}/html/BILLS-${pkg}.htm`;
const statusUrl = (id) => `https://www.govinfo.gov/bulkdata/BILLSTATUS/${id.slice(0, 3)}/${id.slice(3).replace(/[0-9]+$/, '')}/BILLSTATUS-${id}.xml`;

// ── The rolls, keyed by bioguide id ──────────────────────────────────────────────────
//
// 🔑 BIOGUIDE, NOT SURNAME. Every <bioguideId> in a BILLSTATUS document sits in a sponsor
// or cosponsor entry, so presence of the id IS the signature. A surname gate worked and
// was still the wrong key: it needed hand-maintained spellings for Lujan, Cortez Masto,
// Van Hollen and Blunt Rochester, and the next accented or two-word surname was a silent
// miss waiting to happen. The leads file already carries bioguide_id for exactly this.
const allBills = CFG.clusters.flatMap((c) => c.bills);
const roll = {};
for (const b of allBills) {
  const xml = readFileSync(`${BILLDIR}/BS-${b.status}.xml`, 'utf8');
  const ids = [...xml.matchAll(/<bioguideId>\s*([A-Z][0-9]{6})\s*<\/bioguideId>/gi)].map((m) => m[1].toUpperCase());
  roll[b.status] = new Set(ids);
  if (!roll[b.status].size) throw new Error(`no bioguide ids parsed out of BS-${b.status}.xml`);
}

// ── Who is in which cluster ──────────────────────────────────────────────────────────
const leads = readTable(LEADS).filter((r) => r.topic_key === TOPIC);
const owed = readTable(OWED).filter((r) => r.topic_key === TOPIC);
const bioOf = {};
for (const l of leads) if (l.politician_id && l.bioguide_id) bioOf[l.politician_id] = l.bioguide_id.toUpperCase();

/** The first measure in this cluster the member has a lead on, or null. */
const pick = (pid, cluster) => {
  for (const b of cluster.bills) {
    const hit = leads.some((l) => l.politician_id === pid
      && b.bill.test(l.bill.trim())
      && (!b.title || b.title.test(l.title)));
    if (hit) return b;
  }
  return null;
};

const out = [];
const skipped = [];
const unsigned = [];
const conflicted = [];

for (const row of owed) {
  const hits = CFG.clusters.map((c) => ({ cluster: c, bill: pick(row.politician_id, c) })).filter((h) => h.bill);
  if (!hits.length) { skipped.push(row.full_name); continue; }

  // 🔴 CLUSTERS THAT CANNOT DESCRIBE ONE PERSON ARE REFUSED, not resolved by precedence.
  // Measured across all 100 senators the overlap is zero on both topics so far — which is
  // what makes the clusters a clean partition — but chairs two rungs apart are not
  // something to let an array order decide quietly later.
  const keys = hits.map((h) => h.cluster.key);
  const clash = hits.find((h) => (h.cluster.conflictsWith ?? []).some((k) => keys.includes(k)));
  if (clash) {
    conflicted.push(`${row.full_name} is in conflicting clusters [${keys.join(', ')}] — needs a human read`);
    continue;
  }

  const { cluster, bill } = hits[0];
  const reasoning = bill.reasoning ?? cluster.reasoning;
  if (!reasoning) throw new Error(`no reasoning for ${bill.label}`);

  const bioguide = bioOf[row.politician_id] ?? '';
  if (!bioguide) { unsigned.push(`${row.full_name} has no bioguide_id in the leads file`); continue; }
  if (!roll[bill.status].has(bioguide)) {
    unsigned.push(`${row.full_name} (${bioguide}) is not in the roll of ${bill.label}`);
    continue;
  }
  out.push({ ...row, value: cluster.value, reasoning, source_url_1: url(bill.pkg), status_url: statusUrl(bill.status), cluster: bill.label });
}

const COLS = ['politician_id', 'full_name', 'topic_key', 'value', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3'];
const csv = [COLS.join(',')];
for (const r of out) csv.push([r.politician_id, r.full_name, r.topic_key, r.value, r.reasoning, r.source_url_1, '', ''].map(esc).join(','));
writeFileSync(OUT, `${csv.join('\n')}\n`, 'utf8');

const byCluster = {};
for (const r of out) byCluster[r.cluster] = (byCluster[r.cluster] || 0) + 1;
console.log(`${out.length} row(s) written to ${OUT}   [${TOPIC}]\n`);
for (const [k, v] of Object.entries(byCluster).sort((a, b) => b[1] - a[1])) {
  console.log(`  ${String(v).padStart(3)}  chair ${out.find((r) => r.cluster === k).value}  ${k}`);
}
console.log(`\n  bioguide id found in the BILLSTATUS sponsor/cosponsor roll for all ${out.length} row(s)`);
console.log('  gated against:');
for (const u of [...new Set(out.map((r) => r.status_url))]) console.log(`     ${u}`);
if (conflicted.length) { console.log(`\n🔴 ${conflicted.length} row(s) REFUSED as contradictory:`); for (const c of conflicted) console.log(`     ${c}`); }
if (unsigned.length) { console.log(`\n🔴 ${unsigned.length} row(s) DROPPED — named on a lead but not in the roll:`); for (const u of unsigned) console.log(`     ${u}`); }
console.log(`\n  ${skipped.length} owed senator(s) in no cluster, left for individual research`);
if (skipped.length && skipped.length <= 12) console.log(`     ${skipped.join(', ')}`);
