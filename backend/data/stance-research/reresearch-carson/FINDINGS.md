# Carson CA — re-research of the 34 rows retired by migration 1564

**Date:** 2026-08-06 · **Outcome: 3 of 34 assignable. 31 stay blank.**
Evidence base and tooling notes: `EVIDENCE-BASE.md` in this directory (read it first).

---

## 🔴 The headline: Carson's minutes cannot support compass coverage, and that is a fact about Carson

Alhambra yielded 16 of 19 from the same kind of corpus. Carson yields **3 of 34**. The difference is
not effort — the whole 2023–2024 corpus (73 minutes PDFs) was downloaded, extracted and searched
topic by topic. It is structural:

1. **Nearly every substantive item is approved on Consent with no recorded deliberation.** The LASD
   Service Level Agreement, the Homeless Employment Initiative, the PLHA homeless-prevention
   allocations and the post-*Grants Pass* camping-enforceability update were **all** "approved on
   Consent". A consent vote is a recorded act, but no member deliberated on the item, so it cannot
   carry an individual position.
2. **Members' recorded remarks are overwhelmingly ceremonial or informational** — thanking the Public
   Safety Department, asking for a homeless count, requesting a status update. Under the standard
   applied at Alhambra (a *question* is not a position — that is why Katherine Lee's Police HOME Team
   question left her spoke blank), almost all of it is unusable.

**Recommendation: Carson's `hasContext` chip stays FALSE.** Three rows across two topics for three of
five members is not coverage, and flipping it on this would repeat exactly what the audit exists to
correct. That is an operator call, flagged not taken.

## 🔴 Local Immigration Enforcement is empty for all five, and provably so

The retired rows rested on `dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/`.

* Zero immigration content in the 2023–2024 minutes. **Every `ICE` match in all 73 files is
  "Ken's Ice Cream."** (Word-boundary grep still hit it — the substring trap yet again.)
* The Legistar Web API, searching **all years back to 2001**, returns **0** matters for
  `immigration`, `immigrant`, `deportation`, `TRUST ACT` and `SB 54`. The only `sanctuary` hit is a
  pastor's church name; the only `welcoming` hit is "WELCOMING THE XFL WILDCATS TO CARSON."

**Carson has never had an immigration matter before its council.** The claimed 2017 Trust Act
resolution does not exist. All five rows stay blank — verified absent, not merely unfound.

## ⚠ Two topics where the obvious evidence was the WRONG evidence

Worth recording, because both were nearly assigned before the chair texts were read:

* **Environmental Protection vs. Development.** Carson has real air-quality material — Hicks requested
  an updated South Coast AQMD report and reported resident calls about methane and sulfur odours
  (2023-11-07); Davis-Holmes flagged the SBCCOG hearing to amend Rule 118 governing **refinery flare
  emissions** and asked staff to attend (2024-04-02). But this topic asks *"How should your community
  balance new development with environmental preservation?"* and its chairs are about green space,
  tree canopy, environmental review and developer offsets. **Industrial air pollution is a different
  subject.** Searching for the topic-correct material — trees, green space, open space, CEQA, EIR,
  mitigation tied to development — returns exactly one hit: Davis-Holmes asking for "a status of the
  tree" maintenance. Nothing assignable. All 5 blank.
* **Economic Development Incentives.** The council adopted an Economic Development Strategic Plan
  (2023-09-19, moved Hicks, seconded Hilton, unanimous) with all five participating. But the chairs
  are specifically about **tax incentives, abatements, subsidies and community benefit agreements**,
  and a search for `incentive`, `abatement`, `community benefit`, `subsidy`, `local hire` returns **no
  member statement at all**. Adopting an economic development plan is not a position on incentives.
  All 4 blank.

🔑 **Generalise this: match the member's statement to the CHAIR TEXTS, not to the topic's title.**
Both of these would have produced authoritative-looking rows resting on evidence about a different
question — the same failure mode as attributing a state bill to a city councillor.

---

## The 3 assignable rows

### Homelessness Response — `6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f`

Basis: 2024-01-23, the homeless services team presentation — the one homelessness item in the corpus
that was pulled for discussion rather than passed on consent.
Source: `https://carson.legistar.com/View.ashx?M=M&ID=1141751&GUID=4AEB539D-24E0-4D6B-8DB5-9FDC78DDF4EB`

| Member | Chair | Basis |
|---|---|---|
| Cedric L. Hicks Sr. | **2** | As **Chair of the South Bay Cities Council of Governments** he pressed the team on how often it coordinates with SBCCOG and whether it has the resources available, reported he is "working with additional grant funding that will be available in the future", and identified an undercounted population — "a lot of homeless people who live in their cars", naming specific streets. Action and direction, entirely services and funding, no enforcement component. |
| Lula Davis-Holmes | **2** | Responding to staff's problem that donation management was unworkable for lack of storage, she proposed that **staff obtain vouchers from restaurants and stores through the city's term purchase order** — a concrete direct-service delivery mechanism, which the City Manager undertook to pursue. |

**Blank: Dear, Hilton, Rojas.** Dear's contributions at the same item are purely informational (asking
for success stories, the last homeless count, whether donations are received). Hilton offered "a
solicitation to partner with the city"; Rojas has nothing on the topic anywhere in the corpus.

⚠ Carson retains municipal-code camping restrictions — item 2024-0687 sought an enforceability update
after *Grants Pass* — but it was received and filed on consent with no discussion, so it supports no
member's chair either way. That is why Hicks and Davis-Holmes sit at 2 rather than 3: their own
recorded positions contain no enforcement element.

### Affordable Housing — `669cac97-66a6-4087-b036-936fbe62efb3`

| Member | Chair | Basis |
|---|---|---|
| Jim Dear | **3** | Asked that the housing crisis "be made a part of the return of redevelopment" (2023-04-04, to Assemblyman Gipson) — a request to use redevelopment authority as a housing tool — and at the Economic Development Strategic Plan hearing raised housing concerns "especially market rate housing for new families and the importance of how to make the plan happen" (2023-09-19). Targeted public help plus market supply, rather than direct public building or pure deregulation. |

Sources: `…View.ashx?M=M&ID=1075668&GUID=3AB64993-6B41-49B9-A9FC-A6634BED8F0A` ·
`…View.ashx?M=M&ID=1107621&GUID=DAF7B914-61ED-442A-A966-99F0971EB65F`

**Blank: Davis-Holmes, Hilton, Hicks, Rojas.** Hicks "asked about more affordable housing options" —
a question. Rojas and Hilton "offered comments to move forward", which has no content.

---

## What remains owed

| Topic | Owed | Assigned | Blank |
|---|---|---|---|
| Homelessness Response | 5 | 2 | 3 |
| Affordable Housing | 5 | 1 | 4 |
| Public Safety Approach | 5 | 0 | 5 |
| Environmental Protection vs. Development | 5 | 0 | 5 |
| Local Immigration Enforcement | 5 | 0 | **5 — verified absent** |
| Economic Development Incentives | 4 | 0 | 4 |
| Growth and Development Pace | 2 | 0 | 2 |
| Taxation and Public Spending | 2 | 0 | 2 |
| Transportation Priorities | 1 | 0 | 1 |
| **Total** | **34** | **3** | **31** |

**Where the remaining 31 could come from, if they are worth pursuing:**
the 2025–2026 AgendaLink record (not yet read — JS-rendered, needs Playwright or the S3 packet PDFs),
which covers the current council term and is the more relevant window anyway. Nothing in the
2023–2024 Legistar corpus will move these; it has been searched exhaustively.
