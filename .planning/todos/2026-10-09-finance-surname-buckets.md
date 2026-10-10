# The six remaining finance splits — adjudicated 2026-10-09

Follow-on from `CC_0211` / `CC_0212`. Those two retired 11 archived duplicate rows and recovered the
campaign finance stranded on them (Jehlen 3,649 contributions, DiDomenico 8,598, Decker 6,926,
Rogers 2,783). The sweep behind them found **170 inactive rows sharing a first and last name with an
active row, 9 of which hold contributions.** Four are done. These are the remaining six.

**Status 2026-10-09, after `CC_0213`, `CC_0214`, `CC_0215` and `CC_0216`:** attribution is fixed on
all seven affected rows; **Hurtado, Dutra and Dixon hold their own confirmed finance on their
canonical rows**; **John Fleming is merged** (`CC_0215`); and **the 72 disputed bucket sources are
adjudicated** (`CC_0216`). Their duplicate rows are still deliberately **kept, not retired** — see
why below; adjudicating the sources did not change that. The two Indiana leads stay unruled.

## 🔴🔴 THE HEADLINE: FIVE OF THE SIX MUST NOT BE MERGED

**Merging them would have published other people's donations on a real politician's page.** The
money on those rows does not belong to the person named on them.

`confirm-cal-access.ts` matched CAL-ACCESS committees to politicians **by surname**, and attached
every same-surname committee it found to one row. The rows became surname buckets. Measured, with
the committee's own appended forename against the row's forename:

| Row (all `is_active = false`) | Committee name says | Contributions | Dollars |
|---|---|---|---|
| Gil Hurtado | **MELISSA**, ESMERALDA | 476 | $3,441,162 |
| David Patterson | **JOE** ×3 | 1,418 | $2,337,165 |
| Arthur Dixon | **DIANE** ×5, RONDA | 1,746 | $1,885,399 |
| Fernando Dutra | **JOHN** | 1,631 | $1,599,020 |
| John M. Erickson | BRIAN | 323 | $120,037 |
| Angie Reyes English | KEN | 167 | $93,652 |
| Bryan "Bubba" Fish | JONATHAN | 9 | $34,649 |

Melissa Hurtado, Joe Patterson, Diane Dixon and John Dutra are all real California legislators.
**Every one of these is marked `confirmed_by: confirm-cal-access.ts`, not `--ambiguous`.**

