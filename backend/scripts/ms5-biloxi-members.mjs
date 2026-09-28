#!/usr/bin/env node
/** Pull the council page's own links: the member pages, and the full-size portrait files. */
const URL_ = 'https://biloxi.ms.us/departments/city-council/';
const html = await (await fetch(URL_, { headers: { 'User-Agent': 'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)' } })).text();

console.log('--- links to 2025/08 uploads (the FULL-SIZE portraits the thumbnails link to) ---');
for (const m of html.matchAll(/href\s*=\s*"([^"]*wp-content\/uploads\/2025\/08\/[^"]*)"/gi)) console.log('  ' + m[1]);

console.log('\n--- srcset widths offered for each displayed portrait ---');
for (const m of html.matchAll(/<img\b[^>]*src\s*=\s*"([^"]*2025\/06\/[^"]*)"[^>]*?(?:srcset\s*=\s*"([^"]*)")?[^>]*>/gi)) {
  console.log('  ' + m[1].split('/').pop());
  if (m[2]) for (const p of m[2].split(',')) console.log('      ' + p.trim());
}

console.log('\n--- member page links (council members only) ---');
const seen = new Set();
for (const m of html.matchAll(/href\s*=\s*"(https:\/\/biloxi\.ms\.us\/[^"]*)"[^>]*>([^<]{2,60})</gi)) {
  const [, href, text] = m;
  if (!/ward|council|mayor/i.test(href + ' ' + text)) continue;
  const k = href + '|' + text.trim();
  if (seen.has(k)) continue; seen.add(k);
  console.log(`  ${text.trim().padEnd(28)} ${href}`);
}
