# Working the defective clusters as MAPPINGS — migration 1927

**2026-10-22.** Applied live, then verified from outside the migration's own guards.
Follows `../2026-10-21-repaired-rest-sample/MEASUREMENT.md`, which found that **the cluster, not
the row, is the unit of defect**: 231 of the 396 citation-repaired rows outside the generic block
fingerprint to a named instrument, and a wrong rung mapping is wrong for *every* member citing that
instrument. Eight clusters were read and found defective.

---

## 1. What was outstanding, and what was already gone

The eight defective clusters cover **62 rows** — not the 66 quoted in the measurement and carried
into two memory files; see the correction note in that file.

**Three of the eight were already settled before this pass started.** Migration 1926 (PR #1105,
merged) swept every Season 2 row carrying the migration-1903 disclaimer *"it does not by itself
separate the rungs within that side"*, and that census caught all 23 rows of the three TX clusters:

| rows | cluster | settled by |
|---:|---|---|
| 13 | TX Medicaid-expansion filings → healthcare r2 | 1926 (blanked) |
| 6 | TX SB13 (anti-ESG) → fossil-fuels r4 | 1926 (blanked) |
| 4 | TX SB13 (anti-ESG) → climate-change r5 | 1926 (blanked) |

🔑 **Checking the SERVING row rather than the queue's record is what surfaced this.** All 23 read
as `value = 0` in Season 2 with a single shared `updated_at`, which is what sent us looking for the
pass that did it. Working from the measurement alone would have re-adjudicated 23 settled rows.

⚠ **1926 and this pass disagree about two of those three, and 1926's answer stands.** The sample
had re-seated TX Medicaid → healthcare to rung 3 and TX SB13 → climate to rung 4. 1926 blanked them
instead. A blank is the conservative state and 1926 says so explicitly — *"these rows are
candidates for re-seating, not write-offs"* — so the re-seats are now a **re-read against the
record**, not an edit to a seated row. Left as follow-up (▶ §5).

## 2. The five clusters this pass adjudicates — 39 rows / 28 people

| rows | cluster | was | now | why |
|---:|---|---:|---:|---|
| 14 | MA ROE Act H.5179 → abortion | 1 | **2** | the Act's own structure is rung 2 |
| 11 | MA police reform act S.2963 → public-safety | 2 | **blank** | off-axis instrument |
| 7 | MA ROE Act H.5179 → abortion (Nay voters) | 4 | **blank** | direction only |
| 4 | MA jail/prison construction moratorium → jail-capacity | 1 | **blank** | no mechanism on either candidate rung |
| 3 | MA Safe Communities Act → deportation | 1 | **blank** | instrument does not legislate on the question |

**14 re-seated, 25 blanked.** Every cluster was first checked for homogeneity — all 14 ROE rows are
Yea voters, all 7 are Nay voters, all moratorium and Safe Communities rows are verified cosponsors,
all 11 police-reform rows are migration-1900 citation repairs — so one mapping decision really does
govern the whole cluster. None of the 39 carries the 1903 disclaimer, so this pass and 1926 are
disjoint; the migration's Guard 4 enforces that rather than asserting it.

### The one re-seat, and why it is the only one

**The ROE Act is viability-structured**, verified against the record rather than inherited from the
sample: H.5179, enacted 2020 over the Governor's veto (House override 107-46, Senate 32-8), protects
abortion through 24 weeks and after 24 weeks only on a fatal fetal anomaly or to preserve the
patient's physical or mental health. Chair 2 — *"legal and accessible through the second trimester
with rare exceptions afterward"* — is that structure in the ladder's own words. Chair 1 demands
*"all stages"* **and** *"publicly funded"*, and the Act is neither. **The instrument defines the
chair.**

### 🔴 Where this pass departs from the sample's reads — two clusters, 7 rows

The sample re-seated jail-capacity and deportation to chair 2. **Both are blanked here instead**,
after reading what the instruments actually contain:

