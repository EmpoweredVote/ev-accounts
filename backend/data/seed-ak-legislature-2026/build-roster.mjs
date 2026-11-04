import fs from 'fs';
const J=f=>JSON.parse(fs.readFileSync(f,'utf8'));
const MON={January:1,February:2,March:3,April:4,May:5,June:6,July:7,August:8,September:9,October:10,November:11,December:12};
const norm=s=>s.toLowerCase().replace(/[.""']/g,'').replace(/\s+/g,' ').trim();

function parseAssumed(raw){
  let m=raw.match(/^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})$/);
  if(m) return {date:`${m[3]}-${String(MON[m[1]]).padStart(2,'0')}-${String(+m[2]).padStart(2,'0')}`,precision:'day',raw};
  m=raw.match(/^(\d{4})$/);
  if(m) return {date:`${m[1]}-01-01`,precision:'year',raw};
  throw new Error('unparsed assumed-office value: '+JSON.stringify(raw));
}
const SEN='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const out=[];
for(const [ch,akf,bpf] of [['House','house.json','bp_house.json'],['Senate','senate.json','bp_senate.json']]){
  const ak=J(akf), bp=new Map(J(bpf).map(r=>[String(r.district),r]));
  for(const a of ak){
    const b=bp.get(String(a.district));
    if(!b) throw new Error('no ballotpedia row for '+ch+' '+a.district);
    const t=parseAssumed(b.assumed);
    const alt = norm(a.name)!==norm(b.name) ? [b.name] : [];
    const dnum = ch==='House' ? Number(a.district) : SEN.indexOf(a.district)+1;
    out.push({
      chamber: ch,
      district_code: a.district,
      geo_id: ch==='House' ? '02'+String(a.district).padStart(3,'0') : '0200'+a.district,
      mtfcc: ch==='House' ? 'G5220' : 'G5210',
      member_code: a.code,
      full_name: a.name,
      alternate_names: alt,
      party_akleg: a.party,
      party_ballotpedia: b.party,
      home_city: a.city,
      leadership: a.position,
      term_start: t.date,
      start_precision: t.precision,
      assumed_raw: t.raw,
      bp_link: b.link,
      portrait: `https://akleg.gov/images/legislators/450x600/${a.code.toUpperCase()}.jpg`,
      paired_senate: ch==='House' ? SEN[Math.ceil(dnum/2)-1] : null,
      paired_house: ch==='Senate' ? [2*dnum-1, 2*dnum] : null,
    });
  }
}
fs.writeFileSync('roster-final.json', JSON.stringify(out,null,2));
console.log('total', out.length);
console.log('House', out.filter(r=>r.chamber==='House').length, 'Senate', out.filter(r=>r.chamber==='Senate').length);
const prec={}; out.forEach(r=>prec[r.start_precision]=(prec[r.start_precision]||0)+1);
console.log('precision', JSON.stringify(prec));
const ts={}; out.forEach(r=>ts[r.term_start]=(ts[r.term_start]||0)+1);
console.log('term_start values', JSON.stringify(ts,null,0));
console.log('with alternate names:', out.filter(r=>r.alternate_names.length).map(r=>`${r.full_name} / ${r.alternate_names[0]}`).join(' | '));
console.log('year-precision rows:', out.filter(r=>r.start_precision==='year').map(r=>`${r.chamber} ${r.district_code} ${r.full_name} (${r.assumed_raw})`).join(' | '));
console.log('geo_id samples:', out.filter((_,i)=>i<2||i===40).map(r=>r.chamber+' '+r.district_code+' -> '+r.mtfcc+'/'+r.geo_id).join(' | '));
