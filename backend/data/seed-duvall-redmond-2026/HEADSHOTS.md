# Duvall + Redmond — headshot wave

Compiled 2026-10-06. **APPLIED** as `CC_0192` on 2026-10-06, approved by Cantrell.

**13 of 16 published. 3 left blank.**

Pipeline: cropped to 4:5 first and never stretched, resized 600x750 Lanczos q90, uploaded to
`politician_photos/{politician_id}-headshot.jpg` with `x-upsert`, then fetched back and confirmed
serving HTTP 200 `image/jpeg` against a control (an absent object returns 400). The uploader was
`backend/scripts/_tmp-wa-duvall-redmond-headshots.py`, which is **gitignored** like every other
`_tmp-` script; the pipeline it ran is documented here and in `CC_0192`.

⚠ **Six frames were cropped before resizing.** `PoliticianCard` renders a 4:5 box with
`object-cover`, so a circular mask or a flat border shows in the corners. Forsythe, Stuart,
Kritzer, Soni and Nuevacamina were a circle on a flat ground; Birney had a light border. The crop
takes the largest 4:5 rectangle that fits wholly inside the circle — for a 500x500 source that is
313x391, which keeps more height than an inscribed square would.

## Duvall — 6 of 8

`headshots/contact-sheet-duvall.png`. Each frame is from that member's own page on `duvallwa.gov`
and carries the page's own `alt="Profile picture of <NAME>"`, a second factor independent of where
the image sits.

| Seat | Member | documentID | Size | Note |
|---|---|---|---|---|
| Mayor | Amy McHenry | 14439 | 2048x1638 | colour |
| Pos 1 | Adam Olen | 13383 | 2600x1734 | colour |
| Pos 2 | Linda Conway | — | — | **blank** — appointed 2026-09-01, no member page yet |
| Pos 3 | Sara Taylor | — | — | **blank** — appointed 2026-08-18, no member page yet |
| Pos 4 | Ronn Mercer | 14773 | 2048x1638 | colour |
| Pos 5 | Mike Supple | 8889 | **165x231** | colour; the city publishes nothing larger |
| Pos 6 | Paul Wiggins | 14441 | 2048x1638 | colour |
| Pos 7 | Jennifer Hernandez | 14626 | 2048x1638 | colour |

## Redmond — 7 of 8

`headshots/contact-sheet-redmond.png`. Councilmembers from `redmond.gov/189/City-Council`, the
Mayor from `redmond.gov/284/Office-of-the-Mayor`. Every frame carries an `alt` naming the person.

| Seat | Member | documentID | Size | Note |
|---|---|---|---|---|
| Mayor | Angela Birney | 157 | 800x800 | colour |
| Pos 1 | Sayna Parsi | 40581 | 800x800 | colour |
| Pos 2 | Vivek Prakriya | 40270 | 1864x1864 | **REJECTED — black and white** |
| Pos 3 | Jessica Forsythe | 21593 | 500x500 | colour |
| Pos 4 | Melissa Stuart | 21592 | 500x500 | colour |
| Pos 5 | Vanessa Kritzer | 11885 | 500x500 | colour |
| Pos 6 | Menka Soni | 40269 | 1650x1650 | colour |
| Pos 7 | Angie Nuevacamina | 30947 | 500x500 | colour |

## 🔴 Four detector failures, every one caught by looking

**1. `redmond.gov/189` DOES publish portraits — they are BELOW THE FOLD.** An earlier pass of this
wave concluded Redmond published none. That was wrong. The portraits load near the bottom of
`/189`; a text dump of the page truncates before reaching them, and the member staff-directory
pages (`/m/directory/employee?eid=`) genuinely have none, which made the wrong conclusion look
confirmed. **Scroll the page, in a real browser, before concluding an image is absent.**

**2. The control that let that happen passed for the wrong reason.** "The member's surname appears
in the page HTML" returned OK for all eight Redmond members while not one of those pages held a
portrait. 🔴 **A portrait control must require an image whose `alt` or filename names THAT member**,
never merely the presence of a name somewhere in the markup.

**3. A guessed `documentID` served a nine-person group photo** under
`alt="Profile picture of Amy McHenry"`. The id had been incremented from Mercer's rather than read
off McHenry's page; the real one is 14439. **Read the id off the page; never increment one.**

**4. 🔴🔴 A SATURATION THRESHOLD PASSES A TINTED BLACK-AND-WHITE.** Vivek Prakriya's official
portrait (`headshots/REJECTED-prakriya-monochrome.jpg`) is black and white with a cool tint, so its
mean R-G-B spread measured **15.0** and cleared a threshold of 6. Two further attempts also failed:
a hue-variance test over the face crop flagged six colour portraits as mono, because a face crop is
mostly skin and skin is one hue.

The test that works is **chromaticity constancy over the whole frame** — normalise each pixel by
its own R+G+B and take the standard deviation. A greyscale or duotone image sits at one point;
a colour photograph spreads out. Measured here, with controls that fired in both directions:

```
known greyscale (pamphlet)   0.0     <- control, must be low
known colour (city portrait) 87.6    <- control, must be high
Vivek Prakriya                6.4    <- MONOCHROME
every other frame        47.7-164.1  <- colour
```

## Sources that do NOT work, recorded so nobody retries them

- **The King County voters' pamphlet is printed monochrome.** Every extracted frame measures 0.0.
  Barred entirely.
- **Pamphlet frames cannot be used to identify people either.** Nearest-name matching on a
  two-column pamphlet page labelled two men as "Angela Birney" and "Angie Nuevacamina", both of
  whom are women. Kept as `headshots/REJECTED-pamphlet-misattribution.png` — evidence of the
  failure mode, not data.
- **Redmond's press distribution** (Dropbox, linked from the 2026-01-21 release) holds only group
  and event shots: `headshots/redmond-press-full-council.jpg` is a clean 5712x4284 frame of all
  seven councilmembers but is unlabelled. Not needed now that `/189` is known to carry portraits.
