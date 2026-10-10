---
status: accepted
---

> **Draft, 2026-10-10.** Written out of the CAL-ACCESS source audits of 2026-10-10
> (`CC_0221`–`CC_0223`), which hit the same wall three times and left five committees withheld
> because of it. Worklists: `.planning/todos/2026-10-10-cal-access-confirmed-518-audit-log.md`
> and `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
>
> 🔴 Every count in §2 was measured against **production** on 2026-10-10, after `CC_0223`. Treat
> them as a map to re-verify, not as gospel — especially "three committees publish", which is the
> fact doing the most work here and the one most likely to stop being true.
>
> ⚠ Two things this draft could **not** verify from the `ev-accounts` checkout and does not assert:
> whether the **essentials frontend** (a separate repo) renders `outside_spending` at all today,
> and whether **`la_socrata`** carries a support/oppose signal in its source data. §6 and §7 mark
> both as open.

# Outside spending must say whether it supports or opposes

## 1. Why this exists

`getOutsideSpendingForPolitician` returns committees that spent money **about** a politician
without being controlled by them. Three API payloads carry it as `outside_spending`
(`backend/src/lib/campaignFinanceService.ts`, lines 1193, 1261, 1452).

The type it returns has no field for which **direction** that spending ran:

```ts
export interface OutsideSpendingCommittee {
  cmt_id: string;
  cmt_nm: string;
  total_amount: number;
  contribution_count: number;
  top_donors: Array<{ donor_name: string; amount: number }>;
}
```

A committee formed to **elect** someone and a committee formed to **recall** them are, in this
shape, the same object. So are their donor lists — one is people who funded them, the other is
people who funded a campaign against them, and nothing distinguishes the two.

🔴 **This is not a gap in detail. It is a claim the data cannot support being rendered as though it
could.** Publishing a recall committee's money on a politician's finance page, under any heading
that does not say "opposing", is a false statement about a real person. It is the same defect class
as a compass chair the evidence does not name, expressed as a dollar figure.

That is why five committees are withheld today rather than typed. The audits did not lack evidence
of what those committees are; they lacked somewhere true to put it.

## 2. What was measured, 2026-10-10 (production, after `CC_0223`)

**Three sources publish as outside spending.** That is the entire live corpus:

| system | id | on | committee | contributions |
|---|---|---|---|---|
| `la_socrata` | 1442937 | Traci Park | Traci Park for Safe Council District 11 2022 | 20 · $4,050.00 |
| `cal_access` | 1489255 | John Erickson | ERICKSON FOR STATE SENATE 2026 … WORKING FAMILIES FOR JOHN | 1 · $25,000.00 |
| `cal_access` | 1447993 | Melissa Hurtado | HURTADO 2022; COALITION OF BUSINESS ORGANIZATIONS **SUPPORTING** SENATOR MELISSA | 8 · $344,843.80 |

🟢 **All three happen to be support committees, so nothing is currently misstated.**

🔴 **But not one of them is *evidenced* as support — they are support because their names contain
"for", "working families for" and "supporting".** The corpus is accidentally safe, not safely
designed. **The first oppose committee anyone types `ie_committee` publishes silently as though the
politician raised the money.** Nothing in the schema, the query or the type would stop it.

**Five committees are withheld on this, two of them carrying money:**

| id | committee | on | money | direction |
|---|---|---|---|---|
| `1448127` | CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE GIPSON | Mike A. Gipson (live) | 8 · $194,000.00 | support |
| `1418587` | NEWSOM; RAN ACTION FUND COMMITTEE TO **RECALL** GAVIN | Gavin Newsom (live) | 402 · $33,172.80 | **oppose** |
| `1484689` | CERDA 2026; SUPPORTERS OF MAYOR TASHA | Tasha Cerda | 0 | support |
| `1375008` | … NEIGHBORS FOR A BETTER WEST HOLLYWOOD **IN SUPPORT OF** LAUREN MEISTER | Lauren Meister | 0 | support |
| `1434041` | AWAD FOR MAYOR 2020; HAWTHORNE CITIZENS **OPPOSING** HAIDAR | Haidar Awad | 0 | **oppose** |

⚠ Three of the five (`CC_0221`) sit on inactive duplicate rows; Gipson's and Newsom's sit on **live
incumbents**. The money is $227,172.80, all of it on the two live rows.

⚠ A further **105** `CA_0192` primarily-formed committees are identified and typable, but only the
two above carry contributions — the rest would publish nothing because their money was never
ingested. **This decision is about correctness, not coverage.**

## 3. Decision

**Add a direction to the source, and make it required before anything publishes.**

1. `transparent_motivations.politician_sources` gains **`support_oppose`**, nullable, CHECK
   constrained to `'support' | 'oppose'`.
2. 🔴 **`getOutsideSpendingForPolitician` publishes only rows where it is non-null.** A committee
   whose direction is unknown is **withheld**, exactly as a `disputed` source is withheld today.
3. `OutsideSpendingCommittee` gains a non-optional `support_oppose: 'support' | 'oppose'`, so a
   consumer cannot render one without having chosen how to say which.

**The grain is the source row, not the committee**, and that is deliberate: a single committee can
support one candidate and oppose another, and `politician_sources` is already per
(politician, source_system, external_id). The FPPC form records direction the same way — per
candidate, not per committee.

### Why nullable-and-withheld rather than a default

A default is a guess, and the guess is unsafe in one direction: defaulting to `support` publishes
opposition spending as the politician's own backing. **There is no safe default**, so there is no
default. This mirrors the ruling that a blank compass spoke is correct and a guessed chair is not.

## 4. Where the value comes from

🟢 **FPPC Form 460, cover page Part 7 — "Primarily Formed Committee"** — lists each officeholder or
candidate the committee is primarily formed for, with **SUPPORT and OPPOSE checkboxes per name**,
signed under penalty of perjury. Part 6 carries the same for ballot measures.

This is a **primary source we can already fetch**. The 2026-10-10 audit read three of these cover
pages to settle the Dixon, Solache and Malhi attributions, so the retrieval path is proven:

```
/Campaign/Committees/Detail.aspx?id=<cmte>&view=electronic&session=<YYYY>   -> filing ids
/Misc/pdf.aspx?filingid=<id>&amendid=0                                     -> the PDF
```

🔴 Two retrieval traps, both already paid for: the PDF endpoint returns a **212-byte Incapsula stub
at HTTP 200 `text/html`** to `curl` and must be fetched inside a browser context; and the filings
list is **session-scoped**, so a default-session read reports zero filings for committees that have
them.

⚠ **This covers `cal_access` only.** Whether `la_socrata` exposes a direction was **not checked**
and must be before its one published row (`1442937`) can be given a value. If it does not, those
rows stay `NULL` and stay withheld — which is the correct outcome, not a regression.

## 4a. 🔴🔴 AMENDED AFTER IMPLEMENTATION — THE CHECKBOX IS NOT THE ANSWER

Implementing this (`CC_0224`/`CC_0225`, 2026-10-10) found two things §4 had wrong.

**A recall committee files Part 6, not Part 7, and its polarity is INVERTED.** The Newsom recall
committee `1418587` files as a **Ballot Measure Committee**:

```
NAME OF BALLOT MEASURE:  Recall Gavin Newsom
SUPPORT ☒    OPPOSE ☐
```

🔴 **The checkbox says SUPPORT and the correct value for that row is `oppose`.** Part 6's direction
is relative to the **measure**; the measure is his recall; supporting the recall is opposing the
officeholder. Read as a checkbox rather than as a sentence, this field would have published
$33,172.80 raised to **remove** a sitting Governor as money **supporting** him — the exact harm
this ADR exists to prevent, arriving through the field added to prevent it.

▶ **`support_oppose` may never be mechanically copied from a filing.** The column means *direction
relative to THIS POLITICIAN*; the filing states *direction relative to whatever the filer named*.
When those differ, a human reads the filing. This is why §3 puts the field on the source row — the
row knows which politician it is about; the committee does not.

**Form 496 carries the field too.** Erickson's committee files a *Late Independent Expenditure
Report*, whose Part 1 names `John Erickson · State Senator District 24 · SUPPORT ☒`. A pure-IE
committee may file **only** 496s, so a Part 7-only rule finds nothing for it.

**§4's `la_socrata` caveat was real.** Traci Park's `1442937` is an LA **city** filer; a sweep of
CAL-ACCESS sessions found **no filings for it at all**. It stays `NULL` and therefore dark. Its
name reads as support — and a name is not evidence, which is the rule this ADR rests on.

## 5. What this costs today

Withholding is not free: it removes one row that publishes now. **`1442937` Traci Park ($4,050) and
the other two would go dark until a direction is recorded for them.** That is accepted. Three
committees reading correctly by accident is not a state worth protecting, and the work to evidence
three Form 460s is small.

## 6. The rendering contract — the part that is actually hard

🔴 **The schema is the easy half. The display is where the harm lives.**

An oppose committee's `top_donors` are **people who funded a campaign against the officeholder**.
Rendered under the same heading, in the same list, with the same styling as supporters, the list
inverts its meaning while looking identical. A reader scanning a donor table has no way to tell.

This ADR **requires** that support and oppose be visually and textually distinct wherever they
appear together, and that `top_donors` under an oppose committee be labelled as funding the
opposition. It does **not** specify the design.

⚠ **Open: who renders this.** `outside_spending` is returned by three backend endpoints, but no
renderer was found in `app/` or `admin/`. The essentials frontend is a separate repository and was
not inspected. **Before implementing, find every consumer** — a field added to the API that an
unexamined consumer ignores leaves the original misstatement in place.

## 7. What this does not decide

- **Ballot-measure committees.** Form 460 Part 6 carries the same support/oppose for measures, and
  the same argument applies, but no measure committee publishes today and none was audited.
- **The `la_socrata` direction source.** Unverified; see §4.
- **Whether the 105 `CA_0192` primarily-formed committees get retyped.** They are blocked on
  ingestion, not on this.
- **Retroactive labelling of `candidate_committee` sources.** This ADR is about outside spending.

## 8. Consequences

- One migration: the column, the CHECK, and the read-path filter.
- `OutsideSpendingCommittee` gains a required field, which is a **breaking change for consumers** —
  deliberately, so that no consumer can keep rendering direction-blind.
- Five withheld committees become typable once their Form 460 is read, of which two carry
  $227,172.80 on live incumbents.
- Three currently-published committees go dark until evidenced.
- 🔴 **The recurring cost this ends:** three separate audits on 2026-10-10 reached this same wall
  and each had to stop and record it. The next one would too.
