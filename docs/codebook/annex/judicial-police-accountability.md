# judicial-police-accountability — served revision eb6e1ecd-daa3-4362-810b-55fab93ff64c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "When a government employee is accused of misconduct, should the office defend them or
hold them accountable?"

**Orientation:** standard. Rung 1 is the most active accountability, rung 5 the most defence. The
rungs order **how the office responds to accused misconduct by government employees** — police and
every other employee, despite the title.

**Levels with a role:** judicial (`compass_topic_roles`). The lever is held by legal offices, and it
differs by office: a district attorney or attorney general charges or declines to charge an employee
and can run independent review; a city or county attorney defends, settles or concedes civil claims
and advises on discipline. Code each office from its own lever against the same rung text. A
legislator or council member is not this office → `off` (V2) (migration 1735 scope rule).

**Synonyms:** "use of force", "officer-involved shooting", "in-custody death", "independent
investigation", "public integrity unit", "civilian oversight", "internal affairs", "Brady list" or
"do-not-call list", "qualified immunity", "indemnification", "civil rights claim" or "§ 1983",
"pattern or practice", "consent decree", "settlement".

1. **"Actively hold government employees accountable when they do wrong, even when they are on the
   office's own side."**
   - Means: the office goes after misconduct on its own initiative, including by its working partners.
   - Operative clauses: [a] actively hold employees accountable; [b] even when they are on the
     office's own side.
   - Establishing evidence looks like: a standing structure or policy the person created or ran that
     reviews misconduct without waiting for a complaint (an independent unit that reviews every use
     of force, a policy to charge where the evidence supports it), or own words stating that duty.
     One charge in one case does not show "actively" → `direction-only` alone _(proposed)_.
   - Levels that hold a lever: judicial (DA, AG, city or county attorney).
   - Known chair-shaped instruments: _(none on file under this codebook)_. Background only: the Season
     1 re-audit (CA_0097) seated an attorney general here on mandatory independent DOJ review
     (California AB 1506) and a Police Practices Review Division; not re-checked against this text.
   - Commonly confused with rung 2 because both act on misconduct. Rung 2 **responds** to complaints;
     rung 1 **seeks out** misconduct.

2. **"Take misconduct complaints seriously, and act on the ones that hold up."**
   - Means: the office investigates complaints and acts when they are borne out.
   - Operative clauses: [a] take complaints seriously; [b] act on the ones that hold up.
   - Establishing evidence looks like: a complaint-review process the person set up or ran, plus acts
     on sustained complaints, plus something that excludes rung 1 (no proactive review).
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because "act on the ones that hold up" and "hold them accountable
     when it has merit" describe the same act. Rung 3 adds a duty to **defend** against weak
     complaints; code rung 3 only when that clause is evidenced _(proposed)_.

3. **"Defend government employees when a complaint is weak, and hold them accountable when it has
   merit."**
   - Means: the office does both duties, choosing by the strength of the complaint.
   - Operative clauses: [a] defend when the complaint is weak; [b] hold accountable when it has
     merit. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: own words that state both duties; a record that shows both a
     defence of a weak claim and accountability on a strong one.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Give government employees the benefit of the doubt, and act only when the wrongdoing is
   clear."**
   - Means: the office presumes the employee acted properly and acts only on clear wrongdoing.
   - Operative clauses: [a] benefit of the doubt; [b] act only when wrongdoing is clear.
   - Establishing evidence looks like: own words or a written policy that sets a presumption for the
     employee, or a high threshold before the office acts.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a declination for lack of evidence fits both. A declination
     memo that applies the legal standard for charging shows no presumption → `direction-only`
     _(proposed)_.

5. **"Stand behind government employees and defend their conduct rather than hold them accountable."**
   - Means: the office's role is to defend employees, not to hold them to account.
   - Operative clauses: [a] stand behind and defend their conduct; [b] rather than hold them
     accountable.
   - Establishing evidence looks like: own words that put defence of employees ahead of accountability
     as the office's role; a policy that refuses to cooperate with oversight.
   - Levels that hold a lever: judicial (mostly city or county attorneys).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: rung 4 still acts on clear wrongdoing; rung 5 does not.

**Hard cases:**
- **Defending one civil suit** is the city attorney's legal duty; it does not show posture →
  `direction-only` at most _(proposed)_.
- **A settlement** is often a cost decision, not a finding about the employee → `direction-only`
  unless the passage ties it to accountability _(proposed)_.
- **Prosecuting members of the public** (protesters, people arrested by police) is not accountability
  for government employees → `off-axis` (V4) _(proposed)_.
- **A record and a statement that disagree** (a stated support for oversight, and an office that
  declines to cooperate with it) → the record wins; `record-vs-statement-conflict` when it decides the
  chair (V3).
- **For a prosecutor, the police are "the office's own side"** in rung 1: they are the office's
  working partners _(ruled 2026-10-01)_.
- **Legislation** on police accountability by a legislator is outside this office → `off`; an
  attorney general's own legislative career is `pre-seating` (V5).
- **Budget and omnibus votes** → V4 `multi-subject`.
