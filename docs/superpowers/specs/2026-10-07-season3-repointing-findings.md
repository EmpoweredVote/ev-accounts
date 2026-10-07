# Season 3 re-pointing: can a moving rung_map open?

Date: 2026-10-07. Operator: Chris Andrews (namespace `CA_`). Investigation only. No migration written.
Prod project `kxsdzaojfaibhuzmclfq`, read-only, plus one rolled-back dry run (section 4).

## Answer in five lines

1. **Yes, a moving rung_map can publish at open.** The guard accepts it once every earlier-season answer on the topic has a row in Season 3.
2. **Nothing reusable exists.** CC_0058 is a one-off migration, hard-coded to Housing and Same-Sex Marriage. Season 3 needs a generic function.
3. **The guard is stricter than "carry Season 2".** It demands an S3 row for every earlier answer in Season 1 *and* Season 2. On prod, 29,585 Season 1 answers have no Season 2 row. A moving topic must give each of those people a row (a mapped value or a blank).
4. **Voter answers are already handled.** CC_0061/CC_0062 suppress a moved or invalidated voter answer and prompt a re-ask. No build needed there.
5. **The one-open index is acceptable, with one trap.** An approved S3 revision blocks S2 clarifying fixes on that topic. Re-pointing it later is hard once S3 answers exist (section 6).

## 1. What the guard checks now (prod, read 2026-10-07)

The live `inform.admin_publish_topic_revision(uuid, uuid)` is byte-for-byte the CC_0060 body. In order:

1. Revision must exist and be `approved` (`NOT_FOUND`, `NOT_APPROVED`).
2. If `rung_map` is non-null and any key maps to a different value (a move, a merge, or `invalidated`):
   - no `season_questions` row pins this revision: **`REPOINTING_NOT_IMPLEMENTED`**;
   - else count earlier-season answers (`s_old.number < s_target.number`) on the topic with no `politician_answers` row for the same politician, topic and **pinning** season: if above zero, **`REPOINTING_INCOMPLETE`**.
3. A current revision must exist (`NO_CURRENT_REVISION`).
4. `version` must be current or current + 1 (`STALE_VERSION`).
5. Flip `is_current` and `status`.

An identity map (or null map) skips step 2 entirely.

`admin_open_season` (CA_0024) publishes every pin of the draft season whose revision is still `approved`, in a loop, before the changeover. It has no extra rung_map check of its own. One refusal aborts the whole open.

**Verdict:** an approved S3 revision with a moving map publishes at open if, and only if, the S3 answer rows exist first. With none, the open aborts with `REPOINTING_INCOMPLETE`.

What the guard does *not* check:

- That the S3 value equals the mapped value. A row of any value, including a wrong one, satisfies it.
- `politician_context`. A carried answer can reach S3 with no reasoning row, and the guard stays silent.
- `compass_responses` (deliberate, CC_0060).

## 2. Was CC_0058 reusable?

**One-off.** CC_0058 is plain `INSERT ... SELECT` SQL with `topic_key IN ('housing','same-sex-marriage')`, a hard-coded expected rung table, and the season hard-wired as "number = 2". `grep` over `pg_proc` finds no re-point function. The only rung_map code in `inform` is the proposer, `is_valid_rung_map`, the publish guard, and `compass_answer_disposition`.

What the S3 version must do, using CC_0058 as the template:

- **Source rows.** The latest earlier answer per politician (S2 over S1), not S2 alone. With S2 alone the guard still refuses (dry run, step 5).
- **Mapped, blank, or empty.**
  - *Mapped:* write the S3 row at `rung_map[value]`.
  - *Blank:* write `value = 0` for `invalidated`, and for any person you decide not to carry. The guard counts a blank as a row. This is the honest choice where no rung fits.
  - *Empty:* **not allowed** for a moving topic. The guard refuses it. Empty is only valid for identity-map topics.
