import fs from 'fs';
const dec = s => s.replace(/&amp;/g,'&').replace(/&#0?39;|&apos;|&rsquo;/g,"'")
  .replace(/&quot;/g,'"').replace(/&nbsp;/g,' ').replace(/&lt;/g,'<').replace(/&gt;/g,'>')
  .replace(/<[^>]*>/g,'').replace(/\s+/g,' ').trim();

const DL = {
  District: /<dt>\s*District\s*:?\s*<\/dt>\s*<dd>([\s\S]*?)<\/dd>/i,
  Party:    /<dt>\s*Party\s*:?\s*<\/dt>\s*<dd>([\s\S]*?)<\/dd>/i,
  City:     /<dt>\s*City\s*:?\s*<\/dt>\s*<dd>([\s\S]*?)<\/dd>/i,
};
const SPAN = {
  District: /<li>\s*District\s*:?\s*<span>([\s\S]*?)<\/span>/i,
  Party:    /<li>\s*Party\s*:?\s*<span>([\s\S]*?)<\/span>/i,
  City:     /<li>\s*City\s*:?\s*<span>([\s\S]*?)<\/span>/i,
};
const NAME1 = /<strong class="name">([\s\S]*?)<\/strong>/i;
const NAME2 = /<span class="name"[^>]*>([\s\S]*?)<\/(?:strong|span)>/i;
const POS   = /<span class="position">([\s\S]*?)<\/span>/i;
const IMG   = /<img src="([^"]+)"/i;
const ANCH  = /\/basis\/Member\/Detail\/(\d+)\?code=([a-zA-Z0-9]+)"/g;

function occurrences(file, chamber){
  const s = fs.readFileSync(file,'utf8');
  const anchors = [...s.matchAll(ANCH)];
  const out = [];
  for (let i=0;i<anchors.length;i++){
    const a = anchors[i], start = a.index;
    const end = i+1 < anchors.length ? anchors[i+1].index : Math.min(s.length, start+3000);
    const w = s.slice(start, end);
    const get = k => { const m = w.match(DL[k]) || w.match(SPAN[k]); return m ? dec(m[1]) : null; };
    const nm = w.match(NAME1) || w.match(NAME2);
    out.push({ chamber, legislature: a[1], code: a[2].toLowerCase(),
      name: nm ? dec(nm[1]) : null,
      district: get('District'), party: get('Party'), city: get('City'),
      position: (w.match(POS)||[])[1] ? dec(w.match(POS)[1]) : null,
      image: (w.match(IMG)||[])[1] || null });
  }
  return out;
}

const result = {};
for (const [f,ch] of [['house.html','House'],['senate.html','Senate']]) {
  const occ = occurrences(f,ch);
  const by = new Map(); const conflicts = [];
  for (const o of occ) {
    if (!by.has(o.code)) by.set(o.code, { chamber:ch, legislature:o.legislature, code:o.code, images:new Set() });
    const r = by.get(o.code);
    for (const k of ['name','district','party','city','position']) {
      if (o[k] == null) continue;
      if (r[k] == null) r[k] = o[k];
      else if (r[k] !== o[k]) conflicts.push(`${o.code}.${k}: "${r[k]}" vs "${o[k]}"`);
    }
    if (o.image) r.images.add('https:' + o.image.replace(/^https?:/,''));
  }
  const u = [...by.values()].map(r => ({...r, images:[...r.images]}));
  console.log(`\n=== ${ch}: ${occ.length} occurrences -> ${u.length} members (${new Set(u.map(r=>r.legislature)).size===1?'leg '+u[0].legislature:'MIXED LEG'})`);
  console.log('field conflicts across listings:', conflicts.length ? conflicts.join(' | ') : 'NONE');
  const incomplete = u.filter(r=>!r.district||!r.party||!r.city||!r.name);
  console.log('incomplete:', incomplete.length ? incomplete.map(r=>r.code).join(',') : 'none');
  const d = u.map(r=>r.district);
  console.log('districts:', d.slice().sort((a,b)=>a.localeCompare(b,undefined,{numeric:true})).join(' '));
  console.log('duplicate districts:', d.filter((x,i,ar)=>ar.indexOf(x)!==i).join(',') || 'NONE');
  const p={}; u.forEach(r=>p[r.party]=(p[r.party]||0)+1);
  console.log('parties:', JSON.stringify(p));
  console.log('image dirs:', [...new Set(u.flatMap(r=>r.images).map(x=>x.replace(/[^/]*$/,'')))].join(' '));
  result[ch]=u;
  fs.writeFileSync(ch.toLowerCase()+'.json', JSON.stringify(u,null,2));
}
