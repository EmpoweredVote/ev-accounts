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

---

# Batch 2 — applied 2026-11-16 (`CC_0438`)

**7 of the 73 legislative winners who have no face.** This batch changed the scope: batch 1 worked
the nearest *handovers* (special districts, school boards); batch 2 works the **legislative tiers**
— `STATE_LOWER`, `STATE_UPPER`, `NATIONAL_LOWER`, `NATIONAL_UPPER`. Measured against production,
that tier holds **73** winners with no photograph in any of the three places, against a positive
control of **1,339** legislative winners that DO read as having one.

By state: **WA 23 · WI 23 · CA 19 · IN 3 · CO 2 · UT 2 · TX 1.** All seven below are California.
The faceless legislative count went **73 → 66**, gated as a delta inside the migration's own
transaction.

## 🔴 THESE WINNERS ARE NOT ON ANY CHAMBER ROSTER YET, SO THERE IS NO BULK SOURCE

Batch 1 could lean on roster pages that yield several faces at once. This tier cannot: a winner of
2026-11-03 does not appear on `legis.wisconsin.gov` or `leg.wa.gov` until the chamber seats them in
January. **The source for each is the body they hold office in TODAY** — a county board, a city
council, a school board — or their campaign site. That is one research problem per person, and it
is why this batch is 7 and not 73.

▶ The corollary: **a winner who holds no current office has only a campaign site**, and campaign
sites are where the licence questions live.

## ⚠ EVERY ONE OF THE SEVEN IS `unknown`, AND THAT IS THE FINDING

Not one California publisher in this batch grants reuse. `fresno.gov` and `garcia.asmdc.org` assert
a blanket copyright; `fresnocountyca.gov`, `rpvca.gov`, `rpcity.ca.gov` and `kerncounty.com`
publish no photo policy at all on the pages carrying these portraits. Only **federal** US
government work is public domain (17 USC §105) — a city, county or state portrait is not. Recorded
`unknown`, the same disposition `CC_0383` gave the two cvwd.com rows.

## 🔴🔴 A STORAGE OBJECT EXISTED FOR A PERSON THE DATABASE SAID HAD NO PHOTO

The absence control before upload found `8bfb459b-…-headshot.jpg` answering **HTTP 200** while
Robert Garcia's row carried nothing on any of the three surfaces. An orphan file nobody wired up —
the **mirror image of the Steve Hobbs defect** `CC_0384` found, where the row pointed at a file and
the scalar pointed at a seal. Opened and compared: the same man, an older outdoor portrait,
600×750, sha256 `42d4f894…`. Replaced with his current Assembly studio portrait, and **his URL
alone carries `?v=20261116`** because an `x-upsert` at an existing path returns 200 while the CDN
serves the old bytes.

▶ **The absence control is not ceremony — it is the only thing that distinguishes a fresh object
from an overwrite, and the two need different URLs.**

## 🔴 THE VERIFY CAUGHT ITSELF ASSERTING ON A URL THE MIGRATION DOES NOT STORE

First verify run: Garcia **FAIL**, `cf-cache=HIT`, sha `42d4f894` — the old photograph. The script
was fetching the un-keyed path while the migration writes the `?v=` one. Re-pointed at the exact
stored URL it reads `MISS` and the new sha. **Verify the URL you are writing down, not the one you
uploaded to.**

## ⚠ TWO IMAGE-FINDING TRAPS, BOTH CAUGHT BY LOOKING

- **`dombelza.com`'s highest-scoring portrait is Kevin Kiley's** — an endorser's headshot, sitting
  in the candidate's own media library. A relevance score on a campaign site ranks *whoever is
  pictured*, not the candidate.
- **`fresno.gov` serves `pereas.jpg` with the alt text "andrew-janz".** Not used; the file taken is
  `annalisa_perea.jpg`, whose filename and alt agree. **Where filename and alt disagree, neither is
  evidence.**

## 🔴 THE RESIZE HIDES IN THE QUERY STRING, AND IT COST 5× ON ONE FILE

