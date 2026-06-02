# Phase 87: Stance Accuracy Audit + Agent Update — Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 87 delivers two things:

1. **SACC-01 — Formal audit artifact** (`87-AUDIT-REPORT.md`): A prioritized correction list for all ~1,049 politicians, produced by low-variance SQL flagging + formalized from the 2026-06-02 informal audit. Consumed directly by Phase 88 to drive re-research order.

2. **SACC-04 — Researcher agent update** (`.claude/skills/research-stances/SKILL.md`): Replace the existing SCALE RULE section with a five-chairs framing block, so all future stance research starts from the correct evaluation posture.

Phase 87 does **not** perform any corrections. That is Phase 88's job.

</domain>

<decisions>
## Implementation Decisions

### Five-Chairs Framing (SACC-04)

- **D-01:** Replace the existing `SCALE RULE — CRITICAL` block in `research-stances/SKILL.md` with a new **five-chairs framing** section. Do not keep the old text — the replacement should make the new framing the only authoritative voice on this topic.

- **D-02:** Source for the block is the five-chairs philosophy document captured in this session (reproduced in `<specifics>` below). Write the SKILL.md block naturally from that document — do not paraphrase robotically. The chair metaphor, the defensibility claim, and the direction-is-arbitrary rule all belong in the block.

- **D-03:** The block's core instruction to the researcher agent: "Read the written text at each value level for this topic. Find sources that document this politician's position. Match the documented record to the chair whose text fits — do not pick based on party expectation or directional assumption." The scale can be visually flipped for users; neither end is the 'correct' side. Value=1 is not conservative; value=5 is not progressive. Direction varies per topic.

- **D-04:** The defensibility framing must be present: when a voter matches a politician on a topic, the system can say *why* — "you both hold the position that [specific written text]" — not just "you both scored a 2." The researcher agent's value assignment must make that specific claim possible.

### Audit Artifact Format (SACC-01)

- **D-05:** Audit artifact lives at `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md`. This puts it in the planning hierarchy where Phase 88's planner will find it.

- **D-06:** The report table has these columns per politician: `name`, `party`, `office`, `stance_count`, `flagged_count`, `priority_tier`, `flagged_topics` (comma-separated list of topic_keys that triggered flags).

- **D-07:** Three priority tiers: `confirmed-inversion` / `borderline` / `likely-correct`. The 8 known confirmed inversions from the 2026-06-02 informal audit go at the top under `confirmed-inversion` — they are pre-seeded, not re-derived from SQL.

- **D-08:** The audit SQL is documented in the report in a fenced code block so it can be re-run in future milestones.

### Audit SQL Methodology (SACC-01)

- **D-09:** **Primary flag (B):** >= 60% of a politician's stances are the same single value. For a politician with 30 topics, that means 18+ stances all at value=4 (or all at value=2, etc.). This catches lazy-research patterns like Nixon's all-4s without importing any party assumption.

- **D-10:** **Baseline (C):** The 8 confirmed inversions from the 2026-06-02 informal audit are the canonical starting point. They are pre-seeded into the `confirmed-inversion` tier in the report. The formal SQL run produces the `borderline` / `likely-correct` tier additions.

