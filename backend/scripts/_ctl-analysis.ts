import 'dotenv/config';
import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';

const NETFILE_BASE_URL = 'https://public.netfile.com/pub2/Default.aspx';
const NETFILE_AGENCY = 'LACO';

function extractHiddenField(html: string, fieldName: string): string {
  const patterns = [
    new RegExp(`id="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`name="${fieldName}"[^>]*value="([^"]*)"`, 'i'),
    new RegExp(`value="([^"]*)"[^>]*name="${fieldName}"`, 'i'),
  ];
  for (const p of patterns) { const m = html.match(p); if (m) return m[1] ?? ''; }
  return '';
}
function extractCookies(r: Response): string {
  const h = r.headers.get('set-cookie');
  if (!h) return '';
  return h.split(/,(?=[^;]+=[^;]+;|[^;]+=)/).map(c => c.trim().split(';')[0]?.trim() ?? '').filter(Boolean).join('; ');
}

async function main() {
  const pageUrl = `${NETFILE_BASE_URL}?aid=${NETFILE_AGENCY}`;
  const getResp = await fetch(pageUrl, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0' } });
  const html = await getResp.text();
  const cookies = extractCookies(getResp);
  const body = new URLSearchParams({
    __EVENTTARGET: 'ctl00$phBody$GetExcel', __EVENTARGUMENT: '',
    __VIEWSTATE: extractHiddenField(html, '__VIEWSTATE'),
    __VIEWSTATEGENERATOR: extractHiddenField(html, '__VIEWSTATEGENERATOR'),
    __EVENTVALIDATION: extractHiddenField(html, '__EVENTVALIDATION'),
    'ctl00$phBody$DateSelect': '2024',
  });
  const resp = await fetch(pageUrl, {
    method: 'POST',
    headers: { 'User-Agent': 'Mozilla/5.0 Chrome/120.0', 'Content-Type': 'application/x-www-form-urlencoded', Referer: pageUrl, Cookie: cookies },
    body: body.toString(),
  });
  const buf = Buffer.from(await resp.arrayBuffer());
  const zip = new AdmZip(buf);
  const entry = zip.getEntries().find(e => e.entryName.toLowerCase().endsWith('.xlsx'))!;
  const xlsxBuf = entry.getData();

  const wb = XLSX.read(xlsxBuf, { type: 'buffer', cellDates: true });
  const ws = wb.Sheets['A-Contributions'];
  const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(ws, { defval: '' });
  const schedA = rows.filter(r => r['Form_Type'] === 'A');

  // Deduplicate filers
  const filerMap = new Map<string, { name: string; type: string; officeDesc: string; count: number }>();
  for (const r of schedA) {
    const id = String(r['Filer_ID'] ?? '').trim();
    const nm = String(r['Filer_NamL'] ?? '').trim();
    const type = String(r['Committee_Type'] ?? '').trim();
    const officeDesc = String(r['tblCover_Offic_Dscr'] ?? r['tblDetlTran_Offic_Dscr'] ?? '').trim();
    if (!id) continue;
    const ex = filerMap.get(id);
    if (ex) ex.count++;
    else filerMap.set(id, { name: nm, type, officeDesc, count: 1 });
  }

  // Count by type
  const byType = new Map<string, number>();
  for (const [, info] of filerMap) {
    byType.set(info.type, (byType.get(info.type) ?? 0) + 1);
  }
  console.log('=== Committee types among 275 unique filers ===');
  for (const [type, count] of [...byType.entries()].sort((a,b) => b[1]-a[1])) {
    console.log(`  ${type || '(blank)'}: ${count}`);
  }

  // Show all CTL committees
  const ctlFilers = [...filerMap.entries()].filter(([, v]) => v.type === 'CTL').sort((a,b) => b[1].count - a[1].count);
  console.log(`\n=== CTL (candidate-controlled) committees: ${ctlFilers.length} ===`);
  for (const [id, info] of ctlFilers) {
    console.log(`  ${id}: "${info.name}" | office="${info.officeDesc}" | ${info.count} rows`);
  }
}
main().catch(console.error);
