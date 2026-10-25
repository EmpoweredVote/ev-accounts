# The Respect for Marriage Act cluster — a chair decided by a paraphrase

**2026-10-21. Migration 1925: 53 blanked, 1 kept.** The first queue worked from the
instrument/rung contradiction check (PR #1085).

## What the check found

54 members who voted **for** the Respect for Marriage Act, each row resting on that vote, split
across three rungs of `same-sex-marriage`: **27 at rung 2, 26 at rung 3, 1 at rung 4.** One vote,
one bill, three answers — and nothing in the corpus had ever compared them.

## 🔴🔴 The split is an artefact of the SUMMARY, not of the members

Measured across the cluster:

| | mentions the religious carve-out | mentions benefits/recognition |
|---|---|---|
| **rung 2** (27 rows) | **2** | 18 |
| **rung 3** (26 rows) | **23** | 9 |

**Whichever half of the Act the researcher paraphrased set the chair.** Nobody was reading the
member; they were summarising the bill, and the summary chose. 48 of the 54 rows name nothing but
the Act.

🔑 Nancy Mace's row makes it visible: it says *"This matches stance 2 exactly"* while seated at **3**
— written on Season 1 numbering, where rung 2 was the religious-carve-out formulation that became
Season 2's rung 3. The remap was right; the prose number is stale.

## ⚖ The enacted text settles that both readings are true

Public Law 117-228, **fetched and read, not taken from the title**:

- **SEC. 4 — FULL FAITH AND CREDIT GIVEN TO MARRIAGE EQUALITY** → rung 2's claim
- **SEC. 6(b)** — *"nonprofit religious organizations … shall not be required to provide services,
  accommodations, advantages, facilities, goods, or privileges for the solemnization or celebration
  of a marriage"*, and a refusal *"shall not create any civil claim or cause of action"* → rung 3's
  claim

The Act carries **both**, so a vote for it endorses a package holding both. It proves the **side**,
not the **rung** — the Texas cohort's rule, and `chair_needs_evidence_for_that_chair`: evidence
establishing only a direction under-determines which chair on that side the person occupies.

## ⚠ Why not re-seat the cluster to rung 3 instead

Rung 3 describes the instrument most completely, and that was the live alternative. It was rejected
because rung 3 asserts the member wants to *"protect religious organizations' right to decline"*,
and a vote for the only available vehicle does not show that — several of these members accepted
section 6 as the price of sixty Senate votes. Publishing that as their position would misrepresent
them. **A blank withdraws a claim nobody established; a re-seat would assert a new one on the same
evidence.**

🔑 A blank here is **recoverable**: the reasoning and every citation stay on the row.

## ⚠ Not blanked — 1 of the 54

**Martin Heinrich** was an **original cosponsor of legislation to repeal DOMA** — a second record of
his own, with no section 6(b) ambiguity, and benefits parity on its face. Chair stands at 2. A guard
in the migration fails the transaction if he appears in it.

### The five that carried other evidence and still blanked
McNerney (DADT + unnamed "employment non-discrimination"), Davis (a 100% HRC rating is a bare score;
ENDA "supported" with no vote named), Merkley (DADT is military service, not marriage), Gimenez (his
Obergefell announcement is **own words**, and federal basis is `record`).
▶ **Eleanor Holmes Norton is the strongest re-seat candidate in the corpus for this topic** — dated
entries for domestic-partner benefits, ENDA and DADT repeal, which answer **rung 1's discrimination
limb**. Blanked rather than re-seated because a re-seat needs her sources checked and the
chair-evidence gate run. That is a separate pass.

## ▶ Recorded, not acted on — a ladder reachability finding for Season 3

`inform.compass_topic_roles` marks `same-sex-marriage` at **federal** level `evidence_basis =
'record'`. The Respect for Marriage Act is the only federal marriage instrument there is, and it
carries section 6(b). So for a member of Congress, on a record basis, **rungs 1 and 2 may have no
reachable instrument at all** — naming the corpus (federal statute) and the source class (roll-call
record), as the reachability rule requires. `compass_topic_roles` is **not** touched.

## Verification

Applied, then checked from outside on a fresh connection: **53/53 answer 0**, 0 still seated,
citations **min 1 / max 3 / 0 empty**, **0** Season 1 answers moved, **Heinrich still at 2**.
`check:stance-sources` **790, exit 0, unchanged**. The contradiction check drops **120 → 119
groups, 1,144 → 1,090 rows** — exactly this cluster.

⚠ `audit-chair-evidence.mjs` is a pre-write gate for any migration that **sets** a chair. This one
sets none — every row goes to 0 — so there is no chair for it to test. Said explicitly rather than
skipped silently, because migration 1921 skipped it and 1922 had to undo two re-seats.
