import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
// Usage: node quoted_passages.mjs <slug> [url-to-skip ...]
// Prints every passage near the member's name that contains a quotation mark — i.e. everything the
// STRICT attribution rule dropped. README: re-read what the strict rule drops.
const SLUG=process.argv[2];
if(!SLUG){console.error('usage: quoted_passages.mjs <slug> [url-to-skip ...]');process.exit(1);}
const DIR=(process.env.SWEEP_OUT||'data/stance-news')+'/'+SLUG;
const key=(u)=>crypto.createHash('sha1').update(u).digest('hex').slice(0,24);
const idx=JSON.parse(fs.readFileSync(path.join(DIR,'_index.json'),'utf8'));
const SKIP=new Set(process.argv.slice(3));
for(const a of idx){
  if(SKIP.has(a.url)) continue;
  let t; try{t=fs.readFileSync(path.join(DIR,key(a.url)+'.txt'),'utf8');}catch{continue;}
  const hits=[];
  let i=-1;
  const SURNAME=JSON.parse(fs.readFileSync(path.join(DIR,'_index.json'),'utf8')) && (process.env.SURNAME || SLUG[0].toUpperCase()+SLUG.slice(1));
  while((i=t.indexOf(SURNAME,i+1))!==-1){
    const w=t.slice(Math.max(0,i-320),i+420);
    if(!/"/.test(w)) continue;
    hits.push(w);
  }
  if(!hits.length) continue;
  // de-dup overlapping windows
  const out=[]; for(const h of hits){ if(out.some(o=>o.includes(h.slice(50,150)))) continue; out.push(h); }
  console.log('#'.repeat(78));
  console.log(a.url);
  out.slice(0,3).forEach(h=>{console.log('  ...'+h.trim()+'...');console.log('');});
}
