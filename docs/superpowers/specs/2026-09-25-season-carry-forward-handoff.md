# Season carry-forward display — handoff to Chris Cantrell (2026-09-25)

**From:** Chris Andrews' codebook session. **Owner asked for:** Chris Cantrell, author of
`2026-08-25-compass-seasons-design.md` and ADR 0005/0006.
**Status:** facts and open questions only. **No read path was changed.**

## The question

A politician has a Season 1 chair and no Season 2 row yet. Season 2 is open. What do voters see?

Andrews' intent (2026-09-25): new research is done for Season 2 only. Until a person is re-researched,
voters should still see something useful, with a notice that research is in progress. He wants your
ruling on what exactly that looks like, and he notes that some ladders changed only in wording while
others changed in substance.

## What the seasons design already says

`docs/superpowers/specs/2026-08-25-compass-seasons-design.md`, Migration plan step 4:

> Update the API to select the newest season in which a person has an answer, and to return the
> "last reviewed in season N" notice when that is not the current season.

- **The first half is built.** Every voter read shows the newest published season per topic.
- **The second half is not.**
  - No voter-facing API returns the answer's season.
  - Neither `essentials` nor `CompassV2` shows a notice.
  - So today a Season 1 chair displays against the Season 2 question with no label.

## Measured on production (read-only, 2026-09-25)

- **43 topics** have a Season 1 pin and a Season 2 served revision.
  - **3** are text-identical.
  - **40** differ in question or rung wording.
- **Same ladder `version`** (clarifying or editorial changes only): **22 topics**.
  - Examples: abortion, fossil-fuels, trans-athletes, medicare/aid, data-centers, taxes.
- **Different `version`** (at least one substantive change): **21 topics**.
  - Examples: school-vouchers, voting-rights, childcare, housing, climate-change, deportation.
- **27,786** Season 1 chairs are displayed today with no Season 2 row for that pair. **712** of them sit
  on the 3 text-identical topics.
- **`rung_map` cannot drive a per-rung rule yet.** Every substantive revision checked has the identity
  map (`1→1 … 5→5`), including school-vouchers, where rungs 1–3 changed meaning. The schema allows
  `"invalidated"` per rung, but nobody has recorded it.
- **Concrete case:** Durazo / school-vouchers shows her Season 1 rung 1 against the Season 2 wording.
  - The Season 1 reasoning describes SB 494 (2023) as a charter moratorium.
  - The official title is *School district governing boards: meetings: school district
    superintendents and assistant superintendents: termination*.
  - (Finding from the codebook P1 shadow run: `2026-09-25-codebook-p1-findings.md`.)

## Where a change would land

Every voter-facing read inlines its own `DISTINCT ON … ORDER BY s.number DESC` collapse; only
`researchEvidenceService` uses a shared helper. The sites:

- **`compassService.ts`:**
  - `getPoliticianAnswers` (704), `getBatchPoliticianAnswers` (1061), `getCandidateAnswers` (647)
  - `compareWithPoliticians` (966; the match score)
  - `getCompassPoliticians` (403)
  - `getPoliticianContext` (745)
  - `getPoliticianCitations` (1170)
- **`compassStatsService.ts`:** `POLITICIAN_COUNTS_SQL` (119), `POLITICIAN_TOTALS_SQL` (155).
- **`researchEvidenceService.ts`:** `reviewReadJoins` (315; admin "Voters see now").
- **`seasonService.ts`:** `DISPLAYED_VALUES_SQL` (494). Used by `verify-stance-research.ts` for the
  `replaces-published-chair` review reason.
- **Tests that pin today's behaviour:**
  - `researchEvidenceService.test.ts` 290–306 (a Season 1 value shown against Season 2 text is the
    asserted behaviour);
  - `compassService.test.ts` 159–375;
  - `compassStatsService.test.ts` 152–180.

A shared helper plus a `season_number` field (and maybe a carry status) in each response would
cover all of them. The research program's "ever researched" reads (`@season-scope: all-seasons`) need
no change.

## Questions for you

1. **Clarifying-only topics** (same version). Should the Season 1 chair show on the Season 2 ladder
   with a "from Season 1 — being researched" notice, or show as today with no notice?
2. **Substantive topics** (version changed). Which of these:
   - (a) the Season 1 chair on the Season 2 ladder, with a notice;
   - (b) the Season 1 chair with its own Season 1 rung wording, shown as history and not counted in the
     match score;
   - (c) hidden until re-researched.
3. **Per-rung.** Should substantive revisions record real `rung_map` values (`"invalidated"` for rungs
   whose meaning changed), so the rule can be per rung instead of per topic?
4. **The match score.** Should a carried Season 1 chair count in `compareWithPoliticians`?
5. **Ownership.** Build it yourself, or rule and hand back?

The codebook design's ruling Q3 (§9.1 of `2026-09-25-stance-quote-codebook-reliability-design.md`)
is **suspended** pending your answer. It said: carry forward only when the question and the rungs are
unchanged.
