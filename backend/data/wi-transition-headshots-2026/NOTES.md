# Wisconsin 2026 winner headshots

The Wisconsin slice of `backend/data/transition-headshots-2026/`. Read that directory's
`NOTES.md` first — it defines the queue, the three-places rule, and the licence rules that
apply here unchanged.

**Applied to production 2026-11-16 as `CC_0444`: 11 of 20 imported, 2 held by the operator,
7 refused with a stated reason.**

| | |
| --- | --- |
| WI winners of 2026-11-03 | 129 |
| had a photo before this | 109 |
| **had none anywhere** | **20** |
| imported here | **11** |
| still missing after this | **9** |

---

## 🔴 THE QUEUE SHRANK FROM 26 TO 20 AND ONLY FIVE OF THE SIX WERE PROGRESS

`transition-headshots-2026/headshot-queue-2026-11-08.csv` lists 26 for WI. Measured again on
2026-11-16 it was 20. Five had genuinely been sourced in between (Binsfeld, Zimmerman,
Severson, Luna, Kroll — all from their own campaign sites, all recorded `photo_license =
'unknown'`).

**The sixth, Romaine Quinn, left the queue without getting a face.** A duplicate person row
`a0ea7354` ("Romaine Robert Quinn") was merged into the real `2dbf3032` ("Romaine Quinn"),
which already held his legislature portrait; the duplicate is now `is_active = false` with
no candidacy rows, exactly as the merge policy requires.

▶ **A FALLING QUEUE IS NOT THE SAME CLAIM AS A RISING PHOTO COUNT.** A row can leave this
list because somebody did the work, or because the row it was counted through moved. Check
which before reporting progress — the second kind changes no photo anywhere.

---

## What was imported

All 11 came from **the candidate's own campaign site**, each footer read. `press_use` here
means the site publishes no restriction on the photograph; none of the 11 sites carries a
terms-of-use page, only privacy policies.

🔴 **NO AGGREGATOR IMAGE WAS TAKEN.** Ballotpedia and PBS Wisconsin were used only as
POINTERS to find each campaign's address — 17 of 18 campaign URLs came off Ballotpedia's
external-links block. That is the rule this repo wrote for Ballotpedia and had to write again
for BallotReady, whose terms forbid reproducing images outright.

Both `politicians.photo_custom_url` and a `politician_images` row of `type = 'default'` were
written for every one, and `CC_0444`'s gate asserts the two name the same file.

---

## 🔴 THE TWO THE OPERATOR HELD

