# Tennessee legislature portraits — source prep, 2026-09-24

**130 owed.** Tennessee is the largest single portrait gap left in the corpus and the only state
where an entire seated legislature renders nothing at all. It is **not a Knight state** — this is
corpus-wide portrait work, the shape of the Florida and Washington sweeps, not a slice.

Nothing has been written. This is a source and licence assessment only.

✅ **THE LICENCE IS SETTLED (2026-09-24)** — `(C) State of Tennessee, "editorial or personal use
only"`, found **inside the PNG metadata**, not on any page. What remains is an operator ruling on
whether our use is editorial. [Jump to it](#-the-licence-is-settled--and-it-was-never-on-a-page).

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

## ✅ THE LICENCE IS SETTLED — AND IT WAS NEVER ON A PAGE

**`(C) State of Tennessee — "Editorial or personal use only, all other uses require written
permission."`** Photographer **Jed DeKalb**, Chief Photographer for Tennessee State Government.

🔴🔴 **THE POLICY IS EMBEDDED IN THE IMAGE FILES, NOT PUBLISHED ON THE SITE.** Every earlier pass
looked for a disclaimer page, because that is where NC's and OH's answers were. Tennessee has no
such page — and it does not need one, because the rights statement travels inside each portrait as
a PNG `tEXt` chunk. ▶ **When a site publishes no policy, read the bytes it publishes instead.**
The statement is only visible after the base64 is decoded, which is why two prior passes and a
whole-site sweep both missed it.

### Measured across all 132 districts, 2026-09-24

131 portraits read (H84 is **Vacant** on the GA's own page — matching our 98 seated House exactly,
from two independent directions). 0 fetch failures.

| `Copyright` field | count |
| --- | --- |
| *(absent)* | 112 |
| `(C)2012 State of Tennessee  Editorial or personal use only, all other uses require written permission` | 5 |
| `(C)2013 …` *(same sentence)* | 3 |
| `(C)2017 …` *(same sentence)* | 3 |
| `(C)2015 …` *(same sentence)* | 1 |
| `(C) 2008 State of Tennessee` *(no terms)* | 3 |
| `(C) 2007 State of Tennessee` *(no terms)* | 1 |
| `x-default` *(empty placeholder)* | 3 |
| **carrying a rights string** | **19 of 131** |

`Author = Jed DeKalb` on **14**. Per-district record:
[`backend/data/tn-portrait-metadata-2026-09-24.json`](../../backend/data/tn-portrait-metadata-2026-09-24.json).

⚠ **A MINORITY CARRIES THE STRING, AND NOTHING CONTRADICTS IT.** The other 112 are not a different
licence — they are the same photographs re-saved by a tool that drops metadata (`Software` reads
`GIMP 2.10.8`, `GIMP 2.10.22`, `Adobe Photoshop CS6` on sampled rows). **Every rights string that
exists names the same owner and, where it states terms, the same terms.** Treat the set as one
licence; do not treat a stripped file as unencumbered.

⚠ **`Copyright = x-default` IS AN EMPTY FIELD, NOT A CLAIM.** It is the XMP language-alternative tag
surviving a blank value. Three rows carry it. Read the value, never the presence of the key.

### What this licence is, and is not

- It is an **explicit copyright assertion** by the State of Tennessee. This is **stronger** than
  Ohio, where only a blanket footer existed and the ruling was `press_use` on the reasoning that
  *no restriction was published*. Here a restriction **is** published.
- It is also an **explicit grant** for editorial use — which Ohio never gave. So Tennessee is
  neither the OH/GA/FL/PA shape (silence) nor the MN shape (a published refusal). **It is a third
  shape: a published permission with a stated limit.**
- ▶ **The operator decision is whether Empowered Vote's use is "editorial".** Displaying an
  officeholder's portrait beside their seat, district and record is informational, not promotional
  — but the sentence closes with *"all other uses require written permission"*, so the judgement
  belongs to Cantrell and not to this file. If the answer is anything but a confident yes, the MN-5
  route applies: ask, and ship nothing until the answer arrives.

### How the whole-site sweep was proved, not assumed

`capitol.tn.gov` publishes **no** disclaimer, terms-of-use, copyright or photo policy anywhere:

- The **site map lists the whole site** and contains no policy page. The master layout's footer
  offers only Home · Homework Help · About · Help & FAQs · Capitol Tour · Legislative Links ·
  Site Map · Workplace Discrimination Policy · Careers. The member pages share that footer.
- **All 100 URLs in `capitol.tn.gov/sitemap.xml` were fetched and scanned.** Two hits, both false:
  *"unlawful photography"* in a bill subject line, and *"reproducing"* in the how-a-bill-becomes-law
  explainer. **0 of 100 carry a `(C)` symbol or the word "copyright".**
- 🔴 **THE SOFT 404 IS REAL AND IT IS WHY GUESSED PATHS PROVE NOTHING.** Any missing path returns
  **HTTP 200** with `og:url = https://capitol.tn.gov/Error.aspx` and the title *"Page Not Found -
  Tennessee General Assembly"*, at a stable 39,985 bytes. A classifier keyed on that signature was
  **controlled both ways** — it called the bogus path SOFT-404 and the homepage REAL — before any
  candidate was judged.
- ✅ **Controls on every "nothing found".** The 100-page sweep was checked for a footer word known
  to be present: **100 of 100**. The `(C)`-symbol detector was controlled against `ohiohouse.gov`
  (fires) and `tn.gov/web-policies.html` (9 hits for "copyright"), so its zero on the GA is a real
  zero and not a blind one.
- **`tn.gov`'s statewide web policies do not reach the legislature.** The set is Privacy,
  Accessibility, Linking, Security, COPPA and DMCA — **no terms-of-use and no copyright grant** —
  and the DMCA page scopes itself to *"the TN.gov site (the 'Site')"* and only describes how to
  **send** an infringement notice. The GA site links to none of them.
- ⚠ **`robots.txt` on both hosts ends `User-agent: * → Disallow: /`.** Named crawlers are allowed
  (Googlebot, Bingbot, DuckDuckBot, Slurp, Siteimprove, `archive.org_bot`); a generic agent is not.
  That is not a copyright term, but it is a stated wish about automated fetching, and a 132-page
  extractor run should be slow and one-pass.
- 🔴 **ONE CHECK CAME BACK BLIND AND IS RECORDED AS UNKNOWN.** The Wayback CDX index was queried for
  any archived `capitol.tn.gov` URL containing a policy word. It returned empty — **and so did the
  positive control**, because the Internet Archive was serving **HTTP 503 "Temporarily Offline"**.
  The empty result is therefore evidence of nothing. Whether a policy page once existed and was
  removed is **still open**; re-run it when the archive is back.

### The files themselves

Decoded and inspected. The House portrait is **400x400 PNG, RGBA** — so alpha must be composited
onto white, not discarded. Senate rows are mostly **RGB**; two are off-square (**400x405**,
**381x400**), so the crop cannot assume 1:1. Sizes are otherwise uniform at 400x400, confirming the
**1.88x enlargement** problem stands unchanged.
✅ One portrait was decoded and **looked at** (H7, Rep. Rebecca Alexander): a real studio portrait on
a grey gradient, not a badge or a placeholder. The uniform backdrop across the set is consistent
with a single state photographer, which is what the `Author` field says.
🟢 **The extractor is one regex.** `src='data:image/png;base64,…'`, one match per member page, keyed
by district — no name matching, no collision risk.

---

## 🔴 SUPERSEDED — the earlier reading of the licence

## 🔴 THE LICENCE IS UNRESOLVED FOR BOTH SOURCES

No photo policy was found for the General Assembly. ⚠ **`capitol.tn.gov/disclaimer.html` returns
HTTP 200 with the title "Page Not Found"** — a soft 404. That is a guessed URL failing, **not
evidence that no policy exists**: NC's public-domain grant was three clicks deep under a heading
about photographs, and Ohio's silence was only established by reading the real disclaimer. Find the
actual page before concluding anything.

The caucus sites' licence is a separate and weaker question, per the above.

## What is still unknown

1. ~~**The real GA legal/disclaimer page.**~~ ✅ **RESOLVED 2026-09-24 — there is none, and the
   licence did not need one.** The whole crawlable site was swept with controls; the rights
   statement lives in the image metadata. See the top of this file.
   ⚠ One residual: the Wayback check for a *removed* policy page was **blind** (archive 503).
2. **Caucus coverage.** `tnhousegop.org/members/` yielded **52 distinct uploaded images** against
   roughly 75 House Republicans — so the page is paginated, lazy-loaded, or some of those images are
   not members. Unmeasured.
3. **The other three caucus sites.** `tnhousedems.com`, `tnsenategop.com` and `tnsenatedems.com` are
   all live but **JS-rendered**, so raw-HTML link extraction returns nothing and the member pages
   were not located. ⚠ That is a rendering limitation, not an absence — they need Playwright.
   `tnsenategop.com/members/`, `/senators/` and `/our-members/` are all 404, so the path is
   something else.
4. ~~The Tennessee Blue Book.~~ ✅ **REACHED AND RULED OUT — see below.**

## 🔴 THE BLUE BOOK IS RULED OUT ON RESOLUTION — ITS PORTRAITS ARE 119x153

Reached 2026-09-24 at **`sos.tn.gov/blue-book`**. ⚠ The earlier 404 was a guessed path, as
suspected; the real page exists and the current edition is **2025-2026**, published as per-section
PDFs at `publications.tnsosfiles.com/pub/blue_book/25-26/` — `25-26_House.pdf` (39 MB, 124 pages)
and `25-26_Senate.pdf` (13 MB, 60 pages).

**The member portraits inside are ~119x153.** Enumerated with PyMuPDF and confirmed by eye — they
are unmistakably the members, not decoration:

| chapter | pages | embedded images | commonest portrait sizes |
| --- | --- | --- | --- |
| House | 124 | 113 | 119x153 (49) · 116x154 (26) · 116x156 (11) · 103x137 (7) |
| Senate | 60 | 49 | 116x154 (10) · 119x153 (7) · 97x123 (5) · 103x137 (4) |

A 119x153 source needs **5.0x** to reach 600x750 — nearly three times worse than the GA member
page's already-poor 1.88x.
⚠ **A 39 MB PDF IS NOT EVIDENCE OF LARGE IMAGES.** The file is big because it is 124 print pages,
not because the portraits are. Measure the embedded raster, never the download size.

▶ **The Blue Book was the best LICENCE answer and it is the worst PIXELS.** It cannot be the
source, and the party-provenance question it might have dissolved is still live.

## Order of work when this opens

1. ~~Find the GA's real disclaimer and settle the licence.~~ ✅ **DONE 2026-09-24 — the licence is
   `(C) State of Tennessee, editorial or personal use only`, read out of the PNG metadata.**
   ▶ **The open item is now an operator ruling, not research**: is our use "editorial"? Nothing
   ships before that answer.
2. ~~Reach the Blue Book.~~ **Done — ruled out on resolution, 119x153.**
3. Measure caucus coverage properly, in Playwright, across all four sites — they are now the only
   known source above 400x400.
4. Decide the spine-plus-upgrade question above, and get the 400x400 enlargement judged on a
   contact sheet **before** building the extractor, not after.
