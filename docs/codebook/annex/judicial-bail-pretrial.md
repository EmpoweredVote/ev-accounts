# judicial-bail-pretrial — served revision 1b4e6f5a-62e6-4939-95f3-c173eb471fb3 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked `_owed:_` need a ruling before this file is merged.

**Question:** "Should a judge trust what prosecutors say, or watch them closely?"

**Orientation:** off-axis. Rung 1 is the closest judicial scrutiny of prosecutors, rung 5 the most
trust. The rungs order **a judge's posture toward the prosecution**, not more or less government
action and not a view on crime. ⚠ The topic key says "bail", but no rung mentions bail; code the rung
text, not the key.

**Levels with a role:** judicial (`compass_topic_roles`). Only a judge, or a candidate for a judge's
seat, holds this lever: it is conduct in the role ("a judge's job"). A legislator, prosecutor or
defence lawyer cannot hold it in their own role → `off` (V2) (migration 1735 scope rule).

**Synonyms:** "prosecutorial misconduct", "Brady" or "disclosure" (evidence favourable to the
defence), "discovery", "chain of custody", "plea agreement" or "plea bargain", "plea colloquy",
"charging decision", "suppression", "dismissal with prejudice", "sanctions", "detention hearing",
"pretrial release".

1. **"Watch closely. Prosecutors have enormous power and real incentives to win. A judge's job is to
   make sure that power is used fairly."**
   - Means: the judge treats close watch over the prosecution's use of power as part of the job.
   - Operative clauses: [a] watch prosecutors closely; [b] the judge's job is to make sure that power
     is used fairly. The middle sentence is the reason; it is not a clause a passage must match
     _(proposed)_.
   - Establishing evidence looks like: own words that state close watch over prosecutors as the
     judge's duty; a pattern of opinions the person wrote that check the prosecution on the judge's
     own motion (questioning a charge, a disclosure failure or a plea) _(proposed)_.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both scrutinise the prosecution. Rung 2 names strict
     **standards**; rung 1 names the judge's **role**. A passage that only says "hold prosecutors to
     strict standards" is rung 2, not rung 1 _(proposed)_.

2. **"Be skeptical. Hold prosecution to strict standards — especially on evidence handling and plea
   deals."**
   - Means: the judge holds the prosecution to a strict standard, above all on evidence and pleas.
   - Operative clauses: [a] skepticism toward the prosecution; [b] strict standards. "Especially on
     evidence handling and plea deals" names examples; a strict standard on another matter can meet
     [b] _(proposed)_.
   - Establishing evidence looks like: an opinion the person wrote that sanctions a disclosure
     failure, suppresses evidence for mishandling, or rejects a plea deal, **and** states a strict
     standard as the reason. One ruling on one case shows direction → `direction-only` alone.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Treat both sides equally and let the process work."**
   - Means: the judge gives the prosecution no more and no less trust than the defence.
   - Operative clauses: [a] treat both sides equally; [b] let the process work.
   - Establishing evidence looks like: own words that reject both extra trust and extra scrutiny of
     the prosecution. "I am fair to both sides" alone is near-universal for judges → `rhetorical`
     _(proposed)_.
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rungs 2 and 4 when the passage only says "follow the law" (V4.2 "Ruling
     out the other rungs is not evidence").

4. **"Give prosecutors reasonable deference. They're trained professionals representing the
   public."**
   - Means: the judge starts from respect for the prosecution's judgment, within limits.
   - Operative clauses: [a] reasonable deference to prosecutors. The second sentence is the reason
     _(proposed)_.
   - Establishing evidence looks like: own words or an opinion the person wrote that gives weight to
     the prosecution's judgment as such, **plus** something that excludes rung 5 (the judge still
     reviews it).
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because the law itself gives prosecutors broad charging
     discretion. A ruling that declines to review a charge because the law forbids review is the
     law's choice, not the judge's posture → `direction-only` at most _(proposed)_.

5. **"Trust prosecutors. They represent the community and have already screened the case — judges
   shouldn't second-guess that judgment."**
   - Means: the judge accepts the prosecution's judgment and does not review it.
   - Operative clauses: [a] trust prosecutors; [b] judges should not second-guess that judgment.
   - Establishing evidence looks like: own words that reject judicial review of the prosecution's
     judgment. [b] is an absence clause: a record of accepting pleas does not show the judge would
     never question one (V4.2 "Silence is not a clause").
   - Levels that hold a lever: judicial (judges).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Bail and pretrial-detention rulings.** A ruling on the prosecution's request to detain or set bail
  is about the defendant's release, not trust in the prosecution. `_owed:_` whether such a ruling is
  `on-question` when its reasoning states how much weight the judge gives the prosecution's showing.
- **A judge's earlier career as a prosecutor or defence lawyer** is a different role and says nothing
  about the judge's posture → `off` (V2) _(proposed)_.
- **Judicial ethics.** Candidates may not promise outcomes. A questionnaire answer on how the person
  reviews plea deals or disclosure is `statement-answer` (V3); "tough on crime" or "protect the
  accused" with no posture toward prosecutors → `rhetorical`.
- **A written opinion** the judge authored is `record` (`record_kind = author`); the instrument is the
  case name and docket number. Code the standard the opinion states, not who won _(proposed)_.
- **Court statistics** (plea-acceptance rates, dismissal counts) compiled by a third party →
  `not-evidence` (V3); follow them to the named cases _(proposed)_.
- **Bar complaints or appellate reversals** about the judge are not the judge's own act →
  `third-party-characterization` (V1).
- **A record from a lower court** is `pre-seating`: valid for that office only (V5). It counts for
  the current seat only when the rung's lever is the same at both courts (an opinion that shows the
  judge's method, the judge's own sealing or access practice), and the coder names that lever _(ruled 2026-10-01)_.
