# Headshots for the 2026 transition — the sourcing queue

`build-list.mjs` produces `headshot-queue-2026-11-08.{csv,json}`: every winner of the
2026-11-03 election who has **no headshot in any of the three places a photo can live**.

**Measured 2026-11-08, against production:**

| | |
| --- | --- |
| winners recorded | **1,134** |
| a photo somewhere (the positive control) | 901 |
| **no photo anywhere — the queue** | **233** |
| of those, NEW to the seat | **169** |
| already carrying a recorded licence refusal | 1 |

**By tier:** STATE_EXEC 77 · SCHOOL 59 · STATE_LOWER 38 · STATE_BOARD_EDUCATION 22 ·
STATE_BOARD 14 · LOCAL 11 · STATE_UPPER 11 · NATIONAL_LOWER 1.

**By state:** CA 82 · WI 26 · AL 11 · TX 10 · NE 10 · NM 9 · WA 9 · CO 8 · GA 8 · HI 6 ·
NH 5 · AZ 5 · MI 5 · OK 5 · SD 5, then a long tail across 31 states in all.

🟢 **The federal tier is effectively done — 1 missing of 414** — because earlier headshot
programmes worked it. **The gaps are exactly the tiers this programme has just created or just
recorded**, which is what you would expect and is worth saying out loud: a new winner arrives
with no face.

---

## 🔴 A PERSON IS ONLY "MISSING" IF ALL THREE PLACES ARE EMPTY

- **`politicians.photo_custom_url`** — the scalar the backend reads.
- **a `politician_images` row of `type = 'default'`** — what the grid reads out of `images[]`.
- **`race_candidates.photo_url`** — the one nothing sweeps, and it **beats** the fixed image on
  ballot pages.

A query against any one of them alone under- or over-counts. The builder checks all three and
asserts the opposite class is populated first: *901 winners read as HAVING a photo* is the
positive control, without which "233 are missing" is indistinguishable from a query that cannot
see photos at all.

### 🔴 TWO ROWS ALREADY DISAGREE WITH THEMSELVES, AND NOTHING CATCHES IT

**Mark Teixeira** and **Vanessa Kritzer** each carry `photo_custom_url` **and no `default`
image row**. They render on one surface and blank on the other, and no gate in this repo sees
it. Writing the scalar without the image row is a known defect — ▶ **write both, always.**
These two are not in the queue above (they have *a* photo) and want a repair, not sourcing.

---

## 🔴 BEFORE SOURCING ANYTHING, READ THE LICENCE RULES — THEY ARE NOT IN THIS FILE

This list says **who has no face**. It says nothing about where a face may come from, and that
is the part this repo has paid for repeatedly. The rules live in the memory files and must be
read before a photo run:

- `feedback_no_facebook_photos_press_only` — **press, official or public-domain only.**
  🔴 **The credit line is the licence test.**
- `feedback_headshot_must_contain_a_face` — 🔴🔴 **nothing we run asks whether an image contains
  a face.** A seal, a map, a blank frame and a torso all pass. The only gate is the CI job
  `headshot faces`, and it is **schedule-only**, so it will not fire on a PR.
- `feedback_measure_dont_eyeball_crop_geometry` and `feedback_headshot_crop_composition` —
  crop geometry is measured, never eyeballed.
- `feedback_look_at_the_proof_sheet_you_publish` and `feedback_headshot_contact_sheet_approval`
  — **look at the proof sheet**; a correct API response is not evidence the image landed.
- `project_photo_custom_url_is_what_renders` — 🔴 **write BOTH the scalar and the image row**,
  and **read the rendered `<img>`**, not the API.
- 🔴 **Mirror at native size.** A bare CDN URL is not the original: both the resize and the
  quality loss can hide in the query string.
- ⚠ **A namesake reaches production and nothing errors.** This repo has shipped the late
  President of Yemen as a Bell CA councilman and a New York talk-show host as a Manhattan Beach
  official. **Check the person against the body's own roster and OPEN THE IMAGE.**

⚠ **One of the 233 already carries a `photo_restriction_code`** — a licence refusal somebody
recorded. Do not re-source it without reading why.

---

## ▶ Where to start

**California is 82 of 233** and most of it is the December wave — school boards (59 across the
whole queue) seat on **2026-12-11** and the special districts on **2026-12-04**. Those are the
faces a voter will look for first, and they have the nearest deadline.

⚠ **A seat is not a person.** 64 of the 233 are **re-elected incumbents** who have held the seat
and still have no photo; the other 169 are new. The second group is the transition's own gap,
the first is older debt that this list happens to surface.

---

# Batch 1 — applied 2026-11-09 (`CC_0383`)