Fresno County serves Pacheco's portrait as `…?dimension=pageimage&w=480`. Stripping the query
returns the native **2400×3200**. Mirroring the page's own `src` would have stored a 480px copy of
a file five times that size.

## ⚠ THREE PUBLISHERS KEY THEIR PORTRAITS ON AN ID, NOT A NAME

`rpvca.gov` and `rpcity.ca.gov` (CivicPlus) serve `ImageRepository/Document?documentID=NNNN`, and
Kern County serves `showpublishedimage/2316`. **A positional URL encodes a slot, not a person.**
Each was bound by the alt text *and* the body's own roster entry, and every render was opened.

## ⚠ WHAT THE PUBLISHER HAS IS THE ANSWER

Kern County and Rohnert Park publish their members at **200×250** and nothing larger. Those two
ship at native size. Nothing in this batch is enlarged.

## ⚠ `maraelliott.com` REFUSES BOTH NODE FETCH AND CURL AT THE TLS HANDSHAKE

Her source is found — a 2000×1334 campaign portrait — and could not be downloaded by either client
(`OpenSSL unexpected eof`). Playwright reaches the page fine, so the file has to come down through
the browser. **Deferred, not refused.**

## Verification

- **Before:** six of seven paths absent, Garcia's present (above), with a known-good object
  returning 200 as the positive control.
- **After:** all 7 re-fetched from the **exact URL written to the database** and compared by
  sha256 to the local file — 7 of 7 byte-identical.
- **Gates watched failing first**, three tampers, each asserted present in the file before running:
  removing the `photo_origin_url` write → `7 of 7 do not carry the source page`; dropping one
  person from the import set → `moved by 6 (73 -> 67)`; pointing the image row at a different
  object → `7 of 7 ... disagrees with photo_custom_url`. ⚠ **A fourth attempt was REFUSED by the
  tamper builder** because the edit stripped its own marker — it would have produced a file that
  passed for the wrong reason.
- **The rendered `<img>`, not the API:** `essentials.empowered.vote` read for Robert Garcia —
  600×750 from our bucket at the `?v=20261116` URL, showing the studio portrait and not the
  outdoor one it replaced.
- **No face detector ran.** `check-headshot-faces.py` needs Python and there is none on this
  machine. Every frame was opened and looked at. The Sunday CI sweep is their first automated check.

## ▶ What is next

**66 legislative winners remain** — WA 23, WI 23, CA 12, IN 3, CO 2, UT 2, TX 1. Indiana's three
are re-elected incumbents on `iga.in.gov`, which is the one place in this cohort where a chamber
roster already carries the people. Washington and Wisconsin are the bulk and are all new members.

---

# Indiana — checked 2026-11-16, 1 of 3 has a portrait (not yet imported)

The three Indiana winners are re-elected incumbents seated by `CA_0374`, and all three are on the
chamber's own **2027** roster — bound by DISTRICT, which is the roster's own key: Streeter House 45,
Kippenbrock House 63, Ellington Senate 39. ⚠ The roster says **"Jeff" Ellington** where our row says
**"Jeffrey"**; the district binding is what confirms him, and it corroborates `CA_0374` rather than
contradicting it.

⚠ **They are NOT in `data/in-legislature-roster.json`.** That file holds the 150 members of the
**124th** GA; these three arrived mid-term. The portrait path moved too:
`iga.in.gov/images/legislators/**125/2027**/{house|senate}/{lpid}.jpg`.

## 🔴🔴 IGA SERVES A PLACEHOLDER FOR A MEMBER WITH NO PORTRAIT, AND NOTHING ABOUT IT SAYS SO

Streeter and Kippenbrock both return **HTTP 200, `content-type: image/jpeg`, 403,152 bytes** — and
the file is the **Indiana statehouse-dome graphic on a marble background**. It is a valid image, at
a plausible 686×886, from the chamber's own domain. It is not a face.

**sha256 `cc1c59ec61c5be8315015efdd69e6ce3430068f20b5fd579977ca25f9701dba5`** — pin it.

