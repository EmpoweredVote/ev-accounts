# Design — branch protection for `master`

**Status:** Proposal, awaiting a decision (2026-09-20).
**Decision owner:** Chris. Applying this changes repo settings, not code.
**Measured:** 2026-09-20, against the GitHub API and `origin/master`'s `.github/workflows/ci.yml`.
**Prompted by:** PR #552 merging with `mergeStateStatus: CLEAN` and no review, which contradicted
the working assumption that `master` needs an approving review. It does not.

---

## 1. What is actually true today

`master` **is** protected, but only against destruction. Nothing gates content.

| Rule | `ev-accounts` `master` | `civic-spaces` `main` |
|---|---|---|
| `required_pull_request_reviews` | **key absent — none required** | 1 approval, `require_last_push_approval: true` |
| `required_status_checks` | **key absent — none required** | `build`, `strict: true` |
| `enforce_admins` | **true** | false |
| `allow_force_pushes` | false | false |
| `allow_deletions` | false | false |
| `required_linear_history` / `required_signatures` / `required_conversation_resolution` / `lock_branch` | false | false |

Repo-level rulesets: **`[]`**, empty. So the two content keys are absent outright — not present and
set to zero. **Anyone with write access can merge any PR immediately, with CI red or never run.**
Six accounts hold admin: `EmpoweredChris`, `chrisandrewsedu`, `MrPeterTorres`, `DoyleJ11`, `meroon`,
`EV-Jack` (`krishnapatel0196` is read-only here).

🔴 **`enforce_admins: true` reads as the strict setting and is doing almost nothing.** It subjects
admins to the rules that exist, and the rules that matter do not exist. `civic-spaces` is the exact
inverse: real gates, admins exempt.

---

## 2. Three findings that make the obvious fix wrong

The obvious fix is "copy `civic-spaces`: require the build and one review." Both halves break here,
for different reasons, and both failures are silent until someone is stuck.

### 2a. 🔴 CI does not run on docs-only PRs, so a required check would block them forever

`ci.yml` carries `paths-ignore: ['**/*.md', '.planning/**']` on **both** `pull_request` and `push`.
That is deliberate and well argued in the file's own header comment — 18 of 90 push/PR runs in an
8-day window changed nothing but markdown, and no check in the file reads a `.md`.

But a **required** status check that never reports does not pass. GitHub waits for it, and the PR
sits on *"Expected — Waiting for status to be reported"* permanently. There is no timeout.

**PR #552 was docs-only.** Under a naive required-checks configuration it could never have merged.
Nor could any `.planning/**` PR, which is a large share of this repo's traffic.

`civic-spaces` avoids this by accident of shape, not by design: its `build-check.yml` has **no path
filter**, so `build` always reports.

### 2b. 🔴 A required review would deadlock the repo, because nobody reviews and admins cannot bypass

GitHub refuses self-approval — confirmed on #552: `Review Can not approve your own pull request`.

Across the **last 60 merged PRs there are zero reviews by anyone.** Not few: none. Combined with
`enforce_admins: true`, requiring one approval means whoever opens a PR can never merge it, and no
habit exists of anyone else doing so. The repo stops.

`civic-spaces` survives the same rule only because of two escape hatches this repo lacks:
`enforce_admins: false` (an admin can merge unreviewed), and `docs-auto-approve.yml` (which supplies
the approval for docs-only PRs).

### 2c. So the `civic-spaces` config is coherent as a *pair*, and neither half ports alone

| Property `civic-spaces` relies on | Present in `ev-accounts`? |
|---|---|
| Required check always reports (no path filter) | ❌ — `paths-ignore` skips docs PRs |
| Docs PRs get an automatic approval | ❌ — no auto-approve workflow |
| Admin can bypass when needed | ❌ — `enforce_admins: true` |

---

## 3. Which checks are even eligible

Job names are the status-check context names. Of the 13 jobs in `ci.yml`, only **four** run on
`pull_request`:

| Context | Guard | Requirable? |
|---|---|---|
| `backend lint · typecheck · test` | `github.event_name != 'schedule'` | ✅ |
| `static guards` | `pull_request \|\| push` | ✅ |
| `migration reservations` | `pull_request \|\| push` | ✅ |
| `answer-season consumers` | *(no `if:` — runs on everything)* | ✅ |

🔴 **The other nine must NEVER be required** — they are `schedule` / `workflow_dispatch` only, or
explicitly `!= 'pull_request'`, so requiring one blocks every PR forever, exactly as in §2a:
`address-search reachability`, `child→county mapping`, `stance sourcing`, `read & rank question
unit`, `season corpus floor`, `spatial_ref_sys baseline`, `stance-read audit guard`,
`state-leg OCD-ID suffixes`.

`migration reservations` is the highest-value of the four — it is what enforces the allocated-slot
rule that is otherwise pure convention.

---

## 4. Recommendation

**Require status checks. Do not require reviews yet.**

