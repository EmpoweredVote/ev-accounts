# judicial-interpretation — served revision e9bd9e3b-5ced-439e-b989-b98643d053f2 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked `_owed:_` need a ruling before this file is merged.

**Question:** "Does the law change with the times, or does it mean what it said when it was written?"

**Orientation:** off-axis. Rung 1 is the most change with the times (read the law in light of how
society has changed), rung 5 the most fixed (apply it as written; change is for lawmakers). The rungs
order **interpretive method**, not policy: any method can produce any policy outcome, so never infer
a rung from the result of a case or from which judges a person praises.

**Levels with a role:** judicial (`compass_topic_roles`). The lever is a judge's method in written
opinions. A non-judge can only hold an opinion about method. A legislator's vote on a judicial
nominee is a vote on a person, not a statement of method → `off` (V2) _(proposed)_.

**Synonyms:** "living constitution", "evolving standards", "purposivism", "purpose" or "spirit of the
law", "legislative intent", "legislative history", "plain meaning", "textualism", "original public
meaning", "originalism", "original intent", "canons of construction", "absurdity doctrine",
"judicial restraint", "legislating from the bench". ⚠ "Stare decisis" (keeping or overturning
precedent) is not this axis → `off-axis` (V4).

1. **"Judges should read the law in light of how society has changed, not only what it meant long
   ago."**
   - Means: the law's meaning can grow as society changes.
   - Operative clauses: [a] read the law in light of how society has changed; [b] not only its
     original meaning.
   - Establishing evidence looks like: own words or an opinion the person wrote that reads a text by
     present-day understanding because society has changed.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both go beyond the exact words. Rung 2 follows the law's
     **purpose** as enacted; rung 1 updates its **meaning** to the present.
   - **Overturning precedent** is not rung 1. Judges of every method overturn precedent → `off-axis`.

2. **"Judges should follow what the law was meant to achieve, even when the exact words don't fit a
   new situation."**
   - Means: the law's purpose governs when its words do not fit.
   - Operative clauses: [a] follow what the law was meant to achieve; [b] even when the exact words
     do not fit.
   - Establishing evidence looks like: own words or an opinion that sets aside a poor fit of the words
     to serve the statute's stated purpose.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because both weigh purpose. Rung 3 uses purpose only when the words
     are **unclear**; rung 2 lets purpose govern when the words are clear but do not fit.

3. **"Start with what the law says; when the words are unclear, weigh what lawmakers were trying to
   do."**
   - Means: text first; purpose and intent only to resolve unclear words.
   - Operative clauses: [a] start with the text; [b] when the words are unclear, weigh what lawmakers
     were trying to do.
   - Establishing evidence looks like: own words or an opinion that reads the text first and, finding
     it unclear, turns to the drafters' purpose or legislative history. Compound: text-first alone →
     `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rungs 4 and 5 because all three start with the text. Rung 3 is the only
     one that turns to lawmakers' aims.

4. **"Stick to what the words meant when they were written; don't update them to fit new times."**
   - Means: the words carry the meaning they had when enacted.
   - Operative clauses: [a] the meaning the words had when written; [b] no updating to fit new times.
   - Establishing evidence looks like: own words or an opinion that fixes a text's meaning by the
     public meaning at the time of enactment.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5: see rung 5.

5. **"Judges should apply the law as written. If it needs to change, that is for elected
   lawmakers."**
   - Means: the judge applies the text and leaves change to the legislature.
   - Operative clauses: [a] apply the law as written; [b] change is for elected lawmakers.
   - Establishing evidence looks like: own words or an opinion that states both clauses.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a person who holds rung 4 usually says rung 5's sentence
     too, and rung 5 names no method that rung 4 lacks. `_owed:_` what excludes rung 4 when a passage
     states only rung 5's two clauses.
   - **"Apply the law, don't make it" / "not legislate from the bench"** is said by nearly every
     judicial candidate. Alone it does not exclude rungs 3 or 4 → `rhetorical` or `direction-only`
     _(proposed)_.

**Hard cases:**
- **Outcome is not method.** A ruling's result does not set a rung; code the method the opinion
  states _(proposed)_.
- **Praise for a named justice or a court** is not the person's own method → `direction-only` at most
  _(proposed)_.
- **A brief a legal officer files** (an attorney general's brief that argues a method) argues for a
  client. `_owed:_` whether such a brief evidences the officer's own method.
- **Judicial ethics.** Candidates may not promise outcomes, but they may state a method. A
  questionnaire answer on method is `statement-answer` (V3).
- **A written opinion** the judge authored is `record` (`record_kind = author`); the instrument is the
  case name and docket. Joining another judge's opinion is `vote` _(proposed)_. `_owed:_` whether a
  unanimous appellate panel counts as `near-unanimous`.
- `_owed:_` whether a judge's record on a lower court counts as `in-term` for the current seat.
