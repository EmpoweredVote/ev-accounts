# Berkeley chairs owed evidence — findings (2026-08-13)

Continues `.planning/todos/2026-08-13-ca-chairs-owed-handoff.md`. Standard: [[chair_needs_evidence_for_that_chair]].
Worklist regenerated: **42 rows** — CA 31, MD 3, MA 2, MI 1, 5 unattributed.

## ✅✅ BERKELEY IS CLOSED — **mig 1738 then mig 1739**. Debt **42 → 25 → 17**, CA **31 → 14 → 6**.
The 6 CA rows left are **not Berkeley**: Gloria 2 (San Diego), Elo-Rivera 1, Boyles 1 — plus
**Kesarwani 2, deliberately LEFT OWED** because she is not blankable and has no instrument (below).
Mig 1739 = Bartlett's 6 + Taplin/Climate re-seated + Tregub/Transportation blanked. Gate exit 0;
answers 32,367 → 32,366 (−1, exactly the blank); context unchanged; **debt fell by exactly 8, the
number of rows touched**, which is what proves nothing unread was greened.

### 🔴🔴 THE CORPUS ITSELF WAS DEFECTIVE, AND REPAIRING IT CHANGED AN ANSWER
Two *more* silent under-reads in `berkeley-agenda-corpus.mjs`, both fixed (3,423 → **3,649 items**):
1. **THE PLURAL CO-SPONSOR SERIES.** Most items tag each name — `Councilmember Hahn (Co-Sponsor)` —
   but some write a series with ONE TRAILING PLURAL: `Councilmember Taplin (Author), Councilmember
   Bartlett, Councilmember Hahn, and Mayor Arreguin (Co-Sponsors)`. A per-name anchor matches only
   the LAST name and drops the rest.
2. **MY OWN 1738 FIX OVER-CUT.** Truncating at the first `Adjourn…Communications` boundary killed 96
   legitimate items across 4 meetings, because consent calendars carry early items titled *"Adjourned
   in Memory of <resident>"* and long packets APPEND the prior meeting's full minutes. Replaced with a
   per-chunk **reprint filter**, which keeps the items and still refuses the reprints.
