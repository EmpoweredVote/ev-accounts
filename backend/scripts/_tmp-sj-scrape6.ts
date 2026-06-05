import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

async function fetchHtml(url: string): Promise<{html: string, status: number}> {
  try {
    const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url }, redirect: 'follow' });
    if (resp.status !== 200) return { html: '', status: resp.status };
    return { html: await resp.text(), status: 200 };
  } catch (e: any) {
    return { html: `ERROR: ${e.message}`, status: 0 };
  }
}

function findSquarespaceImgs(html: string, nameHint: string): void {
  const allImgs: Array<{url: string, alt: string}> = [];

  // data-src pattern
  const dsRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/[^"]+\.(jpg|jpeg|png))"/gi;
  let m;
  while ((m = dsRe.exec(html)) !== null) {
    const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 200));
    const altM = ctx.match(/alt="([^"]*)"/);
    allImgs.push({ url: m[1], alt: altM ? altM[1] : '' });
  }
  // src pattern
  const srcRe = /src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/[^"]+\.(jpg|jpeg|png))"/gi;
  while ((m = srcRe.exec(html)) !== null) {
    const ctx = html.substring(Math.max(0, m.index - 200), Math.min(html.length, m.index + 200));
    const altM = ctx.match(/alt="([^"]*)"/);
    allImgs.push({ url: m[1], alt: altM ? altM[1] : '' });
  }

  const lower = nameHint.toLowerCase();
  const parts = lower.split(' ').filter(p => p.length > 3);
  const seen = new Set<string>();

  // Score each image
  const scored = allImgs
    .filter(i => {
      if (seen.has(i.url)) return false;
      seen.add(i.url);
      return true;
    })
    .filter(i => !/logo|map|banner|icon|facebook|instagram|twitter|signature|email|youtube|newsletter|nextdoor|award/i.test(i.url + i.alt))
    .map(i => {
      let score = 0;
      const urlL = i.url.toLowerCase();
      const altL = i.alt.toLowerCase();
      if (parts.some(p => urlL.includes(p) || altL.includes(p))) score += 10;
      if (/headshot|portrait|photo|official|bio|about|cm\+|councilmember/i.test(urlL + altL)) score += 5;
      if (/landing|hero|banner|building|city.hall|map|district/i.test(urlL + altL)) score -= 3;
      return { ...i, score };
    })
    .sort((a, b) => b.score - a.score);

  if (scored.length === 0) {
    console.log('  No images found');
    return;
  }
  scored.slice(0, 6).forEach(i => console.log(`  [score=${i.score}] ${i.url.replace('https://images.squarespace-cdn.com', '')} | "${i.alt.substring(0,80)}"`));
}