**14 of 25 imported, 11 refused with a stated reason.** The cohort was the two nearest
handovers: 11 special-district directors seating **2026-12-04** and 14 members of four
school boards seating **2026-12-11**, chosen because those four school bodies cluster onto one
roster page each and a roster page yields several faces at once.

```
batch1-manifest-2026-11-09.json   what was offered for approval, sourced and refused alike
batch1-imported-2026-11-09.json   what production holds afterwards, read back from prod
check-flat-border.py              the border detector written for this batch, with its control
```

## 🔴🔴 BALLOTREADY IS A REFUSAL, NOT A SOURCE — AND 21 LIVE ROWS ALREADY REST ON IT

`ballotready.org/terms` defines **"Services Content"** to include *"text, graphics, logos,
button icons, **images**, audio clips, digital downloads, trade dress, data compilations"* and
then: *"You won't modify, publish, transmit... reproduce... or otherwise exploit any of the
Services."* There is **no press or media carve-out**. Read twice — the IP clause names images,
the restriction clause forbids publishing them — which is the same shape as `coloradosos.gov`.

This repo's notes call it *"the source that keeps working for local candidates"*. Measured
against production on 2026-11-09:

| | |
| --- | --- |
| active politicians citing `ballotready.org` / `assets.civicengine.com` as photo origin | **21** |
| of those, **mirrored into our own bucket** (we serve copies) | **21** |
| recorded `press_use` | **19** · `unknown` 1 · blank 1 |

`press_use` means *"the site offers the photo for press use or publishes no restriction"*.
BallotReady publishes a restriction, so those 19 claims are not supported by their source —
the same defect class as the 184 unversioned CC BY-SA claims that `CC_0326`-`CC_0334` cleared.

🟢 **THE FIX IS NOT DELETION.** The photographs are **candidate-submitted**, so the copyright is
usually the candidate's, and BallotReady's own clause claims it for *"BallotReady or our
suppliers"*. The rule this repo already wrote for Ballotpedia applies unchanged:
▶ **AN AGGREGATOR IS A POINTER, NOT A GRANTOR.** Re-source each from the candidate's own site
and record THAT as the origin. Affected names include Mike Bird, Stephen Otterstrom, Tayler
Khater and Terri DeBoer — all seated from BallotReady by `CC_0255`/`CC_0257`/`CC_0259`.

⚠ It cost this batch three people: Vrsalovich, Worthington and Blades-Snell. **Not fixed here.**

## 🔴 WHAT A BODY PUBLISHES IS THE ANSWER, NOT A SEARCH FAILURE — THREE TIMES IN ONE BATCH

- **Santa Monica College publishes its trustees in BLACK AND WHITE.** Chroma **0.00**, neutral
  share **1.000** — pure greyscale, measured, not borderline. The standing no-monochrome rule
  refuses Roy, Peters and Barrera Castañón, and BallotReady was their only other route, so
  **all four SMC seats are blocked** rather than partly filled.
- **Foothill MWD publishes NO member portraits at all** — text bios only; the page's only
  images are a banner and a decorative valve photograph. ⚠ Its roster was still useful: it
  independently corroborated the election result, naming Laura Olhasso as the sitting Division 4
  director whom our data records Amy Chen as defeating.
- **La Cañada Irrigation District has no website that resolves.**

## ⚠ THREE REFUSALS THAT ARE NOT ABOUT LICENCE OR QUALITY

- **"Amy Chen" was refused on IDENTITY.** A BallotReady page of that name exists and **names no
  office at all**, so nothing ties it to our Foothill Division 4 winner. A name is a hypothesis.
- **Patrick W. Atwater carries a live namesake risk** — a **RICHARD** Atwater retired from that
  same board in February 2026. Do not source him without binding to the person, not the surname.
- **Robbie Staenberg's BallotReady image is the grey placeholder silhouette.** Caught by reading
  the `src`; the `alt` read *"Headshot of Robbie"*. 🔴 **READ THE SRC.**

## 🔴 A PURE-BLACK BORDER PASSED `check-portrait-framing.mjs` — DIAGNOSED AND FIXED 2026-11-09

Walnut Valley’s published portrait of **Theresa Lee** is 4800×6000 with a black border measured
at **505px left, 504px right, 161px top, 160px bottom**; all four corners read **exactly 15.0**,
which is the disc-on-matte signature the gate exists to catch. `check-portrait-framing.mjs`
returned **FRAMED: none** with its own two fixtures passing. The border was cropped off before
import — corners now 18.4-22.4, the real studio backdrop — and the stored file is that crop.

