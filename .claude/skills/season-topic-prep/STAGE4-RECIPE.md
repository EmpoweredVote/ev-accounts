# Stage 4 recipe — revision package and apply

Stage 4 turns the winning draft into a Season revision: approved, parked (not published) and pinned into the draft
season, so it goes live when that season opens. It follows the recipe proven on `education-library-books` (CA_0310)
and `education-equity-programs` (CA_0314, EmpoweredVote/ev-accounts#1053). The SQL is
[templates/stage4-revision.sql](templates/stage4-revision.sql).

Nothing in steps 1–2 writes anything outside the research folder. Every later step that writes waits for its own
yes.

## Steps, in order

### 1. Read the topic facts (read-only)
Write them at the top of `stage4/revision.md`:
- topic id and key; the control revision id (the current published one), its revision number, version and
  change class; any other open (`draft` or `approved`) revision — there must be none;
- the open and draft season ids and what each pins for this topic;
- the number of questions in each season (`inform.season_questions`) — these go into the gate as `{{S2_COUNT}}`
  and `{{S3_COUNT}}`;
- seats on the topic in every season (`politician_answers`, `politician_context`, `stance_research_review`) and
  live voter answers by revision and value. The draft season must hold **no** politician answers on this topic.

### 2. Write the offline package (`stage4/`)
- `revision.md` — every field: change class (`substantive` when a seat or a voter answer moves position or the
  axis changes; `clarifying` only under the widening rule), title, short title, question, guidance, the five rungs
  beside the control's, the rung map with a reason per row, the rationale, the public note, the review ref.
- **Rung map** — keyed by the **old** rung (the control revision's), value = the new rung, or `"invalidated"` when
  no new rung holds that position. Work out what it does to each live voter answer
  (`inform.compass_answer_disposition`, CC_0061): `moved` and `invalidated` answers are hidden and re-asked when the
  season opens.
- **Rationale** — first line is the L1 poles, exactly `L1 poles: <pole 1> = "…"; <pole 5> = "…".` (stored
  internally, not shown to voters). Then: what each rung names; which rulebook rules the control failed; the rung
  map in words; the Stage 3 numbers (T1, T3, validation, T6); the rulings with dates; T5 (seats and voter answers
  that move); and this line: "Expert review is owed: N seated rows that rest on a bill or ordinance are queued
  (stage3/expert-queue.json); disputes ruled: M."
- **Public note** — plain words for voters: what the question now asks, why the old one did not work, and whether
  their answer will be asked again. No party names.
- **Review ref** — the research folder paths of `stage3/results.md`, `stage2/drafts.md` and `stage4/`.
- Season annex text for `docs/codebook/annex/season3/<topic_key>.md` (the topic's Season 2 annex stays as it is),
  and the row for the "Season 3 (draft)" table in `docs/codebook/annex/README.md`.
- A codebook line, if a ruling owes one (topic-scoped readings go in the codebook header and in RULINGS.md
  "Topic-scoped readings").
- RULINGS.md lines for any ruling that generalises.
- `README.md` — a file table, a summary of the change, "What the runner must approve" (numbered), and "Steps on
  approval". It becomes the progress log.
- The migration as a file only: copy the template to `stage4/<slot placeholder>_<suffix>.sql` and fill every
  `{{…}}`. Rung texts, title, question, guidance, rationale, public note and review ref sit inside dollar quotes, so
  apostrophes need no escaping. `grep -n '{{' <file>` must print only the comment line that mentions it.

🛑 **Yes #1: the package.** Ask for the text, the rung map, the rationale and public note, and the annex and codebook
lines, as one plain question each where there is a choice; recommend.

### 3. Reserve the slot (after yes #1)
`npm run steward --prefix backend -- slot <CA|CC> --purpose "<topic_key> Season 3 revision"` in your **own**
namespace. Name the file with that number straight away; replace `{{SLOT}}` everywhere (SQL, annex, README row).

### 4. Worktree and PR
In your own ev-accounts worktree, on a new branch from `origin/master`: add the migration, the Season 3 annex, the
annex README row, the codebook line if owed, the RULINGS.md lines, and the stage's source-store files
(`npm run source-store --prefix backend -- validate` first). Commit with an explicit pathspec. Open a **draft** PR.

### 5. Re-read the season counts
Read the question count of each season again. If another season migration ran since step 1, update `{{S2_COUNT}}`
and `{{S3_COUNT}}` in the file. A gate that expects a stale count fails on apply.

### 6. Dry run on production
Run the migration body **twice inside one transaction, then force a rollback with a RAISE**, in one session:

```sql
BEGIN;
-- body (everything between the file's BEGIN; and COMMIT;), first run: proposes, approves, pins, gate passes
-- body again, second run: must print "already present — skipping propose/approve" and pass the gate
DO $$ BEGIN RAISE EXCEPTION 'dry run: forced rollback'; END $$;
ROLLBACK;
```

The forced `RAISE` makes sure nothing commits even if the client would otherwise commit each statement. Then
confirm the rollback in a fresh read: the topic still has its old number of revisions, the draft season still pins
the control revision, and no open revision exists. Record in the file header and `README.md`: gate OK, idempotent
second run OK, the voter-answer dispositions the gate printed, rollback confirmed.

🛑 **Yes #2: apply on production.** A separate, explicit yes, after the dry run is reported.

### 7. Apply and record
Apply the file once. Read back the new revision id and write it into the file header ("APPLIED …"), the annex, the
README row, `stage4/README.md` and the PR. Push the update to the PR.

### 8. Merge and confirm the slot
🛑 **Yes #3: merge.** Mark the PR ready and merge on the runner's yes. Then
`npm run steward --prefix backend -- sync --apply` and confirm the slot's state is `written`. (`written` means the
file exists, not that it ran; the apply is recorded in step 7.)

### 9. Close the stage
- Re-measure: `npm run topic:seat-rate --prefix backend -- --topic <key> --season draft`.
- Follow-up owed by every Season 3 revision so far: point `build-coder-inputs.ts` at `annex/season3/` before coding
  the topic with `--season draft`.
- Monday step: stage `done`, the revision id, the expert-queue count.

## Known traps

- **`guidance` is not a parameter of `admin_propose_topic_revision`.** A trigger copies the previous revision's line
  onto the new row. Set it with `UPDATE inform.compass_topic_revisions SET guidance = … WHERE id = <new> AND status =
  'draft'` **before** approving. `guidance` is outside the immutable-content trigger, so this is allowed on a draft.
- **Season question counts in the gate must be re-read** before the dry run and before applying (step 5).
- **Approve, never publish.** Publishing would make the revision current in the open season. Opening the draft
  season publishes its pins.
- **No `--season draft` research on the topic before the apply.** Rows written earlier pin the control revision in
  the draft season, and the precondition refuses to re-pin.
- **An open revision blocks the propose.** Resolve any `draft` or `approved` revision on the topic first.
- **Material rewording of seated chairs** needs the seated-row count in the rationale and a re-audit of what carries
  forward (CLAUDE.md "Rewording a chair that already holds seated politicians").
