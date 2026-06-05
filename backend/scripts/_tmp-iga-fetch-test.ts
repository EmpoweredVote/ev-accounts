// Quick test: fetch IGA roster pages and see what we get back
const headers = { 'User-Agent': 'EmpoweredVote-TM/1.0' };

console.log('Fetching IGA Senate...');
try {
  const res = await fetch('https://iga.in.gov/legislative/2025/senators', { headers });
  console.log('Status:', res.status, res.statusText);
  const html = await res.text();
  console.log('HTML length:', html.length);
  console.log('First 1000 chars:', html.slice(0, 1000));
  console.log('---');
  // Check if it has Senator/Representative keywords
  console.log('Contains "Senator":', html.includes('Senator'));
  console.log('Contains "senators":', html.includes('senators'));
  console.log('Contains "Sen.":', html.includes('Sen.'));
  // Show a snippet around "Senator" if found
  const idx = html.indexOf('Senator');
  if (idx !== -1) {
    console.log('Context around "Senator":', html.slice(Math.max(0, idx - 100), idx + 200));
  }
} catch (e) {
  console.error('Fetch failed:', e);
}
