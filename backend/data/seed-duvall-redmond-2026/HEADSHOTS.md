# Duvall + Redmond — headshot wave

Compiled 2026-10-06. Nothing is published yet; `photo_custom_url` is unwritten for all 16.

## Duvall — 6 of 8, ready for approval

`headshots/contact-sheet-duvall.png`. Every frame comes from that member's own page on
`duvallwa.gov` and carries the page's own `alt="Profile picture of <NAME>"`, which is a second
factor independent of where the image sits.

| Seat | Member | Image | Size | Note |
|---|---|---|---|---|
| Mayor | Amy McHenry | `documentID=14439` | 2048x1638 | colour |
| Pos 1 | Adam Olen | `documentID=13383` | 2600x1734 | colour |
| Pos 4 | Ronn Mercer | `documentID=14773` | 2048x1638 | colour |
| Pos 5 | Mike Supple | `documentID=8889` | **165x231** | colour, but small — the city publishes nothing larger |
| Pos 6 | Paul Wiggins | `documentID=14441` | 2048x1638 | colour |
| Pos 7 | Jennifer Hernandez | `documentID=14626` | 2048x1638 | colour |

**Positions 2 (Linda Conway) and 3 (Sara Taylor) have no portrait.** Neither has a member page yet;
both were appointed in August and September 2026. They stay blank.

⚠ **A guessed document id produced a nine-person group photo under `alt="Profile picture of Amy
McHenry"`.** I had incremented Mercer's id rather than reading McHenry's page. The alt was right
about the intent and wrong about the file. Only looking at the frame caught it. **Read the id off
the page; never increment one.**

## Redmond — 0 of 8. There is no usable source.

Three sources were tried and all three fail, for different reasons:

1. **The city publishes no member portraits.** Checked in the rendered DOM with Playwright, not
   just the raw HTML: `redmond.gov/m/directory/employee?eid=<n>` serves the member's name in the
   page title and **the same four chrome images for every member**, including one empty-alt
   banner identical across all eight. The council pages carry none either.
   🔴 My first control here — "the surname appears in the page HTML" — **passed for all eight and
   was worthless**. A control for a portrait must require an image whose alt or filename names
   *this* member.

2. **The city's press distribution has only group and event shots.** The 2026-01-21 release links
   a Dropbox folder (`Council 01-20-26`) holding `Full Council.jpg`, `Nuevacamina, Parsi,
   Stuart.jpg` and three Parsi swearing-in frames. `headshots/redmond-press-full-council.jpg` is a
   clean, well-lit 5712x4284 shot of all seven councilmembers — crops would be good quality — but
   it is **unlabelled**, and six of the seven are women of broadly similar age. This is the exact
   case a contact sheet cannot resolve by itself.

3. 🔴🔴 **The King County voters' pamphlet is MONOCHROME, and my attempt to label it failed.**
   Measured R-G-B spread of every extracted pamphlet frame is **0.00** — the pamphlet is printed
   black and white, so no-monochrome bars all of it from publication.
   Worse, the attempt to use those frames as *identification references* for the group photo
   produced demonstrably wrong pairings: see `headshots/REJECTED-pamphlet-misattribution.png`,
   where nearest-name matching labelled **a man as "Angela Birney" and another man as "Angie
   Nuevacamina"** — both are women. A two-column pamphlet layout defeats proximity matching.
   **That strip is kept as evidence of the failure mode, not as data. Do not use it.**

### What would actually work for Redmond

Identify the seven faces in the press group shot against a labelled, non-pamphlet source, then crop
each from the colour original. The city's own release names three of them in one file
(`Nuevacamina, Parsi, Stuart.jpg`), and Vivek Prakriya is the only man in the group, so four of
seven are constrained before any further work. The remaining identifications need a labelled photo
the city has not published, or a request to the city's communications office.

**Until then Redmond stays blank. A blank beats a wrong face**, and this wave produced two concrete
demonstrations of how easily the wrong face would have been published.
