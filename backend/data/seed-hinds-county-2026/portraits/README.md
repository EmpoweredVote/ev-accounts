# Hinds County, Mississippi — portraits

Opened 2026-10-31, continuing the Jackson + Hinds deep seed
(`backend/data/seed-jackson-ms-2026/ROSTERS.md`, ev-accounts #1248, `CC_0320`-`CC_0324`).
That wave seated **28 Hinds offices, 28 holders, 0 portraits**. This one sources the portraits.

## 🔴🔴 THE COUNTY PUBLISHES A PORTRAIT FOR 12 OF ITS 28 OFFICEHOLDERS, AND NONE FOR THE OTHER 16

**The 16 are not a sourcing failure. They are what the county publishes**, read office by office:

| office group | n | what the county's own page carries |
| --- | --- | --- |
| Justice Court Judge 1-5 | 5 | courthouse address and phone, **no image**, all five identically |
| Constable 1-5 | 5 | the officer's name and district, **no image**, all five |
| Election Commissioner 1-5 | 5 | one **contact table** — name, district, email. No images at all |
| County Surveyor | 1 | **no page exists.** `surveyor` returns ZERO hits across the whole site |

⚠ **A blank beats a wrong link**, and a blank is findable by every "who still needs a headshot"
query. These 16 are recorded as a gap, not filled from a source we cannot state terms for.

## 🔴🔴 "THE PUBLISHER IS OFFLINE" WAS A CONCLUSION, AND IT WAS WRONG A SECOND TIME

MS-6 recorded `hindscountyms.com` as **dead** (HTTP 503). It is not dead — it is **being rebuilt**:

```
HTTP/1.1 503 Service Unavailable        server: Apache
last-modified: Fri, 23 Oct 2026 16:37:22 GMT     retry-after: 3600
→ body: "U.S.NEXT New Domain … Website Coming Soon. We're actively working on this website."
```

That is a **vendor placeholder with a `retry-after`**, not an abandoned host, and `U.S.NEXT` is the
same vendor named in the footer of the archived pages. ▶ **The content is expected back.** Until it
is, the county's own pages are readable in the Internet Archive, and every capture used here is
from **2026** — after the current officers took office in January 2024, before the site went down.

🔴 **READ THE 503 BODY.** A status code said "gone"; the body said "back soon, same vendor".

## 🔴 THE JUSTICE COURT JUDGES MOVED, AND THE OLD PATHS STILL ANSWER

`/elected-offices/justice-court-judges/district-N` → **`/court-systems/justice-court-judges/district-N`**.
Both have captures, so a sweep built from the older sitemap reads **stale pages** and never errors.
The live nav is the authority: it is what names `/court-systems/`. Chancery and circuit court judges
moved the same way. ⚠ The Coroner is at **`/coroner`**, NOT under `/elected-offices/` at all — a CDX
query scoped to `elected-offices*` misses it silently.

## 🔴 THE LICENCE TEST REFUSED A REAL PHOTOGRAPH OF A REAL OFFICEHOLDER

Mississippi Today publishes a portrait of Coroner **Jeramiah Howard**. It is **refused**:

- their republishing licence covers the **story**, and states outright that you *"cannot republish
  our editorial cartoons, photographs, illustrations or graphics without specific permission"*;
- the image's own credit line reads **"Courtesy of Jeramiah Howard"** — so it is not the newsroom's
  to sublicense even if the licence did cover photographs.

🔴 **THE CREDIT LINE IS THE LICENCE TEST, AND A CC-LICENSED OUTLET IS NOT A CC-LICENSED PHOTO.**
A nonprofit newsroom with a "Republish This Story" button is exactly the shape that invites the
wrong assumption. Read what the licence covers, not who is offering it.

## Binding, and why it is not the filename

🔴 **BOUND BY SEAT.** Each image is whatever the county's page **for that office** shows, and the
officeholder's name was asserted present in that page's own text before the row was written. Two
pages disagree with our record about the person's NAME while agreeing about the seat:

| our record | the county's page says |
| --- | --- |
| Anthony Smith, Supervisor District 2 | **"Tony Smith District 2 Supervisor"** |
| Deborah Butler Dixon, Supervisor District 3 | **"Deborah Butler-Dixon District 3 Supervisor"** |
| Beverly Wade-Green, Constable District 5 | **"Beverly Green … Constable District 5"** |

Neither is a different person, and **neither would have been caught by a name match** — which is
the argument for binding on the seat. MS-5 found three wrong labels on Biloxi's filenames and the
Jackson wave found a fourth (`Ashby-M-Forte.jpg`); this county's filenames are surname-based and
look trustworthy, which is not evidence.

## 🔴🔴 TWO DEFECTS THAT ONLY THE RENDER SHOWS — AND BOTH PASSED EVERY NUMBER

Supervisor District 3's portrait is 949x1200, colour spread 27.2, one face cleanly detected,
licence stateable, name beside it on the page. **Every check this repo owns passed it.** Looking
at it found two things:

1. **A DECORATIVE BLACK FRAME on all four edges.** This is the Atlanta ATL-4 ruling
   (`feedback_headshot_crop_composition`) in a different shape — there a circular matte, here a
   rectangular one. Cropped to the house 4:5 it keeps a black band across the top and bottom.
   ▶ `deframe.py` trims it, and **its control was watched failing twice before use**: a frame
   planted with JPEG-like noise must be found exactly, and an unframed image, plus a *dark but
   textured* one (a black suit against a dark ground), must be left alone.
   ⚠ **THE FIRST CONTROL PASSED FOR THE WRONG REASON.** The planted frame was pure black, so a
   tolerance of 0.001 found it just as well as the real 14.0 — the tamper was present in the file
   and the control went green anyway. A flat frame tests nothing; the frame in the control now
   carries noise, and both tampers then turn it red.

2. 🔴🔴 **A COMMERCIAL PHOTOGRAPHER'S SIGNATURE WATERMARKED INTO THE IMAGE** — *"Jay D. Johnson"*,
   bottom right. **THE CREDIT LINE IS THE LICENCE TEST, AND HERE IT NAMES A THIRD PARTY.** The
   county published the portrait; that does not make the county's publication permission a
   sublicence to us.
   🔴 **DO NOT CROP THE SIGNATURE OFF.** Removing an author's attribution from a copyrighted
   work to reuse it is worse than not using it, not a fix — and a crop that chases a corner mark
   is no longer the crop the face asked for. The choice is **use it signature-intact, or blank the
   seat.** It is a licence posture for the whole set, so it is the operator's call, put on the
   contact sheet rather than decided here.

## ⚠ A FAILED WRITE LEFT A 0-BYTE SCRIPT AND THE NEXT RUN REPORTED SUCCESS

Editing `process.py` with a Python one-liner opened it `'w'` (truncating it) and then raised
`UnicodeEncodeError` on an emoji under Windows' cp1252 default. The file was left **empty**, and
`py -3 process.py` then exited **0 with no output at all**. That is
`feedback_dry_run_migration_committed_to_prod`'s sibling: **an empty file passes every gate it does
not contain.** ▶ Check the byte count after writing a file, and read the output rather than the
exit code. Always pass `encoding='utf-8'` when rewriting a source file on Windows.

## 🔴 BLOCKED 2026-10-31 — THE WAYBACK MACHINE IS REFUSING THIS IP

The county's own site is gone from the live web (`/sites/default/files/*` answers **404**, not
503 — the vendor replaced the site, files included), so **the Internet Archive is the only source
for these twelve image files**. Partway through retrieving them the archive began answering every
request with **HTTP 429** and this body:

