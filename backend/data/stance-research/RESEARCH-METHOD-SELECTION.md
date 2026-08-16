# Choosing a stance-research method: instrument-first vs person-first

**What this is.** A decision document for the next jurisdiction, written from measured results across
three Washington cohorts researched by two different methods between 2026-08-13 and 2026-08-16. It
exists because the obvious conclusion from the Seattle numbers is *wrong*, and a future session that
reads only those numbers will pick the wrong method for legislators.

**The two methods.**
- **Instrument-first** — index the legislative corpus, rank instruments by reach, read the enacted
  text of one instrument properly, then seat everyone who sponsored or voted for it.
- **Person-first** — take one official at a time and search the open web for what *they* have said:
  candidate questionnaires, voters' pamphlet statements, local news interviews, campaign material.

---

## The headline result, and why it is misleading on its own

Seattle's eleven city offices are a natural experiment: **the same eleven people were researched by
both methods**, three days apart.

| | Instrument-first (migs 1754 + 1759) | Person-first (mig 1784) |
|---|---|---|
| Corpus examined | **10,639** agenda items, 2020–2026, re-swept to **284** divided roll calls | **9** candidate questionnaires + ~6 articles |
| Rows produced | **2** | **42** |
| Officials covered | **1 of 11** | **11 of 11** |
| Distinct source hosts | 1 (Legistar) | 3 |

Twenty-one times the rows and eleven times the coverage, from roughly **one seven-hundredth** of the
reading. Every one of the 13 source URLs on the instrument-first rows was a Legistar attachment.

**Do not generalise from this table.** It is the strongest result in the file and the most dangerous.

---

## 🔴 The counter-result that inverts the naive lesson

The same instrument-first method, run against the **147 WA state legislators**, is the single most
productive thing done in this workstream:

| | WA legislature (instrument-first) |
|---|---|
| Corpus indexed | 3,411 bills |
| Instruments read in full | ~19 |
| Rows produced | **286** |
| Officials covered | **131 of 147** |
| Documented blanks | 49 |

That is roughly **15 rows per instrument read**. Seattle's person-first pass produced about **2.8 rows
per document read**. Per unit of effort, instrument-first on legislators was *five times more
efficient* than person-first on a city council.

**So the lesson is not "person-first is better."** Both methods worked spectacularly in one place and
failed in the other. The question is what distinguishes the places.

---

## 🔑 The actual rule

> **Match the method to the unit at which the office generates attributable evidence.**

An official leaves a trail only where their institution requires them to act individually and on the
record. Find that unit first, then pick the method that reads it.

| Office type | Where individual evidence accrues | Method |
|---|---|---|
| State legislator | **Bill sponsorship** — dense, attributable, per-person | Instrument-first |
| City / county councilmember | **Campaigns** — questionnaires, pamphlets, interviews | Person-first |
| Executive (mayor, county exec) | **Their own orders and budgets**, plus campaigns | Person-first, verified against orders |
| Prosecutor / elected attorney | **Charging policy and public advocacy** | Person-first |
| Administrator (assessor, clerk, sheriff, elections) | Usually **nowhere** — they execute others' policy | Neither; expect a blank, and see Class G |

### Why sponsorship carries legislators and votes do not carry councils

Measured, not assumed:

- **WA legislators sponsor densely.** Median sponsorships: **166 for Democrats, 78 for Republicans**
  across the biennium. Every member has a large, individually attributable record.
  ⚠ Only because the index covered **introduced** bills. An enacted-only index gives a median of
  **13 for everyone** and leaves minority-party members near-empty for reasons unrelated to their
  records — a party bias created entirely by corpus choice.
- **City councils vote, but almost never divide.** King County vote labels across the whole indexed
  corpus: **Yes 8,608 · No 105 · Excused 434 · Abstain 1.** Real dissent is **1.2%** of all votes.
  And only about **11 of 60** sampled agenda items carry any roll call at all — the rest are consent
  or procedural.
- **City sponsorship is weak evidence, inverting the legislative rule.** Three of three Strauss
  land-use "sponsorships" carry a `Mayor's leg transmitted to Council` history line. A Seattle
  sponsor on a land-use bill is routinely the council sponsor of mayor- or department-drafted
  legislation, not its author.
- **What divided votes are *about* differs by body.** Seattle's divided votes cluster on tax
  mechanics, procedure, appointments, labour agreements and fees. The ladders describe substantive
  policy. That mismatch — not a thin search — is why the method returned almost nothing.

🔑 The tell that was present in the original write-up and misread: *"Seattle's divided votes cluster
on tax mechanics, procedure, appointments and labour agreements, while the ladders describe
substantive policy."* That sentence is evidence the **method** was wrong for the body. It was
recorded as evidence the **record** was thin.

---

## The two failure signatures, so you can recognise them early

**Instrument-first is failing when:** you have read several top-ranked instruments end to end and
seated nobody; the divided-vote list is dominated by appointments, fees, labour contracts and
procedure; the officials with the thinnest records are the *newest* ones rather than the quietest
ones. In Seattle, five instruments were examined end-to-end for zero rows before this was believed.

