/**
 * Shared campaign-site crawling primitives for the stance citation tools.
 *
 * MOVED HERE VERBATIM from repair-primary-site-paths.mjs on 2026-08-01, comments intact, when
 * propose-quote-corrections.mjs needed to read the same pages the repair pass read. Same reasoning as
 * lib/claim-match.mjs: if the two tools fetch and extract text differently, then a span this tool
 * proposes as "verbatim on the page" may not be the text the repair pass scored -- and the whole point
 * of the correction pass is that the replacement text is exactly what a reader will see.
 *
 * 🔴 A THIN BODY IS NOT AN ABSENT CLAIM. A React/Vue campaign site serves an empty shell to a plain
 * fetch. Scoring that as "claim not on the site" is the same false negative as Ballotpedia's silent
 * HTTP 202, which already produced one wrong sweep. Under MIN_BODY chars => unreadable, full stop.
 *
 * Callers pass their own tuning (delays, page caps) through `opts`; the defaults are the values the
 * 223-site repair run used.
 */
import { writeFileSync, readFileSync, statSync, mkdirSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parse } from 'node-html-parser';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const DEFAULTS = {
  hostDelay: 900,       // between requests to ONE host
  maxPages: 8,          // interior pages per site
  minBody: 600,
  noCache: false,
  cacheTtlHours: 24,
};

// ---------------------------------------------------------------------------- fetching

/**
 * 🔴 BUMP CACHE_VERSION WHENEVER THE CACHED PAGE SHAPE CHANGES. Adding `chrome` to the page record
 * left every existing cache entry without it, and `chrome ?? ''` turns that into an empty footer --
 * i.e. silently back to the bug the field was added to fix, for a full cache TTL. A stale cache that
 * looks like a successful read is the same failure mode as the HTTP 202 with an empty body.
 */
const CACHE_VERSION = 4;
const CACHE_DIR = path.join(os.tmpdir(), `primary-site-cache-v${CACHE_VERSION}`);
const cachePath = (u) => path.join(CACHE_DIR, `${Buffer.from(u).toString('base64url').slice(0, 180)}.json`);

function cacheGet(u, o) {
  if (o.noCache) return null;
  try {
    if (Date.now() - statSync(cachePath(u)).mtimeMs > o.cacheTtlHours * 3600 * 1000) return null;
    return JSON.parse(readFileSync(cachePath(u), 'utf8'));
  } catch { return null; }
}
function cachePut(u, page, o) {
  if (o.noCache) return;
  // Only cache a GOOD read, for the same reason the citation audit does: caching a failure freezes it.
  try {
    mkdirSync(CACHE_DIR, { recursive: true });
    if (page.status === 200 && page.body.length >= o.minBody) writeFileSync(cachePath(u), JSON.stringify(page));
  } catch { /* best effort */ }
}

/**
 * Strip the furniture, keep the prose. Campaign sites repeat their nav on every page.
 *
 * 🔴 DO NOT SCOPE TO <main>. It was an optimisation to cut nav noise, and the nav/header/footer strip
 * above already does that job -- but scoping THREW AWAY EVERY SECTION A SITE BUILDER PUT OUTSIDE
 * <main>, which on Webflow/Wix single-page campaign sites is routinely the entire issues section.
 *
 * Measured on the Wayback capture of neighbors4faye.com 2026-08-01: 2,667 chars kept out of 4,797.
 * The 2,667 was a biography and a donate box; the discarded 2,130 was "important Issues" —
 * homelessness, Public Safety, housing, infrastructure — including the exact string one of her rows
 * quotes, "Treatment First, Housing Second." Four rows were about to be retired as unsourced on the
 * strength of that omission, and the archive proved them right all along.
 *
 * Same root cause as the campaign-finance disclaimer being invisible (see chromeText). An extractor
 * that silently keeps 55% of a page and reports nothing is the most dangerous shape of bug in this
 * whole workstream: the loss looks exactly like an absent claim.
 */
