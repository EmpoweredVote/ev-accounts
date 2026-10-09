# Los Angeles headshot replenish list — audited 2026-10-07

Scope: everybody the Los Angeles browse page renders.

    https://essentials.empowered.vote/results?browse_government_list=0644000&browse_label=Los+Angeles&browse_state=CA&view=elections

Method: pulled both payloads the page fetches (`browse/by-government-list`,
`browse/elections-by-government-list`), downloaded every rendering image **at its origin**,
measured it there (never the `<img>` on the page — see `project_la_county_headshot_audit`),
then looked at all 139 on labelled contact sheets.

**612 people. 139 render a photo, 473 are blank. 120 of the 139 pass. 19 are flagged below.**

**▶ CLOSED 2026-10-08. All 19 are resolved: 17 replaced across nine batches (`CC_0195`-`CC_0210`),
2 closed unchanged by operator ruling.** The blanks in section G are a separate programme.

The pass rate is the positive control: the detector is not uniformly failing.

Quality bar applied (from `feedback_headshot_crop_composition`, `feedback_no_facebook_photos_press_only`,
`project_la_county_headshot_audit`): face 20–62% of frame height, head not clipped, ≥300px on the
short side at the ORIGIN, portrait orientation, press / official / campaign source, no monochrome.

---

## A. City of Los Angeles — officeholders (19 render, 0 blank)

| # | Person | Seat | Defect | Replacement found |
|---|--------|------|--------|-------------------|
| 1 | ~~**Curren D. Price Jr.**~~ ✅ **DONE 2026-10-07** (`CC_0195`+`CC_0196`) | CD 9 | **250×333** — under the floor. Only LA-city row on the `<uuid>/default.jpeg` path, and it carries **no `photo_origin_url` at all** (no provenance). | ✅ **YES.** `cd9.lacity.gov/sites/g/files/wph2021/files/2022-02/Curren_D_Price_Jr_Portrait.jpg` — **2213×2728**, the *same photograph*, 8.8× larger. Identity confirmed by the city's own alt, "Councilman Curren D Price Jr". |
| 2 | ~~**Imelda Padilla**~~ ✅ **DONE 2026-10-07** (`CC_0195`+`CC_0196`) | CD 6 | Environmental shot outside a hot-dog stand. Head ≈15% of frame. Commercial signage behind her. | ✅ **YES.** `cd6.lacity.gov/wp-content/uploads/2024/03/photo-imelda-portrait-02.jpg` — **1500×1500**, alt "Imelda Padilla Portrait", City Hall background. |
| 3 | ~~**Tim McOsker**~~ ✅ **DONE 2026-10-09** (`CC_0209`) | CD 15 | Street scene. Head ≈15% of frame, cars and trees behind him. | ❌ **No.** The city's own file (`/meet-tim`) is this same image, and its ORIGIN is only **400×267**. Real ceiling at lacity.gov. Lead: filename is Flickr id `51857445559`, so a larger original may exist on Flickr. |
| 4 | ~~**Ysabel J. Jurado**~~ ✅ **DONE 2026-10-08** (`CC_0210`) | CD 14 | Loud mural background — and, found on the way, the live file is a **1.42x enlargement** of the city's 960x530 landscape derivative, carrying a **false `cc_by_sa_4.0`** licence. | ✅ **YES.** Wikimedia Commons `Ysabel Jurado, 2025.jpg`, 1920x1280, **public domain (PD-CAGov)**, author her own council district. |

### Bookkeeping only (image is correct, the record is untidy)

| # | Person | Problem |
|---|--------|---------|
| 5 | ~~Karen Ruth Bass~~ ⬜ **CLOSED 2026-10-08, no action** (operator ruling) | Stored file is `2f96d5e2-8284-490d-8ba1-d204b649f45a-headshot.jpg`. That UUID **matches no row anywhere in the schema** (checked `politicians`, `politician_images`, `offices`). Image is correct: 2614x3486, head 63%. **One of 48 corpus-wide — see the batch 9 section.** |
| 6 | ~~Monica Rodriguez~~ ⬜ **CLOSED 2026-10-08, no action** (operator ruling) | Stored at a **truncated stem** — `7c0d3bdd-headshot.jpg`, 8 hex characters, not the full id. Image is correct: 600x750, head 41%. **One of 37 truncated stems corpus-wide, none of which collide — see the batch 9 section.** (Estuardo Mazariegos, `92876cb7-headshot.jpg`, is the same shape.) |

---

## B. City of Los Angeles — 2026 candidates

| # | Person | Race | Defect |
|---|--------|------|--------|
| 7 | ~~**Barri Worth Girvan**~~ ✅ **DONE 2026-10-07** (`CC_0198`, superseded by `CC_0199`) | CD 3 | **White rectangle burned into the top-right corner** — a compositing artifact, visible to a voter. |
| 8 | ~~**John McKinney**~~ ✅ **DONE 2026-10-08** (`CC_0205`) | City Attorney | Full-length walking shot. Head ≈12% of frame. |
| 9 | ~~Timothy Gaspar~~ ✅ **DONE 2026-10-07** (`CC_0197`) | CD 3 | Half-body, head small, busy signage behind. **Borderline.** |

