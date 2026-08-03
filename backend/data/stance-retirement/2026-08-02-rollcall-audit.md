# Roll-call citation pass — checking asserted votes against the official record

**Scope:** every citation to a machine-readable roll-call record — **1,706 row-citations, 233 records,
4 formats** (US House clerk XML, US Senate LIS XML, Maine `rollcall.asp`, Wisconsin Assembly/Senate).

**Why this family alone.** Every other pass in this workstream asks whether a page exists and whether
it mentions the right things. A roll call records the measure **and how each member voted**, so
"voted YES on X" can be checked end to end — and a row that cites a real roll call for the wrong bill,
or asserts a vote its subject could not have cast, is invisible to reachability, name-matching and
quote-matching alike.

## Result

| verdict | n | |
|---|---|---|
| **VOTE_CONFIRMED** | **594** | asserted direction matches the official record |
| PROCEDURAL_NOT_COMPARED | 523 | motion is an amendment / cloture / ONTP — not mechanically comparable |
| ROW_NAMES_NO_MEASURE | 346 | row describes the vote in prose without a bill number |
| RECORD_HAS_NO_MEASURE | 108 | nomination votes and the like |
| NO_DIRECTION | 52 | measure named, direction not pinnable to it |
| AMBIGUOUS_MEMBER | 30 | two members share a surname and party |
| 🔴 **MEASURE_MISMATCH** | **29** | the cited roll call is for a bill the row never names |
| 🔴 **MEMBER_ABSENT** | **23** | the member is not in the roll call |
| RECORDED_NOT_VOTING | 1 | (row is correct — see below) |
| **VOTE_CONTRADICTED** | **0** | |

**594 confirmed against the official record and zero contradictions** is the largest positive
verification this workstream has produced. The two red rows are the findings.

---

## 🔴 Finding 1 — 20 rows assert a US House vote the member could not have cast

The strongest defect found anywhere in this workstream, because the official record settles it.

| member | roll-call years asserted | rows | in office since |
|---|---|---|---|
| **Val Hoyle** | 2017, 2019, 2021 ×4, 2022 ×4 | 11 | Jan **2023** |
| **Andrea Salinas** | 2021 ×2, 2022 ×3 | 5 | Jan **2023** |
| **Cliff Bentz** | 2017 ×2 | 2 | Jan **2021** |

Proof is internal to the records, not assumed: each roll call lists the whole chamber (431–434 votes),
and the Oregon delegation in the 2021 and 2022 records is **Bentz, Blumenauer, Bonamici, DeFazio,
Schrader** — no Hoyle, no Salinas. Both appear normally in the 2023 and 2024 records. Bentz likewise
appears from 2021 on and not in 2017.

One row states the contradiction in its own sentence:

> "Hoyle voted YES on Inflation Reduction Act (2022) with $369B in climate investments; **as Labor
> Commissioner** advocated for green jobs transition."

She was Oregon Labor Commissioner in 2022 *because she was not yet in Congress*.

These are not citation defects that a re-point can fix — the row asserts something that did not happen.
They need correction or retirement, which is an operator call, so nothing here is migrated.

## 🔴 Finding 2 — 29 rows cite a roll call for a bill they never name

| cited record | row actually discusses | rows |
|---|---|---|
| `H R 1446` (Enhanced Background Checks) | H.R. 1, For the People Act | 4 |
| `H J RES 24` | H.R. 734 | 4 |
| `H R 5293` (appropriations) | H.R. 4 / H.R. 1 | 2 |
| `S. 5` | H.R. 1 | 2 |
| `H.R. 5376` | H.R. 1 | 2 |
| `H R 8466` | H.R. 8404 | 2 |
| `H R 3397` | H.R. 8035 | 2 |
| `H R 1280` | H.R. 7120 / H.R. 5 | 3 |
| 9 more, 1 row each | | 8 |

Example: *"Bentz voted NO on H.R. 1 (For the People Act, 2021)…"* cited to
`clerk.house.gov/evs/2021/roll073.xml`, which is the roll call for **H R 1446**, a background-checks
bill. A reader who clicks it lands on a vote about something else.

⚠ **`H R 1280` ← `H.R. 7120` is the mildest case and worth distinguishing**: that is the George Floyd
Justice in Policing Act **renumbered** between the 116th and 117th Congresses. The vote is the right
vote; the number the row cites is the previous Congress's. Not the same error as `H R 1446` vs `H.R. 1`.

