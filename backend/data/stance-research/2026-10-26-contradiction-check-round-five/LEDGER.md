# Contradiction check, round five — migration 1946

27 rows read across two instruments. **12 written, all withdrawals.** 2 rows left alone, and a
14-row group deliberately left intact.
Queue `--sole` **132 groups / 807 rows → 131 / 800**.

| rows | instrument | ladder | decision | written |
|---:|---|---|---|---:|
| 13 | California AB 2655 (2023-24) | misinformation | withdraw 11, leave 2 | 11 |
| 14 | Texas HB 44 (89R) | abortion | **not defective**; one row goes | 1 |

Both targets serve from the **closed Season 1**, so both writes insert a Season 2 row. Season 1 is
untouched and the post-flight block proves it.

⚠ **No chair is seated by this file, so `audit-chair-evidence` has nothing to judge.** Running it
would print `OK: all 0 valued row(s)` — the vacuous pass its own header warns about. It was not run,
and that is recorded rather than presented as a passing gate.

This was a small pass by design: the queue's big mapping-shaped groups were consumed in rounds two
to four, and what sits at the top now is mostly sound. The three findings in §4 are larger than the
migration.

---

## 1. California AB 2655 → misinformation — 13 rows, 11 withdrawn

The ladder was rewritten between seasons at chairs 1 and 2, and the rewrite is what makes this group
look resolvable:

```
S1 c2  mandate fact-checking and transparency in how algorithms promote content
S2 c1  legally require platforms to remove false information
S2 c2  require platforms to label false content, RATHER THAN remove it
S2 c3  encourage voluntary standards for combating misinformation online
```

Every row describes AB 2655 as a **labelling** mandate — *"requiring platforms to label deepfake
political content"*, *"mandating disclosure labels on AI-generated political content"* — which lands
on Season 2 chair 2 almost word for word. I was about to re-seat all 13 there.

**Reading the Act reversed it.** Its Legislative Counsel's Digest:

> *"This bill … would require a large online platform, as defined, to **block the posting** of
> materially deceptive content related to elections in California, during specified periods before
> and after an election. The bill would require a large online platform to **label** certain
> additional content inauthentic, fake, or false during specified periods before and after an
> election in California."*

The Act carries **both limbs**. Chair 2 says *"rather than remove it"* and the blocking mandate
contradicts it. Chair 1 says *"remove false information"* and the Act is confined to election
content, defined windows, and large platforms. Chair 3 says *"voluntary"*, and a mandate is not.

**A vote on a package holding two chairs' content proves the side and not the rung** — migration
1925's rule, and the reason the title is never trusted.

### ⚖ The rows carrying more than the Act

Four rows are not bare. They were read, and the extra evidence strengthens the **side** without
choosing a rung:

| | beyond AB 2655 |
|---|---|
| the Governor | signed AB 2655, AB 2839, AB 2355 (disclosure labels on AI political ads) and SB 942 |
| the Attorney General | letters to Meta, YouTube, Twitter, TikTok and Reddit demanding action on disinformation |
| one member | *"supports much greater accountability by social media companies and strong regulation around AI"*, in her own words |
| one member | a cybersecurity background — CCPA amendments, IoT security bills |

None of that distinguishes removing false content from labelling it instead. All four are withdrawn
with the rest, and the notice says why rather than treating them as bare rows.

### ⚖ The two rows left alone

Two rows voted **No** on the Act and sit at chair 4, *"protect free speech online and prevent
government censorship"*. One states its reason in the row — opposing government-mandated content
restrictions *"citing free speech"*. A no vote on a mandate is consistent with that chair without
asserting anything further, and unlike chairs 1–3 it does not require the Act to have a shape it
does not have. They are not part of this defect.

---

## 2. Texas HB 44 (89R) → abortion — 14 rows, **not defective**, 1 withdrawn

🔑 **A 2/4 split that is the ladder working.** HB 44, the Life of the Mother Act, adds
medical-judgment exceptions to Texas's existing near-total ban and drew **61 co-authors from both
parties**. Co-sponsoring a narrow exceptions bill means opposite things depending on the rest of the
record, and these rows show it:

- **chair 2** — Democrats seated on wider records: a former House Minority Leader who opposed SB 8,
  HB 1280 and the trigger ban; a fifty-year women's-rights record.
- **chair 4** — Republicans seated on recorded floor votes **for the ban itself**. One row cites the
  House Journal by record number: Yea on SB 8 (83-64) and Yea on HB 1280 (81-61). Another cites the
  member's own candidate questionnaire: *"Abortion should not be allowed."*

These are good rows. The group needs no write, and the migration guards that it survives intact.

**One row is withdrawn.** It seats chair 2 on a bill the member is not recorded as having joined:

> *"**Did not appear on HB44 co-author list specifically**, but consistent Democratic caucus
> position."*

plus the district's geography. An absence of sponsorship and a caucus prior are not a position.

⚠ **It is the same member and the same shape migration 1944 withdrew from school-vouchers**, where
the row read *"Did not co-author HB3 … As a Rio Grande Valley Democrat"*. A shape that recurs for
one member is worth looking for across that member's other rows.

---