- **Jail-capacity.** S.2030 (192nd General Court, filed, never enacted) freezes construction,
  expansion, conversion and renovation of correctional facilities for five years and allows routine
  maintenance. Chair 1 requires *redirecting* incarceration funding into community programmes — a
  freeze redirects nothing. Chair 2 requires *pretrial diversion, bail reform and treatment
  alternatives*; the moratorium is only chair 2's trailing clause (*"rather than building new
  capacity"*) and contains none of its three named mechanisms. ⚠ **Moving the row to chair 2
  because chair 1 is too strong is the least-extreme-option-on-that-side TIEBREAKER, and the
  standard names reaching for it as the signal that a row is not evidenced.**
- **Deportation.** The Safe Communities Act limits *state and local cooperation* with federal
  immigration enforcement — barring 287(g) agreements, barring holds on an ICE detainer alone,
  restricting release notifications. This ladder asks **who should be deported**, which a state
  legislature does not decide. Chair 2's *"only serious violent crimes"* threshold appears nowhere;
  its nearest clause still permits ICE notification when someone is released after serving a
  sentence, which governs **notification**, not which convictions warrant removal.

⚖ **This is the measurement's own lesson applied against its own reads:** a rung stating a broad
DIRECTION is usually described by the evidence, a rung stating a MECHANISM or an EXCEPTION
FRAMEWORK usually is not. Both of these are mechanism rungs.

## 3. Gates, in the order they were run

| gate | when | result |
|---|---|---|
| `audit-chair-evidence.mjs --csv` | **pre-write** | OK — all 14 valued rows name an instrument |
| `check-stance-sources.mjs` | pre-write baseline | OK, 790 across 4 checks |
| `dry-run-migration.mjs` | pre-write | all in-migration assertions passed, rolled back |
| `apply-migration-file.mjs` | write | applied in one transaction |
| direct SQL, outside the migration | post-write | 39/39 hold the adjudicated value; Season 1 unmoved |
| `audit-chair-evidence.mjs --check` | post-write | OK — **14 rows**, not a vacuous 0 |
| `check-stance-sources.mjs` | post-write | **identical to baseline** |

🔑 **`check:stance-sources` is unchanged before and after, and that is the expected result, not a
weak one.** The gate's universe is `WHERE pa.value <> 0`, so a blanked row leaves it; the one
re-seat keeps its sources. **No baseline moved, so this pass does not put master's stance gate in
the red-by-construction state** — a later red there still means something.

⚠ The `--check` run was read for its **count**, not just its exit code: pointed at rows that do not
exist, or fed a bare array, it prints "all 0 row(s)" and exits 0.

## 4. The pre-write gate is a floor, and it says so

`--csv` is a **lexical** test: it asks whether the reasoning names an instrument, never whether that
instrument establishes *that chair*. It passed all 14 ROE rows — and it would equally have passed
the 7 rows this pass blanked, every one of which names a real act. **The gate cannot tell a
chair-shaped instrument from a directional one; a human read is what separated them.**

## 5. ▶ What this leaves open

1. **Re-read the two clusters 1926 blanked that the sample would have re-seated** — TX
   Medicaid-expansion → healthcare (13) and TX SB13 → climate (4). Now a re-seat from blank against
   the record, which is the cleaner operation.
2. ✅ **DONE — migration 1930 (§6).** Migration 1921 kept members at deportation chair 2 on
   sanctuary instruments; all are now blank. It was **three** rows, not the two this item named —
   **Hugo Soto-Martinez** (1921 ledger row R21) was kept the same way and the note missed him.
3. **Sample the 8 unread clusters of 3+ (36 rows)** — Fair Share → taxes r3 (7) and r4 (6),
   Ballotpedia themes → taxes r4 (5), police reform → public-safety r4 (5), Ballotpedia themes →
   healthcare r4 (4), rent stabilization → housing r1 (3), SB13 → climate r4 (3), ROE Act →
   abortion r2 (3). 🔑 **Two of these are neighbours of clusters just adjudicated**, so they are the
   cheapest reads in the queue: police reform r4 is off-axis for the same reason r2 was, and ROE
   Act r2 is where the 14 just landed.
