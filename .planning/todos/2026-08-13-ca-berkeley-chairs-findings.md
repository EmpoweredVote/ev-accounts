# Berkeley chairs owed evidence — findings (2026-08-13)

Continues `.planning/todos/2026-08-13-ca-chairs-owed-handoff.md`. Standard: [[chair_needs_evidence_for_that_chair]].
Worklist regenerated: **42 rows** — CA 31, MD 3, MA 2, MI 1, 5 unattributed.

## 🔴🔴 THE GATE CANNOT SEE MUNICIPAL INSTRUMENTS — 14 of the 31 CA rows are in the worklist partly for a LEXICAL reason
`audit-chair-evidence.mjs`'s `NAMES_INSTRUMENT` regex was built for state legislatures: it matches
`HB/SB/AB`, `\bAct\b`, `\bOrdinance\b` (**case-sensitive**) and `voted YES/NO`. It does **not** match
`referral`, `budget referral`, `resolution`, `Item 21`, `Measure FF`, or a lowercase `ordinance` —
the entire vocabulary of a city council. 14 CA rows name a municipal instrument it cannot see.
🔑 **Do NOT "fix" this by widening the regex alone.** Naming an instrument was only ever a proxy for
the real standard, and a wider regex would let every one of these rows pass the gate *without anyone
checking that the instrument describes the seated chair*. Widen it only together with the re-sourced
reasoning below, so passing means what it is supposed to mean.

## ✅ THE CORPUS — Berkeley is now fully readable, and it is reusable
`scripts/berkeley-agenda-corpus.mjs` + three fallbacks + `scripts/berkeley-find.mjs`.
**211 open meetings, 2021-01-19 → 2026-07-28, 3,423 council items indexed.** The annotated agenda is
Berkeley's mgaleg: it names the **Author and every Co-Sponsor** of each item and records the
**roll-call vote**. Author/co-sponsor counts: Taplin 132/125, Bartlett 64/127, Kesarwani 37/46,
Tregub 45/37, Blackaby 15/35.

### Traps this corpus cost me, all of the "silent under-read" family
1. 🔴 **The site indexes older meetings under a LONGER path** (`/your-government/city-council/city-council-agendas/…`).
   My first extraction regex only matched single-segment hrefs, so **all of 2021 vanished without an
   error** — 69 meetings. Exactly the MD unreadable-session shape.
2. 🔴 **`pdftotext` hyphen-wraps across lines** and the line may carry TRAILING SPACES, so
   `"Co-   \n   Sponsor"` is not `"(Co-Sponsor)"`. Anchoring on `-\n` alone still lost **55
   co-sponsorships**, 14 of them Blackaby's own.
3. 🔴🔴 **The trailing "Communications" section reprints each item's heading AND its `From:` line.**
   Left in, a co-sponsor named in the reprint is attributed to the *preceding* item — a **fabricated
   sponsorship**, not merely a duplicate. It also inflated Taplin from 132 to 166 authored. Fixed by
   cutting the document at Adjournment; regression-checked on 2025-02-11 #12 (was falsely carrying
   Blackaby from the Item #7 reprint).
4. ⚠ **40 meetings publish no ANNOTATED agenda**, only a plain agenda or the web eagenda. Those are
   tagged `agenda_only`: authorship is readable, **outcomes are not**. Never cite a vote from one.
   Tregub's Nov-2024 pedestrian referrals sit on such a date.

### Coverage, stated exactly — this decides who is blankable
- **Tregub, Blackaby** (seated 2024): record COMPLETE. Blankable.
- **Taplin** (seated Dec 2020): missing Dec 2020 + **3 meetings the city returns a hard 403 for**
  (2021-02-16, 2021-06-03, 2021-06-10). ~5 of ~200. Effectively complete.
- **Kesarwani** (seated Dec 2018): **2019 and 2020 are NOT PUBLISHED** — berkeleyca.gov's index
  begins 2021 and the legacy `cityofberkeley.info` redirects to it. **Two full years unread.**
  🔴 **Per the MD rule she is NOT BLANKABLE.** Positive sourcing only.

