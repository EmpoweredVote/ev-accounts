# Term-start detector — votes asserted before the member held the office

**Built after** the roll-call pass proved 20 rows crediting members with votes cast before they were in
Congress. That pass could only see rows citing a roll-call URL. This one reads the claim and checks it
against the calendar, so it needs no citation at all.

**Result: 30 candidates, 12 confirmed by hand, 6 of them new.** Precision 12/30 — this is a **reading
queue with a validated core**, not a clean list, and it is reported that way.

## The 12 confirmed

Each credits a **federal legislator** with a vote on a **federal measure** in a year before their
federal service began. Service dates are authoritative (unitedstates/congress-legislators).

| politician | federal service from | asserted | clause |
|---|---|---|---|
| **Val Hoyle** | 2023-01-03 | IRA 2022, TCJA 2017, IIJA 2021 | *"Hoyle voted YES on Inflation Reduction Act (2022)…"* |
| **Andrea Salinas** | 2023-01-03 | IRA 2022, IIJA 2021 | *"Salinas voted YES on Infrastructure Investment and Jobs Act (2021)"* |
| **Sydney Kamlager-Dove** | 2023-01-03 | Build Back Better Nov 2021, IRA Aug 2022 | *"She voted for the Build Back Better Act (November 2021)…"* |
| **Ayanna Pressley** | 2019-01-03 | TCJA 2017 | *"Pressley voted against the 2017 Tax Cuts and Jobs Act"* |
| **Cindy Hyde-Smith** | 2018-04-09 | TCJA 2017 | *"Hyde-Smith voted for the Tax Cuts and Jobs Act of 2017"* |
| **Guy Reschenthaler** | 2019-01-03 | TCJA 2017 | *"Reschenthaler voted for the 2017 Tax Cuts and Jobs Act"* |
| **Joe Neguse** | 2019-01-03 | TCJA 2017 | *"Neguse voted against the 2017 Tax Cuts and Jobs Act"* |
| **Cliff Bentz** | 2021-01-03 | TCJA 2017 | *"Bentz voted YES on Tax Cuts and Jobs Act (2017)"* |

🔴 **Six are new** — Kamlager-Dove ×2, Pressley, Hyde-Smith, Reschenthaler, Neguse. The other six
(Hoyle ×3, Salinas ×2, Bentz) were already proven by the roll-call pass **through a completely
different route**, which is the detector's validation: it independently rediscovered known-true cases
before finding unknown ones.

⚠ **The Tax Cuts and Jobs Act accounts for 6 of the 12.** A December-2017 vote attributed to members
sworn in during 2018, 2019 and 2021 looks like one systematic error, not eight independent ones —
worth checking whether a single research prompt or template produced it.

## How the inference stays closed

Our own data cannot say when anyone took office: **`essentials.office_terms` holds 82,351 rows and
exactly 69 `term_start` values** — 60 of the 3,826 politicians with stances. `bioguide_id` covers 120.
That is itself worth recording.

So the detector never asks "was this person in office in year Y". It fires only when:

1. the politician is a **federal legislator** — gated on `governments.type = 'NATIONAL'`, not on a job
   title (⚠ 42 US Representatives carry the bare title *"Representative"*, identical to Maine's and
   Texas's 150 state reps each; Hoyle, Salinas and Bentz all read *"Representative"*);
2. the clause asserts a personal **action** — voted / co-sponsored / introduced / sponsored;
3. the measure is one **no other body can vote on** — an H.R./S./H.J.Res. number, or a federal statute
   with no state namesake;
4. a year **adjacent to that measure** precedes their authoritative federal start.

A state legislator cannot have voted on H.R. 5376, so step 3 closes the inference without needing our
missing term data.

## 🔴 The detector was wrong six ways, and each fix is in the code

Seventh pass running where a detector's first cut over-fired. The cost here is unusually high — a false
positive is a public claim that a politician's record is fabricated — so the bar was set to abstain.

| bug | what it produced |
|---|---|
| **matched on surname with an "any candidate" fall-back** | bound LA **city councilmembers** Monica Rodriguez, John Lee and Traci Park to former members of Congress. 26 of the first 59 "findings" |
| **gated on job title** | missed Hoyle, Salinas and Bentz entirely — all titled *"Representative"* |
| **required a bill NUMBER** | missed the motivating cases: *"voted YES on Inflation Reduction Act (2022)"* carries no "H.R. 5376" |
| **took every year in the clause** | flagged Klobuchar, Whitehouse, Baldwin, Hassan for **correct** rows whose sentences also mention an earlier statement or a prior state office |
| **`S\.?\s?\d{1,4}` matched possessives** | *"Ballotpedia's 2022"* and *"Pennsylvania's 2020 electoral votes"* became federal measures; and `S.1975` was read as the **year 1975**, flagging Mark Warner |
| **`'Equality Act'` in the federal-act list** | matches New York's **Marriage Equality Act** (2011), a state law — five false accusations at a stroke: Meng, Malliotakis, Espaillat, Tenney, Kennedy |

Also added: counterfactuals and denials are skipped. Ashley Moody's row says she *"did not vote for the
Respect for Marriage Act (2022) — **she was not yet a senator**"*, which is the row getting it right,
and the detector was flagging it.

## The 18 context-year candidates

All read and dismissed: the year sits near the act name but belongs to another statement in the same
sentence — Ernst's 2014 Norquist pledge, Whitehouse's 2006 statement, Hassan's 2012 New Hampshire
service (which the clause states plainly), Cohen's 2005 Tennessee amendment vote, Ruiz's 2012 campaign
statement, Harshbarger's 2020 Vote Smart survey, Castor's "2030" clean-electricity **target date**, and
Vargas's "1961" from Civil Rights-era context. Each carries its reason in
`2026-08-02-term-start-findings.json` under `review_note`.

## Coverage, stated plainly

| | rows |
|---|---|
| reasoning names a year | 15,849 |
| …politician is a federal legislator we could match | 4,481 |
| …clause asserts a federal measure **and** an adjacent year | 30 |
| …confirmed pre-tenure | **12** |

🔴 **11,312 of the 15,849 are not federal legislators and this detector cannot judge them at all.**
State and local rows are the majority of the corpus and there is no term-start authority for them in
the database. If that matters, the fix is upstream: populate `office_terms.term_start`. Until then the
same defect could sit unmeasured across every state legislature and city council in the corpus.

## What is owed

1. **12 confirmed rows** — ⏳ operator decision, correct or retire. They assert something that did not
   happen; no citation change fixes them. Six overlap the roll-call pass's 20, so the combined queue is
   **26 distinct rows**.
2. **Check the TCJA cluster for a common cause** — 6 of 12 are the same December-2017 vote.
3. **Populate `office_terms.term_start`** — 69 of 82,351. Everything non-federal is unmeasurable without it.

Artifacts: `2026-08-02-term-start-findings.json` (30 candidates, each with clause, matched legislator,
authoritative service dates, and hand-review verdict) · `scripts/_tmp-term-start-detector.mjs` ·
`scripts/_tmp-term-start-classify.mjs`.