---

## C. Los Angeles County

| # | Person | Seat | Defect |
|---|--------|------|--------|
| 10 | ~~**Robert S. Draper**~~ ✅ **DONE 2026-10-08** (`CC_0200`) | LA Superior Court judge | **Worst on the page.** Candid snapshot in a courthouse lobby. **672×446 landscape**, subject off-centre and at an angle, flags and furniture behind, poor light. |
| 11 | ~~**Nathan Hochman**~~ ✅ **DONE 2026-10-07** (`CC_0197`) | District Attorney | Full-body standing portrait between flags. Head ≈10% of frame. |
| 12 | ~~Patrick Connolly~~ ✅ **DONE 2026-10-07** (`CC_0197`) | LA Superior Court judge | 588×554, three-quarter body, bokeh city background. **Borderline — crop would fix it.** |

---

## D. Los Angeles school and college boards

| # | Person | Seat | Defect |
|---|--------|------|--------|
| 13 | ~~**Scott Schmerelson**~~ ✅ **DONE 2026-10-08** (`CC_0204`) | LAUSD District 3 | Heavy blur — an upscale of a small original. Top of head clipped. |
| 14 | ~~**Sara Hernandez**~~ ✅ **DONE 2026-10-08** (`CC_0205`) | LACCD Seat 4 | **200×300** — under the floor. |

---

## E. Candidates in districts that cover Los Angeles

| # | Person | Race | Defect |
|---|--------|------|--------|
| 15 | ~~**Cristian Morales**~~ ✅ **DONE 2026-10-08** (`CC_0205`) | CA-43 | Heavy blur — an upscale. Head clipped at the top. **Also an Instagram source.** |
| 16 | ~~**Angela Gonzales-Torres**~~ ✅ **DONE 2026-10-08** (`CC_0205`) | CA-34 | **200×300** — under the floor. |
| 17 | ~~**Houston Brignano**~~ ✅ **DONE 2026-10-08** (`CC_0210`) | CA-36 | 🔴 **THIS DEFECT LINE WAS WRONG.** "Head ≈10% of frame" was eyeballed; measured, his head is **27.3%**, inside the 20-62% bar. Shipped anyway as a framing improvement, not a rescue. |
| 18 | ~~**Xavier Becerra**~~ ✅ **DONE 2026-10-08** (`CC_0210`) | Governor | Candid at a campaign event. A microphone intrudes bottom-right, a blurred object left. Face sat at 65.2% of the frame width. |
| 19 | ~~**Samantha Mota**~~ ✅ **DONE 2026-10-08** (`CC_0210`) | CA-37 | Casual shot against a mural, arm raised. Not a portrait. **Not an enlargement — the wrong frame.** |

---

## F. Visible on this page, but NOT Los Angeles' problem

These come from the shared national and state corpus. Every page in California shows them.
They are listed so nobody re-finds them here and files them as an LA defect.

- **All 9 Supreme Court justices at 151×189**, Senators Padilla and Schiff at 180×225, and
  **7 California US House members at 175×193 to 175×263** — all under the floor, all on the
  `<uuid>/default.jpeg` path.
- Gavin Newsom — 3130×2200 **landscape** podium candid.
- Ricardo Lara and Kenneth R. Yegan — full-body.
- Eleni Kounalakis 200×300 · Grant Parks 275×387 · Isaac G. Bryan 200×300 ·
  Malia M. Cohen 280×280 · Tony Thurmond 207×290 · Wade Crowfoot landscape.

---

## G. Blanks (no photo at all) — 473 of 612

| Cohort | Blank |
|--------|-------|
| **City of Los Angeles officeholders** | **0** — fully covered |
| LA County (almost all Superior Court judges, seated by `CA_0183` from the court rosters) | 405 |
| Candidates in LA races | 23 |
| Candidates in other races on this page | 36 |
| State of California | 2 |
| Other | 2 |

The Superior Court bench is the whole blank story. It is a separate programme, not a
replenish job.

---

## Done so far

**2026-10-07 — Price and Padilla are live.** Crops approved on the proof sheet, uploaded to
`politician_photos/la_city/2026-10-replenish/<pid>.jpg` (read back byte-identical), then two
migrations applied to production. Verified on the rendered page: Price now 1200x1500, Padilla
1128x1410.

### 🔴🔴 THE RULE THIS PASS CORRECTED — THE GRID READS `images[]`, NOT THE SCALAR

`CC_0195` repointed `photo_custom_url` and `photo_origin_url`. The API returned the new URLs
immediately, checked three ways. **The live page did not change.** The essentials frontend's
`PoliticianGrid.getImageData()` prefers the `politician_images` array and falls back to the scalar
only when the array is empty:

```js
if (pol.images && pol.images.length > 0) {
  const defaultImg = pol.images.find((img) => img.type === "default");
  return { url: (defaultImg || pol.images[0]).url, ... };
}
return { url: pol.photo_origin_url, focalPoint: null };
```

So the standing rule "a `politician_images` row changes nothing a voter sees" is true of the
BACKEND and **false of this grid**. `CC_0196` repointed the images rows and the page changed the
same minute.