function pageText(html) {
  const root = parse(html);
  root.querySelectorAll('script,style,noscript,svg,nav,header,footer,form').forEach((n) => n.remove());
  const body = root.querySelector('body') ?? root;
  return body.textContent.replace(/\s+/g, ' ').trim();
}

/**
 * The chrome `pageText` throws away, returned SEPARATELY rather than merged into the body.
 *
 * 🔴 THE CAMPAIGN-FINANCE DISCLAIMER LIVES IN THE FOOTER, AND CAMPAIGN-FINANCE ROWS CITE IT. Kshama
 * Sawant's row quotes "Paid for by Kshama For Congress, not corporate cash." That string is on her
 * homepage VERBATIM -- inside <footer>, which pageText removes, so the row scored as quoting something
 * absent. Of all the topics in the compass, Campaign Finance is the one whose best evidence is
 * routinely a disclaimer rather than a plank.
 *
 * It is kept separate, not folded into the body, because footers and navs repeat every issue keyword
 * on the site ("Issues", "Priorities", "Healthcare") on EVERY page -- merging them would hand the term
 * test the same no-signal haystack that made the full-page keyword probe useless. A caller that wants
 * this evidence has to ask for it and say so in its output.
 */
/**
 * 🔴 THIS MUST STAY THE EXACT COMPLEMENT OF pageText, OR IT DOUBLE-COUNTS. An earlier version removed
 * <main> and returned the rest, which was right only while pageText scoped TO <main>. Now that
 * pageText keeps the whole body minus nav/header/footer/form, those four ARE the complement -- and the
 * old form would have returned most of the body a second time, so the proposer would have found body
 * text and labelled it "[footer/nav]". Whenever pageText's selector changes, change this with it.
 */
function chromeText(html) {
  const root = parse(html);
  root.querySelectorAll('script,style,noscript,svg').forEach((n) => n.remove());
  return root.querySelectorAll('nav,header,footer,form')
    .map((n) => n.textContent).join(' ').replace(/\s+/g, ' ').trim();
}

async function fetchPage(url, opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const hit = cacheGet(url, o);
  if (hit) return { ...hit, cached: true };
  let res;
  try {
    res = await fetch(url, {
      headers: { 'User-Agent': UA, Accept: 'text/html' },
      redirect: 'follow', signal: AbortSignal.timeout(30000),
    });
  } catch (e) { return { status: 0, error: e.message, body: '', html: '', finalUrl: url }; }
  if (res.status !== 200) return { status: res.status, body: '', html: '', finalUrl: res.url || url };
  const ct = res.headers.get('content-type') ?? '';
  if (!/html/i.test(ct)) return { status: 200, body: '', html: '', finalUrl: res.url || url, notHtml: ct };
  // 🔴 THE BODY READ THROWS TOO, AND IT IS NOT COVERED BY THE TRY AROUND fetch(). A server that
  // closes the connection mid-response ("SocketError: other side closed") rejects here, not at
  // fetch(). Leaving it uncaught killed a 223-site run at site 180 and discarded every result.
  let html;
  try { html = await res.text(); }
  catch (e) { return { status: 0, error: `body read failed: ${e.message}`, body: '', html: '', finalUrl: res.url || url }; }
  let page;
  try { page = { status: 200, body: pageText(html), chrome: chromeText(html), html, finalUrl: res.url || url }; }
  catch (e) { return { status: 0, error: `parse failed: ${e.message}`, body: '', html: '', finalUrl: res.url || url }; }
  cachePut(url, page, o);
  return page;
}

