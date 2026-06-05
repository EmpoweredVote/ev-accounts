import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.5',
};

async function scrapeSquarespace(name: string, url: string) {
  console.log(`\n=== ${name} ===`);
  console.log(`URL: ${url}`);
  try {
    const resp = await fetch(url, {
      headers: { ...HEADERS, 'Referer': url },
      redirect: 'follow'
    });
    console.log(`Status: ${resp.status}, Final URL: ${resp.url}`);
    if (resp.status !== 200) return;
    const html = await resp.text();

    // Look for portrait/headshot images in squarespace format
    // Squarespace images often: /content/.../filename.jpg?format=NNNw
    // or static1.squarespace.com
    const imgPatterns = [
      /static1\.squarespace\.com\/[^\s"']+\.(jpg|jpeg|png|webp)/gi,
      /squarespace-cdn\.com\/content\/[^\s"']+\.(jpg|jpeg|png|webp)/gi,
      /images\.squarespace-cdn\.com\/[^\s"']+\.(jpg|jpeg|png|webp)/gi,
    ];

    const allImgs = new Set<string>();
    for (const pat of imgPatterns) {
      const matches = html.matchAll(pat);
      for (const m of matches) {
        // Clean up the URL (remove format= and beyond or keep it)
        const rawUrl = m[0].replace(/\?.*$/, '');
        allImgs.add('https://' + rawUrl);
      }
    }

    // Also find JSON data in squarespace scripts
    const jsonMatches = html.match(/"url":"(https?:\/\/[^"]+squarespace[^"]+\.(jpg|jpeg|png|webp)[^"]*)"/gi);
    if (jsonMatches) {
      jsonMatches.slice(0,5).forEach(m => {
        const url = m.replace('"url":"', '').replace('"', '');
        allImgs.add(url);
      });
    }

    // Find image URLs with alt text context
    const imgWithAlt = html.match(/<img[^>]*(?:headshot|portrait|official|council|mayor|district|photo)[^>]*>/gi);
    if (imgWithAlt) {
      console.log(`  Alt-matched images:`);
      imgWithAlt.slice(0, 5).forEach(i => console.log(`    ${i.substring(0, 300)}`));
    }

    if (allImgs.size > 0) {
      console.log(`  Found ${allImgs.size} squarespace images:`);
      Array.from(allImgs).slice(0, 8).forEach(u => console.log(`    ${u}`));
    } else {
      console.log('  No squarespace images found');
      // Check for other image URLs
      const otherImgs = html.match(/src="(https?:\/\/[^"]+\.(jpg|jpeg|png))[^"]*"/gi);
      if (otherImgs) console.log('  Other imgs:', otherImgs.slice(0, 5));
    }
  } catch (err: any) {
    console.log(`  ERROR: ${err.message}`);
  }
}

async function main() {
  const sites = [
    ['Tordillos D3', 'https://www.sjdistrict3.org'],
    ['Cohen D4', 'https://www.sanjosedistrict4.com'],
    ['Ortiz D5', 'https://www.sjdistrict5.org'],
    ['Doan D7', 'https://www.sjdistrict7.org'],
    ['Casey D10', 'https://www.sjdistrict10.org'],
  ];
  for (const [name, url] of sites) {
    await scrapeSquarespace(name, url);
    await new Promise(r => setTimeout(r, 500));
  }

  // Also check D6 Mulcahy deeper (the page that had images was D6)
  console.log('\n=== Mulcahy D6 deeper ===');
  const resp6 = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjoseca.gov/' }
  });
  const html6 = await resp6.text();
  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  while ((m = regex.exec(html6)) !== null) {
    const start = Math.max(0, m.index - 250);
    const end = Math.min(html6.length, m.index + 200);
    const ctx = html6.substring(start, end).replace(/\s+/g, ' ');
    if (!/facebook|twitter|instagram|linkedin|youtube|nextdoor|IG Logo|Center for Digital/i.test(ctx)) {
      console.log(`  ${m[1]}/${m[2]}: ${ctx}`);
    }
  }

  // Check D9 Foley - look for a real portrait
  console.log('\n=== Foley D9 non-logo images ===');
  const resp9 = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9/your-councilmember', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjoseca.gov/' }
  });
  console.log('D9 /your-councilmember status:', resp9.status);

  // Also try Campos D2
  console.log('\n=== Campos D2 squarespace ===');
  const respC = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjoseca.gov/' }
  });
  const htmlC = await respC.text();
  const ext2 = htmlC.match(/href="https?:\/\/(?!www\.sanjoseca)[^"]+"/gi);
  console.log('D2 external links:', ext2?.slice(0, 5));
  // also check for squarespace
  const sqsp2 = htmlC.match(/squarespace-cdn[^"']*/g);
  if (sqsp2) console.log('Squarespace:', sqsp2.slice(0, 3));

  // Check D8 Candelas more carefully
  console.log('\n=== Candelas D8 links ===');
  const resp8 = await fetch('https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-8', {
    headers: { ...HEADERS, 'Referer': 'https://www.sanjoseca.gov/' }
  });
  const html8 = await resp8.text();
  const ext8 = html8.match(/href="https?:\/\/(?!www\.sanjoseca)[^"]+"/gi);
  console.log('D8 external links:', ext8?.slice(0, 5));
}

main().catch(console.error);
