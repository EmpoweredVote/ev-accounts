// Look more carefully at CandidateSearch results
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';
const res = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await res.text();

const viewstate = html.match(/name="__VIEWSTATE"\s+id="__VIEWSTATE"\s+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/name="__EVENTVALIDATION"\s+id="__EVENTVALIDATION"\s+value="([^"]+)"/)?.[1] ?? '';
const gen = html.match(/name="__VIEWSTATEGENERATOR"\s+id="__VIEWSTATEGENERATOR"\s+value="([^"]+)"/)?.[1] ?? '';

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

// Find content section - look for all relevant text
const contentStart = postHtml.indexOf('Content');
const relevantSection = postHtml.slice(contentStart, contentStart + 5000);

// Strip HTML tags
const stripped = relevantSection.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
console.log('Relevant section:', stripped.slice(0, 2000));

// Also look for specific data items
const candidateData = postHtml.match(/(?:Candidate|Office|Position|Chamber|State Representative|State Senator|House|Senate)[^<]{0,200}/gi) || [];
console.log('\nData mentions:', candidateData.slice(0, 10).join('\n'));

// Look for links that might go to candidate profiles
const links = postHtml.match(/href="([^"]+(?:Candidate|Committee|Filer)[^"]*)"[^>]*>/gi) || [];
console.log('\nRelevant links:', links.slice(0, 10));
