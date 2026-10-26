# The eight unread clusters of 3+, adjudicated — migration 1941

**2026-10-25.** Closes open item 3 of `../2026-10-22-cluster-mappings/LEDGER.md`: *"Sample the 8
unread clusters of 3+ (36 rows)."* They were read in full rather than sampled. Applied live, then
verified from outside the migration's own guards.

---

## 1. The result

| rows | cluster | decision | written |
|---:|---|---|---:|
| 7 | MA Fair Share Amendment → taxes r3 (Yea voters) | **re-seat to 2** | 7 |
| 6 | MA Fair Share Amendment → taxes r4 (Nay voters) | **blank** — direction only | 6 |
| 5 | Ballotpedia campaign themes → taxes r4 (VA) | **split**: 2 keep, 3 blank | 3 |
| 5 | MA police reform act S.2963 → public-safety r4 | **blank** — off-axis | 5 |
| 4 | Ballotpedia campaign themes → healthcare r4 (VA) | **split**: 3 keep, 1 blank | 1 |
| 3 | MA rent stabilization filings → housing r1 | **re-seat to 3** | 3 |
| 3 | TX SB13 → climate-change r4 | already settled before this pass | 0 |
| 3 | MA ROE Act H.5179 → abortion r2 (Yea voters) | **keep** — correctly seated | 0 |
| **36** | | **10 re-seats · 15 blanks** | **25** |

Eleven rows were deliberately left alone, and their `updated_at` still proves it (8 October for the
kept Ballotpedia rows, 7 October for the ROE Act rows, 21 October for the climate rows).

## 2. 🔴🔴 THE PREMISE BROKE ON TWO OF THE EIGHT, AND THAT IS THE FINDING

The parent measurement's rule is **the cluster, not the row, is the unit of defect** — one mapping
decision governs every member citing the same instrument. That held for six of these eight.

It broke on the two fingerprinted **"Ballotpedia campaign themes (own words)"**, because that is a
**SOURCE TYPE, not an instrument**. Every member's evidence is a different text saying a different
thing, so there is no shared mapping decision to make. Read as units they would have been blanked
or kept wholesale; read row by row they split **2 keep / 3 blank** and **3 keep / 1 blank**.

⚠ **Before treating any future cluster as a unit, ask whether its fingerprint names an INSTRUMENT or
a SOURCE TYPE.** Only the first kind carries one decision. The 68-cluster file has more of the
second kind in it.

## 3. 🔴 Checking the SERVING row removed a whole cluster from the queue

**TX SB13 → climate-change r4 was already fully settled** and the measurement could not know it:

| person | state today | by |
|---|---|---|
| Brad Buckley | blank | migration 1926 |
| Tom Oliverson | blank | migration 1926 |
| Terry Wilson | **chair 5** | migration 1931, re-seated on 87(R) **HB 4470**, which he authored — a state tax on federal renewable-energy credits received by wind generators |

Working from the measurement alone would have re-adjudicated three settled rows and probably
reverted Wilson's correct re-seat. This is the second pass in a row where that check paid.

## 4. The six adjudications

### (1) Fair Share Yea voters → taxes **3 → 2** (7 rows)

Chair 3 is *"Keep the current tax system mostly as-is with small adjustments to close unfair
loopholes."* These seven voted to amend the Constitution to create a new bracket — not "as-is", and
a surtax is not a loophole closure. **The chair they held was affirmatively wrong.**

🔑 **The instrument picks between the two raise-side rungs**, so this is not the least-extreme-option
tiebreaker. **Article CXXI of the Articles of Amendment** — read in the Constitution itself, not in
a summary — lays an additional **4 per cent** tax on annual taxable income above **$1,000,000**,
indexed for cost of living, and dedicates the revenue, subject to appropriation, to public
education, public colleges and universities, and the repair and maintenance of roads, bridges and
public transportation.

- chair 1 — *"Significantly raise … to fund **MORE** public services"*
- chair 2 — *"Moderately raise … to fund **EXISTING** services"*

Every dedicated purpose is an **existing** service category, which is chair 2's discriminating limb
in the ladder's own words; and the base is a single bracket above $1M with every other rate
untouched, which reads as *moderately*.

⚠ **Honest about what does not fit:** both rungs say *"and large companies"*, and Article CXXI is a
personal income surtax that leaves corporations alone. That limb is unmet by **either** rung
equally, so it does not separate them.

✅ **The vote was verified against the primary record by this pass**, not inherited from the 1902
repair text: Senate Roll Call #48 of the 192nd, *"S.5 — Question on again agreeing to the
amendment"*, **YEAS 38 Senators + 121 Representatives = 159; NAYS 2 + 39 = 41.** All seven are in
the Yea lists.

