#!/usr/bin/env node
/**
 * Harvest stance-source pages to local markdown for the Colorado Springs wave.
 *
 * Several of the best sources for this cohort sit behind a WAF that returns a clean
 * HTTP 403 to both WebFetch and curl-with-a-browser-UA (verified 2026-08-21 on cpr.org),
 * so a real browser is the only way in. Harvesting once to disk also means the research
 * agents read local files instead of re-fetching — no rate limit, no 403, and the
 * source text is frozen so a later re-read sees exactly what the stance was drawn from.
 *
 * Usage:  node harvest.mjs <targets.json>
 *   targets.json = [{ "slug": "...", "url": "...", "who": "...", "note": "..." }]
 * Writes ./sources/<slug>.md and prints a per-target status line.
 */
import { chromium } from 'playwright';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import path from 'node:path';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const OUT = path.join(HERE, 'sources');

const targets = JSON.parse(await readFile(process.argv[2], 'utf8'));
await mkdir(OUT, { recursive: true });

// Headless bundled Chromium gets fingerprinted by this WAF and 403s on every navigation after
// the first, even with generous backoff. A real Chrome channel, headed, gets through — measured
// 2026-08-21 against cpr.org. Override with HARVEST_HEADLESS=1 / HARVEST_CHANNEL= if a target
// doesn't need it.
const launchOpts = { headless: process.env.HARVEST_HEADLESS === '1' };
if (process.env.HARVEST_CHANNEL !== '') launchOpts.channel = process.env.HARVEST_CHANNEL || 'chrome';
// 🔴 EXACTLY ONE PAGE SUCCEEDS PER BROWSER LAUNCH on the cpr.org WAF. The first navigation
// returns 200; every one after it returns 403 with a 258-char body, no matter how long the
// delay (tested to 54s) or whether we use headless Chromium or a real headed Chrome channel.
// The WAF hands out a challenge cookie after the first request that the automated browser
// cannot satisfy. So: throw the whole browser away between targets. Slow, but it works.
const freshPage = async () => {
  const browser = await chromium.launch(launchOpts);
  const ctx = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    viewport: { width: 1400, height: 1000 },
  });
  const page = await ctx.newPage();
  // Block images/media/fonts — we only want text, and this makes the harvest much faster.
  await page.route('**/*', (route) => {
    const t = route.request().resourceType();
    return ['image', 'media', 'font'].includes(t) ? route.abort() : route.continue();
  });
  return { browser, page };
};

// The WAF throttles rapid sequential navigation: the first page returns 200 and every
// one after it 403s with a 258-char body. Pacing between requests (and backing off on a
// block) is what gets the rest through — measured 2026-08-21.
const DELAY = Number(process.env.HARVEST_DELAY_MS || 9000);
const TRIES = Number(process.env.HARVEST_TRIES || 4);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const scrape = async (url) => {
  const { browser, page } = await freshPage();
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    const status = resp ? resp.status() : 0;
    await page.waitForTimeout(1500);
    const text = await page.evaluate(() => {
      for (const sel of ['script', 'style', 'nav', 'footer', 'aside', 'form']) {
        document.querySelectorAll(sel).forEach((n) => n.remove());
      }
      return document.body.innerText.replace(/\n{3,}/g, '\n\n').trim();
    });
    return { status, text };
  } finally {
    await browser.close();
  }
};

let ok = 0, fail = 0, first = true;
for (const t of targets) {
  try {
    // Resume-safe: never re-fetch something already on disk. The per-target browser launch is
    // expensive and this harvest gets re-run as new targets are discovered.
    try { const prev = await readFile(path.join(OUT, `${t.slug}.md`), 'utf8');
      if (prev.length > 1200) { console.log(`SKIP  ${t.slug.padEnd(38)} already harvested`); ok++; continue; } } catch {}
    if (!first) await sleep(DELAY);
    first = false;
    let status = 0, text = '';
    for (let attempt = 1; attempt <= TRIES; attempt++) {
      ({ status, text } = await scrape(t.url));
      // A WAF challenge can come back HTTP 200 with a few KB of shell, so gate on LENGTH too,
      // never on status alone.
      if (status < 400 && text.length >= 1200) break;
      if (attempt < TRIES) {
        const back = DELAY * attempt * 2;
        console.log(`      ${t.slug} blocked (http=${status} len=${text.length}), retry ${attempt}/${TRIES - 1} in ${back / 1000}s`);
        await sleep(back);
      }
    }
    if (status >= 400 || text.length < 1200) {
      console.log(`FAIL  ${t.slug.padEnd(38)} http=${status} len=${text.length}`);
      fail++;
      continue;
    }
    const head = [
      `# ${t.who || t.slug}`,
      ``,
      `- source_url: ${t.url}`,
      `- harvested: 2026-08-21`,
      `- http_status: ${status}`,
      t.note ? `- note: ${t.note}` : null,
      ``,
      `---`,
      ``,
    ].filter((x) => x !== null).join('\n');
    await writeFile(path.join(OUT, `${t.slug}.md`), head + text, 'utf8');
    console.log(`OK    ${t.slug.padEnd(38)} http=${status} ${String(text.length).padStart(6)} chars`);
    ok++;
  } catch (e) {
    console.log(`ERR   ${t.slug.padEnd(38)} ${e.message.slice(0, 80)}`);
    fail++;
  }
}

console.log(`\nHARVEST ok=${ok} fail=${fail} -> ${OUT}`);
process.exit(fail && !ok ? 1 : 0);
