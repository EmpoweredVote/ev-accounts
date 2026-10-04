# Knight Cities — stance programme tracker

The seeding programme ([`PROGRAM.md`](./PROGRAM.md)) deliberately excluded stances: *"No stances —
those are the next program."* This is that programme. **Update this file at the end of every
session.**

Standard: `docs/superpowers/specs/2026-09-23-stance-program-design.md`. Pipeline: the
`research-stances` skill. Every row goes to the admin review queue; nothing auto-publishes.

## Measured scope, 2026-10-02

| Tranche | Governments | Seated people | Holding a Season 2 chair before this programme |
| --- | --- | --- | --- |
| Cities | 25 | **287** | 20 (Long Beach 9, San José 11) + Detroit 1 |
| State legislatures | 16 | **2,551** | 171 (CA 116, NC 53) |
| Counties | 21 | **~302** | Miami-Dade only (13 rows) |

Order is **cities → state legislators → counties** (operator, 2026-10-02). State legislators have
far better evidence per row, but many lack portraits, and the municipal tier is the one the
programme is for.

## Slice status

| # | Slice | Members | Rows | Scored | Batch |
| --- | --- | --- | --- | --- | --- |
| 1 | Charlotte NC | 12 | 420 | 5 | `2026-10-02-knight-clt-city` (PR #856) |
| 2 | Bradenton, Miami, Tallahassee FL | 17 | 595 | 2 | `2026-10-03-knight-fl-cities` (PR #857) |
| 3 | Duluth, Saint Paul MN | 18 | 630 | — | `2026-10-04-knight-mn-cities` — **OPEN** |

Seven chairs from 29 members. 🔴 **A low yield was the TOOLING, not the world** — re-mining with a
publisher-agnostic link extractor took Charlotte 3 → 5 and Florida 0 → 2, and attributed passages
from 22 → 122 in Florida. Price the next slice from these numbers, not from the first pass.

✅ **Slices 1 and 2 are merged** (2026-10-04): PR #855 (verifier fix), then #857, then #856. #856 had
cherry-picked only half of #855 and conflicted once #855 landed; the base was merged into it and both
verifier files were resolved to master, which is a strict superset. Charlotte’s five and Florida’s two
sit in the admin review queue awaiting human approval.

## Slice 3 — Duluth and Saint Paul, Minnesota (opened 2026-10-04)

- **18 seated people**: Duluth 9 councilors + Mayor Reinert; Saint Paul 7 councilmembers + Mayor Her.
  35 local ladders pinned into the open season (Season 2, 60 pinned, 35 at `local`). **630 rows.**
- **Baseline measured, not assumed: zero** `politician_answers` rows in the open season for all 18.
  A positive control confirmed the query shape returns rows for other politicians, so the zero is real.
- Leases: `place:2717000` (Duluth) and `place:2758000` (Saint Paul).
- Branch `knight/stances-mn`; batch `backend/data/stance-research/2026-10-04-knight-mn-cities`.

### Why Minnesota, and the claim the scope review must test FIRST

Charlotte spent 216 of its 420 rows on scope blanks, and Florida 306 of 595, because both states
preempt the whole field for firearms, municipal wages and rent regulation. Those rows prove a city
cannot act; they seat nobody.

Minnesota is expected to be the opposite case. Saint Paul is believed to have enacted **both** a rent
stabilisation ordinance and a municipal minimum wage — which, if true, makes those ladders live
levers carrying recorded votes and recorded member statements.

🔴 **NEITHER CLAIM HAS BEEN VERIFIED AGAINST A STATUTE OR AN ORDINANCE. It is the reason the slice
was chosen, so it is also the first thing that can make the choice wrong.** Read the Minnesota
preemption statutes and the Saint Paul ordinance text before researching any row, exactly as
§14-409.40 and §790.33 were read. If the claim fails, this slice reverts to the NC/FL shape and the
yield estimate must come down with it.

⚠ **Saint Paul's mayor reads as Kaohly Her, `is_incumbent` true.** Confirm the current officeholder
against the city's own page before citing the office — a roster label says how someone arrived, not
what they hold now, and a departed official's URL can serve their successor.

### Outlets to profile before the sweep — none yet checked for reachability

MPR News · MinnPost · Minnesota Reformer · Sahan Journal · Racket · Duluth News Tribune ·
Saint Paul Pioneer Press. Run `sweep.py` (name x topic) **and** `small_outlet.py` (name only) and
merge: query breadth must match outlet size in both directions. Expect the two dailies to be
paywalled, as the Charlotte Observer was.

---

## 🔴🔴 Rules this programme has already paid for

1. 🔴🔴 **MUNICIPAL EVIDENCE IS LOCAL REPORTING, NOT THE VOTE RECORD** (operator, 2026-10-02 —
   and the pilot confirmed it). Roll calls are the *state legislature* method. Every one of
   Charlotte's divided policy votes failed as chair evidence, each for a different reason, and
   each refusal is citable from the instrument's own text:
   - **Charlotte Future 2040 Plan** (6-5) — spans nine policy areas and adopts a section the
     document itself calls aspirational.
   - **Unified Development Ordinance** (6-4) — consolidates **eight** ordinances in one vote
     (zoning, subdivision, streets, trees, stormwater, floodplain, driveways, erosion).
   - **Tree Ordinance amendment** (9-1) — the agenda calls it minor: how penalty money may be
     spent, numbering corrections, two stray words deleted.
   - **Data-centre moratorium** — passed **11-0 twice**, which C46 refuses as a position.
   ▶ **Read the agenda item text before trusting a vote title.** Doing so stopped four wrong rows.

2. 🔴🔴 **SEARCH BY NAME *AND* TOPIC. A NAME-ONLY SWEEP IS UNDER-POWERED AND LOOKS LIKE A
   FINDING.** An outlet's search returns its top ~25 results for a person, which is election and
   process coverage. Adding the topic term surfaced **9-15 new articles per query**
   (Driggs+transit 15, Watlington+housing 11, Ajmera+housing 9). The first pass reported a thin
   corpus and that conclusion was partly an artifact of the query.

3. 🔴 **A SURNAME IS NOT A PERSON, AND THE COLLISIONS ARE NOT POLITICIANS.** The name-only corpus
   matched **Kelly Lee Owens** (musician), **Jessica Lea Mayfield** (musician), **Michael Mayo**
   (jazz singer) and **Baker Mayfield**. An article counts only when the name matches as a
   **phrase**; a surname is enough only *within* an article already validated that way.

4. 🔴🔴 **SCOPE IS A PER-RUNG QUESTION, AND NORTH CAROLINA REMOVES RUNGS RATHER THAN TOPICS.**
   Verified against the statutes, not assumed:
   - **§14-409.40(a)-(b)** preempts *the entire field* of firearm regulation → `gun-policy` blank.
   - **§95-25.1(d)** preempts local wage rules **but exempts a city's own employees** → a vote
     raising city staff pay is **not** `minimum-wage` evidence.
   - **§42-14.1(a)** bars rent regulation, **but (c)(2) and (c)(4) allow it on subsidised or
     city-funded property** → chairs 1-3 unavailable, **chair 4 survives**, and chair 5 cannot be
     inferred from the absence of an ordinance the law forbids.
   - **§160A-205.2(a)-(b)** bars limiting federal immigration enforcement or withholding status
     information → `local-immigration` **chairs 1 and 2 removed**; chair 4 turns on detainers,
     which are the Sheriff's.
   - **§163-292** (election method) and **§163-278.13** (contribution limits) are state levers.
   ▶ Scope blanks are a fact about the **office**, identical for every member of the body, so
   verify once and template them. 216 of Charlotte's 420 rows are these.

5. 🔴 **THE LADDER AND THE QUESTIONNAIRE OFTEN ASK DIFFERENT QUESTIONS.** WFAE's 2025 climate
   survey produced substantive written answers from Mayo and Owens — on tree canopy, cool roofs
   and shaded bus stops — while the `climate-change` ladder asks about clean-energy mandates and
   subsidies. Substantive evidence that answers a different question seats nothing.

6. ⚠ **A STUDY CALL AND A DOUBT ARE BOTH REFUSALS.** Graham's call for an independent I-77 study
   is C47. Driggs asking how much of Charlotte's climate the city can affect questions efficacy,
   not policy — reading either as a chair would be a confident wrong row.

## Toolchain

🟢 **`backend/scripts/stance-news/`** — the sweep and mining scripts, with a README stating the
nine rules each one encodes. Run both `sweep.py` (name x topic) and `small_outlet.py` (name only)
and merge: query breadth must match outlet size in both directions. Start there for a new city;
only the outlet list and the state statute review are per-slice.

## Access notes

- 🟢 **Legistar's Web API is public and keyless** — `webapi.legistar.com/v1/charlottenc`. Gives
  per-member roll calls. The event-item id **is `MatterHistoryId`**; there is no
  `MatterHistoryEventItemId`, and reading for one returns a silent zero on every matter.
- 🔴 **`charlottenc.gov` 403s a Chrome UA on curl's TLS fingerprint** (449 bytes) and serves
  **bare curl** (286 KB) *and* the verifier's own `EmpoweredVoteBot` UA. Python `urllib` is
  refused whatever UA it sends. Its planning pages return **HTTP 200 carrying an Akamai
  challenge**, so the Strategic Mobility Plan and Strategic Energy Action Plan could not be read.
- Reachable outlets: **WFAE** (best; has per-person tag pages), **Queen City Nerve**, **WCNC**,
  **The Charlotte Post**. **Axios Charlotte 403s.** The Charlotte Observer is paywalled.
- 🔴 **vote411.org and thevoterguide.org cannot be cited on any row** — LWV terms.

## Open

- 🔴 **LADDER DEFECTS FOR SEASON 3 — written up for Chris Andrews:**
  [`.planning/todos/2026-10-03-local-ladder-defects-season-3.md`](../todos/2026-10-03-local-ladder-defects-season-3.md).
  Seven asks. The costliest by far is `public-safety-approach`, whose chairs 1 and 3 do not
  separate a member who funds both police and prevention — **7 of Charlotte's 12 spoke
  substantively on it and none could be seated.**
- ▶ **Campaign-site pass not yet run.** Only Ajmera's was read. Watlington's and Graham's are live
  on guessed URLs alone, so more exist; Ballotpedia lists each member's campaign URL. First-person
  issue pages are the most chair-shaped source still untouched.

- ▶ **21 cities remain.** The sweep scripts are generic; only the outlet list and the preemption
  review are per-state.
- ▶ **PR #855** fixes a verifier defect this wave exposed: a stored name carrying a diacritic the
  source spells without (`Reneé` vs `Renee`) failed `checkNameProximity` although the snippet
  matched, and `TITLE_PATTERN` lacked the two-word `council member`. Cities work depends on it.
- ▶ Charlotte's three scored rows await human approval in the admin review queue.
