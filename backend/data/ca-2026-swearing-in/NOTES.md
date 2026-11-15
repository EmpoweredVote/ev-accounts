# The 2026-12-11 cohort — 197 LA County school and community college seats

Companion to `RULES.md`, which establishes the DATE. This records what was done about the PEOPLE.

**State after `CC_0434` (applied to production 2026-11-15):**

| | offices | state |
| --- | --- | --- |
| cancelled, single-seat | **85** | ✅ seated at 2026-12-11 by `CC_0434` |
| cancelled, at-large boards | **29** (10 boards) | 🔴 blocked on a decision — see below |
| cancelled, no person row | **1** | ⏳ Norwalk-La Mirada TA5 — needs a `politicians` row |
| contested, awaiting certification | **52** | ⏳ LA County certifies by 2026-12-03 |
| winner already recorded | **49** | ⏳ still need a 2026-12-11 term written |
| | **197** | |

---

## 🔴 The finding that made this piece safe

**Our own data cannot tell a cancelled election from a held, uncontested one.** Both are one
candidate against one seat, `description` NULL, `result` NULL and `candidate_status` `active`.
They need **opposite** handling: a cancelled election is seated now with no result, an uncontested
one must be certified first.

96 of the 197 match `candidates <= seats and no winner`. That is a predicate on **shape**, and it
was treated as a hypothesis, not a fact. The authority is the county's own publication:

> **FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION DUE TO INSUFFICIENCY OF
> CANDIDATES**, LA County Registrar-Recorder/County Clerk, revised 8/25/2026.

🟢 **The shape and the authority agree row for row: the same 96, nothing on one and not the other.**
That is why the predicate is trusted here — it was checked, not assumed.
Reconciliation: `reconcile-12-11-cohort.mjs`. Parser: `parse-la-canceled-elections.mjs`.

### Four traps that document set

- 🔴 **A school seat is not always under a school heading.** `Pasadena (Pasadena Unified School
  District Board of Education 5)` is filed under **CITIES**, because that seat is consolidated
  with the city's election. A parse bounded to the four school sections drops it silently. The
  parser reads every section and lets the caller filter.
- 🔴 **The asterisk is a second, opposite reason.** The footnote reads *"\*Cancelled Elections Due
  to No Candidates"* — nobody filed, so there is nobody to appoint and the seat becomes a vacancy
  for the board to fill. **Gorman Joint Elementary (Full Term)** is the only school seat so marked.
  Seating an asterisked row would invent an officeholder out of an empty race.
- ⚠ **The tentative list is published beside the final one.** No school election was un-cancelled
  between them — checked, not assumed. The only row that left was a placeholder reading
  *"Information is forth coming"* where the CITIES section had not yet been compiled.
- ⚠ **Four list rows have no office in our data**: Snowline Joint UA TA1, Gorman Joint Full Term,
  Lowell Joint TA2 and TA5. A coverage gap, not an error.

---

## 🔴 The 10 at-large boards, and the decision they need

El Monte City · El Rancho · El Segundo · Hawthorne · Hermosa Beach City · Manhattan Beach ·
Rosemead · San Marino · Walnut Valley · West Covina.

Each is **five office rows all titled `Board Member`, all currently seated**, and the 2026 race
points at **one** of them while carrying `seats = 3`. Three people cannot enter one office, and
the title says nothing about which three of the five seats are up.

🟢 **The discriminator exists.** The five rows carry different `term_start` values, and the
sources are explicit. El Monte City, worked through:

| holder | term_start | source says | up in 2026? |
| --- | --- | --- | --- |
| Elizabeth "Beth" Rivas | 2022-12-01 | won Nov 2022 | **yes** |
| Lisette Mendez Garcia | 2022-12-01 | won Nov 2022 | **yes** |
| Cesar Peralta | 2024-12-01 | *"Unexpired term ending December 11, 2026"* | **yes** |
| David Siegrist | 2024-12-01 | won Nov 2024, full term | no — 2028 |
| Jennifer Cobian | 2024-12-01 | won Nov 2024, full term | no — 2028 |

The three filed candidates are exactly Rivas, Mendez Garcia and Peralta. So for a board where
**every** filer already sits, the mapping is determinate: each returns to the seat they hold.

🔴 **It is not determinate where a NEWCOMER is involved.** Hawthorne's filers are Eugene Krank,
Luciano Aguilar and Yaquelin Amador against sitting member Cristina Chiappe; Hermosa Beach has one
sitting filer of three. Choosing which of five identical seats a newcomer takes is a claim about
**who replaced whom**, and nothing in the record supports one choice over another.

▶ **Two options, and this is the operator's call:**
1. **Seat only the all-incumbent boards** (determinate) and leave the rest until each board's own
   organisational minutes name who succeeded whom. Minutes appear shortly after 12-11.
2. **Adopt a rule** — e.g. assign newcomers to the expiring seats in ballot order — and record it
   as a convention rather than a fact. Cheap, and wrong in a way nobody can later detect.

⚠ Option 2 is how a seat ends up asserting a succession that never happened. Option 1 is
recommended; the cost is that those boards show a stale member for a few weeks.

---

## What `CC_0434` encodes, and why

- `how_started => 'appointed'`, not `'elected'`. No election was held; the county's document is
  titled *appointment in lieu of election* and Elec. Code 10515 is an appointment power. Educ.
  Code 5328 then **deems** the appointee elected, which is why the term is a full one — but how
  they started is an appointment.
- `p_allow_reelection => true`. **Most of these people already hold the seat**, because an
  uncontested filing usually is the sitting member. The helper's re-election guard refused the
  first run by design, which is the guard working.
- Terms start **2026-12-11** and are written in advance at day precision — the **Reno pattern**
  (`CC_0387`). `office_current_holder` keeps returning the sitting member until the date and flips
  by itself, with no migration on the day. ⚠ It flips at **UTC midnight = 16:00 Pacific on 12-10**.

## ⚠ A gate of ours that was wrong, recorded because it looked right

`CC_0434`'s "nobody is current yet" gate first failed the dry run on **9 legitimate rows**.
`current_office_holders` reads `term_start IS NULL` as current, and a NULL never satisfies
`< DATE`, so an undated existing term read as "no earlier term". **The members were right and the
comparison was NULL-unsafe.** Any gate in this area must treat a NULL `term_start` as earlier.

## Still owed for 12-11

1. The 10 at-large boards (decision above).
2. A `politicians` row for Norwalk-La Mirada Trustee Area 5's filer.
3. **The 49 offices that already have a recorded winner still have no 2026-12-11 term.** They are
   not blocked on anything — they simply were not in `CC_0434`'s scope, which was the cancelled
   set. They should be seated the same way, in advance.
4. The 52 contested races, after LA County certifies (by 2026-12-03).