▶ **Every remaining item on this list must write BOTH**, and gate on the pair agreeing. Also assert
exactly one `type='default'` row — two make the grid's `find()` pick an arbitrary one.

▶ **A correct API response is not evidence the fix landed.** Only the rendered `<img>` is.

### 2026-10-07, batch 2 — Hochman, Connolly, Gaspar (`CC_0197`)

**14 of the original 19 remain.**

| Person | Was | Now | How |
|---|---|---|---|
| Nathan Hochman | 1069×1200, head ~10% | **630×788**, head 40.0%, eyes 30.5% | Pure crop. `da.lacounty.gov`'s own original is also 1069×1200 — measured at the origin, nothing larger exists. |
| Patrick Connolly | 588×554 suit shot from LAist | **736×920**, head 42.4%, eyes 28.8% | **A different photograph**: the judicial-robe studio portrait on `reelectjudgepatconnolly.com` (1080×1080). Operator compared the faces and approved. |
| Timothy Gaspar | 1011×1404, busy signage | **840×1050**, head 50.5%, eyes 26.7% | Pure crop. `timgaspar.com` publishes no better portrait. |

Nothing was enlarged; every output is a native-size crop. All three passed the no-monochrome gate.

⚠ **Connolly's identity rests on a filename-only alt** (`DSC_2550_pp.png`) and the fact that it is the
single hero of a single-candidate site. That is weaker than the two-source standard. It was approved
on sight against the LAist image we already held.

### 🔴 A PROOF SHEET CAN GO STALE BETWEEN THE NUMBERS AND THE PICTURES

The first version of this batch's proof sheet was published with **re-measured numbers and the
PREVIOUS crops**: the images were cached as `data:` URIs in a separate file, the crops were re-cut,
and only the page's text was rebuilt. The operator reviewed a Hochman frame that cut his face in
half — a crop that had already been discarded — and rejected it.

▶ **Re-encode the assets in the same step that rebuilds the page, and diff them.** The check that
caught it afterwards was comparing each new data URI against the old one; all three "proposed"
tiles had changed, meaning every one on the published page was stale.

▶ **"I looked at the render" is only true for the version you looked at.** Looking once, then
editing, then publishing is not the same as looking at what you published.

### 2026-10-07, batch 3 — Girvan (`CC_0198`)

**13 of the original 19 remain.**

The white block was never a photo problem. barriforthevalley.com publishes her portrait as a
**transparent-background cutout** (`…7f10fc86…~mv2.png`, 1000×1465 RGBA). Something composited it
onto a leafy backdrop and left white where a corner fill failed.

Shipped: the same cutout on a neutral radial-grey studio backdrop, cropped 4:5 to **680×850**,
head 48.8%, eye line 27.1%, chroma 21.8. A pure crop of the composite; nothing enlarged.

⚠ **This image is composited.** The subject pixels are untouched — only the background behind the
alpha is new. The operator reviewed a white-background version in the live card first and asked for
a neutral backdrop, because a white cutout blends into the white card and reads as floating.

🟢 **CHECK A CUTOUT FOR A WHITE MATTE BEFORE PUTTING IT ON GREY.** A cutout matted on white grows a
pale halo the moment the background stops being white. The test: compare the luma of the
semi-transparent rim against the opaque pixels just inside it. Here the rim measured **40.7 against
78.2 — darker by 37.5**, so it is straight alpha with no matte baked in. A white matte would have
made the rim far *brighter*. Then look at the edges at 3× against the new backdrop anyway.

🟢 **A PREVIEW OBJECT IN THE BUCKET IS THE CHEAPEST WAY TO SEE THE REAL CARD.** Upload the candidate
to `_preview/`, swap it into the live page's `<img>` with Playwright, screenshot, then delete.
🔴 **The delete said "Successfully deleted" while the public URL kept serving 200** — a stale CDN
edge copy. Confirm removal with an authenticated read or a bucket listing, never the public URL.

Rejected and recorded: Ballotpedia holds a larger file (1213×1574) whose alt text names her, but it
is a half-body street shot with the head at ~12% of frame; cropped tight it yields about 400×500.

### 2026-10-07, batch 4 — Girvan again (`CC_0199`, supersedes `CC_0198`)

**Operator wanted the BALLOTPEDIA photograph.** I had read "go with the alternative" as "use a
neutral background" when it meant "use the other source", and `CC_0198` is what that misreading
shipped. Now live: `ballotpedia-api4/files/DSC4920_20260714_204927_31330_1.jpeg` (1213×1574)
cropped 4:5 to **720×900**, head 44.4%, eye line 27.8%, chroma 37.4. A pure crop — **nothing
composited**, so the "this image is composited" caveat is retired.

### 🔴 I ARGUED AGAINST THIS SOURCE ON A NUMBER I NEVER MEASURED

Batch 3 recorded that the Ballotpedia file had "the head at roughly 12% of the frame" and would
"crop to about 400×500". Both figures were eyeballed off a contact-sheet thumbnail. **Measured on
the file: the head is 400 px of 1574 — 25.4% — and it crops to 720×900, LARGER than the 680×850
composite that was shipped instead.** A rejection is a measurement, not an impression; if a source
is being ruled out on size, measure it at the origin before writing the number down.

