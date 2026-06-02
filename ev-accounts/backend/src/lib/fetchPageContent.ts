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

// A realistic desktop Chrome UA — some sites serve a stub or a bot challenge to
// the default headless UA. Harmless for sites that don't care.
export const REALISTIC_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

/**
 * Render one URL in an already-launched browser and return its visible text.
 * The caller owns the browser lifecycle (so it can be reused across a batch).
 */
export async function renderPage(browser: Browser, url: string): Promise<string> {
  const page = await browser.newPage({ userAgent: REALISTIC_UA });
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