- **Anthony W. Phillips (AD56)** — his own site, `phillipsforwisconsin.com`, publishes one
  usable image: a **full-length** photograph of him in a white coat across an office, where
  the face is a few dozen pixels. The only close portrait is PBS Wisconsin's
  (`wisconsinvote2026-anthony-phillips.jpg`, 1000×1000, alt text "Anthony Phillips poses for
  a portrait"). **PBS Wisconsin publishes no terms page I could find**, so its licence is
  unread and the operator held it rather than import at `unknown`.
  ⚠ PBS Wisconsin's candidate pages are independently useful: the page states **WINNER** for
  this race, corroborating our recorded result, and it carries the campaign URL that
  Ballotpedia did not have.
  ⚠ A second active politician row exists for a plain **"Anthony Phillips"**
  (`7fefb4bb`, 1 compass answer, no photo). Not investigated. Decide whether it is the same
  person before seating or sourcing either.
- **Trevor Jung (SD21)** — the available file (`jung-fall1.png`, 600×600) has **a second
  person's head partly in frame** at the left edge.
  🔴 **`trevorjung.com` REFUSES EVERY NON-BROWSER CLIENT.** Python `requests` and `curl` both
  get `RemoteDisconnected` / `SSL_read: unexpected eof` — not a 403, so it reads like a
  network fault rather than a block. A `Referer` header does not help. The file comes out
  only through Playwright. That is the TLS-fingerprint case in
  `reference_waf_blocks_node_fetch_by_tls`, with the connection dropped instead of challenged.

## 🔴 THE SEVEN WITH NO USABLE PHOTOGRAPH — THIS IS A FINDING, NOT A STALLED SEARCH

Each campaign site was crawled to depth (up to 14 internal pages), every `<img>`, `<source>`
and `og:image` collected, and every candidate downloaded and measured.

| who | seat | what the site actually publishes |
| --- | --- | --- |
| Yee Leng Xiong | Treasurer | A group photograph and three line-art icons. No portrait of him alone. |
| Steve Wicklund | AD33 | Renders in JavaScript; exposes one image, a social card that is text on a blue field. |
| Bradley Petersen | AD59 | A Canva site whose images are the Facebook wordmark, a distant shot beside a truck, and a blank film-grain frame. |
| Marty Ryan | AD60 | Only full-length photographs in front of the State Capitol. |
| Ben Brist | AD61 | Him with a partner, a military group shot, a childhood photo, a union logo — **and a portrait of Governor Tony Evers**. |
| Ellen Schutt | SD11 | A farm sign, two group photographs, a pig, and an endorsement graphic with lettering across her face. |
| Nic Cravillion | SD1 | His nomination papers, a district map poster, and endorsement photographs with county sheriffs. The one solo image has campaign text across it. |

🔴🔴 **BEN BRIST'S SITE CARRIES A PORTRAIT OF THE GOVERNOR, AND IT SCORED HIGHEST OF HIS
IMAGES.** 2048×2047, portrait-shaped, studio-lit, on his own domain — every mechanical
signal said "this is the headshot". It is Tony Evers. **Only looking at it caught this.**
Nothing this repo runs asks whether an image contains the *right* face, and a filename-led or
aspect-ratio-led pass would have shipped the Governor as a freshman representative.
▶ This is the same class as Bell CA's Ali Saleh and Manhattan Beach's Joe Franklin, reached
from a new direction: not a namesake, but **a photograph of a different real politician
hosted on the subject's own site**.

⚠ **A FILENAME CONTAINING THE SURNAME IS NOT EVIDENCE EITHER.** `bernie-newman-family.jpeg`
is a named file and a family photograph; the usable one is `bernie-head-pic-1-1.jpg`. The
first pass ranked the family photo top because it scored on the name.

## ⚠ Weakest of the 11

**Becky Nichols** is a standing, mid-distance photograph — the right person, alone, but the
face is small in frame. It is the best her site publishes. Replace it if a closer one appears.

---

## Reproducing

```
import.py manifest-2026-11-16.json CC_0444-rows.sql     # needs SUPABASE_SERVICE_ROLE_KEY
```

`import.py` mirrors each approved file into `politician_photos` and prints the migration's
row SQL. It never writes to the database. Two things in it are load-bearing:

- **Storage needs BOTH `apikey` and `Authorization`.** A lone Bearer is refused as HTTP 400
  with a body saying 403 "Invalid Compact JWS", which reads like a missing object.
- **It reads every file back from the PUBLIC CDN and compares byte counts** before reporting
  success. The upload host and the CDN host are different; a 200 from the upload is not
  evidence the file is servable.

It also refuses to run if a source image's dimensions no longer match the manifest, so a
campaign that swaps its photograph fails the import instead of silently shipping a new one.

**Verified after applying:** all 11 fetched anonymously from the public CDN (no key),
all HTTP 200, all exactly 600×750, each containing one face. Queue went 20 → 9.

## 🔴 The controls, and the one that was shadowed

`CC_0444`'s post-verify was watched failing three times before it was trusted, each tamper
changing exactly one thing:

| control | expected | result |
| --- | --- | --- |
| remove one image INSERT | image-count gate | `default image rows for 10 of 11` ✅ |
| point one scalar at a different file | agreement gate | `scalar and default image row disagree for: JoCasta Zamarripa` ✅ |
| point one URL at `example.org` | bucket gate | `1 of the 11 point outside our own bucket` ✅ |

⚠ **THE FIRST ATTEMPT AT CONTROL 1 WAS SHADOWED AND LOOKED LIKE A PASS.** It swapped a real
`politician_id` for `00000000-…-0001`, which tripped the **foreign key** on
`politician_images` instead of the count gate — a correct failure, for the wrong property,
leaving the gate still untested. Rebuilt to delete the INSERT statement outright, so a real
person simply ends with a scalar and no image row. ▶ **A tamper must reach the gate you are
testing; check which error you got, not that you got one.**

## Still open for Wisconsin

- **9 winners still have no face** — the 7 above plus Phillips and Jung.
- 🔴 **SEATING HAS NOT STARTED.** 137 Wisconsin offices (99 Assembly, 33 Senate, 5 statewide
  executives) carry **no `office_swearing_in` row at all**; only the 8 US House seats do.
  None of these 11 is seated, so they do not yet appear in the officeholder list — their
  photographs reach voters through the ballot surface until the Legislature convenes.