4. **95 fingerprinted rows sit in clusters nobody has read**, plus the 165 rows that fingerprint to
   no named instrument at all.
5. **The contradiction check (PR #1085) still has 119 groups / 1,090 rows** to work as a reading
   queue.

---

## 6. Migration 1930 — the 1921 sanctuary rows, re-examined

**2026-10-22, same day.** Closes open item 2 above. ⚖ **A ruling that implicates earlier rows is
not self-executing** — 1927 deliberately did not reach these; they are read here on their own
evidence.

**Three rows, all blanked**, each a 1921 KEEP at deportation chair 2:

| 1921 row | person | evidence |
|---|---|---|
| R01 | Adena Ishii (Berkeley) | unanimous council vote reaffirming sanctuary status + her own remark that some cities actively assist ICE |
| R10 | Eunisses Hernandez (LA) | co-introduced the 2023 motion that became LA ordinance 188441 |
| R21 | Hugo Soto-Martinez (LA) | introduced that motion with Hernandez and Raman |

🔴 **1921's own reasoning states the defect.** R01: *"Enforcement-sceptical direction; rung 1 (stop
deportations entirely) needs more, **so narrowing lands on 2**."* R10: *"rung 1 needs more."* That
is the least-extreme-option tiebreaker, which the standard names as the signal a row is **not**
evidenced rather than as a way to pick a chair.

🔑 **The decisive point is the project's own adjudication.** 1921 seated the *same ordinance* at
chair 1 of the separate **`local-immigration`** ladder for Hernandez, writing that there *"it is
squarely on-axis"* (R14). **Squarely on-axis there concedes off-axis here.** That row is untouched
and Guard 3 refuses to run if it ever stops being seated at chair 1.

### 🔴 The one real argument the other way — and why it did not carry

Press coverage reports that LA ordinance 188441 carries an **LAPD carve-out for "serious
offenses"**, which Council President Harris-Dawson described as letting police contact ICE about a
migrant *convicted of a violent felony* who was deported and returned. **If the enacted text drew
that line, this would be a re-seat, not a blank** — it is close to chair 2's own words.

**It could not be verified.** The amlegal code library returned HTTP 403, the City Clerk's document
host did not respond, and the only available description is **a reporter's paraphrase plus a
councilmember's spoken characterisation** — the article does not quote the ordinance.
⚖ **Same shape as the RFMA cluster (migration 1925): A CHAIR DECIDED BY A PARAPHRASE.** The
standing rule is to read the enacted text and never seat from a news summary.
⚠ And as described the carve-out is **narrower than chair 2 anyway** — it concerns re-entry after a
prior removal, not a general proposition about whom to deport.
▶ **If the enacted Chapter 19 text is obtained and does draw chair 2's line, the two LA rows are a
re-seat candidate on that text.** Ishii's Berkeley reaffirmation carries no such carve-out.

### ⚠ Admissibility is not sufficiency

`compass_topic_roles` marks **deportation/local** as `evidence_basis = 'own-words'`,
`is_required = false`, so own words *may* seat this chair. That settles what **kind** of evidence is
allowed, never whether the evidence **describes** the chair. Ishii's remark criticises cities that
assist ICE; it states no removal threshold.

### ⚠ What this leaves behind

**Soto-Martinez and Ishii have no `local-immigration` row at all**, so for them the sanctuary
evidence now has no on-axis home. That is **a gap to seed, not a reason to keep an unevidenced
chair** — Soto-Martinez introduced the same LA motion Hernandez is seated on, so his
`local-immigration` row is a strong candidate to seat at chair 1 on the same evidence. ▶ Seeding a
new row is research, not adjudication; left for a pass that can do it properly.

### Chain checked and closed

1921's R01 cites *"the Grijalva and Menendez rulings in mig 1920"* as precedent. **Neither has a
deportation row in Season 2 at all**, so the chain does not propagate to live rows and stops here.

### Gates

