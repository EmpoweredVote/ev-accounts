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

## 4. Stance queue — Bend CITY + county-pamphlet cohorts DONE; 13 people outstanding

**Totals now live: 76 stances / 65 quotes across 17 people, 0 unsourced.**

**Wave 5 (2026-07-24): Chang 4, Adair 5 — both sitting commissioners now covered.**
Chang: growth 2, housing 3, local-environment 2 (his own guest column), homelessness 3 (his Oct
2024 BOCC vote for the Juniper Ridge safe-stay plan). Adair, labelled county vs congressional:
growth 4 + public-safety 4 (county), taxes 4 + deportation 2 + voting-rights 3 (OR-05 campaign).
**Adair's federal record is genuinely thin** — nothing usable found on tariffs, vouchers, Social
Security structure, fossil fuels, or immigration-as-distinct-from-deportation. Two findings worth
keeping: her voter-guide answers put her at chair 2 on deportation (violent criminals only) and she
says "I strongly support mail voting", neither of which a party prior would have predicted.
9 of 16 wave-5 rows were rejected in validation — see below.

Bend-city cohort **complete** (waves 2-3, 2026-07-24, three `politician-stance-researcher` agents
capped at 3 concurrent): Kebler 10, Perkins 6, Méndez 5, Cummiskey 5, Reinholtz 5, Franzosa 4,
Riley 4, Platt 3, Norris 2, Boozell 2, **Sorrells 0**. County side after the wave-4 pamphlet pass:
Schmidt 5, Connally 4, DeBone 4, Imhoff 4, Sabbadini 4, **Chang 0, Adair 0**. Payloads:
`wave1-stances.json`, `wave2-stances.json`, `wave3-*.json`, `wave4-county-pamphlet.json`;
push any of them with `_push.ts <file>`.

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

### ✅ MINED 2026-07-24 — county pamphlet wave (`wave4-county-pamphlet.json`, 13 rows)
The pamphlet described below **has now been mined** for every commissioner-race candidate in it.
Column-crop method (the two-column layout otherwise cross-attributes text between rival
candidates — a real wrong-attribution risk): pages are **540×774pt**, so
`pdftotext -layout -f <pg> -l <pg> -x 0 -W 270 -H 774` for the LEFT candidate and `-x 270 -W 270`
for the RIGHT one. Page/column map: p18 Collins|**DeBone**, p21 **Connally**|Facey,
p22 Page|**Sabbadini**, p24 Boozell|**Imhoff**, p25 Letz|**Schmidt**.

Results: **DeBone 0→4** (a sitting commissioner who had no stances at all), Imhoff **2→4**
(gained transportation=4 from his Hwy 97 bypass plan and housing=4 from "fewer lawsuits"),
Schmidt 4→5, Connally **public-safety REVISED 4→3** (his pamphlet pairs "fully funded" law
enforcement with early mental-health investment — chair 3 — where the campaign-site wording had
read as capacity-building), Sabbadini 4 rows unchanged but re-cited to the official primary
source. Deliberately skipped: Imhoff `economic-development` (his 75%-local-contracts and sports-
complex ideas never address corporate incentives, so chairs 1 and 2 are indistinguishable — the
same gate that dropped Cummiskey's) and Imhoff `growth-and-development` (his 50-year road plan
argues for chair 3 while "fewer lawsuits" argues for chair 4).

**Chang and Adair still have zero stances** and are NOT in this pamphlet — Chang was not on the
2026 ballot and Adair ran for Congress instead. They need BOCC minutes / news coverage.
The **November** county pamphlet (published after the September measure deadline) will be the
equivalent primary source for the **Sheriff (Rupert, McLaughlin), Clerk and Treasurer** races.

### ~~HIGH-VALUE UNMINED SOURCE~~ (now mined — kept for the method and the page map)
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
0. **Adair's federal topics** — she is on the Bend ballot for OR-05 but only 3 federal topics are
   documented (taxes, deportation, voting-rights). Nothing found on tariffs, school-vouchers,
   Social Security structure, fossil-fuels, or immigration. **Do NOT fill these from party priors.**
   Her abortion position is genuinely undocumented federally — a 2022 county employee health-plan
   coverage vote exists but measures a different axis and was rejected. Watch for a general-election
   Oregon Capital Chronicle voter guide and any OR-05 debate.
1. **Dan Sorrells (Bend P6)** — 0 stances and the only empty compass on the Bend ballot. His sole
   campaign presence is Instagram `@citycouncildan`; no site, no news profile, no questionnaire.
   The **city-hosted candidate forum is mid-September 2026** — that is the unlock. Re-run then.
2. **Sheriff race (2):** Rupert and McLaughlin — `public-safety-approach`, `jail-capacity`,
   `local-immigration`. The November county pamphlet (not yet published) will carry both.
3. **Bend-La Pine School Board (7)** — `school-vouchers` and school-adjacent topics only.
4. **BPRD board (5)** — expect thin; `local-environment` / `growth-and-development` at most.
   Riley's KPOV "The Point" podcast episode on the tree code is an unmined source (audio).
5. **HD 53/54 (3):** Levy, Kropf, Summers — STATE legislators with zero stances (so is SD-27's
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