🔴 **THE COLLISION CHECK ONLY CAUGHT IT BECAUSE TWO MEMBERS IN ONE BATCH GOT IT.** `sweep-in-legislature-headshots.mjs`
compares sha256 across the sweep, which is why two people sharing bytes stood out. **Fetch one
legislator on their own and the dome ships as their headshot**, with every gate green: it decodes,
it is the right shape, it comes from the right host, and `check-headshot-faces.py` is schedule-only.
▶ **Match the placeholder by IDENTITY, not by collision.**

🔴 **AND MY FIRST POSITIVE CONTROL WAS ONE OF THE TWO SUSPECTS.** I used Streeter as the known-good
lpid — so the control certified the placeholder as "decodes fine, the fetch path works". **A control
drawn from the data under test moves with the defect.** Replaced with a member read off the roster
(Aylesworth, House 11 — 90,383 B, a real JPEG, a different sha). The paired negative still returns
the 691-byte React shell that `iga.in.gov` serves every non-browser client at HTTP 200.

## Outcome

| | | |
| --- | --- | --- |
| Jeff Ellington | Senate 39 | ✅ real portrait, 279×419 — ships native, nothing enlarged |
| Kellie Streeter | House 45 | ❌ no portrait published. Lead: she is a **Knox County Commissioner, District 3** until 2026-12-31 |
| Amy Kippenbrock | House 63 | ❌ no portrait published. Current office not yet established |

**What a body publishes is a finding, not a search failure.** IGA has not posted portraits for its
two newest House members; that is the answer to the question, and the two want their *current*
office as a source, the way the whole California batch did.

# Washington — 22 of 23 imported (CC_0439, 2026-11-16)

⚠ **An earlier draft of this section concluded "Washington is 23 separate hunts". That was
wrong, and it is left corrected rather than deleted because the reasoning that produced it is
the trap.** Three official routes really do fail — `leg.wa.gov/legislators` lists only SITTING
members (a sweep of its roster service confirms **0 of the 23 sit today**; positive control:
Speaker Laurie Jinkins found, 158 members parsed), `app.leg.wa.gov/districtfinder` returns the
**outgoing** member, and `voter.votewa.gov/CandidateList.aspx` serves **zero images**. Three
dead ends read like "there is no source". There was one, and it covered 20 people at once.

## 🟢 The source: the Secretary of State's online Voters' Guide

```
https://voter.votewa.gov/elections/voterguide.ashx?e=899&la=en&c=<county 1..39>&p=XX   # the index
https://voter.votewa.gov/elections/candidate.ashx?e=899&r=<RaceID>&b=0&la=en&c=<county> # the photos
```

JSON. `Categories[] -> Races[] -> Candidates[]`, each candidate carrying `HasPhoto` and a
`BallotName`; the race carries `Jurisdiction` ("Legislative District 14") and a position. The
photographs are base64 inside the **candidate** endpoint. 217 legislative candidates, 215 with a
photo.

🔴 **`e=898` IS THE PRIMARY. `e=899` IS THE GENERAL.** Nothing in the URL says so, and sourcing
from the primary mixes in people who lost in August. ⚠ **`config.ashx` cannot tell you which is
which — it returns a byte-identical 33,339-byte response for EVERY election id.** That uniform
answer is a broken detector, not a finding. `voterguide.ashx` carries the election's real `Name`
and is what settled it. Unused ids return a 65-byte null shell, which is a clean negative control.

🔴🔴 **THE RACE PAGE RENDERS EVERY CANDIDATE, LOSER FIRST.** Chelsea Dimas is the **second**
photo on her page; the first is Gloria Mendoza, the incumbent she beat. Read "the candidate
photo" positionally and you ship the defeated opponent under the winner's name, with every gate
green. ▶ **Bind the photo to its `BallotName`, never to an index**, and make Mendoza the paired
control: fetch the loser deliberately and assert her bytes never reappear under a winner.

🔴 **The data URI says `data:image/png` and the bytes are JPEG** (`FF D8 FF`). The declared type
lies; the magic number is the only answer.

