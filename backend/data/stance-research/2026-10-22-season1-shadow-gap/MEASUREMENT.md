# The Season 1 shadow gap — what voters are actually served

**Read-only. Nothing was written to the database.** Measured 2026-10-22 against production.

Prompted by an operator observation while merging two duplicate person rows: *"We should ideally be
doing this work on the live season, not much help to do it off the old seasons other than to port it
over."* That is right, and nobody had measured how much there is to port.

---

## ▶▶ THE HEADLINE: ABOUT 90% OF EVERY PUBLISHED ANSWER COMES FROM THE CLOSED SEASON

Season 1 is **closed** and immutable (ADR 0005 §1.6). Season 2 is **open**. A Season 2 row shadows
the Season 1 row for the same (politician, topic) on read; where there is no Season 2 row, **Season 1
is what a voter sees**.

| | (politician, topic) pairs |
|---|---|
| **Serving from Season 1 only — nothing shadows them** | **30,190** |
| Published in Season 2 | 3,512 |
| …of which also exist in Season 1 (shadowing working) | 2,818 |
| …Season 2 only | 694 |

**The live season covers about 10% of what is on the site.** 4,005 people serve at least one answer
from Season 1 alone; 2,363 people have any Season 2 answer at all.

⚠ This is a COVERAGE measurement, not a quality one. It says nothing about whether the 30,190 are
well evidenced — that is the separate audit programme (migrations 1920-1933). A row can be in this
count and be perfectly sound.

---

## THE THREE BUCKETS, AND THEY ARE DIFFERENT KINDS OF WORK

What matters is whether Season 2 still asks the same question with the same rungs. `season_questions`
pins a `topic_revision_id` per season, so this is decidable rather than a judgement call.

| bucket | pairs | what porting one costs |
|---|---|---|
| **Ladder REVISED in Season 2** | **16,379** | RE-READ. The rungs changed, so the stored value may not mean what the current question says. This is the audit's natural target. |
| **Ladder unchanged** | **12,134** | RE-PIN. Same question, same rungs — the existing evidence supports the same chair, and the chair-evidence gate applies unchanged. |
| **Topic ABSENT from Season 2** | **1,677** | NEITHER. There is no Season 2 question to answer. |

🔑 **The 16,379 are the quiet version of the problem migrations 1926/1928/1931 chased through 165
rows.** Those passes withdrew chairs whose evidence proved the side but not the rung. These rows have
a subtler defect: the evidence may be fine, but it was weighed against a ladder the live season has
since replaced, so the rung a voter reads may not be the rung the current question defines.

### ⚠ The 1,677 absent rows are the known `immigration` orphan, measured independently

Every one of the 1,677 is **Immigration and Treatment of Immigrants**, which is not carried into
Season 2 at all. This reproduces the figure already recorded in the Season 3 agenda (~1,678) from a
different direction, which is worth having: it was not derived from that note.

There is no Season 2 question these can be ported to. Their disposition belongs to the Season 3
topic decisions, not to a porting pass.

---

## RETIREMENT DOES NOT SHRINK THIS

| bucket | total | on an ACTIVE person | on a SEATED officeholder | on a retired row |
|---|---|---|---|---|
| ladder REVISED | 16,379 | 16,266 | 13,808 | 113 |
| ladder unchanged | 12,134 | 12,048 | 9,950 | 86 |
| absent from S2 | 1,677 | 1,666 | 1,290 | 11 |

**29,980 of 30,190 sit on active people and 25,048 on sitting officeholders.** Only 210 are on
retired rows. The exposure is live.

---

## PER TOPIC

### Ladder revised — the re-read queue (16,379)

| topic | pairs | | topic | pairs |
|---|---|---|---|---|
| Climate Change and Environmental Protection | 1,884 | | Social Security | 592 |
| Civil Rights and Social Justice | 1,553 | | Homelessness Response | 438 |
| Voting Rights and Electoral Integrity | 1,514 | | Growth and Development Pace | 428 |
| Deportation Priorities | 1,340 | | Misinformation and Algorithms in Democracy | 367 |
| School Vouchers & Public Education Funding | 1,225 | | Environmental Protection vs. Development | 357 |
| Medicare / Medicaid | 1,131 | | Criminal Justice Approach | 287 |
| Campaign Finance Reform | 835 | | Data Center Development & Energy Costs | 282 |
| Childcare Affordability & Access | 773 | | Rent Regulation | 228 |
| Economic Development Incentives | 693 | | Same-Sex Marriage | 147 |
| Religious Freedom | 676 | | City Sanitation and Cleanliness | 113 |
| Criminalization of Homelessness | 634 | | Affordable Housing | 86 |
| Artificial Intelligence Oversight | 603 | | Judicial Interpretation | 71 |
| | | | Access to Justice | 48 |
| | | | Transparency in Legal Proceedings | 34 |
| | | | Judicial & Prosecutorial Discretion | 22 |
| | | | Police Accountability | 12 |
| | | | Bail and Pretrial Decisions | 6 |

