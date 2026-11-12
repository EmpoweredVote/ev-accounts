# ev-accounts — working notes

Conventions that are not obvious from the code and that are expensive to get wrong. Keep this short;
if something needs a page, put it in `docs/` or an ADR and link it here.

## How to report

Report in plain English. Readers are smart non-developers.

- Lead with the answer or result. Then give only the detail needed to act on it.
- Short sentences, one idea per sentence, active voice. No idioms, metaphors, or filler.
- Use a plain word instead of a technical term when one exists. When you must use
  a technical term, define it in a few words the first time.
- Make each reply as long as the question needs, and no longer. Do not repeat
  what you already said.

This controls chat replies only. It does not control the style of the files you write —
docs, code comments, commit messages, and page copy follow this repo's own conventions.

## Officeholder occupancy — read `backend/migrations/CLAUDE.md` before seeding anyone

`essentials.offices` is a SEAT and holds no occupant; occupancy is a dated row in `essentials.office_terms`, read
through `essentials.office_current_holder` (ADR 0002). The full rules — reading in both join directions, the
three-part drift measurement and its 238 baseline, seating and vacating helpers, sourcing a seat, the `is_vacant`
trap — moved to [`backend/migrations/CLAUDE.md`](backend/migrations/CLAUDE.md) (loaded automatically under
`backend/migrations/` and `backend/src/`). 🔴 Read it before any query or migration that touches offices, terms,
vacancies or politicians. Its hardest traps, in one line each:

- An office with **no `office_terms` row is invisible**, and nothing errors.
- A politician-rooted join on the view fans out one row **per seat held**; it needs `DISTINCT ON (p.id)`.
- `count(*)` on the view counts vacancies too: **count `och.politician_id`**.
- `seat_officeholder` does **not** clear `is_vacant`; clear it in the same migration.
- Set `politicians.is_incumbent` explicitly on every insert. **Never raise the drift baseline.**

## Migrations — read `backend/migrations/CLAUDE.md` first

The full rules moved to [`backend/migrations/CLAUDE.md`](backend/migrations/CLAUDE.md). The ones that bite first:

- 🟢 **Ask the allocator for the number; never count:** `npm run steward --prefix backend -- slot CC|CA|shared --purpose "..."`.
  CI fails a migration whose slot its author did not reserve.
- 🔴 **Decide the author before the number.** Two people here are called Chris: Cantrell → `CC_`, Andrews → `CA_`.
- 🔴 **The dry-run and apply tools already exist** (`backend/scripts/dry-run-migration.mjs`, `apply-migration-file.mjs`).
  **One migration per file — never concatenate.**
- 🔴 **A migration that overwrites a value records the old value in its own header.**
- 🔴 **Never create a table or view in `public`**; grant, enable RLS and add policies in the same file.

## Working alongside other sessions

Several sessions and machines write into this repo at once, and two of the four ways they
collide cannot be fixed by any convention — those are the steward's job (migration slots, and
jurisdiction claims). The other two need a shared working directory to happen, so they are
rules. All four are described in
[`docs/superpowers/specs/2026-09-04-steward-coordination-design.md`](docs/superpowers/specs/2026-09-04-steward-coordination-design.md); these are the two you must follow.

🔴 **THERE IS A FIFTH, AND IT IS THE ONE THE OTHER FOUR CANNOT SEE: TWO BRANCHES EDITING THE SAME
FILE.** The steward's scopes describe the **world** — which place, which migration number. This
one is in the **repo**. Measured 2026-09-26: Knight slices 11 (MI) and 12 (ND) held *disjoint*
jurisdiction claims, took *distinct* slot ranges, and worked in *separate* worktrees — every
mechanism did its job — and both edited `backend/scripts/load-state-tiger-boundaries.ts`, because
every state's geography load does. PR #797 sat **64 commits behind master with 2 conflicting
files for two days** and nothing said so.
- ⚠ **A JURISDICTION CLAIM CANNOT KNOW WHICH FILES THAT JURISDICTION TOUCHES.** Claiming
  `state:nd` says nothing about the generic loader, or `PROGRAM.md`, which every slice appends to.
  Expect to conflict in those two; they are the hot files.
