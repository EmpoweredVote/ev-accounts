# Phase 108: CouncilScribe roster client + CLI — Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship a CouncilScribe-side HTTP client and CLI that:

1. `src/essentials_client.py` — calls the Phase 107 `/api/essentials/bodies*` endpoints with a configurable base URL (`EV_ACCOUNTS_URL`, default `https://accounts.empowered.vote`), handles network failure gracefully.
2. `refresh_roster.py` — CLI that fetches a named body's roster and writes `~/CouncilScribe/config/rosters/{body_slug}.json`. Auto-generates per-member aliases covering the variants Whisper is known to mis-transcribe.
3. Extends `src/roster.py` so `load_roster()` resolves per-body rosters by slug when supplied, and falls back to the legacy `~/CouncilScribe/config/council_roster.json` when no slug is set.
4. Emits a non-blocking staleness warning when reusing a cached roster older than 30 days.
5. Never corrupts an existing cached roster on network/parse failure.

**Out of scope for this phase:** meeting-level `--body` plumbing (Phase 109), `StoredProfile` schema changes or politician-slug-keyed profiles (Phase 110), identification pipeline integration of live rosters (Phase 111).

The immediate consumer of this phase is Phase 109 (per-meeting body tagging). Data shape lives on disk at `~/CouncilScribe/config/rosters/{body_slug}.json` and the in-memory `Roster` dataclass returned by `load_roster()`.

</domain>

<decisions>
## Implementation Decisions

### Alias generation rules (primary gray area discussed)

