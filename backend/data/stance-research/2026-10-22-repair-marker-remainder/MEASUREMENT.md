# The citation-repair-marker remainder — MEASURED

**2026-10-22. Read-only: nothing was written to the database by this pass.** This answers the
▶ NEXT item left by the repaired-chairs remedy: *"the class is 436 rows, not 40, and the other 396
are invisible — nobody has sampled them."*

Prior work: [`2026-10-20-repaired-chairs/LEDGER.md`](../2026-10-20-repaired-chairs/LEDGER.md) ·
[`1922-REMEDY.md`](../2026-10-20-repaired-chairs/1922-REMEDY.md) ·
[`1923-IDENTIFIERS.md`](../2026-10-20-repaired-chairs/1923-IDENTIFIERS.md)

---

## ▶▶ THE HEADLINE: 165 ROWS DO NOT NEED SAMPLING. THEY SAY IT THEMSELVES.

**165 of the 388 remaining rows (43%) carry this sentence in their published reasoning:**

> ⚠ WHAT THIS DOES AND DOES NOT SETTLE. The instrument places this member firmly on their side of
> the ladder; **it does not by itself separate the rungs WITHIN that side, and the chair keeps the
> placement the original research gave it.** Registered as a ladder-reachability finding rather
> than silently absorbed.

That is **a census, not an estimate**, and it is dispositive against the repo's own bar:

> *Evidence that establishes only the **direction** (pro/anti) under-determines which of the two or
> three chairs on that side applies. **Seating anyway is an unevidenced claim** — the same defect
> class as a composed citation, expressed as a number.* — CLAUDE.md

🔴 **And note what the chair rests on: "the placement the original research gave it."** The original
research is the generic-profile-sourced research this entire queue exists because it was never
evidenced. So the repair added a roll-call vote that proves the **side**, and left the **rung**
standing on the unevidenced guess — while the added citation makes the row *look* sourced. **This is
the 1921 failure at 165 rows instead of 40, and it is self-documenting.**

All 165 come from **migration 1903** (the Texas cohort), which wrote 172 of the 388 — so **96% of
that migration's surviving rows carry the admission.**

## The population, and why it is 388 rather than 396

| | rows |
|---|---:|
| class measured 2026-10-20 | 436 |
| carrying the marker **now** | 393 |
| …seated (voter-facing) | 393 |
| …**not** touched by migrations 1920–1923 — **this population** | **388** |

⚠ **The population moved by 43 rows while it was being worked on.** About 18 of that is migrations
1921–1923 rewriting reasoning in this class. The rest is **another session**: migration **1925**
blanked 53 same-sex-marriage rows at 03:29 UTC on 2026-10-22, mid-measurement, selected on a
different predicate (members who voted for the Respect for Marriage Act). Any overlap left this
population silently, because their rewrite removed the marker text. See *Coordination* below.

### By the migration that wrote the row

| written by | rows | people | topics | avg sources |
|---|---:|---:|---:|---:|
| **1903** (TX cohort) | **172** | 75 | 15 | 4.18 |
| 1900 (MA, bill-identity repairs) | 80 | 37 | 11 | 3.78 |
| 1902 (MA, roster→bill repairs) | 68 | 47 | 13 | 3.06 |
| 1911 (VA, page-says-so repairs) | 41 | 22 | 15 | 1.32 |
| 1909 | 17 | 11 | 11 | 1.06 |
| 1899 / 1904 / unattributed | 10 | — | — | — |

⚠ **The class is wider than the ledger said.** The repaired-chairs ledger named migrations
1903/1909/1911/1913; the marker also appears from **1899, 1900, 1902 and 1904**.

## The second template: sponsorship verified, bill never read

**67 rows** carry *"🔑 THE SPONSORSHIP IS VERIFIED"* — the migration-1902 Massachusetts repair, which
confirms the member's name appears on a bill's cosponsor list and repoints the citation at the bill.
**30 of the 67 never state what the bill is about.**

🔴 **A bill number with no subject cannot seat a rung defined by degree** — and the one opened here
is worse than silent:

> **R-sample #2 · Angelo J. Puppolo · Jail Capacity · chair 3**
> Cited: `malegislature.gov/Bills/194/H1937`, sponsorship verified.
> **H1937 is "An Act relative to the Commonwealth's right to appeal bail decisions."**
> Chair 3 reads *"Upgrading jail facilities only as needed to meet constitutional standards, without
> expanding overall capacity."* The bill is about **bail appeal rights**, not capacity — off-axis,
> and if anything it points away from rung 2's "bail reform".

This reproduces the 2026-10-20 measurement's own finding — *a named instrument roughly halves the
defect rate but does not clear a row, almost always because the instrument is off-axis or proves the
side rather than the rung.*

**232 of 388 rows (60%) carry one template or the other.**

## The hand sample

