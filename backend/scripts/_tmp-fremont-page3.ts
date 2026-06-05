import 'dotenv/config';

async function run() {
  const resp = await fetch('https://www.fremont.gov/government/mayor-city-council', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    }
  });
  const text = await resp.text();
  
  // Extract all showpublishedimage URLs with context
  const matches = text.match(/showpublishedimage\/\d+\/\d+/g) || [];
  const uniqueMatches = [...new Set(matches)];
  
  // Also get the full src attributes
  const srcMatches = text.match(/src="\/home\/showpublishedimage\/[^"]+"/g) || [];
  
  console.log('Unique showpublishedimage paths:', uniqueMatches.length);
  uniqueMatches.forEach(m => console.log('  https://www.fremont.gov/home/' + m));
  
  console.log('\nFull src attributes:');
  srcMatches.forEach(m => {
    const path = m.replace('src="', '').replace('"', '');
    console.log('  https://www.fremont.gov' + path);
  });
}
run().catch(console.error);