- 🟢 **`steward who` NOW REPORTS BRANCH DRIFT** for every worktree in the checkout, at session
  start: how far behind the base each branch is, and **which files already conflict**. It is
  read-only (`git merge-tree`, computed in memory — it never touches another session's worktree),
  it never fetches, and **it prints even when the steward's database is down**, because it is git
  alone. It stays silent when nothing is wrong.
- ▶ **A CONFLICTING BRANCH DOES NOT GET BETTER BY WAITING.** Merge the base into it early, and do
  it **in that branch's own worktree** — never by moving HEAD in a worktree you did not create.
- 🔴🔴 **A DUPLICATED REGISTRATION IS NOT A TEXT CONFLICT, SO NEITHER THE MERGE NOR THE DRIFT
  REPORT CAN SEE IT.** Two branches that add the same `vi.mock`, import, route or handler **in
  different places** merge cleanly, and the later copy silently wins. Measured 2026-11-10: merging
  master into `feat/fc-seasons-api` left master's `roleService` mock followed by this branch's
  older copy of the same mock, so `getCachedUserRoles` returned `[]` for every caller and **five
  curation tests answered 403 instead of 200** — in a file git had auto-merged without a murmur.
  ▶ **RUN THE TESTS AFTER A MERGE GIT CALLED CLEAN.** And read `steward who`'s conflict list as a
  floor: it names the files that collide as *text*, never the ones that collide as *meaning*.


**Jurisdiction claims** (`steward claim place:… | county:… | state:…`, leases, `--if-held`) are described in
[`backend/migrations/CLAUDE.md`](backend/migrations/CLAUDE.md) § "Jurisdiction claims". Take the lease before working
a jurisdiction; `steward who` runs on session start and shows every claim.

- 🔴 **ONE SESSION OWNS A WORKTREE.** If you are going to commit, work in your own:
  `git worktree add -b <branch> /c/ev-accounts-<topic> origin/master`. It costs seconds. On
  2026-09-04 it was the entire reason two concurrent sessions never touched.
  - **Never `checkout` or `switch` in a worktree you did not create.** Moving HEAD under a
    running session is the failure — `C:\EV-Accounts` changed branch three times under one
    session that day, and again the same evening. If you need another branch, make another
    worktree.
  - 🟢 **THE BOARD NOW WATCHES THIS RULE.** The SessionStart hook runs `steward worktree`,
    which records the directory and branch and then tells you what moved:
    **`🔴 HEAD MOVED in <path> — it was on X …, and is now on Y`**, or **`⚠ another session was
    last seen in <path> at T`**. Read those two lines before you touch anything.
    - ⚠ **A WORKTREE ROW IS A MARKER, NOT A LEASE.** Nothing releases it when a terminal
      closes, so it means *a session started here at T* — never *a session is running here*.
      That is why `who` lists it under `~` and prints **seen**, not "expires". Registering
      takes the marker over unconditionally; the displaced session is reported, not protected.
      This is the opposite of a jurisdiction claim, because the fact is different.
- 🔴 **COMMIT WITH AN EXPLICIT PATHSPEC**: `git commit -F msg -- <path>`. Staging carefully is
  not enough, because it is the *other* session's `git add -A` that sweeps your files in.
  - 🟢 **A PRE-COMMIT HOOK NOW WATCHES THIS.** Install it once per clone:
    `npm run install:hooks --prefix backend` (sets `core.hooksPath` to `.githooks`).
    It grades the warning, because rule 3 only matters when rule 1 is broken: a note when you
    are alone, and **`🔴 COMMITTED WITHOUT A PATHSPEC IN A SHARED WORKTREE`**, naming the other
    session, when someone else has been in this checkout in the last 12 hours.
  - ⚠ **IT NEVER BLOCKS A COMMIT**, on any path, including a dead database or its own crash.
    A hook that can wedge a commit gets deleted, and then the rule has no observer at all.
    A hook cannot be pushed to anyone — it is opt-in per clone, so a colleague who has not run
    the installer is unobserved.
  - ⚠ **Until 2026-09-23 it never ran on macOS or Linux**: it was committed without its exec bit,
    and git there skips such a hook with only a `hint:` line (Git for Windows ignores the bit). CI
    step "git hooks are executable" now fails on any `.githooks/` file that is not mode 100755.
    🔴 **Linked worktrees run the MAIN checkout's copy**: their `config.worktree` sets an absolute
    `core.hooksPath` to `<main clone>/.githooks`, so the hook runs only once the main checkout's
    branch carries the 100755 file. Check with `git rev-parse --git-path hooks`.
  - ⚠ **Both steward hooks (this one and SessionStart) used to skip SILENTLY without
    `backend/node_modules`** — 10 of 17 worktrees on 2026-09-23, so most sessions got no board, no
    worktree marker and no pathspec check. They now run through
    `backend/scripts/lib/main-checkout-fallback.mjs`, which borrows the main checkout's
    `node_modules` and `.env`, and print one "skipped" line when neither checkout has them.
- 🔴🔴 **BEFORE ANY `git worktree remove`, SCAN FOR A `node_modules` JUNCTION — REMOVAL DELETES
  STRAIGHT THROUGH IT.** A junction planted to save a reinstall is followed by the delete, and it
  has **emptied the main checkout's `node_modules` twice**. ⚠ **`check:deletable` is silent on
  this** — it is not one of the four checks. Look with PowerShell (`Get-ChildItem -Directory` and
  read `LinkType`), and `rmdir` a junction you made yourself as a control before trusting the scan.
  ▶ **Do not plant junctions**; run tooling from the main checkout with an absolute `--dir`.
- **Before deleting a worktree or branch**, run the four checks — as **one command**:

  ```bash
  npm run check:deletable --prefix backend -- /c/ev-accounts-<topic>
  #   exit 0 = safe, and it prints the exact removal commands
  #   exit 1 = do not delete, with every blocker named
  ```

  It checks: fully merged into `origin/master`; merged content byte-identical **for the paths
  this branch touched** (a whole-repo diff would report everyone else's merges); stash count
  unchanged (pass `STASH_BASELINE=<n>`; stashes are shared and usually someone else's); and
  nothing untracked that exists **nowhere else**.
  - ⚠ **"Untracked count is zero" can never be true here** — every worktree carries
    `node_modules` and a `.env` copy. The check asks what the rule *means*: `node_modules` is
    regenerable, and a `.env` is a copy **only once it has been byte-compared**. An unverified
    `.env` counts as unique, because it could hold a credential that exists nowhere else.
  - 🔴 **It plants its own positive control** — writes a file, confirms its scan sees it,
    removes it — and **refuses to give a verdict if the scan came back blind**. That is not
    ceremony: on its first run the scan was blind, because `git status --ignored` returns
    ~1.4 MB here and overflowed `execFileSync`'s 1 MB default with `ENOBUFS`, which the error
    handler swallowed into an empty result. Without the control it would have said
    **"0 untracked, SAFE TO DELETE"** for a worktree full of files.
  - 🔴 **Run a positive control on any detector that reports "nothing found."** Two detectors were
    silently broken on 2026-09-04 and only a control exposed them: a file-mtime scan whose
    threshold predated the checkout, and a `curl` sweep where the host had begun 403-ing every
    request, turning "this file does not exist" into "you are being blocked". The general form of
    this rule, and the part about watching the control FAIL first, is in **Verification rules**
    below.

## Verification rules that each cost a real failure

Every rule here is in the file because skipping it broke something. They are about *checking* —
they belong to no one subsystem, so they sit on their own rather than inside the section where
each was first learned.

- 🔴🔴 **A UNIFORM ANSWER IS A BROKEN DETECTOR UNTIL A POSITIVE CONTROL PASSES — AND THE CONTROL
  MUST BE WATCHED FAILING FIRST.** A control that has only ever passed proves nothing: it can pass
  for the wrong reason, an earlier gate can shadow the one you meant to test, and a tamper that
  cannot trip the comparison tests nothing at all. Plant the fault, see the detector go red, then
  remove it and see it go green.
  - ⚠ **A control proves a verifier CAN fail. It does not prove the verifier reads the RIGHT
    ROWS** — for that, check the count it actually examined.
  - 🔴 **A TAMPER THAT DID NOT APPLY IS A CONTROL THAT PROVED NOTHING, AND IT LOOKS LIKE A PASS.**
    On 2026-10-26 a `sed` that built a tamper file failed on a quoting error, left a **0-byte**
    file, and `dry-run-migration.mjs` reported **`DRY RUN OK`** on it — an empty migration passes
    every gate it does not contain. **Assert the tamper is PRESENT in the file before running it**
    (grep for a marker, or build it in a script that exits non-zero when the replacement misses).
  - 🔴 **A CONTROL CAN FAIL CORRECTLY, FOR THE WRONG PROPERTY, AND STILL MISS THE DEFECT.**
    `ev-jobs-legiscan` died of heap exhaustion; the fix shipped a real control proving a repeat
    read re-parses — that nothing is **retained** — and the job died again, because the defect was
    **allocation on the first read** (26,707 entries inflated back to back to read one integer).
    Removing retention is not removing allocation. **Ask what the defect's MECHANISM is and pin
    that**, not the nearest property that is easy to assert.
  - Change one thing per tamper. A tamper that trips three assertions at once tells you the suite
    is alive but not which guard holds which claim.
- 🔴🔴 **A GATE NO CONTROL REACHES IS A GATE NOBODY HAS TESTED, AND TWO GATES CATCHING ONE FAULT
  IS WHAT HIDES IT.** Gates run in order, so a tamper stopped by an earlier one says nothing about
  a later one — and the earlier gate firing looks like success. `CC_0376` planted three label-swap
  tampers before one reached its point-to-member chain gate: the first was stopped by an
  incumbent-consistency check, the second by a gate the first tamper had just bought. Only a
  tamper that leaves every other table correct and self-consistent tests the last gate in a chain.
  ▶ **Track which gate each control fires on, not just that it went red.** A gate with no control
  of its own is untested however many controls the file has.
- 🔴🔴 **A UNION OR COVERAGE GATE CANNOT SEE WHICH VERSION OF A MAP IT HAS, AND ITS NUMBER WILL NOT
  EVEN WOBBLE.** Two complete partitions of the same area have *identical* unions by construction,
  so every coverage, overlap and bounding-box measure agrees to the last decimal. Measured: New
  Hampshire's superseded 2012 councilor map covers the TIGER state outline to **99.6836%, the same
  figure as the 2022 map to four decimal places**, and differs from it on 66 of 259 towns.
  ▶ Only evidence about **which district a NAMED PLACE belongs to** separates two vintages. Where
  a statute names places (New Hampshire names all 259), that is the strongest anchor available —
  stronger than a county composition, and it leaves no district unpinned.
- 🔴🔴 **A FLAT CONTROL TESTS NOTHING, AND A CONTROL DERIVED FROM THE DATA UNDER TEST MOVES WITH
  THE DEFECT.** A blank grey frame proves a detector can return "nothing"; it proves nothing about
  what the detector does with real input. Worse, a threshold or baseline computed *from the same
  rows you are checking* shifts when they shift, so the check silently follows the fault instead of
  catching it. **Derive the control independently of the data under test.**
- 🔴🔴 **A CONTROL SET THAT IS UNIFORM IN A PROPERTY THE DETECTOR DEPENDS ON CANNOT TEST THAT
  PROPERTY — AND IT PASSES WHILE A WHOLE CLASS OF INPUT WALKS THROUGH.** This is the companion to
  "a uniform ANSWER is a broken detector", with the uniformity sitting in the *controls* instead of
  the output. `check-portrait-framing.mjs` had two fixtures, a **green** matte and a **white**
  matte, and a centre test that asked "is the middle the same colour as the surround". Neither
  colour can occur in a human subject, so no fixture had ever exercised a **dark** surround — and a
  pure-black border passed the gate, because dark hair, a dark jacket and shadow are near-black in
  every portrait, so **the subject itself voted the frame innocent**. Both controls were green
  throughout. ▶ **List what your fixtures hold constant, and add one that varies it.** A second
  fixture of the same kind is coverage of nothing.
  - 🔴 **TWO DETECTORS CAN BE COMPLEMENTARY RATHER THAN REDUNDANT, AND GEOMETRY DECIDES WHICH.**
    The same gate could not see a rectangular frame *structurally*: a disc of full width touches
    the left and right edges at their midpoints, so **no side of a disc image is flat along its
    whole length**. A per-side test sees a letterbox and a corner-and-diagonal test sees a disc,
    and neither can be made to see the other by moving a threshold. **Ask whether the shape you
    missed is reachable by the measurement you have before you retune it.**
  - 🔴 **A PREDICATE OF SEVERAL `&&` CONDITIONS FAILS FOR EXACTLY ONE REASON, AND NOTHING PRINTS
    IT.** That gate reported only its flagged rows, so a passing row produced **no numbers at all**
    and the verdict was readable while the evidence for it was not. ▶ **Print every row a detector
    scanned, not only its hits** — otherwise "why did this pass?" costs a re-implementation.
- 🔴🔴 **A COUNT OF EVENTS THROWS AWAY THE MEASUREMENT OF THE EVENTS, AND THE MEASUREMENT IS
  USUALLY THE ANSWER.** `check-portrait-framing.mjs` walked the four corner diagonals of an image
  and asked **how many** of them left the matte. A circular crop answers four. A person cut out on
  plain white answers four as well — so over the 9,481 published headshots the gate flagged 44 and
  **33 of them were real photographs**. The number it already had and discarded was **how far
  along each diagonal** the surround ended: a disc is round, so all four are the same, while a
  person ends at their hair on the top two and their shoulders on the bottom two. The three
  positive fixtures read 0, 1 and 3; every real manufactured surround in the corpus read 0–2; the
  nearest real photograph read 8. One term, 44 flags down to 12. ▶ **When a detector counts
  occurrences, ask what it measured to find them and whether that number discriminates.**
  - ⚠ **A TUNING PASS NEEDS THE WHOLE CORPUS, NOT THE SET THAT PROMPTED IT.** The repair before
    this one was measured over 36 images and reported **zero false positives**; the first 500
    random published headshots produced one, and all 9,481 produced 33. The 36 were the batch
    being worked on, so they were uniform in exactly the thing that was wrong. **Nothing about a
    detector's error rate is known until it has been run over the population it will police.**
  - 🔴 **TWO GATES OVER ONE CORPUS ARE NOT REDUNDANT WHEN THEY ASK DIFFERENT QUESTIONS, AND THE
    SECOND ONE'S FINDINGS ARE INVISIBLE TO THE FIRST.** Every one of the 11 real framing defects
    had **passed** `check-headshot-faces.py` — two of them are the **State Seal of Washington** and
    the **Great Seal of North Carolina**, which contain a portrait, so a face detector clears them
    honestly and correctly. "We already check the headshots" is not an answer to "do we check
    *this*".
  - 🔴 **A FLAGGING GATE NEEDS ITS BACKLOG WRITTEN DOWN AS DEFECTS, NOT AS ACCEPTANCES.**
    `data/headshot-framing-known.json` keys on **(url, sha256)** like `headshot-accepted-flags.json`
    — the hash is the load-bearing half, because our storage overwrites a file **in place** at the
    same URL — and every entry must declare which of two opposite things it is: a **defect** that
    is still published and still owed a re-source, or an **accepted** row the gate reads wrong,
    with the reason. Both suppress the red; only one is a queue. **A defect filed as an acceptance
    is a defect nobody will ever fix.**
- ⚠ **A UNIFORM PROBE RESULT CAN BE A PROPERTY OF YOUR SAMPLE, NOT OF THE DATA.** Before concluding
  "they are all like this", check that the sample was not itself selected by the thing you are
  measuring.
- ⚠ **A PERCENTAGE COLUMN MAY BE COUNTING BLANKS IN ITS DENOMINATOR** — a reported 47.5% was really
  58.2%. Ask what the denominator contains before quoting a rate.
- 🔴 **A MASTER-ONLY GATE CANNOT VET THE MERGE THAT TRIPS IT.** It reads production data and runs
  after the merge, so it fails on *the next* PR and names an innocent author. Carry the check into
  the migration's own post-verify, as a delta, if you need it to block the guilty change.
  - 🔴🔴 **AND APPLYING A MIGRATION BEFORE ITS READ-PATH CODE MERGES HOLDS THAT GATE RED FOR
    EVERYONE, FOR AS LONG AS THE BRANCH STAYS OPEN.** The gate reads **production data with
    MASTER's code**, and those two are different things that can disagree for days.
    `CC_0366`-`CC_0372` created Colorado's and Louisiana's board districts in production while
    the `X-ST-BOARD` line that makes them readable sat unmerged in `districtQueries.ts` and
    `geoIdGuard.ts`. `check:reachability` reported **`UNREACHABLE` 20 against a baseline of 7**
    — new buckets `co|STATE_BOARD` 8 and `la|STATE_BOARD` 5 — and failed **four consecutive
    master runs**, every one of them somebody else's merge. Merging the PR took it straight back
    to 7 with no baseline change: the gate was right the whole time and the branch was late.
    🔴 **So do not raise the baseline to clear this red** — see § Officeholder occupancy in `backend/migrations/CLAUDE.md`, *never
    raise it at all*. ▶ **A districted body on a new `X…` layer is not safe to apply to
    production until its registration is on master.** Land the migration and those two code
    lines together, or merge the same day you apply.
- 🔴🔴 **A TRUNCATED DISPLAY MANUFACTURES FINDINGS, AND IT BIASES THEM TOWARDS LOOKING LIKE
  DUPLICATES.** Cutting a column to fit makes distinct values collapse onto one another, and that
  collision is exactly the shape of a real defect, so the artefact reads as a discovery. On
  2026-11-02 a report column formatted a district label with `.slice(0, 24)` — and
  `"Congressional District "` is exactly 23 characters — so every two-digit district printed as
  its first digit alone. Two different candidates appeared to share one implausible district,
  which was reported as a race-mapping bug and was retracted: both were mapped correctly.
  ▶ **Print the field at FULL WIDTH before believing a pattern in it, or read the stable key
  beside it.** `ocd_id` carried the right answer throughout and was never displayed.
  - 🔴 **A NORMALISATION STEP MANUFACTURES THE SAME SHAPE, AND IT LOOKS LIKE TWO SOURCES
    DISAGREEING.** `CC_0377` cross-checked LA County's JSON against the same county's
    server-rendered page and three candidates came back "absent from the text page" — a
    disagreement about who was on the ballot. The pages write accents as numeric entities
    (`LA CA&#xD1;ADA`, `ERIK PE&#xD1;A`) and the parser did not decode them. ▶ **Before
    reporting a mismatch between two readings, ask what your own pipeline does to the field —
    and give the comparison a positive control that names a row it must be able to see.**
- 🔴🔴 **BOUND A PARSE BY THE DOCUMENT'S OWN STRUCTURE, NEVER BY A BLACKLIST OF WHAT ELSE MIGHT
  BE IN IT.** A section reader that stops at a list of headings you thought of cannot see the
  heading you did not, and everything after it is read as part of the section before — with a
  plausible value, not an error. Nebraska's 2024 canvass book prints "Judge of the District
  Court", "District 3", "Lancaster" a few pages past the Board of Regents, so a blacklist that
  had not thought of judges would have recorded Lancaster County as part of **Regents District
  3**. Take each section's page range and stop-title from the book's **own table of contents**
  instead (`backend/data/state-exec-2026-results/parse-ne-canvass-counties.mjs`).
  ▶ It applies to any delimiter you supply from outside the document: ask what the document
  itself says its parts are.
- 🔴🔴 **A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS.** Before naming or acting
  on the class some `WHERE` clause catches, `GROUP BY` the discriminating field and read a sample
  of real rows. **Deleting raises that bar, it does not lower it.** ⚠ A lookalike key can be a
  clean permutation of a real one, so "this looks malformed" is a hypothesis, not a finding.
- 🔴🔴 **GREEN CI IS NOT "THE SERVER BOOTS".** Four deploys have gone out green and failed to
  start. Boot the built artifact against a **dead** `DATABASE_URL` and watch it come up; and note
  that `npm install` passing is not `npm ci` passing — the lockfile is what the deploy resolves.
- 🔴🔴 **PUT THE DIAGNOSTIC WHERE THE PROCESS CAN STILL REACH IT.** A summary printed after the
  loop teaches a crash nothing. Log the size before, and progress from inside. For memory,
  `heapUsed`, `external` and `rss` are three different answers — print all three, because the one
  that grows tells you which thing is leaking.
  ⚠ **A green run can be a no-op.** Read what it says it did, not just its exit code.
- 🔴🔴 **`WebFetch` FABRICATES NAMES AND DATES AND FORMATS THEM AS QUOTATIONS.** It once invented
  four officeholder names and three district labels and presented them as quoted text from the
  page. Use it to LOCATE a document; never source a **name, a date or a count** from it. A web
  search summary is a lead, not evidence — open the page and read it.
- 🔴 **A CLEAN HTTP 200 LIES IN AT LEAST FIVE WAYS**, and each one reads as success: an ACS or API
  host returning an **HTML error page**; **TIGERweb layer 0** answering for a layer that holds
  nothing; a **parked domain**; a **truncated body** — check `Content-Length` against what you
  received; and a **soft 404**, a "not found" page served as 200. Assert on the *content* you
  expected, never on the status code alone.
- 🔴 **A WAF REJECTION CAN BE HTTP 200 OR 202, so never judge a fetch by `r.ok`.** F5 WAFs on
  government hosts reject Node's `fetch` on its TLS fingerprint and answer 200 with a challenge
  body; `curl` and Python `requests` get through. A 403 that persists even with a browser
  `User-Agent` means **fetch it in Playwright**. Wikimedia 429s a generic UA. ⚠ The inverse
  happens too, and a challenge may cover **pages** while leaving **files** open.
- ⚠ **READ THE BODY OF A 503 BEFORE CALLING A HOST DEAD.** Government sites commonly answer 503
  with "site is being rebuilt" or a maintenance notice — a temporary state with a successor URL in
  it, not an outage to retry forever.
- ⚠ **A PUBLISHER'S OWN HUB CAN SERVE A SUPERSEDED MAP**, with the same district count over the
  same area and different answers per address. A plausible count is not evidence of the right
  vintage — check which map legally governs.
- 🔴 **ONE DENIED COMMAND IS NOT A BLOCKED PATH.** Try a different shape before reporting a
  capability as unavailable — and **never print a secret's value** while doing it. ⚠ An
  unexplained break from the normal workflow usually means "I am doing this wrong", not "the
  environment changed".
- ⚠ **A WORKAROUND SIZED IN UNITS OF A BUG OUTLIVES THE BUG FIX.** When a constant is chosen to
  dodge a defect, write down what it is dodging, or it becomes permanent and nobody can say why
  it is that number. 🔴 Render instance of the same thing: **`NODE_OPTIONS` applies to the BUILD**,
  so a heap flag meant for a job belongs on that job's START command.
- **Image sourcing is measured, not eyeballed.** A no-monochrome rule that is not enforced in code
  is not enforced — unenforced it cost 156 frames. **A badge is portrait-shaped: look at the image
  before accepting it as a headshot.** **A bare CDN URL is not the original** — both the resize and
  the quality loss can be hiding in the query string.

## Repo facts worth knowing — in `backend/src/CLAUDE.md`

Moved to [`backend/src/CLAUDE.md`](backend/src/CLAUDE.md): antipartisan party storage, FIPS vs USPS in
`geofence_boundaries.state`, `(mtfcc, geo_id)` as the real key, the landing-chip vs address-search split, Supabase
Storage headers and hostnames, the `ev_api` role, `districts.geo_id` and `district_type` as routing keys, shared
custom layers, multi-member statewide bodies, and non-residency seats (ADR 0003). 🔴 Read it before writing a query
or a seed that touches districts, geofences, storage or credentials.

## Compass chairs are five distinct stances, not a polarity rating

**To seat a politician in a chair you need evidence describing THAT chair, with sources.** The five
options are five distinct stances along a spectrum; the chair is a voter-facing claim about what
this person holds, not a rating of how strongly they lean.

- Evidence that establishes only the **direction** (pro/anti) under-determines *which* of the two or
  three chairs on that side applies. Seating anyway is an unevidenced claim — the same defect class
  as a composed citation, expressed as a number.
- A bill citation proves direction. It does **not** automatically prove magnitude: "supports
  progressive taxation to fund public services" cannot distinguish *significantly raise taxes on the
  wealthy* (1) from *moderately raise* (2).
- ⚠ **"The least extreme option the reasoning supports" is a TIEBREAKER, not evidence.** Reaching
  for it is the signal that the row is not yet evidenced.
- The honest alternative to a guessed chair is a **blank spoke**. A blank spoke is correct.
- **Never assume polarity.** Read each ladder from `inform.compass_stances`. The corpus convention is
  chair 1 = maximum government action, but **AI Oversight and Tariffs run the other way**, and
  Residential Zoning, Growth and Development Pace and Government Deference are off-axis entirely
  (the deregulatory and the progressive position sit at the same end). See
  [`.planning/todos/2026-08-12-ladder-orientation-and-consumers.md`](.planning/todos/2026-08-12-ladder-orientation-and-consumers.md).
- A re-sourcing pass that cites **sponsorship** must refuse any row at the anti pole — the new
  citation would contradict the displayed position.

**Gate:** `node backend/scripts/audit-chair-evidence.mjs --check <rollback.json>` fails if any row it lists
carries reasoning that names no instrument, act or vote. Run it before committing any migration that
sets a chair.

### Pre-staging research into a DRAFT season (`--season`)

Every stance-research step takes `--season open|draft|<uuid>` (default `open`, unchanged): bundle
(`build-stance-topic-bundle.ts`), `code-stance-batch.ts`, `queue-coded-batch.ts`,
`verify-stance-research.ts`, `export-written-ledger.ts`, and `gold-desk/build_batch.py`. Pass the SAME
value to each step: a non-open bundle writes `<dir>/season.json`, and a step run against another
season exits 2. A **closed** season is always refused.
- The draft ladder is the draft season's pin, served as ADR 0006 will serve it once it opens — so an
  `approved`, not-yet-published revision counts (`servedRevisionLateral(..., {includeApprovedWhen})`).
  The open season's served text still means published/superseded only.
- Writes carry the draft season's id (`UPSERT_*_IN_SEASON_SQL`, evidence via `accumulateEvidence(..., {seasonId})`).
  A review-queue row whose `season_id` is a draft season approves into THAT season (`resolveResearchReview`).
- 🔴 **Voters must not see it.** Every reader of `politician_answers` / `politician_context` /
  `politician_context_evidence` excludes draft (`SEASON_IS_PUBLISHED`) or declares `@draft-reads: ADMIN-ONLY`;
  `draftSeasonWrites.test.ts` scans for a new unguarded one. A draft run does not stamp
  `last_stances_researched_at`.

### A blank is `value = 0`, and `-- @zero-scope:` records who counts it

When a ladder changes so that no rung states what a politician holds, the answer is **blanked**
rather than guessed or deleted: the row stays, carrying `value = 0`. Season 1 keeps the old rung as
history; the new season shows a blank spoke. (Ruling 2026-09-02: *"If there is nowhere for them to
go, they can be blanked. We will remember the difference between seasons 1 and 2."*)

So **every read of `politician_answers.value` has to decide what a 0 means to it**, and the two
right answers point opposite ways:

- **Anything that displays or averages a position must exclude it.** A 0 is not rung 0. Left in, it
  scores as maximum disagreement in `compareWithPoliticians`, opens a bar no ladder text can label
  in the stats distribution, and makes `has_stance` true with nothing to name.
- **Anything asking whether research HAPPENED must keep it.** Blanking says the ladder moved out
  from under a position, not that the reading was undone — the coverage rollups would otherwise
  report a loss no editor caused.

A site that keeps blanks says so in the query, in the same shape as `-- @season-scope:`:

```sql
-- @zero-scope: counts-blanks — coverage is "ever researched", and the research happened.
```

**⚠ Unlike `@season-scope`, this marker is NOT enforced by a gate.** It is documentation, and
`grep -rn "@zero-scope" backend/src` is how you find every site that has been judged. A read with no
marker has not necessarily been thought about — check it before trusting it.

**Guard placement is the part that goes wrong.** Put the filter OUTSIDE the newest-season collapse,
never inside it. Inside, a blank in the newest season is skipped and the query silently falls back
to an older season's rung — serving a position the politician no longer holds, against a ladder it
was never an answer to. That is the same failure the season collapse exists to prevent, one layer
down, and it is what the tests in `compassService.test.ts` pin.

### Rewording a chair that already holds seated politicians (ruling 2026-08-28, Chris Andrews)

- A **clarifying** rewording — same position, clearer words — keeps existing seats. Nothing re-audits.
- A **material** rewrite — a double-barrel split, a narrowed or widened claim — means the seats' evidence
  was gathered against a sentence that no longer exists. Those rows need a **re-audit against the new
  wording** (`audit-chair-evidence.mjs` is the tool), not a silent text update. State the seated-row
  count in the proposal's rationale so the reviewer prices the re-audit before approving.
- Seasons carry the mechanics: a season's pin never moves once open, so Season 1 rows keep asserting
  exactly the wording they were evidenced against. The re-audit question is about what carries forward
  into the NEXT season's research, not about rewriting history.

### Scope decides the evidence, not whether a position exists (ruling 2026-10-06, Chris Andrews, option B)

This replaces the 2026-08-28 ruling "Scope is a per-rung question, not a per-topic one", which said a
chair evidenced only by opinion at a level is "the exact shape the evidence standard refuses". The
operator's reason: *"I would want to know whether my local mayor thinks the 2020 election was stolen or
her position on abortion, even if she can't change the laws on that."* Memo:
`.planning/todos/2026-10-06-positions-without-a-lever.md` (workspace root).

- **Which topics a level is ASKED** — every topic, at federal, state and local, unless there is a good
  reason not to. Named exclusions: judges keep the judicial topics only and judicial topics stay
  judge-only; **school boards keep the school topics only** (the 2026-09-24 rung-by-rung school ruling
  stands, for now); local-only topics ("your community") are not asked of federal or state officials
  until their question text reads at every level. Recorded in `compass_topic_roles` (CA_0302).
- **What evidence can seat a chair** — still a per-rung question. **A record needs a lever**: a rung no
  officeholder at this level can act on cannot be evidenced at this level by a record. **The person's
  own words can** (codebook V2 "No-lever level"). `compass_topic_roles.evidence_basis` marks a
  (topic, level) `own-words` when no rung has a lever there.
- **Before adding a topic or a level**, still read every rung and ask whether an officeholder there
  holds a lever on it. The answer now sets the evidence basis, not whether the level is asked.
- **Voters see no label** — they see the sources (the evidence chain). An own-words chair is compared
  with the voter's view like any other chair.
- 🔴 **An own-words chair is a separate reliability stratum.** A certification measured on `record` rows
  never covers it; own-words rows go to review until that stratum has its own blind gold. **Passed for
  `voting-rights`** (Season 3, 2026-10-31: blind check run 4, 35 of 35 against a pre-set 34; `.claude/skills/
  season-topic-prep/RULINGS.md` "Own-words seats: the hold ends after a blind check"), and for **`gun-policy`**
  (Season 3, 2026-11-04: blind check run 1, 24 of 24 against a pre-set 23), so their own-words seats are approved
  like any other row. Every other topic keeps the hold until its own blind check passes.
- The election-cycle rule for statements (codebook V5, Q4) applies unchanged.
- **What a voter sees is decided by the lenses, not by `compass_topic_roles`.** The essentials compass
  draws its spokes from the active lens's curated topic list (or the voter's own compass), and with no
  lens the stance breakdown lists every topic the official answered. `applies_*` only narrows the pool
  under the Local Lens, and drives tier badges, coverage counts and the stance-research gate.
- ⚠ **Legacy out-of-scope chairs exist and are already visible** in that breakdown (Season 1 research at
  levels that were not asked, e.g. local `taxes`, `deportation`, `same-sex-marriage`). They are owed a
  re-audit under the codebook; adding a role row does not change whether they show.

## Render settings live in ev-infra

This repo's Render services (`ev-accounts-api`, `ev-accounts` (admin), `empowered-vote-app` and the seven `ev-jobs-*` cron jobs) are managed by the Render Blueprint in
[`EmpoweredVote/ev-infra`](https://github.com/EmpoweredVote/ev-infra) (`render.yaml`).

- Build and start commands, rewrites, headers, custom domains, plans, cron
  schedules and build filters change **only through a PR to ev-infra**. Render
  syncs its `main` branch automatically.
- A setting changed in the Render dashboard is **undone on the next sync**.
- Env var **values** are the exception: set them in the Render dashboard. Add a
  new variable's name to ev-infra (with `sync: false`) so the record stays complete.
- Do not add a `render.yaml` to this repo. Render does not read it.
