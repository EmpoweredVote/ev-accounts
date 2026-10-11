# ✅ CLOSED 2026-10-10 — CAL-ACCESS sources: the 518 that PUBLISH

> ## 🔴 THIS HANDOFF IS DONE. DO NOT RE-RUN IT.
>
> **The audit it asks for was completed on 2026-10-10 by `CC_0221` (PR #973) and `CC_0222`
> (PR #974), both applied to prod and merged.** Everything below is the *original brief*, kept
> because its reframing and its traps are still correct. It is **not** a to-do list any more.
>
> ▶ **Result, method and what is still open:
> [`2026-10-10-cal-access-confirmed-518-audit-log.md`](2026-10-10-cal-access-confirmed-518-audit-log.md).**
>
> | `research_status` | at handoff | now |
> |---|---|---|
> | `confirmed` / candidate | 518 | **448** |
> | `not_applicable` | 5,417 | 5,484 |
> | `disputed` | 1,333 | 1,336 |
>
> **All 518 were tested** — 223 against CAL-ACCESS candidate pages, 100 against the committee's own
> official name, 195 by shape detector with every flagged row read.
>
> 🟢 **The money side came back CLEAN. $31,050 of $357,410,183 was misattributed** — one source,
> `1376762 MALHI FOR ASSEMBLY 2016`, which is Satinder S. Malhi's, not Raj Malhi's.
>
> 🔴 **Two of this brief's own instructions were WRONG, and the audit log says why:**
> - **"Start with the 259 that carry money, heaviest first"** — money does not predict error here.
>   The ten heaviest politicians (80 sources, $265M) produced one defect, worth **$0**. The real
>   predictor is the **absence of a forename tail**. The defect was 100 sources of surname buckets
>   on **eight inactive duplicate rows**, every one shadowing a live seated official.
> - **"Presence on the candidate page is the test"** — ⚠ **absence from it is NOT evidence of
>   misattribution.** Three money-carrying sources were flagged that way and **two were correct**: a
>   67% false-positive rate. A committee seeking a **non-state** office carries no
>   `(OFFICEHOLDER: …)` link and is invisible to the candidate page even when genuinely the
>   candidate's. 🟢 **Use the FPPC Form 460 cover page, Part 5 instead** — it names the candidate
>   *and* the office sought, under penalty of perjury, for every committee that files.
>
> ### 🔴 STILL OPEN — this brief is closed, but these are NOT
>
> **The two disputed sources that carry money are UNCHANGED and still sit on LIVE rows.** Verified
> 2026-10-10. The audit covered the `confirmed` population; these are `disputed`, so they publish
> nothing — but they are the open item this brief raised and they survive it:
>
> | source | committee | on | money | why it is still open |
> |---|---|---|---|---|
> | `1448127` | `GIPSON FOR ASSEMBLY 2022; CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE` | **Mike A. Gipson** (live) | 8 · $194,000.00 | A committee *supporting* him, typed `candidate_committee`. Confirming as-is would publish it as his own fundraising. |
> | `1418587` | `NEWSOM; RAN ACTION FUND COMMITTEE TO RECALL GAVIN` | **Gavin Newsom** (live) | 402 · $33,172.80 | Money raised to **remove him from office**. ⚠ `OutsideSpendingCommittee` has **no support/oppose field**, so typing it `ie_committee` is a UI design question, not a flip. `disputed` is correct until the UI can say "opposing". |
>
> `CC_0221` hit the same wall and left three support/oppose committees `disputed` for the same
> reason. ▶ **The blocker is one design decision: how outside spending renders support vs. oppose.**
>
> **Also open:** the 173 sources whose forename *and* surname both match and which were never
> individually read — only a same-full-name collision could make one wrong, which is a dedupe
> question; and **fourteen duplicate rows** on
> [`2026-10-09-finance-surname-buckets.md`](2026-10-09-finance-surname-buckets.md).
> ⚠ **The 5,484 `not_applicable` sources have still never been examined.**

---

## The original brief, as written 2026-10-10 (kept for its reframing and its traps)

Handoff written 2026-10-10, after `CC_0213`–`CC_0220` closed the surname-bucket programme.
Background and every rule those migrations paid for: `2026-10-09-finance-surname-buckets.md`.

## 🔴 THE REFRAMING — READ THIS BEFORE PLANNING ANYTHING

The open item was recorded as *"1,486 disputed `cal_access` sources across 319 politicians, many on
active rows"*. That framing is **wrong by priority**, and the measurement says so.

| `research_status` / `source_type` | sources | politicians | publishes? |
|---|---|---|---|
| `needs_research` / candidate | 77,225 | 76,710 | no — the `cal_access_discovery` placeholder registry |
| `not_applicable` / candidate | 5,417 | 349 | no |
| **`disputed` / candidate** | **1,333** | 270 | **no** |
| **`confirmed` / candidate** | **518** | **146** | **🔴 YES** |
| `confirmed` / ie | 2 | 2 | yes, as outside spending (`CC_0219`) |

**A `disputed` source publishes nothing. A `confirmed` one is on a voter's page right now.**

### What the disputed 1,333 are actually worth

Measured 2026-10-10: **exactly 2 of the 1,333 carry a single contribution.** The other 1,331 hold
**zero**, because their committees' money was never ingested — the CAL-ACCESS ingestion gap
`CC_0214` recorded. Adjudicating them changes nothing a voter sees.

| population | sources | active rows | carry money |
|---|---|---|---|
| mig 1792 "UNVERIFIED, never independently checked" | 1,205 | 707 | **0** |
| `CA_0192` PRIMARILY FORMED (a real IE committee) | 105 | 105 | 2 |
| `confirm-cal-access.ts`, no later note | 18 | 15 | 0 |
| `CC_0216`/`CC_0217` downgrades | 5 | 0 | 0 |

### What the confirmed 518 are worth

**259 of them carry money: 260,653 contributions, $357,410,183.** Every one was written by
`confirm-cal-access.ts` — the script that matched committees to politicians **by surname** and
confirmed its own guesses in the same pass. That is the script that produced the seven surname
buckets. ⚠ **120 of the 518 carry no forename tail in the committee name at all**, and 8 carry no
committee name, so no name-based test can clear them.

▶ **The audit that matters is the 518. The 1,333 are provenance cleanup and can wait.**

## The method, already proven

Use the CAL-ACCESS **candidate** page — it lists a candidate's own committees **by filer ID**, which
is a primary source naming the committee *and* the candidate. The committee page never names the
candidate; reasoning from it is what produced the buckets.

```
/Campaign/Candidates/list.aspx?view=name&letter=<X>   ->  "DIXON, DIANE" -> Detail.aspx?id=1418515
/Campaign/Candidates/Detail.aspx?id=<candidate filer> ->  every committee they control, by ID
```

Scrape the ids with `[...document.body.innerText.matchAll(/([A-Z0-9'’,;.\- &]+)\s*\(ID#\s*(\d+)\)/g)]`.

- 🔴 **cal-access.sos.ca.gov is behind Incapsula.** `curl` gets **HTTP 200 and a 212-byte script
  stub** — `r.ok` is true. Playwright is refused too **until the homepage is loaded first**; after
  that every page works in the same context.
- 🟢 **Batch it.** One `browser_evaluate` doing in-page `fetch(url, {credentials:'include'})` over a
  list of ids reads **34 committee pages in a single tool call**. That is how to do 518.
- ⚠ **It covers STATE candidates.** A purely local filer is not listed, and anyone who left before
  ~2005 is gone entirely (John Dutra, Jim Patterson's pre-2012 committees).
- ⚠ **Match on the filer id, never on our stored `committee_name`** — ours drifts from CAL-ACCESS's
  (our "DIXON FOR CITY COUNCIL 2014, DIANE" is their "…2018").

## Suggested order

1. **Pull the 518 and group by politician** (146 of them). One candidate-page fetch clears all of
   that politician's committees at once, so the unit of work is the politician, not the source.
2. **Start with the 259 that carry money**, heaviest first. That is where a wrong attribution is
   visible to a voter.
3. **Three outcomes per source**, the same ones `CC_0216` used:
   - on the candidate's page → leave `confirmed`;
   - absent, and it reads as outside spending → `ie_committee`. **It can publish now** —
     `getOutsideSpendingForPolitician` was widened in PR #969 and `CC_0219` published the first two;
   - absent, and it belongs to somebody else → `disputed`, then `not_applicable` once adjudicated.
4. **The `CA_0192` 105** are already identified as PRIMARILY FORMED committees and only need the
   retype + confirm. They are the cheapest win, but only 2 carry money.

## The two disputed sources that DO carry money

```
1448127  GIPSON FOR ASSEMBLY 2022; CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE
         -> Mike A. Gipson (active)    8 contributions   $194,000.00
1418587  NEWSOM; RAN ACTION FUND COMMITTEE TO RECALL GAVIN
         -> Gavin Newsom (active)    402 contributions   $ 33,172.80
```

🔴 **Both are typed `candidate_committee`.** Confirming either as-is would publish it as the
politician's **own fundraising**. Gipson's is a committee supporting him; **Newsom's is a committee
to RECALL him** — money raised to remove him from office, which would render as money he raised.

⚠ **Newsom's is a genuine design question, not a flip.** `OutsideSpendingCommittee` carries
`cmt_id`, `cmt_nm`, `total_amount`, `contribution_count`, `top_donors` — and **no support/oppose
field**. Publishing a recall committee under a heading that does not say "opposing" is its own
misstatement. Decide what the UI says before typing it `ie_committee`. Leaving it `disputed` is
correct until then.

## Traps carried forward

- 🔴 **A `disputed`/`not_applicable` source on a LIVE politician is a loaded gun.** `CC_0220` moved
  18 foreign committees onto Bryan Fish's and Angie Reyes English's live rows. **Anyone confirming a
  cal_access source must check it names the politician it sits on.**
- 🔴 **`notes` is not always valid JSON.** Appended text (`{...} | UNVERIFIED … | DISPUTED …`) breaks
  `notes::jsonb`. A guard that casts across rows it did not write will die mid-migration — use
  `regexp_match(notes, '"committee_name"\s*:\s*"([^"]*)"')` for a corpus-wide read.
- 🔴 **`la_socrata` reuses CAL-ACCESS filer ids**, so a shared `external_id` is the SAME committee.
  193 ids are shared and 3 carry contributions in both systems — gather by
  **(external_id, source_system)** or you double count.
- 🔴 **`contributions.politician_source_id` has NO foreign key.** Deleting a source silently strands
  its contributions. Move sources; never delete one that carries rows.
- ⚠ **`politician_sources` has a UNIQUE index on (politician, source_system, external_id)** — which
  also means a planted-row negative control fails on the index before reaching any gate.
- ⚠ **A filer phone is the TREASURER's number.** It groups by filing agent, never identifies.
- ⚠ **Donor-overlap only discriminates between comparable fundraising universes.** A statewide and a
  city committee share almost no donors even for the same person; a null is not a negative.
- ⚠ **`NOT EXISTS` / aggregates over the whole `contributions` table exceed the statement timeout.**
  Scope to the source ids you touch, or pre-compute per source with a `LATERAL`.

## Not in scope here, but open

- **Bryan Fish is listed as Vice Mayor on culvercity.gov; our row says Council Member.** Occupancy.
- **`FISH FOR CITY COUNCIL 2028`** (`1465836`, 0 contributions) is the one source `CC_0217` left
  `disputed` as genuinely undetermined; it now sits on Bryan Fish's live row.
- **The 5,417 `not_applicable` cal_access sources** pre-date this programme and were never examined.
