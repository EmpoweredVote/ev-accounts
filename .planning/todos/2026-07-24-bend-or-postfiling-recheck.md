# Bend, OR — post-filing re-check + remaining stance/headshot queue

**Created:** 2026-07-24 (out of the Bend, OR deep seed — migrations 1414 + 1415)
**Date-gated:** do the ballot section on or after **2026-08-29** (Bend/Deschutes withdrawal
deadline is 2026-08-28; filing closed 2026-08-25 for non-incumbents, 2026-08-18 for elected
incumbents). The stance/headshot sections are not date-gated.
**Priority:** high for the ballot section (candidate cards go stale/wrong otherwise)

## 0. STATUS 2026-07-26 — the provisional field is now DISCLOSED on the site

Migration **1469** brought these rows into the `provisional_until` convention that migration
**1456** established (read 1456's header before touching this): `provisional_until` is the first
date the row can be **RE-VERIFIED**, paired with a `cull >= <date>` marker in `source`. So the
15 candidate rows across the 8 LOCAL races below carry **`2026-08-29`** — the day after the
withdrawal deadline — **not** 2026-08-28, because the field is still mutable through Aug 28.

The elections API now surfaces it per race and `ElectionsView.jsx` renders a "Candidate field not
final" note, so the site no longer presents this field as settled. 1456 had already dated ~293
rows across a dozen states and **nothing on the read path looked at any of them** — that is fixed
for all of them at once, not just Bend.

**🔴 READ THIS BEFORE DOING §1:** the note does **not** clear when 2026-08-29 passes. The read
path uses 1456's comparison — `last_verified_at IS NULL OR last_verified_at < provisional_until`
— deliberately, so a re-check that never happens cannot silently turn into a claim that the field
is final. Past its date the note switches to "past its re-verification date and may be out of
date" and the row appears in `essentials.stale_provisional_candidates`. When you finish §1:
  - bump `last_verified_at` past 2026-08-29 on every row you re-verify, **or**
  - set `provisional_until = NULL` on rows confirmed final (what migration 1457 did for its 9).
Doing neither leaves the note up; clearing the flag without re-deriving the ballot is the exact
failure this was built to prevent.

HD 53/54 were deliberately **not** flagged — all 60 Oregon House districts are equally
provisional in this window, so flagging only Bend's two would show the note to HD-53 residents
and nothing to HD-12 residents. That wants a separate Oregon-wide pass.

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

## 2b. Bend has NO city banner (found 2026-07-26)

`buildingImages.js` `CURATED_LOCAL` carries **139 curated city banners**; Bend is not one, so its
civic space renders the tier-gradient fallback. Four operator-review candidates are cropped to the
1700×540 house spec and staged (NOT uploaded, NOT certified) in the session scratchpad
`bend_banner/`, with licence + author + Commons page in `bend_banner/_meta.json`:

| Key | Subject | Licence | Author |
|-----|---------|---------|--------|
| A | Mirror Pond + Three Sisters (recommended) | CC BY-SA 3.0 | Spencer Dahl |
| B | Downtown street at golden hour, Pilot Butte on axis | CC0 | UpdateNerd |
| C | Downtown from Pilot Butte, autumn | CC0 | Roc0ast3r |
| D | City + Cascade horizon | CC0 | Roc0ast3r |

Rejected on inspection: Old Mill District (mostly sky, smokestacks not visible), Drake Park 2014
(flat grey water), `Bend, OR (DSC 0153)` (a "Wall Street Storage" sign at night), Hayden Homes
Amphitheater (too dark), `North Middle Sisters Mirror Pond` (bare-winter, peaks crop out).
On certification: `py scripts/banners/upload_banner.py --file <final>.jpg --dest cities/bend.jpg`
then add `bend: { state: 'OR', src: '…/cities/bend.jpg' }` to `CURATED_LOCAL` + the attribution
comment block.

## 3. Headshot pins — 7 of 13 CLEARED 2026-07-26 (migrations 1477 + 1478), 6 remain

**32 of 38 now imported.** Wave 2 (mig **1477**) cleared **Rupert, Connally, Sabbadini, Cummiskey,
Reinholtz, Summers**; mig **1478** added **McLaughlin**. All 600×750, `press_use`, verified serving
and reaching the live elections API. Review artifact:
`claude.ai/code/artifact/d3dc02b2-de55-4696-98d5-3622d3676de9`.

**McLaughlin's came from the STANCE research, not the headshot sweep** — his KTVZ press release
links **`votemacforsheriff.com`**, whose hero is a 7008×4672 professional portrait. That domain is
in neither wave-1 list. Cheapest way to find a candidate's real site: read their own press release.

**🔑 WHY THE "DEAD" SITES WERE NOT DEAD — reuse this before declaring any campaign site a loss.**
The wave-1 trail below recorded most of these as placeholder/logo/theme-asset dead ends. That was a
*rendering* artifact:
1. **Scroll the page** (`window.scrollTo` in steps + a short wait) — lazy-loaded `<img>` elements do
   not exist in the DOM until then, so a bare fetch or a single snapshot sees nothing.
2. **Strip the CDN render directive to get the full-resolution original:**
   | Platform | URL shape | Original |
   |---|---|---|
   | Wix | `static.wixstatic.com/media/<id>~mv2.<ext>/v1/fill\|crop/…` | cut at `/v1/` |
   | GoDaddy | `img1.wsimg.com/isteam/ip/<id>/<file>/:/rs=…` | cut at `/:/` |
   | Squarespace | `…/<file>?format=750w` | `?format=2500w` |
   | Next.js | `/_next/image?url=%2Fimages%2F…&w=640` | fetch `/images/…` raw |
   Yields: Connally's "blank Wix placeholder" = a 512² studio headshot; Reinholtz 464px → 1350×1800;
   Summers → 2705×3500.
3. **A transparent PNG flattens to BLACK** if you `convert('RGB')` it — composite onto a neutral
   ground first (Summers, and the county's own 428px Rupert file).

**🔴 CORRECTIONS to the wave-1 trail — it is wrong in two places:**
- **`macforsheriff.com` is NOT McLaughlin's site any more.** It redirects to `/wyatt-mcintrye` and
  serves **"Wyatt McIntyre for Sebastian County Sheriff" (Arkansas)**. The old note ("og:image is a
  theme asset") reads as though it were still his — importing from it would have attached a photo of
  a different person in a different state. `mclaughlinforsheriff.com` is a parked lander.
- **Summers' real domain is `electsummers.com`** (bio at `/meet-michael`). Both previously-recorded
  domains were never his.
- **Rupert's portrait exists after all**, at `sheriff.deschutes.org/about/leadership/` — a different
  path from the `/administration/` page that showed the building. Better still, the Oregon State
  Sheriffs' Association (`oregonsheriffs.org/sheriff/deschutes/`) hosts the *same* official portrait
  at **2466²** vs the county's 428², and its `-circle-` filename is misleading: the alpha is fully
  opaque, the circle is CSS.
- **`deschutes.org` now redirects to `deschutescounty.gov`** (CMS migration), so every wave-1
  `deschutes.org/...` path in this file is a redirect.

### Still pinned (6)
| Person | Blocker | Unlock |
|---|---|---|
| **Bill Kuhn** `-4101713` Treasurer, *sitting* | No portrait on any county page; name appears only in the "Investment Portfolio May 2026" PDF signature line. `billkuhn4treasurer.com` dead. | Nov pamphlet |
| **Robert Tintle** `-4101727` Treasurer cand., *sitting county CFO* | Only image anywhere is a portrait **inset inside a KTVZ graphic** (`ktvz.b-cdn.net/2022/09/Robert-Tintle-Deschutes-County-CFO.jpg`, 658×430) — a head crop needs ~3× upscale, worse than the pamphlet photos already rejected. | Nov pamphlet |
| **Jonathan Curtis** `-4101725` Clerk cand. | No campaign site; no coverage portrait. | Nov pamphlet |
| **Ron (Rondo) Boozell** `-4105831` Mayor cand. | `rondo2026.org` is entirely activist graphics (BlackDogBandW, DIGNITYforALL, warCriminals…) — no portrait of him on it. | Nov pamphlet |
| **Morgan Schmidt** `-4101724` Comm. P5 cand. | `morganlovesoregon.com` has only the logo, an Unsplash stock image, and one 2000×1125 landscape in which she is a small distant figure. No `/about` page. | news / site refresh |
| **Dan Sorrells** `-4105834` Council P6 cand. | Instagram `@citycouncildan` only; social-media profile photos excluded on licensing grounds. | Sept city forum |

Four of the six converge on the **November county voters' pamphlet** — grayscale and ~219px, so
below the normal bar, but for Kuhn/Tintle/Curtis/Boozell it may be the only image that will ever
exist. Decide then whether the bar bends for a sitting official with no alternative.

### Wave-1 search trail (2026-07-24) — ⚠️ SUPERSEDED IN PART, read section 3 above first
Kept for the dead-domain list and the pamphlet assessment. Its "needs a JS-rendering pass" verdicts
were resolved on 2026-07-26 (5 of those 7 sites yielded a usable headshot), and two entries were
outright wrong — see the corrections in section 3.

- No site resolves for: `dansorrells.com`, `sorrellsforbend.com`, `danforbend.com`,
  `jonathancurtis.org`, `curtisforclerk.com`, `tintlefortreasurer.com`, `summersfororegon.com`,
  `michaelsummersoregon.com`, `billkuhn4treasurer.com`. *(Still true — but Summers was found at
  `electsummers.com`, a domain not on this list. A dead-domain list is not proof of no site.)*
- Sites that DO resolve but whose images need a JS-rendering pass (Wix/Squarespace/GoDaddy lazy
  loaders defeat curl): `connally4deschutes.com` (og:image is a blank Wix placeholder) **→ RESOLVED,
  512² studio headshot**, `vote4sabbadini.com` **→ RESOLVED**, `morganlovesoregon.com` (og:image is
  a logo) **→ still no usable photo**, `bobbiforbend.com` (**trap:** the only real photo on the page
  is an endorser — **Jamie Collins** — not Cummiskey) **→ RESOLVED; note the endorser file is now
  `Ariel.webp` (Ariel Méndez), so this site has had at least two endorser-photo traps — always check
  the filename**, `elanaforbend.com` (og-image.png is a social card) **→ RESOLVED, raw asset is
  1350×1800**, `rondo2026.org` (no og:image) **→ confirmed no portrait exists**,
  `macforsheriff.com` / `mclaughlinforsheriff.com` (og:image is a theme asset) **→ 🔴 WRONG:
  macforsheriff.com now serves a DIFFERENT PERSON (Wyatt McIntyre, Sebastian County AR) and the
  other is a parked lander. Do not pull an image from either. His REAL site is
  `votemacforsheriff.com` — found in his own press release, and the source of the mig-1478
  headshot.**
- **Rejected source:** the Deschutes County May 2026 voters' pamphlet
  (`DocumentCenter/View/5835`) does contain statement photos for Connally (p21), Sabbadini (p22),
  Boozell + Imhoff (p24) and Schmidt (p25), but they are **grayscale ~219×256** — below the
  quality bar that rejected Springfield's 198px thumbnails. The **November** pamphlet (published
  after the Sept measure deadline) will add Curtis, McLaughlin and Tintle but will be grayscale
  too. Use only as a last resort.

## 4. Stance queue — Bend city, county pamphlet, sitting commissioners AND both appointed boards DONE
Outstanding: sheriff race (2), Sorrells (1). **HD 53/54 + SD 27 DONE 2026-07-25** — see
`.planning/todos/2026-07-24-party-prior-stance-contamination-audit.md`: their 18 pre-existing rows
were FABRICATED (party priors + votes predating their seating) and were retired and replaced with
45 evidence-only stances / 16 quotes across Levy, Kropf, Broadman and challenger Michael Summers.
Clerk/Assessor/Treasurer and their candidates remain honest-skip-by-design as ministerial offices.

**Totals now live, Bend LOCAL cohort** (city + county + school + park, ext ranges `-41058xx` /
`-410 17xx-19xx`): **83 stances / 70 quotes across 23 people, 0 unsourced.**
**Plus the 4 state legislators** (ext `-4120053`, `-4120054`, `-4110027`, `-4129001`, counted
separately because they sit outside those ranges): **45 stances / 16 quotes, 0 unsourced.**

### Wave 6 (2026-07-24): school board + park board — 7 rows kept of 10 researched
Three `politician-stance-researcher` agents (3-concurrent cap held). Payloads
`wave6-school-z1-4.json`, `wave6-school-z5-7.json`, `wave6-park.json`; per-wave NOTES.md files
carry the full source trail and every skip reason. **These boards are genuinely thin — 6 of 12
members have exactly one stance and 6 have zero. That is the honest ceiling, not under-research.**

- **Bend-La Pine (7 members → 3 stances/3 people):** LeGrand `civil-rights`=2, Tomlin
  `civil-rights`=2, Chadwick `civil-rights`=2. Lynch, Fischer, Olson, Tatom = 0.
- **BPRD (5 members → 4 stances/3 people):** Hovekamp `local-environment`=3 + `taxes`=3,
  Schneider `growth-and-development`=3, Schoen `growth-and-development`=3. Owens, Schiffman = 0.
- **Best find:** Hovekamp's real land-use record is on the **Deschutes County Planning
  Commission**, not the park board — on 2025-05-08 he personally moved to recommend approval of
  the clear-and-objective Goal 5 housing amendments, over Central Oregon LandWatch's request for
  a fresh ESEE analysis. A career conservationist at chair 3, which no party prior predicts.
- **Only scoreable BPRD axis** was the City of Bend affordable-housing property-tax exemptions
  that cost BPRD revenue: 2025-09-23 both failed 2-2, Schoen (moved) + Schneider for,
  Hovekamp + Owens against, Schiffman absent.

### Wave-6 validation rejections — do NOT silently re-add (3 of 10 rows, 30%)
Every quote re-fetched and string-matched; every secondary claim re-read at the primary source.
**All agent facts were accurate** — all three drops are about what the evidence can support.
1. **Fischer `civil-rights`=2** and **Olson `civil-rights`=2** — DROPPED. Both rested on
   **Resolution 1985** (2025-02-11, **7-0**; Olson moved it, Fischer got "Sexual Identity" added
   to the title — all verified). But the full resolution grounds itself in **existing** statute,
   is 3-of-4 clauses "Reaffirms", and carries a **savings clause**: *"shall be interpreted as not
   to violate any requirement of federal or state law."* A measure that disclaims exceeding
   current law fits chair 3 as well as chair 2. And a unanimous vote would mint the same stance
   for **all seven** directors off one symbolic institutional act.
2. **Tatom `taxes`=1** — DROPPED. Her 2019 quote is exact but says *"**Although I would have
   preferred a different mechanism for generating revenue**, I believe the positive aspects of
   the Student Success Act outweigh its drawbacks"* — she distances herself from the one tax
   position in it. Chair 1's "significantly raise taxes on wealthy people and large companies"
   entered only via the Oregon DOR's description of the Corporate Activity Tax, i.e. a fact about
   the bill, not her words. Also 2019-stale, and chairs 1 vs 2 are indistinguishable.
   → Unlock: the **May 2023 Deschutes pamphlet** (her contested re-election, her own statement) —
   not on DocumentCenter; untried paths in `wave6-school-z5-7-NOTES.md`.
3. **Corrected, not dropped — Tomlin.** The agent's *reasoning* wrapped the reporter's indirect
   speech in quote marks (*"He's looking forward to improving achievement gaps…"*). Rewritten as
   explicit indirect speech. **`quote_text` was clean.** This failure mode has now appeared in
   three consecutive waves and it keeps hiding in `reasoning`, which no string-matcher checks.

### Structural findings that should shape future local waves
- **Bend-La Pine BoardBook minutes cannot yield director stances.** They record attendance, a
  one-line **institutional** discussion summary, the motion and the tally — never a director's
  reasoning. Use them to **confirm a skip**, not to source a stance. (BoardBook PDF pattern:
  `meetings.boardbook.org/Documents/DownloadPDF/<GUID>?org=2413`; search is URL-addressable at
  `/Search/Index/2413?q=…`. The viewer page itself is an empty Apryse shell.)
- **Deschutes County Planning Commission minutes carry a printed disclaimer** that they are
  *"derived from an automated transcription service and have been summarized through an automated
  process."* Formal motions are reliable; publish no verbatim quote from them.
- **`X0024`-style special districts have almost no stance surface.** BPRD's entire 2026 record is
  procedural or collectively attributed apart from the one tax-exemption fight. Expect ≤1 stance
  per member for appointed/low-salience boards and budget the wave accordingly.
- **Oregon has no voucher program**, so `school-vouchers` is structurally empty for every Oregon
  school-board member — a permanent skip, not a research gap. Renewing a **public charter's**
  charter (Bend International School, 7-0, 2026-01-13) is not voucher evidence.

### Tooling: `backend/scripts/validate-stance-quotes.py` (new, reusable for any wave)
`py scripts/validate-stance-quotes.py <payload.json> [...]` from `backend/`. Bare names resolve
against `data/stance-research/bend-or/`. **It lives in `scripts/` deliberately:**
`.gitignore:76` ignores `backend/data/stance-research/**/_*`, so every `_*` helper in a
stance-research dir (`_push.ts`, `_headshots.py`, the `_TOPIC_SCALE_*.txt` files) is
**local-only and never committed** — worth knowing before relying on one surviving a fresh
clone. Its `ROSTER` / `ALLOWED_TOPICS` constants are per-wave guards; update them per cohort.
Re-fetches every
source and string-matches every quote; also checks roster/topic scope, value range, sources and
reasoning. Handles HTML, **PDF** (default + `-layout`, searched as a union) and **.docx**; caches
pages under `.qcache/`. Four hazards it exists to catch, all hit during this wave:
- **A naive re-fetch produces false accusations.** `opb.org` returns ~2 KB of nav + headline on a
  direct fetch with the body loaded by JS — three already-pushed, correct quotes looked
  fabricated. It now searches the direct **and** `r.jina.ai` renditions and reports
  `UNVERIFIABLE` (never `FAIL`) when every fetch returns a wall/shell.
- **Empty-`quote_text` rows were getting ZERO source verification** — nothing fetched at all, so
  an unfalsifiable claim passed silently. Now every source on every row is fetched and
  reachability-checked regardless of quote presence.
- **`r.jina.ai` needs `x-no-cache: true`** or it returns HTTP 200 with an **empty body** for
  403-walled origins (`bendoregon.gov`) — a silent failure that reads as a successful fetch.
- **Quote-terminal punctuation** gets its own `ok(punct)` tier: sources print
  `…time equals money,” Norris said`; payloads close with `money.` Benign, same class as the
  `net-zero -energy` source typo.
**Two things the validator cannot do — always do them by hand:** (a) an exact match *anywhere* in
a 40-page two-column pamphlet does **not** prove attribution — check the quote's position against
the `(This information furnished by X.)` delimiters (LeGrand and Tomlin use the *identical*
"With your vote, I will continue to" heading, so this is a live risk, not theoretical); and
(b) it never inspects `reasoning`, which is where indirect-speech-as-quote now hides.

### Agent-prompt lever that worked
`_TOPIC_SCALE_BOARDS.txt` embeds the exact 1-5 texts **plus a per-topic anti-trap note** aimed at
the previous wave's real failures (voucher chair 1 needs an anti-voucher position, not
public-school enthusiasm; referring a bond to voters does not place anyone on the `taxes` scale;
a district running preschool is institutional activity). Reuse that file's shape for the next
local board wave.

**Fetch-layer hazard for every future wave: WebFetch — including via `r.jina.ai` — refuses
verbatim reproduction and returns a PARAPHRASE.** Building `quote_text` from it fabricates a
quote that looks perfect. Use `curl` + `grep -F` (or this validator) for anything quoted.

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
Schmidt 5, Connally 4, DeBone 4, Imhoff 4, Sabbadini 4, and after wave 5 **Adair 5, Chang 4**. Payloads:
`wave1-stances.json`, `wave2-stances.json`, `wave3-*.json`, `wave4-county-pamphlet.json`;
push any of them with `_push.ts <file>`.

### Validation rejections — do NOT silently re-add these
Every agent output was spot-checked against its sources. **14 rows across waves 2-5 were rejected or
amended** (5 below, plus 9 in wave 5 documented in `_fix_wave5.py`). Recurring failure modes, in
frequency order: reporter's INDIRECT speech passed off as a quote (twice, second time despite an
explicit prompt warning); a value inferred from SILENCE; institutional action scored as a personal
position; evidence measuring a DIFFERENT axis than the topic (Adair's abortion row); stale evidence
where chairs can't be discriminated; and a source that is an opposition outlet describing reshares.
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
2. **Sheriff race (2): RESEARCHED 2026-07-26 → 0 rows. Honest skip, do not re-run the same sources.**
   Both candidates' own words were found and read in full; the three topics still cannot be scored.
   - **Sources mined (all read, all verbatim-checked):** OPB *Think Out Loud* write-up of the Rupert
     interview (2025-08-11, quotes marked "edited for length and clarity"); Bend Source DCSEA
     candidate forum (2025-07-08) covering both men; KTVZ 2026-01-26 carrying **Rupert's full
     statement and McLaughlin's full press release**; **`votemacforsheriff.com`** (his real site —
     mission, core values, platform); Bend Source 2026 budget piece on the $1M savings.
   - **Rupert `public-safety-approach` — considered chair 4, REJECTED.** His Aug-2025 interview
     supports it (*"First and foremost though, I have to get our staffing levels to a reasonable
     standard, both for patrol and corrections"*, plus wanting to expand a traffic team). But his
     2026 conduct and framing cut the other way: the Source reports his campaign *"centers on fiscal
     mindedness"*, and **$700K of his $1M savings comes from deliberately NOT backfilling** an
     undersheriff, a captain, a lieutenant, two admin roles **and a patrol deputy**, alongside
     equipment cuts (no ALPR, no vehicle graphics). He did add four jail deputies — a reallocation,
     not an increase. Chair 4's defining content (increase staffing/equipment/pay) is contradicted
     by his headline actions; chair 3's (adding crisis-response teams for mental health/addiction)
     is absent everywhere. **Two adjacent chairs, neither cleanly met → skip**, same gate that
     dropped Cummiskey's economic-development and held Kebler at 3.
   - **McLaughlin — nothing scoreable on any of the three.** His platform is cost discipline
     (*"reducing costs"*, *"cost-saving opportunities"*, *"culture change doesn't require a large
     financial investment"*), transparency, and partnerships. That rules out 4/5 without
     establishing 3, whose crisis-team content he never mentions. His forum and release quotes are
     about media contrition, trust and a *"1,000-day vision"* — leadership character, not a chair.
   - **`local-immigration` is STRUCTURALLY EMPTY for every Oregon sheriff** — same class as
     "Oregon has no voucher program" for OR school boards. ORS 181A.820 and HB 3265 forbid honoring
     ICE detainers and sharing status information statewide, so a sheriff's compliance is **legally
     compelled, not a chosen position**. Do not score it as chair 1/2 for any OR sheriff absent an
     explicit statement going beyond the law. (Rupert dropping the ALPR contract is adjacent — that
     database was queried ~300 times by federal immigration authorities at Bend PD — but he gave
     **cost** as the reason, so it is not immigration evidence.)
   - **`jail-capacity`:** neither has stated a position. A **144-bed jail addition is under
     construction** (Steele Associates project) — county capital work, institutional, not either
     man's stated view. Do not score it to whoever holds office, per the Riley tree-code rule.
   - **UNMINED, and the best remaining source:** the **Indivisible Sisters Sheriff Candidate Forum**
     — a recorded forum with both candidates, linked from `votemacforsheriff.com` ("Watch Mac at
     the Indivisible Sisters Sheriff Candidate Forum"). It is video, so it needs a transcript or a
     written recap. A forum is the one format that puts both men on the record on the same policy
     questions. Check that before the November pamphlet.
   - **NEW OBSTACLE: `bendbulletin.com` is now REGISTRATION-walled** ("Get access by creating an
     account"), so the wave-1 note calling it "the best search" no longer holds for article bodies.
     `redmondspokesman.com` mirrors much Bulletin content (same publisher) — try it first.
3. **Bend-La Pine School Board (7)** — external_ids `-4101981`..`-4101987` (Lynch Z1, LeGrand Z2,
   Fischer Z3/Vice Chair, Olson Z4, Tatom Z5/Chair, Tomlin Z6, Chadwick Z7). Applicable topics are
   narrow: `school-vouchers`, `childcare`, `civil-rights`, `trans-athletes`, `taxes` (bond/levy
   votes) — do NOT force the growth/housing/transport topics onto a school board.
   **Sources to start from:** the board's minutes and agendas live in BoardBook, NOT on the district
   site — `https://meetings.boardbook.org/Public/Organization/2413` (policies:
   `.../Public/Book/2413`). Board meetings are also recorded on the YouTube channel
   `@blsschoolboard6373`. Roster/zone page is `https://www.blschools.org/board-and-policy/school-board`
   (the "Meet the Board Members" panel is an accordion — its content only exists in the DOM after
   the link is clicked, so Playwright + click, or read `data-image-sizes` attributes).
   Note three of them (Tatom, Olson, Lynch) publicly endorsed Amy Sabbadini for county commissioner
   per the May 2026 pamphlet — that is affiliation, NOT stance evidence.
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