### 🔴 MEASURE THE HORIZONTAL CENTRE. DO NOT READ IT OFF A GRID BY EYE.

Twice in this batch I misread the x axis of a labelled grid and cut a face to the edge of the
frame — once for Hochman, once for Girvan. Both times the labels were in source pixels while I was
judging positions on a resized render.

▶ **Use a skin-tone column-density centroid across the eye band** (y from about the brow to the
mouth). For Girvan it returned x=622 against the 430 I had guessed. Assert the result: the shipped
crop has the face centre at exactly 50.0% of the width.

▶ **Look at the crop itself before anyone else does.** The card simulation caught the first bad
Girvan crop, and a plain side-by-side caught the bad Hochman one.

### 2026-10-08, batch 5 — Draper (`CC_0200`), and what the search turned up

**12 of the original 19 remain.**

Photo: the live file was byte-identical to LAist's 672×440 web variant of
`screenshot-2026-04-27-at-4-13-39-pm.png`. Their S3 **original is 1342×890** — twice the linear
size — so the better crop was behind the variant we had taken. Shipped: the same frame recropped to
**592×741**, head 60.9%, eye line 31.0%.

Operator chose this over an LA Times staff portrait (5891×3927, Robert Gauthier) because he wears
**opaque sunglasses** in it and at card size it reads as a dark rectangle. ⚠ **Whether LA Times staff
photographs belong in the corpus at all is still unanswered** — it will come up again.

Rejected: `judgerobertdraper.com` returns **410 Gone**; recovered from the Wayback Machine, its only
portrait is 376×284 of him looking down at papers, with nothing larger behind the image optimiser.
Ballotpedia has no photo of him. The Daily Journal profiles sit behind a Sucuri firewall that
refuses a real browser, and the Wayback has no snapshot of either.

### 🔴🔴 A SOURCING FAILURE IS A DEPARTURE SIGNAL — AGAIN

Ballotpedia had no photograph because **Draper lost his seat.** He was defeated in the 2026-06-02
primary by Tal Khan Valbuena, 43.2% to 56.8%; Valbuena won outright so the general was cancelled;
**Draper's term ends 2027-01-04.** Our own data already said so independently — race
`LA Superior Court Office 2` records Valbuena `won` and Draper `lost` — we had just never carried
the result into occupancy.

**He still holds the seat today, so occupancy was correct and was not changed.** A certified result
is not a fact about who holds the seat.

The handover is now prepared as **dated rows**, which is what the temporal model is for:

- **`CC_0201` (applied):** `seat_officeholder` closed Draper at 2027-01-04 and seated Valbuena from
  2027-01-05. `current_office_holders` filters on `CURRENT_DATE`, so the future row is invisible
  until then and the view flips itself. No trigger, no job, no deploy. The gate asserts *today is
  unchanged* and probes the view's own predicate at both 2027-01-04 and 2027-01-05.
- **`CC_0202` (WRITTEN, NOT APPLIED — refuses before 2027-01-05):** the two columns that cache
  "current" and will not move. `politicians.is_incumbent` and the legacy `politicians.office_id`.
  **Nothing in the codebase recomputes `is_incumbent`** — it is only read, as four
  `p.is_incumbent = true` filters in `essentialsBrowseService.ts`. Left alone, Draper becomes an
  active "incumbent" with no seat and **Valbuena is hidden from address search while holding it.**
  Both guards were proved: it refuses today, and with the guards relaxed the body passes inside a
  rollback.
- **`CC_0203` (applied):** the seat was named **"LA County Superior Court - Robert S. Draper"** — the
  district named after its occupant. Renamed to **"LA County Superior Court - Office 2"**, taken
  from the race name, not invented.

### ▶ BACKLOG: 364 LA SUPERIOR COURT SEATS ARE STILL NAMED AFTER THEIR SITTING JUDGE

425 districts are labelled `LA County Superior Court - <name>`; **364 still match their current
holder exactly** (365 before `CC_0203`). It came in with `CA_0183`, which seated 421 judges from the
court roster. Every one has the same failure mode at its next handover. Not renamed blind here:
most have no office number in our data, and a guessed number is worse than a stale name.

### 2026-10-08, batch 6 — Schmerelson (`CC_0204`)

**11 of the original 19 remain.**

The live 600×750 was an **enlargement**. Measured edge energy (mean absolute neighbour difference
over luma) **1.15 against 7.15** for the replacement — six times less real detail in a file with
nearly three times the pixels, and the top of his head clipped.

Shipped: `SMS-squaresredlanyard-triangle-hands.jpg` from **boardmemberscott.org**, his own site.
947×615 is the original (srcset tops at 771w; the unsuffixed WordPress file is this). Cropped to
**360×451**, head 43.0%, eye line 31.0%, pure crop. The smallest thing shipped in this run, taken
knowingly over a larger blurred file.

🟢 **EDGE ENERGY SETTLES "BIGGER BUT BLURRIER".** A pixel count is not information. Compare
`abs(diff(luma))` means before arguing about dimensions — it turned a judgement call into a number.

