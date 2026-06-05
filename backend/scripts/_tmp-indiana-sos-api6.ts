// Try the CandidateSearch to look up by name and see if it returns office type
// Also check CommitteeDetail with the right FilingID format

// First, let's try CandidateSearch with a known name
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';
const res = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await res.text();

// Extract VIEWSTATE and other hidden fields
const viewstate = html.match(/name="__VIEWSTATE"\s+id="__VIEWSTATE"\s+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/name="__EVENTVALIDATION"\s+id="__EVENTVALIDATION"\s+value="([^"]+)"/)?.[1] ?? '';
const gen = html.match(/name="__VIEWSTATEGENERATOR"\s+id="__VIEWSTATEGENERATOR"\s+value="([^"]+)"/)?.[1] ?? '';

console.log('ViewState length:', viewstate.length);
console.log('EventValidation length:', eventval.length);

// Try POST with candidate last name
const formData = new URLSearchParams({
  '__EVENTTARGET': '',
  '__EVENTARGUMENT': '',
  '__VIEWSTATEGENERATOR': gen,
  '__VIEWSTATE': viewstate,
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:txtLastName': 'Burton',
  '_ctl0:Content:txtFirstName': 'Alexander',
  '_ctl0:Content:Button1': 'Search',
});

const postRes = await fetch(candidateUrl, {
  method: 'POST',
  headers: {
    'User-Agent': 'Mozilla/5.0',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': candidateUrl,
  },
  body: formData.toString(),
  signal: AbortSignal.timeout(10000),
});

const postHtml = await postRes.text();
console.log('\nCandidateSearch POST result:', postRes.status, '| Length:', postHtml.length);

// Look for results table with office type
const tableMatch = postHtml.match(/<table[^>]*>[\s\S]{100,5000}?<\/table>/gi) || [];
console.log('Tables found:', tableMatch.length);
for (const t of tableMatch.slice(0, 2)) {
  // Strip HTML tags for readability
  const stripped = t.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('Table content:', stripped.slice(0, 600));
}
