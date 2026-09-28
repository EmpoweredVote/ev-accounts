#!/usr/bin/env node
/** Read each member page: resolve the Ward 3 name, and find the mayor's portrait. */
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const pages = [
  ['ward-3', 'https://biloxi.ms.us/city-council-ward-3/'],
  ['mayor',  'https://biloxi.ms.us/departments/mayor/'],
  ['CONTROL','https://biloxi.ms.us/city-council-ward-99/'],
];
for (const [name, url] of pages) {
  const r = await fetch(url, { headers: UA });
  const html = await r.text();
  const text = html.replace(/<script[\s\S]*?<\/script>/gi,' ').replace(/<style[\s\S]*?<\/style>/gi,' ')
                   .replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g,' ').replace(/&#\d+;/g,"'").replace(/\s+/g,' ').trim();
  console.log('='.repeat(74));
  console.log(name, r.status, html.length + ' chars', r.url);
  if (name === 'CONTROL') { console.log('  (control: must be 404)'); console.log(''); continue; }
  // The page's own prose, where a legal name and a used name would both appear.
  const i = text.search(/Council|Mayor/);
  console.log('TEXT:', text.slice(Math.max(0,i), i + 900));
  console.log('IMAGES:');
  for (const m of html.matchAll(/<img\b[^>]*>/gi)) {
    const src = /src\s*=\s*"([^"]*)"/i.exec(m[0]);
    const alt = /alt\s*=\s*"([^"]*)"/i.exec(m[0]);
    if (src && /uploads/i.test(src[1]) && !/tile|button|logo|footer/i.test(src[1]))
      console.log('   ' + src[1] + '   alt=' + JSON.stringify(alt ? alt[1] : null));
  }
  console.log('');
}