- **Pin first.** `politician_answers_pin_fkey` and `politician_context_pin_fkey` reference `season_questions(season_id, topic_id, topic_revision_id)`. So order is: propose, approve, pin to S3, then write S3 rows carrying the pinned revision id taken from `season_questions`, never from the caller.
- **A draft season accepts the writes** (dry run, step 4; same as CC_0058 into draft S2).
- **Context rows:** carry reasoning for mapped answers, none for blanks (CC_0058 rule), `editor_id` NULL on answers.
- **Chained maps.** A `rung_map` maps from the revision that was `is_current` when it was proposed. S3 pins equal `is_current` on all 60 carried topics, but **13 topics' S2 pin differs from the S3 pin**, and every S1 answer sits on the S1 ladder. For those people one map is the wrong map. See open decision A.
- **Write-ins and non-integers:** prod has none today (0 write-ins, 0 non-integer values). Keep CC_0058's refusal if that changes.

## 3. Voter `compass_responses`

- `compass_responses_assign_season` fills `season_id` with the **open** season on insert. While S3 is a draft, voter writes still land in S2. After the open, they land in S3.
- Primary key is `(user_id, topic_id, season_id)`. The scaffold unique index on `(user_id, topic_id)` is gone (checked on prod), so a voter can hold an S2 row and an S3 row.
- `compass_responses_stamp_revision` stamps the answered revision from the season's pinned version. So an S2 answer is stamped with the S2-pinned version.
- After the open, `compass_responses_effective` runs `compass_answer_disposition` against the new pinned version. A version gap with a moved or invalidated rung gives `moved` or `invalidated`, and the answer is withheld from display and scoring and a re-ask is prompted (`routes/compass.ts`, CC_0062). A reword gives `reworded`: kept and prompted.
- Dry run, step 8, homelessness-response with map `2->3, 3->4, 4->5`: S1 voter rows gave 2 `moved` and 1 `reworded`; the S2 voter row gave `moved`. The voter's S3 re-answer then wins the newest-season collapse.
- No voter row needs re-pointing. This stays Chris Andrews' CC_0058 ruling: a voter's answer is their own statement.

## 4. Dry run on prod (rolled back)

One session, `BEGIN ... ROLLBACK`, topic `homelessness-response` (440 S1 answers, 3 S2, 4 voter rows). The actor was a real user id, only because `approved_by`/`approved_at` have a paired CHECK. Throwaway revision, `rung_map {1:1, 2:3, 3:4, 4:5, 5:5}`, one rung text altered so the ladder changed.

| Step | Result |
|---|---|
| propose, approve | OK |
| second open revision on the same topic | refused: `duplicate key ... compass_topic_revisions_one_open` |
| pin to draft S3 (`admin_season_pin_revision`) | OK, approved revision accepted |
| publish, no S3 rows | **`REPOINTING_INCOMPLETE`, 443 answer(s)** |
| write 3 S3 rows from S2, publish | **`REPOINTING_INCOMPLETE`, 440 answer(s)** |
| write 440 more from S1-only answers, publish | **published** (v3, supersedes v2) |

**Rollback verified.** Row counts and md5 hashes for answers, context, revisions, stances, seasons, pins and responses were captured before and after in separate sessions: identical. I did not call `admin_open_season` (it would flip season statuses); its publish loop calls the same function tested here.

Note: the guard counts earlier **rows**, not people. A politician with an S1 row and an S2 row counts twice in the message. The pass/fail result is unaffected.

## 5. Build needed (if you approve)

1. **`inform.repoint_season_answers(p_season_id, p_topic_id)`** (required for any moving S3 topic). Generic, idempotent, draft-season only. Reads the pinned revision's `rung_map`, writes mapped/blank answer rows and mapped context rows, refuses write-ins, asserts per-rung counts and that S1 and S2 are untouched. Slot: `steward slot CA`.
2. **Guard hardening in `admin_publish_topic_revision`** (recommended, small). Also require that each S3 row's value equals `rung_map[source value]` (or 0), and that each non-blank row has a context row. This closes the gap in section 1. Needs the same dry-run proof CC_0060 used.
3. **Friendlier one-open error** (optional). Today it is a raw `duplicate key` error. Wrap it as `OPEN_REVISION_EXISTS: topic X has revision N in <status>`.