---

## ✅ RESOLVED — one instrument closed five rows
**Sanctuary City Ordinance, BMC Ch. 13.114, Ordinance No. 7,984–N.S.** First reading 2025-09-09,
second reading adopted **2025-09-30, "Absent: None. Vote: All Ayes"** — so all five members voted for
it on the record. I read the ordinance TEXT, not its title, and it settles chair 1 vs chair 2:
- 13.114.030(C)(5) forbids "**Complying with any civil immigration warrant or request to detain,
  transfer, or notify**" — with **no** judicial-warrant carve-out in that clause = chair 1's "Refuse
  **all** ICE detainers", not chair 2's "comply only with **court-ordered** detainers".
- 13.114.030(C)(4) forbids disclosing protected personal information to immigration authorities, and
  (C)(3) forbids even *collecting* immigration status = chair 1's "prohibit local employees from
  sharing immigration status information".
- Protection is **universal**, not limited to chair 2's "crime victims and witnesses".

| row | was | now | attribution |
|---|---|---|---|
| Tregub / Local Immigration Enforcement | 2 | **1** | Aye 9/30/25; co-sponsor of Item 21 |
| Blackaby / Local Immigration Enforcement | 2 | **1** | **authored** Res. 71,658 (Reaffirming Sanctuary City, 1/21/25); co-sponsored the 4/15/25 referral that produced the ordinance; Aye |
| Taplin / Local Immigration Enforcement | 2 | **1** | co-sponsored both the reaffirmation and the referral; Aye |
| Kesarwani / Local Immigration Enforcement | 1 | **1** (kept) | Aye — re-source only |

## ✅ RESOLVED — chair kept, re-sourced to a verified instrument
- **Tregub / Fossil Fuel Policy ch2** — 2026-03-10 #10, **he LEADS**, adopted **Res. 72,156–N.S.**,
  opposing BLM oil & gas leasing on ~1.6M acres and urging "**cessation of all new oil and gas lease
  sales**". That is chair 2's "stop issuing new permits" almost verbatim, and it beats chair 1
  because it asks nothing about *existing* extraction. ⚠ The reasoning I replaced cited Golden State
  Energy and a buildings gas ban — **utility and building instruments, on a DRILLING ladder**.
- **Tregub / Rent Regulation ch2** — **Res. 72,378–N.S.** (2026-07-07): the Nov-2026 ballot measure
  making "most rent control and registration exemptions inapplicable to units that were not exempt
  when the current tenancy began". Tregub **moved it, co-sponsored it, and was designated to write
  the ballot argument in favour**. 🔑 What rules out chair 1 is in the document itself: the adopted
  amendment **preserves the Golden Duplex Exemption** and ~330 projects "would remain exempt" — so it
  extends coverage to *more* units, not to *all*.
  🔴 **The instrument the row previously cited was never adopted**: 2025-03-11 Item 15 reads
  "**Item removed from the agenda by Councilmember Tregub.**" A withdrawn referral is not an act.
