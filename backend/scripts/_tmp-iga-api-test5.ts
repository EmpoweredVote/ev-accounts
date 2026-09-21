// Get the actual JS bundle URL and look for API calls
const spaRes = await fetch('https://iga.in.gov/', { headers: { 'User-Agent': 'Mozilla/5.0' }});
const spaHtml = await spaRes.text();

// Extract the main JS file
const scriptMatch = spaHtml.match(/src="(\/static\/js\/main\.[^"]+\.js)"/);
if (!scriptMatch) {
  console.log('Could not find main JS script');
  process.exit(1);
}

console.log('Main JS:', scriptMatch[1]);
const jsUrl = `https://iga.in.gov${scriptMatch[1]}`;

// Need to get via CloudFront without SPA routing - try direct S3 path
// Actually let's just fetch the static file
const jsRes = await fetch(jsUrl, {
  headers: {
    'User-Agent': 'Mozilla/5.0 Chrome/120.0',
    'Accept': 'application/javascript',
  }
});
console.log('JS status:', jsRes.status, jsRes.headers.get('content-type'));
const js = await jsRes.text();
console.log('JS length:', js.length);

if (js.length < 1000) {
  console.log('JS too short - still getting SPA shell:', js.slice(0, 300));
} else {
  // Look for API endpoint patterns in the bundle
  const apiDomains = js.match(/https?:\/\/[a-zA-Z0-9\-.]+\.[a-zA-Z]{2,6}\/[a-zA-Z0-9/\-_.]{3,60}/g) || [];
  const unique = [...new Set(apiDomains)].filter(u => !u.includes('fonts.') && !u.includes('cdnjs'));
  console.log('API URLs found:', unique.slice(0, 20));

  // Look for "legislators" in the bundle
  const legIdx = js.indexOf('legislators');
  if (legIdx !== -1) {
    console.log('Context around "legislators":', js.slice(Math.max(0, legIdx - 200), legIdx + 200));
  } else {
    console.log('No "legislators" found in bundle');
  }
}
