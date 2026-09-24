# Tennessee legislature portraits — source prep, 2026-09-24

**130 owed.** Tennessee is the largest single portrait gap left in the corpus and the only state
where an entire seated legislature renders nothing at all. It is **not a Knight state** — this is
corpus-wide portrait work, the shape of the Florida and Washington sweeps, not a slice.

Nothing has been written. This is a source and licence assessment only.

## Measured 2026-09-24

| chamber | offices | seated | already ours | owed |
| --- | --- | --- | --- | --- |
| House | 99 | 98 (1 vacant) | 1 | 97 |
| Senate | 33 | 33 | 0 | 33 |
| **total** | **132** | **131** | **1** | **130** |

Every owed row has `photo_custom_url`, `photo_origin_url` **and** `urls` NULL. Honest nulls — there
is nothing to re-point, unlike North Carolina where 163 rows already carried a URL. This is a hunt.

## 🔴🔴 THE OFFICIAL PORTRAITS ARE BASE64 DATA URIs, NOT FILES

The General Assembly does publish a portrait for every member, and **there is no image URL to
mirror**. Each member page embeds it inline:

```html
<img class='framed-photo' src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUg…' />
```

▶ **Two independent checks said "no portrait" and both were wrong.** Playwright's rendered `img.src`
filter skipped it, and a grep for `.jpg|.png` references over the raw HTML returned only the site
logo. The page is ~460 KB and roughly 300 KB of that **is** the portrait. A third check — reading the
`<img` tags themselves — found it.
⚠ **Every tool in this pipeline takes a URL.** This source needs an extractor that parses the base64
out of the page and feeds the bytes in directly; `--json` candidates carrying a `url` cannot express
it as it stands.

**Enumeration is easy and safe.** Member pages are keyed by district:
`wapp.capitol.tn.gov/apps/LegislatorInfo/Member?district=H7&ga=114` — 99 House + 33 Senate, no name
matching, so none of the (first, last) collision risk NC carried.

**Resolution is the problem: every sampled portrait is 400x400 square PNG**, both chambers. After a
4:5 crop that is 320x400, so reaching 600x750 costs a **1.88x enlargement on all 130** — worse than
the single worst frame in the NC wave, applied to a whole state.

## 🟢 THE CAUCUS SITES PUBLISH THE SAME PEOPLE AT 2048x2560, AND THE RATIO IS EXACTLY 4:5

`tnhousegop.org/members/` serves WordPress `-scaled.jpg` portraits measured at **2048x2560**.
2048/2560 = **0.8 exactly**, so the 4:5 crop discards nothing and the whole frame downscales to
600x750. `-scaled` is WordPress's own cap, which means an even larger original exists at the same
path without the suffix.

| source | size | ratio | to reach 600x750 |
| --- | --- | --- | --- |
| GA member page (base64) | 400x400 | 1:1 | **1.88x enlargement** |
| House GOP caucus | 2048x2560 | **4:5 exactly** | 0.29x, no crop loss |

## ⚠ BUT SOURCING FROM CAUCUS SITES MEANS SOURCING BY PARTY

This is the objection to weigh before the resolution argument wins. There are four caucus sites, one
per party per chamber, so a member's portrait provenance would **depend on their party**. This repo
is antipartisan by design — party lives on `races.primary_party`, never on a person — and a pipeline
where Republicans are photographed by one organisation and Democrats by another reintroduces exactly
the asymmetry the portrait programme has been careful about elsewhere
([[feedback_challenger_headshot_asymmetry]]).

A caucus is also a **political organisation, not a government publisher**. The NCGA's grant works
because the chamber itself published it; a caucus site carries no such standing.

▶ **Suggested shape: the GA member page is the SPINE, the caucus sites are an UPGRADE.** Every member
gets the official 400x400 by default, so coverage and provenance are uniform and non-partisan; a
caucus portrait is used only where it exists, and the fact is recorded per row. That keeps one rule
for everyone and still takes the better pixels where they are available.

## 🔴 THE LICENCE IS UNRESOLVED FOR BOTH SOURCES

No photo policy was found for the General Assembly. ⚠ **`capitol.tn.gov/disclaimer.html` returns
HTTP 200 with the title "Page Not Found"** — a soft 404. That is a guessed URL failing, **not
evidence that no policy exists**: NC's public-domain grant was three clicks deep under a heading
about photographs, and Ohio's silence was only established by reading the real disclaimer. Find the
actual page before concluding anything.

The caucus sites' licence is a separate and weaker question, per the above.

## What is still unknown

1. **The real GA legal/disclaimer page.** Not located; `/disclaimer.html` and
   `/about/disclaimer.html` are both soft 404s.
2. **Caucus coverage.** `tnhousegop.org/members/` yielded **52 distinct uploaded images** against
   roughly 75 House Republicans — so the page is paginated, lazy-loaded, or some of those images are
   not members. Unmeasured.
3. **The other three caucus sites.** `tnhousedems.com`, `tnsenategop.com` and `tnsenatedems.com` are
   all live but **JS-rendered**, so raw-HTML link extraction returns nothing and the member pages
   were not located. ⚠ That is a rendering limitation, not an absence — they need Playwright.
   `tnsenategop.com/members/`, `/senators/` and `/our-members/` are all 404, so the path is
   something else.
4. **The Tennessee Blue Book.** The Secretary of State's official publication carries member
   portraits and would be a state work rather than a party one — the best licence answer available
   if it pans out. ⚠ `sos.tn.gov/products/blue-book` is a 404; the URL was guessed and the
   publication was not reached.

## Order of work when this opens

1. Find the GA's real disclaimer and settle the licence. Nothing ships before this.
2. Reach the Blue Book — a state publication would beat both other sources on licence.
3. Measure caucus coverage properly, in Playwright, across all four sites.
4. Decide the spine-plus-upgrade question above, and get the 400x400 enlargement judged on a
   contact sheet **before** building the extractor, not after.
