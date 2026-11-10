// Final resolution: every one of AP's 212 gap candidacies -> an existing politician, or NEW.
//
// Two name spellings per person now: AP's and Ballotpedia's. 🔴 AP TRUNCATES — "T. Shannon"
// is T. W. Shannon, "L. Taylor" is L. Webb Taylor, "H. Paige" is H. Brooke Paige. Ballotpedia's
// is the fuller spelling and carries a per-person article URL, so it is what a new row is
// seeded with; AP's spelling is kept beside it so the feed can still be matched to the row.
//
// The match ladder, strongest first. Nothing below the first rung is accepted without a read:
//   1. ANCHORED       AP says incumbent AND office_current_holder names that person for THIS seat.
//   2. EXACT          exactly one ACTIVE politician whose full name equals AP's or Ballotpedia's.
//   3. NEAR           first+last agree but the middle name differs — reported, never auto-taken.
//   4. NEW            nothing matches.
// 🔴 Rung 2 is a HYPOTHESIS, not a finding: the TX-22 winner was the incumbent's twin brother.
//    Every rung-2 and rung-3 row is printed with what that politician currently holds, and
//    three were thrown out on that read alone — see decisions.json.
import fs from 'node:fs';
const SP = process.argv[2];
const g = JSON.parse(fs.readFileSync(`${SP}/gap-ballots.json`, 'utf8'));
const pols = JSON.parse(fs.readFileSync(`${SP}/all-politicians.json`, 'utf8'));
const holders = JSON.parse(fs.readFileSync(`${SP}/holders.json`, 'utf8'));
const pairs = JSON.parse(fs.readFileSync(`${SP}/bp-pairs.json`, 'utf8'));
const decisions = JSON.parse(fs.readFileSync(`${SP}/decisions.json`, 'utf8'));

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
const SUF = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);
const loose = s => { const t = norm(s).split(' ').filter(w => !SUF.has(w)); return t.length < 2 ? (t[0] || '') : `${t[0]} ${t[t.length - 1]}`; };

const byExact = new Map(), byLoose = new Map();
const push = (m, k, v) => { if (!k) return; if (!m.has(k)) m.set(k, []); m.get(k).push(v); };
for (const p of pols) { push(byExact, norm(p.full_name), p); push(byLoose, loose(p.full_name), p); }
const holderByOffice = new Map(holders.map(h => [h.office_id, h]));
const pairByKey = new Map(pairs.map(p => [`${p.st}|${p.office}|${p.apId}`, p]));
const decByKey = new Map(decisions.map(d => [`${d.st}|${d.office}|${d.apId}`, d]));

const WRITEIN = /\s*\(write-in\)\s*$/i;
const rows = [];
for (const r of g) {
  for (const c of r.candidates) {
    if (c.apId === '100008') continue;
    const apName = c.name.replace(WRITEIN, '').trim();
    const key = `${r.st}|${r.office}|${c.apId}`;
    const bp = pairByKey.get(key);
    if (!bp) throw new Error(`no Ballotpedia pairing for ${key} — the cross-check and the resolver disagree`);
    const name = bp.bpName;                                     // the spelling a new row gets
    const isWriteIn = WRITEIN.test(c.name) || bp.bpWriteIn;

    const keys = [...new Set([norm(name), norm(apName)])];
    const exact = [...new Map(keys.flatMap(k => byExact.get(k) ?? []).map(p => [p.id, p])).values()];
    const nearAll = [...new Map([...new Set(keys.map(loose))].flatMap(k => byLoose.get(k) ?? []).map(p => [p.id, p])).values()];
    const near = nearAll.filter(p => !exact.some(e => e.id === p.id));
    const activeExact = exact.filter(p => p.is_active);
    const holder = holderByOffice.get(r.ourOfficeId);
    const holderLoose = !!holder && [...new Set(keys.map(loose))].includes(loose(holder.full_name));

    let verdict, politicianId = null;
    if (c.incumbent && holderLoose)    { verdict = 'ANCHORED';       politicianId = holder.politician_id; }
    else if (holderLoose)              { verdict = 'HOLDS-SEAT-AP-SAYS-NOT-INCUMBENT'; politicianId = holder.politician_id; }
    else if (c.incumbent)              { verdict = 'AP-INCUMBENT-SEAT-HELD-BY-OTHER'; }
    else if (activeExact.length === 1) { verdict = 'EXACT';          politicianId = activeExact[0].id; }
    else if (activeExact.length > 1)   { verdict = `${activeExact.length}-ACTIVE-EXACT`; }
    else if (exact.length >= 1)        { verdict = `${exact.length}-ARCHIVED-EXACT`; }
    else if (near.length)              { verdict = `NEAR-${near.length}`; }
    else                               { verdict = 'NEW'; }

    // a recorded human decision overrides the ladder, and must say why
    const d = decByKey.get(key);
    if (d) {
      if (!d.why) throw new Error(`decision for ${key} carries no reason`);
      if (d.politicianId === null) { verdict = 'NEW (ruled: ' + d.why + ')'; politicianId = null; }
      else { verdict = 'MATCHED-BY-HAND (' + d.why + ')'; politicianId = d.politicianId; }
    }

    rows.push({
      st: r.st, office: r.office, apRace: r.apRace, ourOfficeId: r.ourOfficeId, ourTitle: r.ourTitle,
      apId: c.apId, apName, name, bpUrl: bp.bpUrl, party: c.party, bpParty: bp.bpParty,
      pct: c.pct, votes: c.votes, result: c.winner ? 'won' : 'lost',
      apIncumbent: c.incumbent, isWriteIn, seatHolder: holder ? holder.full_name : null,
      verdict, politicianId,
      exact: exact.map(p => ({ id: p.id, full_name: p.full_name, is_active: p.is_active })),
      near:  near .map(p => ({ id: p.id, full_name: p.full_name, is_active: p.is_active })),
    });
  }
}
fs.writeFileSync(`${SP}/resolved.json`, JSON.stringify(rows, null, 1));

const tally = {};
for (const x of rows) { const k = x.verdict.replace(/ \(.*/, ''); tally[k] = (tally[k] || 0) + 1; }
console.log(`candidacies: ${rows.length}`);
for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(4)}  ${k}`);
const sum = Object.values(tally).reduce((a, b) => a + b, 0);
if (sum !== rows.length) throw new Error(`BUCKETS DO NOT SUM: ${sum} vs ${rows.length}`);
console.log(`  (sum ${sum} ✔)`);
console.log(`\nresolved to an existing person: ${rows.filter(x => x.politicianId).length}`);
console.log(`to be seeded:                   ${rows.filter(x => !x.politicianId).length}`);
console.log(`winners: ${rows.filter(x => x.result === 'won').length} (must be 73)`);

// 🔴 A NEW person whose name collides with an existing row is a DELIBERATE act, not an oversight.
const collide = rows.filter(x => !x.politicianId && (x.exact.length || x.near.length));
console.log(`\n=== ${collide.length} NEW person(s) whose name already exists on another row ===`);
for (const x of collide) console.log(`  ${x.st} ${x.office}: seed "${x.name}" — db already has ${[...x.exact, ...x.near].map(p => `"${p.full_name}" ${p.id}`).join(', ')}`);

const unresolved = rows.filter(x => !x.politicianId && !/^NEW/.test(x.verdict));
if (unresolved.length) { console.log(`\n🔴 ${unresolved.length} candidacy(ies) neither matched nor ruled NEW:`); for (const x of unresolved) console.log(`  ${x.st} ${x.office} "${x.name}" -> ${x.verdict}`); }