**Person-first is failing when:** the officials are appointed rather than elected; their public
documents are biography rather than position; their statements are valence ("listening to, and
fighting for, us") rather than policy. Three King County officials hit exactly this.

### Diagnose before you index, not after

The Legistar index that produced two rows cost a year-by-year pull of 23,270 agenda items across two
clients. A **60-item sample** would have shown that only ~11 carried a roll call, and a single label
histogram would have shown 1.2% dissent. Both are minutes of work. Run them first.

---

## 🔑 The methods are complementary, not rival — and this is the part worth keeping

The temptation after Seattle is to retire instrument-first. That would be a serious mistake, for two
measured reasons.

### 1. Instrument-first is the better VERIFIER, because instruments cannot be fabricated

Person-first sources are what a politician *says*. Instruments are what they *did*. The pass that
worked used each to check the other:

- **Strauss's two instrument-first rows survived** re-checking against his questionnaire — the same
  chairs, from a completely different source class. That is the strongest form of confirmation
  available, and it is only possible because two independent methods were run over one person.
- **The 2023 questionnaires were tested against the September 2025 comp-plan votes** before anything
  was seated. Saka, Rivera and Rinck were corroborated. **Hollingsworth was not**, and her
  `residential-zoning` row was withheld as a documented blank rather than seated on a promise her
  record was in tension with.

> A campaign promise abandoned in office is not a sincere chair-match. Person-first supplies reach;
> instrument-first supplies proof. Run person-first for coverage, then test the resulting claims
> against the record before writing.

### 2. Instrument-first is the better DIAGNOSTIC — it is what found every ladder defect

Nearly the whole of `COMPASS-LADDER-TROUBLE-SPOTS.md` came from instrument-first work: `taxes` chair
4/5's unlegislatable consequence clause, `climate-change` chair 3 absorbing the entire middle,
`housing` chair 2's missing element, `abortion` chair 1's bundled funding requirement,
`voting-rights` chair 5's bundled conditions, `judicial-criminal-justice` chair 4/5's
indistinguishable purposes. Person-first found **two** gaps by comparison.

The reason is structural: instrument-first forces you to read enacted text against chair text
clause by clause, so a chair that cannot be reached *announces itself*. Person-first lets a fluent
candidate statement glide onto an approximately-right chair, and the ladder's defect stays hidden.

⚠ **So a corpus researched only person-first will look cleaner than it is.** If the goal includes
improving the compass rather than only populating it, keep instrument-first in the loop.

---

## Reachability is a property of a chair meeting a CORPUS

Both methods produced the same lesson from opposite directions, and it is the one most likely to be
mis-generalised:

- **`housing` chair 2 was declared unreachable** from the WA legislative corpus — it needs
  inclusionary zoning and an anchored search of 3,411 bills found zero instruments. **Seattle's MHA
  *is* inclusionary zoning**, so a city official can hold all three limbs. Dionne Foster does.
- **`taxes` chair 4 was declared broken** after four legislators across both parties were blanked on
  its consequence clause. **Reagan Dunn's voters' pamphlet states that clause outright.** Bills never
  legislate their own downstream effect on services; candidate statements are exactly the genre in
  which people do.

> Before recording that a chair is unreachable, name the corpus and the source class you searched.
> "Unreachable" without those qualifiers is a claim nobody can check and the next session will
> inherit as fact.

---

## Class G: the officials neither method can reach, and why that is a finding

Roughly a third of a county's elected roster does not legislate at all. The King County Sheriff does
not honour ICE detainers — but the office's own page presents that as compliance with three binding
authorities, one of which is **K.C.C. 2.15, the chapter created by the very ordinance that seated two
councilmembers on that same ladder**. The councilmembers who *wrote* the policy hold the chair; the
appointed sheriff who *executes* it does not. Same at the Assessor, where state law sets the
exemption thresholds.

**The test is advocacy vs administration.** It is not "is this person an administrator" — the King
County Elections Director *is* seated, because she requested prepaid postage for all voters and her
push became statewide law. Advocating a change in the law is a position; applying one someone else
wrote is not.

⚠ The trap is that an execute-only record *reads* like a strong stance. Seating it double-counts the
legislators who actually chose the policy, and attributes a position to someone who never took one.

---

## The procedure for the next jurisdiction

1. **Classify the roster by office type** before any indexing. Count how many are legislators,
   executives, and administrators. That count predicts the yield better than anything else.
2. **Sample 60 agenda items** and pull one vote-label histogram. If roll calls are rare or dissent is
   under a few percent, do not build the index.
3. **Find the questionnaire ecosystem.** Every metro has one — an urbanist or transit outlet, a party
   or district organisation, a voters' pamphlet. In Seattle it was The Urbanist (9 of 11 officials);
   in Beaverton it was washcodems.org (36 citations). Locate the year's endorsement page and harvest
   the linked PDFs.
4. **Do not stop at one source class**, in either direction. That is the error this whole document
   exists to prevent, and it is symmetrical.
5. **Test every campaign-sourced claim against the record** before seating it, and blank on conflict.
6. **Record what you searched, not just what you found.** A blank means "this source class could not
   reach it" — write that, and name the class.

---

## Cohort results as of 2026-08-16

| Cohort | Officials | Covered | Rows | Documented blanks | Method |
|---|---|---|---|---|---|
| WA legislature | 147 | 131 | 286 | 49 | instrument-first |
| Seattle city | 11 | **11** | 44 | 5 | person-first (2 rows survive from instrument-first) |
| King County | 14 | 11 | 35 | 4 | person-first |

The three King County officials with no rows are blanks by finding, not gaps: two are Class G, and
one was appointed three months ago with no public policy statement of any kind.

**Related:** `WA-SWEEP-PRECEDENTS.md` (every chair ruling), `COMPASS-LADDER-TROUBLE-SPOTS.md` (where
the ladders fail), `2026-08-15-seattle-council-web-sources.md` (the Seattle re-run in detail),
`scripts/wa-sweep/README.md` (the instrument-first tooling and the failures it encodes).
