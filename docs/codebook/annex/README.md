# Per-topic annexes — index

One annex per open-season topic, written against the **served** ladder revision (codebook Part C).
`build-coder-inputs.ts` pastes `annex/<topic_key>.md` into every coder prompt for that topic, so an
annex on `master` is live guidance. This index is **not** pasted into prompts; provenance and drafting
notes live here, not in the annexes.

## Annexes

Season 2 (open). Served revision = what `seasonService.servedRevisionLateral` resolves for the season
pin, read 2026-10-01. On all four topics below the pin and the served revision are the same row.

| Topic | Served revision | Status |
|---|---|---|
| [`climate-change`](climate-change.md) | `5f1403f3-90b6-491f-ba54-3c8e46a5ae26` (v2 r3) | draft, not ruled; 4 `_owed:_` |
| [`misinformation`](misinformation.md) | `bd313c07-02a5-4344-8cc3-0e4b4c3b78a1` (v2 r3) | draft, not ruled; 1 `_owed:_` |
| [`school-vouchers`](school-vouchers.md) | `88858826-90c0-41c9-a3a4-1d9f5b8c5307` (v2 r3) | draft, not ruled; 3 `_owed:_` (refreshed 2026-10-01) |
| [`voting-rights`](voting-rights.md) | _(not recorded in the file)_ | draft, not ruled (2026-09-26); not yet refreshed to this format |

The other 56 open-season topics have no annex yet.

## How the drafts were made

- **Rung text:** copied verbatim from the served revision (`inform.compass_stance_revisions`), never
  from the frozen `inform.compass_stances`.
- **"Means" lines:** first drafted from the Season 1 `description` column (focused-communities
  migrations `20260416233145`, `20260416233416`, `20260416234110` — AI-written 2026-04-16, never
  reviewed, keyed by topic and value only). Where the Season 2 rung differs from what the description
  paraphrased, the line was rewritten to the Season 2 wording. `example_perspectives` was not used.
  No party or ideology words.
- **"Commonly confused with" and hard cases:** from adjudicated gold (`inform.stance_gold_labels`
  `source_judgments`, and `.planning/gold/gold-*.json`). **No gold item, politician or bill is named.**
  Every gold item on these topics is `excluded_from_cert = false`; naming one would make it a codebook
  example and remove it from certification (Part D). The annexes describe the boundary pattern only,
  the same way H13 and H14 were written on 2026-09-30. The coder labels for those items predate these
  lines; if one of those items is re-coded after an annex lands, mark it `excluded_from_cert`.
- **`_(proposed)_`** marks a drafter's reading with no gold behind it. **`_owed:_`** marks a question
  that needs a ruling. Resolve every `_owed:_` before merging an annex: coders read it as guidance.

## Season 1 description vs Season 2 served text

A rung is listed when its Season 2 served text differs from the legacy `inform.compass_stances` text
that the Season 1 description paraphrased (exact comparison, ignoring case and a final period).
Differences are not graded for materiality, except on the three drafted topics. Using a Season 1
description on a listed rung, unchanged, describes a sentence that is no longer served.

| Topic | Rungs whose wording changed |
|---|---|
| `abortion` | 1, 2, 3, 4, 5 |
| `ai-regulation` | 3, 4, 5 |
| `campaign-finance` | 1, 2, 3 |
| `childcare` | 4 |
| `civil-rights` | 1 |
| `climate-change` | 1, 2, 3, 4, 5 — every rung re-axed, from emissions and bans to mechanisms (mandate, fund, ease, neutral, end support). Only rung 4's description is still close. |
| `data-centers` | 2, 5 |
| `deportation` | 1, 2, 3, 4, 5 |
| `fossil-fuels` | 1, 2, 3, 4, 5 |
| `healthcare` | 1 |
| `homelessness` | 1, 2, 4, 5 |
| `housing` | 1, 2, 3, 4, 5 |
| `jail-capacity` | 2, 5 |
| `medicare/aid` | 2, 4 |
| `misinformation` | 1, 2 — rung 1 dropped "all" and "regulate algorithms"; rung 2 changed from fact-checking and algorithm transparency to labels instead of removal. The S1 rung-2 description would put transparency laws on rung 2, which is now wrong. |
| `religious-freedom` | 1 |
| `same-sex-marriage` | 1, 2, 3, 4 |
| `school-vouchers` | 1, 2, 3, 4 — rungs 1-3 re-written (S1 rung 2 was a low-income-only programme; S2 has no such rung); rung 4 dropped "while maintaining baseline public school funding". |
| `social-security` | 4 |
| `tariffs` | 2 |
| `taxes` | 3, 4, 5 |
| `trans-athletes` | 3 |
| `ukraine-support` | 1 |
| `voting-rights` | 1, 2, 3, 4, 5 |

Unchanged on every rung: `redistricting`.

No Season 1 description exists (35 topics; draft "Means" from the served text alone):
`city-sanitation`, `economic-development`, `growth-and-development`, `homelessness-response`,
`judicial-access-to-justice`, `judicial-bail-pretrial`, `judicial-criminal-justice`,
`judicial-government-deference`, `judicial-interpretation`, `judicial-police-accountability`,
`judicial-prosecution-priorities`, `judicial-transparency`, `local-environment`, `local-immigration`,
`public-safety-approach`, `rent-regulation`, `residential-zoning`, `transportation-priorities`,
`2020-election`, `border-security`, `education-curriculum`, `education-library-books`,
`education-gender-identity`, `education-equity-programs`, `education-school-police`,
`education-charter-authorization`, `education-school-budget`, `education-ai`, `cannabis-policy`,
`defense-spending`, `military-intervention`, `gun-policy`, `israel-military-aid`, `minimum-wage`,
`ranked-choice-voting`.

## Pending notes for annexes not yet written

### `abortion` (served `085feb9c-f157-4dae-bfd0-7b2736c5d87c`)

From the gold-labelling session, 2026-10-01, operator-approved. Coders split twice on one bill: a
15-week limit with only a medical-emergency exception (death or serious lasting harm to a major
bodily function) after it. The operator ruled it rung 3 on two gold items, which stay unnamed. The
ladder states limits in trimesters; laws state them in weeks.

Proposed line, as received:

> A gestational limit at about 12–15 weeks, with only a health or life exception after it, reads as
> rung 3. A limit at about 20–24 weeks, or at viability, with a health exception after it, reads as
> rung 2. A ban from conception or implantation with rape, incest and life exceptions reads as rung 4.
> A limit with NO stated exception after it does not reach rung 3 or 2 on its own (silence is not a
> clause).

Checked against the served wording before use. Open points:
- Rungs 2 and 3 say "only to protect the mother's **health**". A **life-only** exception is narrower
  than that, so "health or life" overstates rung 3. The ruled bill had a health exception.
- Rung 2 is "through the second trimester" (about week 27). Viability (about 24) and 22–24 weeks are
  close to it; **20 weeks** sits about halfway between the two thresholds. Decide where 16–21 weeks
  goes, and whether weeks are counted from the last menstrual period or from fertilization (20 weeks
  after fertilization is about 22 weeks LMP).
- Rung 4 lists three exceptions: rape, incest **and** a serious risk to life. Not covered: an early
  ban (for example 6 weeks) with those exceptions, and a ban whose only exception is the mother's
  life. The second fits neither rung 4 nor rung 5 ("no exceptions").

⚠ `medicare/aid` contains a slash, so `annexPath` resolves it to `annex/medicare/aid.md` (a
subdirectory). Keep that path when writing its annex.