🟢 **The gate is now fixed** (same file, same session). Measured afterwards, Lee satisfied
**four of the five** old conditions and failed on exactly one: `centrePct = 10` against a
required `< 4`.

🔴🔴 **THE MECHANISM: THE OLD CENTRE TEST ASKED “IS THE MIDDLE THE SAME COLOUR AS THE
SURROUND”, WHICH IS NOT THE QUESTION “IS THE MIDDLE PART OF THE SURROUND”.** Lee’s matte is
near-black, and dark hair, a dark jacket and shadow are near-black in every portrait ever taken,
so **the subject itself voted the frame innocent**. ⚠ **BOTH FIXTURES WERE A GREEN MATTE AND A
WHITE MATTE** — colours that cannot occur in a subject — so no fixture had ever exercised a dark
surround. ▶ **A CONTROL SET THAT IS UNIFORM IN A PROPERTY THE DETECTOR DEPENDS ON CANNOT TEST
THAT PROPERTY.** This is the companion to "a uniform ANSWER is a broken detector": here the
uniformity was in the *controls*, and it hid a whole class of input.

Two repairs, both chosen from measurements over the 14 approved crops of this batch plus every
raw source and every fixture — **36 images, zero false positives**:

1. 🟢 **SURROUND MEMBERSHIP IS NOW AN EDGE-CONNECTED FLOOD FILL, NOT A COLOUR MATCH.** A
   surround touches the frame edge; dark hair in the middle of a face does not. On the same
   corpus the colour test read up to **11.8%** inside the centre ellipse while the flood fill
   reads **0.0% on every row**. The colour figure is still *reported* and never tested, so the
   next reader can watch the two diverge instead of measuring it again.
2. 🟢 **A BORDER BRANCH WAS ADDED, BECAUSE THE DISC TESTS CANNOT SEE A RECTANGULAR FRAME
   STRUCTURALLY.** A disc of full width touches the left and right edges at their midpoints, so
   **no side of a disc image is flat along its whole length** — a per-side test is the only
   thing that sees a letterbox, and a corner-and-diagonal test is the only thing that sees a
   disc. They are complementary, not redundant. Lee is the only row in the corpus with any flat
   border depth (`[4,4,12,12]` px of 120×150, colour agreement 0, contrast 81); every approved
   crop, the de-bordered twin and all three old fixtures read depth 0.

🔴 **AND IT NOW PRINTS EVERY ROW IT SCANNED, NOT ONLY ITS HITS.** The reason the pass was
undiagnosable for a day is that **a passing row produced no numbers at all** — the verdict was
readable and the evidence for it was not.

**Fixtures now number five**, and the last two are the same photograph: Lee’s published file as a
third POSITIVE (the dark-matte case the other two miss) and **the de-bordered crop of it as a
second NEGATIVE** — subject, studio, lens and compression all held constant, so the only thing it
can be answering is the border. The de-bordered fixture is built by cropping the positive’s own
downloaded bytes at the measured insets, and **the build asserts the source is still 4800×6000**,
so if the district republishes the portrait the fixture fails loudly instead of cropping air.

**Watched failing first, three tampers, each asserted present in the file before it ran:**

| tamper | effect on Lee | what it proves |
| --- | --- | --- |
| **A** — flood fill reverted to colour | DISC goes dark, **BORDER still catches him** | the border branch alone is sufficient |
| **B** — border branch disabled | BORDER goes dark, **DISC still catches him** | the flood-fill repair alone is sufficient |
| **A+B** — both reverted (the original gate) | **not framed — the defect reproduced exactly** | and the gate then **refuses a verdict**: `*** CONTROLS FAILED — the gate is blind ***` |

⚠ **A first attempt at tamper A was INVALID AND LOOKED LIKE A PASS** — it substituted a name that
is not in scope at that line, so the gate threw and exited 1 for the wrong reason. **An exit code
is not a control.** Read what the tamper actually did.

🟢 **IT IS IN CI NOW (2026-11-09), inside the `headshot faces` job, on the Sunday full sweep.**
It reads `check-headshot-faces.py`'s own `--json` output instead of querying the database, so
both detectors scan one list decided by one piece of SQL and record judgements under the same
`(url, sha256)` key; `data/headshot-framing-known.json` holds the flags already looked at. The
line that used to stand here — *the gate is hand-run, nothing runs it for you* — is gone.

