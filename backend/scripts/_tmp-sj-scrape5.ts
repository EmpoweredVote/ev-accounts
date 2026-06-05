import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.5',
};

async function fetchHtml(url: string): Promise<string> {
  const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url }, redirect: 'follow' });
  if (resp.status !== 200) {
    console.log(`  Status ${resp.status}`);
    return '';
  }
  return resp.text();
}

function findImgWithContext(html: string, nameHint: string): void {
  // Look for squarespace data-src images with useful context
  const patterns = [
    /data-src="(https:\/\/images\.squarespace-cdn\.com[^"]+)"[^>]*data-image="[^"]*"[^>]*>[\s\S]{0,200}/g,
    /"(https:\/\/images\.squarespace-cdn\.com[^"]+\.(jpg|jpeg|png)[^"]*)"/g,
    /<img[^>]+src="([^"]*squarespace[^"]+)"[^>]*alt="([^"]*)"/gi,
  ];

  const allUrls = new Map<string, string>(); // url -> alt text or context

  // Find data-src pattern
  const dsRegex = /data-src="(https:\/\/images\.squarespace-cdn\.com[^"]+)"/g;
  let m;
  while ((m = dsRegex.exec(html)) !== null) {
    const start = Math.max(0, m.index - 100);
    const end = Math.min(html.length, m.index + 400);
    const ctx = html.substring(start, end).replace(/\s+/g, ' ');
    const altMatch = ctx.match(/alt="([^"]*)"/);
    const alt = altMatch ? altMatch[1] : '';
    allUrls.set(m[1], alt);
  }

  // Find regular src pattern too
  const srcRegex = /<img[^>]+src="(https:\/\/images\.squarespace-cdn\.com[^"]+)"[^>]*alt="([^"]*)"/gi;
  while ((m = srcRegex.exec(html)) !== null) {
    allUrls.set(m[1], m[2]);
  }

  // Filter for potentially interesting images (portraits/headshots)
  const lower = nameHint.toLowerCase();
  const nameParts = lower.split(' ');
  const interestingEntries: Array<[string, string]> = [];
  for (const [url, alt] of allUrls) {
    const urlLower = url.toLowerCase();
    const altLower = alt.toLowerCase();
    // Skip logos, maps, banners
    if (/logo|map|banner|icon|facebook|instagram|twitter|signature|email/i.test(url + alt)) continue;
    // Prioritize if name appears in URL or alt
    const hasName = nameParts.some(p => p.length > 3 && (urlLower.includes(p) || altLower.includes(p)));
    if (hasName || /headshot|portrait|photo|official|councilmember|council.member|cm\+|d[0-9]+\+/i.test(url + alt)) {
      interestingEntries.push([url, alt]);
    }
  }

  // If nothing found with name, show first 5 non-logo images
  if (interestingEntries.length === 0) {
    let count = 0;
    for (const [url, alt] of allUrls) {
      if (/logo|map|banner|icon|facebook|instagram|twitter|signature/i.test(url + alt)) continue;
      console.log(`  [non-logo] ${url} | alt: "${alt}"`);
      if (++count >= 8) break;
    }
  } else {
    interestingEntries.forEach(([url, alt]) => {
      console.log(`  [MATCH] ${url} | alt: "${alt}"`);
    });
  }
}

async function main() {
  // D2 Campos - sjdistrict2.org
  console.log('\n=== Campos D2 (sjdistrict2.org) ===');
  const html2 = await fetchHtml('https://www.sjdistrict2.org');
  findImgWithContext(html2, 'Pamela Campos');

  await new Promise(r => setTimeout(r, 400));

  // D3 Tordillos - specific image URL found
  console.log('\n=== Tordillos D3 (sjdistrict3.org) ===');
  const html3 = await fetchHtml('https://www.sjdistrict3.org');
  // We know: "Website Landing Image" but that might be a hero photo
  // Look for about page or bio page
  const aboutLinks3 = html3.match(/href="[^"]*(?:about|bio|meet|anthony|tordillos)[^"]*"/gi);
  console.log('  About links:', aboutLinks3?.slice(0, 5));
  findImgWithContext(html3, 'Anthony Tordillos');

  await new Promise(r => setTimeout(r, 400));

  // Check sjdistrict3.org/about
  console.log('\n=== Tordillos D3 /about ===');
  const html3a = await fetchHtml('https://www.sjdistrict3.org/about');
  findImgWithContext(html3a, 'Anthony Tordillos');

  await new Promise(r => setTimeout(r, 400));

  // D4 Cohen
  console.log('\n=== Cohen D4 (sanjosedistrict4.com) ===');
  const html4 = await fetchHtml('https://www.sanjosedistrict4.com');
  // cohen+at+city+hall+2.jpg looks like a real photo
  const aboutLinks4 = html4.match(/href="[^"]*(?:about|bio|meet|david|cohen)[^"]*"/gi);
  console.log('  About links:', aboutLinks4?.slice(0, 5));
  findImgWithContext(html4, 'David Cohen');

  await new Promise(r => setTimeout(r, 400));

  // D5 Ortiz - has "Brisa+Headshot" which is likely staff not Ortiz
  console.log('\n=== Ortiz D5 (sjdistrict5.org) ===');
  const html5 = await fetchHtml('https://www.sjdistrict5.org');
  const aboutLinks5 = html5.match(/href="[^"]*(?:about|bio|meet|peter|ortiz)[^"]*"/gi);
  console.log('  About links:', aboutLinks5?.slice(0, 5));
  findImgWithContext(html5, 'Peter Ortiz');

  await new Promise(r => setTimeout(r, 400));

  // D7 Doan
  console.log('\n=== Doan D7 (sjdistrict7.org) ===');
  const html7 = await fetchHtml('https://www.sjdistrict7.org');
  const aboutLinks7 = html7.match(/href="[^"]*(?:about|bio|meet|bien|doan)[^"]*"/gi);
  console.log('  About links:', aboutLinks7?.slice(0, 5));
  findImgWithContext(html7, 'Bien Doan');

  await new Promise(r => setTimeout(r, 400));

  // D9 Foley - from D9 main page we saw logo but no portrait
  // Try the about/meet page
  console.log('\n=== Foley D9 ===');
  const htmlF = await fetchHtml('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9');
  const aboutLinksF = htmlF.match(/href="[^"]*(?:about|bio|meet|foley|pam)[^"]*"/gi);
  console.log('  sanjoseca.gov D9 about links:', aboutLinksF?.slice(0, 5));

  // D10 Casey
  console.log('\n=== Casey D10 (sjdistrict10.org) ===');
  const html10 = await fetchHtml('https://www.sjdistrict10.org');
  const aboutLinks10 = html10.match(/href="[^"]*(?:about|bio|meet|george|casey)[^"]*"/gi);
  console.log('  About links:', aboutLinks10?.slice(0, 5));
  findImgWithContext(html10, 'George Casey');

  await new Promise(r => setTimeout(r, 400));

  // D8 Candelas - check wikimedia
  console.log('\n=== Candelas D8 (Wikimedia search) ===');
  const wikiResp = await fetch('https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=Domingo+Candelas+San+Jose+councilmember&format=json', {
    headers: HEADERS
  });
  const wikiData: any = await wikiResp.json();
  console.log('  Wiki results:', wikiData?.query?.search?.map((r: any) => r.title)?.slice(0,3));

  // Matt Mahan - use known Wikimedia URL
  console.log('\n=== Mahan Mayor (Wikimedia check) ===');
  const mahanUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg';
  const mahanResp = await fetch(mahanUrl, { method: 'HEAD', headers: HEADERS });
  console.log(`  Wikimedia ${mahanUrl}: ${mahanResp.status}`);
  // Also check commons page
  const wikiMahanResp = await fetch('https://en.wikipedia.org/w/api.php?action=query&titles=Matt_Mahan&prop=pageimages&format=json&pithumbsize=600', {
    headers: HEADERS
  });
  const wikiMahan: any = await wikiMahanResp.json();
  const pages = wikiMahan?.query?.pages;
  if (pages) {
    for (const p of Object.values(pages) as any[]) {
      console.log(`  Wiki page: ${p.title}, thumbnail: ${p.thumbnail?.source}`);
    }
  }
}

main().catch(console.error);
