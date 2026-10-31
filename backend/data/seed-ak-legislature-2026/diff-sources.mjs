import fs from 'fs';
const J=f=>JSON.parse(fs.readFileSync(f,'utf8'));
const norm=s=>s.toLowerCase().replace(/[.""']/g,'').replace(/\s+/g,' ')
  .replace(/\b(jr|sr|ii|iii|iv)\b/g,'').replace(/\s+/g,' ').trim();
const last=s=>{const t=norm(s).split(' ').filter(Boolean);return t[t.length-1];};

for(const [ch,akf,bpf] of [['House','house.json','bp_house.json'],['Senate','senate.json','bp_senate.json']]){
  const ak=J(akf), bp=J(bpf);
  const akBy=new Map(ak.map(r=>[String(r.district),r]));
  const bpBy=new Map(bp.map(r=>[String(r.district),r]));
  console.log(`\n===== ${ch}  akleg=${ak.length}  ballotpedia=${bp.length}`);
  const keys=[...new Set([...akBy.keys(),...bpBy.keys()])].sort((a,b)=>a.localeCompare(b,undefined,{numeric:true}));
  console.log('districts only in akleg:',[...akBy.keys()].filter(k=>!bpBy.has(k)).join(',')||'none');
  console.log('districts only in BP   :',[...bpBy.keys()].filter(k=>!akBy.has(k)).join(',')||'none');
  const nameDiff=[], partyDiff=[];
  for(const k of keys){
    const a=akBy.get(k), b=bpBy.get(k); if(!a||!b) continue;
    if(norm(a.name)!==norm(b.name)) nameDiff.push({d:k,ak:a.name,bp:b.name,sameLast:last(a.name)===last(b.name)});
    const ap=(a.party||'').toLowerCase(), bpp=(b.party||'').toLowerCase();
    const map=p=>p.startsWith('republic')?'R':p.startsWith('democrat')?'D':p.startsWith('independ')?'I':p.startsWith('not affil')?'N':p||'?';
    if(map(ap)!==map(bpp)) partyDiff.push({d:k,ak:a.party,bp:b.party});
  }
  console.log(`name disagreements: ${nameDiff.length}`);
  nameDiff.forEach(x=>console.log(`   D${x.d}: akleg "${x.ak}"  vs  BP "${x.bp}"   sameSurname=${x.sameLast}`));
  console.log(`party disagreements: ${partyDiff.length}`);
  partyDiff.forEach(x=>console.log(`   D${x.d}: akleg "${x.ak}"  vs  BP "${x.bp}"`));
}
