// Match OUR candidate rows against AP's own ballot for every called US Senate and US House
// race, so a loser is recorded because AP lists them and they did not win -- never because they
// are "not the winner" in our data. That inference is what would have marked Lindsey Graham,
// who died before the election, as having lost it.
import fs from 'node:fs';
const SP = process.argv[2];
const ballots = JSON.parse(fs.readFileSync(`${SP}/ap-ballots-2026-11-04.json`, 'utf8'));
const ours = JSON.parse(fs.readFileSync(`${SP}/ours.json`, 'utf8'));

// A row with no first name whose surname is exactly "Total Write-ins" is AP's AGGREGATE of
// uncounted write-ins -- not a person. A NAMED write-in ("Parkman (write-in)") IS a person and
// must still be matched; the discriminator is the exact string, not the words "write in".
const isAggregate = c => c.first == null && c.last === 'Total Write-ins';

const norm = s => (s || '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase()
  .replace(/\(write-?in\)/g, ' ')
  .replace(/"[^"]*"/g, ' ').replace(/[‘’'`]/g, '')
  .replace(/\b(jr|sr|ii|iii|iv)\b\.?/g, ' ')
  .replace(/[^a-z ]/g, ' ')
  .replace(/\s+/g, ' ').trim();

const key = r => r.office === 'S' ? `S:${r.state || r.st}` : `H:${r.geo_id}`;

const ourByRace = new Map();
for (const r of ours) {
  const k = key(r);
  if (!ourByRace.has(k)) ourByRace.set(k, []);
  ourByRace.get(k).push(r);
}

const losers = [], already = [], unmatchedOurs = [], seedingGaps = [], ambiguous = [], noRace = [];
const winnerMismatch = [];

for (const race of ballots) {
  if (race.winnerCount !== 1) continue;             // only CALLED races
  const k = key(race);
  const pool = ourByRace.get(k);
  if (!pool) { noRace.push({ seat: race.seat, office: race.office, why: 'no race of ours for this key' }); continue; }

  const apReal = race.candidates.filter(c => !isAggregate(c));
  const usedOurs = new Set();

  for (const c of apReal) {
    const apLast = norm(c.last), apFirst = norm(c.first), apFull = norm(c.name);
    const scored = pool.map(o => {
      const ourLast = norm(o.last_name), ourFirst = norm(o.first_name), ourFull = norm(o.full_name);
      let tier = null;
      if (ourLast === apLast) tier = 'last-exact';
      else if (ourLast.endsWith(' ' + apLast) || apLast.endsWith(' ' + ourLast)) tier = 'last-suffix';
      else if (ourFull.endsWith(' ' + apLast) || ourFull === apFull) tier = 'fullname-tail';
      return { o, tier, ourFirst, ourFull };
    }).filter(x => x.tier);

    let best = null;
    for (const t of ['last-exact', 'last-suffix', 'fullname-tail']) {
      const g = scored.filter(x => x.tier === t);
      if (g.length === 1) { best = g[0]; break; }
      if (g.length > 1) {
        const fn = g.filter(x => x.ourFirst === apFirst || x.ourFirst.startsWith(apFirst + ' ') || apFirst.startsWith(x.ourFirst + ' '));
        if (fn.length === 1) { best = fn[0]; break; }
        ambiguous.push({ seat: race.seat, ap: c.name, tier: t, ours: g.map(x => x.o.full_name) });
        best = 'AMBIG'; break;
      }
    }
    if (best === 'AMBIG') continue;
    if (!best) { seedingGaps.push({ seat: race.seat, office: race.office, ap: c.name, party: c.party, pct: c.votePct, votes: c.voteCount, winner: c.winner, apCandidateID: c.apCandidateID }); continue; }

    usedOurs.add(best.o.rc_id);
    const rec = {
      office: race.office, seat: race.seat, geo_id: race.geo_id, state: race.state,
      apRaceID: race.apRaceID, calledAt: race.candidates.find(x => x.winner)?.calledAt || null,
      ap: { name: c.name, first: c.first, last: c.last, party: c.party, votePct: c.votePct, voteCount: c.voteCount, apCandidateID: c.apCandidateID },
      ours: { rc_id: best.o.rc_id, race_id: best.o.race_id, pol_id: best.o.pol_id, full_name: best.o.full_name,
              first_name: best.o.first_name, last_name: best.o.last_name, party: best.o.party,
              existing_result: best.o.existing_result, existing_certainty: best.o.existing_certainty,
              existing_source: best.o.existing_source },
      tier: best.tier,
      spellingDiffers: norm(best.o.full_name) !== apFull,
    };

    if (c.winner) {
      if (best.o.existing_result !== 'won') winnerMismatch.push(rec);
      already.push(rec);
    } else if (best.o.existing_result === 'won') {
      winnerMismatch.push({ ...rec, why: 'our row says WON but AP lists this candidate as a non-winner' });
    } else {
      losers.push(rec);
    }
  }

  for (const o of pool) {
    if (usedOurs.has(o.rc_id)) continue;
    unmatchedOurs.push({ seat: race.seat, office: race.office, full_name: o.full_name, party: o.party,
                         rc_id: o.rc_id, existing_result: o.existing_result, is_active: o.is_active });
  }
}

const w = (f, v) => fs.writeFileSync(`${SP}/${f}`, JSON.stringify(v, null, 2));
w('losers.json', losers);
w('losers-review.json', losers.filter(l => l.spellingDiffers));
w('unmatched-ours.json', unmatchedOurs);
w('seeding-gaps.json', seedingGaps);
w('ambiguous.json', ambiguous);
w('winner-mismatch.json', winnerMismatch);

const calledRaces = ballots.filter(r => r.winnerCount === 1);
console.log('called races                      :', calledRaces.length);
console.log('AP candidates on them (real)      :', calledRaces.reduce((a, r) => a + r.candidates.filter(c => !isAggregate(c)).length, 0));
console.log('  of which aggregates skipped     :', calledRaces.reduce((a, r) => a + r.candidates.filter(isAggregate).length, 0));
console.log('LOSERS to record                  :', losers.length, `(S ${losers.filter(l => l.office === 'S').length}, H ${losers.filter(l => l.office === 'H').length})`);
console.log('  needing review (spelling differs):', losers.filter(l => l.spellingDiffers).length);
console.log('winners already recorded, re-matched:', already.length);
console.log('🔴 winner disagreements           :', winnerMismatch.length);
console.log('🔴 ambiguous matches              :', ambiguous.length);
console.log('AP candidates we do not hold      :', seedingGaps.length);
console.log('our rows AP does not list         :', unmatchedOurs.length);
const dup = Object.entries(losers.reduce((a, l) => ((a[l.ours.rc_id] = (a[l.ours.rc_id] || 0) + 1), a), {})).filter(([, n]) => n > 1);
console.log('rc_id used twice                  :', dup.length);
console.log('existing result on losers         :', JSON.stringify(losers.reduce((a, l) => ((a[l.ours.existing_result || '<null>'] = (a[l.ours.existing_result || '<null>'] || 0) + 1), a), {})));