### (2) Fair Share Nay voters → taxes r4 **blank** (6 rows)

Chair 4 is *"Cut taxes for everyone **and** scale back public services to match"* — two limbs. A vote
against one tax increase proves the **side**, not the rung, and states neither limb. The rest of
each row is uninstrumented characterisation. ⚖ Same shape migration 1927 blanked for the ROE Act Nay
voters: **direction only**.

⚠ Chair 3 is what a Nay vote most nearly supports — and reaching for it is exactly the
least-extreme-option tiebreaker the standard names as the signal a row is **not** evidenced. Declined.

✅ All six verified in the Nay list of the same roll call.

### (3) Ballotpedia themes → taxes r4 — **2 keep / 3 blank**

⚖ **Admissibility first, and it is not what a short note would suggest** — see §5.

| | member | their own words | why |
|---|---|---|---|
| **keep** | Glen H. Sturtevant, Jr. | *"government should \[learn to] live with less and we keep more of what we earn… I'll be a vote for lower taxes"* | both limbs |
| **keep** | Mark J. Peake | *"Keeping Taxes Low"* + *"cut back wasteful government expenditures and help balance the budget by **limiting the scope of government**"* | both limbs |
| blank | Mark D. Obenshain | *"**Holding the line** on Taxes… higher taxes and fees would be particularly devastating"* | opposing increases is not cutting; no service limb |
| blank | Terry L. Austin | *"**hold down** taxes"* | same |
| blank | Todd E. Pillion | *"Virginia has one of the highest **corporate** tax rates… I will fight to oppose such taxes"*, and under *"Coal"*, *"job-killing regulations and taxes"* | sector-specific, not "for everyone"; no service limb |

### (4) MA police reform act → public-safety-approach r4 **blank** (5 rows)

Chair 4 is *"Increase police **staffing, equipment, and pay** to improve response times and deter
crime"* — three named mechanisms. The evidence is a vote **against** the 2020 accountability act,
whose subject is qualified-immunity limits and POST certification. Not one of the three mechanisms
appears. ⚖ Migration 1927 blanked the **r2** cluster from this same instrument as off-axis, and its
ledger predicted this one would follow. It does.

### (5) Ballotpedia themes → healthcare r4 — **3 keep / 1 blank**

Chair 4 is *"Only help the poorest people afford healthcare and leave everyone else to employers and
private insurance."*

| | member | why |
|---|---|---|
| **keep** | David R. Suetterlein | opposes expanding Obamacare **+** *"market-based competition"* for the rest |
| **keep** | Glen H. Sturtevant, Jr. | *"I oppose the expansion of Medicaid and Obamacare… Medicaid is already growing at an unsustainable rate"* |
| **keep** | Todd E. Pillion | opposes expansion **+** *"legislation that allows the private sector to grow in order to drive the price of premiums down"* |
| blank | M. Keith Hodges | *"Oppose big government healthcare mandates… preserve the doctor-patient relationship and patient choice"* — nothing about who gets help; **the row's own prose concedes it**, calling the quote merely *"consistent with"* limiting government's role |

🔑 **Opposing EXPANSION is the mirror of migration 1928's rule** that expansion proves a floor and
never a ceiling: declining to extend eligibility beyond the existing population *is* a statement
that help stops at the poorest — chair 4's first limb, stated as a position.

### (6) MA rent stabilization → housing **1 → 3** (3 rows)

🔴 **The housing ladder is not merely renumbered between seasons, it is RESTRUCTURED**, and both
revisions were read before writing — the trap that put a wrong chair in prod in migration 1935.

| | Season 1 | Season 2 |
|---|---|---|
| 1 | Directly build and operate public housing so anyone who needs a home can get one | Make government the main provider — build and operate public housing so everyone is guaranteed a home |
| 2 | **Use rent caps**, require affordable units, and publicly fund new housing | *(new rung)* Build a large public housing sector that competes with the private market |
| 3 | targeted subsidies, first-time buyer help, easier permits | Build no public housing, but set binding rules on the private market like **rent caps** or required affordable units |

Season 2 inserted a rung at position 2 and split the old rung 2's content. **Chair 1 is stable across
both seasons**, which is how we know this is a genuine mis-mapping and not a renumbering artefact:
rent stabilisation was chair **2** on the S1 ladder and is chair **3** on the S2 ladder, and was
**never chair 1 on either**.

