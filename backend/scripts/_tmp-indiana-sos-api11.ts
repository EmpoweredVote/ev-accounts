// Try broader search and dump more of the results HTML
const candidateUrl = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

const getRes = await fetch(candidateUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
const html = await getRes.text();
const cookieHeader = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';

const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
const eventval = html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

// Try all statuses (including historical)
// Status: 1=active, 2=inactive, 4=exploratory - try value 2 for "All"
const formData = new URLSearchParams({
  '_ctl0_ToolkitScriptManager1_HiddenField': '',
  '__EVENTTARGET': '',
  '__EVENTARGUMENT': '',
  '__VIEWSTATE': viewstate,
  '__VIEWSTATEGENERATOR': '4045FD78',
  '__SCROLLPOSITIONX': '0',
  '__SCROLLPOSITIONY': '0',
  '__EVENTVALIDATION': eventval,
  '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': 'Burton',
  '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '1',  // contains
  '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '0',
  '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
  '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
  '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
  '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',  // all
  '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '4',  // all?
  '_ctl0:Content:btnSearch': 'Search',
});

const postRes = await fetch(candidateUrl, {
  method: 'POST',
  headers: {
    'User-Agent': 'Mozilla/5.0',
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': candidateUrl,
    'Cookie': cookieHeader,
  },
  body: formData.toString(),
  signal: AbortSignal.timeout(15000),
});

const postHtml = await postRes.text();
console.log('Status:', postRes.status, '| Length:', postHtml.length);

// Dump a chunk of the middle of the response where results would be
const midPoint = Math.floor(postHtml.length / 2);
const section = postHtml.slice(midPoint - 1000, midPoint + 3000);
const stripped = section.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
                        .replace(/<[^>]+>/g, ' ')
                        .replace(/\s+/g, ' ')
                        .trim();
console.log('\nMid-page content:', stripped.slice(0, 2000));

// Also check if there's an error message
const errors = postHtml.match(/(?:error|Error|invalid|no results|no records)[^<]{0,200}/gi) || [];
if (errors.length) console.log('\nErrors/messages:', errors.slice(0, 5));

// Check for specific table/grid IDs
const gridIds = postHtml.match(/id="[^"]*(?:Grid|List|Result|Data)[^"]*"/gi) || [];
console.log('\nGrid IDs:', gridIds.slice(0, 10));