> *"Your request is being blocked because our system has flagged it as suspected abusive bot
> traffic that is degrading the performance of the Wayback Machine. … Please email
> info@archive.org with your OS/Browser and IP number if you would like us to look into this."*

That is a **block on the IP, not a per-request throttle**: it answers curl and Python alike, and
two full passes at 45-second spacing got nothing. ▶ **The retrieval was STOPPED rather than
retried**, because continuing to poll is what the block is for.

**Nothing upstream of the download is unfinished.** Every image is identified, bound to its seat,
and licence-checked; `hc-manifest.json` carries the exact capture timestamp and source URL for all
twelve, so the set is reproducible by re-running `hinds-fetch-portraits.py` once the block clears.

**On disk already: 2 of 12** — Supervisor District 3 and the Chancery Clerk.

▶ **To resume:** run `py -3 backend/scripts/hinds-fetch-portraits.py` from this directory. It skips
anything already in `src/`. Space the passes out; if it 429s again, wait longer rather than faster.

## 🟢 RULING 2026-10-31 (operator): BLANK ANY PORTRAIT CARRYING A PHOTOGRAPHER'S WATERMARK

*"blank the ones with photographer watermark."*

So the disposition is settled before the files arrive, and it is **not** a crop decision:

- A visible photographer's signature is a **third party asserting ownership**. The county's
  permission to publish is not a sublicence to us, so the seat is **left blank**.