A seeded sample of 30 was drawn — `md5(politician_id || topic_id || '2026-10-22-repair-marker-388')`,
ordered ascending — and is committed as `sample-30.json` so it is reproducible and auditable.
**13 were read in full against their Season 2 ladder; 11 were defective.**

**11/13 = 85%** (95% CI roughly **57–96%**). ⚠ Small n, and two calls are provisional pending a full
read of a truncated reasoning field. The CI is wide; the direction is not in doubt, and the 165 do
not depend on it at all.

### The clearest four

| row | seat | what the row actually cites | shape |
|---|---|---|---|
| **Ghazala Hashmi** / Economic Development Incentives | 2 | a campaign commitment to *"quality public education that prepares them for well-paying jobs"* and investment in schools | 🔴 **OFF AXIS** — the ladder asks about business subsidies. The evidence is education funding. |
| **Danica Roem** / Trans Athletes | 1 | that she is the first openly transgender legislator in Virginia, and opposed **HB 1612, a bathroom bill** | 🔴 **IDENTITY AS EVIDENCE + OFF AXIS** — who a person is, is not a position they hold, and a bathroom bill is not a position on athletes. Same error as the DeMaio row blanked in 1922. |
| **Sam Rasoul** / Same-Sex Marriage | 2 | *"All Virginians should have the right to know they won't be discriminated against based on who they love or how they worship."* | **RUNG TEXT** — a non-discrimination statement that never mentions marriage; the only rung its words touch is rung **1**, not the rung it sits on. |
| **Daniel Donahue** / Abortion | 1 | a verified, divided-margin vote for the Massachusetts ROE Act | **RUNG TEXT** — the Act is *legal and accessible through 24 weeks with exceptions afterward*, which is rung **2**'s own text. The vote was carefully verified; the rung was not. |

### ⚖ What a sound row looks like, since two survived

**Samantha Montaño / Rent Regulation (2)** — cosponsor of rent stabilization legislation, verified on
the bill's own cosponsor list, searched across *every* General Court in which the act was filed
rather than only the one the row named. On-axis, and rung 2's own text.
**Danica Roem / Same-Sex Marriage (2)** — her own bill, as first sponsor, to amend the Virginia
Constitution on marriage.

⚠ **Note the same person appears in both columns.** The defect is per-row, not per-person, and a
politician with one sound row can carry a baseless one on the next topic.

## 🔑 What this costs, and what it does not

- **This is not a claim that 165 politicians are on the wrong rung.** Some will be right by luck.
  It is a claim that **165 rows are seated on evidence their own text says cannot seat them**, which
  is the standard the corpus is held to.
- **Blanking is cheap and honest; it is also large.** 165 rows is ~4.4% of the 3,718 seated Season 2
  rows. A blank keeps the row and its citations, so coverage still counts the research as having
  happened.
- **The alternative is a re-read, not a defence.** Each row has a real roll-call vote attached. A
  re-read against the ladder could seat many of them properly — that is work, not a write-off.

▶ **This pass makes no disposition.** It measures. The decision on 165 voter-facing rows belongs to
the operator.

## 🔴 Coordination — why the board did not help

The steward coordinates **four** things: migration numbers, jurisdiction leases, worktree markers,
and branch file-drift. **Row-level work on shared tables is none of them.**

Measured on the board: **760 claims ever, in exactly four kinds** — `worktree` (438), `state` (120),
`county` (103), `place` (99). **No stance, topic or queue scope has ever been claimed.** So when
migration 1925 rewrote 53 rows at 03:29 UTC today, nothing told this session, and nothing told that
one that this class was being measured. The slot allocator *did* work — it reported 1924 and 1925 as
taken — but a **number is not a row**.

🟢 **The mechanism already exists and is unused.** `parseScope` accepts any `kind:id` and files an
unrecognised kind as `kind: "other"` with no geographic claim — deliberately, per its own comment
(*"reserves `worktree:<path>` for a later rollout step, so an unrecognised kind must PARSE"*). The
database's uniqueness constraint on the exact scope string then gives the same structural guarantee
it gives `place:0642468`. This pass claimed **`queue:repair-marker-436`** — the first non-geographic
claim in the board's history — and it worked.

⚠ **What it cannot do, and this is the real gap:** `relate()` returns `unrelated` for any `other`
kind, so containment warnings cannot fire between two row-scopes. Two sessions naming the same work
differently — `queue:repair-marker-436` vs `topic:same-sex-marriage` — still collide in silence.
**A convention for naming row-scopes is worth more here than any code change.**

## ▶ Still open

- **The disposition of the 165.** Blank, or re-read against the ladder.
- **The 30 sponsorship rows that never state the bill's subject**, and the 67 they sit inside.
- **156 rows carry neither template** and are only sampled, not counted.
- `same-sex-marriage @ state` and `jail-capacity @ local` may be mis-marked `record` — rulings.
