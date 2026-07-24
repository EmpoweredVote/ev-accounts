# Bend, OR — post-filing re-check + remaining stance/headshot queue

**Created:** 2026-07-24 (out of the Bend, OR deep seed — migrations 1414 + 1415)
**Date-gated:** do the ballot section on or after **2026-08-29** (Bend/Deschutes withdrawal
deadline is 2026-08-28; filing closed 2026-08-25 for non-incumbents, 2026-08-18 for elected
incumbents). The stance/headshot sections are not date-gated.
**Priority:** high for the ballot section (candidate cards go stale/wrong otherwise)

## 1. Ballot re-check (≥ 2026-08-29) — REQUIRED

The Nov 3 2026 candidate field was seeded on 2026-07-24, **before filing closed**. Re-derive
against the primary sources and reconcile `essentials.race_candidates`:

- City of Bend: https://bendoregon.gov/city-council/elections/
- Deschutes County: https://www.deschutescounty.gov/1593/November-3-2026-General-Election

Seeded field as of 2026-07-24 (all `candidate_status='active'`):

| Race | Seeded candidates |
|------|-------------------|
| Bend Mayor | Melanie Kebler (inc), Ron (Rondo) Boozell |
| Bend City Council Position 5 | Ariel Méndez (inc) — unopposed |
| Bend City Council Position 6 | Bobbi Cummiskey, Elana Reinholtz, Dan Sorrells |
| Deschutes County Commissioner Position 3 | Lauren Connally, Amy Sabbadini |
| Deschutes County Commissioner Position 5 | Rob Imhoff, Morgan Schmidt |
| Deschutes County Clerk | Steve Dennison (inc), Jonathan Curtis |
| Deschutes County Sheriff | Ty Rupert (appointed inc), James (Mac) McLaughlin |
| Deschutes County Treasurer | Robert Tintle — unopposed |
| OR State House District 53 | Emerson Levy (inc), Michael Summers |
| OR State House District 54 | Jason Kropf (inc) — unopposed |

Specific things to confirm:

1. **Position 6 has no incumbent on purpose.** Councilor Mike Riley (`external_id -4105807`)
   announced he will not seek re-election (The Bulletin, 2026-06-19). If he refiled after
   2026-07-24, add him with `is_incumbent = true`. A migration-1415 gate asserts zero incumbent
   candidates in that race — update the gate if this changes.
2. Any **late filers** in the three unopposed races (Méndez P5, Tintle Treasurer, Kropf HD 54).
3. Any **withdrawals** by 2026-08-28 → set `candidate_status` rather than deleting rows.
4. HD 53/54: confirm no minor-party or independent nominees were certified after 2026-07-24
   (source used: Ballotpedia district pages).

## 2. January 2027 officeholder turnover (≥ 2027-01-04)

Deschutes County seats decided in the **May 19 2026** primary are NOT seeded as officeholders
(nobody holds them until January 2027). Migration 1415 created two vacant office rows for
Commissioner Positions 4 and 5. At swearing-in:

- **Commissioner Position 1** → Jamie Collins (won outright in May with 55%, defeating incumbent
  Tony DeBone 38%). Retire DeBone (`-4101701`), seat Collins.
- **Commissioner Position 4** (new 2-year seat) → winner of Rick Russell vs Chet Wamboldt.
- **Commissioner Position 5** (new 2-year seat) → winner of the November Imhoff/Schmidt runoff.
- **Assessor** → winner of Zachary J Hastings vs Tana West; retire Scot Langton (`-4101712`),
  who is retiring at the end of his term.
- Board chamber `official_count` is already 5; re-check `is_vacant` flags after seating.

## 3. Headshot pins (13 outstanding)

25 of 38 imported on 2026-07-24 (`data/stance-research/bend-or/_review.json`,
contact sheet at `data/stance-research/bend-or/headshots/_contact_sheet.jpg`). Outstanding:

**Sitting officials (2)**
- **Bill Kuhn**, County Treasurer (`-4101713`) — no portrait on any county page; Treasury page
  names no one (his name appears only in the "Investment Portfolio May 2026" PDF signature line).
  2022 campaign domain `billkuhn4treasurer.com` no longer resolves.