No voter-side build. No change to `admin_open_season`.

## 6. The one-open-revision index

An approved (or draft) S3 revision on topic T blocks any other proposal on T, so **S2 clarifying fixes on T cannot be proposed** until the S3 revision publishes at the flip. Verified in the dry run.

**Acceptable, with these rules:**

- Propose and approve moving S3 revisions **late**, topic by topic, shortly before the open. A topic with no pending S3 revision keeps its S2 fix path.
- Do any known S2 clarifying fix **before** proposing the S3 revision.
- 🔴 **Trap: do not re-pin after S3 answers are written.** Both pin FKs have no cascade. Once S3 rows carry revision X, rejecting X and re-proposing Y cannot re-pin without deleting and rewriting those rows. So the escape hatch (reject, publish the fix, re-propose, as CC_0031 did) is cheap *before* the re-point and expensive *after*. Run the re-point as the last step before the open, and re-run it if the revision changes (hence idempotent, item 1).

No schema change is needed for the index.

## 7. Decisions for the operator

- **A. S1-only people on a moving topic.** The guard forces a row for each. Options: (i) carry them mapped, which needs a chained map for the 13 topics where S2 and S3 pins differ and is wrong for S1 answers on a ladder the map was not written against; (ii) write a blank (value 0). Blanking hides a position that S2 currently shows through the newest-season fallback. Which one is the editorial intent?
- **B.** Approve build items 1 and 2?

## Reproduction

Scripts used (not committed; scratchpad): a before/after snapshot of seven tables, and the dry-run script described in section 4. Prod access: session pooler `DATABASE_URL`, with `SET default_transaction_read_only = on` inside each session. The pooler ignores `PGOPTIONS`, so that environment variable does **not** make the session read-only.

## Appendix: per-topic counts (prod, read-only, 2026-10-07)

One row per topic pinned in draft Season 3 (61 topics: 60 carried plus surveillance-technology).

- **s2 rows**: people with a Season 2 answer (includes blanks).
- **s2 blank**: Season 2 rows with value 0.
- **s1-only**: people with a Season 1 answer and no Season 2 row. The guard forces an S3 row for each if the topic moves.
- **s2 pin = current**: yes means one map step is correct for Season 2 rows. NO means chained maps (13 topics).
- **s1 pin vs current**: differs means Season 1 answers sit on an older ladder than the current one.
- **voters**: voter answer rows on the topic, all seasons.