Dry run (all assertions passed, rolled back) → apply → **direct SQL outside the migration**: 3/3 at
`value = 0`, each carrying the withdrawal notice and its original reasoning verbatim, sources
intact, Hernandez's `local-immigration` row unmoved at chair 1 with its original `updated_at`.
`check:stance-sources` **identical before and after** (790 across 4 checks, no baseline moved).
No re-seats in this migration, so the chair-evidence CSV gate has nothing to score — it scores only
valued rows.

---

## 7. Migration 1932 — seeding the on-axis rows 1930 left empty

**2026-10-22.** Closes the gap §6 named: Soto-Martinez and Ishii had **no `local-immigration` row
at all**, so blanking their deportation chairs left verified evidence with nowhere on-axis to sit.

⚖⚖ **A SEED IS A BIGGER CLAIM THAN A BLANK.** Blanking needs only a showing that the evidence does
not reach the chair; seating asserts affirmatively that this person holds this stance. Both rows
were therefore built from **primary documents read in full** — the enacted ordinance in each city,
plus a primary record of the person's own act.

### Chair 1 has two limbs, and both had to be found in the enacted text

> *"Refuse all ICE detainers; prohibit local employees from sharing immigration status information
> with federal agencies"*

Chair 3, the nearest weaker neighbour, carries **neither** limb (*"follow federal law as required
but do not use local resources for proactive immigration enforcement"*). That is exactly why the
text had to be read rather than assumed — a sanctuary ordinance could easily be a chair-3 ordinance.

| person | their own act (primary record) | enacted text |
|---|---|---|
| **Hugo Soto-Martinez** | LA council file 23-0243 lists him as a **Mover**; originating motion 2023-06-09 is *"Motion (Soto-Martinez - Rodriguez)"* | Ord. 188441 §19.191(c) bars responding to "any administrative warrant or other request to detain, transfer, or notify any Immigration Agent"; §19.192 bars providing data that can "determine or trace a person's Citizenship or Immigration Status" |
| **Adena Ishii** | City Attorney's report to Council, 2025-09-09: *"In January 2025, the Mayor convened a Sanctuary City Task Force that recommended codifying these sanctuary policies in an ordinance"* | Ord. 7,984-N.S. §13.114.030(C)(5) bars "Complying with any civil immigration warrant or request to detain, transfer, or notify"; (C)(4) bars "Disseminating or disclosing Protected Personal Information to Immigration Authorities" |

⚠ **Ishii's chair does NOT rest on the vote.** Ordinance 7,984-N.S. passed **9-0, none absent**, and
a unanimous vote is weak evidence of an individual's position — the rule that blanked Newhouse on
385-41. It rests on her convening the task force that produced the ordinance, an act recorded in an
official City Attorney report, with the recorded Aye as corroboration.
⚠ Berkeley's §13.114.050 exceptions (consent, necessity to provide a City service, or where
required by state/federal law incl. 8 U.S.C. 1373) do **not** reopen either limb — none permits
honouring a civil detainer.

### 🔴 The press had the LA carve-out BACKWARDS, and the enacted text says so

§6 blanked three rows partly because the reported LAPD "serious offenses" carve-out could not be
verified. **The enacted text was obtained for this pass** (the City Clerk PDF has a text layer;
`pdftotext` reads it — the earlier 403s were the amlegal code library, not the Clerk).

**Sec. 19.191(b)** does not *permit* cooperation for violent felons. It **requires** that, before a
probable-cause arrest for illegal re-entry under 8 U.S.C. §1326(a) carrying the §1326(b)(2)
aggravated-felony enhancement, *"City personnel shall obtain approval from their respective
department's designated immigrant affairs liaison."* **A restriction, reported as a permission.**
✅ **§6's blanks were right, and now rest on the enacted text rather than on "could not verify".**

### ⚠⚠ Found while writing this, recorded not fixed: Ishii's Season 1 row is INVERTED

