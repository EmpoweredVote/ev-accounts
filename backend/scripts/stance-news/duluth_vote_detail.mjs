const client='duluth-mn';
const get=async(u)=>{const r=await fetch(u);if(!r.ok)throw new Error(`${r.status} ${u}`);return r.json();};
const events=await get(`https://webapi.legistar.com/v1/${client}/events?$filter=EventBodyId+eq+138+and+EventDate+ge+datetime'2025-01-01'&$orderby=EventDate+desc&$top=40`);
const want=new Set(['26-0092R','26-0105R','25-035-O','25-036-O','25-0995R','25-032-O','25-0891R','25-0784R','25-016-O','25-015-O']);
for(const e of events){
  let items; try{items=await get(`https://webapi.legistar.com/v1/${client}/events/${e.EventId}/eventitems?AgendaNote=0&MinutesNote=0`);}catch{continue;}
  for(const it of items){
    if(!want.has(it.EventItemMatterFile))continue;
    let votes; try{votes=await get(`https://webapi.legistar.com/v1/${client}/eventitems/${it.EventItemId}/votes`);}catch{continue;}
    if(!Array.isArray(votes)||!votes.length)continue;
    console.log('='.repeat(70));
    console.log(`${(e.EventDate||'').slice(0,10)}  ${it.EventItemMatterFile}  matterId=${it.EventItemMatterId}`);
    console.log('TITLE:', (it.EventItemTitle||'').replace(/\s+/g,' '));
    console.log('ACTION:', it.EventItemActionName, '|', (it.EventItemActionText||'').replace(/\s+/g,' ').slice(0,300));
    for(const v of votes) console.log(`   ${v.VoteValueName.padEnd(8)} ${v.VotePersonName}`);
  }
}
