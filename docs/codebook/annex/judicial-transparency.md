# judicial-transparency — served revision 15252183-dcf4-4ea9-b2e8-0faf26175bb0 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How much should the public know about what happens in court?"

**Orientation:** standard. Rung 1 is fully open (never seal, never close), rung 5 is closed by
default. The rungs order **the strength of the presumption that court proceedings are open**, not
which reasons justify sealing.

**Levels with a role:** judicial (`compass_topic_roles`). The lever is a judge's sealing, closure and
protective orders, and a court's rules on public access. Legislators who write sealing statutes are
not this role → `off` (V2) _(proposed)_.

**Synonyms:** "sealing order", "motion to seal", "closure" or "closed hearing", "in camera",
"protective order", "redaction", "presumption of access", "right of access", "overriding interest",
"narrowly tailored", "specific findings", "confidential settlement", "juvenile records",
"public access to court records".

1. **"Everything in court should be public. Courts should never seal records or close hearings."**
   - Means: no sealing and no closure, ever.
   - Operative clauses: [a] everything public; [b] never seal records or close hearings.
   - Establishing evidence looks like: own words that reject all sealing and closure, including
     sealing the law requires. [b] is an absence clause: a record of refusing many motions to seal
     does not say "never" (V4.2 "Silence is not a clause").
   - Levels that hold a lever: judicial (judges, rule-making courts).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both refuse discretionary sealing. Rung 2 keeps the
     sealing the law requires.

2. **"Courts should be open except where the law requires privacy, like juvenile records. Judges
   shouldn't seal anything beyond that."**
   - Means: seal only what the law requires; no judicial discretion to seal more.
   - Operative clauses: [a] open except where the law requires privacy; [b] no sealing beyond that.
   - Establishing evidence looks like: own words or an opinion the person wrote that rejects
     discretionary sealing or closure as such. [b] is an absence clause: refusing one motion to seal
     does not show the person would refuse every discretionary one → `direction-only`.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a judge who refuses a motion to seal under the strong-reason
     test is applying rung 3, not rejecting discretion. Code rung 2 only when the passage rejects the
     discretion itself _(proposed)_.

3. **"Courts should be open by default. A judge can seal records or close a hearing only when there's
   a strong, specific reason that outweighs the public's interest."**
   - Means: open by default; discretionary sealing is allowed only on a strong, case-specific showing.
   - Operative clauses: [a] open by default; [b] seal or close only for a strong, specific reason that
     outweighs the public interest.
   - Establishing evidence looks like: own words stating this test as the person's view; an opinion
     the person wrote that argues for it where the law left room.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because this test is often the **law** a judge must apply. A ruling
     that applies the required access test as written shows compliance, not posture →
     `direction-only` _(proposed)_.

4. **"Openness matters, but so do privacy and fair trials. Judges should seal or close proceedings
   whenever sensitive information is at stake."**
   - Means: sealing or closure is readily available whenever sensitive interests are involved.
   - Operative clauses: [a] privacy and fair trials weigh with openness; [b] seal or close whenever
     sensitive information is at stake.
   - Establishing evidence looks like: own words or a court rule the person adopted that permits
     sealing on a showing of sensitivity, without the strong-reason test.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because one granted motion to seal fits both. The test is the
     threshold the passage states, not the outcome.

5. **"Court proceedings should be closed to the public by default. A judge decides what, if anything,
   becomes public."**
   - Means: closed unless the judge chooses to open.
   - Operative clauses: [a] closed by default; [b] the judge decides what becomes public.
   - Establishing evidence looks like: own words or a rule that makes closure the default for a
     general class of proceedings.
   - Levels that hold a lever: judicial.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: rung 4 starts open; rung 5 starts closed.
   - A rule that closes **one class** where the law already requires it (juvenile, adoption) is rung
     2's carve-out, not rung 5 _(proposed)_.

**Hard cases:**
- **Cameras and broadcast rules** decide how a public hearing is shown, not whether it is open →
  `adjacent` _(proposed)_.
- **Gag orders** limit what parties say, not public access to the court → `adjacent` _(proposed)_.
- **Publishing opinions or court data** is outside the rung text (sealing and closing) → `adjacent`
  _(proposed)_.
- **Court clerks' records-access rules** (fees, remote access) do not seal or close → `adjacent`
  _(proposed)_.
- **Judicial ethics.** Candidates may state a view on openness. A questionnaire answer is
  `statement-answer` (V3); "transparency matters" with no threshold → `rhetorical`.
- **A written opinion or order** the judge authored is `record` (`record_kind = author`); the
  instrument is the case name and docket. Code the threshold the order states, not whether it sealed
  _(proposed)_.
- **A record from a lower court** is `pre-seating`: valid for that office only (V5). It counts for
  the current seat only when the rung's lever is the same at both courts (an opinion that shows the
  judge's method, the judge's own sealing or access practice), and the coder names that lever _(ruled 2026-10-01)_.