Her **Season 1** `local-immigration` row sits at **chair 5** — *"Direct local police to actively
assist with immigration enforcement and support federal detention operations"* — while its own
stored reasoning says she *"reaffirmed Berkeley's sanctuary city status … stating 'we will not be
doing that' regarding ICE assistance"* and *"led passage of a codified sanctuary ordinance in
September 2025"*. **The row asserts the opposite of the evidence printed beneath it.**
🔑 It carries the **same `topic_revision_id`** as the Season 2 ladder, so this is **not** a
season-remap artifact — it is a chair inversion.
🔴 **Season 1 is closed and migration 1932 does not touch it.** ▶ Logged for a pass that can; worth
running `chair-inversion-scan.mjs` over Season 1 to see whether it is systemic.
🔑 It also **independently corroborates the seed**: a separate research pass, working from different
sources, likewise recorded Ishii as having *led* the ordinance.

### A guard bug worth keeping

The first draft asserted that **no** Season 1 row existed for these pairs, and failed its own dry
run — **both targets already had one**, untouched since 2026-08-26. The assertion was testing a
pre-existing condition it had not caused. Replaced with a **snapshot-and-compare**, the same shape
1927 and 1930 use. ⚖ *"Season 1 must not move"* is a delta, never an absence.

### Gates

`audit-chair-evidence --csv` **pre-write** (2/2 name an instrument; the CSV is generated **from the
migration file** so the gate tests the text that will actually be written) → dry run → apply →
`--check` post-write reading **2 rows** → direct SQL outside the migration: both at chair 1 with two
primary citations each, Season 1 unmoved at its original `updated_at`, the three deportation blanks
still blank, Hernandez's row untouched. `check:stance-sources` **identical before and after**, with
`ANSWER_WITHOUT_CONTEXT` still 0 — the context rows were inserted **before** the answers for exactly
that reason.

---

## 8. Running `chair-inversion-scan.mjs` over Season 1 — and what it could not see

§7 logged "worth running `chair-inversion-scan.mjs` over Season 1 to see whether it is systemic."
Done. **The scan does not answer the question, and finding out why was the useful part.**

### 🔴🔴 First, a correctness bug in the scanner itself — fixed in this commit

Its query joined `politician_context` to `politician_answers` on `(politician_id, topic_id)` with
**no season predicate**. Both tables are keyed `(politician_id, topic_id, season_id)`, so a pair
with rows in two seasons **cross-joined**: four rows where there should be two, **pairing Season 2
reasoning with a Season 1 chair** and vice versa.

Measured: **4,728 of 34,501 pairs span more than one season**; the unscoped query returned
**47,843** rows where season-matched joining returns **38,417** — **~9,400 phantom rows, ~20%**.
Those rows both *manufacture* inversions and *distort the per-topic calibration* that decides which
rows get flagged at all. Fixed by joining on `season_id` and adding an optional `--season`.
⚖ This is the same trap already documented in `audit-chair-evidence.mjs`: **name the season for any
pair that has rows in more than one.** It was written down in one script and not the other.

### The run: 80 flags, and they are overwhelmingly FALSE POSITIVES

| flags | topic |
|---:|---|
| 45 | School Vouchers & Public Education Funding |
| 9 | Healthcare Access |
| 8 | Climate Change and Environmental Protection |
| 7 | Same-Sex Marriage |
| 6 | Affordable Housing |
| 3 | Misinformation and Algorithms |
| 1 each | Civil Rights, Ukraine |

**43 of the 45 School Vouchers flags have reasoning explicitly about public-school funding, sitting
at chair 1 — which reads "Fully funding public schools and eliminating voucher programs."** Those
are *correct* seatings. The cause is the failure the script's own header documents: **a verb has an
OBJECT the regex cannot see.** This ladder has something to *support* at BOTH ends — public schools
at chair 1, vouchers at chair 5 — so a PRO lexicon cannot be monotonic in the chair number, and
`RESTRICTIVE_ANYWHERE` does not catch "supports public education funding".
The sampled flags in the other topics are the same shape: Mike Kelly at Same-Sex Marriage chair 5
("voted NAY on the Respect for Marriage Act, cosponsored the Federal Marriage Amendment") is
*correctly* seated; "cosponsored" read as PRO.