🔴 **IT ALSO FIXED A CLAIM WITH NOTHING BEHIND IT.** His `photo_origin_url` was **NULL** while the
image row asserted licence `government-official`. Same defect class as Price's `cc_by_sa_4.0`.
▶ **When `photo_origin_url` IS NULL, treat the licence as unverified** — it was asserted about a
file whose source nobody recorded.

Ceilings measured: `lausd.org` and `boe.lausd.org` both answer **403 to a real browser**, not only
to curl. Everything else on his own site is a classroom or cafeteria scene.

### 2026-10-08, batch 7 — McKinney, Morales, Hernandez, Gonzales-Torres (`CC_0205`)

**7 of the original 19 remain.** All four verified on the rendered page, not on the API.
Proof sheet: https://claude.ai/artifact/PCsCQZJQ7fCv2bzqUjXsYD

| Person | Was | Now | How |
|---|---|---|---|
| John McKinney | 600×750 enlargement of a 540×751 full-length shot on the City Hall steps | **578×723**, head 48.3%, air above the hair 8.7%, face centre 49.5% | Ballotpedia `JohnMcKinney_CA.png` (680×723). **Pure crop, no resize** — the source height is the binding constraint. |
| Cristian Morales | 600×750 enlargement, edge energy **1.48**, head clipped | **1200×1500**, head 45.0%, eye line 31.6%, centre 50.5% | Ballotpedia `ChristianMorales26-2_2026-09-03_181854.jpg` (3024×4032), downscaled 2.16×. |
| Sara Hernandez | 200×300 | **1200×1500**, head 45.0%, eye line 32.1%, centre 50.5% | The **same photograph** at full size, `SaraHernandez2022.jpg` (8192×5464), downscaled 3.12×. |
| Angela Gonzales-Torres | 200×300 | **1200×1500**, head 45.0%, eye line 31.8%, centre 50.0% | The **same photograph** at full size, `Angela_GonzalesTorres_20250814_062216.jpg` (4094×5337), downscaled 2.53×. |

Nothing enlarged, nothing composited, every one above the chroma floor.

🟢 **A BYTE COMPARISON CAN RETIRE THE IDENTITY QUESTION ENTIRELY.** Both 200×300 files were
**byte-identical to Ballotpedia's own 200×300 thumbnail** of the originals shipped here. So neither
is a change of photograph: the subject pixels are the ones we already published, at 4× and 6× the
linear resolution. There was nothing left to verify, and no second source was needed. Download the
thumbnail and compare bytes before spending a search on provenance.

🔴 **MORALES WAS A LICENCE DEFECT, NOT ONLY A QUALITY ONE.** His `photo_origin_url` was
`instagram.com/cmoralescagov`. The standard is press, official or campaign; a social media profile
is none of those. It was not on the original audit list as a licence problem because the audit
measured pixels, not provenance. **`CC_0205`'s gate now refuses any row whose `photo_origin_url`
matches instagram / facebook / twitter / x.com / linkedin / tiktok** — worth copying forward.

### 🔴 THE SKIN-TONE CENTROID IS NOT A UNIVERSAL FACE-CENTRE DETECTOR

`feedback_measure_dont_eyeball_crop_geometry` says to centre a crop on a skin-tone column centroid
across the eye band. On John McKinney it returned **x=244 against a true centre of 359 — 115 px
off**, because the Cb/Cr box that defines "skin" is tuned for lighter skin and under-detects his
face. On Angela Gonzales-Torres it was 126 px off, pulled by asymmetric lighting.

▶ **The Haar face-box centre and the eye midpoint agreed with each other on all four subjects**
(spread 0–32 px). Those are what the crops use. Keep the skin centroid as a third reading that
flags disagreement, never as the answer.

### 🔴 TWO DETECTORS, EACH WRONG ON WHAT THE OTHER GETS RIGHT

Head top was measured two ways and they disagreed on half the batch:

- A **background-departure column scan** reads the first row that stops matching the background. It
  was right on the two plain-backdrop portraits and wrong by **236 px on Morales** (his flags) and
  **262 px on Hernandez** (a building behind her) — busy texture answers the same way a head does.
- **GrabCut segmentation** asks which pixels are the subject, so texture does not fool it. It fixed
  Hernandez, returned 0 on Gonzales-Torres (the plain grey backdrop got absorbed into the
  foreground) and **could not run at all** on McKinney, whose face fills the frame so the seed
  rectangle left no background samples.

▶ **Neither is right everywhere, so neither verdict is trustworthy on its own.** Draw every reading
back onto the photograph and look at it. That is what caught all four errors, and it is the only
step that worked on every image.

### 🔴 THE GATE WAS PROVED BY WATCHING IT FAIL, THREE WAYS

Before `CC_0205` was applied, three tampered copies were dry-run against production: a wrong name on
the McKinney row, Morales' origin left as an Instagram URL, and an origin pointed at our own bucket.
All three raised, each on the guard it targeted. A post-verify gate that has only ever passed has
not been tested.

### ▶ FOUND ON THE WAY: FOUR CA 2026 GENERAL CANDIDATES RENDER AS GREY INITIALS