🔴 **`candidatephoto.ashx`, `photo.ashx` and `statement.ashx` do not exist** — they 302 to
`error.aspx`, which answers **HTTP 200 with 9.6KB of HTML**. A guessed endpoint reports success
on the failing path.

🟢 **THE GUIDE IS ALSO THE NAMESAKE CHECK, which is why it outranks a campaign site.** Every race
publishes the district and position, from the body that ran the election. **All 20 matched ours
exactly — 20 for 20, no mismatches.** ⚠ And the surname sweep across the sitting roster shows why
that matters: **April Berg** is neither Reedy nor David Berg, and **Shaun Scott** is not Jaelynn
Scott. A full-name match is not an identity; a district-bound match from the chamber is.

## 🔴 LD 18 and LD 49 are absent from the state guide — the DISTRICTS, not the candidates

Checked across every county code, in **both** the primary and the general. Clark County carries
those two districts in its **own local voters' pamphlet** instead:

```
https://clark.wa.gov/sites/default/files/media/document/2026-09/2026clarkcountygeneralvp_web.pdf
```

Its text names Knott/McClintock (18-1), Letinich/Ley (18-2) and Harless/Mittelman (49-1) under
"State Legislative Offices", so it supplies the district binding for all three. ⚠ **But its
photographs are unusable:** single-channel **greyscale** at ~385×477, stored with an inverted
decode (they extract as negatives). Below our size floor and monochrome.
▶ A county that runs its own pamphlet is a **coverage gap in the state guide, not a gap in the
record.** Check the county before concluding a winner published nothing.

## The one that got away

**Randi L. Knott — LD 18 Position 1 — NOT SOURCED.** Her campaign site `electrandi.com` carries
only an embedded **Instagram** feed (refused: social-media licence) and one two-person bookshop
candid in which she is in profile looking down. The county pamphlet photo is greyscale and
undersized. ▶ **Lead:** she is a Brush Prairie horse-ranch owner and a retired government-affairs
professional, holding no current elected office, so there is no official-body route.

