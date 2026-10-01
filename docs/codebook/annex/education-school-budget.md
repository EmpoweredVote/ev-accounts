# education-school-budget — served revision 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked `_owed:_` need a ruling before this file is merged.

**Question:** "How should schools set spending levels and decide whether to raise more revenue?"

**Orientation:** standard. Rung 1 raises taxes to raise funding a lot; rung 5 cuts funding a lot to
cut taxes. The rungs order **the funding level and its tax source**. Rung 4 is about the **mix** of
spending (administration against classroom), not the level.

**Levels with a role:** local, school, state (`compass_topic_roles`). The lever is the school board's
budget and levy, the city or county council where it funds or approves the school budget, and the
state's school-aid formula and tax law.

**Synonyms:** "levy", "mill rate", "millage", "operating referendum", "override", "bond", "per-pupil
funding", "foundation amount", "school-aid formula", "adequacy", "truth in taxation", "levy limit",
"tax cap", "property-tax relief", "maintenance of effort", "central office", "administrative
overhead", "classroom spending".

1. **"Raise taxes to significantly increase school funding"**
   - Means: a tax increase that pays for a large rise in school funding.
   - Operative clauses: [a] a tax increase; [b] a significant funding increase. Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a vote to raise the levy or rate, or to put an operating
     referendum or override on the ballot, where the passage shows the increase is large.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - `_owed:_` where is the line between "significantly" and "modestly", and how is a tax-funded
     increase that only keeps pace with costs coded?

2. **"Increase funding modestly to keep pace with costs, without raising taxes"**
   - Means: funding rises about as fast as costs, paid from existing revenue.
   - Operative clauses: [a] a modest increase that tracks costs (inflation, enrollment); [b] no tax
     increase. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget whose increase tracks costs **and** a levy or rate
     held at its current level. [b] is an absence clause: the passage must show no tax increase
     (V4.2 "Silence is not a clause").
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the nominal budget is flat but costs rise. Code the change
     the passage states; do not convert to real terms _(proposed)_.

3. **"Hold funding flat at current levels"**
   - Means: no increase and no cut.
   - Operative clauses: [a] the total stays at its current level.
   - Establishing evidence looks like: a budget or own words that keep the total the same as last
     year.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.

4. **"Cut administrative overhead to lower costs while protecting classroom funding"**
   - Means: spend less on administration and keep classroom spending whole.
   - Operative clauses: [a] a cut to administrative overhead; [b] classroom funding protected.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget amendment or own words that cut central-office or
     administrative spending **and** keep classroom spending at or above its level.
   - Levels that hold a lever: school; local; state (classroom-spending floors).
   - Known chair-shaped instruments: _(none on file)_.
   - A classroom-spending floor (a share that must go to instruction) meets [b] only →
     `compound-partial` _(proposed)_.

5. **"Cut school funding significantly to reduce the taxes residents pay"**
   - Means: a large funding cut that is made to lower taxes.
   - Operative clauses: [a] a significant funding cut; [b] made to reduce taxes. Compound: one side
     only → `compound-partial`.
   - Establishing evidence looks like: a vote to lower the levy or rate together with a large
     budget cut; own words that tie the two.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **Property-tax relief that the state replaces with state aid** lowers taxes without cutting
     funding → not [a] → `direction-only` _(proposed)_.

**Hard cases:**
- `_owed:_` is a Yes on the district's annual budget `multi-subject`, or `on-question` on this
  ladder because the total is the subject?
- **A No on a budget** proves nothing (V4.1).
- **What counts as raising taxes.** A higher rate, a higher levy amount, a new tax, or approval of a
  referendum, override or bond raises taxes. A rate held flat while values rise is not a tax
  increase unless the instrument says it raises the levy _(proposed)_.
- **Capital bonds** fund buildings, not operating spending → [a] at most; code [b] only when the
  passage ties the bond to the funding level _(proposed)_.
- **State levy limits and tax caps** on districts limit what a district may raise; they do not by
  their own text cut funding or lower a tax → `adjacent` (V2, H12), unless the act itself lowers
  rates _(proposed)_.
- **A state budget** with a school-aid line → V4 `multi-subject`; a single-subject school-aid bill →
  on-question.
- **Teacher pay and specific programmes** → `adjacent` unless the passage states the total level.
