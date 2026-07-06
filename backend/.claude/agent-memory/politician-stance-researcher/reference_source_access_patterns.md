---
name: reference_source_access_patterns
description: WebFetch-only access patterns/walls for common stance-research sources (Ballotpedia, Vote411, smarter.vote, campaign sites) observed during SC 2026 House research
metadata:
  type: reference
---

Observed 2026-07-06 while researching SC-4 candidates (Courtney McClain,
Jessica Ethridge) under the WebFetch-only constraint (no WebSearch, no
Playwright).

## Walled / unreliable sources (direct WebFetch AND r.jina.ai proxy both fail)
- **ballotpedia.org** — direct WebFetch returns "content appears empty";
  r.jina.ai proxy returns 403 Forbidden. Consistent wall in both this repo's
  main-project memory and this local run. Don't burn more than one attempt
  each way before moving on.
- **vote411.org** — 403 direct.
- **smarter.vote/races/.../candidate-slug/** — loads but for
  under-covered down-ballot candidates often just says "We haven't found any
  issue stances for this candidate yet" — a real, honest null result, not a
  wall. Still worth checking, cheap.
- **oppintell.com** — candidate profile pages 404 when not yet enriched.
- **web.archive.org** — WebFetch is entirely blocked from fetching this host
  in this environment ("Claude Code is unable to fetch from web.archive.org").
  Don't bother trying Wayback Machine at all.

## Discovery trick: r.jina.ai + DuckDuckGo HTML search
`https://r.jina.ai/https://duckduckgo.com/html/?q=<url-encoded query>` reliably
returns a clean list of result titles + URLs (this is the sanctioned
WebSearch-quota-free substitute per the WebFetch-only rule). Use it to find:
- the candidate's real campaign website domain (candidates rarely link it
  clearly from Ballotpedia when Ballotpedia itself is walled)
- news coverage of the specific race
- old campaign social posts / prior-race artifacts (2022 runs, etc.)
Zero-result DDG queries render as DuckDuckGo's own "no results" suggestion
copy — treat that as a genuine null, not a tool failure.

## Squarespace/NationBuilder-style campaign sites (e.g. mcclainforsc.com)
Issue sub-pages often live at ugly auto-generated slugs like
`/issues/your-issue-title-hereee` (note the site owner never renamed the
default placeholder slug). The `/issues` index page itself DOES render and
list all issue titles — fetch it first with a prompt asking for
`href`/hyperlink URLs explicitly, then fetch each `/issues/<slug>` page
individually. WebFetch's default summarization sometimes paraphrases instead
of quoting — when you need an exact quote for a `quote_text` field, re-fetch
the same URL with a prompt that explicitly says "verbatim, word-for-word, no
paraphrase" — this reliably produces cleaner exact text on a second pass.

## Wix-style campaign sites (e.g. jessica4sc.com)
Nav links (e.g. an "Issues" menu item) can point to pages that don't
actually exist yet (early-stage/template sites) — direct fetch 404s even
though the link is visible in the rendered nav. To confirm whether a page
genuinely doesn't exist vs. is just hard to find, fetch
`https://<domain>/sitemap.xml` → it's usually an index pointing to
`https://<domain>/pages-sitemap.xml` → THAT file lists every actually-indexed
page URL. If the target slug isn't in that list, it doesn't exist — stop
guessing slugs and don't fabricate content for it.

## Facebook posts
A specific Facebook post permalink (not the profile timeline) sometimes
renders real post text via a direct WebFetch call even though the profile
page and the r.jina.ai proxy of the SAME post both fail (login wall). Worth
one direct-WebFetch attempt on a specific post URL surfaced via DDG search
before giving up on Facebook as a source.
