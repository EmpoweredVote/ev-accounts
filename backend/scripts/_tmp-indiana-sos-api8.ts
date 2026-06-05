// Check what the CandidateSearch returns for Alexander Burton
// We saw the Office dropdown — let's get actual search results

const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';
const res = await fetch(candidateUrl, {
  headers: { 'User-Agent': 'Mozilla/5.0', 'Cookie': '' }
});
const html = await res.text();
const cookies = res.headers.get('set-cookie') ?? '';
console.log('Cookies:', cookies.slice(0, 200));

const viewstate = html.match(/id="__VIEWSTATE"\s+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/id="__EVENTVALIDATION"\s+value="([^"]+)"/)?.[1] ?? '';
const gen = html.match(/id="__VIEWSTATEGENERATOR"\s+value="([^"]+)"/)?.[1] ?? '';
const scrollx = html.match(/id="__SCROLLPOSITIONX"\s+value="([^"]+)"/)?.[1] ?? '0';
const scrolly = html.match(/id="__SCROLLPOSITIONY"\s+value="([^"]+)"/)?.[1] ?? '0';

console.log('VIEWSTATE length:', viewstate.length);

// Try POST with just last name "Burton" — cast wider net
const formData = new URLSearchParams({
  '__EVENTTARGET': '_ctl0$Content$Button1',
  '__EVENTARGUMENT': '',
  '__SCROLLPOSITIONX': scrollx,
  '__SCROLLPOSITIONY': scrolly,
  '__VIEWSTATEGENERATOR': gen,
  '__VIEWSTATE': viewstate,
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:txtLastName': 'Burton',
  '_ctl0:Content:txtFirstName': '',
  '_ctl0:Content:ddlOffice': '-1',
  // Some IN SoS forms use contains vs begins
  '_ctl0:Content:rdoLastName': '1',
  '_ctl0:Content:rdoFirstName': '1',
  '_ctl0:Content:Button1': 'Search',
});

const postRes = await fetch(candidateUrl, {
  method: 'POST',
  headers: {
    'User-Agent': 'Mozilla/5.0',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': candidateUrl,
    'Cookie': cookies.split(';')[0] ?? '',
  },
  body: formData.toString(),
  signal: AbortSignal.timeout(15000),
  redirect: 'follow',
});

const postHtml = await postRes.text();
console.log('\nSearch result:', postRes.status, '| Length:', postHtml.length);

// Look for result rows
const rows = postHtml.match(/<tr[^>]*>[\s\S]{50,1000}?<\/tr>/gi) || [];
console.log('Table rows found:', rows.length);
for (const row of rows.slice(3, 20)) {
  const stripped = row.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  if (stripped.length > 20 && stripped.length < 400 && /[A-Z]/.test(stripped)) {
    console.log('ROW:', stripped);
  }
}
