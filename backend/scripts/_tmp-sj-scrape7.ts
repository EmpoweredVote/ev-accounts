import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': '*/*',
};

async function getWikimediaFileInfo(filename: string): Promise<void> {
  const url = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const resp = await fetch(url, { headers: HEADERS });
  const data: any = await resp.json();
  const pages = data?.query?.pages;
  if (pages) {
    for (const p of Object.values(pages) as any[]) {
      const ii = p.imageinfo?.[0];
      console.log(`  ${filename}`);
      console.log(`    URL: ${ii?.url}`);
      console.log(`    License: ${ii?.extmetadata?.LicenseShortName?.value}`);
      console.log(`    Attribution: ${ii?.extmetadata?.Attribution?.value}`);
    }
  }
}

async function main() {
  console.log('\n=== Wikimedia file lookups ===');
  await getWikimediaFileInfo('Domingo Candelas, San José City Councilman.png');
  await new Promise(r => setTimeout(r, 200));
  await getWikimediaFileInfo('Foley Pam - San José City Councilwoman.jpg');
  await new Promise(r => setTimeout(r, 200));
  await getWikimediaFileInfo('Matt Mahan portrait 2025.jpg');
  await new Promise(r => setTimeout(r, 200));

  // Verify D10 Casey image
  console.log('\n=== Casey D10 portrait URL check ===');
  const caseyUrl = 'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg';
  const caseyResp = await fetch(caseyUrl, { method: 'HEAD', headers: HEADERS });
  console.log(`  Status: ${caseyResp.status}, Content-Type: ${caseyResp.headers.get('content-type')}`);

  // Verify D4 Cohen "cohen at city hall" image
  console.log('\n=== Cohen D4 portrait URL check ===');
  const cohenUrl = 'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/756eaf72-18b7-44b0-9036-3a560af75d95/cohen+at+city+hall+2.jpg';
  const cohenResp = await fetch(cohenUrl, { method: 'HEAD', headers: HEADERS });
  console.log(`  Status: ${cohenResp.status}, Content-Type: ${cohenResp.headers.get('content-type')}`);

  // Download and check D3 Tordillos image - is it a photo or a logo?
  console.log('\n=== Tordillos D3 landing image check ===');
  const tordillosUrl = 'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/265abb99-2103-4102-83ed-303e5b4034e3/Website+Landing+Image.png';
  const tResp = await fetch(tordillosUrl, { method: 'HEAD', headers: HEADERS });
  console.log(`  Status: ${tResp.status}, Content-Type: ${tResp.headers.get('content-type')}, Content-Length: ${tResp.headers.get('content-length')}`);

  // Check actual content (first bytes) to see if it's a real photo
  const tBodyResp = await fetch(tordillosUrl, { headers: HEADERS });
  if (tBodyResp.status === 200) {
    const buf = Buffer.from(await tBodyResp.arrayBuffer());
    console.log(`  File size: ${buf.length} bytes`);
    // Check if PNG has data (large = likely photo, small = likely icon)
    console.log(`  File type: ${buf[0] === 0x89 && buf[1] === 0x50 ? 'PNG' : buf[0] === 0xff && buf[1] === 0xd8 ? 'JPEG' : 'other'}`);
  }

  // D5 Ortiz - search Wikimedia as fallback
  console.log('\n=== Ortiz D5 Wikimedia ===');
  const wikiOrtiz = await fetch('https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=Peter+Ortiz+San+Jose+council&format=json&srnamespace=6', {
    headers: HEADERS
  });
  const wikiOrtizData: any = await wikiOrtiz.json();
  console.log('Commons Ortiz:', wikiOrtizData?.query?.search?.map((r: any) => r.title).slice(0, 3));

  // D2 Campos sjdistrict2.org main page - try to find portrait
  console.log('\n=== Campos D2 portrait ===');
  const htmlC = await (await fetch('https://www.sjdistrict2.org', { headers: HEADERS, redirect: 'follow' })).text();
  const dsRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/6942f53c3db83d0e41471664\/[^"]+\.(jpg|jpeg|png))"/gi;
  let m;
  const imgs: string[] = [];
  while ((m = dsRe.exec(htmlC)) !== null) imgs.push(m[1]);
  // also src
  const srcRe = /src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/6942f53c3db83d0e41471664\/[^"]+\.(jpg|jpeg|png))"/gi;
  while ((m = srcRe.exec(htmlC)) !== null) imgs.push(m[1]);
  const unique = [...new Set(imgs)].filter(u => !/logo|map|banner|icon|email|signature/i.test(u));
  unique.slice(0,8).forEach(u => console.log(`  ${u.replace('https://images.squarespace-cdn.com', '')}`));

  // D6 Mulcahy - verify URL
  console.log('\n=== Mulcahy D6 image verify ===');
  const mulcahyUrl = 'https://www.sanjoseca.gov/home/showpublishedimage/23362/639001978590570000';
  const mulcahyResp = await fetch(mulcahyUrl, {
    headers: {
      ...HEADERS,
      'Referer': 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember',
    }
  });
  console.log(`  Status: ${mulcahyResp.status}, Type: ${mulcahyResp.headers.get('content-type')}`);
  if (mulcahyResp.status === 200) {
    const buf = Buffer.from(await mulcahyResp.arrayBuffer());
    console.log(`  Size: ${buf.length} bytes`);
  }

  // D1 Kamei - verify
  console.log('\n=== Kamei D1 image verify ===');
  const kameiUrl = 'https://www.sanjoseca.gov/home/showpublishedimage/18393/638145599495300000';
  const kameiResp = await fetch(kameiUrl, {
    headers: {
      ...HEADERS,
      'Referer': 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei',
    }
  });
  console.log(`  Status: ${kameiResp.status}, Type: ${kameiResp.headers.get('content-type')}`);
  if (kameiResp.status === 200) {
    const buf = Buffer.from(await kameiResp.arrayBuffer());
    console.log(`  Size: ${buf.length} bytes`);
  }
}

main().catch(console.error);