### Ladder unchanged — the port queue (12,134)

| topic | pairs | | topic | pairs |
|---|---|---|---|---|
| Taxation and Public Spending | 1,958 | | Local Immigration Enforcement | 553 |
| Reproductive Rights and Abortion Access | 1,869 | | Ukraine - Russia Conflict | 462 |
| Healthcare Access | 1,757 | | Transportation Priorities | 444 |
| Fossil Fuel Policy | 1,326 | | Residential Zoning | 439 |
| Transgender Athletes | 850 | | Jail Capacity and Incarceration Alternatives | 301 |
| Public Safety Approach | 832 | | Prosecution Priorities | 20 |
| State Redistricting and Gerrymandering | 662 | | | |
| United States Tariff Policy | 661 | | | |

🔑 **Four topics carry 57% of the port queue** — Taxation, Reproductive Rights, Healthcare Access and
Fossil Fuel Policy total 6,910 of 12,134. A port pass scoped to one unchanged-ladder topic is a
tractable unit of work in a way "port Season 1" is not.

---

## ⚠ A TENSION TO SETTLE BEFORE ANY BULK PORT

Migrations 1925, 1926, 1928 and 1931 have been **blanking Season 2 rows** whose evidence does not
seat the rung. A bulk port pushes volume through the very gate that work has been clearing.

So a port must carry the EVIDENCE test, not just the value: `audit-chair-evidence.mjs` is a pre-write
gate, and a row whose reasoning names no instrument should not become a Season 2 answer merely
because it was already a Season 1 answer. **Porting is not free, and "it was already published" is
not evidence.** On the eight rows that prompted this measurement, three had an unchanged ladder and
all three were sourced to ontheissues.org with no instrument named — they would have failed.

---

## NO DISPOSITION IS MADE

This is a measurement. What to do with 30,190 rows belongs to the operator. The obvious shapes:

- **Port queue first, by topic.** 12,134 rows where the question did not change, gated on evidence.
- **Re-read queue by topic.** 16,379 rows where the ladder moved; highest value where the revision
  changed the rungs most.
- **The 1,677 immigration rows** are a Season 3 topic decision, not a porting problem.

---

## METHOD, so it can be re-run rather than trusted

```sql
WITH s1 AS (
  SELECT politician_id, topic_id, topic_revision_id
    FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'   -- Season 1 (closed)
     AND value IS DISTINCT FROM 0),                            -- 0 = blank/suppressed
s2 AS (
  SELECT politician_id, topic_id
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'   -- Season 2 (open)
     AND value IS DISTINCT FROM 0),
only1 AS (
  SELECT s1.* FROM s1
   WHERE NOT EXISTS (SELECT 1 FROM s2
                      WHERE s2.politician_id = s1.politician_id
                        AND s2.topic_id = s1.topic_id))
SELECT CASE WHEN sq.topic_revision_id IS NULL                        THEN 'ABSENT from S2'
            WHEN sq.topic_revision_id <> only1.topic_revision_id     THEN 'ladder REVISED'
            ELSE 'ladder unchanged' END AS status,
       count(*)
  FROM only1
  LEFT JOIN inform.season_questions sq
    ON sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND sq.topic_id = only1.topic_id
 GROUP BY status;
```

⚠ **A trap that produced wrong numbers on the first attempt.** Computing "does a Season 2 row exist"
with a window function over a result set already filtered to Season 1 makes the answer always zero,
so every row reads as unshadowed and the bucket totals come out against 33,008 rows instead of
30,190. The Season 2 presence test must be a separate scan, as above. The first cut of this
measurement had that bug and the numbers were corrected before publication.

⚠ `value = 0` means blank/suppressed, not "answered zero" — every count here filters it out, so these
are PUBLISHED answers only.

⚠ One row per (politician, topic, season) is guaranteed by the primary key, so pair counts and row
counts agree; that is why every per-topic `pairs` figure equals its distinct-people figure.
