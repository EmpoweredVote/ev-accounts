# Stage 4 recipe — revision package and apply

Stage 4 turns the winning draft into a Season revision: approved, parked (not published) and pinned into the draft
season, so it goes live when that season opens. It follows the recipe proven on `education-library-books` (CA_0310)
and `education-equity-programs` (CA_0314, EmpoweredVote/ev-accounts#1053). The SQL is
[templates/stage4-revision.sql](templates/stage4-revision.sql).

Nothing in steps 1–2 writes anything outside the research folder. Every later step that writes waits for its own
yes. In dry mode (SKILL.md "Hard rules") the run stops at yes #1.

## Steps, in order

### 1. Read the topic facts (read-only)
Fill [templates/stage4-facts.sql](templates/stage4-facts.sql) (topic id and key) and run it with
`npm run db:ro --prefix backend -- --file <abs path> --json`. Write the facts at the top of `stage4/revision.md`:
- topic id and key; the control revision id (the current published one), its revision number, version and
  change class; any other open (`draft` or `approved`) revision — there must be none;
- the open and draft season ids and what each pins for this topic (`{{SEASON_OPEN_ID}}`, `{{SEASON_DRAFT_ID}}`);
  the open season's pin goes into the gate as `{{OPEN_PIN_ID}}`. It is usually the control, but not always (see
  "Known traps");
- the number of questions in each season (`inform.season_questions`) — these go into the gate as `{{S2_COUNT}}`
  and `{{S3_COUNT}}`;
- seats on the topic in every season (`politician_answers`, `politician_context`, `stance_research_review`). The
  draft season must hold **no** politician answers on this topic. If it does (Source-path draft rows written before
  a wording problem appeared), stop and ask the runner whether to withdraw those draft rows or defer the rewording
  to the next season;
- **live voter answers as ROWS** of `inform.compass_responses` (not deleted), by the revision they were **given
  on** and value. The gate counts rows, so `{{EXPECTED_DISPOSITIONS}}` is worked out from this query by applying the
  rung map by hand. (`inform.compass_answer_dispositions` keeps only each voter's latest answer, so it can show
  fewer; do not take the expected figure from it.) Report answers given on an older ladder than the control (a
  Season 1 axis carried forward by an identity map): the runner sees them when approving the rung map;
- the actor id `{{ACTOR_ID}}`: the runner's `auth.users` id (the query prints it for the email you give; Chris
  Andrews' is in the header of CA_0318);
- `{{FILE_SUFFIX}}`: `<topic_key with _>_s<N>_<draft letter>_revision`, as in
  `CA_0318_voting_rights_s3_draft_c_revision.sql`.

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
- RULINGS.md lines for any ruling that generalises, in `stage4/rulings-proposed.md`, each marked **ruled** (a filing
  of a ruling the runner already made, with its date) or **needs a ruling** (a new rule: ask it as its own question
  at yes #1).
- `README.md` — a file table, a summary of the change, "What the runner must approve" (numbered), and "Steps on
  approval". It becomes the progress log.
- The migration as a file only: copy the template to `stage4/<slot placeholder>_<suffix>.sql` and fill every
  `{{…}}` **except `{{SLOT}}`**, which waits for step 3. Rung texts, title, question, guidance, rationale, public
  note and review ref sit inside dollar quotes, so apostrophes need no escaping. `grep -n '{{' <filled file>` must
  print only `{{SLOT}}` lines now, and nothing after step 3 (the template's comments name no braces, so any other
  line it prints is an unfilled placeholder).
  The template finds the new revision by its number `{{REV_NUM}}` and its five rung texts, on any revision **other
  than** `{{REV_PREV_ID}}`, so a clarifying revision whose rungs are unchanged (only question, guidance or title
  change) still works: set `{{CHANGE_CLASS}}` to `clarifying` and `{{VERSION}}` to the control's version.

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
Run the migration body **twice inside one transaction, then force a rollback with a RAISE**, in one session.
Write the dry-run file below into the research folder (`stage4/dry-run.sql`) and run it with psql, reading
`DATABASE_URL` from your `backend/.env` without printing it:

```bash
set -a; . backend/.env; set +a      # in a worktree: the main checkout's backend/.env. Never echo it.
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f <absolute path>/stage4/dry-run.sql
```

`ON_ERROR_STOP=1` makes psql stop at the forced RAISE (the expected last error) or at the first real failure.

```sql
BEGIN;
-- body (everything between the file's BEGIN; and COMMIT;), first run: proposes, approves, pins, gate passes
-- body again, second run: must print "already present — skipping propose/approve" and pass the gate
DO $$ BEGIN RAISE EXCEPTION 'dry run: forced rollback'; END $$;
ROLLBACK;
```

The forced `RAISE` makes sure nothing commits even if the client would otherwise commit each statement. Check
that the output shows both gate passes and ends with `dry run: forced rollback`. Then confirm nothing persisted
with a read-only check in a new session (`psql "$DATABASE_URL" -X -c "SELECT …"`): the topic still has its old
number of revisions, the draft season still pins the control revision, and no open revision exists. Record in the file header and `README.md`: gate OK, idempotent
second run OK, the voter-answer dispositions the gate printed, rollback confirmed.

🛑 **Yes #2: apply on production.** A separate, explicit yes, after the dry run is reported.

### 7. Apply and record
Apply the file once. Read back the new revision id and write it into the file header ("APPLIED …"), the annex, the
README row, `stage4/README.md` and the PR. Push the update to the PR.

### 8. Merge and confirm the slot
🛑 **Yes #3: merge.** Mark the PR ready and merge on the runner's yes. Then
`npm run steward --prefix backend -- sync --apply` and confirm the slot's state is `written`. (`written` means the
file exists, not that it ran; the apply is recorded in step 7.)

