import 'dotenv/config';

async function run() {
  const resp = await fetch('https://www.fremont.gov/government/mayor-city-council', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
    }
  });
  const text = await resp.text();
  
  // Look for all img tags with various patterns
  const allImgs = text.match(/<img[^>]+>/gi) || [];
  console.log('Total img tags:', allImgs.length);
  
  // Look for specific CDN patterns
  const cdnPatterns = [
    /civicmedia\.granicus\.com[^"'\s]*/g,
    /cms7files\.revize\.com[^"'\s]*/g,
    /media\.gvnppc\.com[^"'\s]*/g,
    /\.jpg[^"'\s]*/gi,
    /\.png[^"'\s]*/gi,
  ];
  
  // Print all unique image-like URLs found
  const urls = new Set<string>();
  text.replace(/(?:src|data-src|href)=["']([^"']*(?:\.jpg|\.jpeg|\.png|\.gif|\.webp)[^"']*)["']/gi, (_, url) => {
    if (url.startsWith('http') || url.startsWith('/')) urls.add(url);
    return '';
  });
  
  console.log('Image URLs found:', urls.size);
  [...urls].forEach(u => console.log(' ', u));
  
  // Also look for council member names
  ['Salwan', 'Keng', 'Campbell', 'Kimberlin', 'Shao', 'Zhang', 'Liu'].forEach(name => {
    const idx = text.indexOf(name);
    if (idx >= 0) {
      console.log(`\n--- Context around "${name}" ---`);
      console.log(text.slice(Math.max(0, idx-200), idx+500));
    }
  });
}
run().catch(console.error);
