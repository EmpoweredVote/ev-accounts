# judicial-access-to-justice — served revision 6c1d0a40-eb5c-481b-b035-323dedaa0d88 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked `_owed:_` need a ruling before this file is merged.

**Question:** "How easy should it be to use the courts?"

**Orientation:** standard. Rung 1 is the most access (the court clears away costs and hurdles), rung
5 the least (courts for serious cases only). The rungs order **how high the bar is to get a case
heard**, as a legal actor sets it in their own role — not opinions about the legal system.

**Levels with a role:** judicial (`compass_topic_roles`). The lever is held by legal-system actors in
their role: judges (rulings on pleadings, dismissals, fees), presiding judges and court rule-makers
(court-wide programmes and rules), court clerks (filing, fees, hours, language help). Legislators who
fund legal aid or write court-access statutes are not in this role → `off` _(proposed)_.

**Synonyms:** "fee waiver", "in forma pauperis" (IFP), "self-represented" or "pro se" litigant,
"self-help center", "e-filing", "language access", "court interpreter", "civil right to counsel",
"legal aid", "leave to amend", "excusable neglect", "lenient construction", "plausibility pleading",
"heightened pleading", "certificate of merit", "anti-SLAPP", "vexatious litigant", "standing",
"alternative dispute resolution" (ADR), "mandatory arbitration", "mediation", "small claims".

1. **"Make it easy to bring a case, and clear away the costs and hurdles that shut people out."**
   - Means: the court works actively to lower the cost and difficulty of getting a case in.
   - Operative clauses: [a] make it easy to bring a case; [b] clear away costs and hurdles.
   - Establishing evidence looks like: a court-wide rule or programme the person adopted or led that
     removes a cost or hurdle (fee waivers made easier, self-help centres, interpreters, simpler
     forms, remote filing); own words calling for that as the court's job. One programme for one
     hurdle shows direction; it does not exclude rung 2 unless the passage goes beyond excusing
     mistakes → `direction-only` alone _(proposed)_.
   - Levels that hold a lever: judicial (presiding judges, rule-making courts, clerks for [b]).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both help the person who gets things wrong. Rung 2 keeps
     the normal requirements; rung 1 removes them.

2. **"Apply the normal requirements, but don't let small mistakes or technicalities keep a real case
   out."**
   - Means: the usual rules apply, but a court forgives minor errors so a real claim is heard.
   - Operative clauses: [a] apply the normal requirements; [b] do not let small mistakes or
     technicalities keep a real case out.
   - Establishing evidence looks like: an opinion the person wrote that reads a self-represented
     filing generously, grants leave to amend, or excuses a missed formality **and** keeps the
     requirement in force; own words stating that posture. Compound: one side only →
     `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because forgiving a mistake the rules themselves forgive is
     applying the same rules to everyone. Code rung 2 only when the passage chooses leniency the
     rules allow but do not require _(proposed)_.

3. **"Apply the same rules to everyone, and let a case stand or fall on its own merits."**
   - Means: no thumb on the scale for or against access; the rules apply evenly and the merits decide.
   - Operative clauses: [a] the same rules for everyone; [b] the merits decide.
   - Establishing evidence looks like: own words that reject both special leniency and a raised bar.
     "I treat everyone the same" alone is near-universal for judges → `rhetorical` _(proposed)_.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rungs 2 and 4: a passage that only says "follow the rules" does not
     exclude either (V4.2 "Ruling out the other rungs is not evidence").

4. **"Require people to show a strong case up front, and dismiss those that fall short."**
   - Means: a case must show real strength at the start, and weak ones are dismissed early.
   - Operative clauses: [a] require a strong case up front; [b] dismiss those that fall short.
   - Establishing evidence looks like: an opinion the person wrote that applies or argues for a
     heightened threshold at the start (plausibility pleading, a certificate of merit, an early
     anti-SLAPP or vexatious-litigant screen) and dismisses on it, **plus** something that excludes
     rung 5 (the person does not want such cases out of court altogether).
   - Levels that hold a lever: judicial (judges, rule-making courts).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a judge who dismisses under a threshold the law **requires**
     is applying the same rules. Code rung 4 only for a bar the person chose or argued for _(proposed)_.

5. **"Keep the courts for serious cases only, and steer other disputes elsewhere."**
   - Means: courts are a last resort; most disputes should go to other forums.
   - Operative clauses: [a] courts for serious cases only; [b] steer other disputes elsewhere.
   - Establishing evidence looks like: a rule or programme that sends a class of disputes out of the
     court system (to arbitration or another forum) **and** own words or a rule that limits the court
     to serious cases. Compound: one side only → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: judicial (rule-making courts, presiding judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: rung 4 keeps the case in court and tests it; rung 5 sends it out.
   - **Court-run mediation** that keeps the case on the court's docket does not "steer elsewhere" →
     not rung 5 on its own → `direction-only` _(proposed)_.

**Hard cases:**
- **Legal-aid funding votes and court-access bills by legislators** are outside this role → `off`
  (V2). Season 2 codes legal actors only _(proposed)_.
- **Court clerks** control filing costs, hours and language help (rung 1 [b]) but never whether a case
  stands, so only rung 1 can be reached for a clerk. `_owed:_` whether clerks are coded on this
  ladder.
- **A ruling that grants a fee waiver or dismisses a case because binding law requires it** is the
  law's choice, not the judge's posture → `direction-only` at most _(proposed)_.
- **Criminal diversion** (alternative courts for defendants) is a criminal-justice or prosecution
  question, not access to the courts for people bringing cases → `adjacent` _(proposed)_.
- **Judicial ethics.** Candidates may not promise outcomes. "I will be fair to every litigant" →
  `rhetorical`. A questionnaire answer on how the person treats self-represented litigants →
  `statement-answer` (V3).
- **A written opinion** the judge authored is `record` (`record_kind = author`); the instrument is the
  case name and docket number. Code the standard the opinion states, not who won _(proposed)_.
- **A record from a lower court** is `pre-seating`: valid for that office only (V5). It counts for
  the current seat only when the rung's lever is the same at both courts (an opinion that shows the
  judge's method, the judge's own sealing or access practice), and the coder names that lever _(ruled 2026-10-01)_.
