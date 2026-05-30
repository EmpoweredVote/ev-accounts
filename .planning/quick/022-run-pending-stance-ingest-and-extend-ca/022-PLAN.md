---
plan: "022"
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/scripts/apply-malik-stances.ts
  - backend/src/lib/compassService.ts
autonomous: true

must_haves:
  truths:
    - "apply-malik-stances.ts stores raw CSV values without inverting them"
    - "All 24 ingest scripts run and upsert rows into inform.politician_answers"
    - "getCandidates() returns candidates with politician_answers stances when no empowered_profile exists"
    - "getCandidateAnswers() falls back to politician_answers when no empowered_profile compass_responses exist"
    - "backend TypeScript compiles clean after changes"
  artifacts:
    - path: "backend/scripts/apply-malik-stances.ts"
      provides: "Corrected malik ingest — no value inversion"
      contains: "parseInt(r.value)"
    - path: "backend/src/lib/compassService.ts"
      provides: "Dual-path getCandidates + getCandidateAnswers"
      exports: ["getCandidates", "getCandidateAnswers"]
  key_links:
    - from: "getCandidates SQL WHERE clause"
      to: "inform.politician_answers"
      via: "EXISTS subquery on politician_answers"
      pattern: "politician_answers pa"
    - from: "getCandidateAnswers"
      to: "inform.politician_answers"
      via: "Path B fallback after empowered_profiles miss"
      pattern: "politician_answers"
---

<objective>
Fix a value-inversion bug in the Malik ingest script, run all 24 pending stance ingest scripts
against production, then extend getCandidates() and getCandidateAnswers() in compassService.ts
to fall back to inform.politician_answers when a candidate has no empowered_profile.

Purpose: Unlock compass comparisons for the ~24 researched candidates whose stances are stored
in politician_answers, not in compass_responses via empowered_profiles.

Output: Corrected Malik stances in DB, politician_answers populated for all 24 candidates,
compassService dual-path logic shipping clean TypeScript.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix value-inversion bug in apply-malik-stances.ts and commit</name>
  <files>backend/scripts/apply-malik-stances.ts</files>
  <action>
    On line 17, change:
      [r.politician_id, r.topic_id, 3 - parseInt(r.value)]
    to:
      [r.politician_id, r.topic_id, parseInt(r.value)]

    Every other ingest script stores raw CSV values. The subtraction was erroneous.
    After editing, commit with message: "fix(data): remove value inversion in apply-malik-stances"
  </action>
  <verify>
    Confirm line 17 reads `parseInt(r.value)` with no arithmetic.
    Run: cd C:/EV-Accounts/backend && git diff HEAD scripts/apply-malik-stances.ts
  </verify>
  <done>Line 17 stores parseInt(r.value) directly. Commit exists on master.</done>
</task>

<task type="auto">
  <name>Task 2: Run all 24 pending ingest scripts against production DB</name>
  <files>(no file modifications — scripts write to DB)</files>
  <action>
    From C:/EV-Accounts/backend/, run each script with `npx tsx`. Continue on error; log all stdout.
    Scripts must run in this order (sequential):

    npx tsx scripts/apply-calanche-stances.ts
    npx tsx scripts/apply-carlisle-stances.ts
    npx tsx scripts/apply-cd1-challengers-stances.ts
    npx tsx scripts/apply-celona-stances.ts
    npx tsx scripts/apply-feldstein-soto-stances.ts
    npx tsx scripts/apply-gaspar-stances.ts
    npx tsx scripts/apply-girvan-stances.ts
    npx tsx scripts/apply-hahn-stances.ts
    npx tsx scripts/apply-hernandez-rosas-stances.ts
    npx tsx scripts/apply-horvath-stances.ts
    npx tsx scripts/apply-kendall-stances.ts
    npx tsx scripts/apply-malik-stances.ts
    npx tsx scripts/apply-mantel-stances.ts
    npx tsx scripts/apply-mazariegos-stances.ts
    npx tsx scripts/apply-mejia-stances.ts
    npx tsx scripts/apply-nuno-stances.ts
    npx tsx scripts/apply-oyler-stances.ts
    npx tsx scripts/apply-prang-stances.ts
    npx tsx scripts/apply-rivers-stances.ts
    npx tsx scripts/apply-roldan-stances.ts
    npx tsx scripts/apply-sanchez-stances.ts
    npx tsx scripts/apply-sarian-stances.ts
    npx tsx scripts/apply-solis-stances.ts
    npx tsx scripts/apply-ugarte-stances.ts

    Collect all "Done — Upserted: X, Skipped: Y" lines. Sum total rows upserted.
    After all scripts complete, commit with message:
    "feat(data): run 24 stance ingest scripts — {TOTAL} rows upserted"
    (substitute actual total for {TOTAL})

    DATABASE_URL is in backend/.env — dotenv/config loads it automatically.
  </action>
  <verify>
    All 24 scripts exit without throwing an unhandled exception.
    Total upserted rows > 0.
    Run spot check: psql $DATABASE_URL -c "SELECT COUNT(*) FROM inform.politician_answers;"
    (or equivalent pool.query in a one-liner tsx snippet)
  </verify>
  <done>
    24 scripts ran. Total upserted rows logged. Commit exists recording the total.
    At least one row exists in inform.politician_answers for each script's politician.
  </done>