🔑 **The cost of those two bugs was the decisive instrument: Res. No. 70,171-N.S., "Commit the City
of Berkeley to a Just Transition from the Fossil Fuel Economy" (Taplin author, Bartlett co-sponsor,
adopted 2021-12-14) read as ABSENT under both bugs at once.** A tool's own gap is indistinguishable
from a politician having no record; only re-reading the source told them apart.
✅ **Re-verified after the repair: all 3 blanks from 1738 STILL STAND** on the larger record, and both
regressions held (2025-02-11 #12 carries no role; the `Russbumper Supplemental Communications`
reprint at #69 carries none either).
⚠ **Two of my own detectors over-fired before I trusted them** — worth the reflex: `/ICE\b/i` matched
"Serv**ice**"/"Off**ice**"/"Pol**ice**", and a tail-truncation scan reported "10 meetings, 275 items
missing" that were really **public-speaker lists**. The true figure was 97 chunks in 4 meetings.
⚠ The corpus also indexes **appended prior-meeting minutes under the later date** (Res. 70,171 is
filed under 2022-01-25 but was adopted 2021-12-14). Duplicates, not fabrications — the author/
co-sponsor totals in this file are inflated by it. Cite the TRUE meeting date, not the file's.

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

## ✅ THE FOUR "STILL OPEN" ITEMS ARE NOW CLOSED — decided with the user, applied in **mig 1739**
1. **Taplin / Rent Regulation ch2 — KEPT** (already decided in 1738; the later vote governs, and the
   2026 measure preserves the same golden duplex exemption he protected in 2022). Not owed.
2. **Tregub / Transportation ch2 → BLANKED.** Chair 2 is contradicted by his pedestrian/cycling/
   transit record; chair 1's "reduce parking requirements communitywide" has **no instrument of his**
   anywhere in the repaired corpus. Contradicted at 2, incomplete at 1 → neither chair is described.
   ✅ Safe as an absence finding: seated Dec 2024, and **none of the 96 recovered items falls inside
   his tenure**, so this rests on a complete record.
3. **Taplin / Transportation ch2 — KEPT** (decided in 1738 after I had to withdraw a re-seat).
4. **Taplin / Climate ch3 → 2, and Bartlett / Climate ch2 KEPT** — one shared record, decided on the
   **END-STATE reading**: chairs 2 and 3 differ in end state, not only pace ("phase out fossil fuels"
   vs "gradually reducing **reliance**"). Res. 70,171-N.S. commits the city to a Just Transition
   **FROM** the fossil fuel economy = elimination in kind; Res. 70,348-N.S. supports fossil-fuel
   **divestment**. Taplin authored 70,171 and also Res. 70,172-N.S. (carbon fee and dividend).
   ⚠ The losing reading is recorded in the row itself, not hidden: **chair 2's "by 2030" is pinned by
   no adopted instrument** — the only 2030 figure is a 25% VMT-per-capita target sitting in a referral
   of *concepts*, and C40 Race to Zero runs to **2050**. On a pace reading these rows would be
   unevidenced, exactly as all 13 MD Taxation rows were.
   🔑 **Three members co-sponsored ONE instrument and sat at THREE different chairs** (Bartlett 2,
   Taplin 3, Kesarwani 3). The same evidence cannot support two chairs — that inconsistency was the
   finding that forced this decision.

## 🔴 SUPERSEDED — the original open list, kept for the reasoning
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

## ✅ BARTLETT — ALL 6 ROWS READ AND APPLIED (mig 1739)
🔴 **HE IS NOT BLANKABLE, and that was settled before anything else was read.** berkeleyca.gov's
roster page states **"Elected: November 2016"**; the corpus begins 2021-01-21, so **2017-2020 — four
years, more than half his tenure — is UNREAD.** Positive sourcing only, same bar as Kesarwani.
⚠ **Two claims in his seated reasoning did not survive the record and were REMOVED, not re-cited:**
every **Specialized Care Unit** item in the readable corpus is a **City Manager contract with no
council sponsor**, and **"Step Up Housing" appears NOWHERE** in 3,649 items. Both sit in the unread
window; both came from `ben2024.com`. A campaign site can corroborate an instrument, never be one.

| row | was | now | instrument |
|---|---|---|---|
| Local Immigration Enforcement | 2 | **1** | Ord. 7,984-N.S.; roll call names him **Present / Absent: None**, All Ayes |
| Criminalization of Homelessness | 2 | **3** | Ord. 7,935-N.S., named individually in the Aye roll |
| Homelessness Response | 2 | 2 | **his own authored $200k Homeless Outreach Coordinator** (approved 2021-11-09) + 7,935's sequencing clause |
| Transportation Priorities | 2 | 2 | Vision 2050 Complete Streets + 50-50 Sidewalk Repair (both approved, co-sponsor on the record) |
| Environmental Protection vs. Development | 2 | 2 | **Res. 71,118-N.S.** permanent linear City park dedication under BMC 6.42 + SB 954 habitat review |
| Climate Change | 2 | 2 | **Res. 70,171-N.S.** Just Transition FROM fossil fuels + Res. 70,348-N.S. divestment |

🔑 **I re-verified the ordinance TEXT myself rather than inheriting 1738's reading**, and the
discriminator is a deliberate internal contrast I can now state exactly: **(C)(4) and (C)(8) each
carve out "a valid judicial warrant", and (C)(5) — detainer compliance — does NOT.**
⚠ **Counter-evidence cited in the row rather than omitted** (the Ellis rule): he AUTHORS the PITCH
upzoning (8 stories on Telegraph) — which is what rules out chair 1 — and he co-sponsored support for
**SB 922, which would permanently EXEMPT transportation projects from CEQA**. The park dedication, not
the review provisions, is what carries the Env-vs-Dev chair.
⚠ Chair 3's second clause on Criminalization ("citations diverting people to services") is **NOT** in
Ord. 7,935. Chair 3 is seated because it **beats every rival**, not because both clauses are evidenced.
⚠ The recusal warning did not bite: Bartlett has no rent-regulation row.

## ▶ KESARWANI — READ, AND DELIBERATELY LEFT OWED (no migration touches her; guard 6 proves it)
- **City Sanitation ch2** — chair 2 needs "increase sanitation crews" AND "prioritize historically
  underserved neighborhoods". **NO matching item exists in her complete repaired record.** Her
  campaign claim to have funded the **Downtown Streets Team** expansion is not an instrument of hers:
  **all four Downtown Streets Team items are City Manager contracts with no council sponsor.**
- **Climate ch3** — her only climate instrument in 96 role entries is the co-sponsorship of the
  2024-12-03 Green New Deal referral. She is **not** on Res. 70,171, so she did not move with Taplin
  and Bartlett.
🔴 **She is NOT BLANKABLE** (2019-2020 unpublished), so "no instrument" cannot become a blank. Owed is
the honest state. ⚠ Her seated Climate reasoning contains a pure non-argument worth deleting whenever
this row is next touched: *"served on the council in 2019 when Berkeley passed the natural gas ban"* —
**presence at a vote is not a position.**
## ✅ SAN DIEGO CLOSED — **mig 1740**. Debt **17 → 14**, CA **6 → 3** (Kesarwani 2 + Boyles 1)
All 3 re-sourced, 1 re-seated. Gate exit 0; **no blanks**, so nothing here rests on a completeness
claim. Debt fell by exactly 3 = rows touched. Sources cached at `%TEMP%/ev-stance-cache/sandiego/`.
🔑 **A MAYOR'S ATTRIBUTION IS BETTER THAN A CO-SPONSORSHIP, NOT WORSE.** Gloria doesn't co-sponsor —
he proposes and signs. The adopted **2022 Climate Action Plan** carries his **signed first-person
letter**, and the City's news release calls it "**the Mayor's CAP update**".

- **Gloria / Climate ch3 → 2.** Applies the end-state reading from 1739, on stronger evidence than
  Berkeley's because it is dated and quantified: CAP adopted unanimously 2022-08-02, net zero by 2035,
  and **numbered measures with deadlines** — M1.1 phase out **45% of natural gas in existing buildings
  by 2030, 90% by 2035**; M1.2 **all-electric reach code from 2023** for new development; M1.3 **50% of
  municipal gas by 2030, 100% by 2035**; SDCP 100% renewable electricity by 2035. Plan text: net zero
  "means **eliminating fossil-fuel emissions**"; the City "has taken bold steps to **accelerate** the
  transition away from fossil fuels".
  🔑 **The stored reasoning ALREADY described chair 2 while seated at chair 3** — it ended "aligns with
  rapidly transitioning to clean energy and phasing out fossil fuels". An independent instance of
  [[chair_reasoning_inversion]], found before the evidence and corroborating it.
  ⚠ Completion is 2035, not ch2's 2030; the 2030 milestones are partial. Recorded in the row.
- **Gloria / Env-vs-Dev ch3 KEPT.** 🔑 Settled by the **regulation's own structure**, not by judging his
  politics: **CAP Consistency Regulations**, SDMC ch.14 art.3 div.14, added by **Ordinance O-21528 N.S.**
  (2022-09-21, eff. 2022-10-23). §143.1403(b) **bars using a bonus or incentive to waive** the
  requirements = "consistent standards"; **§143.1403(c) lets development that DEVIATES be approved with
  a Process Two Neighborhood Development Permit** = "reasonable flexibility", in the code's own words.
  Beats ch1 (thresholds: 3+ units / 5,000+ sq ft; state-law ADUs exempt → not "any development"),
  ch2 (deviation pathway, no full-offset), ch4 (on-site duties incentives can't buy out), ch5 (adds
  local restrictions). ⚠ Its stored reasoning also named the WRONG chair ("requiring significant
  environmental review and offsetting") — chair survives, reasoning does not.
  ⚠ **CHECKED AND DELIBERATELY NOT CITED**: the 2021 **Parks Master Plan** (acreage → recreational-value
  points; on-site amenities offset park fees). It reads as ch4 vocabulary but governs **park adequacy
  owed by new development**, not environmental preservation vs development. Off-axis.
- **Elo-Rivera / Taxes ch2 KEPT.** 🔴🔴 **THIS LADDER IS NOT PURELY MAGNITUDE-BOUND — see below.**
  He **introduced** the Empty Homes Tax (Rules Cttee Jan 2026, per IBA 26-05); **Ord. O-22071** +
  **Res. R-316659**, both 2026-03-03, placed it as **Measure A** on the 2026-06-02 ballot. SDMC
  §§32.0101–32.0123: **$8,000 (2027) → $10,000** on non-primary residences vacant >182 days, **plus a
  separate $4,000/$5,000 charge on corporate-owned** empty homes — ch2's "wealthy people **and** large
  companies" on both halves at once. IBA 26-08: **"all revenue would be unrestricted and deposited into
  the City's General Fund"**, $9.2M–$21.4M yr 1.
  ⚠ Stored reasoning was **factually wrong about its own instrument**: "$5k/bedroom" vs the actual flat
  $8,000/home. A wrong instrument description is a sourcing defect even when the chair is right.
  🔴 **Counter-evidence cited in the row** (Ellis rule): as Council President he backed **Measure E**
  (Nov 2024), a **one-cent GENERAL SALES TAX**, 7.75%→8.75%, **$360–400M/yr**. A sales tax is not levied
  on "wealthy people and large companies", and $400M is not "moderate" — but it too went to the
  unrestricted General Fund against a ~$200M structural deficit.

### 🔴🔴 THE TAXES LADDER'S ch1/ch2 DISCRIMINATOR IS **PURPOSE**, NOT MAGNITUDE — re-examine MD
ch1 = "significantly raise … to fund **MORE** public services"; ch2 = "moderately … to fund **EXISTING**
services". **The second half is a documentable purpose test.** Both Elo-Rivera instruments send proceeds
to the **unrestricted General Fund to sustain existing operations against a deficit** — neither creates a
new programme — so **ch1 is contradicted and ch2 wins without any judgement about "moderately".**
▶ [[chairs_owed_evidence]] records the MD reading as "the only difference from chair 1 is MAGNITUDE".
That is a **misreading of the chair text**, and the 13 MD Taxation rows blanked in mig 1736 may have
been decidable on the purpose clause (e.g. where a bill's revenue was earmarked for a NEW programme vs
the general fund). **Not reopened here** — flagged as a re-examination candidate, needs the user's call.

### ⚠ The gate was widened a SECOND time, narrowly, and only alongside these verified rows
`NAMES_INSTRUMENT` was legislature-shaped, then municipal after 1738 — but it still could not see a
**mayor's** instrument, an adopted municipal PLAN. Added `Measure \d+\.\d+` (a numbered measure inside
an adopted plan; the **decimal is required** so vague prose and a bare ballot "Measure A" cannot satisfy
it) and `O-#####`/`R-######` (San Diego numbering). **Proof it greened nothing unread: debt fell by
exactly 3, the number of rows touched.**

## ▶▶ NEXT — the 14 rows left
- **CA 3**: Kesarwani 2 (owed by design, see above) + **Boyles / Residential Zoning** (El Segundo, one
  campaign-site citation; ⚠ Residential Zoning is **OFF-AXIS** per [[ladder_orientation]]).
- **Non-CA 11**: MD 3 (Washington + Muse / Voting Rights, restored by 1732 and still owed; Waldstreicher
  / Same-Sex Marriage needs the **2012** Civil Marriage Protection Act roll call, outside the 2013+
  corpus), MI 1 (Stevens / AI Oversight — sourced only to isidewith.com; ⚠ AI Oversight runs
  **BACKWARDS**), MA 2, 5 unattributed.
- **Non-CA 11**: MD 3 (Washington, Muse — **both restored to chair 2 by mig 1732 and still owed, so
  MD debt is 3, not the 1 the previous handoff recorded**; plus Waldstreicher / Same-Sex Marriage,
  which needs the **2012** Civil Marriage Protection Act roll call, outside the 2013+ corpus),
  MI 1 (Stevens / AI Oversight — sourced only to isidewith.com), MA 2, 5 unattributed.
