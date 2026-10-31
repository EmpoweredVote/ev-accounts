import fs from 'fs';
const dec=s=>s.replace(/<[^>]*>/g,'').replace(/&amp;/g,'&').replace(/&#0?39;|&apos;/g,"'")
 .replace(/&quot;/g,'"').replace(/&nbsp;/g,' ').replace(/\s+/g,' ').trim();

function table(file, chamber){
  const s=fs.readFileSync(file,'utf8');
  const t=s.indexOf('id="officeholder-table"');
  if(t<0) throw new Error('no officeholder-table in '+file);
  const end=s.indexOf('</table>', t);
  const body=s.slice(t,end);
  const rows=[...body.matchAll(/<tr>([\s\S]*?)<\/tr>/g)].map(m=>m[1]);
  const out=[];
  for(const r of rows){
    const tds=[...r.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map(m=>m[1]);
    if(tds.length<4) continue;
    const office=dec(tds[0]), name=dec(tds[1]), party=dec(tds[2]), date=dec(tds[3]);
    const dm=office.match(/District\s+([0-9]+|[A-T])\s*$/);
    out.push({chamber, office, district: dm?dm[1]:null, name, party,
      assumed: date, link: (tds[1].match(/href="([^"]+)"/)||[])[1]||null});
  }
  return out;
}
const H=table('bp_house.html','House'), S=table('bp_senate.html','Senate');
for(const [ch,rows] of [['House',H],['Senate',S]]){
  console.log(`\n=== Ballotpedia ${ch}: ${rows.length} rows`);
  console.log('null districts:', rows.filter(r=>!r.district).map(r=>r.office).join(' | ')||'none');
  const d=rows.map(r=>r.district);
  console.log('dupes:', d.filter((x,i,a)=>a.indexOf(x)!==i).join(',')||'NONE');
  const noDate=rows.filter(r=>!/\d{4}/.test(r.assumed));
  console.log('rows without a year in the date:', noDate.length?noDate.map(r=>r.name+' ["'+r.assumed+'"]').join(' | '):'none');
  const yrs={}; rows.forEach(r=>{const m=r.assumed.match(/(\w+ \d+, )?(\d{4})/); yrs[r.assumed.replace(/^\w+ \d+, /,'')]=(yrs[r.assumed.replace(/^\w+ \d+, /,'')]||0)+1;});
  console.log('assumed-office values:', JSON.stringify(Object.fromEntries(Object.entries(yrs).sort())));
  fs.writeFileSync('bp_'+ch.toLowerCase()+'.json', JSON.stringify(rows,null,2));
}