🔴🔴 **AND WIRING IT UP IS WHAT REVEALED THAT THE FIX ABOVE WAS MEASURED ON TOO SMALL A SET.**
Over the 36 images of this batch it had **zero false positives**. Over the first 500 random
published headshots it had one, and over **all 9,481 it flagged 44, of which 33 were real
photographs** — every one of them a subject cut out on plain white or shot against a seamless
studio backdrop. The flood-fill repair is what admitted them: a seamless backdrop really **is**
connected to the frame edge, so `surroundPct` was answering correctly and nothing left in the
predicate could tell a backdrop from a matte. ▶ **36 images drawn from the batch being worked on
are uniform in exactly the thing that was wrong. An error rate is not known until the detector
has been run over the population it will police.**

🟢 **THE REPAIR WAS A NUMBER THE GATE ALREADY HAD AND THREW AWAY.** The diagonal walk counted
how many of the four corner diagonals left the matte — a disc answers four, and so does a person
on white. It never kept **how far along each one** the surround ended. A disc is round, so all
four are equal; a person ends at their hair on the top two and their shoulders on the bottom two.
Measured: the three positive fixtures 0, 1 and 3; all 11 real manufactured surrounds in the
corpus 0–2; the nearest real photograph **8**, then 8, 11, 13, 13, 14. `DISC_SPREAD = 6` sits in
that gap, and the corpus went **44 → 12**. ▶ **When a detector counts occurrences, ask what it
measured to find them.**

🔴 **ALL 11 REAL DEFECTS HAD PASSED THE FACE GATE**, and two of them are the **State Seal of
Washington** and the **Great Seal of North Carolina** — seals that contain a portrait, so a face
detector clears them honestly. The rest are oval crops, pillarboxed photographs and framed ones.
They are recorded as `"kind": "defect"` in `backend/data/headshot-framing-known.json` and are
owed a re-sourcing pass; the file is a queue that should only ever shrink. One row is recorded
`"kind": "accepted"` with its reason: a cut-out portrait on plain white satisfies the BORDER
branch, because when the subject reaches no edge every edge line really is flat and one colour,
so that branch cannot tell a uniform BACKGROUND from a FRAME.
## ✅ THE ELEVEN ARE FIXED — `CC_0384`, 2026-11-10

Applied to prod. The whole published corpus now flags **one** frame, and that one is the recorded
acceptance. The defect queue in `backend/data/headshot-framing-known.json` is **empty**.

| what it was | n | what was done |
| --- | --- | --- |
| **state seals** | 2 | Jeff Jackson re-sourced; Steve Hobbs **repointed** |
| oval crop on a matte | 4 | 3 re-sourced from the same shoot; 1 blanked |
| letterboxed in a flat frame | 2 | the frame cropped off |
| pillarboxed | 2 | the bands cropped off |
| arched mask burnt in | 1 | blanked |

🔴🔴 **ONE OF THE TWO SEALS WAS ALREADY HALF-FIXED, AND THE HALF THAT WAS MISSING IS THE ONE THE
GATE READS.** Steve Hobbs got a real portrait on 2026-10-19. It went into `politician_images` as
`<id>-headshot-v2.jpg` — and **`photo_custom_url` was never moved off `<id>-headshot.jpg`, the
seal**. So for three weeks the profile grid, which reads `images[]`, showed the portrait while the
backend scalar and the framing gate both still had the seal. ▶ **Three photo columns, and they can
disagree PAIRWISE. "Both sides written" is not one check, it is three.** `CC_0384`'s post-verify
asks the question that was wrong here: not *does the new value appear*, but **does any old value
survive anywhere** — and it names `race_candidates.photo_url` as the third surface and gates it at
zero, because nothing else above would have noticed it.

🟢 **THE MEMBER PAGE AND THE ROSTER PAGE SERVED DIFFERENT FILES.** Draper publishes each councillor
as a 1080×1080 circle on their own page — and the **Mayor and Council index** serves a different
asset entirely: the rectangular original from the same shoot, 2216×3936. Three of the four oval
crops were fixed from it, at a 0.43–0.52× downscale. ▶ **"The body publishes only circles" was true
of the page I looked at and false of the site.** List the images on every page of a roster before
concluding a source is empty.

⚠ **AND THE OTHER THREE BODIES REALLY DO PUBLISH THE FRAME.** Allen County's own file carries the
same white border we held, Covina's is byte-identical to ours (sha256 checked), Monroe County
publishes every councillor as a circle, and Cottonwood Heights publishes no portrait at all. For
those, cropping the surround off the file we already hold IS the fix, and it costs an enlargement:
Scheuman 1.84×, Cortez 1.59×, Holton 1.25×. Blackwell's cost nothing — 0.79×, a downscale.

