# `districts.official_web_url` rot — CA counties (swept 2026-08-09)

Found while seeding Sonoma (migration 1644): the stored county URL redirected to
**winecountry.com**, a commercial tourism site. Swept all 58 CA rows
(`district_type='COUNTY'`, `lower(state)='ca'`) with `curl -L`, 12s timeout.

**A URL that resolves is not evidence that it resolves to the county.** Sonoma returned HTTP 200
the whole time it was pointing at a travel brand.

All of these came from the migration-1619 import, so **the other states almost certainly share
this** — sweep them before deciding the fix is CA-only.

## Counts

| Class | N | Meaning |
|---|---|---|
| OK | 15 | 200, same host |
| REDIRECT-OFFHOST | 14 | 200 but lands on a different host — mostly benign `.ca.us`→`.gov`, **2 are not** |
| DEAD | 14 | connection/DNS failure |
| 403-maybe-WAF | 13 | **needs a browser check before touching** — a WAF 403 is not a dead site |
| HTTP-502 | 1 | Humboldt |
| HTTP-301 | 1 | Tulare (redirect loop / unresolved) |

## 🔴 Fix first — pointing at NON-COUNTY sites

- **06091 Sierra** — `http://www.sierracounty.ws` → `https://mampir123.org/` ("The mampir123",
  an expired-domain takeover). **STILL BROKEN IN PROD.** Real site appears to be
  `sierracounty.ca.gov` — verify before writing.
- **06097 Sonoma** — `sonomacounty.org` → winecountry.com. ✅ FIXED in migration 1644.

## 🔴 Typo

- **06033 Lake** — stored `http://www.w.co.lake.ca.us` (note `www.w.`). `co.lake.ca.us` answers
  200; current site is `lakecountyca.gov`.

## Method notes for the fix

1. **Do not bulk-replace.** The 12 `403`s are the same WAF pattern this wave keeps hitting
   (Ventura returned HTTP 200 with a 269-byte "Request Rejected" body). Check each in a browser.
2. Prefer the county's current `.gov` host where the redirect already lands there — the
   REDIRECT-OFFHOST rows are mostly free wins (`co.fresno.ca.us` → `fresnocountyca.gov`, etc.).
3. Verify the destination is the county, not a lookalike. That is the whole point of this file.
4. Guard the migration on end state (`official_web_url` equals the intended value per geo_id),
   scoped by `district_type` — geo_id is not unique.

## Full sweep result

Raw classified output (geo_id, county, class, stored URL, final URL) is in
`.planning/todos/data/2026-08-09-ca-county-url-sweep.tsv`.
