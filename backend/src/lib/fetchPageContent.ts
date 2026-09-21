/**
 * fetchPageContent — a thin, browser-free page fetch used by the discovery
 * pre-fetch (discoveryService). It runs the verification ladder (plain fetch +
 * legacy extractor → Wayback) and returns the best text it can, or throws when
 * every rung fails so the caller can fall back (discoveryService → web_search).
 *
 * HISTORY: this module used to launch a headless browser to render JS-heavy
 * municipal pages. That rung was removed — it could not run on the Alpine/musl
 * deployment and was unexercised in production. See
 * knowledge/decisions/0003-scraping-toolchain.md. Recovering the pages a plain
 * fetch cannot reach (JS-rendered / bot-protected) is decision 0003 rung 2,
 * tracked separately.
 *
 * The honest user-agent constants now live in verificationFetch.ts, next to the
 * robots.txt matcher and the fetch that sends them. They are re-exported here
 * unchanged so existing importers (backend/scripts/*, tests) keep working.
 */
export {
  EMPOWERED_VOTE_UA,
  EMPOWERED_VOTE_UA_TOKEN,
  LEGACY_BROWSER_UA,
} from './verificationFetch.js';
import { fetchForVerification } from './verificationFetch.js';

/**
 * Fetch a page's text with no browser: the verification ladder (tier 1 plain
 * fetch + legacy extractor → tier 3 Wayback). Throws when every rung fails, so
 * callers (discoveryService) fall back cleanly to web_search.
 */
export async function fetchPageContent(url: string): Promise<string> {
  return fetchForVerification(url);
}
