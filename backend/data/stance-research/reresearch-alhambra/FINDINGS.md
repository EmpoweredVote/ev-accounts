# Alhambra CA — re-research of the 19 rows retired by migration 1564

**Date:** 2026-08-06 · **Status:** proposed, NOT applied — awaiting operator approval
**Owed:** 19 (politician, topic) pairs across 5 councilmembers, all emptied to zero answers by 1564.
**Proposed:** 16 chair assignments · **3 stay PENDING** (no evidence — a blank spoke is correct).

---

## Why the old rows could not be repaired

All six sources cited by the 19 retired rows were fabricated. Five are `sgvtribune.com` article paths
denylisted by 1564; the sixth is `alhambraca.gov/government/city-council/agendas-minutes`, a 404 index.

🔴 **`sgvtribune.com` is the `lowellsun.com` shape again** — a real, live outlet (Southern California
News Group) carrying invented article paths. See [[invented_publications]]. One retired citation claimed
an *"Alhambra mental health co-responder program"* (`/2022/05/…`). **There is no co-responder or crisis
team anywhere in Alhambra's 2024–2026 council minutes** — the program appears not to exist. That is
consistent with fabrication, and it is why re-research had to start from primary sources.

## Evidence base built for this cluster

`alhambraca.gov` **AgendaCenter minutes, 2024–2026: 77 of 78 PDFs downloaded and text-extracted**
(1 failed extraction: `_03242025-1357`). Alhambra minutes are high quality for this purpose — they carry
named roll calls (`PRESENT: LEE, MAZA, WANG, ANDRADE-STADLER, MALONEY`), per-member discussion
attributed by name, and per-item vote tallies.

⚠ **Agenda packets are scanned images with no text layer** (7.8 MB → 403 lines). Only the *minutes*
are readable. A search hit inside a packet cannot be read and must not be treated as evidence either way.

### 🔴 TOOLING TRAP — `pdftotext -layout` MIS-ASSIGNS VOTE TALLIES IN THIS FORMAT

The single most dangerous thing found this session. With `-layout`, the 2025-07-28 immigration
resolution extracts as:

```
Vote:   Moved:  ANDRADE-STADLER   Seconded: MALONEY
        Ayes:
        Noes:   ANDRADE-STADLER, MALONEY, MAZA, WANG, LEE
        Absent:
                NONE
                NONE
```

Read literally: **all five voted NO on a resolution they had just moved, seconded, and spoken in support
of.** Extracting the same page *without* `-layout` shows the truth — labels in one column, values in
another:

```
Moved: Ayes: Noes: Absent:
ANDRADE-STADLER
Seconded: MALONEY
ANDRADE-STADLER, MALONEY, MAZA, WANG, LEE
NONE
```

→ **Ayes: all five. Noes: NONE. The resolution passed 5–0.**

The tell that caught it: the *same* shape appears on Item 6 of the same meeting, *accepting a donated
tile mural "with gratitude"* — which nobody opposes — while Item 5 renders correctly. **Every vote in
this corpus must be read without `-layout`, or cross-checked against the discussion narrative.** Had this
gone unnoticed it would have published five councilmembers as voting against a pro-immigrant resolution:
a fabrication in the opposite direction, from a genuine source.

🔑 This is the standing rule again, in a new place: **before concluding anything, check what your
extractor KEPT.** Layout mode is not a neutral formatting choice; it reassigns values across labels.

---

## Proposed assignments

### Local Immigration Enforcement — `b9ccee94-ad96-4f10-b655-889d8e5abe92` (4 owed)

**Primary evidence — a recorded, unanimous vote.** 2025-07-28, Item 4: City Council adopted
**Resolution No. R2M25-29**, *"Alhambra condemns aggressive and non-transparent federal immigration
enforcement tactics, reaffirms commitment to constitutional and community safety principles, and directs
proactive local response measures."* Moved ANDRADE-STADLER, seconded MALONEY, **Ayes: all five,
Noes: NONE**. Source: `alhambraca.gov/AgendaCenter/ViewFile/Minutes/_07282025-1433`.