⚠ **CORRECTED 2026-11-16 (was: "re-check `leg.wa.gov/memberthumbnail/<id>.jpg` after she is
sworn in January 2027 — the cleanest future source").** That endpoint serves **150×200**, which
is a **2.85× upscale** to reach our 600×750 floor, so swearing-in does NOT solve her. Wisconsin
proved the same thing from the other direction: `docs.legis.wisconsin.gov` publishes 150×200 for
**all 132** of its members and holds nothing larger (the member detail pages carry the same file;
`_large`/`@2x`/`static` variants all 404). 🔴 **A legislature's own roster photo is an excellent
IDENTITY REFERENCE and a poor SOURCE.** Treat January 2027 as the moment her *identity* becomes
checkable, not the moment a publishable portrait appears.

## 🔴 A bare CDN URL is not the original — three different hiding places in one batch

| host | what it serves | what it holds | factor |
| --- | --- | --- | --- |
| `cityofvancouver.us` | `Kim-D.-Harless-1024x1024.jpg` | `Kim-D.-Harless.jpg` 1280×1280 | 1.6× pixels |
| `images.squarespace-cdn.com` | `?format=500w` | `?format=2500w` | 25× pixels |
| `static.wixstatic.com` | `/v1/fill/w_341,h_286,...` | the un-transformed base path, 4854×3238 | 160× pixels |

⚠ **Squarespace and Wix content-negotiate to WebP.** A sniffer that accepts only JPEG and PNG
throws every valid image away as "not an image" — that happened here and looked like a CDN block.
Let the decoder decide, not a magic-number allow-list.

## Outcome — 22 imported, faceless legislative winners 66 → 44

18 from the state Voters' Guide, plus four sourced elsewhere:

| | | |
| --- | --- | --- |
| Kim D. Harless | LD 49 Pos 1 | City of Vancouver council portrait, 1280×1280 — LD 49 not in the state guide |
| Diana H. Perez | LD 17 Pos 2 | City of Vancouver council portrait, 1280×1280 — supersedes her 563×677 pamphlet photo |
| Danica Noble | LD 32 Pos 1 | `electdanica.com`, 9504×6336 **in colour** — the pamphlet photo measured chroma **exactly 0** |
| Deken Letinich | LD 18 Pos 2 | `electdeken.com` media gallery, 2500×1667, cropped **right-flush** — he sits right of centre |
| Randi L. Knott | LD 18 Pos 1 | ❌ not sourced, see above |

⚠ **Two ship undersized and that is deliberate** — Joshua Thompson 152×183 and Alan Nolan
293×350, mirrored **at native size, never upscaled**. Neither has a campaign site; the small file
is what they themselves submitted to the state. Operator approved both on the contact sheet.

**Licence is `unknown` for all 22.** `voter.votewa.gov` carries "© Copyright 2023", publishes no
grant, and its photographs are **candidate-submitted** — so they are not the State's to license
in the first place. The three campaign/city hosts publish no photo policy on the pages that carry
these portraits. Only **federal** work is public domain; a state or city portrait is not, and
silence is not a grant.

# Wisconsin — 5 of 23 imported (CC_0440, 2026-11-16), 18 still open

🔴🔴 **WISCONSIN IS THE OPPOSITE OF WASHINGTON. DO NOT GO LOOKING FOR A STATE GUIDE — THERE IS
NOT ONE.** CC_0439 sourced 20 people from a single state publication. Wisconsin publishes **no
state voters' pamphlet at all**, so every one of these is an individual hunt. Three things were
measured before accepting that, because "there is no source" is the conclusion that is usually
wrong:

- **The legislature DOES publish official portraits — and every one is 150×200.**
  `docs.legis.wisconsin.gov/<session>/legislators/{assembly|senate}/<id>.jpg`. That is not a
  thumbnail in front of a larger file: the member detail page carries the same 150×200 image and
  nothing else, and `_large`, `@2x` and `/static/leg_photos/` all 404. It is the published size
  for **all 132 members**, control included.
- **0 of the 23 currently sit.** Parsed from the chamber's own roster: 99 Assembly + 33 Senate,
  exactly the chamber sizes. Positive control Speaker **Robin Vos** found; **Melissa Agard**
  correctly absent (she left for Dane County Executive).
- **Only 3 of the 23 ever served** (Binsfeld, Schutt, Severson), so the past-session rosters —
  which go back to **2013** and no further; 2009 and 2011 honestly 404 — reach almost none.

🟢 **SO THE 150×200 PORTRAIT IS AN IDENTITY REFERENCE, NOT A SOURCE.** It is too small to
publish and it is an authoritative picture of the right person. That is what confirmed Binsfeld
and Severson against their campaign photos, and it is the single most useful thing on that
domain. ▶ Use it that way everywhere, including Washington (see the corrected Knott note above).

## 🔴🔴 A campaign site carries other people, and the biggest photo is often not the candidate

On **severson4senate.com** the highest-scoring portrait by size and aspect ratio is **a woman**,
and a second man appears against a US flag. "Take the best image on the candidate's own site"
ships a stranger under his name with every migration gate green. **ismaelluna.com** carries three
other people; **krollforwi.com** is mostly **stock photography** (a stock doctor, stock hands
holding a phone). ▶ **Lay every candidate image from one site side by side and look before
picking**, and where an identity reference exists, put it in the same strip.

## 🔴🔴 A Commons "Own work / CC BY-SA 4.0" claim can be false, and it is cheap to disprove

The only one of the 23 with a Wikipedia lead image was Ellen Schutt:
`commons.wikimedia.org/wiki/File:Ellen_Schutt_Official.jpg`, uploaded as **"Own work"** under
**CC BY-SA 4.0** by a username. It is **byte-for-byte identical** to the Wisconsin Legislature's
official portrait of her — same sha256, 150×200, 41,489 bytes. The uploader did not take that
photograph and cannot license it.
▶ **When a Commons file looks like an official portrait, fetch the official one and diff the
bytes.** This repo already carries **184 rows** with an unverifiable CC BY-SA claim; this is
exactly how they get there. Nothing in `CC_0440` records a Creative Commons licence.

## 🔴 A Wikipedia article existing for a name is not evidence about that person

17 of the 23 names resolved to an en.wikipedia article. Reading each intro showed **2 were
somebody else entirely**: "Ben Gruber" is a **television producer**, and "Bernie Newman"
redirects to a **disambiguation page** of Canadian politicians. The other 15 are genuinely these
people and were used only as **leads** to campaign sites, never as a source. ⚠ They also settled
two look-alikes in the legislature's *staff* lists — "Nicolas William **Nic** Cravillion"
(a Senate staffer who won Senate 1) and "William Lee **Bill** Oemichen" — which a name match
alone could not have done.

⚠ **The Wikipedia/Commons sweep must be BATCHED.** A first attempt ran 46 separate requests, got
**429-rate-limited after the 4th**, and printed "no page" for all 19 remaining people — a
rate-limit rendered as a finding, with the controls already passed. The rewrite puts every title
in **one** query and runs the control **before, inside and after** the batch.

## 🔴 Portraits can be CSS background images, not `<img>` tags

**trevorjung.com** returns zero `<img>` elements over 250px and is full of photographs — they are
`background-image` on styled divs. An `<img>`-only scraper reports "no candidates" on a site full
of faces. ⚠ That host also **refuses Node entirely**, pages *and* files, so it needs a
browser-side download (same disposition as Mara Elliott in the CA batch).

## Outcome — 5 imported, faceless legislative winners 44 → 39

| | | | |
| --- | --- | --- | --- |
| Amy Binsfeld | Senate 9 | 8256×5504 | ✅ identity CONFIRMED vs her 2023 Assembly portrait |
| Erik Severson | Senate 25 | 1443×2048 | ✅ identity CONFIRMED vs his 2013 Assembly portrait |
| Ismael Luna | Assembly 8 | 960×1200 | ✅ solo portrait, recurs on his own site |
| Amy Zimmerman | Assembly 13 | 2500×1407 | ✅ solo portrait, recurs on her own site |
| John Kroll | Assembly 85 | 714×542 | ⚠ **undersized**, ships 434×543 at native, never upscaled |

**Licence is `unknown` for all 5.** Every site carries only a **"Paid for by …"** campaign-finance
disclaimer, which is required by law and grants nothing; two also assert "©". None publishes a
press kit, media page or photo policy.

### Refused, with the reason — re-read this before re-hunting them

- **Ellen Schutt** (Senate 11) — every portrait on her site is an **endorsement advertisement**
  with organisation branding across it (AFP Wisconsin, NRA, Turning Point Action). Publishing one
  as her official portrait would be editorialising. Her legislature portrait is 150×200.
- **Kevin Knoke** (Assembly 30) — one solo portrait exists, identity **not** confirmable: his site
  mixes stock photography with couple photos and he has no reference image.
- **Nic Cravillion** (Senate 1) — no solo portrait at all; a family group, a barn, a stock soldier.
- **Trevor Jung** (Senate 21) — see the CSS-background note above. The City of Racine confirms him
  as **Transit and Mobility Director** (by his `@cityofracine.org` address) but publishes **no
  photograph** beside the listing.
- **Ben Brist** (Assembly 61) — site reachable, renders no images to a non-browser client.

### Open leads for the remaining 18

- **Steve Wicklund** (Assembly 33) — **Village President of Union Grove**, already in our
  `office_terms`. `uniongrove.net` is up but its board page 404s; find the right path.
  ⚠ He replaces **Robin Vos**, whose seat Assembly 33 is.
- **Daniel J. Bukiewicz** (Assembly 21) — appears to hold office in **Oak Creek**;
  `oakcreekwi.gov` is CivicEngage and the obvious mayor paths 404.
- **Becky Nichols, Kevin Krentz, Bryson Reyes, Jeremiah Fredrickson** — verified Wikipedia
  articles exist but carry **no external links**, so no campaign site is known yet.
- **Anthony W. Phillips, Bradley Petersen, Marty Ryan, Brandy Tollefson, Ben Gruber,
  Bernie Newman** — no Wikipedia article and no campaign site found.
