#!/usr/bin/env node
/** Pull hrefs matching a pattern off WAF-protected index pages. One fresh browser per URL
 *  (see harvest.mjs — this WAF allows exactly one navigation per browser session). */
import { chromium } from 'playwright';

const pattern = new RegExp(process.argv[2], 'i');
const urls = process.argv.slice(3);
const out = {};
for (const url of urls) {
  const browser = await chromium.launch({ channel: 'chrome', headless: false });
  try {
    const page = await browser.newPage();
    await page.route('**/*', (r) => (['image', 'media', 'font'].includes(r.request().resourceType()) ? r.abort() : r.continue()));
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(1500);
    const links = await page.evaluate(() =>
      [...document.querySelectorAll('a')].map((a) => ({ t: a.innerText.trim().slice(0, 70), h: a.href }))
    );
    const seen = new Set();
    out[url] = links.filter((l) => pattern.test(l.h) && !seen.has(l.h) && seen.add(l.h));
  } catch (e) {
    out[url] = { error: e.message.slice(0, 100) };
  } finally {
    await browser.close();
  }
  await new Promise((r) => setTimeout(r, 4000));
}
console.log(JSON.stringify(out, null, 1));
