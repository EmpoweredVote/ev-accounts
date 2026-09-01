/**
 * fetchPageContent — renders a URL with a headless Chromium browser and returns
 * the visible text content of the page.
 *
 * WHY PLAYWRIGHT INSTEAD OF node-fetch:
 * Municipal election pages (e.g. Glendale, Pomona) render candidate rosters via
 * JavaScript. A plain HTTP fetch returns a skeletal HTML shell with no candidate
 * names. Playwright executes the JS and waits for the DOM to settle before
 * extracting text — the same content a human browser would see.
 *
 * `renderPage(browser, url)` is the reusable core: callers that fetch many URLs
 * in a batch (e.g. the stance-research verifier) launch ONE browser and reuse it
 * across pages instead of paying a fresh launch per URL. `fetchPageContent(url)`
 * is the standalone convenience used by single-shot callers (discoveryService).
 *
 * RENDER DEPLOYMENT:
 * Add this to the Render build command for the backend service:
 *   npm install && npx playwright install chromium --with-deps && npm run build
 */

import { chromium, type Browser } from 'playwright';

const TIMEOUT_MS = 20_000;

/**
 * Honest user-agent. Names Empowered Vote, links a public policy page, and
 * gives a contact address so a publisher can reach us or ask to be excluded.
 *
 * The product token `EmpoweredVoteBot` is what a site's robots.txt matches on
 * (see verificationFetch.ts), so it must stay stable — do not reword it.
 *
 * Rationale: decision knowledge/decisions/0003-scraping-toolchain.md (rung 0).
 * From 15 Sep 2026 Cloudflare's defaults classify an unlabelled fetcher that
 * pretends to be a desktop browser as "evasive". An honest, contactable UA is
 * both more defensible and more likely to be allowed.
 *
 * Contact address confirmed by the founders (Chris, 2026-09-01): info@empowered.vote.
 */
export const EMPOWERED_VOTE_UA =
  'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';

/**
 * The robots.txt product token for {@link EMPOWERED_VOTE_UA}. Matching is
 * case-insensitive; kept as a named constant so the fetcher and the UA cannot
 * drift apart.
 */
export const EMPOWERED_VOTE_UA_TOKEN = 'EmpoweredVoteBot';

/**
 * DEPRECATED — a spoofed desktop Chrome user-agent. Kept, exported and UNUSED
 * only so its removal is a deliberate, reviewed act rather than a silent one.
 *
 * 🔴 Do NOT reintroduce this into any live fetch path without a founder
 * decision. Pretending to be a browser is exactly the profile Cloudflare's
 * 15 Sep 2026 defaults target, and it is indefensible for a civic-trust
 * nonprofit bound by a radical-transparency clause. Use {@link EMPOWERED_VOTE_UA}.
 */
export const LEGACY_BROWSER_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

/**
 * Render one URL in an already-launched browser and return its visible text.
 * The caller owns the browser lifecycle (so it can be reused across a batch).
 */
export async function renderPage(browser: Browser, url: string): Promise<string> {
  const page = await browser.newPage({ userAgent: EMPOWERED_VOTE_UA });
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: TIMEOUT_MS });
    // Wait a beat for JS-rendered content to settle.
    await page.waitForTimeout(2000);
    // Nudge lazy-loaded content into the DOM.
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight)).catch(() => {});
    await page.waitForTimeout(500);
    const text = await page.evaluate(() => document.body.innerText);
    return text.trim();
  } finally {
    await page.close();
  }
}

export async function fetchPageContent(url: string): Promise<string> {
  const browser = await chromium.launch({ headless: true });
  try {
    return await renderPage(browser, url);
  } finally {
    await browser.close();
  }
}