- **D-11:** **Party-distribution comparison (A — optional exploration only):** A party-distribution query (compare politician values to their party's per-topic median) may be included in the report as a documented reference tool. It is NOT used as the primary priority signal. Using party distributions as the primary flag would encode the partisan directional assumption that five-chairs framing rejects.

### Claude's Discretion

- Threshold tuning: if the 60% threshold produces fewer than ~30 flagged politicians beyond the 8 known inversions, the planner may lower it to 50%. If it produces more than ~100, raise to 70%. Goal is a signal-rich but workable correction list for Phase 88.
- Report sectioning: beyond the required columns, the planner may add summary statistics (total politicians audited, flag rate, party breakdown of flags) if useful.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and scope
- `.planning/REQUIREMENTS.md` — SACC-01, SACC-04 definitions (the two requirements this phase closes)
- `.planning/ROADMAP.md` §Phase 87 — success criteria, wave structure, dependencies

### Prior audit findings (baseline for confirmed-inversion tier)
- `.planning/STATE.md` §v2.6 Stance Accuracy Retro — 8 confirmed inversions with flag counts, known-correct cases that must NOT be corrected (Collins/Murkowski/Tillis SSM, VanDeaver school-vouchers), ukraine-support note (26 Rs deferred to Phase 88)

### Researcher agent to be updated
- `.claude/skills/research-stances/SKILL.md` — current SKILL.md; the `SCALE RULE — CRITICAL` section will be replaced by the five-chairs block

### Database tables (audit SQL targets)
- `inform.politician_answers` — `(politician_id, topic_id, value)` — primary audit target
- `essentials.politicians` — `(id, full_name, party, ...)` — politician metadata for the report
- `inform.compass_topics` — `(id, topic_key, ...)` — for joining topic_key into flagged_topics column

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/src/lib/db.js` (`pool`) — use for all audit SQL queries via the standard `pool.query()` pattern; same as every other direct-postgres query in this repo
- `backend/data/stance-research/` — established pattern for output artifacts; the audit report is a planning doc, not a data file, but the CSV pattern is reference for any supplemental output

### Established Patterns
- **Direct postgres for all `inform.*` reads:** `inform.politician_answers` is not in the PostgREST exposed schema list. All audit queries must use `pool.query()`, not `supabaseAdmin.schema('inform')`.
- **Migration number:** Last applied is 256. Phase 87 produces no migrations — it's a read-only audit + SKILL.md edit.

### Integration Points
- Phase 88 reads `87-AUDIT-REPORT.md` to determine which politicians to re-research and in what order. The report table format (especially `priority_tier` and `flagged_topics` columns) directly drives Phase 88's work queue.

</code_context>

<specifics>
## Specific Ideas

### Five-Chairs Philosophy (source for SKILL.md update)

The researcher agent update must reflect this framing, captured from the product team's explanation:

> Each question on the compass has five pre-written stances — one for each position on the spoke. These aren't degree-of-agreement markers. They are five distinct, substantive positions on the issue: positions a real person could hold, defend in a conversation, and point to a policy that reflects it.
>
> Think of them less like a dial and more like five named chairs in a room. A voter isn't saying "how strongly do I feel about Chair 1" — they're picking the chair that actually fits their view. A politician's public record places them in one of those same chairs.
>
> The stances don't have a partisan direction — they're just positions. The spoke can be visually flipped on the chart so that neither end looks like the "correct" side.
>
> When a voter's compass aligns with a politician's, we can say exactly why. Not "they both scored a 2 on Climate," but "they both support a carbon price with revenue returned to households." That's a claim we can back up with the source.

The SKILL.md block should make this the researcher agent's evaluative posture — not just a rule to follow but a framing to reason from.

### Known Confirmed Inversions (pre-seed into report)

From 2026-06-02 informal audit — these go straight into `confirmed-inversion` tier:

| Name | Party | Office | Flag count | Notes |
|------|-------|--------|-----------|-------|
| Jeff Gonzalez | R | CA Assembly | 17 | All stances read as progressive Democrat |
| Roger Niello | R | CA State Sen. | 11 | Same pattern |
| Angie Nixon | D | FL Senate cand. | 10 | Every topic locked at value=4 |
| Alex Vindman | D | FL Senate cand. | 9 | abortion=5 religious-freedom=5 |
| Tim Grayson | D | CA State Sen. | 9 | civil-rights=5 climate=5 SSM=5 |
| Ashley Hinson | R | IA Senate cand. | 9 | abortion=2 climate=2 immigration=2 |
| Derek Dooley | R | GA Senate cand. | 9 | Same pattern as Hinson |
| Adam Hinojosa | listed as D | TX? | 6 | Values look Republican — party tag may be wrong |

### Known-Correct Cases (do NOT flag or correct)

- Collins, Murkowski, Tillis, Young, Capito: SSM=2 ✓ (all voted for Respect for Marriage Act)
- Gary VanDeaver (R-TX): school-vouchers=2 ✓ (voted against TX voucher bills)

These must be called out in the audit report as reviewed-and-confirmed to prevent Phase 88 from re-researching them unnecessarily.

</specifics>

<deferred>
## Deferred Ideas

- **Ukraine-support Rs (26 at value=2):** Individual verification deferred to Phase 88. Phase 87 notes them in the report but does not attempt corrections.
- **Party string normalization ("Democrat" vs "Democratic"):** Phase 88 scope (SACC-03). Phase 87 may note the inconsistency in the report but does not fix it.
- **Party-distribution query as primary signal:** Deferred indefinitely. Including it as an optional documented reference is acceptable; using it as the primary audit heuristic would encode partisan directional assumptions that conflict with five-chairs philosophy.

</deferred>

---

*Phase: 87-stance-accuracy-audit-agent-update*
*Context gathered: 2026-06-02*