Hernandez did not appear on the Elections view after the fix, and the reason was not the photograph.
She has **two `race_candidates` rows for the same contest**: the 2026-06-02 primary row
(`240be7d9`, `result = advanced`) carries `politician_id = 3ce8b7fa`, and the 2026-11-03 general row
(`c7a5fca4`) carries `politician_id = NULL`. The general row therefore has no photo and the card
falls back to initials.

Measured, not guessed. The loose predicate — an unlinked active candidate sharing a first and last
name with any linked row — returns 22 people, which is a **lead count and not evidence**. Narrowed
to the shape Hernandez actually has (a linked primary row and an unlinked general row for the
**same office** in the same cycle) it returns exactly **four**, and all four politicians already
carry a photograph:

| Candidate | Office | Politician row |
|---|---|---|
| Fiona Ma | Lieutenant Governor | `41ef8aaa` |
| Gloria Romero | Lieutenant Governor | `f8189ff3` |
| Richard Barrera | Superintendent of Public Instruction | `96485b13` |
| Sara Hernandez | State Senate District 26 | `3ce8b7fa` |

All four are on the **CA 2026 Statewide General**, so this is one import that created its rows
unlinked. The fix is one `UPDATE essentials.race_candidates SET politician_id = …` per row.
**Not done here** — it is a different table from the one this batch was approved to change, and it
wants its own slot and its own gate.

⚠ Do not widen the predicate to the 22. A shared first and last name is not identity; what makes
these four safe is the same office in consecutive stages of the same election.

### Also measured, so nobody re-finds it

- The production card is **95×127 CSS px with `object-fit: cover`** — taller than 4:5, so a 4:5 crop
  loses about 6.5% of its width at the sides. Worth composing for.
- The `view=` query parameter does **not** switch the browse view. `view=school-board` silently
  renders the representatives list. The tab must be clicked; the School Board tab's own URL is
  `view=educators`. A scan that looks for one person on "the page" can miss them for this reason
  alone — carry a positive control, as the scans here did.
- The API exposes the **serving** URL in a field named `photo_origin_url`. That is not the database
  column of the same name, which holds provenance. Do not read one for the other.

### 2026-10-09, batch 8 — McOsker (`CC_0209`)

**6 of the original 19 remain.** Verified on the rendered page.

| Was | Now |
|---|---|
| 600×750, an enlargement of a 400×267 street scene; head ≈15%, face clipped at the card's left edge | **1032×1290**, head 49.5%, air above the hair 7.8%, face centre exactly 50.0%, chroma 36.5. **A pure crop with no resize.** |

Shipped: `Tim_McOsker_full_portrait_(cropped).jpg` from Wikimedia Commons, **1045×1393** — the
official studio portrait, suit and tie against the city flag, the same frame the other nineteen LA
officeholders are shot in. Author **Los Angeles City Council District 15**, 13 January 2023,
**public domain** under the California Public Records Act (PD-CAGov, citing *County of Santa Clara
v. CFAC*).

### 🔴 THE "400×267 CEILING AT LACITY.GOV" WAS A COPY OF A COPY

This worklist recorded the city as a real ceiling. It was — of a borrowed thumbnail.
`cd15.lacity.gov/meet-tim` serves a Drupal 636×358 derivative of a file the city had itself
downloaded from **Flickr at the `_w` size**, which is 400 px wide. The city was never the
photograph's publisher, so measuring its ceiling measured nothing.

▶ **When an origin filename looks borrowed, chase the name before trusting the ceiling.** The
Flickr id in that filename is what unlocked this — not by yielding the photo, but by proving the
city was a dead end and sending the search elsewhere.

### 🔴 THE FLICKR LEAD RESOLVED, AND IS REJECTED ON LICENCE AND ON PICTURE

`flickr.com/photos/193472024@N08/51857445559` is **his own account**, so a permitted source class.
But the page states **All rights reserved**, the file is titled
`©CourtneyLindbergPhotography_082421_3326`, and Flickr serves no larger than `_b` 1024×683
(`_h` and `_k` both 410). It is landscape and a street scene; a compliant 4:5 crop yields about
350×438. Worse licence, worse picture, smaller output.

### 🔴 WE WERE ASSERTING `cc_by_sa_4.0` OVER AN ALL-RIGHTS-RESERVED PHOTOGRAPH

The row being replaced claimed `cc_by_sa_4.0`. Nobody licensed that file CC BY-SA — it is a
derivative of an ARR Flickr photograph with a photographer's copyright in its title. Same defect
class as Price's `cc_by_sa_4.0` (`CC_0195`) and Schmerelson's `government-official` over a NULL
origin (`CC_0204`): **a licence written from the shape of a URL rather than from anything the
source said.** ▶ Three of these have now been found in one programme. Treat any licence on a row
whose origin is a CMS derivative path as unverified until the real publisher is identified.

### ⚠ THE OPERATOR RULED ON FACEBOOK PROVENANCE (2026-10-09)

Commons records this portrait's origin as a council-district **Facebook** post. The house rule is
press/official only, no Facebook photographs. Ruled outside that rule: the **author** is the
government body and the work is public domain **by statute**, not by anyone's permission —
Facebook is the venue the city published in, not the rights holder. The citation points at Commons;
the Facebook origin is described in the licence prose.