- **Ty Rupert**, County Sheriff (`-4101714`) — sheriff.deschutes.org has no portrait; the image
  next to his name on `/administration/` is a photo of the **Sheriff's Office building** (checked
  visually and rejected). Try press photos from his 2025-07-29 appointment coverage (OPB, KLCC,
  KTVZ, Central Oregon Daily) — `press_use`, same basis as the Springfield MO council photos.

**2026 candidates (11)** — Boozell, Cummiskey, Reinholtz, Sorrells, Connally, Sabbadini,
Schmidt, Curtis, McLaughlin, Tintle, Summers.

Search trail already burned (do not repeat):
- No site resolves for: `dansorrells.com`, `sorrellsforbend.com`, `danforbend.com`,
  `jonathancurtis.org`, `curtisforclerk.com`, `tintlefortreasurer.com`, `summersfororegon.com`,
  `michaelsummersoregon.com`, `billkuhn4treasurer.com`.
- Sites that DO resolve but whose images need a JS-rendering pass (Wix/Squarespace/GoDaddy lazy
  loaders defeat curl): `connally4deschutes.com` (og:image is a blank Wix placeholder),
  `vote4sabbadini.com`, `morganlovesoregon.com` (og:image is a logo), `bobbiforbend.com`
  (**trap:** the only real photo on the page is an endorser — **Jamie Collins** — not
  Cummiskey), `elanaforbend.com` (og-image.png is a social card), `rondo2026.org` (no og:image),
  `macforsheriff.com` / `mclaughlinforsheriff.com` (og:image is a theme asset).
- **Rejected source:** the Deschutes County May 2026 voters' pamphlet
  (`DocumentCenter/View/5835`) does contain statement photos for Connally (p21), Sabbadini (p22),
  Boozell + Imhoff (p24) and Schmidt (p25), but they are **grayscale ~219×256** — below the
  quality bar that rejected Springfield's 198px thumbnails. The **November** pamphlet (published
  after the Sept measure deadline) will add Curtis, McLaughlin and Tintle but will be grayscale
  too. Use only as a last resort.

## 4. Stance queue (28 people outstanding)

Wave 1 (2026-07-24) pushed **23 evidence-only stances + 23 verbatim quotes** across 7 people,
0 unsourced: Kebler 3, Reinholtz 3, Cummiskey 3, Connally 4, Sabbadini 4, Imhoff 2, Schmidt 4.
Payload + push script: `data/stance-research/bend-or/wave1-stances.json`, `_push.ts`.

Still to research, in priority order:

1. **On the Nov ballot, no stances yet (3):** Ariel Méndez (P5, has a substantial council voting
   record — worth a deep pass), Dan Sorrells, Ron (Rondo) Boozell.
2. **Sitting Bend councilors (4):** Megan Norris, Gina Franzosa, Megan Perkins, Steve Platt —
   council votes on growth/housing/transportation are the evidence, not campaign copy.
3. **Kebler deepening:** only 3 stances from her campaign page; as sitting mayor her council
   record should support several more (homelessness response and public safety were honest-skipped
   because the campaign-page wording was too vague to place on the scale).
4. **Sitting commissioners (3):** Chang, DeBone, Adair — BOCC minutes and Bulletin/Source
   coverage. Adair note: she is also the OR-05 Republican nominee, so her federal-topic record
   may be researchable at the same time.
5. **Sheriff race (2):** Rupert and McLaughlin — `public-safety-approach`, `jail-capacity`,
   `local-immigration` are the applicable topics.
6. **Bend-La Pine School Board (7)** — `school-vouchers` and school-adjacent topics only.
7. **BPRD board (5)** — expect thin; `local-environment` / `growth-and-development` at most.
8. **HD 53/54 (3):** Levy, Kropf, Summers — these are STATE legislators with zero stances today
   (so is SD-27's Broadman); they belong to a state-leg wave rather than the Bend local wave.

**Honest-skip by design (do not chase):** County Clerk, Assessor and Treasurer are ministerial
offices — same treatment as the Falls Church constitutional officers. Only chase the Clerk
candidates if election-administration topics get added to the compass.

Sources that worked for Bend: candidate campaign sites via a markdown reader (verbatim quotes),
bendbulletin.com, bendsource.com, KTVZ, OPB/KLCC, official city/county/district pages.
Sources that fought back: `bendoregon.gov` returns 403 to non-browser requests (HTML *and*
images — city portraits had to be pulled through a browser context); Wix/Squarespace candidate
sites need JS rendering.