const ISSUEISH = /issue|platform|priorit|policy|policies|position|stand|vision|plan|agenda|values|about|meet|why|solution/i;
const SKIP = /^(mailto:|tel:|javascript:|#)|\.(pdf|jpe?g|png|gif|svg|zip|mp4|docx?)$|\/(donate|contribute|volunteer|shop|store|privacy|terms|login|events?|press|news|media|contact)(\/|$)/i;

/**
 * 🔴 /home IS THE HOMEPAGE. Squarespace and Wix serve the front page at both / and /home, so
 * proposing site.com/home in place of site.com adds a path and no precision whatsoever -- it looks
 * like a repair in the tally and is not one.
 */
const HOME_ALIAS = /^\/(home|index|main|home-1|homepage)(\.html?|\.php)?$/i;
function isHomeAlias(url, rootUrl) {
  try {
    const u = new URL(url); const r = new URL(rootUrl);
    if (u.hostname.replace(/^www\./, '') !== r.hostname.replace(/^www\./, '')) return false;
    return HOME_ALIAS.test(u.pathname.replace(/\/$/, '') || '/') || (u.pathname.replace(/\/$/, '') === '');
  } catch { return false; }
}

/** Same-host interior links that look like they hold positions, best-looking first. */
function discoverLinks(html, baseUrl, opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const root = parse(html);
  const base = new URL(baseUrl);
  const scored = new Map();
  for (const a of root.querySelectorAll('a')) {
    const href = a.getAttribute('href');
    if (!href || SKIP.test(href.trim())) continue;
    let u;
    try { u = new URL(href, base); } catch { continue; }
    if (u.hostname.replace(/^www\./, '') !== base.hostname.replace(/^www\./, '')) continue;
    if (u.protocol !== 'https:' && u.protocol !== 'http:') continue;
    u.hash = ''; u.search = '';
    const clean = u.toString().replace(/\/$/, '');
    if (clean === baseUrl.replace(/\/$/, '')) continue;
    if (SKIP.test(u.pathname)) continue;
    if (isHomeAlias(clean, baseUrl)) continue;
    const text = (a.textContent ?? '').trim().slice(0, 80);
    const score = (ISSUEISH.test(u.pathname) ? 2 : 0) + (ISSUEISH.test(text) ? 1 : 0);
    if (score === 0) continue;
    if (!scored.has(clean) || scored.get(clean).score < score) scored.set(clean, { url: clean, text, score });
  }
  return [...scored.values()].sort((a, b) => b.score - a.score).slice(0, o.maxPages);
}

async function crawlSite(rootUrl, opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const home = await fetchPage(rootUrl, o);
  if (home.status !== 200 || home.body.length < o.minBody) {
    // A 404/410 on the root, or a hostname that no longer resolves, is a DEAD SITE -- a different
    // problem from a page we merely failed to read, and the only one of the two a human can act on.
    const dead = home.status === 404 || home.status === 410
      || (home.status === 0 && /ENOTFOUND|EAI_AGAIN|ERR_NAME|certificate|ECONNREFUSED/i.test(home.error ?? ''));
    return {
      ok: false,
      dead,
      status: home.status,
      reason: home.status !== 200 ? `status ${home.status}${home.error ? ` (${home.error})` : ''}` : `thin body ${home.body.length}c`,
      pages: [],
    };
  }
  const pages = [{ url: home.finalUrl.replace(/\/$/, ''), body: home.body, chrome: home.chrome ?? '', html: home.html, isHome: 1 }];
  for (const link of discoverLinks(home.html, home.finalUrl, o)) {
    if (!home.cached) await sleep(o.hostDelay);
    const p = await fetchPage(link.url, o);
    if (p.status === 200 && p.body.length >= o.minBody) {
      pages.push({ url: link.url, body: p.body, chrome: p.chrome ?? '', html: p.html, isHome: 0 });
    }
  }
  return { ok: true, pages };
}

/** Run `worker` over `items` with at most `n` in flight. */
async function pooled(items, n, worker) {
  const out = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await worker(items[i], i);
    }
  }));
  return out;
}

export {
  UA, sleep, pageText, chromeText, fetchPage, discoverLinks, isHomeAlias, crawlSite, pooled,
  ISSUEISH, SKIP,
};
