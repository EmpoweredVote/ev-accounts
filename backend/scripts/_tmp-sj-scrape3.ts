import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/your-government/city-council',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

async function checkPage(name: string, url: string) {
  console.log(`\n=== ${name} ===`);
  const resp = await fetch(url, { headers: HEADERS });
  console.log(`Status: ${resp.status}`);
  if (resp.status !== 200) return;
  const html = await resp.text();

  // Find showpublishedimage with portrait/headshot context
  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const seen = new Set<string>();
  const portraits: string[] = [];
  while ((m = regex.exec(html)) !== null) {
    const key = `${m[1]}/${m[2]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const start = Math.max(0, m.index - 250);
    const end = Math.min(html.length, m.index + 150);
    const ctx = html.substring(start, end).replace(/\s+/g, ' ');
    // Only show images that look like portraits (have alt text with name or "councilmember" etc)
    if (/alt="[^"]*(?:portrait|headshot|photo|councilmember|council member|mayor|district|[A-Z][a-z]+\s[A-Z][a-z]+)/i.test(ctx)) {
      portraits.push(`  PORTRAIT ${key}: ...${ctx}...`);
    }
  }
  if (portraits.length > 0) {
    portraits.forEach(p => console.log(p));
  } else {
    console.log('  No portrait images found');
    // Show squarespace or other img patterns
    const sqsp = html.match(/squarespace-cdn[^"']*/g);
    if (sqsp) console.log('  Squarespace imgs:', sqsp.slice(0,3));
  }
}

async function main() {
  // Try the main city council page which often has all official portraits
  await checkPage('Main council page', 'https://www.sanjoseca.gov/your-government/city-council');
  await new Promise(r => setTimeout(r, 300));

  // Try alternate Tordillos URL
  await checkPage('Tordillos D3 - NID-285', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/-NID-285');
  await new Promise(r => setTimeout(r, 300));

  // Check if the D3 page has links to external sites
  const resp = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3', { headers: HEADERS });
  const html3 = await resp.text();
  // Find links to sub-pages/external sites
  const links3 = html3.match(/href="[^"]*tordillos[^"]*"/gi);
  const ext3 = html3.match(/href="https?:\/\/(?!www\.sanjoseca)[^"]+"/gi);
  console.log('\n=== D3 external links ===');
  if (links3) console.log('Tordillos links:', links3);
  if (ext3) console.log('External:', ext3.slice(0,5));

  await new Promise(r => setTimeout(r, 300));

  // Similarly for D4-D10
  for (const [dist, name] of [['4','Cohen'],['5','Ortiz'],['7','Doan'],['9','Foley'],['10','Casey']]) {
    const r2 = await fetch(`https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-${dist}`, { headers: HEADERS });
    const h2 = await r2.text();
    const regex2 = /showpublishedimage\/(\d+)\/(\d+)/g;
    let m2;
    const found: string[] = [];
    const seen2 = new Set<string>();
    while ((m2 = regex2.exec(h2)) !== null) {
      const k = `${m2[1]}/${m2[2]}`;
      if (seen2.has(k)) continue;
      seen2.add(k);
      const start = Math.max(0, m2.index - 200);
      const end = Math.min(h2.length, m2.index + 150);
      const ctx = h2.substring(start, end).replace(/\s+/g, ' ');
      if (/alt="[^"]*(?:portrait|headshot|photo|councilmember|council member|mayor|district|[A-Z][a-z]+\s[A-Z][a-z]+)/i.test(ctx)) {
        found.push(`  ${k}: ${ctx}`);
      }
    }
    const ext = h2.match(/href="https?:\/\/(?!www\.sanjoseca)[^"]+"/gi);
    console.log(`\n=== D${dist} ${name} external links ===`);
    if (ext) console.log('External links:', ext.slice(0,5));
    if (found.length > 0) found.forEach(f => console.log('  PORTRAIT:', f));
    await new Promise(r => setTimeout(r, 200));
  }
}

main().catch(console.error);
