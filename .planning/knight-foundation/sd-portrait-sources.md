# South Dakota portraits — the source sweep, and why it is PARKED

**Measured 2026-09-29. Nothing from this sweep has been imported.**
**Decision the same day (Cantrell): ship the placeholder for all 105 and come back to this after
the remaining states are in.** This file exists so that return costs an hour, not a day.

Data: [`backend/data/sd-portrait-sweep-2026-09-29/`](../../backend/data/sd-portrait-sweep-2026-09-29/)
— `sd-portrait-sources.csv` and `.json`, one row per legislator, with the band, the backdrop
distance, the Ballotpedia article and portrait URL, and the Legislature's own portrait URL.

---

## Where this came from

The LRC replied 2026-09-29: *"You will need to ask each legislator individually as they are the
ones who can grant permission for use."* See
[`letters/2026-09-28-sd-legislature-portrait-permission.md`](./letters/2026-09-28-sd-legislature-portrait-permission.md).

That reply reserves **the Legislature's portrait files**. It says nothing about a member's
likeness, so the standing 2026-07-08 source ruling still applies — campaign sites, official
rosters and candidate-submitted Ballotpedia photos are approved sources and need nothing from the
Council. The sweep asked how many of the 105 actually have such a source.

## What the sweep found

| | |
| --- | --- |
| Legislators | 105 |
| Ballotpedia portrait found | **95** |
| No portrait anywhere | **10** |

### 🔴 THE FINDING THAT BLOCKED THE IMPORT

**Ballotpedia carries the Legislature's own studio portraits — including PRIOR SESSIONS' — and at
thumbnail size they do not look like it.**

- **Spencer Gosch**: his Ballotpedia portrait *is* the Legislature's current file, re-cropped.
  Same backdrop, lapel pin, tie knot, expression. At 150 px it reads as a different picture; it
  took a 430 px side-by-side to be sure.
- Worse, and the reason a same-file test is not enough: **Eric Emery, Chris Kassin, Brian Mulder
  and Karla Lems** each appear on Ballotpedia in *different clothing* against the *same backdrop*.
  That is not one file copied — it is the same studio in a different year. Those are still the
  Legislature's portraits.

So the question is **not** "is this the same file". It is **"is this from their studio at all"**,
and that is a judgement made by looking.

### The bands in the data file

Backdrop distance = mean RGB distance between the two TOP corners of each image, where a sitter's
head never is. **It is TRIAGE ONLY.** It reliably separates an outdoor or dark-studio photo from
the Legislature's mottled blue-grey, and it is blind in the middle.

| Band | Pairs | Meaning |
| --- | --- | --- |
| `A-same-studio-suspect` (<40) | **35** | Same blue-grey studio. Assume the Legislature's until proven otherwise. |
| `B-ambiguous` (40–70) | 16 | Must be looked at individually. |
| `C-likely-independent` (70–120) | 22 | Different setting. |
| `D-clearly-independent` (>120) | 22 | Obviously independent — outdoors, flags, dark studio, a cap, a cowboy hat. |
| `no-source` | 10 | Placeholder regardless of any decision. |

⚠ **Band A contains a KNOWN-different pair and a KNOWN-same pair four points apart**: Gosch (same)
at 28.3, Amber Arlint (different) at 32.9, Tim Reisch (different) at 32.2. **Never promote a row
out of band A on the number alone.**

### 🔴 THREE AUTOMATED DETECTORS WERE BUILT FOR THIS AND ALL THREE WERE DELETED

Each was tested against five pairs already judged by eye. None could separate them:

1. Crop-tolerant grey correlation, narrow search — scored Gosch (same) **0.47**.
2. The same with a wide crop/scale/offset search — scored Gosch **0.44** while scoring Reisch,
   a plainly different photograph, **0.82**. Anti-correlated with the truth.
3. Backdrop distance — kept, but only as triage, for the reason above.

**Do not rebuild one without a control set.** Grey correlation on studio portraits tracks
backdrop and lighting, not identity, and its numbers look like findings.

## The 10 with no source at all

Placeholder regardless of what is decided about the other 95.

| Why | Who |
| --- | --- |
| Ballotpedia shows its own silhouette | Tim Czmowski, Helene Duhamel, Rebecca Reimer, John Shubeck, Brandon Wipf |
| Article exists, no portrait | Nick Fosness, Taylor Rehfeldt, Mykala Voita, Larry Zikmund |
| Disambiguation unresolved — **look again** | Lauren Nelson (S-18) |

## How to resume

1. Read this file and the letter file. **Do not re-send the LRC letter.**
2. Open `sd-portrait-sources.csv`. Work band **D**, then **C** — those are where the yield is.
3. For every candidate, **compare against the `legislature_portrait` column at full size before
   importing.** The thumbnail is not enough; that is what the Gosch case proves.
4. Apply the standing bars unchanged: no news photography, no personal social media, no mugshots,
   **no monochrome** (enforced in `headshot_crop.py`), and the correct-person guard at full
   strength.
5. Clear `politicians.photo_restriction_code` in the **same migration** that writes the portrait —
   otherwise the person keeps the placeholder and the notice while having a photo.
6. Anything still unsourced keeps the placeholder. That is a correct end state, not a gap.

## Traps this sweep paid for

- 🔴 **`Picture` / `PictureSmall` URLs contain RAW SPACES** (`.../sm_arlint, amber rep-6194 rt js.webp`).
  `curl` rejects them unencoded and the failure is **silent in a loop** — it cost 4 of 5 pilot
  downloads and looked like "these members have no portrait". Percent-encode the path.
- 🔴 **Ballotpedia DISAMBIGUATES common names.** A plain `First_Last` lookup returned "no article"
  for **12 of the 105** who in fact have one at `First_Last_(South_Dakota)`. Follow the
  disambiguation page. Jamie Smith, who ran for Governor, was in that 12.
- ⚠ **A Ballotpedia article title can lag the person.** Tim Reed's article is
  `Tim_Reed_(South_Dakota_House)` and he now sits in the **Senate**. Confirmed the right person by
  district (7) and city (Brookings), not by the title.
- ⚠ **Encoding parentheses BREAKS a Ballotpedia URL.** `%28`/`%29` returns 0 bytes; literal
  `(` and `)` work. The opposite of the rule for the Legislature's blob store.
- ⚠ **WebFetch returns an EMPTY BODY for Ballotpedia**, which reads as "no photo" rather than as a
  block. Fetch it with curl and a browser UA, or in Playwright.
- ⚠ **A python traceback behind a pipe exits 0.** The sweep crashed on its summary and the shell
  reported success; only the missing output showed it.
