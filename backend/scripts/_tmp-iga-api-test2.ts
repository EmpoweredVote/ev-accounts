// Test IGA official API with auth-like headers
const headers = {
  'User-Agent': 'EmpoweredVote-TM/1.0',
  'Accept': 'application/json',
  'x-api-key': 'test',
};

// Try the documented IGA API pattern
const apis = [
  'https://iga.in.gov/api/2025/legislators?limit=10',
  'https://iga.in.gov/api/2025/legislators/',
  // Try direct data endpoint
  'https://iga.in.gov/2025/legislators',
  // Try with explicit JSON accept
];

for (const url of apis) {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'EmpoweredVote-TM/1.0', 'Accept': 'application/json' },
      signal: AbortSignal.timeout(8000)
    });
    console.log(`${url} → ${res.status} ${res.headers.get('content-type')}`);
    if (res.ok) {
      const text = await res.text();
      if (text.includes('{') || text.includes('[')) {
        console.log('  JSON snippet:', text.slice(0, 300));
      } else {
        console.log('  Not JSON. Length:', text.length);
      }
    }
  } catch (e) {
    console.log(`${url} → ERROR: ${(e as Error).message}`);
  }
}

// Also check the IGA JavaScript bundle to find API endpoint patterns
console.log('\n--- Checking main JS bundle for API patterns ---');
try {
  const res = await fetch('https://iga.in.gov/legislative/2025/senators', {
    headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' }
  });
  const html = await res.text();
  const scriptMatch = html.match(/src="(\/static\/js\/main\.[^"]+\.js)"/);
  if (scriptMatch) {
    console.log('Found script:', scriptMatch[1]);
    const jsRes = await fetch(`https://iga.in.gov${scriptMatch[1]}`, {
      headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' }
    });
    const js = await jsRes.text();
    // Look for API endpoint patterns
    const apiPatterns = js.match(/\/api\/[^"'\s]{5,50}/g);
    if (apiPatterns) {
      const unique = [...new Set(apiPatterns)].slice(0, 20);
      console.log('API patterns found:', unique);
    } else {
      console.log('No /api/ patterns found. JS length:', js.length);
      // Try to find any URL-like patterns
      const urlPatterns = js.match(/https:\/\/[^"'\s]{10,60}/g);
      if (urlPatterns) {
        console.log('HTTPS patterns:', [...new Set(urlPatterns)].slice(0, 10));
      }
    }
  }
} catch (e) {
  console.log('JS bundle check failed:', (e as Error).message);
}
