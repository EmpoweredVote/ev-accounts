#!/usr/bin/env node
/**
 * The JS-capable twin of read-site.mjs, for campaign sites that serve an empty shell to a plain fetch.
 *
 * WHY THIS HAD TO EXIST. The 2026-08-01 reachability sweep found 20 cited hosts behind 55 published
 * rows that return a shell to `fetch` -- several with a body of literally ZERO characters. Every tool
 * on this workstream reads pages with plain fetch, so all of them are BLIND to those sites:
 *   - the citation audit scores them as "claim not on the page"
 *   - the topic probe finds no topic passages
 *   - read-site.mjs reports an empty haystack
 * 🔴 EVERY ONE OF THOSE VERDICTS IS VOID, NOT NEGATIVE. `lib/site-crawl.mjs` says it in its own header
 * -- "A THIN BODY IS NOT AN ABSENT CLAIM" -- and this script is what makes that rule actionable rather
 * than merely a warning.
 *
 * It prints BOTH numbers, rendered vs plain, so the size of the lie is visible per page:
 *   evandone.com   plain=93c  rendered=8,412c
 *
 * 🔴 IT PROPOSES NOTHING AND WRITES NOTHING TO THE DATABASE. Output is for a human to read, exactly
 * like read-site.mjs.
 *
 * Usage (from backend/):
 *   node scripts/read-site-js.mjs --site https://evandone.com --find "housing|transit"
 *   node scripts/read-site-js.mjs --sites a.com,b.com --full
 */
import { chromium } from 'playwright';
import { fetchPage } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const many = (n) => argv.reduce((a, v, i) => (v === n && argv[i + 1] ? [...a, argv[i + 1]] : a), []);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);

const SITES = [...many('--site'), ...(flag('--sites') ?? '').split(',').filter(Boolean)];
const FIND = (flag('--find') ?? '').split('|').map((s) => s.trim()).filter(Boolean);
const FULL = has('--full');
const CTX = parseInt(flag('--ctx', '150'), 10);
const MAXHITS = parseInt(flag('--maxhits', '3'), 10);
const WAIT = parseInt(flag('--wait', '3500'), 10);

if (!SITES.length) { console.error('give at least one --site'); process.exit(2); }

const fold = (s) => s.toLowerCase().replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/\s+/g, ' ');
function hits(haystack, needle) {
  const H = fold(haystack); const N = fold(needle);
  const out = []; let i = H.indexOf(N);
  while (i > -1 && out.length < MAXHITS) {
    out.push(haystack.slice(Math.max(0, i - CTX), Math.min(haystack.length, i + N.length + CTX)).replace(/\s+/g, ' ').trim());
    i = H.indexOf(N, i + N.length);
  }
  return out;
}

const browser = await chromium.launch();
const ctx = await browser.newContext({
  userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36',
  viewport: { width: 1280, height: 2000 },
});

for (const site of SITES) {
  const url = /^https?:\/\//i.test(site) ? site : `https://${site}`;
  console.log(`\n${'='.repeat(100)}\n${url}\n${'='.repeat(100)}`);

  // What a plain fetch sees — the number every other tool on this workstream is working from.
  let plain = 0;
  try { const p = await fetchPage(url, { minBody: 1, noCache: true }); plain = p.body.length; }
  catch { plain = -1; }

  const page = await ctx.newPage();
  let text = ''; let status = 0; let title = '';
  try {
    const res = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
    status = res?.status() ?? 0;
    // Give client-side rendering a chance; networkidle often never fires on ad/analytics-heavy sites.
    try { await page.waitForLoadState('networkidle', { timeout: WAIT }); } catch { /* fine */ }
    await page.waitForTimeout(800);
    title = await page.title().catch(() => '');
    text = await page.evaluate(() => document.body?.innerText ?? '').catch(() => '');
  } catch (e) {
    console.log(`  ⚠ render failed: ${e.message.split('\n')[0]}`);
    await page.close();
    continue;
  }
  const rendered = text.replace(/\s+/g, ' ').trim();
  const ratio = plain > 0 ? (rendered.length / plain).toFixed(1) : '∞';
  console.log(`  status=${status}  plain=${plain}c  rendered=${rendered.length}c  (${ratio}x)  "${title}"`);
  if (rendered.length > plain * 2 && rendered.length > 600) {
    console.log('  🔴 JS SHELL CONFIRMED — any earlier verdict from a plain-fetch tool on this site is VOID');
  }

  for (const needle of FIND) {
    const h = hits(rendered, needle);
    console.log(`\n  FIND "${needle}": ${h.length ? `${h.length} HIT` : 'MISS'}`);
    for (const x of h) console.log(`    · …${x}…`);
  }
  if (FULL) console.log(`\n--- RENDERED TEXT ---\n${rendered}`);
  await page.close();
}

await browser.close();
