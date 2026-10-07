# Los Angeles headshot replenish list — audited 2026-10-07

Scope: everybody the Los Angeles browse page renders.

    https://essentials.empowered.vote/results?browse_government_list=0644000&browse_label=Los+Angeles&browse_state=CA&view=elections

Method: pulled both payloads the page fetches (`browse/by-government-list`,
`browse/elections-by-government-list`), downloaded every rendering image **at its origin**,
measured it there (never the `<img>` on the page — see `project_la_county_headshot_audit`),
then looked at all 139 on labelled contact sheets.

**612 people. 139 render a photo, 473 are blank. 120 of the 139 pass. 19 are flagged below.**

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
| 3 | **Tim McOsker** | CD 15 | Street scene. Head ≈15% of frame, cars and trees behind him. | ❌ **No.** The city's own file (`/meet-tim`) is this same image, and its ORIGIN is only **400×267**. Real ceiling at lacity.gov. Lead: filename is Flickr id `51857445559`, so a larger original may exist on Flickr. |
| 4 | Ysabel J. Jurado | CD 14 | Loud mural background. Head size is acceptable. **Borderline — low priority.** The city serves the same frame; its alt literally reads "Photo of Councilmember Jurado in front of a mural". | — |

### Bookkeeping only (image is correct, the record is untidy)

| # | Person | Problem |
|---|--------|---------|
| 5 | Karen Ruth Bass | Stored file is `2f96d5e2-8284-490d-8ba1-d204b649f45a-headshot.jpg`. That UUID **matches no politician row.** Her id is `21c9e711-…`. Image is correct. |
| 6 | Monica Rodriguez | Stored at a **truncated stem** — `7c0d3bdd-headshot.jpg`, 8 hex characters, not the full id. Image is correct. (Estuardo Mazariegos, `92876cb7-headshot.jpg`, is the same shape.) |

---

## B. City of Los Angeles — 2026 candidates

| # | Person | Race | Defect |
|---|--------|------|--------|
| 7 | **Barri Worth Girvan** | CD 3 | **White rectangle burned into the top-right corner** — a compositing artifact, visible to a voter. |
| 8 | **John McKinney** | City Attorney | Full-length walking shot. Head ≈12% of frame. |
| 9 | ~~Timothy Gaspar~~ ✅ **DONE 2026-10-07** (`CC_0197`) | CD 3 | Half-body, head small, busy signage behind. **Borderline.** |

---

## C. Los Angeles County

| # | Person | Seat | Defect |
|---|--------|------|--------|
| 10 | **Robert S. Draper** | LA Superior Court judge | **Worst on the page.** Candid snapshot in a courthouse lobby. **672×446 landscape**, subject off-centre and at an angle, flags and furniture behind, poor light. |
| 11 | ~~**Nathan Hochman**~~ ✅ **DONE 2026-10-07** (`CC_0197`) | District Attorney | Full-body standing portrait between flags. Head ≈10% of frame. |
| 12 | ~~Patrick Connolly~~ ✅ **DONE 2026-10-07** (`CC_0197`) | LA Superior Court judge | 588×554, three-quarter body, bokeh city background. **Borderline — crop would fix it.** |

---

## D. Los Angeles school and college boards

| # | Person | Seat | Defect |
|---|--------|------|--------|
| 13 | **Scott Schmerelson** | LAUSD District 3 | Heavy blur — an upscale of a small original. Top of head clipped. |
| 14 | **Sara Hernandez** | LACCD Seat 4 | **200×300** — under the floor. |

---

## E. Candidates in districts that cover Los Angeles

| # | Person | Race | Defect |
|---|--------|------|--------|
| 15 | **Cristian Morales** | CA-43 | Heavy blur — an upscale. Head clipped at the top. |
| 16 | **Angela Gonzales-Torres** | CA-34 | **200×300** — under the floor. |
| 17 | **Houston Brignano** | CA-36 | Full-body standing shot. Head ≈10% of frame. |
| 18 | Xavier Becerra | Governor | Candid at a campaign event. A microphone intrudes bottom-right, a blurred object left. |
| 19 | Samantha Mota | CA-37 | Casual shot against a mural, arm raised. Not a portrait. |

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

## Notes

- No flagged person carries a `photo_restriction_code`, and none has
  `photo_custom_url_manual_override = true`. Every one is free to replace.
- **Write `photo_custom_url`.** A `politician_images` row alone changes nothing a voter sees
  (`project_photo_custom_url_is_what_renders`).
- Ruled out: the name mojibake I first saw on my contact sheet (`AngÃ©lica MarÃ­a DueÃ±as`) is
  my own sheet's encoding. The database is clean — `full_name LIKE '%Ã%'` returns zero rows.

Contact sheets and measurements:
`C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts\df43942a-00b1-4202-89ed-633ac22bfd2f\scratchpad\`
