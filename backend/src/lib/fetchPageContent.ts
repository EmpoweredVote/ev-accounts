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
 * RENDER DEPLOYMENT:
 * Add this to the Render build command for the backend service:
 *   npm install && npx playwright install chromium --with-deps && npm run build
 */

import { chromium } from 'playwright';

const TIMEOUT_MS = 20_000;

export async function fetchPageContent(url: string): Promise<string> {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: TIMEOUT_MS });

    // Wait a beat for JS-rendered content to settle
    await page.waitForTimeout(2000);

    const text = await page.evaluate(() => document.body.innerText);
    return text.trim();
  } finally {
    await browser.close();
  }
}
