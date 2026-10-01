#!/usr/bin/env node
/**
 * The Sheriff and the Chancery Clerk run their own sites, outside the county CMS.
 * NOTE: harrisoncountysheriff.com SOFT-404s -- a bogus path returns HTTP 200 after redirecting
 * to /404?requestedPage=... -- so status is meaningless there and the FINAL URL is what is read.
 */
const UA = { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' };
const SITES = [
  ['sheriff',  'https://www.harrisoncountysheriff.com/',        'Matt Haley'],
  ['chancery', 'http://harrisoncountymschanceryclerk.gov/',     'Angela Thrash'],
];
for (const [slug, url, who] of SITES) {
  try {
    const r = await fetch(url, { headers: UA, redirect: 'follow' });
    const html = await r.text();
    const softly404 = /\/404\?/.test(r.url);
    const text = html.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ');
    console.log('='.repeat(70));
    console.log(`${slug}  HTTP ${r.status}  ${html.length} chars  final=${r.url}${softly404 ? '  [SOFT-404]' : ''}`);
    console.log(`  names "${who}": ${text.includes(who) ? 'YES' : 'no'}   surname: ${text.includes(who.split(' ').pop()) ? 'YES' : 'no'}`);
    const imgs = [...html.matchAll(/<img\b[^>]*>/gi)].map(m => {
      const s = /src\s*=\s*["']([^"']+)["']/i.exec(m[0]);
      const a = /alt\s*=\s*["']([^"']*)["']/i.exec(m[0]);
      return s ? { src: new URL(s[1], r.url).href, alt: a ? a[1] : null } : null;
    }).filter(Boolean).filter(i => !/logo|icon|sprite|banner|badge-?bg|facebook|twitter|instagram/i.test(i.src));
    console.log(`  ${imgs.length} candidate images:`);
    for (const i of imgs.slice(0, 18)) console.log(`     ${i.src}\n        alt=${JSON.stringify(i.alt)}`);
    // links that might lead to a bio/portrait page
    const links = [...html.matchAll(/href\s*=\s*["']([^"']+)["'][^>]*>([^<]{2,50})</gi)]
      .filter(m => /sheriff|about|meet|biography|staff|administration|clerk/i.test(m[1] + ' ' + m[2]))
      .map(m => `${m[2].trim()} -> ${new URL(m[1], r.url).href}`);
    console.log('  bio-ish links:'); for (const l of [...new Set(links)].slice(0, 10)) console.log('     ' + l);
  } catch (e) { console.log(slug, 'ERROR', e.message); }
}