## 3. 🔴 The check grouped 14 rows; 69 cite the bill

Round four's lesson was to read the whole instrument cohort, not the flagged group. Applied here:

| | AB 2655 / misinformation | HB 44 / abortion (Texas-sourced) |
|---|---:|---:|
| grouped by the check | 8 | 14 |
| rows actually citing it | **13** | **69** |

The AB 2655 gap was closed — all 13 were read and 11 written. **The HB 44 gap was not.** 61
co-authors means most Texas legislators' abortion rows mention it, and the keyer resolves a
direction for only some. The 14 the check grouped were read in full and are sound; **the other 55
are unread.** The migration pins the population at 69 so the gap cannot widen unnoticed.

---

## 4. Three findings larger than this file

### 🔴🔴 4.1 `immigration` exists in Season 1 only, and 1,666 valued answers are stranded

It has **no `season_questions` row in Season 2**, and none in the Season 3 draft. Every repair these
passes use is an insert of a Season 2 row, and for this topic there is nothing to insert against.

The Texas SB 8 (89R) group was read in this pass and **is defective**: the Act makes county sheriffs
in counties of 100k+ enter ICE 287(g) agreements, while every chair on the ladder is about **legal
immigration levels and public-service eligibility** —

```
4 Make it harder to immigrate legally and limit public services to people with legal status
5 Stop most legal immigration and block public services for anyone without legal status
```

— so the Act is off-axis, and three of its five rows rest on nothing more than *"Consistent with
conservative Republican immigration enforcement position"*. **It cannot be written.** Any queue
group on `immigration` is in the same position.

### 🔴 4.2 An older programme has already blanked 1,021 rows for these shapes

603 people, 36 topics, written between 2026-10-09 and 2026-10-25 in the format
`INTERNAL RECORD - blanked by migration NNNN … Shape: X`, under a named vocabulary:

`OFF AXIS` · `DIRECTION ONLY` · `OMISSION FOR COMMITMENT` · `EMPLOYER` · `AFFILIATION` ·
`OFFICE DUTY` · `BARE SCORE` · `ABSENCE MOVES THE SEAT` · `NO RECORD AT A RECORD` ·
`COUNTERFACTUAL` · `EVIDENCE POINTS AWAY` · `RUNG TEXT` · `BAND NOT RUNG` ·
`THE ROW INFERS THE CHAIR INSTEAD OF SHOWING IT` · `THE INSTRUMENT DOES NOT LEGISLATE ON THE
LADDER'S QUESTION`

Those map almost one-to-one onto rulings the contradiction passes have been writing in their own
words for four rounds — "off-axis", "proves the side not the rung", "an employer is not a position",
"a committee seat is not a position". **The two programmes are converging on the same defects with
two different notice formats.** Worth reconciling; not by rewriting a hundred rows today.

### 🔴 4.3 The shapes have a long tail still in the corpus

A regex sweep for serving rows that seat a chair while declaring the evidence absent — *"did not
appear"*, *"no record of"*, *"insufficient"*, *"no strong public stance was identified"*, a party or
caucus baseline, NVR — returns **563 rows out of 31,362**.

⚠ **That is a search result, not a defect count.** A sample of 8 contained 3 rows that name real
instruments and merely use a trigger word (*"Authored AB-915 … AB-2161 … AB-1360"*). The real number
is smaller and only reading settles it. Examples that are clearly defective:

> *"has supported voting access expansion legislation consistent with the Maryland Democratic caucus
> position"* — names no bill at all
> *"NVR on AB 2099. No authored abortion bills. Republican platform and 2024 Trump delegate status
> indicate restrictive stance"*

---

## 5. Gates

| gate | before | after |
|---|---|---|
| `audit-chair-evidence` | **not applicable — this file seats no chair** | — |
| `check-stance-sources` | 789 across 4 checks | **789 across 4 checks — identical** |

The sourcing outcome needed no prediction model: all 12 writes are blanks, which never enter a
universe defined by `value <> 0`, and Season 1 is untouched so nothing leaves. No baseline commit
is owed.

Verified deltas, pre-state queried before committing:

| topic | value | before → after | Δ |
|---|---|---|---|
| misinformation | 0 | 35 → 46 | +11 |
| abortion | 0 | 101 → 102 | +1 |

---

## 6. Open items

1. ▶ **55 unread Texas abortion rows citing HB 44** (§3).
2. ▶ **`immigration` cannot be repaired at all** until it has a Season 2 question (§4.1). 1,666
   answers, including the off-axis Texas SB 8 cohort read in this pass.
3. ▶ **Reconcile the two notice formats** (§4.2) and adopt the older programme's shape vocabulary in
   future contradiction passes rather than re-deriving it.
4. ▶ **Triage the 563-row absence-of-evidence tail** (§4.3), starting with the sub-shapes that
   declare themselves.
5. ▶ Still open from earlier rounds: the check counts draft Season 3 rows as voter-facing; bill
   numbers collide across sessions of one legislature; misdescribed citations pass both gates; 89
   Season 1 campaign-finance answers sit on a deleted chair; the 8 Season 1 value-vs-text rows and
   the 191 stale-prose rows.
