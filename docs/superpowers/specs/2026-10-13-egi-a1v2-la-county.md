# education-gender-identity — A1 v2 LA County wave (offline)

Date: 2026-10-13. For Chris Andrews. **Offline only: nothing was written to prod.** No revision row, no season
pin, no `politician_answers` / `politician_context`, no review-queue row, no `source_snapshots` row
(`coding:snapshot` ran without `--apply`). Prod was read through the session pooler with
`SET default_transaction_read_only = on`. Steward lease `county:06037` held for the wave.

Ladder, rules and pipeline: exactly as in the three-county wave
([`2026-10-08-egi-a1v2-broad-research.md`](2026-10-08-egi-a1v2-broad-research.md), PR #950) — A1 v2, codebook
0.4 + the 2026-10-08 rulings, alias key `egi-draft-a1v2` with no annex, one Opus coder per person. Roles: school =
record, state = record, federal = own words, local = own words.

| rung | text |
|---:|---|
| 1 | Require staff to keep a student's gender identity from parents unless the student consents. |
| 2 | Forbid rules that require schools to tell parents. |
| 3 | Require schools to tell parents when parents ask. |
| 4 | Require schools to notify parents. |
| 5 | Require parental permission before staff use a different name or pronouns. |

Why LA: Chris asked for a wave in a state whose law sits on the student side before judging A1 v2. California
AB 1955 (2024) is that law.

## Result in one paragraph

Of **797 people** (judges excluded, by ruling), the coder seated **23**, all at **rung 2**: every LA County state
legislator who voted Aye on the final text of **AB 1955** (Senate 29-8, 2024-06-13; Assembly concurrence 61-16,
2024-06-27). These are the **first seats on the student side** of A1 v2 in any wave. **Rung 1 and rung 3 are still
empty in all four counties.** Again, **every seat rests on a record, and own words seated nothing**: one No vote
(Lackey) and one local statement (Anthony) were coded direction-only. 13 sitting legislators have no record
because they took office in December 2024, after the only vote. No school board, city council or the Board of
Supervisors voted on this question; no federal incumbent made a findable statement on it.

## 1. Seat table

Counts are people. Full per-person rows with the coder's reasoning: `backend/data/stance-research/2026-10-13-egi-a1v2-la/seat-table.csv`.

| status | level | basis | n | r1 | r2 | r3 | r4 | r5 | dir-only | no-source |
|---|---|---|---|---|---|---|---|---|---|---|
| incumbent | state | record | 37 | · | **23** | · | · | · | 1 | 13 ¹ |
| incumbent | school | record | 164 | · | · | · | · | · | 1 | 163 |
| incumbent | federal | own words | 19 | · | · | · | · | · | · | 19 |
| incumbent | local | own words | 346 | · | · | · | · | · | 1 | 345 |
| challenger | state | record | 40 | · | · | · | · | · | 9 | 31 |
| challenger | school | record | 44 | · | · | · | · | · | 1 | 43 |
| challenger | federal | own words | 18 | · | · | · | · | · | 4 | 14 |
| challenger | local | own words | 129 | · | · | · | · | · | · | 129 |
| **all** | | | **797** | · | **23** | · | · | · | 17 | 757 |

¹ 12 took office in December 2024 (no vote on AB 1955 and no later instrument exists); Henry Stern was
No Vote Recorded on the Senate final vote.

Challengers include 205 candidates with **no `politicians` row** (`race_candidates.politician_id` is null — most
CA Assembly and Senate challengers are stored this way). The earlier roster query dropped them; this wave adds
them by name (`roster.sql`, `kind = candidate_unlinked`). They cannot be coded by the pipeline (the bundle needs a
politician id), which did not matter here: no challenger statement named a rule.

## 2. The instrument

**CA AB 1955 (2023-24), "SAFETY Act", Chapter 95, Statutes of 2024.** Operative clauses (chaptered text,
`saved-pages/ca-2024-AB1955-chaptered.txt`):

- Ed Code 220.3(a): an employee "shall not be required to disclose any information related to a pupil's sexual
  orientation, gender identity, or gender expression to any other person without the pupil's consent unless
  otherwise required by state or federal law."
- Ed Code 220.5(a): a school district, county office, charter school or board member "shall not enact or enforce
  any policy, rule, or administrative regulation that would require an employee or a contractor to disclose" the
  same information without the pupil's consent.

The coder placed 220.5 on rung 2 for all 23 Aye votes, and read the bill as single-subject (see reviewer flag 1).
It did not place it on rung 1: the law forbids *requiring* disclosure; it does not require staff to keep the
information from parents.

| vote | date | tally | used? |
|---|---|---|---|
| Assembly third reading (consent calendar) | 2024-04-25 | 75-0 | **No — a different bill.** As introduced, AB 1955 was "Pupil health: school-based health services". The Senate replaced the whole text on 2024-05-22. |
| Senate third reading | 2024-06-13 | 29-8 | Yes |
| Assembly, two procedural "appeal the decision of the chair" votes | 2024-06-27 | 55-15, 57-12 | No (procedural) |
| Assembly concurrence in Senate amendments | 2024-06-27 | 61-16 | Yes |

Both votes used are contested (>20% No), so the near-unanimous-vote rule does not apply.

Other California instruments found, none coded: AB 1314 (2023, parental notification within three days — died
without a committee vote; no LA author on the roster); 2025-26 bills AB 1401, AB 600, AB 844 and SB 622 (records
access, curriculum opt-out, sports/facilities — none acts on telling parents). The 2024 parental-notification
initiative failed to qualify. The Ninth Circuit enjoined 220.3(a) and 220.5(a) on 2026-06-18; that changes the
law's force, not what the votes show.

## 3. What each level found

- **State.** 23 seated, 1 direction-only (Lackey, No — a No on a rung-2 law shows the parents' side but not a rung).
  Own words: 9 challengers, all direction-only and not coded (e.g. Netter: teachers were told "NOT to share
  information with parents … restore parental rights"; Liu names AB 957, a custody bill). No incumbent statement
  adds a rung beyond the vote.
- **School.** No board vote in the 40 boards in the roster (incl. LAUSD — its LGBTQ+ resolutions of 2018 and
  2023 set no notice rule). The live LA County fights were in **Glendale USD and Burbank USD, which are not in the
  database** (roster gap; no districts, offices or people). Agenda systems (BoardDocs/Simbli) were not searched,
  so "no board vote" means not found in news or web search.
- **Federal.** No own-words statement from any of the 19 incumbents. Votes recorded as context only (H.R. 5, 2023;
  H.R. 2616, 2026): Obernolte Aye on both; every other member on the roster No. Challengers: Cargile (2024
  interview: California tries "to make employees, primarily teachers, secret keepers") and three iVoterGuide pages
  — direction-only.
- **Local.** Cheap sweep, by ruling: no city council or Board of Supervisors vote on this question in LA County
  2023-26. One statement: Konstantine Anthony (Burbank, 2023) opposes "hard and fast rules" that make teachers
  "immediately" notify parents, but says teachers will "eventually definitely get the parents involved". The coder
  read it as direction-only: it rejects an immediate-notice rule without choosing a rung.

## 4. What this wave says about A1 v2

1. **The ladder can seat the student side.** Rung 2 is a real, enacted position that 23 local legislators voted
   for, and the coder separated it from rung 1 cleanly. Across the four counties, seats now sit on rungs 2, 4 and 5.
2. **Rungs 1 and 3 are still empty everywhere.** No instrument in four states *requires* secrecy (rung 1) or
   gives a right to be told only on request (rung 3). In the Utah wave, the record-access law (SB 100) fit
   no rung at all (Gap A, PR #950, Q1).
3. **Seats come from one vote in one session.** In LA, a third of the sitting legislators (13 of 37) have no
   record, because the only vote came before they took office. State seats decay with turnover until a new
   instrument appears.
4. **Own words still seat nothing.** In four counties, every statement from an official or a candidate on this
   question shows a side, but none chooses a rung.

## Reviewer flags (mine, not the coder's)

1. **Q4 — is AB 1955 single-subject?** Besides 220.3/220.5 it adds Ed Code 217 (state resources for parents of
   LGBTQ pupils) and 220.1 (no retaliation against staff who support a pupil's rights). The coder called it
   single-subject. I agree: all three parts are on one subject (a pupil's gender identity at school), unlike
   HEA 1608, which bundled a K-3 instruction ban (Q3 in PR #950). If you rule otherwise under V4.1, all 23 seats
   become direction-only.
2. **Lead-file errors caught.** The state lead file left out Jacqui Irwin (AD 42, Aye on concurrence). I checked
   every state incumbent against both roll calls, then added and coded her. Two surname matches (Celeste and
   Michelle Rodriguez, both seated December 2024) were false — the "Rodriguez" on the 2024 roll is Freddie
   Rodriguez — and are correctly listed as not in office.

## Files

`backend/data/stance-research/2026-10-13-egi-a1v2-la/`: `roster.sql` / `roster.csv` (read-only query),
`people.json`, `leads/*.json` (four Sonnet source collectors) and `leads/people-*.txt`, `saved-pages/` (AB 1955
chaptered text and the two roll calls, extracted from the Legislature's bulk export because
leginfo.legislature.ca.gov returns 403 to scripts), `spec-ca.json`, one directory per coded person (25), `seat-table.csv`,
`run_egi.py`, `seat_table.py`, `run.log`.

Cost: 25 Opus coder runs, API-price equivalent **$37.74** (plan quota). Source collection: four Sonnet agents,
about 420k tokens in total.

## Next steps (owed by Chris)

- Q4 above. Q1-Q3 from PR #950 are still open; the LA result bears on Q1 (should the ladder place record/form rules?).
- Pin / push decision for A1 v2: unchanged — nothing here is pushed.
- Roster gap: Glendale USD and Burbank USD (and other LA County districts) are not in the database.