🔴 **TWO WERE BLANKED, AND THE GEOMETRY IS WHY, NOT A SHRUG.** Liz Feitl's mask measures as a circle
of radius **498** in a 1000×1000 frame with her crown at **y=75**; the largest 4:5 window that stays
inside it, clears her hair and keeps her face near the middle is **279×349** — a 2.15× enlargement
of a frame her face would overflow. Mike Klein's arch is burnt into a file already cropped to
600×750, so there is nothing to crop back to, and his origin was a **Ballotpedia** election page
recorded `press_use`, a claim Ballotpedia cannot grant. He lost FL-3 on 2026-11-03. **A rejection is
a measurement too** — both numbers are in the migration header.

⚠ **Klein's `politician_images` ROW WAS DELETED, NOT EMPTIED** — the grid reads `images[]` first, so
a row holding a bad URL is worse than no row. Both now have `photo_origin_url` NULL as well, which
is what puts them back in the needs-a-headshot queue.

🔴 **EVERY REPLACEMENT URL CARRIES `?v=20261110`.** `x-upsert` at the same object path returns 200
while the public CDN goes on serving the **old** bytes, `cf-cache-status: HIT`. Each of the eight
uploads was verified by re-fetching **the exact URL written to the database** and comparing sha256
to the local file: 8 of 8 matched, all `MISS`.

**Watched failing first.** Three tampers on the post-verify, each asserted present in the file
before the dry run: dropping the Hobbs repoint → `found 8`; blanking Klein's image row instead of
deleting it → `found 1`; writing the scalar but leaving one `images[]` row on the old file → `found
8`. All three red for the right reason, then the real file applied with every statement touching
exactly one row.

⚠ **NO FACE DETECTOR RAN ON THE NINE.** `check-headshot-faces.py` needs Python and there is none on
the machine that did this work. Every frame was measured off a grid labelled in original pixels,
drawn back onto the photograph, looked at, and put through `check-portrait-framing.mjs` with its
five fixtures green. The Sunday CI sweep will be the first face check they get.

## ⚠ MY FIRST BORDER DETECTOR SAID 13 OF 14 AND WAS WRONG

It measured *"distance inward to the first brightness change"*, which on any graduated studio
backdrop fires well inside the frame. **The near-uniform answer was the tell.** `check-flat-border.py`
replaces it and asks the three questions a border actually answers — is the ring **flat along its
length**, does it **agree on all four sides**, does it **contrast with the interior** — and it was
watched going **red on Lee's bordered file (flatness 0.0)** and **green on the de-bordered copy of
the SAME PHOTOGRAPH (17.3)** before any result was believed. All 14 production crops read clean,
flatness 15.3-85.1 against the border's 0.0.

## What shipped, and the two judgement calls inside it

🔴 **NOTHING IS ENLARGED.** Six are stored at **native** size — 400×500, 576×720, and 300×375
three times — rather than upscaled to 600×750. The importer's default `--max-upscale 1.0` does
this, and it is also what the approved contact sheet showed. The three 300×375 are **SMMUSD's
published ceiling**, not a crop choice.

⚠ **BODNAR AND JOHNSON CARRY `anchor_y: 0`.** The default centre crop took their crowns to
**0.12 and 0.03 ear-lengths** of headroom — the NC-legislator defect. At `anchor_y=0` they sit
at 0.31 and 0.37. Still short of the ~1.0 the house wants, and that is the source's framing;
padding would invent image content.

⚠ **Their licence is recorded `unknown`, not `press_use`** — `cvwd.com`'s footer asserts
**"All Rights Reserved"**, a positive reservation rather than the silence case. An `unknown` is
findable by the query that looks for missing provenance; a guessed licence is not.

## Verification

- **Before:** all 14 storage paths returned `NoSuchKey`, with a known-good object returning 200
  as the control — so these are fresh objects and need **no `?v=` cache key**.
- **After, against the PUBLIC CDN rather than the upload's own 200:** all 14 re-fetched and
  re-gated — 14 real colour faces, correct rotation, **0 failures**.
- **The rendered `<img>`, not the API:** `essentials.empowered.vote` was read for Triston
  Ezidore — 600×750 from our bucket, credit line "Photo: Press use" displayed.
- **`CC_0383` dry-run:** `UPDATE=0 INSERT=0` (everything already true), all three gates pass.
  **Control:** pointing one row's scalar at a different object fires gate 3 alone
  (*"1 of 14 have a default image row that disagrees"*), exit 1, nothing shadowed. The tamper
  was asserted **present in the file** before it was run.

## ▶ What is next in California

**68 of the 82 CA rows remain** — 50 more school boards (2026-12-11), 6 special districts,
and 12 legislators with no swearing-in date yet. The school boards are the nearest deadline.
🔴 **Do not reach for BallotReady for any of them** until the re-sourcing piece above is done.
