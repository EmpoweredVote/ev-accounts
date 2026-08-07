# Waltham MA — re-research of the rows retired by migration 1564

**Date:** 2026-08-06 · **Outcome: 4 of 4 restored** by migration 1569. The cleanest cluster so far.
Full reasoning, evidence and caveats live in the migration header —
`backend/migrations/1569_reresearch_waltham_council_stances.sql`. This file is the short record.

## Shape of the cluster

Five retired rows, all the same claim on the same two sources: `walthampatch.com` (DNS dead) and
`mass.gov/info-details/mbta-communities-compliance-status`, asserting a 2024 MBTA Communities Act
zoning vote. **One of the five belonged to "Arthur Donahue", who does not exist** — migration 1566
unseated him and seated the real mayor. That left four real at-large councillors, each owed
Affordable Housing: Bradley-MacArthur, Brasco, LeBlanc, King.

## The denylist entry was re-checked, not assumed

My probe of the cited mass.gov URL returned **403**, which is a bot block and proves nothing. Rather
than treat that as absence, the real page was located: Massachusetts publishes this at
`/info-details/multi-family-zoning-requirement-for-mbta-communities` (plus
`/info-details/mbta-communities-law-qa`). The cited slug is composed. **1564's denylist entry is
correct.**

## 🔴 The claimed 2024 vote is REAL — and the roll call still convicts the rows

Waltham did adopt MBTA Communities zoning: first reading 2024-12-23, third and final reading
**2025-01-13**, approved 12-0-2-1.

> In favor: Brasco, Dunn, Durkee, Hanley, Harris, Katz, LaCava, LaFauci, Logan, McMenimen, Vidal and
> McLaughlin. **Opposed:** None. **Absent:** LeBlanc, Stanley. **Present:** Bradley-MacArthur.

| Member | On the 2024/25 MBTA vote the retired rows cited |
|---|---|
| Brasco | Voted in favour |
| Bradley-MacArthur | **"Present"** — present and deliberately not voting |
| LeBlanc | **Absent** |
| Tim King | **Not on the roll at all — PRE-TENURE** |

**Tim King took office 2026-01-04**, a year after the vote the retired row attributed to him. The 2025
roster seats McMenimen and Stanley, whom King and Tzioumis replaced. This is the **1537 pre-tenure
defect in local government again** (as in Newton), and no tenure detector can catch it while
`term_start` is NULL for local officials.

⚠ **Name-matching trap avoided:** "King" appears in 2025 minutes months before he took office — as
**"King First West Owner, LLC"**. Surname substring matching over-fires exactly as `Chan`/`channel`
and `ICE`/`Ken's Ice Cream` did. Confirm a first appearance against an inaugural roll call.

## What the restored rows rest on

**2026-06-22 — Affordable Housing Zoning Amendment (Article IX Sec. 9.1), third and final reading:**

> In favor: Bradley-MacArthur, Brasco, Dunn, Durkee, Hanley, Harris, Katz, King, LaCava, LaFauci,
> LeBlanc, McLaughlin and Tzioumis. **Opposed:** None. **Absent:** Vidal. Approved 13-0-1-1.

All four owed members, in the current term, on the owed topic, in a deliberated roll call — not on
consent. Bradley-MacArthur and LeBlanc additionally questioned Councillor Harris on the proposal at
the joint public hearing of 2026-04-13.

Article IX Sec. 9.1 is Waltham's **inclusionary zoning** article: 15% of units at or below 80% AMI in
developments of 8+ units, plus 5% at or below 50% AMI in developments of 19+. Voting to amend and
re-adopt it affirms a regime that **requires new developments to include affordable units** — chair
**2**.

⚠ **Honest limit:** the minutes name the amendment but never state its substance, and no primary
description of what it changes was found. The stored reasoning says only what the record supports and
does **not** assert that the amendment strengthened or weakened the requirement. Chair 2 rests on the
standing ordinance the vote affirms, not on an assumed direction of change.

## Corpus caveats

* **17 of 61** published minutes PDFs are **scanned images with no text layer** — unassessed, not empty.
* **2024 minutes are absent from the CivicPlus archive entirely** (the city migrated from Drupal), which
  is why the 2025-01-13 minutes are the earliest readable record of the 2024-12-23 first reading.
* Live council pages are the numeric CivicPlus paths; the older Drupal URLs 404. City Council is
  **CID 2**: `/AgendaCenter/Search/?term=&CIDs=2,&startDate=…&endDate=…`.

## Chip

`hasContext` left **FALSE**, consistent with the Carson ruling — four rows on one topic for four of
sixteen officials is not coverage. Operator call, flagged not taken.
