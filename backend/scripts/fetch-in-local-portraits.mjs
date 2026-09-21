/**
 * fetch-in-local-portraits.mjs — download the matched local/county portrait candidates.
 * Matches come from harvest.json by NAME BESIDE THE IMAGE (see harvest-in-local-portraits.mjs).
 * Nothing here decides a match; this only fetches what the matcher chose, and records bytes,
 * magic number and status so a decoy body cannot pass as a portrait.
 */
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
const UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
const OUT='data/seed-in-local-headshots-2026'; mkdirSync(`${OUT}/raw`,{recursive:true});
const sniff=b=>b.length>=3&&b[0]==0xff&&b[1]==0xd8&&b[2]==0xff?'jpg'
 :b.length>=8&&b.subarray(0,8).equals(Buffer.from([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]))?'png'
 :b.length>=12&&b.subarray(0,4).toString('latin1')=='RIFF'&&b.subarray(8,12).toString('latin1')=='WEBP'?'webp'
 :b.length>=4&&b.subarray(0,4).toString('latin1')=='GIF8'?'gif':null;
const matches=JSON.parse(readFileSync(`${OUT}/matches.json`,'utf8'));
const b=await chromium.launch(); const c=await b.newContext({userAgent:UA});
const rows=[];
for (const m of matches){
  if(!m.cands.length){ rows.push({...m, status:'NO CANDIDATE'}); continue; }
  const cand=m.cands[0];
  const slug=m.name.toLowerCase().replace(/[^a-z]+/g,'-').replace(/^-|-$/g,'');
  try{
    const r=await c.request.get(cand.src,{failOnStatusCode:false});
    const buf=Buffer.from(await r.body()); const fmt=sniff(buf);
    const rec={gov:m.gov,title:m.title,name:m.name,slug,page:cand.page,src:cand.src,
               near:cand.near,status:r.status(),bytes:buf.length,format:fmt};
    if(fmt){ rec.file=`${slug}.${fmt}`; writeFileSync(`${OUT}/raw/${rec.file}`,buf); }
    else rec.note='NOT AN IMAGE';
    rows.push(rec);
  }catch(e){ rows.push({...m,status:`THREW ${e}`}); }
}
await b.close();
writeFileSync(`${OUT}/fetched.json`,JSON.stringify(rows,null,1));
console.log(`fetched ${rows.filter(r=>r.file).length} of ${rows.length}`);
