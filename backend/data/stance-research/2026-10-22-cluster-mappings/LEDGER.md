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
2. **🔴 Migration 1921 kept two members (Hernandez, Ishii) at deportation chair 2 on sanctuary
   instruments.** That reading reached chair 2 the same way this pass just rejected, so those rows
   are very likely defective. Re-examine rather than treat as precedent.
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