🔑 **The enacted text was read, not the title.** 194/H2328, *"An Act enabling cities and towns to
stabilize rents and protect tenants"*: §2 lets a municipality *"impose a limit on the size of annual
rent increases"* and require just-cause eviction; §4(a) caps any annual increase at *"the annual
change in the Consumer Price Index for the applicable area or 5 per cent, whichever is lower"*. **It
creates and funds no public housing at all** — it regulates privately owned units. So **both** of
chair 3's limbs are satisfied by the instrument, *including the negative one*, while chair 1's
"government the main provider" is evidenced by nothing on the row.

✅ The cosponsorships were verified on each bill's own cosponsor page by migration 1900; those
citations are carried forward unchanged.

## 5. ⚖ A standing note that was being read backwards: `evidence_basis`

Working these clusters turned up a misreading worth recording, because it would cause **wrong
refusals** elsewhere.

`compass_topic_roles.evidence_basis` is **a restriction on RECORDS, never on own words.** From
CLAUDE.md, *"Scope decides the evidence"* (ruling 2026-10-06, option B):

> **A record needs a lever**: a rung no officeholder at this level can act on cannot be evidenced at
> this level by a record. **The person's own words can.** `compass_topic_roles.evidence_basis` marks
> a (topic, level) `own-words` when no rung has a lever there.

So:

- `evidence_basis = 'own-words'` → **no lever** at this level → only the person's own words can seat
  the chair. This is the restrictive value.
- `evidence_basis = 'record'` → the level **holds a lever** → a record can seat the chair. It does
  **not** make own words inadmissible.

`topicApplicability.ts` implements exactly this: `ownWordsLevels()` collects only the `own-words`
rows, and `build-stance-topic-bundle.ts` prints *"— OWN WORDS ONLY at this level"* for them. There
is no "record only" concept anywhere in the code.

Taxes and healthcare are both `record` at `state` scope, so the nine Virginia campaign-theme rows
are **admissible**, and the two clusters turn purely on whether each quotation describes the chair.
Had the column been read the other way, all nine would have been blanked on a false ground.

## 6. Gates, in the order they were run

| gate | when | result |
|---|---|---|
| serving-row check, all 36 keys | before anything | removed 3 rows (cluster 7) from the queue |
| `audit-chair-evidence.mjs --csv` | pre-write | **OK — all 10 valued rows name an instrument** |
| `check-stance-sources.mjs` | pre-write baseline | OK, **789 across 4 checks** |
| `dry-run-migration.mjs` | pre-write | all in-migration assertions passed, rolled back |
| `apply-migration-file.mjs` | write | applied in one transaction, 25 answers + 25 contexts |
| direct SQL, outside the migration | post-write | 25/25 at their adjudicated value; the 11 untouched rows still carry their old `updated_at`; Season 1 unmoved |
| `audit-chair-evidence.mjs --check` | post-write | **OK — 10 rows**, not a vacuous 0 |
| `check-stance-sources.mjs` | post-write | **identical to baseline** |

🔑 The CSV fed to the pre-write gate was **generated from the migration's own `$txt$` blocks**, so the
text gated is necessarily the text written.

🔑 `check:stance-sources` is unchanged before and after, which is the expected result: the gate's
universe is `WHERE pa.value <> 0`, so blanked rows leave it and the re-seats keep their sources. **No
baseline moved, so this pass does not put master's stance gate in the red-by-construction state.**

⚠ One prediction of mine was wrong and is recorded rather than quietly dropped: I expected
`BALLOTPEDIA_ONLY` to fall from 162 to 158 as the four Ballotpedia blanks left the universe. It
stayed at **162**. That check evidently does not scope on the answer value the way the others do.
Harmless here — the backlog did not grow — but it means **BALLOTPEDIA_ONLY cannot be used to measure
the effect of a blanking pass.**

## 7. ▶ What this leaves open

1. **Ryan's stale prose.** Daniel J. Ryan's abortion row says the ROE Act *"remov[ed] the 24-week
   gestational limit"*. It did not — the Act kept the 24-week line and widened the exceptions after
   it. The **chair is right** and the 1900 repair record on the same row states the structure
   correctly, so this is stale prose beside a correct chair, not a chair defect. Fix it in a
   prose-forward pass, not a chair migration.
2. **The remaining unread clusters.** `../2026-10-21-repaired-rest-sample/clusters.json` holds 68
   clusters, 24 of them 3+. With 1926, 1927 and this pass, the 3+ band is worked; **95 fingerprinted
   rows still sit in unread clusters of 1–2, plus 165 rows that fingerprint to no named instrument.**
3. **The contradiction check (PR #1085)** still has 119 groups / 1,090 rows as a reading queue.
4. **Re-read the two clusters 1926 blanked that the sample would have re-seated** — TX
   Medicaid-expansion → healthcare (13) and TX SB13 → climate (4). Still open from 1927's §5.1.
