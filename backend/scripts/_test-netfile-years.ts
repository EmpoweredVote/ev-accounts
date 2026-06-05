import 'dotenv/config';

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';

function extractHiddenField(html: string, fieldName: string): string {
  const patterns = [
    new RegExp(`id="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${fieldName}"`, 'i'),
  ];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match) return match[1] ?? '';
  }
  return '';
}
function extractCookies(response: Response): string {
  const h = response.headers.get('set-cookie');
  if (!h) return '';
  return h.split(/,(?=[^;]+=[^;]+;|[^;]+=)/).map(c => c.trim().split(';')[0]?.trim() ?? '').filter(Boolean).join('; ');
}

async function tryDownload(year: number, eventTarget: string, dateField: string): Promise<string> {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' } });
  const html = await getResp.text();
  const cookies = extractCookies(getResp);
  const viewState = extractHiddenField(html, '__VIEWSTATE');
  const viewStateGenerator = extractHiddenField(html, '__VIEWSTATEGENERATOR');
  const eventValidation = extractHiddenField(html, '__EVENTVALIDATION');

  // Check if year is in dropdown
  const yearInDropdown = html.includes(`value="${year}"`) || html.includes(`>${year}<`);

  const formBody = new URLSearchParams({
    __EVENTTARGET: eventTarget,
    __EVENTARGUMENT: '',
    __VIEWSTATE: viewState,
    __VIEWSTATEGENERATOR: viewStateGenerator,
    __EVENTVALIDATION: eventValidation,
    [dateField]: String(year),
  });

  const postResp = await fetch(pageUrl, {
    method: 'POST',
    headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0', 'Content-Type': 'application/x-www-form-urlencoded', Referer: pageUrl, Cookie: cookies },
    body: formBody.toString(),
  });
  const contentType = postResp.headers.get('content-type') ?? '';
  const buf = Buffer.from(await postResp.arrayBuffer());
  const isHtml = contentType.includes('text/html');
  const sizeMB = (buf.length / 1024 / 1024).toFixed(1);
  return `year=${year} target=${eventTarget.split('$').pop()} field=${dateField.split('$').pop()} → ${isHtml ? 'HTML' : contentType.split('/')[1]} ${sizeMB}MB (yearInDropdown=${yearInDropdown})`;
}

async function main() {
  // Check what the portal HTML looks like — what years and buttons are available
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' } });
  const html = await getResp.text();

  // Find year dropdown options
  const yearMatches = [...html.matchAll(/<option[^>]*value="(\d{4})"[^>]*>(\d{4})</g)];
  console.log(`Year dropdown options: ${yearMatches.map(m => m[1]).join(', ') || 'none found'}`);

  // Find button/event targets
  const buttonMatches = [...html.matchAll(/doPostBack\('([^']+)'/g)];
  console.log(`Postback targets: ${[...new Set(buttonMatches.map(m => m[1]))].join(', ')}`);

  // Find select/input elements related to year
  const selectMatches = [...html.matchAll(/<select[^>]*name="([^"]*)"[^>]*>/g)];
  console.log(`Select elements: ${selectMatches.map(m => m[1]).join(', ')}`);
  
  // Try GetExcel (all) vs GetExcelAmend for 2024
  console.log('\n=== Testing download combinations ===');
  const tests = [
    { year: 2024, target: 'ctl00$phBody$GetExcel', field: 'ctl00$phBody$DateSelect' },
    { year: 2024, target: 'ctl00$phBody$GetExcelAmend', field: 'ctl00$phBody$DateSelect' },
    { year: 2022, target: 'ctl00$phBody$GetExcelAmend', field: 'ctl00$phBody$DateSelect' },
    { year: 2022, target: 'ctl00$phBody$GetExcelAmend', field: 'ctl00$phBody$ddlYear' },
    { year: 2022, target: 'ctl00$phBody$GetExcel', field: 'ctl00$phBody$DateSelect' },
  ];
  for (const test of tests) {
    try {
      const result = await tryDownload(test.year, test.target, test.field);
      console.log(`  ${result}`);
    } catch(e) {
      console.log(`  year=${test.year} → ERROR: ${e instanceof Error ? e.message : String(e)}`);
    }
    await new Promise(r => setTimeout(r, 1000));
  }
}
main().catch(console.error);