async function main() {
  // D5 Ortiz - check /about page
  console.log('\n=== Ortiz D5 /about ===');
  const { html: html5a, status: s5a } = await fetchHtml('https://www.sjdistrict5.org/about');
  console.log('Status:', s5a);
  if (s5a === 200) findSquarespaceImgs(html5a, 'Peter Ortiz');
  await new Promise(r => setTimeout(r, 400));

  // D7 Doan - check /about-councilmember-doan
  console.log('\n=== Doan D7 /about-councilmember-doan ===');
  const { html: html7a, status: s7a } = await fetchHtml('https://www.sjdistrict7.org/about-councilmember-doan');
  console.log('Status:', s7a);
  if (s7a === 200) findSquarespaceImgs(html7a, 'Bien Doan');
  await new Promise(r => setTimeout(r, 400));

  // D7 also try /about_me
  console.log('\n=== Doan D7 /about_me ===');
  const { html: html7b, status: s7b } = await fetchHtml('https://www.sjdistrict7.org/about_me');
  console.log('Status:', s7b);
  if (s7b === 200) findSquarespaceImgs(html7b, 'Bien Doan');
  await new Promise(r => setTimeout(r, 400));

  // D10 Casey /meet-our-team
  console.log('\n=== Casey D10 /meet-our-team ===');
  const { html: html10a, status: s10a } = await fetchHtml('https://www.sjdistrict10.org/meet-our-team');
  console.log('Status:', s10a);
  if (s10a === 200) findSquarespaceImgs(html10a, 'George Casey');
  await new Promise(r => setTimeout(r, 400));

  // D2 Campos - sjdistrict2.org /about
  console.log('\n=== Campos D2 /about ===');
  const { html: html2a, status: s2a } = await fetchHtml('https://www.sjdistrict2.org/about');
  console.log('Status:', s2a);
  if (s2a === 200) findSquarespaceImgs(html2a, 'Pamela Campos');
  await new Promise(r => setTimeout(r, 400));

  // D3 Tordillos - sjdistrict3.org (only one page)
  // Let's see all images (already found "Website Landing Image" - could be a portrait)
  console.log('\n=== Tordillos D3 ALL images ===');
  const { html: html3 } = await fetchHtml('https://www.sjdistrict3.org');
  findSquarespaceImgs(html3, 'Anthony Tordillos');
  await new Promise(r => setTimeout(r, 400));

  // D8 Candelas - try Wikimedia Commons search via API
  console.log('\n=== Candelas D8 Wikimedia ===');
  const wikiResp = await fetch('https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=Domingo+Candelas&format=json&srnamespace=6', {
    headers: HEADERS
  });
  const wikiData: any = await wikiResp.json();
  console.log('Commons results:', wikiData?.query?.search?.map((r: any) => r.title).slice(0, 5));

  // D9 Foley - try to find headshot via API or Wikimedia
  console.log('\n=== Foley D9 Wikimedia ===');
  const wikiF = await fetch('https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=Pam+Foley+San+Jose&format=json&srnamespace=6', {
    headers: HEADERS
  });
  const wikiFData: any = await wikiF.json();
  console.log('Commons results:', wikiFData?.query?.search?.map((r: any) => r.title).slice(0, 5));

  // Check D9 Foley on Wikipedia
  const wpF = await fetch('https://en.wikipedia.org/w/api.php?action=query&titles=Pam_Foley&prop=pageimages&format=json&pithumbsize=600', {
    headers: HEADERS
  });
  const wpFData: any = await wpF.json();
  const fpages = wpFData?.query?.pages;
  if (fpages) {
    for (const p of Object.values(fpages) as any[]) {
      console.log(`  WP: ${p.title}, thumb: ${p.thumbnail?.source}`);
    }
  }

  // D8 Candelas on Wikipedia
  const wpC = await fetch('https://en.wikipedia.org/w/api.php?action=query&titles=Domingo_Candelas&prop=pageimages&format=json&pithumbsize=600', {
    headers: HEADERS
  });
  const wpCData: any = await wpC.json();
  const cpages = wpCData?.query?.pages;
  if (cpages) {
    for (const p of Object.values(cpages) as any[]) {
      console.log(`  WP Candelas: ${p.title}, thumb: ${p.thumbnail?.source}`);
    }
  }

  // Mahan - check the specific portrait
  console.log('\n=== Mahan Mayor (Wikimedia verify) ===');
  // Check actual Wikimedia commons page for Matt Mahan
  const wikiMahanSearch = await fetch('https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=Matt+Mahan+mayor&format=json&srnamespace=6', {
    headers: HEADERS
  });
  const wikiMahanData: any = await wikiMahanSearch.json();
  console.log('Commons Mahan:', wikiMahanData?.query?.search?.map((r: any) => r.title).slice(0, 5));

  // Check the Matt_Mahan_portrait_2025 file
  const mahanInfoResp = await fetch('https://commons.wikimedia.org/w/api.php?action=query&titles=File:Matt_Mahan_portrait_2025.jpg&prop=imageinfo&iiprop=url|extmetadata&format=json', {
    headers: HEADERS
  });
  const mahanInfoData: any = await mahanInfoResp.json();
  const mahanPages = mahanInfoData?.query?.pages;
  if (mahanPages) {
    for (const p of Object.values(mahanPages) as any[]) {
      const ii = p.imageinfo?.[0];
      console.log(`  File: ${p.title}`);
      console.log(`  URL: ${ii?.url}`);
      console.log(`  License: ${ii?.extmetadata?.LicenseShortName?.value}`);
    }
  }
}

main().catch(console.error);