### ⚠ THE GATE CANNOT VALIDATE LICENCE PROSE

A tamper control that corrupted the licence TEXT passed green, because the migration writes that
text and then verifies it matches what it wrote — self-consistent by construction. The gate checks
the **shape** of the origin URL (external, image extension, not our bucket, not social media) and
that the pair agrees. It cannot know whether the words are true. Only a human reading the source
page can.

### 2026-10-08, batch 9 — Brignano, Jurado, Becerra, Mota (`CC_0210`)

**0 of the original 19 remain. THIS WORKLIST IS CLOSED.** All four verified on the rendered page, not
on the API. Proof sheet: https://claude.ai/artifact/YSu7TgnzbadRwtv3FhXXgb

| Person | Was | Now | How |
|---|---|---|---|
| Houston Brignano | 600×750, head **27.3%** (not the ≈10% this list recorded) | **496×620**, head 45.0%, air 9.0%, centre 50.0% | Ballotpedia `Houston_Brignano_20260428_022543.jpg` (1024×1024). **Pure crop, no resize.** Face box 169 px → 230 px. |
| Ysabel J. Jurado | 600×750, a **1.42× enlargement**, licence falsely `cc_by_sa_4.0` | **777×971**, head 45.0%, air 9.0%, centre 50.1% | Commons `Ysabel Jurado, 2025.jpg` (1920×1280), **PD-CAGov**. **Pure crop.** Face box 204 px → 349 px. |
| Xavier Becerra | 600×750, face at 65.2% of width, microphone intruding | **1200×1500**, head 42.8%, air 4.4%, centre 49.2% | Commons `HHS Xavier Becerra.jpg` (2400×3000), already 4:5. **Downscaled 2×, not cropped.** |
| Samantha Mota | 600×750, arm raised against a mural | **1126×1407**, head 51.9%, air 7.8%, centre 50.0% | `motaforcongress.com` hero (2304×1536). **Pure crop, no resize.** |

Nothing enlarged, nothing composited, every one above the chroma floor (32.3 / 47.1 / 44.4 / 80.8).

### 🔴🔴 A DEFECT LINE ON THIS LIST WAS AN EYEBALLED NUMBER, AND IT WAS WRONG BY 2.7×

Row 17 read "Full-body standing shot. Head ≈10% of frame." **Measured, Brignano's head is 27.3% of
the frame — inside the 20-62% bar this list applies.** The live file is also not an enlargement: it
is a **1.36× downscaled crop of the Ballotpedia frame itself**, proved by reconstructing the crop
(mean absolute difference 3.1) and by matched-face edge energy (3.79 against 3.85).

This is the same defect as the Girvan rejection in batch 3, where "head ~12%, crops to 400×500" was
read off a thumbnail and the file really measured 25.4%. ▶ **A DEFECT LINE IS A MEASUREMENT TOO, not
only a rejection.** Re-measure a flagged row before sourcing against it — the list can be wrong in
the direction of over-reporting, and then the search is for a problem that is not there.

He was replaced anyway, deliberately: the crop takes his face from 169 px to 230 px and the framing
from 27.3% to 45.0%, at the cost of a frame that is smaller in total pixels (496×620 against
600×750). **Face pixels, not frame pixels, are what the card shows.**

### 🔴 JURADO CARRIED TWO DEFECTS AND THE LIST NAMED NEITHER

It said "loud mural background. Head size is acceptable. Borderline — low priority." Both of the
real problems were invisible to a framing audit:

- **An enlargement.** Her face box is 204 px, upscaled from the 144 px face in
  `cd14.lacity.gov/.../Cd14-Ysabeljurado_960x530.png` — a **960×530 landscape** derivative. Edge
  energy at a matched 200 px face: **5.19 against 5.11.** More pixels, no more detail.
- **A false licence.** `cc_by_sa_4.0`, asserted over a Drupal CMS derivative path. Nobody licensed
  that file CC BY-SA.

🔴 **THAT IS THE FOURTH FALSE LICENCE IN THIS PROGRAMME** — after Price (`cc_by_sa_4.0`,
`CC_0195`), Schmerelson (`government-official` over a NULL origin, `CC_0204`) and McOsker
(`cc_by_sa_4.0` over an ARR photograph, `CC_0209`). All four were written from the shape of a URL.
▶ **The rule now has four data points: a licence on a row whose origin is a CMS derivative path is
unverified until the real publisher is named.** Commons settled this one — her own council district
is the author, so the portrait is public domain by statute.

### 🔴 A CAMPAIGN PORTRAIT CAN BE A CUTOUT *AND* CLIPPED — CHECK BOTH

`voteforhouston.com` publishes a 2135×2996 studio portrait of Brignano that looked like the obvious
answer. Two things killed it, and only one was visible on a contact sheet:

- It is a **transparent-background cutout** — 36.9% of its pixels are transparent. PIL renders the
  palette's fill colour for those, so on a contact sheet it looks like a photograph shot against a
  teal backdrop. **Only reading the alpha channel shows what it is.** Shipping it needs a composited
  backdrop, which the operator rejected on Girvan in `CC_0198`.
