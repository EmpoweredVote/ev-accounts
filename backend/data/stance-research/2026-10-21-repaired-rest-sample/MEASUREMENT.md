# The other 396 repaired rows — SAMPLED

**2026-10-21. Read-only: nothing written to the database.** Measures the population left by
migration 1921 (`../2026-10-20-repaired-chairs/LEDGER.md`): the repaired rows that sit **outside**
the generic-sourcing block, cite at least one specific source, and are therefore flagged by nothing.

---

## 1. The population

**396 voter-facing Season 2 rows / 185 people** carry the citation-repair marker and were never
examined. By the migration that made them: **1903 → 172 · 1900 → 80 · 1902 → 68 · 1911 → 40 ·
unlabelled → 18 · 1906 → 8 · 1899/1904/1909/1913 → 10.** 366 cite at least one specific source;
30 are all-generic but fell outside the 884-key block for other reasons.

Seeded uniform sample of **36** (`sha256('2026-10-21-repaired-rest' + key)`), read one at a time
against the seated rung's own text.

## 2. The measurement: 44%, and the prediction held

| | defect rate |
|---|---|
| the 40 already worked (sources **all generic**) | 22/40 = **55.0%** |
| **these 396 (at least one specific source), n=36** | **16/36 = 44.4%** |

Naive 95% CI **30–60%**. **20 KEEP · 7 RE-SEAT · 9 BLANK.**

✅ **The caution in the 1921 handoff was right**: the better-sourced rows *are* sounder. ⚠ But by
**less than the sourcing difference suggests**, and the intervals overlap heavily. A row can be
impeccably cited and still be seated wrongly — that is the whole defect class.

### 🔴 The naive interval is too narrow, and the reason is the finding

The 36 rows fall in only **25 distinct instrument clusters**. Rows in a cluster share a rung
mapping, so they are **not independent draws** and the true interval is wider than the binomial one.
**A uniform row sample over a clustered population understates its own uncertainty.** Quote the
rate with that caveat, or quote clusters instead of rows.

## 3. 🔑🔑 THE CLUSTER IS THE UNIT OF DEFECT, NOT THE ROW

**231 of the 396 rows fingerprint to a named instrument, forming 68 (instrument, topic, rung)
clusters.** When one member's mapping is wrong, it is wrong for every member who cites that
instrument. The sample lands on both kinds:

| rows | verdict | cluster |
|---:|---|---|
| 26 | ✅ sound (3 read) | TX SB17 (DEI offices) → civil-rights rung 2 |
| **14** | 🔴 **defective** (1 read) | **MA ROE Act → abortion rung 1** |
| **13** | 🔴 **defective** (1 read) | **TX Medicaid-expansion filings → healthcare rung 2** |
| **11** | 🔴 **defective** (3 read) | **MA police reform act S.2963 → public-safety rung 2** |
| 10 | ✅ sound (1 read) | MA Fair Share Amendment → taxes rung 2 |
| 10 | ✅ sound (1 read) | MA Medicare for All filings → healthcare rung 1 |
| 8 | ✅ sound (4 read) | MA rent stabilization filings → rent-regulation rung 2 |
| 8 | ✅ sound (2 read) | TX SB8 (heartbeat act) → abortion rung 2 |
| **7** | 🔴 **defective** (1 read) | **MA ROE Act → abortion rung 4** |
| **6** | 🔴 **defective** (1 read) | **TX SB13 (anti-ESG) → fossil-fuels rung 4** |
| **4** | 🔴 **defective** (1 read) | **TX SB13 → climate rung 5** |
| **4** | 🔴 **defective** (1 read) | **MA jail moratorium → jail-capacity rung 1** |
| **3** | 🔴 **defective** (1 read) | **MA Safe Communities Act → deportation rung 1** |

**66 rows sit in clusters read and found defective; 82 in clusters read and found sound; 248 in
clusters never read.** Eight clusters of 3+ rows were never sampled at all (36 rows).

▶ **This changes how to work the queue: fix a MAPPING, not a row.** Re-seating the 14 ROE-Act rows
is one decision applied fourteen times, not fourteen readings.

## 4. 🔴🔴 ONE INSTRUMENT, ONE LADDER, SEVERAL RUNGS — 167 of 396 rows

**15 (instrument, topic) pairs seat more than one rung**, covering **167 rows**:

```
23 rows  MA Fair Share Amendment / taxes       rung 2: 10 | rung 3: 7 | rung 4: 6
17 rows  MA ROE Act H.5179 / abortion          rung 1: 14 | rung 2: 3 | rung 4: 7
16 rows  MA police reform act / public-safety   rung 2: 11 | rung 4: 5
14 rows  TX Medicaid-expansion / healthcare     rung 2: 13 | rung 3: 1
10 rows  TX SB13 (anti-ESG) / fossil-fuels      rung 2:1 | 3:1 | rung 4: 6 | rung 5: 2
 7 rows  TX SB13 / climate-change               rung 4: 3 | rung 5: 4
 6 rows  TX HJR138 (carbon tax) / climate       rung 4: 4 | rung 5: 2
```

⚠ **A split is legitimate when it separates YEA from NAY** — the heartbeat-act cluster correctly
puts 8 opponents at abortion rung 2 and 1 supporter at rung 5. **It is a contradiction when two
members on the same side of the same vote sit at different rungs**, and the sample confirms several:

- **The ROE Act's Yea voters sit at rung 1 (14) AND rung 2 (3).** The Act is viability-based, so
  rung 2 is right and the 14 are over-seated (Q007). Its Nay voters sit at rung 4 (7), but one Nay
  on an *expansion* bill cannot choose among rungs 3, 4 and 5, which all oppose it (Q018).
- **TX SB13 gives climate rung 4 to three members and rung 5 to four** (Q004 vs Q012).
- **The Fair Share Amendment seats three different tax rungs across 23 rows.** Part of that is
  Yea/Nay, but not all of it.

🔑 **Nothing in the corpus compares two rows that cite one instrument.** That is the structural gap
behind this whole class, and it is cheap to close: a check that groups by (instrument, topic, vote
direction) and flags more than one rung would have found every cluster defect above.

## 5. What the repair passes did RIGHT — worth copying

These rows are far better than the 40. Several are models:

- **Q022 Todd Hunter / voting-rights** argues the carry gate explicitly: the Season 2 rung names a
  *mail-ballot ID number* and that is precisely what TX SB1 requires, so **the rung fits better in
  Season 2 than it did in Season 1**.
- **Q035 Obernolte / trans-athletes** replaced "Republicans broadly supported" plus an OBBBA article
  *containing no sports language at all* with his own Yea on H.R. 734 — "a direct, divided vote on
  exactly this question".
- **Q005/Q010/Q036** caught that the cited bill was *"An Act authorizing the Town of North
  Attleborough to issue an additional liquor license"* and found the real enacted vehicle — then
  **checked the 107-51 margin before keeping**, citing the rule that blanked Newhouse on 385-41.
- **Q008/Q011/Q016/Q032** searched **every General Court** the act was filed in, because a member
  who signed an earlier filing is a cosponsor whatever the row cites.
- **Q001 Bob Good** declines the neighbouring rung in its own words: *"voting against one
  supplemental supports reducing aid; it does not establish rung 5's ending of all aid."*

## 6. The mig-1903 disclaimer is a FLAG, not a verdict

Many TX rows carry: *"The instrument places this member firmly on their side of the ladder; it does
not by itself separate the rungs WITHIN that side, and the chair keeps the placement the original
research gave it."* That is honest, and it marks rows where **the rung was never established** —
the chair is inherited from research whose basis was a biography page.

⚖ **But it does not predict the verdict.** Q006/Q009/Q030 carry it and are sound; Q004/Q014 carry it
and are not. **Read the rung against the instrument; the disclaimer only tells you nobody has.**

## ▶ What this hands the next session

1. **Fix the confirmed-defective clusters as MAPPINGS** — 66 rows across 8 clusters, each one
   decision. Start with ROE Act → abortion rung 1 (14) and TX Medicaid → healthcare rung 2 (13).
2. **Build the contradiction check**: group by (instrument, topic, vote direction), flag any pair
   seating more than one rung. It is a SQL query, it needs no reading, and it would have found every
   cluster defect in this sample.
3. **Sample the 8 unread clusters of 3+** (36 rows) before assuming anything about them.
4. ⚠ **Quote rates with the design effect.** 36 rows but 25 clusters; the honest statement is about
   clusters, not rows.