Gil Hurtado's row is the clearest case: **24 committees belonging to at least seven different
Hurtados** — Melissa (state senator), Esmeralda, Jewel, G. Sylvia, Ricky, Jaime and Gil — of which
Melissa's three Senate committees hold 2,044 of the 2,061 contributions. Arthur Dixon's row holds 43,
including committees named for the **city** of Dixon ("DIXON CITY COUNCIL", "DIXON UNIFIED SCHOOL
DISTRICT", "BOGUE FOR DIXON CITY COUNCIL") — the surname is also a place name.

🟢 **No voter sees any of this today: all seven affected rows are inactive.** The harm would have been
created by the merge, not by the bug. That is the whole point.

### ⚠ TWO FALSE TRAILS, BOTH WORTH KEEPING

1. **"The politician's forename does not appear in the committee name" is a USELESS predicate.** Most
   CAL-ACCESS committees are named `SURNAME FOR OFFICE YEAR` with no forename at all, so that test
   flags **"NEWSOM FOR CALIFORNIA GOVERNOR 2018" on Gavin Newsom** — and ~$13M of other perfectly
   correct attributions (Muratsuchi, Strickland, Gipson, Irwin, Caloza, Lackey, Bryan, Solache…).
   ▶ The only reliable signal is an **explicit forename that CONFLICTS**, taken from the `;`/`,` tail.
2. **A middle name in `full_name` fakes a conflict.** `KAREN` against "Karen Ruth" Bass, `JOHN`
   against "John M." Erickson, `AMY` against "Amy Thomas" Howorth, `HOLLY` against "Holly J."
   Mitchell, `JANET` against "Janet Keo" Conklin — all five correct, all five flagged until the
   comparison allowed a leading-forename match.

An earlier draft of this note reported 2,614 disagreements corpus-wide. **That number is wrong** and
came from predicate (1); the defensible figure is the table above.

## ✅ THE ONE GENUINE MERGE: JOHN FLEMING — DONE, `CC_0215`, applied 2026-10-09

Retired `8be7e981` into `a750bce8` with a ledger row. 5 answers carried across, 15 duplicates and 17
context rows deleted, the Senate candidacy term and `fec_senate:S6LA00318` re-pointed, the duplicate
image row deleted. The canonical row now holds 21 answers and still reads as holding exactly **one**
current office — the closed candidacy term cannot surface as current, because
`essentials.current_office_holders` filters on `term_end >= CURRENT_DATE`.

### 🔴🔴 THE DECISION WENT TO RUNG 5, AND THE OLD REASONING WAS FACTUALLY WRONG

The canonical row sat at **4** on Season 2 `same-sex-marriage` on this sentence: *"His position is
state authority to restrict SSM, **not a federal constitutional ban**."* **He cosponsored a federal
constitutional ban.**

congress.gov lists `Rep. Fleming, John [R-LA-4]*` as an **original cosponsor** of **H.J.Res.32,
"Marriage Protection Amendment", 114th Congress, 02/12/2015** — one of 37. Its text would write into
the Constitution that marriage *"shall consist only of the union of a man and a woman"*, and that no
constitution may be read to require that marriage **or the legal incidents thereof** be conferred on
any other union.

▶ **RUNG 4 IS EXCLUDED BY THE INSTRUMENT.** Rung 4 requires recognising civil unions; the "legal
incidents" clause bars any requirement to confer them. Rungs 1–3 all permit same-sex marriage.
**Rung 5 is reached by elimination from the document**, not by reading its label.

⚠ The caveat is kept in the voter-facing prose: the amendment denies recognition nationwide rather
than making same-sex marriage a crime, while rung 5's wording says "illegal".

🔴 **BOTH ROWS HAD RESTED ON ontheissues.org — AN AGGREGATOR — FOR A CLAIM THIS STRONG.** The row now
cites the bill text and the cosponsor list. 🔴 **congress.gov answers 403 to curl even with a browser
user-agent; it was read in Playwright.**

🔴 **A DUPLICATE CAN HIDE A WRONG READING, NOT JUST A SPLIT.** The split was the visible problem. The
defect was that the surviving row published an unevidenced chair resting on a sentence the record
contradicts. ▶ **When two rows disagree, do not just pick one — check whether either is right.**

### Rules this merge paid for

- 🔴 **THE PRIMARY KEY DECIDES MOST OF A STANCE MERGE.** `politician_answers` is PK
  `(politician_id, topic_id, season_id)`. Overlapping pairs cannot be re-pointed — the key collides,
  so they are deleted. Only the rows the canonical lacks move. Only an **open-season** disagreement
  is ever an editorial decision.
- 🔴 **THE CLOSED-SEASON HATCH IS FOR MOVING A ROW BETWEEN ROWS OF THE SAME PERSON.** `SET LOCAL
  inform.allow_closed_season_write = 'on'` was needed to re-point 4 Season 1 answers and to delete
  the duplicate's Season 1 rows. No closed-season value, reasoning or source was edited.
- 🔴 **DO NOT COPY `photo_origin_url` ACROSS IN A MERGE.** The retired row's origin was the
  provenance of its own small congressional thumbnail. Attaching it to the canonical row — which
  serves a different, larger portrait — would assert a false source. The duplicate
  `politician_images` row is **deleted**, not moved, or the grid gets two `type='default'` rows.
- 🔴 **`ev_api` HAS NO SELECT ON `politician_id_bridge`**, so a pre-flight that counts it dies with
  `permission denied` on prod while passing under the MCP. Its FK is `NO ACTION`, so the constraint
  is the real guard; the check is now privilege-aware.
- 🟢 **TWO CONTROLS, BOTH WATCHED FAILING FIRST:** a planted `politician_name_aliases` row made the
  CASCADE guard abort, and a planted gate-visible orphan context made the ORPHAN_CONTEXT guard fire.
- **The 2 orphan contexts were deleted** (`homelessness`, `voting-rights`, both Season 1, both with
  no answer at all). Captured first to
  `backend/data/stance-retirement/2026-10-09-cc0215-fleming-orphan-context.json`.

---

### The state before the merge, kept for the record

| | `a750bce8` (active) | `8be7e981` (inactive) |
|---|---|---|
| seat | **Treasurer, Louisiana** (open term) | Candidate for U.S. Senate — Louisiana, `2024-12-13 .. 2026-06-27` |
| stance answers | **15** across 2 seasons | **20** across 2 seasons |
| finance | none | `fec_senate:S6LA00318` |
| photo origin | none | `unitedstates.github.io/images/congress/225` (a congressional portrait) |

**Identity is settled, two sources.** `treasury.la.gov/about/meet-the-treasurer` names "John Fleming,
MD" as Treasurer; Ballotpedia's "John Fleming (Louisiana)" records the Treasurer tenure (2024–),
the 4th Congressional District service, and that **he lost the Republican Senate primary runoff on
2026-06-27** — which is exactly the `term_end` on our inactive row. One man: US Rep → Senate
candidate → State Treasurer.

🔴 **This is NOT the CC_0211/CC_0212 shape and must not be done the same way.** Those retired rows
held *nothing*. This one holds **20 stance answers across two seasons**, against an active row that
holds 15. A merge has to decide what happens where both rows answer the same topic in the same
season, and Season 1 is closed — `inform.closed_season_is_immutable()` will refuse, and the
`inform.allow_closed_season_write` hatch is legitimate only for re-pointing `politician_id` without
touching content ([[reference_duplicate_name_guard_predicate]], the `CC_0186` precedent).

**Open question for the operator: what happens to an overlapping (topic, season) pair?** Nothing
should be guessed here.

### ✅ THE OVERLAP IS MEASURED (2026-10-09) — the decision is one row, not fifteen

The two rows overlap on **15 (topic, season) pairs — every answer the active row holds.** The active
row adds nothing the inactive row lacks. **10 agree. 5 disagree:**

| Season | Topic | Active (Treasurer) | Inactive (Senate candidate) |
|---|---|---|---|
| 1 (closed) | `deportation` | 5 | 4 |
| 1 (closed) | `misinformation` | 4 | 5 |
| 1 (closed) | `same-sex-marriage` | 4 | 5 |
| 1 (closed) | `school-vouchers` | 4 | 5 |
| **2 (open)** | `same-sex-marriage` | **4** | **5** |

🟢 **14 of the 15 overlaps sit in CLOSED Season 1, so they are not editable anyway** — the active
row keeps those values and Season 1 keeps asserting what it was evidenced against. **Exactly ONE
contested pair is in an open season:** Season 2 `same-sex-marriage`, 4 against 5.

The inactive row also holds **5 answers the active row does not**: `campaign-finance`, `childcare`,
`housing`, `tariffs` (Season 1) and `housing` (Season 2).

▶ **So the operator question reduces to two small ones:**
1. Season 2 `same-sex-marriage` — keep the Treasurer row's **4**, or take the Senate-candidate row's **5**?
2. Carry the 5 inactive-only answers across, or leave them behind?

⚠ No value is `0`, so no blank is involved and the `@zero-scope` question does not arise here.

## The two Indiana leads — weak, left alone

- **Michael Thompson** `b01acc58` — `indiana:8112`, committee "Patriots for Mike Thompson",
  33 contributions / $13,035. The active namesake holds no seat and 23 contributions of its own.
  An extremely common name; no evidence either way. **Not ruled.**
- **Jessica Mccormick** `2f1440e0` — `indiana:7997`, committee "McCormick for Indiana",
  2 contributions / $1,594. The active namesake is Councilor, District 16. "McCormick for Indiana"
  reads like a statewide committee, which a district councillor is not. **Not ruled.**

## ✅ ATTRIBUTION FIXED — `CC_0213`, applied 2026-10-09

Detached 159 cal_access sources from the seven buckets and repointed 9 to their real owners.
Published contributions now: Gil Hurtado **0** · David Patterson **0** · Dutra **0** · English **0** ·
Fish **0** · Dixon **11** (`fec_house:H6CA34302` only, out of scope) · Erickson **981** (his own) ·
**Melissa Hurtado 1,577** · **Joe Patterson 1,418**.

The detach is `research_status = 'disputed'`, which `campaignFinanceService.ts:37` excludes from every
read. No contribution row was touched; one `UPDATE` back to `'confirmed'` reverts it.

🟢 **The harm is gone either way now.** Those rows publish nothing, so leaving them unmerged costs a
voter nothing. The merge is tidiness; the attribution was the harm.

## ✅ IDENTITY SETTLED FOR ALL THREE — `CC_0214`, applied 2026-10-09

The section this replaces said the three merges were blocked on **thin identity**, and told the next
session to read the CA SoS roster PDF. The PDF was read. **It was needed for one of the three, and
the other two were already settled inside this database.**

| Pair | What settled it | Needed the PDF? |
|---|---|---|
| Gil Hurtado `1a6190c0` → `75f11f44` | Roster lists `Council: Gil Hurtado, Al Rios, Maria del Pilar Avalos` under **City of South Gate**; the canonical row holds that exact seat (geo_id `0673080`) | **Yes** — and it was corroborated, see below |
| Fernando Dutra `bf91e362` → `99929a73` | **`CA_0185`, 2026-09-23**, already wrote on the inactive row: *"inactive scraped twin of 99929a73 … former Whittier D4 member, left 2026-04-28"* | **No** |
| Arthur Dixon `b8e3727a` → `76d1140a` | FEC candidate `H6CA34302` reads `candidate_first_name = ARTHUR`, `candidate_last_name = DIXON`, HOUSE, California **district 34**, committee **ARTHUR DIXON FOR CONGRESS** (`C00903773`); `ballotpedia.org/Arthur_Dixon` — the canonical row's own origin — records the same candidacy, lost primary 2026-06-02 | **No** |

### 🔴🔴 THE IDENTITY EVIDENCE WAS ALREADY IN THE ROW, ONE TABLE OVER

This note asserted that the inactive rows came from a **statewide** roster and so "name no city".
They each carry an `essentials.politician_contacts` row of `contact_type = city_website`:

- Gil Hurtado's inactive row → `https://www.cityofsouthgate.org`
- Fernando Dutra's inactive row → `https://www.cityofwhittier.org`

▶ **Before sourcing an external document to identify a row, read every table that already points at
it.** The city was in `politician_contacts` the whole time, and a 5.6 MB PDF was fetched to learn it.

### 🔴 TWO CLAIMS IN THIS FILE WERE WRONG ABOUT DIXON

1. *"It cannot settle Dixon — his inactive row never cited the roster, or any source."* Its `source`
   column reads `federal_2026_bulk_seed`, and it holds a `confirmed` FEC source.
2. *"his 11 remaining contributions come from an FEC CA-34 committee whose attribution is itself
   unverified."* The attribution is an **FEC candidate-ID match that names him in full** — the
   strongest evidence of the three, not the weakest. Dixon was the easy one.

⚠ **THE ROSTER IS AUTHORITATIVE FOR THE CITY AND STALE FOR THE SEAT.** The 2025 edition still lists
Fernando Dutra on the Whittier council. He lost on 2026-04-14 to Aida Susie Macedo. `CA_0185` hit the
same trap with George Dotson and says so. Read the edition date before treating the roster as current.

### What `CC_0214` did, and what it deliberately did not do

Re-pointed the **8 `confirmed` finance sources** to the canonical rows — Hurtado 4, Dutra 3, Dixon 1.
Every one names its owner in full (`HURTADO FOR CITY COUNCIL 2020; GIL`, `DUTRA FOR CITY COUNCIL
2026; FERNANDO`, `ARTHUR DIXON FOR CONGRESS`).

🔴 **THE PRIZE WAS MUCH SMALLER THAN THIS FILE IMPLIED. Measured before the migration:**

| Canonical row | Confirmed sources moved | Contributions they carry |
|---|---|---|
| Gil Hurtado | 4 | **0** |
| Fernando Dutra | 3 | **0** |
| Arthur Dixon | 1 | **11 — $12,750** |

Two of the three merges move **no money at all**: those people's own committees hold no contribution
rows in this database. ▶ **A $12.2M "split" figure was a LEAD about a bucket, never a loss figure for
the person.** The $12,750 on Dixon is the whole voter-facing gain.

🔴 **THE THREE INACTIVE ROWS WERE KEPT, NOT RETIRED** — against the `CC_0211` / `CC_0212` pattern.
They still hold **72 `disputed` sources** (15 / 14 / 43). `politician_sources.essentials_politician_id`
is NOT NULL and `filed_report_summaries` holds a RESTRICT FK, so deleting a row forces its sources
either **onto a live politician** — re-creating the exact harm `CC_0213` removed — or **out of
existence**, which destroys `CC_0213`'s one-UPDATE revert path. Nothing is gained by the delete: an
inactive row publishes nothing. ▶ Retire them once the disputed buckets are themselves adjudicated.

🟢 All five CASCADE / SET NULL FKs measured **zero** on all six rows, and the migration asserts it, so
a later session inherits a measured zero instead of an assumption.

🟢 **A NEGATIVE CONTROL WAS RUN BEFORE APPLYING.** One `disputed` bucket source was shoved onto the
live Dixon row inside a transaction; the gate raised *"1 non-confirmed sources reached a LIVE
politician"* and the tamper rolled back. The guard that matters was watched failing first.

## ▶ WHAT IS STILL OPEN

1. ✅ **John Fleming is done** — `CC_0215`, applied 2026-10-09. See the section above.
2. ✅ **The 72 disputed bucket sources are done** — `CC_0216`, applied 2026-10-09. See the section
   below. ⚠ It did NOT unblock retirement, which the line here used to predict it would: 62 of the
   72 have no owner in this corpus, so they stay on the bucket rows and the RESTRICT/NOT NULL
   problem is unchanged. What it bought is that nobody has to adjudicate them again.
   ▶ Still open, and NOT touched by `CC_0216`: the **other four rows `CC_0213` detached** — David
   Patterson (56), John M. Erickson (13), Angie Reyes English (12) and Bryan "Bubba" Fish. And
   corpus-wide there are **1,486 disputed `cal_access` sources across 319 politicians**, many of
   them on ACTIVE rows (Francis De Leon Sanchez 80, Traci Park 47, Pat Wilson 35, Grant Parks 22).
   Whether those are surname buckets of the same shape is unmeasured.
3. **Hurtado's and Dutra's own contributions were never ingested.** Their committees exist as sources
   and hold zero rows. That is a CAL-ACCESS ingestion gap, not a merge problem.
4. The two Indiana leads, still unruled.

### ⚠ One item from the old "recommended order" is already done

It said the real defect is in `confirm-cal-access.ts` and should be fixed. **That script no longer
exists** — it was deleted on 2026-09-23. A CI job guards its return:
`backend/scripts/check-cal-access-predicate.mjs`, wired as **"cal-access predicate tripwire"** at
`.github/workflows/ci.yml:340`, which fails if the file comes back without a replaced predicate.
The rest of that order still holds: **fix attribution first, merge second** — detaching is reversible
and invisible, publishing is neither.

## ✅ THE 72 ADJUDICATED — `CC_0216`, applied 2026-10-09

The answer is **10 and 62**. Ten sources belong to a politician this corpus already holds. Sixty-two
belong to people it does not, so there is nowhere for them to go and nothing to publish.

### 🔴🔴 THE PRIZE WAS A LIVE ASSEMBLYMEMBER PUBLISHING NOTHING

**Diane B. Dixon** `9aa10096` — California Assembly Member, AD-72, ACTIVE — held **zero finance
sources**. Eight of Arthur Dixon's 43 are hers: **3,322 contributions, $3,783,054.16.** Her live API
summary returned `no_data` before this and now returns four cycles.

🟢 **SEVEN OF THE EIGHT ARE NAMED BY CAL-ACCESS ITSELF.** The Secretary of State's **candidate**
detail page — `/Campaign/Candidates/Detail.aspx?id=<candidate filer id>` — lists a candidate's own
committees by filer ID. For `DIXON, DIANE` that is filer **1418515**, and it names 1418525, 1456771,
1443172, 1438441, 1477047, 1435365 and 1362246.

▶ **THIS IS THE TOOL THIS WHOLE WORKLIST WAS MISSING.** Every earlier pass reasoned from the
*committee* page, which never names the candidate, and so fell back to reading the committee title —
which is exactly the surname-matching defect that created the buckets. The route is:
`/Campaign/Candidates/list.aspx?view=name&letter=<X>` → the candidate → their committees.
- ⚠ It covers **state** candidates. A purely local filer will not appear, and a candidate who left
  before ~2005 (John Dutra) is no longer listed at all.
- 🔴 **cal-access.sos.ca.gov sits behind Incapsula, which answers `curl` with HTTP 200 and a
  212-byte script stub.** Playwright is refused too *until you load the homepage first*; after that
  every page works in the same context. Same family as the WAF rule already in memory.

🔴 **THE EIGHTH, 1480126 (791 contributions, $798,783.92), IS NOT ON THAT PAGE**, so it was settled
on three independent agreeing signals instead:
1. explicit forename DIANE, with no conflicting forename anywhere;
2. **filer phone (949) 858-7448, byte-identical to 1438441**, which the candidate page does confirm
   as hers, for the same office one cycle earlier;
3. **donor-name overlap with controls** — of its 583 distinct donors, her seven confirmed committees
   share **12.4%–62.8%**; unrelated committees from the same buckets share **0.0%–4.4%**.

⚠ **THE OVERLAP QUERY WAS BROKEN ON ITS FIRST RUN AND LOOKED FINE.** `contributions.donor_id` is
NULL on every CAL-ACCESS row here, so joining on it returned a **uniform zero for all nine
committees**. `donor_name_normalized` is the populated column. A uniform answer is a broken
detector, and it was the *controls* — not the subject — that showed the rewritten query could
discriminate at all.

### 🔴🔴 `CC_0213` WAS WRONG ABOUT ONE COMMITTEE, AND THIS REVERSES IT

That migration held back **1456951 "VALLEY FAMILIES FOR MELISSA HURTADO FOR SENATE 2026"** (467
contributions, **$3,431,362.52**) because the name reads like outside spending, and said its
`source_type` "needs a human ruling". **CAL-ACCESS lists it on Melissa Hurtado's own candidate page**
(filer 1401463), beside HURTADO FOR SENATE 2022 and 2018. It is her **controlled committee**. It is
restored to `confirmed`, and her live summary now carries the 2026 cycle.

▶ **A COMMITTEE NAMED LIKE A SUPPORT GROUP CAN STILL BE THE CANDIDATE'S OWN.** The candidate page
answers it; the title does not — in either direction. (Its total is mostly party transfers,
`ENTITY_CD = 'PTY'`: California Democratic Party $400,000, county central committees $100,000 each.)

The other one is the genuine article: **1447993 "COALITION OF BUSINESS ORGANIZATIONS SUPPORTING
SENATOR MELISSA HURTADO 2022"** (8 / $344,843.80) is **absent** from her candidate page. It moved to
her row typed `ie_committee`.

🔴 **IT IS DELIBERATELY NOT `confirmed`, AND THAT IS A MEASURED DISPLAY BUG, NOT CAUTION.**
`getOutsideSpendingForPolitician` scopes its `ie_all_sources` CTE to **`source_system = 'la_socrata'`**
and labels committees from **`notes::jsonb->>'cmt_nm'`**, a key CAL-ACCESS notes do not carry — while
the committee-list CTE has **no** source_system filter. A `confirmed` cal_access `ie_committee` row
therefore renders as an **unnamed card showing $0**. Held at `not_applicable`; verified against the
live API that `outside_spending.committees` is `[]`. One UPDATE turns it on once that function is
widened. ▶ **That widening is the open follow-up this created.**

### The 62, and why they end at `not_applicable`

Operator ruling 2026-10-09: `not_applicable`, not `disputed`. `disputed` reads as *contested and
unresolved* and would invite the next session to redo this research. `indianaAdapter.ts:772` treats
the two identically ("the wrong committee, and their rows are dropped") and every finance read
filters on `confirmed`, so **no voter-facing value changes either way** — the difference is that the
record now says the work was done. Each row carries `adjudicated_by` and `adjudication` in its notes.

- **Arthur Dixon 35.** 🟢 ~24 are candidates in the **CITY of Dixon, California** — Arnold,
  Batchelor, Bird, Bogue, Castanon, Ceremello, Di Paola, Dingman, Fink, Graham, Hendershot, Janisch,
  McCaffrey, McCluskey, Minnema, Swanson, Thiessen, Young. **We hold no government named Dixon**, so
  not one of them can be in this corpus — `SELECT … FROM essentials.governments WHERE name ILIKE
  '%dixon%'` returning empty settled two dozen rows in one query. ▶ **When a surname is also a place
  name, ask whether the place is seeded before researching the people.** The rest are Julian, Rich,
  Linda, Richard, Fredrisha, Ken, Karen L. and Ronda Dixon.
- **Gil Hurtado 13.** Esmeralda, Jewel, G. Sylvia, Jaime, Ricky Hurtado. None held.
- **Fernando Dutra 14.** John, Jimmy, Joe M., Dominic, Clancy Dutra. None held. John Dutra's two
  committees hold 1,983 of the bucket's contributions and he left the Assembly in 2004.

### Two controls, both watched failing first

- plant a 9th `confirmed` cal_access committee on Diane's **live** row →
  `CC_0216: Diane B. Dixon holds 9 confirmed committees, expected 8`.
- flip one of the 72 out of `disputed` → `CC_0216: 1 of the 72 are not disputed cal_access sources`.

Each failed at the gate it was aimed at, not at an earlier one, and both rollbacks were re-measured
before applying. ⚠ The first dry run died with **`invalid input syntax for type json`**: a guard read
`notes::jsonb` across *every* live politician's cal_access sources, and notes elsewhere in the corpus
do not all parse. ▶ **A guard must not depend on data it did not put there** — it is scoped to the
72 source ids now. The "nothing was touched" check is scoped the same way, because asking it of the
whole `contributions` table exceeds the statement timeout, as `CC_0213` already recorded.