Requiring checks captures nearly all the value: it stops a merge with a failing lint, typecheck,
test, static guard, or unreserved migration slot. Requiring reviews today buys a deadlock in
exchange for a rule nobody performs — and a rule satisfied by rubber-stamping is worse than an
honest absence, because it reads as assurance.

Revisit reviews when a second person is actually reviewing. That is a staffing change, not a
settings change, and papering over it with `enforce_admins: false` would make the rule decorative
from the first day.

### Step 1 — make one context report on every PR

The four jobs cannot be required while `paths-ignore` can suppress them. Two ways out:

**Option A (recommended) — one always-running gate.** Drop `paths-ignore` from the `pull_request`
trigger only, add a cheap first job that decides whether non-docs paths changed, and have the four
real jobs `needs:` it and skip when they should. One extra job-minute on a docs PR instead of four,
one context that always reports exactly once, and the header comment's cost argument survives
roughly intact.

**Option B (lower effort, with a real caveat) — a passthrough workflow.** A second workflow with the
inverse `paths:` filter and a job of the same name that exits 0. ⚠ `paths:` fires when **any**
changed file matches, so a PR touching one `.ts` and one `.md` triggers *both* workflows, both
reporting the same context — and a green passthrough can mask a red real run. Take this only if
mixed PRs are rare, and know that masking is the failure mode you are accepting.

Under either option, add a single aggregate context (say `ci ok`) that `needs:` the four jobs and
fails unless all four succeeded. Requiring one name rather than four keeps the protection config
stable when a job is renamed or split.

⚠ In that gate's expression, hyphenated job ids need bracket syntax —
`needs['static-guards'].result`, not `needs.static-guards.result`, which parses as subtraction.

### Step 2 — turn the rule on

Once `ci ok` reports on every PR, docs-only included, set protection with a **full-replace** PUT.
Anything omitted from this call is cleared, so `required_pull_request_reviews` and `restrictions`
must be sent explicitly null:

    PUT /repos/EmpoweredVote/ev-accounts/branches/master/protection
    {
      "required_status_checks":       { "strict": true, "contexts": ["ci ok"] },
      "enforce_admins":               true,
      "required_pull_request_reviews": null,
      "restrictions":                 null
    }

Read the settings back afterwards rather than trusting the write.

⚠ `strict: true` requires a branch to be up to date with `master` before merging. In a repo whose
local checkouts routinely sit tens of commits behind, that means more "update branch" round-trips.
Set it `false` if that friction outweighs the staleness risk — the check still has to pass either way.

---

## 5. Not chosen, and why

- **Require the four contexts directly, not an aggregate.** Works, but every job rename silently
  drops a requirement: protection keeps the old name and simply never sees it again. A rename is
  exactly the moment nobody re-reads branch protection.
- **Require reviews with `enforce_admins: false`.** What `civic-spaces` does, defensible there
  because auto-approve handles the common case. Here it would be a rule the only person merging
  bypasses every time.
- **A `CODEOWNERS` file.** Same deadlock as §2b, plus it implies an ownership map that does not exist.
- **Leave it as is.** Tenable while one person merges everything and reads every diff. It stops
  being tenable the moment a second writer lands, and the rule is far cheaper to adopt before that
  than after.

---

## 6. Rulesets — checked, and there are none

An earlier draft left this open because `GET /orgs/EmpoweredVote/rulesets` returns 404 without the
`admin:org` scope. That scope turned out to be unnecessary:
`GET /repos/{owner}/{repo}/rules/branches/{branch}` reports every **ruleset** rule applying to a
branch, organisation-level ones included, and needs only repo read.

    GET /repos/EmpoweredVote/ev-accounts/rules/branches/master   ->  []

✅ **No ruleset applies to `master`, at either level.** Combined with repo rulesets being `[]`, the
classic protection in §1 is the whole of it.

🔴 **The control is what makes that `[]` meaningful, and it is worth copying as a habit.**
`civic-spaces` `main` demonstrably carries classic protection — one required review and a required
`build` — and returns `[]` from the same endpoint:

    GET /repos/EmpoweredVote/civic-spaces/rules/branches/main    ->  []

So this endpoint covers **rulesets only and is blind to classic branch protection**. Without the
control, `[]` on `ev-accounts` would read as "no protection at all", which is the wrong conclusion
for the right-looking reason. An empty result from an API you have not calibrated against a known
positive is not evidence.

⚠ **One residual limit, stated rather than glossed.** This endpoint reports the rules applying in
the *requesting user's* context, and the account used holds org admin. A ruleset whose bypass list
includes that account could in principle be filtered out. Nothing suggests one exists — repo
rulesets are empty and the org has shown no sign of ruleset use — but a definitive enumeration
still wants `gh auth refresh -h github.com -s admin:org` and a direct read of
`GET /orgs/EmpoweredVote/rulesets`. It would not change §4: a rule this account bypasses is not a
rule that constrains this account.

Everything else here was read from the API or from `origin/master` on 2026-09-20.
