---
name: ref-bend-oregon-sources
description: Working fetch routes for Bend/Deschutes OR stance research — bendbulletin plain curl beats jina, and where the county voters' pamphlet PDF actually lives
metadata:
  type: reference
---

Fetch routes verified 2026-07-25 for Bend / Deschutes County / Central Oregon.

## bendbulletin.com — use plain curl, NOT r.jina.ai

`curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120"` returns
**full article bodies and working `?s=<query>` search**. No paywall interception on the article HTML.

**`r.jina.ai` times out (HTTP 422 TimeoutError) on bendbulletin even with `x-no-cache: true`.**
Do not route this domain through jina.

- Search: `https://www.bendbulletin.com/?s=Anthony+Broadman`, paginate `https://www.bendbulletin.com/page/2/?s=...`
- Harvest URLs with: `grep -oE 'href="https://bendbulletin.com/[0-9]{4}/[0-9]{2}/[0-9]{2}/[a-z0-9\-]+/"'`
- Extract prose from `<p>` tags. **Apostrophes arrive as `&#8217;` → U+2019 `’`.** Normalize entities
  before string-matching any quote, or a correct quote looks like a mismatch.
- This paper carries guest columns *by* local politicians (first-person, quotable) and names council
  roll-call counts — it resolved a city-council vote I couldn't get from the city site.

## Oregon county voters' pamphlets (State Library digital collections)

Landing page: `https://digitalcollections.library.oregon.gov/nodes/view/<NODE>`
(2024 Deschutes = node **281745**; expect a sibling node per county per election).

- **`/nodes/download/<NODE>` returns HTML, not the PDF.** The real PDF is
  **`https://digitalcollections.library.oregon.gov/assets/displaypdf/<NODE>`**.
- `pdftotext` emits a harmless `Unknown character collection 'Adobe-Korea1'` warning.
- Run **without `-layout`** — these are two-column candidate pages and `-layout` interleaved the
  columns *worse* than plain mode.
- **Attribute by the `(This information furnished by X.)` delimiter, never by page co-location.**
  Two opposing candidates share a spread; the delimiter is the only reliable boundary.
- Party line appears in a contents row like `27th District <Name> Democrat, Independent <Name> Republican`
  — "Democrat, Independent" is one candidate cross-nominated (Oregon fusion), not two people.
- These statements are candidate-authored but usually **third person** ("Anthony will fight to…").
  Treat third-person campaign copy as a platform source, not as a quote.

## Dead / low-value routes

- `sos.oregon.gov/elections/Pages/candidate-filings.aspx` → **404**. Ballotpedia was the working
  route to a 2026 candidate field.
- `bendoregon.gov` 403s all non-browser fetches (known); often avoidable — Bulletin reporting
  supplied the council vote instead.
- Ballotpedia answered plain curl 200 this session (no 403, no Playwright needed), but its
  **biography pages carry zero stance content** — good for identity/field confirmation only.

## Bend-specific evidence anchors

- Bend camping code adopted **11/16/2022 on a 4-3 council vote** — a real dividing line among Bend
  councilors of that era. Coverage:
  `bendbulletin.com/2022/11/17/the-bend-city-council-has-approved-rules-for-unhoused-camping-in-public/`
- Bend's **$190M transportation GO bond** passed Nov 2020; the Transportation Bond Oversight
  Committee is where councilors' multimodal-vs-roads positions surface.

See [[ref_oregon_olis_odata_api]], [[stance_broadman_summers_or_sd27_hd53]].