- **His hair is clipped flat by the top edge.** Row 0 is 36%, 91% and 35% opaque across the crown.
  No crop recovers that.

🟢 The Girvan white-matte test still worked and still mattered: the rim measures **86.5 against
132.7** inside, so it is straight alpha with no matte baked in. That part was sound — it was the
other two readings that disqualified it.

### 🔴 BOTH HEAD-TOP DETECTORS FAILED AGAIN, ON NEW GROUND

Batch 7 recorded that neither detector is right everywhere. Batch 9 is the third confirmation, with
two failures neither had shown before:

- The **background-departure column scan** put Brignano's head top **229 px too high**: the gilt
  **eagle finial on the flagpole directly above his head** sits inside the face-box columns and
  departs from the wood panelling exactly as a head does. It put Mota's **193 px too high** on the
  painted mural shapes.
- **GrabCut returned 0** on both Becerra and Jurado — it absorbed the plain studio backdrop and the
  bokeh mural into the foreground.

▶ **The head top for all four was read off the photograph at 4× with labelled rows**, and that is
the only method that has worked on every image in this programme. The face-box centre and eye
midpoint agreed on all four subjects, so the crops are centred on those.

### 🟢 THE GATE WAS PROVED BY WATCHING IT FAIL, FOUR WAYS

Before `CC_0210` was applied, four tampered copies were dry-run against production — a wrong name on
the Becerra row, Brignano's origin pointed inside our own bucket, Mota's origin replaced with a
Facebook URL *still ending `.jpg`* (so only the social-media guard could catch it), and Jurado's
licence left as the `cc_by_sa_4.0` claim the migration exists to retract. **Each raised on the guard
it targeted.** The run harness also asserts the before/after snapshot returns exactly 4 rows — a
snapshot that returns none is blind, not passing.

### ▶ FOUND ON THE WAY: 48 PHOTO OBJECTS ARE NOT NAMED AFTER THEIR POLITICIAN

Rows 5 and 6 (Bass, Monica Rodriguez) were listed here as LA bookkeeping. They are not an LA
problem. Measured across every row whose `photo_custom_url` points at `politician_photos/…headshot.jpg`:

| Shape | Rows | Collides? |
|---|---|---|
| Named after the politician | 7,951 | — |
| Truncated 8-hex stem | **37** | none — no two politicians share a prefix |
| Foreign UUID owned by nobody | **3** | none |
| Foreign UUID that **is another politician** | **8** | **yes** |

🔴 **THOSE EIGHT ARE A DUPLICATE-PERSON SIGNAL, NOT A FILENAME PROBLEM.** Each one's photo filename
carries the id of a *second politician row bearing the same person's name*: **Brent Taylor, Chelsea
Byers** (against "Chelsea Lee Byers")**, Emma Sharif, Jeffrey Hulum III, Kelly Smith, London Lamar,
Patricia D. Jehlen, Vincent Dixie.** The likely history is that a photo was imported against one row
and the scalar later repointed from another. **A filename is not proof that two rows are one person**
— `reference_person_merge_policy` and the CASCADE hazard apply before anything is merged. None was
touched here.

The 3 orphans are Bass, Benjamin T Arrington and Julie M Hays; the latter two carry synthetic ids
(`ba1e0001-2026-4000-8000-…`).

⚠ **Operator ruling 2026-10-08: close rows 5 and 6 unchanged and log the 48.** Renaming 2 of 48
objects leaves the set less consistent than it is now, and a voter sees none of it. One query
re-derives the whole table; it is in this section's history.

### Also measured, so nobody re-finds it

- **Ballotpedia serves a square original for some candidates.** Brignano's is 1024×1024, not a
  portrait — a 4:5 crop of it is bound by width, not height.
- **A framer-hosted campaign site gives up its originals** by stripping the `?width=&height=` query
  from a `framerusercontent.com/images/<id>.<ext>` URL, and its `sitemap.xml` enumerates every page.
  Brignano's other six images are all **letters**, not photographs.
- **An imgix-hosted campaign site** (`run.imgix.net/<account>/<id>/<id>.<ext>`) does the same: drop
  every query parameter, including the `rect=` crop, and the original comes back. Mota's hero is
  2304×1536 behind a square `rect=384,0,1536,1536` display crop.
- Commons has **no photograph of Samantha Mota or Houston Brignano**. It has four of Jurado and
  twelve of Becerra.


## Notes

- No flagged person carries a `photo_restriction_code`, and none has
  `photo_custom_url_manual_override = true`. Every one is free to replace.
- **Write `photo_custom_url`.** A `politician_images` row alone changes nothing a voter sees
  (`project_photo_custom_url_is_what_renders`).
- Ruled out: the name mojibake I first saw on my contact sheet (`AngÃ©lica MarÃ­a DueÃ±as`) is
  my own sheet's encoding. The database is clean — `full_name LIKE '%Ã%'` returns zero rows.

Contact sheets and measurements:
`C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts\df43942a-00b1-4202-89ed-633ac22bfd2f\scratchpad\`