- **Tregub + Taplin / Homelessness Response ch2 and Criminalization of Homelessness ch3** —
  **Ordinance No. 7,935–N.S.**, second reading 2024-09-24, roll call **"Ayes – Kesarwani, Taplin,
  Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguín; Noes – Lunaparra"**. Authored by Kesarwani.
  It affirms the City "will continue to offer interim housing … when closing encampments" and
  authorises citation and arrest **only** under six enumerated health/safety exceptions.
  → Criminalization **ch3** ("enforcement only when shelter is available"): beats ch2 because it
  expressly authorises citation and arrest, beats ch4 because it does not prohibit encampments.
  → Homelessness Response **ch2** ("expand shelter … use enforcement only after services are
  offered"): the sequencing clause is the ordinance's operative rule, which is what beats ch3.
  ⚠ Tregub's attendance verified — he was seated by Sept 2024 (D4), so these votes are really his.
- **Tregub / Affordable Housing ch3** — 2025-03-11 #14, **he LEADS**, approved: referral for a
  **transfer tax exemption for 100% affordable projects owned by non-profits or community land
  trusts** = chair 3's "subsidies for affordable projects". Beats ch2: it is not a rent cap, not an
  inclusionary requirement, and not public funding of construction.
- **Kesarwani / Transportation Priorities ch2** — hers is a genuinely *balanced* record, which is
  what chair 2 actually asserts: she LEADS **street-maintenance/pavement budget referrals**
  (2022-05-24, 2023-06-06) *and* multimodal safety (AB 43 speed limits ×2, Ohlone Greenway), and
  2026-07-28 she LEADS "**Schedule Hopkins Street for Paving with Enhanced Safety Improvements for
  all Users**" — one item that is both clauses at once. Beats ch1: she *expands* Residential
  Preferential Parking and parking benefit districts rather than reducing parking requirements.

## ▶ BLANK RECOMMENDED — the chair's own clause is absent from a complete record
- **Blackaby / Deportation Priorities ch2** ("only deport people convicted of serious violent
  crimes"). All 52 of his items read. Nothing states who should be deported. 🔑 Two independent
  reasons: (a) the ordinance he backed is **categorical — it has no criminal-conviction carve-out at
  all**, which contradicts rather than supports chair 2; (b) his one cited instrument (Item 21, the
  $200k deportation-defence fund) is the *same act* already carrying his Local Immigration
  Enforcement row — **the ladder asks who should be deported, city instruments answer whether the
  city cooperates**. Same structural mismatch that blanked all 5 MD Immigration rows.
- **Tregub / Public Safety Approach ch3** and **Taplin / Public Safety Approach ch3** ("keep current
  funding while **adding crisis response teams** for mental health and addiction calls"). Neither
  has a crisis-response instrument. Tregub's cited Prop 6 resolution is about **forced prison
  labour**; the only SCU item in his tenure is a City-Manager contract for an *evaluation* of the
  existing unit (2024-11-19). Taplin's sole mental-health item is a **ceremonial proclamation**
  (Res. 69,853–N.S., "May 2021 as Mental Health Month"). On-topic by vocabulary, not by rationale.

## ✅ APPLIED — **mig 1738**, verified on row counts. Debt **42 → 25**, CA **31 → 14**.
Answers 32,370 → **32,367** (−3, exactly the blanks); context **33,083 unchanged**; 4 rows cite
Ord. 7,984-N.S., 4 cite Ord. 7,935-N.S.; 0 blanked rows still seated and all 3 kept their context.
All six guards passed, `--check` on the rollback returns exit 0.
🔑 **The gate regex was widened in the SAME commit, and narrowly**: `Resolution No.` / `Ordinance No.`
require the NUMBER, and `referral approved|adopted|considered` requires the referral to have been
ACTED ON — an unqualified `referral` would have admitted the very withdrawn item this migration
removed. **Proof it greened nothing unread: the debt fell by exactly 17, the number of rows touched.**

## 🔴 DECIDED WITH THE USER — and one correction I had to make first
- **Taplin / Rent Regulation → chair 2 KEPT.** The 2022 votes and the 2026 vote are ONE consistent
  position, not a contradiction: he protects the owner-occupied golden duplex exemption, and the 2026
  measure he supported *also* retains it while extending coverage elsewhere. The later vote governs.
- 🔴🔴 **I RECOMMENDED RE-SEATING TAPLIN / TRANSPORTATION TO CHAIR 1 ON AN INCOMPLETE READ, AND HAD
  TO WITHDRAW IT.** I told the user "nothing in either record supports road parity". False for
  Taplin: he **co-sponsored Kesarwani's street-maintenance pavement referrals** (2022-05-24,
  2023-06-06) and **LEADS the Vision 2050 COMPLETE STREETS** programme (2023-03-14, approved). Road
  investment *plus* bike-lanes-with-repaving is chair 2's pair of clauses. Chair 2 kept, re-sourced.
  This is the Ellis-cemetery error reproduced by me, one step from a migration: **a co-sponsorship
  sits in the record just as firmly as an authorship, and I had only scanned the authored list.**
- **Tregub / Transportation left OPEN and owed** (guard 6 proves the migration did not touch it):
  chair 2 is contradicted by his record, but chair 1's "reduce parking requirements communitywide"
  has no instrument of his behind it. Neither chair is evidenced.

## 🔴 STILL OPEN — the record cuts against the seated chair, so this is a decision, not a citation
1. **Taplin / Rent Regulation ch2 — a recorded vote CONTRADICTS the seated chair.**
   2022-07-12 Item 20, on amending the Rent Stabilization Ordinance, split three ways and Taplin is
   on the record **against extending coverage**: he voted **Aye to "take no action on the golden
   duplex provisions"** (i.e. to keep that exemption), then **Noes on approving Part #1** which would
   have ended the golden-duplex exemption, then **Abstained on Part #3** modifying the
   new-construction exemption. Chair 2 is precisely "extend coverage to more units". Against that,
   in 2026 he voted Aye to *place* Res. 72,378 on the ballot — but placement is not endorsement, and
   that measure keeps the golden duplex exemption he protected.
   Chair 3 ("maintain current tenant protections while allowing market rents for new construction")
   fits the 2022 votes better. **Recommend: blank**, or re-seat 2→3. Not mine to decide silently.
2. **Tregub / Transportation Priorities ch2 → 1?** His record prioritises pedestrian, cycling and
   transit spending (Oxford for All class IV bikeway + $400k, adopted 2025-06-03; pedestrian
   referrals; MTC Transit-Oriented Communities letter) and **nothing anywhere supports chair 2's
   "invest equally in roads"**. But chair 1's second clause — "reduce parking requirements
   communitywide" — has no Berkeley instrument of his behind it. Contradicted at 2, incomplete at 1.
3. **Taplin / Transportation Priorities ch2 → 1?** Stronger than Tregub's: he **LEADS the parking
   minima reduction** (2022-06-28 #39, approved — cuts BMC 23.322 off-street minima for mixed-use,
   live/work and manufacturing) *plus* transit and bike work (51B BRT, e-bike rebates, Vision Zero,
   AC Transit restoration). That evidences **both** of chair 1's clauses, though the parking cut is
   district-scoped rather than literally communitywide.
4. **Taplin / Climate ch3 → 2?** His own instruments say "**Just Transition FROM fossil fuels**"
   (Res. 70,171), "**accelerate the fossil-free economy**", and a 2030 VMT target — chair 2's
   "rapidly transition … by 2030", not chair 3's "**gradually** reducing".

## ▶ NOT YET READ
- **Kesarwani / City Sanitation ch2** and **/ Climate ch3** — both look thin (her sanitation-adjacent
  items are a park bathroom and a council-fund grant to a litter non-profit), **but she is not
  blankable** — see coverage above. Positive sourcing only, or leave.
- **Bartlett, 6 rows** — corpus is built and he is in it (64 authored / 127 co-sponsored). His rows
  mix `ben2024.com` with `berkeleyca.gov`. ⚠ He was **recused** from the 2022 rent votes (resides in
  a golden duplex) — check recusals before reading any vote of his as a position.
- **San Diego 3** (Gloria 2, Elo-Rivera 1) and **El Segundo 1** (Boyles). ⚠ Elo-Rivera / Taxation ch2
  is the magnitude-bound ladder that killed all 13 MD Taxation rows — expect the same.
- **Non-CA 11**: MD 3 (Washington, Muse — **both restored to chair 2 by mig 1732 and still owed, so
  MD debt is 3, not the 1 the previous handoff recorded**; plus Waldstreicher / Same-Sex Marriage,
  which needs the **2012** Civil Marriage Protection Act roll call, outside the 2013+ corpus),
  MI 1 (Stevens / AI Oversight — sourced only to isidewith.com), MA 2, 5 unattributed.