---

## 🔴 The detector was wrong five ways, and finding that out was most of the work

The first cut reported **4 VOTE_CONTRADICTED**. Hand-checking every one against the record found
**three were my own bugs and the fourth was not a defect at all.** After the fixes: **zero.**

| bug | what it produced | evidence |
|---|---|---|
| **compared direction on procedural motions** | Sean Faircloth "contradicted" | on `ACC MAJ OUGHT NOT TO PASS REP` a **YES vote kills the bill**; the row described exactly that. Only ~40% of these records are a plain passage vote. |
| **took the first direction verb in the clause** | Jill Duson "contradicted" | *"Voted Nay on accepting the minority report **and Yea on the majority** report"* — one clause, both directions |
| **missed present-tense "vote Yea"** | Caldwell Jackson "contradicted" | row says he was "the only one … to vote Yea"; record says YES |
| **compound surnames** | Van Hollen, Blunt Rochester, Cortez Masto reported absent | surname taken as the last token only |
| **the clerk's disambiguating suffix** | Val Hoyle reported absent from 2023 and 2024 votes she is in | House XML writes `Hoyle (OR)` when a surname is shared — this one nearly **buried the real finding under a parser bug** |

Two more parser defects, both caught by cross-checking counts against chamber size:

- **Wisconsin Assembly**: the column header `A N NV NAME` repeats mid-page and was being absorbed into
  the name, yielding `"N NV NAME Y ALLEN"`. Scott Allen and Karen Hurd were reported absent from a roll
  call they are plainly in.
- **Wisconsin Senate** is not a grid at all — `AYES - 18 NAME NAME … NAYS - 15 …`, no party, no
  per-name cast. It parsed to zero votes. ⚠ It is now matched against the **verbatim block text**
  rather than tokenised, because `BRADLEY JAGLER` is two senators and `HABUSH SINYKIN` is one, and
  nothing in the page distinguishes them.

The rebuilt matcher **abstains by design**: `PROCEDURAL_NOT_COMPARED`, `NO_DIRECTION`,
`ROW_NAMES_NO_MEASURE`, `AMBIGUOUS_MEMBER` and `RECORD_HAS_NO_MEASURE` are all "cannot tell" outcomes,
and together they are 1,059 of 1,706. That is the price of the 594 confirmations and the two findings
being trustworthy.

## Two things I reported earlier that this pass overturns

- 🔴 **James Dill is NOT a defect.** The OK-sample write-up flagged his row as describing roll call
  #815 while citing #828. It cites **both** — two separate source URLs on the same row, one for the
  enactment vote and one for the veto reconsideration. The single-citation view could not see that.
- **A dedicated roll-call-number check found zero mismatches** across all 1,706 citations. Where a row
  names "Roll Call #715", it cites #715.

The one `RECORDED_NOT_VOTING` is also a false alarm: Grayson Lookner's row says *"**Was absent** for the
LD 70 … vote … but voted for enactment of LD 1937"* — accurate on both counts; the detector matched
the second clause's "voted for".

## Not fixed, and why

**30 AMBIGUOUS_MEMBER** — Maine has two Woods (Peter of Greene, Stephen of Norway, both R) and party
does not separate them; town or district would. Left unresolved rather than guessed.

**2 Robin Vos rows** — the Wisconsin Assembly grid lists the Speaker as `SPEAKER`, not by surname, so
his vote is not matchable by name. A format limitation, not an absence.

## What is owed

1. **20 pre-tenure vote assertions** — correct or retire. ⏳ Operator decision; they assert something
   that did not happen, so a citation change cannot fix them.
2. **29 wrong-bill roll-call citations** — re-point to the roll call for the bill the row names, where
   one exists. Mechanical once the intended bill is confirmed, but it needs the intended vote
   identified per row, so it is a reading queue.
3. ⚠ **The pre-tenure error is unlikely to be confined to roll-call citations.** Nothing here tests the
   many rows that assert a vote without citing a roll call at all. A cheap proxy: for every row naming
   a year or Congress, compare against the politician's term start. That would be a new detector, and
   on this evidence it is the highest-value one left.

Artifacts: `2026-08-02-rollcall-rows.json` (the 1,706 citations) · `-rollcall-records.jsonl` (233 parsed
records) · `-rollcall-verify.json` (per-citation verdict, member match, motion class) ·
`scripts/_tmp-rollcall-{export,verify,wi,match2}.mjs`.
