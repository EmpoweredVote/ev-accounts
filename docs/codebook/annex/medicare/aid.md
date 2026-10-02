# medicare/aid — served revision 38bab357-9790-4cb3-a6d2-c43cbdca615b (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Medicare and Medicaid be funded and structured?"

**Orientation:** standard. Rung 1 makes Medicare cover everyone, rung 5 ends both programmes. The
rungs order **how large the two public programmes are**: universal, larger, the same, smaller, none.

**Levels with a role:** federal, state (`compass_topic_roles`). Medicare is federal only. Medicaid is
joint: Congress sets the frame and the federal share; each state sets eligibility, benefits and
waivers inside it. So a state officeholder holds a lever on Medicaid and none on Medicare.

**Synonyms:** "Medicare Part A / B / C / D", "Medicare Advantage", "traditional Medicare", "premium
support", "voucher", "Medicare buy-in", "Medicare at 60" (or 55, 50), "Medicare for All",
"Medicaid expansion", "FMAP" (federal share), "block grant", "per-capita cap", "section 1115
waiver", "work requirements" or "community engagement", "CHIP", "dual eligibles", "drug price
negotiation", state Medicaid names ("Medi-Cal", "AHCCCS", "BadgerCare", "MassHealth", "TennCare",
"Healthy Indiana Plan").

1. **"expand Medicare to cover everyone regardless of age"**
   - Means: Medicare becomes the coverage for every person, of any age.
   - Operative clauses: [a] Medicare (the federal programme, or a programme that replaces it for
     all); [b] everyone, regardless of age.
   - Establishing evidence looks like: authoring or co-sponsoring a Medicare for All bill that enrolls
     every resident; own words calling for Medicare for everyone.
   - Levels that hold a lever: federal. A state cannot expand Medicare; a state single-payer plan is
     not Medicare → code it on `healthcare`; here a state officeholder's rung 1 is `scope-unavailable`
     (codebook 0.4 principle 5) _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a buy-in or a lower Medicare age is an expansion that
     stops short of everyone → rung 2.

2. **"significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage"**
   - Means: many more people qualify for one of the two programmes, but not everyone.
   - Operative clauses: [a] **eligibility** for Medicare **or** Medicaid (one programme is enough);
     [b] significant; [c] short of universal.
   - Establishing evidence looks like: a single-subject bill or vote that lowers the Medicare age, or
     adopts the adult Medicaid expansion in a state; own words calling for such a change. Code the
     end state the instrument enacts: an instrument that stops short of everyone meets [c]; it does
     not need a second passage that rejects rung 1 _(proposed; adjudicated gold on another topic
     seated an instrument that met every clause of one rung, but not the extra clause of the
     stronger rung beside it, on the rung it met)_. If a surviving rung-1 passage also exists → V6
     `adjacent-chairs` rules apply.
   - Levels that hold a lever: federal (Medicare age, federal Medicaid rules); state (Medicaid
     eligibility).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **narrow** eligibility change (one group, such as
     12-month postpartum coverage) is an expansion but not "significant" → `direction-only`
     _(proposed)_.
   - Benefits are not eligibility. Adding dental, vision or hearing to Medicare improves the programme
     → rung 3 clause [a], not rung 2 _(proposed)_.
   - S1 rung 2 named "lower Medicare age to 55 **and** expand Medicaid"; the served rung needs one of
     the two, not both.

3. **"improve current programs while controlling costs"**
   - Means: keep the two programmes' present shape, make them work better, and hold down what they
     cost.
   - Operative clauses: [a] improve current programmes (benefits, access, quality, administration);
     [b] control costs (drug price negotiation, payment reform, fraud and waste). Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a single-subject Medicare or Medicaid bill that does both, or
     two passages that each match one clause, inside current eligibility.
   - Levels that hold a lever: federal; state (Medicaid administration and payment rates).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because "controlling costs" can mean cutting coverage. A cut in who
     is covered is rung-4 territory, not [b].
   - "Protect Medicare", "no cuts to Medicare" names no clause → `direction-only` (it excludes rungs
     4 and 5 only).

4. **"scale back both programs, shifting more coverage to private insurance"**
   - Means: both Medicare and Medicaid cover less, and private insurance covers more.
   - Operative clauses: [a] scale back Medicare; [b] scale back Medicaid; [c] shift coverage to
     private insurance. Compound: one programme only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a premium-support or voucher plan for Medicare **and** a
     Medicaid cut or cap (block grant, per-capita cap, eligibility rollback); own words calling for
     both.
   - Levels that hold a lever: federal for [a] and [b]; state for [b] only.
   - At state level, a Medicaid-only scale-back → `compound-partial`: the rung says "both" _(ruled 2026-10-01)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Medicare Advantage growth alone moves enrollees to private plans **inside** Medicare; it does not
     scale back the programme → `direction-only` _(proposed)_.
   - S1 rung 4 named "partially privatize Medicare **and** reduce Medicaid"; the served rung is about
     size ("scale back"), and needs both programmes.

5. **"phase out both programs and use private insurance only"**
   - Means: Medicare and Medicaid end, and private insurance is the only coverage.
   - Operative clauses: [a] phase out Medicare; [b] phase out Medicaid; [c] private insurance only (an
     absence clause: the passage must say it, V4.2).
   - Establishing evidence looks like: own words that call for ending both programmes.
   - Levels that hold a lever: federal. A state can leave Medicaid but cannot end Medicare → same
     scope question as rung 4.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a deep cut is not a phase-out. A plan that keeps either
     programme → not rung 5.

**Hard cases:**
- **The omnibus trap (codebook V4, [real]).** A Yea on the One Big Beautiful Bill Act (2025), a
  reconciliation bill covering taxes, Medicaid, immigration and more → `multi-subject`. Statements
  that defend its **work requirements** ("sound policy") speak to a narrower clause than any rung →
  `adjacent`.
- **Medicaid work requirements** on their own → `adjacent` (same codebook example) _(proposed for the
  stand-alone case)_.
- **Budget resolutions and appropriations** that assume Medicare or Medicaid savings → V4
  `multi-subject`; a budget resolution's assumptions are not law _(proposed)_.
- **A multi-subject bill that includes drug price negotiation** (climate, tax and health together) →
  `multi-subject`. Only an amendment or a separate vote on the negotiation provision can carry rung 3
  [b] _(proposed)_.
- **Medicaid enrollment procedure** (renewals after the pandemic, paperwork, enrollment drives) does
  not change who is eligible → `adjacent` _(proposed)_.
- **A Medicare for All bill** can also be evidence on `healthcare`. Code each topic on its own rung
  text.
- **Preemption (codebook V2, H12)** → `adjacent`.
