// Try the specific CommitteeSearch and committee detail endpoints
// FileNumber 7925 = Alex Burton for Indiana (State House candidate)

const urls = [
  'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx',
  'https://campaignfinance.in.gov/PublicSite/SearchPages/CommitteeSearch.aspx',
];

for (const url of urls) {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0' },
    signal: AbortSignal.timeout(8000)
  });
  const html = await res.text();
  console.log(`\n${url} → ${res.status}`);

  // Find any JS/API calls in the page
  const apiCalls = html.match(/(?:fetch|XMLHttpRequest|ajax|url:)\s*['"](\/[^'"]+)['"]/g) || [];
  console.log('API calls:', apiCalls.slice(0, 10));

  // Find hidden inputs (viewstate etc.)
  const hiddenInputs = html.match(/<input[^>]+type="hidden"[^>]*name="([^"]+)"[^>]*value="([^"]{0,50})"/g) || [];
  console.log('Hidden inputs:', hiddenInputs.slice(0, 5));

  // Look for search form
  const formMatch = html.match(/<form[^>]*action="([^"]*)"[^>]*>/i);
  console.log('Form action:', formMatch?.[1]);

  // Preview first 500 chars
  console.log('Preview:', html.slice(0, 500).replace(/\s+/g, ' '));
}

// Also try the DataDownload page which has bulk data
const dlRes = await fetch('https://campaignfinance.in.gov/PublicSite/Reporting/DataDownload.aspx', {
  headers: { 'User-Agent': 'Mozilla/5.0' }
});
const dlHtml = await dlRes.text();
console.log('\nData download page links:');
const dlLinks = dlHtml.match(/href="([^"]+\.(?:csv|xlsx|zip|txt)[^"]*)"/gi) || [];
for (const l of dlLinks.slice(0, 20)) console.log(' ', l);

// Also check for committee type in the download files
const downloadLinks = dlHtml.match(/href="([^"]+\.(csv|xlsx|zip))[^"]*"/gi) || [];
console.log('\nDownload links:', downloadLinks.slice(0, 10));
