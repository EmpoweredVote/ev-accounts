# judicial-prosecution-priorities — served revision f7fe7332-5068-4d41-a8cd-d837b9cdba82 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "Does the office try to put people away, or find better solutions?"

**Orientation:** standard. Rung 1 makes prosecution a last resort, rung 5 prosecutes every case that
can be prosecuted. The rungs order **the default between prosecution and diversion** for a case the
office could charge. They are not about sentence length.

**Levels with a lever:** judicial. The lever is a prosecuting office's charging
and diversion choices: district attorneys, city attorneys with misdemeanor jurisdiction, attorneys
general where they prosecute. Only a holder of, or candidate for, that office is coded; a legislator
who votes on diversion statutes is not this office → `off` (V2) (migration 1735 scope rule).

**Asked at:** judicial (`compass_topic_roles`, CA_0302).

**Synonyms:** "diversion", "pre-filing" or "pre-charge diversion", "deferred prosecution",
"declination" or "decline to file", "charging policy", "special directive", "community court",
"collaborative court", "drug court", "treatment in lieu of prosecution", "low-level offenses",
"quality-of-life offenses", "filing standard", "case screening".

1. **"Prosecution should be a last resort. Connecting people to treatment, housing, or job programs
   does more good than a criminal record."**
   - Means: the office tries services first and prosecutes only when nothing else will do.
   - Operative clauses: [a] prosecution as a last resort; [b] connect people to treatment, housing or
     job programmes instead.
   - Establishing evidence looks like: an office-wide policy the person set that routes chargeable
     cases to services by default, with prosecution kept for what is left; own words stating that.
   - Levels that hold a lever: judicial (prosecuting offices).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both use diversion. Rung 1 makes diversion the **default**
     for all cases; rung 2 uses it "when it's available and makes sense".
   - **A policy to decline a class of cases** with no link to services meets [a] for that class and
     not [b] → `compound-partial` _(proposed)_.

2. **"Use diversion when it's available and makes sense. Reserve prosecution for when community
   safety actually requires it."**
   - Means: diversion is the normal choice where it fits; prosecution is for safety cases.
   - Operative clauses: [a] use diversion when available and sensible; [b] reserve prosecution for
     when community safety requires it.
   - Establishing evidence looks like: a charging policy that sends eligible cases to diversion and
     names public safety as the test for filing. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because both use diversion case by case. The test is the default:
     rung 2 prosecutes **only** for safety; rung 3 prosecutes every **strong** case and diverts by
     exception.

3. **"Strong cases get prosecuted. Diversion is used when there's a clear benefit — it's a judgment
   call every time."**
   - Means: prosecution is the default for strong cases, with diversion chosen case by case.
   - Operative clauses: [a] strong cases get prosecuted; [b] diversion when there is a clear benefit.
   - Establishing evidence looks like: own words or a policy that sets both. Creating or running one
     diversion programme alone is consistent with rungs 1, 2 and 3 → `direction-only`.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both prosecute strong cases. Rung 4 makes declination an
     exception that **needs a strong reason**; rung 3 uses diversion whenever it clearly helps.

4. **"Prosecute all solid cases. Declination is the exception and needs a strong reason."**
   - Means: every solid case is charged unless there is a strong reason not to.
   - Operative clauses: [a] prosecute all solid cases; [b] declination is an exception that needs a
     strong reason.
   - Establishing evidence looks like: a filing policy or own words that require a stated reason to
     decline a provable case, plus something that excludes rung 5 (declination remains possible).
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.

5. **"The office enforces the law — not social policy. If a case is prosecutable, prosecute it. Courts
   figure out the rest."**
   - Means: the office charges every prosecutable case and leaves the outcome to the courts.
   - Operative clauses: [a] enforce the law, not social policy; [b] if prosecutable, prosecute.
   - Establishing evidence looks like: own words that reject discretion to decline or divert
     prosecutable cases. [b] is an "every case" clause: a record of high filing rates does not show
     the office never declines (V4.2 "Silence is not a clause").
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: rung 4 still allows a declination with a strong reason.

**Hard cases:**
- **Sentence severity** (seeking enhancements, the maximum sentence) is the criminal-justice topic,
  not the charge-or-divert choice → `adjacent` _(proposed)_.
- **Office statistics** (filing rates, diversion counts) show outcomes, not the policy that produced
  them → `direction-only` at most; a third party's compilation → `not-evidence` (V3) _(proposed)_.
- **A campaign promise to "prosecute criminals" or "end mass incarceration"** names no default →
  `rhetorical`.
- **A diversion statute** the person voted on as a legislator is another level → `pre-seating` (V5)
  and `off` for this office.
- **Prosecution of police or other government employees** is the police-accountability topic →
  `adjacent`.
- **A charge in one case** does not set the office's default → `direction-only` at most _(proposed)_.
- **Budget votes** on the office's funding → V4 `multi-subject`.
