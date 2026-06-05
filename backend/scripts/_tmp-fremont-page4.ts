import 'dotenv/config';

async function run() {
  const resp = await fetch('https://www.fremont.gov/government/mayor-city-council', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    }
  });
  const text = await resp.text();
  
  // Get Zhang's section more carefully - need broader context
  const idx = text.indexOf('YajingZhang');
  if (idx >= 0) {
    const section = text.slice(idx, idx + 2000);
    console.log('=== Zhang Section ===');
    console.log(section);
  }
  
  // Also check the second "9838" URL to see what it's about
  const idx2 = text.indexOf('9838');
  if (idx2 >= 0) {
    console.log('\n=== 9838 context ===');
    console.log(text.slice(Math.max(0, idx2-300), idx2+500));
  }
}
run().catch(console.error);
