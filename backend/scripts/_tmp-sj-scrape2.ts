import 'dotenv/config';

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/your-government/city-council',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

async function checkPage(name: string, url: string) {
  console.log(`\n=== ${name} ===`);
  console.log(`URL: ${url}`);
  const resp = await fetch(url, { headers: HEADERS });
  console.log(`Status: ${resp.status}`);
  if (resp.status !== 200) return;
  const html = await resp.text();

  // Find all showpublishedimage URLs with context
  const regex = /showpublishedimage\/(\d+)\/(\d+)/g;
  let m;
  const seen = new Set<string>();
  while ((m = regex.exec(html)) !== null) {
    const key = `${m[1]}/${m[2]}`;
    if (seen.has(key)) continue;
    seen.add(key);
    // Get surrounding context
    const start = Math.max(0, m.index - 150);
    const end = Math.min(html.length, m.index + 200);
    const ctx = html.substring(start, end).replace(/\s+/g, ' ');
    console.log(`  Image ${m[1]}/${m[2]}: ...${ctx}...`);
  }
}

async function main() {
  // Try alternate URLs for districts that 404'd
  const tests = [
    ['Kamei D1', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei'],
    ['Tordillos D3 - NID', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/-NID-285'],
    ['Tordillos D3 - alternate', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3'],
    ['Cohen D4', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-4'],
    ['Ortiz D5', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5'],
    ['Doan D7', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-7'],
    ['Candelas D8', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-8'],
    ['Foley D9', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9'],
    ['Casey D10', 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-10'],
  ];

  for (const [name, url] of tests) {
    await checkPage(name, url);
    await new Promise(r => setTimeout(r, 300));
  }
}

main().catch(console.error);
