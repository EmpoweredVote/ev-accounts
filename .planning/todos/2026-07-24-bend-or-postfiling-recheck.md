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

## 4. Stance queue — Bend CITY cohort is DONE; 17 people outstanding

**Totals now live: 60 stances / 52 quotes across 14 people, 0 unsourced.**

Bend-city cohort **complete** (waves 2-3, 2026-07-24, three `politician-stance-researcher` agents
capped at 3 concurrent): Kebler 10, Perkins 6, Méndez 5, Cummiskey 5, Reinholtz 5, Franzosa 4,
Riley 4, Platt 3, Norris 2, Boozell 2, **Sorrells 0**. Plus the county candidates from wave 1:
Connally 4, Sabbadini 4, Schmidt 4, Imhoff 2. Payloads: `wave1-stances.json`,
`wave2-stances.json`, `wave3-*.json`; push with `_push.ts <file>`.

### Validation rejections — do NOT silently re-add these
Each agent output was spot-checked against its sources. Five rows were rejected or amended:
1. **Platt homelessness-response** — quote was The Bulletin's INDIRECT speech ("said he would work
   to create more outdoor shelters"). Stance kept, quote demoted to reasoning.
2. **Cummiskey economic-development=1** — DROPPED. Her issues page shows infrastructure-as-tool
   plus small-business support but takes no position on corporate incentives; chairs 1 AND 2 both
   hinge on an anti-subsidy stance she never states.
3. **Boozell climate-change=2** — DROPPED. Quote is genuine (the Bulletin literally prints "Be a
   net-zero -energy city. Create green jobs.") but it is a 2020 bullet with no timeline, and
   chairs 2 vs 3 cannot be discriminated from it.
4. **Riley local-environment=3** and **Kebler public-safety-approach=3** — DROPPED as institutional
   attribution: a tree code that took effect during his term, and subcommittee minutes of the
   POLICE CHIEF briefing council. Neither is the official's own stated position.
5. **Kebler growth-and-development** — agent proposed an override 3→4 on her Dec-2024 vote to
   fast-track the Caldera Ranch UGB expansion ("I don't think we can wait"). **Held at 3**: chair
   4's defining content (reduce fees, recruit development to grow the tax base) is absent and her
   motive is housing need. A case for 4 is defensible on the streamlining mechanism alone — flagged
   in the row's reasoning if a reviewer wants to flip it.
   Also **Riley homelessness 4→3**, because the same article has him pairing the enforcement vote
   with "incredible progress" on shelter beds, and Kebler scores 3 on that identical vote.

### HIGH-VALUE UNMINED SOURCE (found late, costs nothing to use)
The **Deschutes County May 2026 voters' pamphlet** (`DocumentCenter/View/5835`, already downloaded
to `data/stance-research/bend-or/headshots/dc-may2026-pamphlet.pdf`) carries candidates' own
words, officially, for the current cycle. Extract with `pdftotext -layout -f <pg> -l <pg>`.
Boozell's ICE quote came from p24. **Imhoff's statement on the same page contains material that
would strengthen rows already published for him:**
- `"Enforce a 6 mile no-camping zone around UGBs and move people from streets to stability with
  clear expectations. Treatment must demand recovery and services must deliver results."`
  → confirms his homelessness-response=4 far better than the campaign-site wording now cited.
- `"A 50-year road plan, including a Hwy 97 bypass from Redmond to Sunriver."`
  → a clear road-capacity position on `transportation-priorities`, currently BLANK for him.
- `"need more homes and fewer lawsuits. Endless appeals delay housing and raise costs."`
  → the housing mechanism whose absence caused housing to be skipped for him.
Connally (p21), Sabbadini (p22) and Schmidt (p25) have statements on the same PDF — mine those
before doing any new web research on the county candidates.

### Still to research, in priority order
1. **Dan Sorrells (Bend P6)** — 0 stances and the only empty compass on the Bend ballot. His sole
   campaign presence is Instagram `@citycouncildan`; no site, no news profile, no questionnaire.
   The **city-hosted candidate forum is mid-September 2026** — that is the unlock. Re-run then.
2. **Sitting commissioners (3):** Chang, DeBone, Adair — BOCC minutes plus Bulletin/Source
   coverage. Adair is also the OR-05 Republican nominee, so federal topics are researchable too.
3. **Sheriff race (2):** Rupert and McLaughlin — `public-safety-approach`, `jail-capacity`,
   `local-immigration`. The November county pamphlet (not yet published) will carry both.
4. **County candidate deepening (4):** Connally, Sabbadini, Imhoff, Schmidt — start with the
   pamphlet above.
5. **Bend-La Pine School Board (7)** — `school-vouchers` and school-adjacent topics only.
6. **BPRD board (5)** — expect thin; `local-environment` / `growth-and-development` at most.
   Riley's KPOV "The Point" podcast episode on the tree code is an unmined source (audio).
7. **HD 53/54 (3):** Levy, Kropf, Summers — STATE legislators with zero stances (so is SD-27's
   Broadman); belongs to a state-leg wave, not the Bend local wave.

### Agent-prompt intel that worked (reuse verbatim)
Embed the exact 1-5 texts for all 14 local topics; state that INDIRECT speech is not a quote and
that an empty `quote_text` with a real source is acceptable; tell agents `bendbulletin.com/?s=` is
the best search, `r.jina.ai` proxies past the bendoregon.gov 403, Playwright reaches
web.archive.org and citizenportal.ai, and `lite.duckduckgo.com/lite/` via r.jina.ai survives the
DuckDuckGo CAPTCHA wall. ktvz.com's own `?s=` 404s; centraloregondaily.com rate-limits (429);
vote411.org 403s.

**Honest-skip by design (do not chase):** County Clerk, Assessor and Treasurer are ministerial
offices — same treatment as the Falls Church constitutional officers. Only chase the Clerk
candidates if election-administration topics get added to the compass.

Sources that worked for Bend: candidate campaign sites via a markdown reader (verbatim quotes),
bendbulletin.com, bendsource.com, KTVZ, OPB/KLCC, official city/county/district pages.
Sources that fought back: `bendoregon.gov` returns 403 to non-browser requests (HTML *and*
images — city portraits had to be pulled through a browser context); Wix/Squarespace candidate
sites need JS rendering.
