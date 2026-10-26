# The Massachusetts Safe Communities Act on the local-immigration ladder — migration 1947

72 serving rows name this Act. **69 written: 41 re-seated, 28 withdrawn.** 3 left alone.
Full queue **337 groups / 2,386 rows → 334 / 2,334**. (`--sole` unchanged at 131/800: these rows
carry more than one key, so the strictest view never saw them — the fourth time `--sole` has
under-reported.)

| rows | shape | decision | written |
|---:|---|---|---:|
| 41 | the member **co-sponsored** the Act | re-seat from chairs 1/2 to **chair 3** | 41 |
| 27 | the member **did not** co-sponsor it | withdraw | 27 |
| 1 | a US Representative who cannot co-sponsor it | withdraw | 1 |
| 3 | the member has a bill of their **own** | left alone | 0 |

66 writes insert a Season 2 row (the row served from the closed Season 1); 3 update a row already
serving from Season 2. `local-immigration` pins **one revision across both seasons**, so every row
written is read against the very ladder its reasoning was researched against.

---

## 1. Why this ladder and not `immigration`

Season 1's `immigration` question was **split for Season 2 because it was trying to do too much** —
each of its chairs carried two limbs, legal-immigration levels *and* public-service eligibility:

```
4 Make it harder to immigrate legally AND limit public services to people with legal status
5 Stop most legal immigration AND block public services for anyone without legal status
```

`local-immigration` is one of the successors and asks a single question: what local law enforcement
should do. That matters practically — **Season 1's `immigration` has no Season 2 question at all**,
so its 1,666 valued answers cannot be shadowed by an insert and are not repairable by the technique
these passes use. ADR 0005 §3.4 keeps them: *"A topic dropping out of the active season stops it
being **asked**. It does not unmake the fact that someone answered it."* This file works the
successor, which is repairable, and leaves the stranded question recorded.

---

## 2. The Act was read, and it does not say what the rows say it says

H.2288 / S.1510 of the **193rd** General Court, *"An Act to protect the civil rights and safety of
all Massachusetts residents"*.

```
c1 Refuse all ICE detainers; prohibit local employees from sharing immigration status information
   with federal agencies
c2 Comply only with court-ordered detainers; protect undocumented crime victims and witnesses
c3 Follow federal law as required but do not use local resources for proactive immigration
   enforcement
```

### 🔴 Chair 1 is negated by the Act's own text

> **§2(e):** *"nothing in this section shall prohibit or restrain any state or local agency from
> sending to, or receiving from, any local, state, or federal agency, **information regarding
> citizenship or immigration status**."*

That clause exists because 8 U.S.C. §1373 forbids a State from barring such sharing — so chair 1's
second limb is something **no Massachusetts statute could deliver**. The Act never uses the word
"detainer" either, so the first limb is unevidenced too. **39 rows were seated there.**

### Chair 2 fails on its spine

Complying only with *court-ordered* detainers is a framing the Act does not use. Its second limb
does match — §2(b) bars questioning *"persons, including victims and witnesses of crimes, about
their immigration status"* — but a matching limb is not a matching chair.

### Chair 3 matches both limbs

> **§3:** no officer of the department of corrections, state police, a sheriff's department or a
> city or town police department *"shall perform the functions of an immigration officer, whether
> pursuant to 8 U.S.C. section 1357(g)"*, and inconsistent agreements in existence are void.

That is *"do not use local resources for proactive immigration enforcement"* exactly — it ends
287(g). And §2(e), with the exceptions for where *"state or federal law requires the inquiry"*, is
*"follow federal law as required"*. **The Act is a chair 3 instrument.** Same test migration 1943
used on the Climate Solutions Now Act: one chair whose spine the statute matches, the others failing
on the statute's own text.

---

## 3. 🔴🔴 28 rows seat a position on *not having signed* something

This is the larger defect, and the contradiction check never flagged it — the check compares rows
that cite an instrument, and these rows cite it to say the member is **absent** from it.

> *"**Did not co-sponsor** Safe Communities Act (red X on AOM) … **Middle position** — not limiting
> cooperation but not mandating it."* → chair 3
> *"**Zero co-sponsorships** including Safe Communities Act. **Republican caucus member** with no
> local-immigration legislation. Consistent with honoring ICE detainers."* → chair 4
> *"As a **Republican Assistant Minority Leader**, Durant **likely supports** honoring ICE detainers
> and sharing immigration status information proactively."* → chair 4
> *"**Her failure to support this bill** — unlike many Cambridge-area…"* → chair 3