| topic | s2 rows | s2 blank | s1-only | s2 pin = current | s1 pin vs current | voters |
|---|---:|---:|---:|---|---|---:|
| taxes | 81 | 39 | 1940 | NO | differs | 4 |
| abortion | 61 | 27 | 1850 | NO | differs | 8 |
| climate-change | 60 | 54 | 1842 | yes | differs | 8 |
| healthcare | 54 | 34 | 1741 | NO | differs | 3 |
| civil-rights | 41 | 32 | 1536 | yes | differs | 8 |
| voting-rights | 46 | 46 | 1475 | yes | differs | 6 |
| deportation | 39 | 22 | 1319 | yes | differs | 6 |
| fossil-fuels | 24 | 16 | 1319 | NO | differs | 6 |
| school-vouchers | 15 | 14 | 1216 | yes | differs | 4 |
| trans-athletes | 7 | 5 | 854 | NO | differs | 7 |
| campaign-finance | 7 | 5 | 834 | yes | differs | 4 |
| public-safety-approach | 66 | 23 | 801 | NO | differs | 3 |
| childcare | 36 | 15 | 761 | yes | differs | 6 |
| religious-freedom | 5 | 3 | 683 | yes | differs | 8 |
| redistricting | 12 | 10 | 674 | yes | same | 4 |
| economic-development | 51 | 27 | 668 | yes | differs | 4 |
| tariffs | 6 | 4 | 657 | NO | differs | 8 |
| homelessness | 5 | 1 | 637 | yes | differs | 7 |
| ai-regulation | 7 | 7 | 597 | yes | differs | 3 |
| social-security | 9 | 7 | 589 | yes | differs | 8 |
| local-immigration | 15 | 4 | 555 | NO | differs | 5 |
| ukraine-support | 7 | 6 | 460 | NO | differs | 7 |
| homelessness-response | 3 | 0 | 440 | yes | differs | 4 |
| transportation-priorities | 133 | 16 | 428 | NO | differs | 3 |
| growth-and-development | 10 | 1 | 428 | yes | differs | 4 |
| misinformation | 5 | 5 | 364 | yes | differs | 4 |
| residential-zoning | 92 | 84 | 355 | NO | differs | 5 |
| local-environment | 14 | 12 | 345 | yes | differs | 3 |
| jail-capacity | 16 | 7 | 291 | NO | differs | 3 |
| judicial-criminal-justice | 7 | 4 | 283 | yes | differs | 3 |
| data-centers | 4 | 2 | 280 | yes | differs | 6 |
| rent-regulation | 18 | 1 | 228 | yes | differs | 4 |
| city-sanitation | 1 | 0 | 113 | yes | differs | 3 |
| judicial-interpretation | 0 | 0 | 71 | yes | differs | 3 |
| judicial-access-to-justice | 0 | 0 | 48 | yes | differs | 3 |
| judicial-transparency | 0 | 0 | 34 | yes | differs | 3 |
| judicial-government-deference | 0 | 0 | 22 | yes | differs | 3 |
| judicial-prosecution-priorities | 0 | 0 | 20 | yes | same | 2 |
| judicial-police-accountability | 0 | 0 | 12 | yes | differs | 3 |
| judicial-bail-pretrial | 0 | 0 | 6 | yes | differs | 3 |
| housing | 1821 | 39 | 0 | yes | differs | 6 |
| same-sex-marriage | 901 | 35 | 0 | yes | differs | 8 |
| cannabis-policy | 116 | 0 | 0 | yes | - | 1 |
| gun-policy | 97 | 0 | 0 | NO | - | 1 |
| ranked-choice-voting | 75 | 0 | 0 | yes | - | 1 |
| israel-military-aid | 47 | 0 | 0 | yes | - | 1 |
| border-security | 12 | 0 | 0 | yes | - | 3 |
| minimum-wage | 2 | 0 | 0 | yes | - | 1 |
| 2020-election | 0 | 0 | 0 | yes | - | 1 |
| education-ai | 0 | 0 | 0 | yes | - | 1 |
| education-charter-authorization | 0 | 0 | 0 | yes | - | 1 |
| education-school-police | 0 | 0 | 0 | yes | - | 1 |
| education-library-books | 0 | 0 | 0 | yes | - | 1 |
| education-gender-identity | 0 | 0 | 0 | yes | - | 1 |
| education-equity-programs | 0 | 0 | 0 | yes | - | 2 |
| defense-spending | 0 | 0 | 0 | yes | - | 1 |
| education-curriculum | 0 | 0 | 0 | yes | - | 1 |
| education-school-budget | 0 | 0 | 0 | yes | - | 1 |
| military-intervention | 0 | 0 | 0 | yes | - | 1 |
| surveillance-technology | 0 | 0 | 0 | new | - | 0 |
| **total** | 4028 | 607 | 26776 | | | 223 |

The appendix total of s1-only (27,907) is lower than the prod-wide 29,585 in section 1. The difference is Season 1 answers on topics Season 3 does not carry.