| Member | Chair | Basis |
|---|---|---|
| Adele Andrade-Stadler | **1** | Moved R2M25-29. Discussed her work with **Unión del Barrio** to help immigrant communities and **requested staff prepare a further Resolution** to address additional concerns (2026-02-09). Organized the "No Kings" protests at Alhambra Park. Statement on "extreme Federal Immigration Enforcement tactics" (2026-01-26). |
| Jeff Maloney | **1** | Seconded R2M25-29. 2026-02-09: reaffirmed **"the Council's position that the City would not cooperate with Immigration and Customs Enforcement Officers (ICE)"**; directed staff to look into establishing **"ICE Free Zones"** in Alhambra following LA County; formed a two-member Council subcommittee; said he would write to congressional representatives. |
| Katherine Lee | **2** | Voted aye on R2M25-29 and "supported the Resolution… discussed the need for federal immigration policies to be reformed." 2026-02-09: "supported the subcommittee to focus on immigration enforcement issues and supported a new resolution." ⚠ Moderating signal: asked that the word **"aggressive" in the resolution title be reconsidered**, and echoed "the limitations of local government." |
| Noya Wang | **2** | Voted aye and "spoke in support of the Resolution." 2026-02-09: "supported the Mayor and Vice Mayor on the subcommittee." ⚠ Moderating signal: proposed narrowing the title to **"unwarranted aggressive and non-transparent tactics"** — the added qualifier narrows the condemnation — and echoed "limitations of local government." |

⚠ **1 vs 2 is the judgement call here.** Chair 1's specific mechanisms (refuse *all* detainers; prohibit
employees from sharing status information) are **not** individually evidenced for anyone. Maloney and
Andrade-Stadler are placed at 1 on the strength of unqualified non-cooperation plus active expansion
(ICE Free Zones, a further resolution); Lee and Wang at 2 because both explicitly framed their support
by the limits of local authority and both moved to soften the resolution's language.

### Affordable Housing — `669cac97-66a6-4087-b036-936fbe62efb3` (5 owed)

**Primary evidence:** 2026-02-23, tenant displacement at 110 S. Chapel Ave. / Inclusionary Housing
In-Lieu fund. Source: `…/ViewFile/Minutes/_02232026-1529`.

| Member | Chair | Basis |
|---|---|---|
| Katherine Lee | **2** | Moved to update the Inclusionary Housing In-Lieu fund to fund **tenant relocation assistance of $3,000 per household** for low-to-moderate income residents displaced by new development, paid directly to the new landlord; plus health-and-safety standards and automatic appeals. |
| Adele Andrade-Stadler | **2** | Supported Displaced Tenant Assistance and **"emphasized staff review the Inclusionary Housing In-Lieu fund to provide tenant assistance"**; pressed the developer on including **10% affordable units for Low and Very Low-Income Households**. |
| Jeff Maloney | **2** | Moved staff to examine the In-Lieu fund **and Measure A funds "which could be used to prevent homelessness"** as sources for tenant relocation; discussed "the displacement of residents through development." ⚠ Declined sub-items 1 and 2 as having "no legal path." |
| Noya Wang | **3** | **Resisted repurposing the Inclusionary In-Lieu fund** — warned it would harm the City's RHNA allocation and was "not one of the approved or intended uses" — and instead suggested **developers contribute directly** to tenant relocation. Targeted help, protecting the affordable-housing pipeline. |
| Ross J. Maza | **3** | "Not in favor of sub-items 1 and 2"; emphasized "the responsibility of Council to follow State law" and protecting **the City's certified Housing Element** from an HCD violation finding. Supported only further discussion of Item 3. |

### Residential Zoning — `d4f18138-a2e0-4110-b925-7387d9d0d16d` (2 owed)

**Primary evidence:** 2025-08-25, Item 3 — **SB 79 (Wiener), the Abundant & Affordable Homes Near
Transit Act** (state upzoning near transit, overriding local zoning). Source: `…/Minutes/_08252025-1444`.