### 🔴 And it found NONE of the real ones, because the topic is UNCALIBRATED

`Local Immigration Enforcement` calibrates at **strength 0.10 → UNCALIBRATED**, so it contributes
**zero flags**. ⚖⚖ **The detector is blind on the exact topic that prompted the scan.** A clean
report from it would have meant nothing.

### What a targeted structural probe found instead — a BERKELEY CLUSTER

One query, no lexicon: on Season 1 `local-immigration`, **chair 5 holds 12 rows and 8 of them
mention "sanctuary" (67%) — a higher rate than chair 1 itself (45%)**, where sanctuary belongs.
Reading all 12: **9 are correctly seated** (DeMaio's AB-18, Trump's 287(g) EO, Fortunato and
McCune's SB 5002, Fattman's SHIELD Act, Boldyga's H.2573, Paxton, Vance, Pratt) and **3 are
inverted — all three Berkeley**:

| person | chair 5 says | their reasoning says |
|---|---|---|
| **Adena Ishii** | direct police to actively assist ICE | "we will not be doing that" re ICE assistance; led the sanctuary ordinance |
| **Cecilia Lunaparra** | " | co-sponsored Berkeley's sanctuary reaffirmation and ICE non-cooperation resolution |
| **Shoshana O'Keefe** | " | co-sponsored the Sanctuary City Contracting Ordinance |

Chair 4's 15 sanctuary-mentioning rows are by contrast **correct** — anti-sanctuary officials
opposing SB54, cosponsoring the Stop Sanctuary Policies Act, backing 287(g). ⚠ Three there are
seated on *inference* rather than evidence ("likely supports ICE detainer compliance", "Inferred
from state law context", and Berkeley auditor **Jenny Wong**, whose reasoning states no position at
all) — the absence-seating defect class, not an inversion.

🔑 **So it is a cluster, not a scatter** — the same lesson as §2: one bad mapping applied across the
members of one body.

### ▶ Nothing here is writable, and that is the finding

**All of it lives in Season 1, which is closed.** Of the four, only Ishii has a Season 2 row — and
that is the one migration 1932 just seeded at chair 1, correctly. Lunaparra, O'Keefe and Wong have
**no Season 2 row at all**, so nothing voter-facing in the open season is wrong.
▶ If Season 1 is ever reopened or re-exported, these four are the queue.
▶ The three Berkeley councilmembers are also seeding candidates for Season 2 on the same primary
ordinance text used in migration 1932.

---

## 9. Migration 1934 — the Berkeley sanctuary sponsors

**2026-10-22.** §8 queued "the three Berkeley councilmembers are Season 2 seeding candidates".
**The named roster did not survive contact with the records**, and that is the finding.

### 🔴 The Season 1 corpus asserts a sponsorship that does not exist

§8 named Ishii, **Lunaparra** and **O'Keefe** as the inverted Berkeley rows, and the Season 1
reasoning says O'Keefe *"co-sponsored the second reading of Berkeley's Sanctuary City Contracting
Ordinance"*. **She did not.** She appears on **no sponsor line of any of the three instruments**;
her only record is an Aye on measures that passed unanimously.
⚖ **Had the Season 1 reasoning been inherited rather than checked, this pass would have seated a
voter-facing chair on a sponsorship that never happened** — in the very corpus just shown to be
defective. **O'Keefe is not seeded.**

### The sponsor lines, from the city's own records

| | (A) 2025-01-21 reaffirmation | (B) 2025-04-15 referral | (C) Ord. 7,994-N.S. |
|---|---|---|---|
| Ishii | co-sponsor | **author** | co-sponsor |
| **Lunaparra** | co-sponsor | co-sponsor | **author** |
| **Blackaby** | **author** | co-sponsor | co-sponsor |
| **Taplin** | co-sponsor | co-sponsor | — |
| Humbert | — | — | co-sponsor |
| O'Keefe | — | — | — |

**Seeded at chair 1: Lunaparra, Blackaby, Taplin** (operator's call among the evidenced sets).
⚠ **Humbert is not seeded** — one instrument is thinner than the bar this campaign has applied.
🔑 **Blackaby authored (A), the resolution that set codification in motion, and was never on the
original list.** The list came from a defective detector output; the records came from the city.

### The bar is unchanged from migration 1932

Berkeley's measures passed **9-0 and 8-0**, so an Aye seats nothing — the Newhouse rule. Every row
rests on **authorship or named co-sponsorship**. Guard 4 enforces it: a seed whose reasoning
records no `Author`/`Co-Sponsor` is refused.
Chair 1 is justified from **Ordinance No. 7,984-N.S.** as in §7 — `13.114.030(C)(5)` (no complying
with any civil immigration warrant or request to detain/transfer/notify) and `(C)(4)` (no
disclosing Protected Personal Information). Chair 3 carries neither limb.

### 🔑 A new guard, against a live hazard in this database

`essentials.politicians` holds **Cal-Access committee filer rows with the same names** —
"LUNAPARRA FOR BERKELEY CITY COUNCIL 2024; CECILIA", "TAPLIN FOR CITY COUNCIL 2024; TERRY", two
Blackaby filers. Seeding one of those would attach a voter-facing chair to a campaign committee.
Guard 2 discriminates cheaply: **a committee filer has no Season 1 row on this ladder; the
officeholder does** — which also proves the seed is the same person the inversion scan read. It
additionally requires `full_name` to match the seed's label exactly.

### ⚖ The Season 1 defect is INCONSISTENT, not uniform — which sharpens §8

Of the five Berkeley sponsors, **Season 1 seats Blackaby and Taplin correctly at chair 1** while
**Ishii, Lunaparra and O'Keefe sit at chair 5**. So it is not a Berkeley-wide mis-seed applied to a
cohort; it is three rows going wrong while two colleagues on the *same instruments* went right.
🔴 Season 1 is closed and migration 1934 touches none of it, Lunaparra's inverted chair 5 included;
the guard proves Season 1 did not move.

### Gates

`--csv` pre-write (3/3, CSV generated **from the migration file**) → `check:stance-sources` baseline
→ dry run → apply → `--check` post-write reading **3 rows** → direct SQL outside the migration: all
three at chair 1 with 4, 4 and 3 primary Berkeley citations, all Season 1 rows unmoved at their
original `updated_at`, and the six rows seated by migrations 1921/1932/1934 all at chair 1.
`check:stance-sources` identical before and after, `ANSWER_WITHOUT_CONTEXT` still 0.

### ▶ Left open

- **O'Keefe and Humbert** remain unseeded on this ladder, for stated reasons.
- Season 1's inverted rows (Ishii, Lunaparra, O'Keefe) stay inverted in a closed season.
- Berkeley auditor **Jenny Wong** sits at Season 1 chair 4 on reasoning that states no position —
  the absence-seating class, not an inversion, and she has no Season 2 row.

---

## 10. Jenny Wong — a NO-OP, and the queue her case points at

§9 queued Berkeley City Auditor **Jenny Wong**, seated at Season 1 `local-immigration` chair 4 on
reasoning that states no position. **Nothing was written, because nothing is writable.**

### Why there is nothing to do

Wong holds **seven Season 1 rows** — civil-rights, growth-and-development, homelessness,
homelessness-response, judicial-transparency, local-immigration, public-safety-approach — and
**every one infers a policy position from the duties of an auditor's office**: *"her audit work
focuses on procedural compliance"*, *"Wong's office applies this equity lens"*, *"her office
operates outside the police chain of command"*.

🔑 **The project has already named this shape.** Migration 1917 blanked her growth-and-development
row in Season 2 with: *"Shape: OFFICE DUTY. The cited activity is a duty of the office, not a
position on the question."*

**It caught one of her seven** — because the absence audit worked from a ranked model score (0.840
on that row) rather than from the person. ⚖ **The ranker found a row; the defect belonged to a
PERSON.** That is the same unit-of-defect lesson as §2, one level up.

But: **Season 1 is closed**, and in Season 2 Wong holds exactly one row — the one 1917 already
blanked, correctly. So her six remaining bad rows are all in a closed season, and **seeding her a
Season 2 `local-immigration` chair would be the very defect**: "operates within that city
framework" and "has not challenged sanctuary protections" are an office duty and an absence, not a
position. **No migration.**

### ▶ The queue her case points at — 21 live Season 2 rows, READ not written

Officeholders in administrative (non-legislative) offices still seated in Season 2:
**Treasurer 12 · Auditor of the Commonwealth 2 · Controller 2 · Treasurer and Receiver-General 2 ·
State Treasurer 1 · City Controller 1 · Assessor-Recorder 1** — 21 rows, 14 people.
⚠ **These are NOT automatically defective.** A Treasurer can hold a real position on housing
finance, and several here do (Conine advocating bond funding and criticising the legislature;
Pellicciotti proposing the Washington Future Fund; Mejia's own organising; Fleming's congressional
votes). **Reading them found three distinct shapes:**

**(a) 🔴 THE PROSE NAMES A DIFFERENT RUNG THAN THE CHAIR — 6 rows, self-contradicting, no lexicon
needed.**

| person | topic | chair | rung its own text names |
|---|---|---:|---:|
| Erick Russell | housing | 4 | 3 |
| Erick Russell | same-sex-marriage | 2 | 1 |
| Fiona Ma | housing | 3 | 2 |
| Joey Spellerberg | housing | 4 | 3 |
| Malia M. Cohen | housing | 3 | 2 |
| Steven Johnson | housing | 4 | 3 |

🔴 **PROBED FOR AN INSERTED RUNG FIRST, because a uniform +1 across a topic is exactly that
signature** — the trap that produced 13 wrong blanks in migration 1903. **It is not one.** Housing
rung 3 today reads *"Offer targeted help like subsidies for affordable projects, first-time buyer
assistance, and easier building permits"*, which is precisely what Russell's, Spellerberg's and
Johnson's prose describes; rung 4 is *"Cut regulations and zoning rules"*. Spellerberg's text even
says *"not ... full market deregulation"* **while seated on the deregulation chair**. The prose
matches **today's** numbering, so the chairs are one too high, not the prose one too low.
⚠ Ma's and Cohen's say *"new stance 2"* — the author knew the ladder had been renumbered and wrote
against the new one, which strengthens the same reading.

**(b) A CHAIR SEATED ON IDENTITY, PARTY, AN ENDORSEMENT, OR AN ABSENCE — the same-sex-marriage
cohort, 5 of 7.**
· **Russell**: *"first openly gay Black person elected to CT statewide office and is married to a
man"* — **personal identity is not a policy position.**
· **Cohen**: *"Equality California endorsed Cohen ... The organization ... endorses only candidates
who commit to these positions"* — **reasoning from an endorser's criteria**, not her record.
· **Pellicciotti**: *"has no anti-SSM vote or statement on record"* — **an absence**.
· **Goldberg**: *"throughout her career as a Massachusetts Democrat ... participated in the
Massachusetts Democratic Party community"* — **party affiliation**.
· **DiZoglio**: *"a strong supporter ... a consistent ally"* — no named instrument.
✅ Only **Fleming** is solidly evidenced: original cosponsor of the Marriage Protection Amendment
(H.J.Res. 32), which is chair 5's text almost verbatim.
⚠ Ma names real instruments (SJR 9, SB 1172) but **neither is about marriage** — off-axis.

**(c) OFFICE DUTY, Wong's own shape**: Steven Johnson — *"The Kansas Treasurer's office under
Johnson administers the Home In The Heartland grant program"*; José Cisneros — *"administered the
Empty Homes Tax and Commercial Vacancy Tax"*. **The office administering a programme is not the
officeholder's position on it.**

🔑 **Three shapes, overlapping**: Russell and Johnson appear in two each. ▶ Not written — this is a
reading queue of 21 rows over 14 people, and it is a separate pass from the cluster campaign.
