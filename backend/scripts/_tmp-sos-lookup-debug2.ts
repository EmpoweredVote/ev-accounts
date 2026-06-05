import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Test with fresh GET before each POST
const SOS_URL = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

async function searchCandidate(lastName: string): Promise<string> {
  // GET fresh session
  const getRes = await fetch(SOS_URL, { headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' } });
  const html = await getRes.text();
  const cookie = getRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
  const viewstate = html.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
  const eventval = html.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

  const formData = new URLSearchParams({
    '_ctl0_ToolkitScriptManager1_HiddenField': '',
    '__EVENTTARGET': '', '__EVENTARGUMENT': '',
    '__VIEWSTATE': viewstate, '__VIEWSTATEGENERATOR': '4045FD78',
    '__SCROLLPOSITIONX': '0', '__SCROLLPOSITIONY': '0',
    '__EVENTVALIDATION': eventval,
    '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': lastName,
    '_ctl0:Content:ucCommitteeControl:rblCandidateLastNameSearchType': '0',  // begins with
    '_ctl0:Content:ucCommitteeControl:txtCandidateFirstName': '',
    '_ctl0:Content:ucCommitteeControl:rblCandidateFirstNameSearchType': '0',
    '_ctl0:Content:ucCommitteeControl:ddlCandidateOffice': '-1',
    '_ctl0:Content:ucCommitteeControl:ucCandidateParty:ucddlParty': '-1',
    '_ctl0:Content:ucCommitteeControl:txtCandidateDistrictNumber': '',
    '_ctl0:Content:ucCommitteeControl:rblCandidateExploratory': '2',
    '_ctl0:Content:ucCommitteeControl:rblCandidateStatus': '4',
    '_ctl0:Content:btnSearch': 'Search',
  });

  const res = await fetch(SOS_URL, {
    method: 'POST',
    headers: {
      'User-Agent': 'EmpoweredVote-TM/1.0',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Referer': SOS_URL,
      'Cookie': cookie,
    },
    body: formData.toString(),
    signal: AbortSignal.timeout(15000),
  });

  const postHtml = await res.text();
  const gridStart = postHtml.indexOf('dgdSearchResults');
  if (gridStart === -1) return '(no results)';
  const gridHtml = postHtml.slice(gridStart, gridStart + 5000);
  return gridHtml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 400);
}

// Test a few last names
const testNames = ['Abbott', 'Abernathy', 'Albaugh', 'Albright', 'Alexander'];
for (const name of testNames) {
  console.log(`\n=== ${name} ===`);
  const result = await searchCandidate(name);
  console.log('Result:', result);
  // Small delay to be polite
  await new Promise(r => setTimeout(r, 500));
}

await pool.end();
