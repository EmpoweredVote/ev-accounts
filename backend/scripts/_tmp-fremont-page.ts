// Quick playwright script to grab fremont.gov council page
import 'dotenv/config';

async function run() {
  // Use fetch with proper headers to get the page HTML
  const resp = await fetch('https://www.fremont.gov/government/mayor-city-council', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
    }
  });
  console.log('Status:', resp.status);
  const text = await resp.text();
  console.log('Length:', text.length);
  // Find image URLs
  const imgs = text.match(/src=["'](https?:\/\/[^"']+\.(jpg|jpeg|png|gif|webp))['"]/gi) || [];
  console.log('Images:', imgs.slice(0, 20));
}
run().catch(console.error);
