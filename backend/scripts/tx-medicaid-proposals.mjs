#!/usr/bin/env node
/**
 * Propose one Texas citation per row, ranked by how directly it answers the CLAIM.
 *
 * 🔑 THE CLAIM IS "BACKED MEDICAID EXPANSION", so the best possible evidence is authorship of an
 * actual expansion bill — in Texas those exist and are unmistakable ("Relating to the expansion of
 * eligibility for Medicaid ... under the federal Patient Protection and Affordable Care Act", 89R
 * SB 45 and its companions HB 197 / HB 726). A member on one of those has the claim proved outright.
 * Only where none exists does the ranking fall back to the member's strongest coverage bill, and the
 * wording then says what the evidence actually shows rather than repeating the template.
 *
 * 🔑 IDENTITY IS THE TLO MEMBER CODE. These lists come from TLO's own per-member report, so unlike a
 * sponsor-list surname there is nothing to disambiguate — but the report's own header name is checked
 * against ours, because a wrong Code would silently produce a whole wrong record.
 *
 * ⚠ Author outranks co-author. Recency breaks ties.
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-tx-medicaid-proposals.json');
const REPORTS = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/txlege/reports';

/** an actual ACA Medicaid-expansion bill, which is what these rows claim */
const EXPANSION = /expansion of eligibility for medicaid|expand(ing)? (the )?eligibility for medicaid|medicaid (eligibility )?expansion/i;

const R = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-tx-member-legislation.json', 'utf8'));

/** the report page prints the member's name in its header — confirm the Code is the right person */
function headerName(code) {
  for (const f of fs.readdirSync(REPORTS).filter((x) => x.endsWith(`-${code}.html`))) {
    const h = fs.readFileSync(path.join(REPORTS, f), 'utf8');
    const t = h.replace(/<[^>]*>/g, '\n').replace(/&nbsp;/g, ' ').split('\n').map((s) => s.trim()).filter(Boolean);
    const line = t.find((s) => /^(Rep\.|Sen\.)\s/.test(s));
    if (line) return line;
  }
  return null;
}

const out = [];
for (const r of R.rows) {
  if (!r.code) { out.push({ ...r, proposal: null, blocked_reason: r.how }); continue; }
  const hdr = headerName(r.code);
  // \ud83d\udd34 A SURNAME CHECK IS NOT AN IDENTITY CHECK. Testing only that the header contained "Hernandez"
  // passed "Rep. Ana Hernandez" for Cassandra Garcia Hernandez \u2014 a different member entirely. Require
  // the SURNAME **and** a first-name token to agree.
  const fold = (s) => (s || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const bare = r.name.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/);
  const surname = bare[bare.length - 1], firstName = bare[0];
  const h = fold(hdr).replace(/^(rep|sen)\.\s*/, '');
  const nameOk = !!hdr && h.includes(fold(surname)) && h.includes(fold(firstName));

  const scored = (r.candidates || []).map((c) => ({ ...c, isExpansion: EXPANSION.test(c.caption || '') }))
    .sort((a, b) => (b.isExpansion - a.isExpansion)
      || ((a.kind === 'author' ? 0 : 1) - (b.kind === 'author' ? 0 : 1))
      || b.session.localeCompare(a.session));
  const best = scored[0] || null;
  out.push({ ...r, candidates: undefined, n_candidates: (r.candidates || []).length,
    header_name: hdr, name_confirms: nameOk,
    proposal: best || null,
    blocked_reason: best ? null : 'no citable caption',
    n_expansion: scored.filter((c) => c.isExpansion).length });
}

for (const r of out) {
  console.log(`\n### ${r.name} | ${r.topic.slice(0, 20)} | ch${r.chair} [${r.code || '—'}] ${r.name_confirms ? '✓' : '✗'}${r.header_name ? ` ${r.header_name}` : ''}`);
  if (!r.proposal) { console.log('   NO PROPOSAL — ' + r.blocked_reason); continue; }
  const p = r.proposal;
  console.log(`   ${p.kind.toUpperCase().padEnd(8)} ${p.isExpansion ? '★EXPANSION' : '          '} ${p.session} ${p.bill}  (${r.n_expansion} expansion bill(s) among ${r.n_candidates})`);
  console.log(`   ${(p.caption || '').slice(0, 190)}`);
}
const bad = out.filter((r) => r.proposal && !r.name_confirms);
console.log(`\n${out.length} rows; ${out.filter((r) => r.proposal).length} proposals; ${out.filter((r) => r.proposal && r.proposal.isExpansion).length} on an actual expansion bill; ${bad.length} with an UNCONFIRMED member name.`);
fs.writeFileSync(OUT, JSON.stringify({ pass: 'TX medicaid-template proposals', rows: out }, null, 1));
console.log(`wrote ${OUT}`);
