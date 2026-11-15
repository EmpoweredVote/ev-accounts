# The six duplicate statewide executive races

The record of what `CC_0435` removes, written down because a delete is final and the repo has no
history table. If the migration ever has to be undone, these are the rows.

## 🔴 The headline: these contests were never uncalled

Six races on the 2026-11-03 ballot carried `essentials.races.office_id IS NULL` and were reported
as the transition programme's last six `blocked` races — "6 with no office". Two readings of that
were wrong, one after the other.

**First wrong reading — "we hold no such office".** `blocked_no_office` is `races.office_id IS
NULL`, a fact about the race row. Every office exists and is seated.

⚠ **No state is missing a governor.** We hold **51** governor offices — the 50 states plus Puerto
Rico — and every one is seated. A count of offices titled exactly `Governor` returns **48** and
reads like two missing states: Indiana, Texas and Utah title theirs `<State> Governor`.

**Second wrong reading — "so link them to their offices".** The first draft of `CC_0435` did
exactly that, and the database refused it:
`races_election_office_party_uniq`, a unique index on
`(election_id, office_id, coalesce(primary_party,'~nonpartisan~')) WHERE office_id IS NOT NULL`.

🟢 **Each of the six offices already had a 2026-11-03 race — properly linked, more complete, and
already carrying a winner.** The six "unlinked" rows are duplicate stubs.

| office | canonical race | cands | winner recorded | duplicate (removed) | cands |
| --- | --- | ---: | --- | --- | ---: |
| Governor of Oregon | `4b90a29b` "Governor" | 3 | **Tina Kotek** | `8702f03a` "Governor of Oregon" | 2 |
| Governor of Maryland | `a0da88c6` "Governor" | 4 | **Wes Moore** | `8c67c58e` "Governor of Maryland" | 3 |
| Governor of Massachusetts | `550c8d9f` "Governor" | 3 | **Maura Healey** | `b8f82dc8` "Governor of Massachusetts" | 1 |
| Governor of Maine | `3b70abd2` "Governor" | 5 | **Hannah Pingree** | `deafeeb8` "Governor of Maine" | 3 |
| Attorney General of Maryland | `f355f3a6` "Attorney General" | 2 | **Anthony G. Brown** | `c08f3d4e` "Attorney General of Maryland" | 2 |
| Comptroller of Maryland | `674bc8be` "Comptroller" | 2 | **Brooke Lierman** | `e80f817e` "Comptroller of Maryland" | 2 |

▶ **A flag that names a column is not a description of the world.** The programme's last six
blocked races were an artefact of six stub rows, and nothing about those ballots was unknown.

## The 13 candidacies removed with them

All are strict subsets of their canonical race: **zero** people appear on a duplicate and not on
its canonical row, **zero** carry a `result`, **zero** carry a `photo_url`. Measured, not assumed.

| duplicate race | candidacies removed |
| --- | --- |
| Governor of Oregon | Christine Drazan, Tina Kotek |
| Governor of Maryland | Andy Ellis, Dan Cox, Wes Moore |
| Governor of Massachusetts | Maura Healey |
| Governor of Maine | Bobby Charles, Hannah Pingree, Rick Bennett |
| Attorney General of Maryland | Anthony Brown, James B. Rutledge III |
| Comptroller of Maryland | Brooke Lierman, Sonya Dunn |

The Massachusetts pair is the clearest: the duplicate held only Healey, while the canonical race
held all three and the result.

## 🔴 Why this is a merge and not a delete

`essentials.races` has **nine** inbound foreign keys and several CASCADE. Deleting these rows
outright would have silently destroyed:

| attached to the duplicates | rows | on delete |
| --- | ---: | --- |
| `readrank_questions` | **16** | CASCADE — **silently destroyed** |
| `readrank_race_pipeline` | 4 | SET NULL |
| `discovered_sources` | 3 | SET NULL |
| `candidate_staging` | 1 | no rule — would **error** |
| `race_candidates` | 13 | CASCADE (intended) |

Those 16 ReadRank questions are authored content from **2026-07-21** — 9 on Governor of Maine,
7 on Governor of Maryland.

🟢 **The subsystems were working against the duplicates the whole time.** Every canonical race
holds zero questions, zero pipeline rows, zero sources and zero staging — so the content exists
only on the rows being removed and the move cannot collide with anything.

▶ `CC_0435` therefore **moves everything first, then deletes**, and gates on **preservation**
rather than on the delete's own row count. A cascade that ate the questions would leave a delete
count looking perfect.

## Controls

Three tampers, each firing on its own gate:

| control | gate | what it plants |
| --- | --- | --- |
| A | no candidate is lost | puts Tina Kotek on the **Maryland** duplicate, where she is not on the canonical race |
| B | the questions arrived | removes the move, so the cascade eats all 16 |
| C | no result is lost | sets a result on a duplicate candidacy |

**B is the one that matters**: every other gate still passes under it — six rows still go, nobody
is lost, the winners survive, the blocked bucket still empties. Only a gate counting what
**survived** can see it.

⚠ A fourth gate was watched firing for real and is not tampered: the unique index that refused
the first draft's link. The database caught the wrong fix before any data moved.

⚠ Two of this file's own controls were invalid before they were right: `result = 'won'` is refused
by `race_candidates_result_needs_source` and then by `race_candidates_won_needs_certainty`. A
tamper that cannot be applied tests nothing.
