# ai-regulation — served revision c594dc06-0c70-4707-8ae0-d4bc760172db (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How much should government oversee artificial intelligence development and
deployment?"

**Orientation:** **inverted.** Rung 1 is the **least** government action (no interference), rung 5 the
most (approval before any deployment). Read the rung text, not the number (CLAUDE.md "Never assume
polarity").

**Levels with a role:** federal, state (`compass_topic_roles`). Both legislate; local governments
are not asked on this topic.

**Synonyms:** "automated decision system" (ADS), "automated employment decision tool", "consequential
decision", "high-risk artificial intelligence system", "algorithmic discrimination", "frontier model",
"covered model", "foundation model", "developer" and "deployer", "bias audit", "impact assessment",
"red-teaming", "watermark" or "provenance", "AI Risk Management Framework" (NIST), "AI moratorium".

1. **"Allow AI companies to develop and deploy technology freely without government interference"**
   - Means: government places no rules on how AI is built or used.
   - Operative clauses: [a] free development and deployment; [b] without government interference.
   - Establishing evidence looks like: own words that reject any government rule on AI. [b] is an
     absence clause: a vote against one AI bill does not show that the person rejects every rule
     (V4.2 "Silence is not a clause") → `direction-only`.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because "remove regulations" sounds like rung 1. With no regulation
     named it is V7 `direction` (codebook H10, Hilton / ai-regulation) and, as stance evidence,
     `direction-only`.

2. **"Suggest AI safety guidelines but let companies choose whether to follow them"**
   - Means: government writes safety guidance, and following it is voluntary.
   - Operative clauses: [a] government issues safety guidelines; [b] compliance is voluntary.
   - Establishing evidence looks like: an instrument that tells an agency to publish guidelines or a
     framework and states that compliance is voluntary; own words for voluntary standards over
     mandates _(proposed)_.
   - Levels that hold a lever: federal (agency frameworks); state (state guidance, executive orders).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because an order to **study** AI, convene a task force or report is
     not a guideline → `study-directive`.
   - Commonly confused with rung 3 when a bill pairs voluntary guidelines with a legal duty. The
     binding clause decides the rung.

3. **"Hold AI developers legally responsible when their systems cause harm"**
   - Means: the companies that build AI can be made to answer in law for harm their systems cause.
   - Operative clauses: [a] legal responsibility (liability, a cause of action, a penalty); [b] on the
     developer or company; [c] for harm the system causes.
   - Establishing evidence looks like: operative text that creates liability for harm caused by an AI
     system, where the liable party **can be the company** that made or provided it → rung 3. If the
     text reaches only an individual who misuses AI, [b] is not met → `direction-only` _(proposed)_.
     A general liability statute that does not name AI developers but reaches them meets [b].
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **disclosure or labelling** duty (watermarks, provenance,
     telling users they are dealing with AI) feels like accountability. Disclosure was taken out of
     this rung in Season 2 → BLANK `direction-only` _(ruled 2026-09-01: disclosure-only rows fit no
     rung)_.
   - Commonly confused with rung 4 because many bills test **and** assign liability. A pre-use testing
     duty is rung 4 _(ruled 2026-09-01: rows resting on safety-testing bills moved from 3 to 4)_.

4. **"Require safety testing before AI can be used in high-stakes areas like hiring, healthcare, and
   policing"**
   - Means: before AI is used for decisions in sensitive areas, the law requires it to be tested.
   - Operative clauses: [a] required safety testing; [b] before use; [c] in a high-stakes area. Hiring,
     healthcare and policing are examples ("like"), not the full list.
   - Establishing evidence looks like: operative text that requires testing of an AI system before it
     is used for consequential decisions. A testing duty limited to named high-stakes uses excludes
     rung 5 by its own text (as in codebook V4.2, Adams / trans-athletes).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because duties on **users** of AI (not developers) are oversight,
     not testing, and not developer liability → BLANK `direction-only`.
   - A required pre-use **bias audit** counts as safety testing when it tests the system's outputs
     before use. An impact assessment that is only a report, with no test → `direction-only` _(ruled 2026-10-01)_.
   - A pre-deployment testing duty scoped by **model size** (frontier or covered models), not by use
     area, meets the testing clause but not "in high-stakes areas" → `compound-partial`. It is not
     rung 5 (testing is not approval). A duty only to publish a safety framework → `direction-only`
     _(ruled 2026-10-01)_.

5. **"Impose strict government approval requirements before any AI system can be deployed"**
   - Means: no AI system may be deployed until government approves it.
   - Operative clauses: [a] government approval or licence; [b] before deployment; [c] of **any** AI
     system.
   - Establishing evidence looks like: own words or operative text for a licence or approval regime
     that covers AI systems in general. [c] is universal; approval for one class of system is not it.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both act before deployment. Rung 4 tests in named areas;
     rung 5 needs approval for all systems.
   - A **ban or moratorium on one use** (deepfakes, facial recognition, rent-setting algorithms,
     chatbots for children) is not universal approval, and Season 2 has no ban rung → BLANK
     `direction-only` _(ruled 2026-09-01: targeted-ban rows fit no rung)_.

**Hard cases:**
- **Preemption (codebook V2, H12).** A federal bill that forbids or pauses state AI laws decides which
  level may regulate, not how much → `adjacent`.
- **Government's own use of AI** (agency inventories, procurement rules, a chief AI officer) is not
  oversight of AI development and deployment in general → `adjacent` _(proposed)_.
- **Election deepfakes and synthetic media** also belong to `misinformation`; here they are a targeted
  ban or a label → BLANK `direction-only` (see rungs 3 and 5).
- **Budget and omnibus votes** with an AI item → V4 `multi-subject`.
- **A governor's signature or veto** is a record; code the bill's operative clause as above.