### 9. Re-audit the carried seats
The rung map carries existing seats into the new revision. A **material** rewrite (CLAUDE.md "Rewording a chair
that already holds seated politicians") means each carried seat's evidence was gathered against a sentence that no
longer exists, so re-audit every one against the new wording, one row at a time:
- read its record against every clause of its new rung (codebook V4.2), and check it is still on a tracked office
  (a person with no current office does not carry);
- run `node backend/scripts/audit-chair-evidence.mjs --check <file>` on the rows; a fail there is either a row
  with no instrument named or a gap in the pattern (check the reasoning by reading before you call it a row fault);
- 🛑 ask the runner one question per seat that does not plainly carry (or one question for a group with the same
  reason), with a recommendation;
- write `stage4/reaudit/seats.md` (one section per seat, the ruling at the end) and `stage4/reaudit/carry.json`:
  `{topic_id, season_id, topic_revision_id, ruled_by, ruled_at, carry: [{politician_id, name, rung, records:
  [{instrument_id, record, vote, source}]}], do_not_carry: [{politician_id, name, reason}]}`. Season 3 research
  re-cites the carried seats from it.
A clarifying rewording keeps the seats with no re-audit; say so in `README.md`.

### 10. Close the stage
- The coder reads the Season 3 annex already (`coderAnnexPath` in `build-coder-inputs.ts`); check that the new
  `docs/codebook/annex/season3/<topic_key>.md` is the file it resolves for the topic.
- At apply, measure nothing: `topic:seat-rate --season draft` prints "no rows" until Season 3 research runs on the
  topic. What to check now is the draft pin (`topic:ladder-lint --season draft` prints the new rungs) and the rung
  map. **Re-measure the seat rate after the topic's Season 3 research** (`--season draft`, then `--research` with
  that run's rows), and compare it with the Stage 3 T1 figure and the Stage 0a rate.
- Monday step: stage `done`, the revision id, the expert-queue count, and the re-measure owed.

## Known traps

- **`guidance` is not a parameter of `admin_propose_topic_revision`.** A trigger copies the previous revision's line
  onto the new row. Set it with `UPDATE inform.compass_topic_revisions SET guidance = … WHERE id = <new> AND status =
  'draft'` **before** approving. `guidance` is outside the immutable-content trigger, so this is allowed on a draft.
- **The open season may not pin the control.** When a clarifying revision was published after the open season
  locked its pins, the season keeps its older pin and is served the newer text by version. Then
  `{{OPEN_PIN_ID}}` ≠ `{{REV_PREV_ID}}`; fill `{{OPEN_PIN_ID}}` from the facts query's `pin` row, never by copying the
  control. Found on gun-policy (CA_0338, 2026-10-30: Season 2 pins revision 2, the control is revision 3); on that
  date 13 topics were in this state.
- **Season question counts in the gate must be re-read** before the dry run and before applying (step 5).
- **Approve, never publish.** Publishing would make the revision current in the open season. Opening the draft
  season publishes its pins.
- **No `--season draft` research on the topic before the apply.** Rows written earlier pin the control revision in
  the draft season, and the precondition refuses to re-pin.
- **An open revision blocks the propose.** Resolve any `draft` or `approved` revision on the topic first.
- **Material rewording of seated chairs** needs the seated-row count in the rationale and a re-audit of what carries
  forward (step 9; CLAUDE.md "Rewording a chair that already holds seated politicians").