</task>

<task type="auto">
  <name>Task 3: Extend getCandidates() and getCandidateAnswers() with politician_answers fallback</name>
  <files>backend/src/lib/compassService.ts</files>
  <action>
    **getCandidates() — replace SQL and map return**

    Replace the entire SQL string inside pool.query() (lines 330–367) with:

    ```sql
    SELECT
      rc.id,
      rc.first_name,
      rc.last_name,
      NULL::text AS preferred_name,
      rc.full_name,
      rc.photo_url AS photo_origin_url,
      NULL::text AS photo_custom_url,
      r.position_name AS office_title,
      COALESCE(o.representing_state, e.state::text, '') AS representing_state,
      COALESCE(o.representing_city, '') AS representing_city,
      COALESCE(d.label, '') AS district_label,
      COALESCE(d.district_type, '') AS district_type,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN (
          SELECT COUNT(*)::int FROM inform.compass_responses cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          SELECT COUNT(*)::int FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      END AS answer_count,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN (
          SELECT array_agg(cr.topic_id) FROM inform.compass_responses cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          SELECT array_agg(pa.topic_id) FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      END AS answered_topic_ids,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN 'empowered'
        ELSE 'researched'
      END AS stance_source,
      true AS is_candidate,
      rc.is_incumbent
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.offices o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE rc.candidate_status = 'active'
      AND e.election_date >= CURRENT_DATE
      AND rc.politician_id IS NOT NULL
      AND (
        EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep
          JOIN inform.compass_responses cr ON cr.user_id = ep.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        OR EXISTS (
          SELECT 1 FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      )
    ```

    In rows.map(), add `stance_source` after `is_incumbent`:
      `stance_source: (r.stance_source ?? 'researched') as 'empowered' | 'researched',`

    Update the JSDoc comment to reflect the dual-path (empowered_profiles OR politician_answers).

    ---

    **getCandidateAnswers() — replace Step 2 + Step 3**

    Keep Step 1 unchanged (lines 400–405, resolve politician_id from race_candidates).

    Replace everything after Step 1 (currently: Step 2 resolves user_id, Step 3 fetches
    compass_responses, then returns answersRes.rows) with:

    ```typescript
      // Step 2: try Path A — empowered_profiles → compass_responses
      const profileRes = await pool.query<{ user_id: string }>(
        `SELECT user_id FROM empower.empowered_profiles WHERE politician_id = $1`,
        [politicianId]
      );
      if (profileRes.rows.length > 0) {
        const userId = profileRes.rows[0].user_id;
        const answersRes = await pool.query<{ topic_id: string; value: number }>(
          `SELECT topic_id, value
           FROM inform.compass_responses
           WHERE user_id = $1 AND deleted_at IS NULL AND value != 0
           ORDER BY topic_id ASC`,
          [userId]
        );
        if (answersRes.rows.length > 0) return answersRes.rows;
      }

      // Step 3: fall back to Path B — politician_answers (researched stances)
      const researchedRes = await pool.query<{ topic_id: string; value: number }>(
        `SELECT topic_id, value
         FROM inform.politician_answers
         WHERE politician_id = $1 AND value != 0
         ORDER BY topic_id ASC`,
        [politicianId]
      );
      if (researchedRes.rows.length > 0) return researchedRes.rows;

      return null;
    ```

    Update the JSDoc comment: "Three-step lookup" → "Dual-path lookup: tries
    empowered_profiles → compass_responses (Path A), falls back to politician_answers (Path B)."

    ---

    After edits, verify TypeScript compiles:
      cd C:/EV-Accounts/backend && npx tsc --noEmit

    Fix any type errors (e.g. if the caller of getCandidates() destructures the return type
    and doesn't expect stance_source, widen or add the field to the return type annotation).

    Commit: "feat(compass): extend getCandidates + getCandidateAnswers with politician_answers fallback"
  </action>
  <verify>
    cd C:/EV-Accounts/backend && npx tsc --noEmit
    Must exit 0 with no errors.
  </verify>
  <done>
    getCandidates() SQL includes dual-path CASE for answer_count, answered_topic_ids, stance_source,
    and OR EXISTS in WHERE. getCandidateAnswers() falls back to politician_answers.
    tsc --noEmit exits 0. Commit exists on master.
  </done>
</task>

</tasks>

<verification>
1. git log --oneline -3 shows three new commits: malik fix, ingest run, compassService extension
2. cd C:/EV-Accounts/backend && npx tsc --noEmit exits 0
3. apply-malik-stances.ts line 17 reads `parseInt(r.value)` with no arithmetic
4. compassService.ts getCandidates() SQL contains "politician_answers" and "stance_source"
5. compassService.ts getCandidateAnswers() contains "Path B" fallback block
</verification>

<success_criteria>
- Malik ingest no longer inverts stance values
- inform.politician_answers populated for all 24 candidates with total upserted rows recorded in commit
- getCandidates() returns researched candidates (politician_answers path) alongside empowered candidates
- getCandidateAnswers() returns researched stances when no empowered_profile exists
- TypeScript compiles clean
</success_criteria>

<output>
After completion, create `.planning/quick/022-run-pending-stance-ingest-and-extend-ca/022-SUMMARY.md`
</output>
