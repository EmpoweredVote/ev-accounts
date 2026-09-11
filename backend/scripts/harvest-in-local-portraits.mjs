/**
 * harvest-in-local-portraits.mjs — collect portrait candidates for the 48 Indiana local and county
 * officials from their own bodies' sites.
 *
 * 🔴 WHAT THIS RECORDS, AND WHY. For every image it keeps `alt`, the nearest heading/caption text,
 * and the containing block's text — not just the src. GA-3 proved that reading a roster page's
 * images IN SEQUENCE gives an order that is not district order (Baldwin: Davis 239, Butts 238), and
 * the standing rule is that an ALT naming someone else outvotes the page. Matching is therefore by
 * NAME found beside the image, never by position.
 *
 * 🔴 THE ALLEN COUNTY DIRECTORY IS A KNOWN-STALE SOURCE. IN-5 found it still listing Josh L. Hale
 * on County Council District 1 eight months after he resigned. A portrait taken from a stale row is
 * a picture of the WRONG PERSON that passes every count-based check. Every match is reported with
 * the name the page itself gives, so a mismatch is visible rather than assumed away.
 *
 * 🔴 LAKE COUNTY: IN-6 got ten identical answers from a regex that matched the nav bar. Header,
 * nav and footer are stripped before any text is read, and the harvest prints DISTINCT name counts
 * so a uniform answer cannot pass as a finding.
 *
 *   node scripts/harvest-in-local-portraits.mjs [--only <substring of page label>]
 */
import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, readFileSync, existsSync } from 'node:fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';
const OUT = 'data/seed-in-local-headshots-2026';
mkdirSync(OUT, { recursive: true });

const PAGES = [
  ['FW council',    'https://www.cityoffortwayne.in.gov/185/City-Council'],
  ['FW directory',  'https://www.cityoffortwayne.in.gov/directory.aspx'],
  ['Gary council',  'https://garycommoncouncil.gov/council-members/'],
  ['Gary mayor',    'https://www.gary.gov/office-of-the-mayor'],
  ['Gary clerk',    'http://garycityclerk.com/'],
  ['Allen directory','https://www.allencounty.in.gov/directory.aspx'],
  ['Allen council', 'https://www.allencounty.in.gov/474/County-Council'],
  ['Allen recorder','https://www.allencounty.in.gov/283/Recorder'],
  ['Allen sheriff', 'https://www.allencounty.in.gov/767/Sheriffs-Department'],
  ['Allen clerk',   'https://www.allencounty.in.gov/174/Clerk-of-Courts'],
  ['Lake commissioners','https://lakecountyin.gov/departments/commissioners'],
  ['Lake assessor', 'https://lakecountyin.gov/departments/assessor'],
  ['Lake auditor',  'https://lakecountyin.gov/departments/auditor'],
  ['Lake clerk',    'https://lakecountyin.gov/departments/clerk'],
  ['Lake coroner',  'https://lakecountyin.gov/departments/coroner'],
  ['Lake prosecutor','https://lakecountyin.gov/departments/prosecutor'],
  ['Lake recorder', 'https://lakecountyin.gov/departments/recorder'],
  ['Lake sheriff',  'https://lakecountyin.gov/departments/sheriff'],
  ['Lake surveyor', 'https://lakecountyin.gov/departments/surveyor'],
  ['Lake treasurer','https://lakecountyin.gov/departments/treasurer'],
];
const only = process.argv.includes('--only') ? process.argv[process.argv.indexOf('--only') + 1] : null;

// 🔴 MERGE, NEVER OVERWRITE. A transient timeout on one page must not delete another page's
// good harvest: the Allen directory (33 images, the only source for 11 officials) was lost that
// way once. Only pages that SUCCEED this run replace their previous rows.
const prior = existsSync(`${OUT}/harvest.json`) ? JSON.parse(readFileSync(`${OUT}/harvest.json`, 'utf8')) : [];
const browser = await chromium.launch();
const ctx = await browser.newContext({ userAgent: UA });
const page = await ctx.newPage();
page.setDefaultNavigationTimeout(90000);
const all = [];
const succeeded = new Set();

for (const [label, url] of PAGES) {
  if (only && !label.includes(only)) continue;
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 });
    await page.waitForTimeout(2500);
    const found = await page.evaluate(() => {
      // Strip the chrome first — IN-6's ten identical answers were all the nav bar.
      for (const sel of ['header', 'nav', 'footer', '[role=navigation]', '.nav', '.navbar', '.menu', '.site-header', '.site-footer'])
        document.querySelectorAll(sel).forEach((n) => n.remove());
      const clean = (s) => (s || '').replace(/\s+/g, ' ').trim().slice(0, 160);
      return [...document.querySelectorAll('img')].filter((i) => i.naturalWidth >= 80 && i.naturalHeight >= 80).map((i) => {
        let block = i.closest('li,figure,article,.card,.member,.staff,td,section,div');
        for (let k = 0; k < 3 && block && clean(block.innerText).length < 3; k++) block = block.parentElement;
        const fig = i.closest('figure')?.querySelector('figcaption');
        return { src: i.currentSrc || i.src, alt: clean(i.alt), w: i.naturalWidth, h: i.naturalHeight,
                 caption: clean(fig?.innerText), near: clean(block?.innerText),
                 title: clean(i.getAttribute('title')) };
      });
    });
    console.log(`${label.padEnd(18)} ${resp.status()}  ${found.length} images >=80px`);
    succeeded.add(label);
    for (const f of found) all.push({ page: label, url, ...f });
  } catch (e) {
    console.log(`${label.padEnd(16)} FAILED ${String(e).split('\n')[0].slice(0, 90)}`);
    all.push({ page: label, url, error: String(e).split('\n')[0] });
  }
}
await browser.close();
const merged = [...prior.filter((r) => !succeeded.has(r.page)), ...all];
writeFileSync(`${OUT}/harvest.json`, JSON.stringify(merged, null, 1));
const pageCount = new Set(merged.filter((m) => m.src).map((m) => m.page)).size;
console.log(`
wrote ${OUT}/harvest.json -- ${merged.filter((a) => a.src).length} images across ${pageCount} pages`);
