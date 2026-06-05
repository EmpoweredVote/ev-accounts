import 'dotenv/config';

const OFFICIALS = [
  { name: 'Matt Mahan',         url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/mayor-s-office/-NID-282' },
  { name: 'Rosemary Kamei',     url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-1/the-team/rosemary-kamei' },
  { name: 'Pamela Campos',      url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-2/councilmember-pamela-campos-biography' },
  { name: 'Anthony Tordillos',  url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-3/your-councilmember' },
  { name: 'David Cohen',        url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-4/your-councilmember' },
  { name: 'Peter Ortiz',        url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-5/your-councilmember' },
  { name: 'Michael Mulcahy',    url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-6/your-councilmember' },
  { name: 'Bien Doan',          url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-7/your-councilmember' },
  { name: 'Domingo Candelas',   url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-8/your-councilmember' },
  { name: 'Pam Foley',          url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-9/your-councilmember' },
  { name: 'George Casey',       url: 'https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/district-10/your-councilmember' },
];

const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.sanjoseca.gov/your-government/city-council',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.5',
};

async function scrapePage(name: string, url: string): Promise<void> {
  console.log(`\n--- ${name} ---`);
  console.log(`  URL: ${url}`);
  try {
    const resp = await fetch(url, { headers: HEADERS });
    console.log(`  Status: ${resp.status}`);
    if (resp.status === 200) {
      const html = await resp.text();
      const matches = html.match(/showpublishedimage\/\d+\/\d+/g);
      if (matches) {
        console.log(`  Image URLs found:`);
        // Deduplicate
        const unique = [...new Set(matches)];
        unique.forEach(m => console.log(`    https://www.sanjoseca.gov/home/${m}`));
      } else {
        console.log(`  No showpublishedimage URLs found`);
        // Check for other image patterns
        const imgPatterns = html.match(/src="[^"]*\.(jpg|png|jpeg|webp)[^"]*"/gi);
        if (imgPatterns) {
          console.log(`  Other img srcs:`, imgPatterns.slice(0, 3));
        }
      }
    } else {
      const text = await resp.text();
      console.log(`  Response: ${text.substring(0, 200)}`);
    }
  } catch (err: any) {
    console.log(`  ERROR: ${err.message}`);
  }
}

async function main() {
  for (const off of OFFICIALS) {
    await scrapePage(off.name, off.url);
    // Small delay to avoid rate limiting
    await new Promise(r => setTimeout(r, 500));
  }
}

main().catch(console.error);