- **D-01: Base variants.** For each roster member, generate aliases from:
  1. `full_name` (e.g. `"Isabel Piedmont-Smith"`)
  2. surname alone (last whitespace-separated token of `full_name`; hyphens preserved)
  3. `first_name + " " + last_name` (first = first whitespace token of `full_name`)
  4. `preferred_name + " " + last_name` — **only emitted when `preferred_name` is set and differs from `first_name`** (skip when equal or empty; the spec's "duplicates removed" clause covers this).
  5. `"{title} {last_name}"` (title verbatim from API `title` field)
  6. `"{title_stripped} {last_name}"` — title-stripped variant, emitted **only when the stripping rule below produces a different string**.

- **D-02: Hyphenated surnames get a space variant.** For any surname containing `-`, also emit the hyphen-replaced-with-space form as an additional alias. Example: `Piedmont-Smith` → also add `Piedmont Smith`, `Isabel Piedmont Smith`, `Councilmember Piedmont Smith`. Whisper almost never emits hyphens; the legacy `council_roster.json` already encodes this pattern. **Do NOT split hyphenated surnames into halves** (no bare `Smith` / `Piedmont`) — too collision-prone across a roster.

- **D-03: Accented characters — emit both forms.** For any alias containing non-ASCII characters, also emit the NFKD→ASCII-folded version. Example: `García` → also add `Garcia`; `Muñoz` → also add `Munoz`. Keep the canonical accented form first so the stored JSON is still visually correct. This mirrors the Phase 107 slug transform (NFKD → ASCII) and future-proofs against locales CouncilScribe hasn't encountered yet.

- **D-04: Title stripping rule — leadership titles only.** A small, hardcoded transform handles the `"{title_stripped} {last_name}"` alias:
  - Strip a single leading `Council `, `Vice `, or `Deputy ` prefix when the *next* token is one of: `President`, `Chair`, `Mayor`, `Speaker`, `Clerk`.
  - Example: `Council President Asare` → also emit `President Asare`.
  - Example: `City Clerk Bolden` → stripping doesn't apply (`City` is not in the prefix list) → no extra alias; the verbatim `City Clerk Bolden` is the only title variant.
  - Rule lives as a small regex or startswith-check in the alias generator. Do not generalize to "any multi-word title" or suffix-by-suffix stripping — too noisy for the benefit on the current Bloomington roster.

- **D-05: Dedup — case-insensitive, preserve written variants.** Dedup only collapses *pure case duplicates* (two strings that differ only in letter case). Strings that differ in punctuation or whitespace are kept as distinct aliases. Rationale: Whisper emits different punctuation/whitespace depending on the audio and model, and the matcher in `src/roster.py` already lowercases at comparison time, so keeping both `Piedmont-Smith` and `Piedmont Smith` is free recall. Dedup is applied *after* all generation (including hyphen-space expansion and ASCII folding).

- **D-06: Alias storage format — preserve original case.** The cached `{body_slug}.json` stores each alias with its original case intact (e.g. `"Councilmember Piedmont-Smith"`, `"Piedmont Smith"`). Matches the legacy `council_roster.json` format for operator readability, and `src/roster.py`'s matching routines already lowercase at comparison time (see `correct_speaker_name`), so stored case does not affect matching behavior.

- **D-07: Generation order is deterministic.** Aliases for a given member are generated in a fixed order (variants above in the order listed, with hyphen-space and ASCII-fold expansions inserted directly after their source alias). This makes the output JSON deterministic across refreshes — important for git-friendly diffs when operators commit a cached roster.

- **D-08: Alias generator is a pure function** operating on one politician record → `list[str]`. Unit-testable without network or filesystem; Phase 109/111 can re-use it if needed. Lives in `essentials_client.py` or a dedicated `alias_gen.py` helper (planner's call).

### Items intentionally NOT re-decided in this discussion

The following are constrained by Phase 107 / CSROSTER spec language and did not need user input. Planner may refine specifics but the shape is locked:

- Cache file path: `~/CouncilScribe/config/rosters/{body_slug}.json` (CSROSTER-02).
- Cache payload MUST include `body_key`, `body_slug`, `fetched_at`, and `politicians[]` with `politician_slug`, `full_name`, `aliases[]`, `title`, `district_label` (CSROSTER-02). Whether `politician_id`, `preferred_name`, `photo_url` are also persisted is planner's call — the endpoint returns them (Phase 107 D-16) and persisting them is cheap, but they are not required by the success criteria.
- `load_roster()` slug-first / legacy-fallback semantics (CSROSTER-04).
- 30-day staleness warning is non-blocking (CSROSTER-05).
- Network failure must not corrupt an existing cached file — write-to-temp-then-rename is the standard guard; planner chooses exact mechanism.
- HTTP client library, timeout values, and env var beyond `EV_ACCOUNTS_URL` are Claude's discretion. CouncilScribe already uses `requests` elsewhere — defaulting to `requests` is sensible but not mandated.
- Antipartisan enforcement carries through — the client code must never read, log, or persist any `party` field (there won't be one in the response per Phase 107 D-15, but defensive code review should grep for `party` in new files).

### Claude's Discretion (for researcher / planner)

- HTTP library choice (`requests` vs `httpx`) and timeout/retry policy.
- Exact module layout: one `essentials_client.py` vs splitting client + alias generator.
- Whether to reuse or extend the existing `Roster` / `RosterMember` dataclasses in `src/roster.py`, or introduce a parallel `BodyRoster` / `PoliticianMember` type. Either is acceptable as long as `load_roster(body_slug=...)` returns a type that `correct_speaker_name` and `roster_names_for_prompt` can consume without change (or with minimal, backward-compatible changes).
- CLI argument shape beyond `--body {slug}` (e.g., `--force`, `--base-url`, `--state`).
- Exact format of the staleness warning string and whether it also goes to `logging` in addition to stdout.
- Atomic-write mechanism (tempfile + `os.replace` is standard).
- Unit test layout and whether to stub the HTTP layer with `responses`/`respx` or use a hand-rolled fake.

</decisions>

<specifics>
## Specific Ideas

- **Hyphen-space expansion is load-bearing.** The existing `council_roster.json` entry for `Councilmember Piedmont-Smith` already includes `"Piedmont Smith"` as an alias, which is why it currently matches. Without D-02 the new per-body cache would be a regression on a meeting that already works.
- **Leadership-only title stripping matches the Bloomington roster.** `Council President Asare` is the one case where the verbatim title alone (`Council President Asare`) is unlikely to match Whisper output, which typically emits `President Asare`. The legacy roster handles this via manual aliases (`"Sari"`, `"Asare"`); D-04 makes it automatic.
- **Dedup preserves recall, not file size.** The alias list for a 9-member Bloomington roster will be ~6–10 strings per member. Keeping close-but-not-identical variants (hyphen vs space, accented vs ASCII) is explicitly the point, not a bug. File size is not a constraint here.
- **Backward compat with legacy roster is a hard requirement.** The existing `council_roster.json` uses `members[].name` + `members[].aliases[]`. Any new dataclass must still load it via the no-slug path of `load_roster()`. A meeting run today without `--body` (Phase 109) must still identify speakers exactly as it does now.
- **Antipartisan re-check.** The Phase 107 response already strips `party`; the Phase 108 client should have zero references to the word `party` in its source. Code review for this phase should grep `party` in `src/essentials_client.py`, `refresh_roster.py`, and any new alias helper.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` §"Phase 108: CouncilScribe roster client + CLI" — goal, depends-on, success criteria, requirements mapping.
- `.planning/REQUIREMENTS.md` §"CSROSTER — CouncilScribe roster client" — CSROSTER-01 through CSROSTER-05 (authoritative wording for each requirement).

### Upstream phase (locked data shape)
- `.planning/phases/107-essentials-body-roster-endpoint/107-CONTEXT.md` — the Phase 107 decisions, in particular D-16 (response shape) and D-15 (antipartisan). This is the contract Phase 108 consumes.
- `ev-accounts/backend/src/lib/essentialsBodiesService.ts` — authoritative source of the JSON the client parses.
- `ev-accounts/backend/src/routes/essentialsBodies.ts` — error envelope shapes (`{ code, message }`), status codes (404 `BODY_NOT_FOUND`, 422 `VALIDATION_ERROR`).

### CouncilScribe code to study / modify
- `CouncilScribe/src/roster.py` — existing `Roster` / `RosterMember` dataclasses, `load_roster()`, `correct_speaker_name()`, `roster_names_for_prompt()`, `add_alias()`. The load path is where the slug-vs-legacy branch plugs in.
- `CouncilScribe/src/config.py` — `CONFIG_DIR` (`~/CouncilScribe/config`) constant that both the legacy and new roster paths live under.
- `CouncilScribe/run_local.py` — current `load_roster()` call sites (~lines 568, 1021, 1719, 1749). None of these need to change in Phase 108; they continue to work via the legacy fallback. Phase 109 will thread a `--body` flag through.
- `~/CouncilScribe/config/council_roster.json` — reference copy of the legacy format, so the new code keeps loading it identically.

### Principles & conventions
- `CLAUDE.md` §"Antipartisan" / user memory `feedback_antipartisan.md` — never handle, log, or persist party information.
- User memory `councilscribe.md` — project background and historical decisions on the CouncilScribe runner.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Roster` and `RosterMember` dataclasses already exist (`src/roster.py`). The cached per-body JSON can deserialize into the same `Roster` shape if we accept that `members[].name` maps to the new `"{title} {last_name}"` or `full_name` canonical form. Alternatively, a new `BodyRoster` dataclass can wrap additional fields (`body_key`, `body_slug`, `fetched_at`, per-member `politician_slug`, `title`, `district_label`) while still exposing a `.members: list[RosterMember]` view for `correct_speaker_name` compatibility — planner's call.
- `correct_speaker_name` (roster.py:74) matches on lowercased aliases and does not care about canonical-name casing, so storing aliases in original case (D-06) works without any matcher changes.
- `add_alias` (roster.py:156) already handles de-duping on write; the new generator can share its dedupe helper or use its own since the generator runs on freshly-fetched data (no prior aliases to merge with).

### Established Patterns
- All CouncilScribe config lives under `~/CouncilScribe/config/` via `config.CONFIG_DIR`. New rosters go in `~/CouncilScribe/config/rosters/` — planner creates the dir on write.
- JSON files are written with `indent=2, ensure_ascii=False` (roster.py:209). New cache files follow suit for operator readability and git-friendly diffs.
- CLI scripts in CouncilScribe use `argparse` and print progress to stdout (see run_local.py). `refresh_roster.py` should follow the same convention.
- The existing legacy roster is committed by the operator — the new per-body cache lives outside the repo (`~/CouncilScribe/config/rosters/`) and is operator-local.

### Integration Points
- Only `src/roster.py` is modified in terms of existing files. `run_local.py` is NOT touched in Phase 108 (the legacy fallback keeps it working). Phase 109 wires the body flag through.
- New files: `src/essentials_client.py`, `refresh_roster.py` (at repo root next to `run_local.py` and `reenroll_profiles.py`), plus tests.

### Risks
- The existing `RosterMember.name` field is a human-readable canonical name (e.g. `"Councilmember Piedmont-Smith"`). If the new code stores `full_name` (`"Isabel Piedmont-Smith"`) as the canonical, the `roster_names_for_prompt()` output feeding the LLM (roster.py:215) changes format. Researcher should decide which canonical string (full_name vs title+last) feeds `correct_speaker_name`'s match output, because that string ends up in `transcript_named.json`.
- `src/roster.py` is imported at multiple points in `run_local.py`. Any signature change to `load_roster()` (e.g. adding `body_slug` parameter) must default to `None` / legacy behavior so no caller needs updating in this phase.

</code_context>

<deferred>
## Deferred Ideas

- **Meeting-level `--body` plumbing into `run_local.py`** — belongs to Phase 109 per ROADMAP. Phase 108 stops at `load_roster(body_slug=...)` being *available*; nothing invokes it yet.
- **Politician-slug-keyed voice profiles** — Phase 110.
- **Live roster feeding into identification / LLM prompt** — Phase 111.
- **Auto-refresh on staleness** — the 30-day check only warns; it never auto-fetches. An auto-refresh mode (`--auto-refresh` flag, or time-based trigger in `run_local.py`) is a future enhancement.
- **Multiple roster versions / history** — the cache is last-write-wins per body. Keeping historical rosters for post-hoc re-identification is a separate problem.
- **Splitting hyphenated surnames into halves** — explicitly rejected in D-02 due to collision risk. Revisit only if we see real-world Whisper errors that only half-name aliases would catch.
- **Broader title-stripping rule (multi-word / suffix-based)** — explicitly rejected in D-04. Revisit when a non-Bloomington jurisdiction surfaces a title the leadership-only rule doesn't cover.
- **Lowercasing aliases at storage time** — explicitly rejected in D-06. Revisit only if file size becomes a concern (it won't for ~9-member rosters).
- **Trimming `body_key` / `body_slug` duplication in the cache payload** — both are persisted per CSROSTER-02. If they're always identical in practice, a later cleanup could drop one, but for now we follow the spec verbatim.

</deferred>

---

*Phase: 108-councilscribe-roster-client-cli*
*Context gathered: 2026-04-11*