| Member | Chair | Basis |
|---|---|---|
| Katherine Lee | **1** | Opposed SB 79 on **"the State's overreach… the local burden of additional housing, and the erosion of democracy"**; stated **"the City of Alhambra officially opposed SB79."** Separately (2026-01-26 / 02-09) sought code changes to "condition or reduce the impact of developments," automatic no-fee appeals on health-and-safety grounds, and objected to "high-density projects in medium density neighborhood zones"; said that if concerns went unaddressed **"all future developments should be put on hold."** |
| Noya Wang | **2** | Critical of SB 79 — "discussed the intention of the bill and **the ways it failed to recognize the specific needs at the local level**." But worked within the City's RHNA obligation rather than blanket opposition, and supported further discussion of Lee's density concerns "in order to collect more information." |

### Public Safety Approach — `e9ebefcd-c496-45e8-b816-a79f8442ba85` (4 owed)

**Primary evidence:** 2026-01-12, Item 14 — purchase of a **Lenco G2 Bearcat Armored Rescue Vehicle**
($123,690), approved **5–0** (Moved ANDRADE-STADLER, Seconded WANG) over a public comment urging Council
to decline it because "militarized equipment… reduce[s] community trust." Source: `…/Minutes/_01122026-1512`.
⚠ **No co-responder, crisis-response or mental-health response team appears anywhere in the 2024–2026
minutes** — so chair 3 has no support for anyone here.

| Member | Chair | Basis |
|---|---|---|
| Adele Andrade-Stadler | **4** | **Moved** the ARV purchase; discussed its use in school lockdowns. |
| Noya Wang | **4** | **Seconded**; discussed uses — officer/citizen rescue, serving search warrants, de-escalation of high-risk situations. |
| Ross J. Maza | **4** | **"Supported the purchase of the vehicle and discussed the costs of armored vehicles."** |
| Katherine Lee | **4** | ⚠ **Weakest of the four — the basis is her aye vote, not a statement.** Her recorded remarks are procedural: the current practice of borrowing ARVs from neighbouring cities, availability of used vs new vehicles, and "the appearance of the vehicle." Flagged rather than smoothed over. |

### Growth and Development Pace — `fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4` (1 owed)

| Member | Chair | Basis |
|---|---|---|
| Jeff Maloney | **3** | Declined to act in ways that would "jeopardize the status of the certified Housing Element"; opposed a stand-alone meeting to condition or reduce development impacts but **supported taking it up in the Strategic Planning Session** (2026-01-26, 2026-02-09). On SB 79 (2025-08-25) noted "the affected area would be very small" and "looked forward to the State Assembly process and the amendments made" — notably **did not** join the letter of opposition. Plan-proactively, not growth-limiting. |

### 🔴 Homelessness Response — `6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f` (3 owed) — **ALL THREE STAY PENDING**

Owed by **Lee, Wang and Maza**. The 2024–2026 minutes contain **no position statement on homelessness
from any of the three**:

* **Lee** — asked a clarifying question about the Police **HOME (Homeless Outreach Mental Evaluation)
  Team** membership (2026-02-23). A question is not a position.
* **Wang** — nothing found.
* **Maza** — nothing found.

The only substantive mention is **Maloney's** (not owed) reference to Measure A funds "which could be
used to prevent homelessness."

**A blank spoke is the correct output.** Per the standing rule, verified absent → leave unassigned;
never *unsure* → assign. These three remain part of the coverage gap and should be re-attempted from a
wider date range or from LA County/SGV sources, not resolved by inference from their colleagues.

---

## Chip

Alhambra's `hasContext` chip in `essentials/src/lib/coverage.js` was flipped to **false** by 1564. If
these 16 rows are applied, **the chip should flip back to true** — all five councilmembers regain
answers. That is a coverage claim that becomes true again, so it must move in the same commit.

## What is NOT claimed

* No source outside `alhambraca.gov` official minutes was used. Free sources only.
* No row reuses any retired citation, and none returns to `sgvtribune.com`.
* Every quoted phrase above was read in the extracted text of the named minutes PDF, and every vote
  tally was re-extracted **without** `-layout` before being trusted.
