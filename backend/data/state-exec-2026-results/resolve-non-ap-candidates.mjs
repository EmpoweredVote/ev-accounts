// Resolve the 72 candidates in the 31 races to be CREATED, and match the 36 candidates in the
// 13 races to be UPDATED against the race_candidates rows those races already hold.
//
// Same ladder as CC_0359, and for the same reason: 🔴 a name match is a HYPOTHESIS — the TX-22
// winner was the incumbent's twin brother, and three matches in CC_0359 were thrown out on what
// the person already held. Only an anchor to office_current_holder is accepted unread.
import fs from 'node:fs';
const SP = process.argv[2];
const plan = JSON.parse(fs.readFileSync(`${SP}/plan.json`, 'utf8'));
const pols = JSON.parse(fs.readFileSync(`${SP}/all-politicians.json`, 'utf8'));
const holders = JSON.parse(fs.readFileSync(`${SP}/holders.json`, 'utf8'));
const decisions = JSON.parse(fs.readFileSync(`${SP}/decisions-bp.json`, 'utf8'));

const nm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv']);
const ends = s => { const t = nm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };

const byExact = new Map(), byEnds = new Map();
const push = (m, k, v) => { if (!k) return; if (!m.has(k)) m.set(k, []); m.get(k).push(v); };
for (const p of pols) { push(byExact, nm(p.full_name), p); push(byEnds, ends(p.full_name), p); }
const holderByOffice = new Map(holders.map(h => [h.office_id, h]));
const decBy = new Map(decisions.map(d => [`${d.st}|${d.office}|${d.name}`, d]));

// ── the UPDATE half: every Ballotpedia name must hit exactly one existing race_candidates row ──
const updates = [], updateProblems = [];
for (const r of plan.update) {
  for (const p of r.people) {
    const hits = r.existing.rows.filter(x => ends(x.full_name) === ends(p.name));
    if (hits.length !== 1) {
      // a name on Ballotpedia's ballot that our race does not carry is ABSENT, not wrong —
      // both cases here are declared write-ins. It is recorded, never invented.
      updateProblems.push({ st: r.st, office: r.ourTitle, name: p.name, hits: hits.length, writeIn: p.writeIn });
      continue;
    }
    updates.push({
      st: r.st, office: r.ourTitle, officeId: r.officeId, raceId: r.existing.race_id, seats: r.existing.seats,
      rcId: hits[0].rc_id, dbName: hits[0].full_name, bpName: p.name, priorResult: hits[0].result,
      result: p.won ? 'won' : 'lost', party: p.party, isInc: hits[0].is_incumbent, bpPct: p.bpPct,
    });
  }
}
// rows our race holds that Ballotpedia's ballot does not name: left exactly as they are
const untouched = [];
for (const r of plan.update) for (const x of r.existing.rows)
  if (!r.people.some(p => ends(p.name) === ends(x.full_name)))
    untouched.push({ st: r.st, office: r.ourTitle, name: x.full_name, result: x.result, status: x.candidate_status });

// ── the CREATE half: resolve or seed ──
const creates = [];
for (const r of plan.create) {
  const holder = holderByOffice.get(r.officeId);
  for (const p of r.people) {
    const kE = nm(p.name), kL = ends(p.name);
    const exact = byExact.get(kE) ?? [];
    const near = (byEnds.get(kL) ?? []).filter(x => nm(x.full_name) !== kE);
    const activeExact = exact.filter(x => x.is_active);
    const holderEnds = holder && ends(holder.full_name) === kL;

    let verdict, pid = null;
    if (holderEnds) { verdict = 'ANCHORED-HOLDER'; pid = holder.politician_id; }
    else if (activeExact.length === 1) { verdict = near.length ? 'EXACT-PLUS-NEAR' : 'EXACT'; pid = activeExact[0].id; }
    else if (activeExact.length > 1) { verdict = `${activeExact.length}-ACTIVE-EXACT`; }
    else if (exact.length >= 1) { verdict = `${exact.length}-ARCHIVED-EXACT`; }
    else if (near.length) { verdict = `NEAR-${near.length}`; }
    else { verdict = 'NEW'; }

    const d = decBy.get(`${r.st}|${r.ourTitle}|${p.name}`);
    if (d) { if (!d.why) throw new Error(`decision for ${r.st} ${p.name} has no reason`);
             verdict = d.politicianId ? `BY-HAND (${d.why})` : `NEW (ruled: ${d.why})`; pid = d.politicianId; }

    creates.push({
      st: r.st, office: r.ourTitle, officeId: r.officeId, ticket: r.ticket,
      name: p.name, ticketHead: p.ticketHead, party: p.party, url: p.url, bpPct: p.bpPct,
      result: p.won ? 'won' : 'lost', writeIn: p.writeIn,
      seatHolder: holder ? holder.full_name : null, verdict, politicianId: pid,
      exact: exact.map(x => ({ id: x.id, full_name: x.full_name, is_active: x.is_active })),
      near: near.map(x => ({ id: x.id, full_name: x.full_name, is_active: x.is_active })),
    });
  }
}
fs.writeFileSync(`${SP}/resolved-bp.json`, JSON.stringify({ creates, updates, untouched, updateProblems }, null, 1));

const tally = {};
for (const c of creates) { const k = c.verdict.replace(/ \(.*/, ''); tally[k] = (tally[k] || 0) + 1; }
console.log(`CREATE candidacies: ${creates.length}`);
for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(3)}  ${k}`);
console.log(`  resolved to an existing person: ${creates.filter(c => c.politicianId).length}, to seed: ${creates.filter(c => !c.politicianId).length}`);
console.log(`\nUPDATE candidacies matched to an existing row: ${updates.length}`);
console.log(`  of which won: ${updates.filter(u => u.result === 'won').length}`);
console.log(`  prior results being overwritten: ${JSON.stringify(updates.reduce((a, u) => { const k = u.priorResult || 'NULL'; a[k] = (a[k] || 0) + 1; return a; }, {}))}`);
console.log(`rows our race holds that Ballotpedia does not name (left untouched): ${untouched.length}`);
for (const u of untouched) console.log(`    ${u.st} ${u.office}: ${u.name} [${u.result || 'NULL'}, ${u.status}]`);
console.log(`\nBallotpedia names, absent from our race (NOT invented): ${updateProblems.length}`);
for (const p of updateProblems) console.log(`    ${p.st} ${p.office}: ${p.name}${p.writeIn ? ' (write-in)' : ''} — ${p.hits} matching rows`);

const review = creates.filter(c => !/^(ANCHORED-HOLDER|EXACT|NEW|BY-HAND)$/.test(c.verdict.replace(/ \(.*/, '')));
console.log(`\n=== ${review.length} NEEDING A READ ===`);
for (const c of review) console.log(`  ${c.st} ${c.office}: "${c.name}" -> ${c.verdict}  exact=${JSON.stringify(c.exact)} near=${JSON.stringify(c.near)}`);
const collide = creates.filter(c => !c.politicianId && (c.exact.length || c.near.length));
console.log(`\n=== ${collide.length} SEED(S) WHOSE NAME ALREADY EXISTS ===`);
for (const c of collide) console.log(`  ${c.st} ${c.office}: "${c.name}" vs ${[...c.exact, ...c.near].map(x => `"${x.full_name}" ${x.id} active=${x.is_active}`).join(', ')}`);
