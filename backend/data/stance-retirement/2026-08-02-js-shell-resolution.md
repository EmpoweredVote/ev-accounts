# The 55 JS-shell rows — rendered and classified

The 2026-08-01 sweep found 20 cited hosts, behind **55 published rows**, that return a shell to a plain
`fetch` — several with a body of **zero characters**. Every tool on this workstream reads with plain
fetch, so all of them were blind to these sites. Re-probed with a real browser via the new
`scripts/read-site-js.mjs`.

## 🔴 32 of the 55 rows sit on sites that are full of content

| host | plain | rendered | rows |
|---|---|---|---|
| `tedbrown.org` | 38c | **25,849c** (680×) | 8 |
| `whit4ilsenate.com` | 0c | **24,501c** | 3 |
| `julietle4congress.com` | 0c | 12,461c | 1 |
| `devin4wa.com` | 0c | 12,444c | 3 |
| `gloria4utah.com` | 0c | 10,341c | 2 |
| `hyman4mayor.com` | 0c | 9,311c | 2 |
| `joshuajames4tn.com` | 0c | 6,554c | 2 |
| `cambridgema.iqm2.com` | 0c | 5,448c | 2 |
| `supervisorjimdesmond.com` | 544c | 4,889c (9×) | 1 |
| `fellerforcongress.com` | 0c | 3,653c | 4 |
| `ernie4senate.com` | 0c | 2,705c | 1 |
| `foxforwa.com` | 0c | 2,391c | 1 |
| `wash4council.com` | 0c | 1,675c | 1 |
| `ltgov.nc.gov` | 422c | 897c (2×) | 1 |

**Any verdict a plain-fetch tool ever reached about these 32 rows is void, not negative.** Had the
citation audit or the topic probe been pointed at them, each would have scored "claim not on the page"
against a haystack of 0–38 characters. `lib/site-crawl.mjs` has warned about exactly this in its header
since the neighbors4faye near-miss — *"A THIN BODY IS NOT AN ABSENT CLAIM"* — and this is the first time
the rule has been backed by a tool that can actually see the pages.

✅ **Nothing was wrongly judged.** Cross-checking confirmed zero overlap between these rows and the
83-row cohort read in the `NO_QUOTE` review, so no verdict on this workstream ever rested on a shell.
These rows are **unverified**, not defective — and now they are readable.

## The other 23 rows: genuinely thin, not a tooling problem

| host | plain → rendered | rows | note |
|---|---|---|---|
| `www.jeionward.com` | 0c → **0c** | 2 | renders nothing even in a browser |
| `summerforpa.com` | 323c → 169c | 5 | ⚠ an official campaign site returning almost nothing is odd — may block headless. **Not** to be read as an absent claim |
| `moforla.com` | 180c → 106c | 1 | genuinely a stub |
| `nathanaelschultz.com` | 568c → 853c | 3 | small but real |
| `mikenicholsforcongress.com` | 563c → 579c | 2 | small but real |
| `evandone.com` | 93c → 93c | 10 | genuinely a 93-character page carrying **10 rows** |

## 🔴 `evandone.com` — a FOURTH failure mode: the site was reset for a different campaign

**11 rows** (not 10 — one pairs it with a second source) cite a page whose entire rendered content is:

> *"Coming in 2028 · A VOICE FOR PROGRESS. A CHAMPION FOR ALL. · MAKE A DONATION · SIGN UP TO VOLUNTEER"*

The rows quote very specific 2026 platform language — *"saving the Great Salt Lake"*, *"improving air
quality through renewable energy"*, *"protecting public lands from exploitation"*, *"criminal justice
reform emphasizing compassion, recovery, and inclusion"*, and a dated January 2026 statement about the
Utah homeless campus. **None of it is there.** The site has been rebuilt for a 2028 run.

⚠ **Nothing we check can see this.** Status **200**, well-formed URL, live host, correct candidate,
and a page that is not empty, not a shell and not malformed — it simply no longer says what it said.
It is not GONE, not THIN_SHELL, not NON_URL_SOURCE, and it will sail through the deep-URL sweep as OK.
**A citation can rot without breaking**, and that is a class none of the tooling addresses.

Not resolved: the last full-page Wayback capture (`20251015205910`) is itself only 342c, so the 2026
platform may not be archived at the root. 2026 captures exist for `/author/…` and a paginated URL and
have not been checked. **Owed: find whether the cited content is archived anywhere; if not, these 11
rows are unsourceable and need re-research.**

*(The original note here — "ten rows citing a 93-character page, same shape as Kirkland" — was wrong
about the cause. The page is not thin; it is different.)*

## The tool

`scripts/read-site-js.mjs` — the JS-capable twin of `read-site.mjs`. Same flags (`--site`, `--find`,
`--full`), and it prints **both** numbers, plain vs rendered, so the size of the gap is visible per page.
It proposes nothing and writes nothing.

    node scripts/read-site-js.mjs --site https://tedbrown.org --find "term|other term"

## Next

Re-read the 32 recoverable rows with `read-site-js.mjs` — they have never actually been checked. Then
`evandone.com`'s 10 rows on their own merits.
