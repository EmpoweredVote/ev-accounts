import fs from 'node:fs';
const SP = process.argv[2];
const ap = JSON.parse(fs.readFileSync(`${SP}/ap-house-calls-2026-11-04.json`,'utf8'));
const ours = JSON.parse(fs.readFileSync(`${SP}/ours.json`,'utf8'));

const FIPS={AL:'01',AK:'02',AZ:'04',AR:'05',CA:'06',CO:'08',CT:'09',DE:'10',FL:'12',GA:'13',HI:'15',ID:'16',IL:'17',IN:'18',IA:'19',KS:'20',KY:'21',LA:'22',ME:'23',MD:'24',MA:'25',MI:'26',MN:'27',MS:'28',MO:'29',MT:'30',NE:'31',NV:'32',NH:'33',NJ:'34',NM:'35',NY:'36',NC:'37',ND:'38',OH:'39',OK:'40',OR:'41',PA:'42',RI:'44',SC:'45',SD:'46',TN:'47',TX:'48',UT:'49',VT:'50',VA:'51',WA:'53',WV:'54',WI:'55',WY:'56'};

// Normalise for comparison only. Accents are folded HERE because unaccent is not on prod.
const norm = s => (s||'')
  .normalize('NFD').replace(/[̀-ͯ]/g,'')
  .toLowerCase()
  .replace(/"[^"]*"/g,' ').replace(/[‘’'`]/g,'')
  .replace(/\b(jr|sr|ii|iii|iv)\b\.?/g,' ')
  .replace(/[^a-z ]/g,' ')
  .replace(/\s+/g,' ').trim();

const byGeo = new Map();
for (const r of ours) {
  if (!byGeo.has(r.geo_id)) byGeo.set(r.geo_id, []);
  byGeo.get(r.geo_id).push(r);
}

const matched=[], review=[], problems=[], noCall=[];
for (const race of ap) {
  const geo = (FIPS[race.state]||'??') + race.district2;
  if (!race.winner) { noCall.push(race); continue; }
  const pool = byGeo.get(geo);
  if (!pool) { problems.push({geo, race, why:'no race in our data for this geo_id'}); continue; }
  const apLast = norm(race.winner.last), apFirst = norm(race.winner.first);
  const apFull = norm(race.winner.name);

  const scored = pool.map(c => {
    const ourLast = norm(c.last_name), ourFirst = norm(c.first_name), ourFull = norm(c.full_name);
    let tier = null;
    if (ourLast === apLast) tier = 'last-exact';
    else if (ourLast.endsWith(' '+apLast) || apLast.endsWith(' '+ourLast)) tier = 'last-suffix';
    else if (ourFull.endsWith(' '+apLast) || ourFull === apFull) tier = 'fullname-tail';
    return {c, tier, ourLast, ourFirst, ourFull};
  }).filter(x => x.tier);

  // Prefer the strongest tier; if several share it, require the first name to agree.
  const order=['last-exact','last-suffix','fullname-tail'];
  let best=null;
  for (const t of order) {
    const g = scored.filter(x=>x.tier===t);
    if (g.length===1) { best=g[0]; break; }
    if (g.length>1) {
      const fn = g.filter(x => x.ourFirst===apFirst || x.ourFirst.startsWith(apFirst+' ') || apFirst.startsWith(x.ourFirst+' '));
      if (fn.length===1) { best=fn[0]; break; }
      problems.push({geo, race, why:`${g.length} candidates tie at ${t}`, cands:g.map(x=>x.c.full_name)});
      best='AMBIG'; break;
    }
  }
  if (best==='AMBIG') continue;
  if (!best) { problems.push({geo, race, why:'no candidate in our race matches the AP winner', cands:pool.map(p=>p.full_name)}); continue; }

  const rec = { geo, state:race.state, district:race.district2, apRaceID:race.apRaceID,
    ap:{name:race.winner.name, first:race.winner.first, last:race.winner.last, party:race.winner.party,
        votePct:race.winner.votePct, voteCount:race.winner.voteCount, calledAt:race.winner.calledAt},
    ours:{rc_id:best.c.rc_id, race_id:best.c.race_id, pol_id:best.c.pol_id, full_name:best.c.full_name,
          first_name:best.c.first_name, last_name:best.c.last_name, party:best.c.party,
          existing_result:best.c.existing_result, existing_certainty:best.c.existing_certainty},
    tier:best.tier,
    spellingDiffers: norm(best.c.full_name) !== apFull };
  matched.push(rec);
  if (rec.spellingDiffers) review.push(rec);
}

fs.writeFileSync(`${SP}/matched.json`, JSON.stringify(matched,null,2));
fs.writeFileSync(`${SP}/review.json`, JSON.stringify(review,null,2));
fs.writeFileSync(`${SP}/problems.json`, JSON.stringify(problems,null,2));
console.log('AP races            :', ap.length);
console.log('AP called w/ winner :', ap.filter(r=>r.winner).length);
console.log('matched             :', matched.length);
console.log('NEEDS REVIEW (spelling differs):', review.length);
console.log('PROBLEMS (unmatched/ambiguous) :', problems.length);
console.log('races AP has not called        :', noCall.length);
const dupRace = Object.entries(matched.reduce((a,m)=>((a[m.ours.race_id]=(a[m.ours.race_id]||0)+1),a),{})).filter(([,n])=>n>1);
console.log('races with >1 matched winner   :', dupRace.length);
const dupRc = Object.entries(matched.reduce((a,m)=>((a[m.ours.rc_id]=(a[m.ours.rc_id]||0)+1),a),{})).filter(([,n])=>n>1);
console.log('rc_id used twice               :', dupRc.length);
const over = matched.filter(m=>m.ours.existing_result && m.ours.existing_result!=='won');
console.log('OVERWRITES existing result     :', over.length, JSON.stringify(over.reduce((a,m)=>((a[m.ours.existing_result]=(a[m.ours.existing_result]||0)+1),a),{})));
