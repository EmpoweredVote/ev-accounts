import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Get first 5 unclassified politicians and test SoS lookup for them
const { rows } = await pool.query(`
  SELECT p.full_name, p.first_name, p.last_name, ps.notes
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  JOIN transparent_motivations.politician_sources ps ON ps.essentials_politician_id = o.politician_id
  WHERE o.title = 'Indiana Elected Official'
    AND ps.source_system = 'indiana'
    AND ps.research_status = 'confirmed'
  ORDER BY p.last_name, p.first_name
  LIMIT 5
`);

const SOS_URL = 'https://campaignfinance.in.gov/PublicSite/SearchPages/CandidateSearch.aspx';

// Init SoS
const initRes = await fetch(SOS_URL, { headers: { 'User-Agent': 'EmpoweredVote-TM/1.0' } });
const initHtml = await initRes.text();
const cookie = initRes.headers.get('set-cookie')?.split(',').map(c => c.split(';')[0]).join('; ') ?? '';
const viewstate = initHtml.match(/name="__VIEWSTATE"[^>]+value="([^"]+)"/)?.[1] ?? '';
const eventval = initHtml.match(/name="__EVENTVALIDATION"[^>]+value="([^"]+)"/)?.[1] ?? '';

console.log('SoS init: VS len=', viewstate.length, 'EV len=', eventval.length);

for (const r of rows) {
  console.log(`\n=== Testing: ${r.full_name} (first=${r.first_name}, last=${r.last_name}) ===`);

  const formData = new URLSearchParams({
    '_ctl0_ToolkitScriptManager1_HiddenField': '',
    '__EVENTTARGET': '', '__EVENTARGUMENT': '',
    '__VIEWSTATE': viewstate, '__VIEWSTATEGENERATOR': '4045FD78',
    '__SCROLLPOSITIONX': '0', '__SCROLLPOSITIONY': '0',
    '__EVENTVALIDATION': eventval,
    '_ctl0:Content:ucCommitteeControl:txtCandidateLastName': r.last_name,
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

  const html = await res.text();

  // Find grid section
  const gridStart = html.indexOf('dgdSearchResults');
  if (gridStart === -1) {
    console.log('  No grid found!');
    // Check for error messages
    const errs = html.match(/(?:no records|no matching|error)[^<]{0,200}/gi) || [];
    console.log('  Messages:', errs.slice(0, 3));
    continue;
  }

  const gridHtml = html.slice(gridStart, gridStart + 5000);
  const stripped = gridHtml.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  console.log('  Grid content:', stripped.slice(0, 500));
}

await pool.end();