- 🔴 **NEVER CROP THE SIGNATURE OFF.** That converts "we cannot licence this" into "we removed the
  author's attribution to use it anyway", which is worse, and it drags the crop away from the face.
- **A blank beats a wrong link**, and a blank is findable by every "who still needs a headshot"
  query. This is the same answer Ché Alexander got in Atlanta.

⚠ **WHICH ONES ARE SIGNED IS NOT KNOWN YET — IT IS A LOOKING TASK, NOT A MEASURING ONE.**
Supervisor District 3 is confirmed signed (*"Jay D. Johnson"*). The other eleven have not been
seen, because ten are still behind the archive block. A watermark cannot be detected numerically
with any confidence — faint corner text survives every statistic we compute. ▶ **Open every image
and look at it before it goes on the sheet**, and blank the signed ones there, so the sheet the
operator approves already reflects this ruling rather than asking it again.


## APPLIED 2026-10-31 — 4 BOUND, 24 DELIBERATELY BLANK (`CC_0325`)

Contact sheet: <https://claude.ai/artifact/CMzCFoPS6oNxbp2HxVFbba> (private to the operator).

| seat | officeholder | source | enlargement |
| --- | --- | --- | --- |
| County Attorney | Gerald A. Mumford | `gerald-mumford-2x3-website.jpg` 347x521 | x1.73 |
| Sheriff | Tyree D. Jones | `Tyree_D_Jones.jpg` 1012x1012 | x0.74 (reduced) |
| Tax Assessor | Charles E. Stokes | `stokes-page.jpg` 400x478 | x1.57 |
| Tax Collector | Eddie J. Fair | `fair-page.jpg` 400x478 | x1.57 |

⚠ **THE FILE NAMED `5x7` IS SMALLER THAN THE ONE NAMED `2x3`.** `gerald-mumford-5x7-website.jpg`
is 240x336; the `2x3` is 347x521. Every alternate checked was smaller than the file already in
hand, including the Chancery Clerk's, which settled that no larger original exists. **A filename
that states a size is not a measurement.**

**Verified after applying, in this order:**
1. the four objects re-fetched from the PUBLIC CDN and sha256-compared to the local files, with a
   never-uploaded key as the control (HTTP 400, not an image, so a match means something);
2. the database read back: scalar, `images[]` and `photo_origin_url` all as intended, and the
   scalar and the `images[]` row pointing at the SAME object;
3. 🔴 **the RENDERED page, not the API** — `essentials.empowered.vote/politician/<id>` shows the
   sheriff's portrait at naturalWidth 600 x 750 with alt "Tyree D. Jones portrait", and the other
   three decode from the CDN at 600x750.

⚠ **THE API SERVES THE SCALAR UNDER THE KEY `photo_origin_url`** — `essentialsService.ts` selects
`COALESCE(p.photo_custom_url, p.photo_origin_url, '')` under that alias, and exposes no
`photo_custom_url` key at all. So an API response showing a CDN url in `photo_origin_url` is
CORRECT, and a check that reads that field expecting a *source page* will misread every bound row.

**The gates were watched failing**, one tamper at a time, each asserted present in its file first:
swapping two objects between people tripped the own-uuid gate (`1 row(s) name an object that is
not that politician's own uuid`); deleting the `politician_images` INSERT tripped the images gate
(`expected 4 ... found 0`); and adding a watermarked supervisor to the set tripped the blanks gate
(`expected the other 24 ... found 23 blank`). Three tampers, three different gates, no shadowing.

▶ **The 24 blanks are gated.** `CC_0325`'s post-verify asserts the other 24 Hinds officeholders
still carry no photo, so if a later pass fills one from a watermarked or composite source, that
number moves and the next session sees it.
