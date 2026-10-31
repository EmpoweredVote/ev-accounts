# Jackson portraits — prepared, awaiting approval

**Status 2026-10-31: eight portraits prepared and presented on a contact sheet. NOTHING IS
UPLOADED AND NOTHING IS BOUND.** All eight Jackson officeholders still render blank in production.

Contact sheet: <https://claude.ai/artifact/K7Ld2V74URvqZNZSzEUd7Z> (private to the operator).

## The sources, and why these and not the ones on the page

🔴 **THE CITY'S COUNCIL PAGES SHOW BACKGROUND-REMOVED CUT-OUTS** (`*-remove.bg_.png`, 552×599).
🟢 **The original sitting is still in the media library** — seven portraits at **720×780**, all
uploaded **2025-11-21**, one consistent official set. Those are what `jx-manifest.json` points at.
This is MS-5's Minnesota House lesson, which that wave said should be the **first** thing tried.

🔴 **THE MAYOR'S OBVIOUS FILE IS A LOCATION SHOT.** `John-A-Horhn.jpeg` (1140×1600) and two
siblings are one full-length sitting at the City Hall historical marker, with him small in frame.
His own page uses **`Jhorhn.jpg`** (685×603), a studio head-and-shoulders — that is the one used,
and it is the only source smaller than 600×750, so the only one enlarged (×1.245).

🔴 **WARD 1'S FILE IS NAMED `Ashby-M-Forte.jpg` — THE WRONG SURNAME.** Binding is by **seat**: the
image is whatever that ward's page shows. Its `alt` reads "ashby foote". **Third time in this state
a Mississippi filename has lied about its subject** (Biloxi had two wrong labels on one man).

## What was measured

`scripts/jackson-process-portraits.py` writes `jx-processed.json` and the 600×750 q90 JPEGs.

- **A face was detected in all eight.** 🔴 Nothing else this repo runs asks whether a headshot
  contains a face — a seal, a map, a blank or a torso all pass — so detection is run here and a
  miss is reported, not silently centre-cropped. **Control: the detector is run on flat grey first
  and must find nothing**, so it can report absence.
- **None is monochrome.** Per-pixel channel spread 25.8 … 54.1, well clear of the greyscale floor.
- **Crops are placed from the measured face box**, with headroom of 0.6 × face height, not centred.
- **Only the mayor is enlarged.** The seven council portraits are downscaled (×0.962).

⚠ **A FACE-PROPORTIONAL ZOOM WAS TRIED AND REVERTED, AND THE COMMENT IN THE SCRIPT SAYS SO.**
Normalising every face to 0.40 of the crop width pushed **five of eight into upscaling** (up to
×1.31) to buy a consistency the city's own set already had — its seven portraits already sit at
face/width 0.36–0.45 as published. The largest crop each source allows is taken instead.

## When approval arrives

1. Re-run `scripts/jackson-process-portraits.py` (sources are public URLs; `jx-manifest.json` has
   every one, so the set is reproducible without the scratchpad).
2. Upload to Supabase Storage. 🔴 **Send BOTH `apikey` AND `Authorization`** — a lone Bearer is
   refused as HTTP 400 with a body claiming 403 "Invalid Compact JWS", which reads like a missing
   object. Verify by **byte comparison**, not HTTP 200: a missing object in this bucket answers
   400, not 404. Include a never-uploaded key as the control. `scripts/ms5-upload-headshots.py` is
   the worked example.
3. Write the binding migration (a fresh `steward slot CC`). 🔴🔴 **WRITE BOTH
   `politicians.photo_custom_url` AND the `type='default'` `politician_images` row** — the grid
   reads `images[]` first and the backend the scalar, and a `politician_images` row alone changes
   nothing a voter sees.
4. 🔴 **A correct API response is not evidence it landed — read the rendered `<img>`.**
