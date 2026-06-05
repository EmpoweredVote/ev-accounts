import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': '*/*',
};
const TMP_DIR = process.env.TEMP || 'C:/Windows/Temp';

async function getWikimediaFileInfo(filename: string): Promise<{url: string, license: string}> {
  const url = `https://commons.wikimedia.org/w/api.php?action=query&titles=File:${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url|extmetadata&format=json`;
  const resp = await fetch(url, { headers: HEADERS });
  const data: any = await resp.json();
  const pages = data?.query?.pages;
  if (pages) {
    for (const p of Object.values(pages) as any[]) {
      const ii = p.imageinfo?.[0];
      return { url: ii?.url || '', license: ii?.extmetadata?.LicenseShortName?.value || 'unknown' };
    }
  }
  return { url: '', license: '' };
}

async function searchWikimediaCommons(query: string): Promise<void> {
  const resp = await fetch(`https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&format=json&srnamespace=6&srlimit=5`, {
    headers: HEADERS
  });
  const data: any = await resp.json();
  console.log(`  Commons search "${query}":`);
  data?.query?.search?.forEach((r: any) => console.log(`    ${r.title}`));
}

async function download(name: string, url: string): Promise<void> {
  const resp = await fetch(url, { headers: { ...HEADERS, 'Referer': url } });
  if (resp.status !== 200) { console.log(`  Download failed: ${resp.status}`); return; }
  const buf = Buffer.from(await resp.arrayBuffer());
  const ext = url.toLowerCase().includes('.png') ? 'png' : 'webp';
  const tmpFile = path.join(TMP_DIR, `sj-preview2-${name}.${ext}`);
  fs.writeFileSync(tmpFile, buf);
  console.log(`  Downloaded: ${buf.length} bytes → ${tmpFile}`);
}

async function main() {
  // D3 Tordillos - search Wikimedia
  console.log('\n=== D3 Tordillos sources ===');
  await searchWikimediaCommons('Anthony Tordillos San Jose');
  await searchWikimediaCommons('Tordillos councilmember');
  await new Promise(r => setTimeout(r, 300));

  // Also check sjdistrict3.org for any sub-pages
  const resp3 = await fetch('https://www.sjdistrict3.org', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict3.org/' }
  });
  const html3 = await resp3.text();
  const navLinks = html3.match(/href="(\/[^"]+)"/g);
  const unique3 = [...new Set(navLinks?.map(l => l.replace(/href="(\/[^"]+)"/, '$1')) || [])];
  console.log('  D3 nav links:', unique3.filter(l => !l.includes('?') && l.length > 1).slice(0, 10));

  await new Promise(r => setTimeout(r, 300));

  // D4 Cohen - search Wikimedia, check about page
  console.log('\n=== D4 Cohen sources ===');
  await searchWikimediaCommons('David Cohen San Jose councilmember');
  await searchWikimediaCommons('David Cohen San Jose District 4');

  // Check sanjosedistrict4.com about page
  const resp4a = await fetch('https://www.sanjosedistrict4.com/about', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjosedistrict4.com/' }
  });
  console.log('  D4 /about status:', resp4a.status);
  if (resp4a.status === 200) {
    const html4a = await resp4a.text();
    const dsRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/6201a5e40577d74133ad4cad\/[^"]+\.(jpg|jpeg|png))"/gi;
    let m;
    while ((m = dsRe.exec(html4a)) !== null) {
      if (!/logo|map|banner|icon/i.test(m[1])) console.log('  ', m[1].replace('https://images.squarespace-cdn.com', ''));
    }
  }

  await new Promise(r => setTimeout(r, 400));

  // D7 Doan - check sjdistrict7.org/about-councilmember-doan and about_me
  console.log('\n=== D7 Doan sources ===');
  await searchWikimediaCommons('Bien Doan San Jose council');

  const resp7a = await fetch('https://www.sjdistrict7.org/about-councilmember-doan', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict7.org/' }
  });
  console.log('  D7 /about-councilmember-doan status:', resp7a.status);
  if (resp7a.status === 200) {
    const html7a = await resp7a.text();
    const dsRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/67e5a8b8296f5a5a0214b875\/[^"]+\.(jpg|jpeg|png))"/gi;
    let m;
    while ((m = dsRe.exec(html7a)) !== null) {
      if (!/logo|map|banner|icon/i.test(m[1])) {
        const ctx = html7a.substring(Math.max(0, m.index-200), Math.min(html7a.length, m.index+200));
        const altM = ctx.match(/alt="([^"]*)"/);
        console.log(`  ${m[1].replace('https://images.squarespace-cdn.com/content/v1/67e5a8b8296f5a5a0214b875/', '')} | alt: "${altM?.[1] || ''}"`);
      }
    }
  }
  await new Promise(r => setTimeout(r, 400));

  // D10 Casey - look for about/meet page
  console.log('\n=== D10 Casey sources ===');
  await searchWikimediaCommons('George Casey San Jose council');

  const resp10a = await fetch('https://www.sjdistrict10.org/meet-casey', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict10.org/' }
  });
  console.log('  D10 /meet-casey status:', resp10a.status);
  if (resp10a.status !== 200) {
    // Try /about
    const resp10b = await fetch('https://www.sjdistrict10.org/about', {
      headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict10.org/' }
    });
    console.log('  D10 /about status:', resp10b.status);
    if (resp10b.status === 200) {
      const html10b = await resp10b.text();
      const dsRe = /data-src="(https:\/\/images\.squarespace-cdn\.com\/content\/v1\/67d36df71d3cca0e7ebe4c0e\/[^"]+\.(jpg|jpeg|png))"/gi;
      let m;
      while ((m = dsRe.exec(html10b)) !== null) {
        if (!/logo|map|banner|icon|placeholder/i.test(m[1])) {
          const ctx = html10b.substring(Math.max(0, m.index-200), Math.min(html10b.length, m.index+200));
          const altM = ctx.match(/alt="([^"]*)"/);
          console.log(`  ${m[1].replace('https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/', '')} | alt: "${altM?.[1] || ''}"`);
        }
      }
    }
  }
  await new Promise(r => setTimeout(r, 400));

  // D2 Campos - "Councilmember+Campos+and+Constituent.jpg" is portrait ratio (1066x1409)
  // That's actually a good option if it shows Campos clearly. Let's also search Wikimedia.
  console.log('\n=== D2 Campos sources ===');
  await searchWikimediaCommons('Pamela Campos San Jose council');
  // Also check sjdistrict2.org for more pages
  const resp2 = await fetch('https://www.sjdistrict2.org', {
    headers: { ...HEADERS, 'Referer': 'https://www.sjdistrict2.org/' }
  });
  const html2 = await resp2.text();
  const navLinks2 = html2.match(/href="(\/[^"]+)"/g);
  const unique2 = [...new Set(navLinks2?.map(l => l.replace(/href="(\/[^"]+)"/, '$1')) || [])];
  console.log('  D2 nav links:', unique2.filter(l => !l.includes('?') && l.length > 1).slice(0, 10));

  // Get Ortiz Wikimedia info
  console.log('\n=== D5 Ortiz Wikimedia ===');
  const ortizInfo = await getWikimediaFileInfo('Peter Ortiz, San José City Councilman.png');
  console.log(`  URL: ${ortizInfo.url}`);
  console.log(`  License: ${ortizInfo.license}`);

  // Download Ortiz for size check
  if (ortizInfo.url) await download('D5-Ortiz-wiki', ortizInfo.url);
}

main().catch(console.error);
