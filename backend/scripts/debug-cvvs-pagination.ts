/**
 * debug-cvvs-pagination.ts — Verify page=N URL param gives different vote IDs
 */
import 'dotenv/config';
import { chromium } from 'playwright';

const CVVS_BASE = 'https://cityclerk.lacity.org/cvvs/search';

async function main() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();

  // Load page 1
  await page.goto(`${CVVS_BASE}/search.cfm`);
  await page.evaluate(() => {
    (document.querySelector('input[name="startdate"]') as HTMLInputElement).value = '01/14/2025';
    (document.querySelector('input[name="enddate"]') as HTMLInputElement).value = '01/27/2025';
    (document.querySelector('form[name="form"]') as HTMLFormElement).submit();
  });
  await page.waitForLoadState('networkidle');

  const html1 = await page.content();
  const ids1 = [...new Set([...html1.matchAll(/votedetails\.cfm\?voteid=(\d+)/g)].map(m => m[1]))];
  const pageText1 = html1.match(/page \d+ of \d+/i)?.[0];
  console.log(`Page 1 (${pageText1}): ${ids1.length} IDs → ${ids1[0]}..${ids1[ids1.length-1]}`);

  // Navigate to page 2 using form.action = results.cfm?page=2
  async function gotoPage(n: number): Promise<string> {
    await page.evaluate((pn: number) => {
      const form = document.querySelector('form[name="form"]') as HTMLFormElement;
      form.action = `results.cfm?page=${pn}`;
      form.submit();
    }, n);
    await page.waitForLoadState('load');
    // Extra wait for CF page to settle
    await new Promise(r => setTimeout(r, 800));
    try { return await page.content(); }
    catch { await new Promise(r => setTimeout(r, 1000)); return await page.content(); }
  }

  const html2 = await gotoPage(2);
  const ids2 = [...new Set([...html2.matchAll(/votedetails\.cfm\?voteid=(\d+)/g)].map(m => m[1]))];
  const pageText2 = html2.match(/page \d+ of \d+/i)?.[0];
  console.log(`Page 2 (${pageText2}): ${ids2.length} IDs → ${ids2[0]}..${ids2[ids2.length-1]}`);
  console.log('Same as page 1?', ids1.join(',') === ids2.join(','));
  console.log('Overlap count:', ids1.filter(id => ids2.includes(id)).length);

  const html3 = await gotoPage(3);
  const ids3 = [...new Set([...html3.matchAll(/votedetails\.cfm\?voteid=(\d+)/g)].map(m => m[1]))];
  const pageText3 = html3.match(/page \d+ of \d+/i)?.[0];
  console.log(`Page 3 (${pageText3}): ${ids3.length} IDs → ${ids3[0]}..${ids3[ids3.length-1]}`);

  const allUnique = [...new Set([...ids1, ...ids2, ...ids3])];
  console.log(`\nTotal unique across 3 pages: ${allUnique.length}`);

  await browser.close();
}

main().catch(err => { console.error(err); process.exit(1); });