The pattern is mechanical: a Democrat who did not sign was placed at chair 3 as a "middle
position"; a Republican who did not sign at chair 4. **That is an algorithm over an advocacy
group's tracker and a party column, not research.**

**Not signing a bill is not a position.** It is equally consistent with disagreeing with it,
agreeing and not signing, never having been asked, and holding no view at all, and nothing in these
rows chooses between those. All 27 are blanked.

### The 28th

A **United States Representative**, who cannot co-sponsor a Massachusetts bill at all. Her row holds
direction and demographics — *"has consistently backed local non-cooperation with ICE detainer
requests"*, *"defended Massachusetts' Safe Communities Act"*, a record *"driven by her district's
significant immigrant popula[tion]"* — with no vote, bill or statement of her own named. She cannot
be re-seated on the Act's chair because the Act is not her instrument.

### ⚖ Three rows left alone

Each carries an affirmative instrument of the member's own, which is exactly what the other 27 lack:

| bill | what it does |
|---|---|
| H.2009 | directs local compliance with ICE detainers → chair 4 |
| H.2573 | *"An Act to enhance public safety"*, requiring mandatory local cooperation with ICE → chair 5 |
| H.2575 | regulates law-enforcement federal immigration agreements without prohibiting them → chair 3 |

---

## 4. ⚠ A citation pointing at the wrong session's bill

Two rows cite `malegislature.gov/Bills/194/H2288`. In the **194th** General Court H.2288 is *"An Act
relative to MBTA communities"* — a housing and zoning bill. The Safe Communities Act of the 194th is
**H.2580 / S.1681**; H.2288 was its number in the **193rd**. The rows' prose is right — "H.2288 /
S.1510" are the 193rd's numbers — and the URL is wrong by one session.

**This is the third cross-session collision in three passes:** California "SB 42" merged the 2025-26
Fair Elections Act with the 2023-24 CARE Court Act (migration 1945); Texas bill numbers recur across
the 85th, 87th, 88th and 89th legislatures; and now `MA:H2288` merges a sanctuary bill with a
housing bill. The check's keys scope a numeric bill by its legislature but **not by its session**.
It belongs in the checker, not in a migration.

---

## 5. Gates

| gate | before | after |
|---|---|---|
| `audit-chair-evidence --csv` (41 seated rows) | **OK: all 41** | — |
| `audit-chair-evidence --check` | — | **OK: all 41** |
| `check-stance-sources` | 789 across 4 checks | **789 across 4 checks — identical** |

Predicted before the write: of the rows entering the universe, **0 had a bare domain, 0 were
Ballotpedia-only, 0 had empty sources**. No baseline commit is owed.

Verified deltas, pre-state queried before committing:

| value | before → after | Δ |
|---|---|---|
| 0 | 43 → 71 | +28 (the withdrawals) |
| 1 | 10 → 7 | −3 (the Season 2 updates moving up) |
| 3 | 7 → 48 | +41 (the re-seats) |

### Four guard failures, all caught before any write

1. The VALUES block kept a trailing comma on its last row.
2. `GUARD 5` counted 91 instead of 72, because it filtered `value <> 0` **inside** the `DISTINCT ON`
   and so picked a non-serving row for anyone whose Season 2 row is already a blank.
3. Then 88, because it filtered the reasoning inside the `DISTINCT ON` too, catching people whose
   Season 1 text names the Act but whose serving row does not.
4. A `$`-interpolation was flattened to `''::uuid` while patching.

⚠ Two of those came from editing generator source through a shell heredoc, which silently ate
characters — the same standing hazard that produced a regex matching nothing earlier in this pass.
Generator source is written with a file tool, not a heredoc.

---

## 6. Open items

1. ▶ **`immigration` is unrepairable** until it has a Season 2 question (§1). 1,666 valued answers,
   including the Texas SB 8 (89R) cohort, which is off-axis for that ladder and **on-axis for
   `local-immigration` chair 5** — the evidence has a home, the rows do not.
2. ▶ **Bill-number keys are not session-scoped** (§4). Third occurrence.
3. ▶ **The absence-of-evidence shape is not what the contradiction check looks for.** It found none
   of the 28 rows here; they surfaced only because the cohort was read whole. The 563-row sweep from
   round five is the systematic version of this.
4. ▶ `--sole` under-reported again: this entire cohort is invisible to it.
