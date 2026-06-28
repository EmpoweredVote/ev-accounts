# Pitfalls Research

**Domain:** Adding 2026 US House general-election candidate coverage (CA/TX/FL/NY, 144 districts) to an existing civic-data platform
**Researched:** 2026-06-27
**Confidence:** HIGH (verified against current `electionService.ts`, `essentialsService.ts`, migrations 196/1074/042, and project memory of the v2.4 Senate run + the LA re-check)

> Scope note: these are pitfalls specific to ADDING the 2026 House field, not generic data-entry advice. The four highest-impact traps for THIS milestone — duplicate incumbent records, the lost-incumbent-primary assumption, stance over-read, and seed-now/prune-later discipline — are the first four Critical Pitfalls and are covered with concrete how-to.

---

## Critical Pitfalls

### Pitfall 1: Duplicate incumbent records (the "two Andy Barrs" trap)

**What goes wrong:**
A sitting House incumbent running for re-election already has an `essentials.politicians` row + a `NATIONAL_LOWER` office (seeded in v2.15, stanced in v2.16/v2.17). A naive "seed the 2026 field" script creates a SECOND politician row for the same person (new headshot, partial stance set, new external_id). This is exactly what v2.4 did — it created duplicate "Andy Barr" records — and it took migration 1074 (David Brock Smith) to clean up an analogous Senate dupe later.

**Why it happens:**
- The candidate-seeding source (Ballotpedia, FEC, ballot field) lists the incumbent as "a candidate" with no link back to the existing record, so the importer treats them as net-new.
- New House candidacy is represented by a `race_candidates` row (and/or a `Candidate for U.S. House` office), a different object than the incumbent's sitting `NATIONAL_LOWER` office — easy to conflate "needs a candidacy row" with "needs a politician row."
- Match-by-name is unreliable (suffixes, preferred names, middle initials), so importers skip the de-dup check.

**How to avoid:**
- **Reuse the existing politician record; never create a new one for an incumbent.** The milestone goal already states "sitting incumbents are already stanced (v2.15–v2.17)" — so the in-scope NEW work is challengers + open-seat candidates only.
- Run a **stance-gap / existence diagnostic at plan time** (PROJECT.md already calls for this): for each of the 144 districts, query the existing `NATIONAL_LOWER` office → politician. If the incumbent is the 2026 nominee, link the new `race_candidates` row to the **existing** `politician_id`; add no new politician row.
- Represent candidacy via the `race_candidates` link (and an office row only if you also want them in an offices-based view), **not** a duplicate politician. Migration 1074's lesson: "candidacy is represented by the race_candidate link, not an office."
- Seed challengers (NULL `external_id`, low-profile) and open-seat candidates as new records; sitting officials running keep their existing `external_id`.

**Warning signs:**
- Two `essentials.politicians` rows with the same/near-same `full_name`.
- A district where the incumbent appears twice in any view, or where a "candidate" record has 0–3 stances while another record for the same person has 20+.
- Importer logs "INSERT" for a name that should already exist.

**Phase to address:** Diagnostic phase (first) — before any seeding. Gate assertion: zero duplicate `(full_name)` within a state, and every incumbent-nominee `race_candidates` row points at the pre-existing `politician_id`.

---

### Pitfall 2: Assuming the incumbent is the nominee (lost-primary trap)

**What goes wrong:**
Some 2026 House "incumbents" LOST their primary and are NOT on the November ballot (research flagged NY-10 Goldman and NY-13 Espaillat). If the seeding logic auto-assumes "incumbent = general-election candidate," it surfaces a person who is not actually running and omits the real nominee who beat them.

**Why it happens:**
- "Incumbent" is a status on the person, not a statement about the current ballot. The reps feed legitimately shows the sitting incumbent (they hold the office until Jan), but the ELECTIONS feed must show the actual general-ballot field.
- Primaries are staggered and some are decided after seeding starts; a stale roster assumes incumbency carries forward.

**How to avoid:**
- **Verify the actual general-election nominee per district from a primary-results source** (Ballotpedia/Wikipedia per district), never derive it from incumbency. Ballotpedia blocks WebFetch — use Wikipedia or Playwright (project-confirmed).
- Keep the two concepts separate: the sitting incumbent stays in the **reps feed** (`is_incumbent=true`, surfaced regardless of candidacy); the **elections feed** `race_candidates` rows reflect only who is actually on the Nov ballot.
- For a defeated incumbent: they remain a valid sitting rep (reps feed) but get **no active `race_candidates` row** for the 2026 general (or `candidate_status='withdrawn'` if one was seeded pre-primary). The primary winner gets the active `race_candidates` row.

**Warning signs:**
- A district's general-election field contains the incumbent but the primary-results source shows they lost.
- The real nominee (challenger who won the primary) has no record.
- NY-10 / NY-13 specifically — treat as known cases, verify explicitly.

**Phase to address:** Per-district nominee-resolution phase. Gate: each in-scope district's general `race_candidates` set matches a verified primary-results source; flagged lost-incumbent districts (NY-10, NY-13, others discovered) explicitly confirmed.

---

### Pitfall 3: Stance over-read — agents inject plausible-but-false chairs even with cited URLs

**What goes wrong:**
The stance-research agents pin a compass value (1–5) the cited source does not actually support — e.g. reading a boilerplate "protect Social Security" line into a pinned social-security chair, or inferring fossil-fuels from an anti-CCS/45Q clause (both literally caught and DROPPED on Jamie Davis in the Senate run). The URL is real but the value is polarity-inference, not evidence. This is the exact failure mode that produced 16 deleted rows in the 7-challenger pass.

**Why it happens:**
- WebFetch summaries are LOSSY — the agent adjudicates a chair from a paraphrase that flattened the nuance.
- Agents map party/ideology onto a "plausible" chair when the source is ambiguous, violating "chairs not polarity."
- Low-profile House challengers have thin platforms, so agents over-read whatever boilerplate exists.

**How to avoid:**
- **Mandatory primary-source verification pass on every agent stance row** — re-fetch raw quotes (Playwright/raw fetch, not the lossy summary) and adjudicate the exact chair; delete or correct anything that is polarity-inference. Verify EXISTING stances too where touched.
- Enforce "chairs not polarity": the value must come from evidence showing the specific scale position, never from party. Embed the exact 1–5 stance texts per topic in the agent prompt (direction varies by topic — never "5=progressive").
- **Honest-skip any topic with no real fetched source** — not even a middle value. Whole-record honest-skip is allowed and should be pinned in the gate (like the v2.18 10-id pins, the Rutledge/Dunn MD skips).
- Apply the FEDERAL 24-topic set (federal adds social-security, tariffs, ukraine-support; drops 5 state-only). Don't carry state-only topics onto federal House candidates.

**Warning signs:**
- A stance row whose source is a campaign "issues" boilerplate line with no specific position.
- social-security / fossil-fuels / immigration chairs pinned from a single vague clause.
- A thin challenger with a suspiciously complete 24-topic set.

**Phase to address:** Every stance-research phase, as a required verification sub-step before push. Gate: 0 unsourced stances; spot-check pinned chairs against raw quotes.

---

### Pitfall 4: Seed-now / prune-later without preserving records (the re-check discipline)

**What goes wrong:**
FL primary is Aug 18 (and other late primaries); the field must be seeded NOW so residents get data for the upcoming vote. After the primary, losers must be removed from the live field — but a hard DELETE destroys the record, stances, headshot, and FEC data that took real work to build, and breaks any FK references.

**Why it happens:**
- The instinct after a primary is to "remove the losers," and DELETE is the obvious verb.
- Two different prune mechanisms exist for the two surfacing paths (see Pitfall 5), so a partial prune leaves the loser visible in one place.

**How to avoid (the LA re-check pattern, project-validated):**
- To retire a loser: **`UPDATE essentials.politicians SET is_active=false`** — preserves the record + stances + headshot + FEC; the reps feed filters `p.is_active=true` so they drop out.
- For the elections feed, set `essentials.race_candidates.candidate_status='withdrawn'` for the loser (the candidate-detail path already excludes `candidate_status != 'withdrawn'`); keep the winner's row active.
- Re-research the advancing thin-stance candidate against PRIMARY sources only after they win.
- Operator principle: seed the PRIMARY/RUNOFF field now (data for the upcoming vote), don't wait for or guess the general winner.

**Warning signs:**
- A migration with `DELETE FROM essentials.politicians` for a primary loser.
- A retired candidate still appearing in one feed but not the other.
- Lost stance/headshot work that has to be re-done.

**Phase to address:** Build the re-check as an explicit deferred task/phase keyed to primary dates (FL Aug 18 + any other late ones). Document the two-path prune (is_active=false AND candidate_status='withdrawn') in the phase plan.

---

### Pitfall 5: Two-surfacing-paths confusion — candidate appears in one place but not the other

**What goes wrong:**
There are TWO independent ways a candidate surfaces, with different requirements. A candidate seeded for one path is invisible in the other, so it "works" when testing one screen and silently fails on another.

**The two paths (verified in code):**
1. **Reps feed** (`getRepresentativesByJurisdiction` in `essentialsService.ts`): matches the user's congressional geo_id → `NATIONAL_LOWER` district → office → politician. Critically it filters **`AND COALESCE(p.is_incumbent, true) = true`** — so a challenger (`is_incumbent=false`) does NOT appear here. This path shows the sitting rep, not the challenger field.
2. **Elections feed** (`fetchDistrictRaceRows` in `electionService.ts`): matches the congressional geo_id (via the MTFCC guard) → `races` → `race_candidates`. This is where the full general-ballot field (incumbent + challengers) shows. Photos join via `rc.politician_id`; stances require a linked `politician_id`.

**Why it happens:**
- The Senate "Path A" model surfaces challengers via a `Candidate for U.S. Senate — <State>` **office** row, a third pattern. Carrying that to House without checking the House feed query leads to candidates seeded as offices the elections feed (which reads `race_candidates`) never shows — or vice versa.
- The reps feed's `is_incumbent=true` filter is non-obvious; a challenger seeded "correctly" as a politician+office still won't appear there.

**How to avoid:**
- **Decide the House surfacing path explicitly in research/requirements** (PROJECT.md flags this as an open question: "resolve elections-page vs. representatives-feed surfacing path"). For "see your 2026 House race field," the **elections feed via `race_candidates`** is the correct path — the only path that shows non-incumbent challengers.
- A House general-election candidate needs: a `races` row for the district (office linked to the `NATIONAL_LOWER` district), a `race_candidates` row per candidate, and (for stances + photo) a linked `politician_id`.
- Don't rely on the offices-based reps feed to show challengers — its `is_incumbent=true` filter excludes them by design.
- If a small code change is needed (e.g. to surface the House race block on the Elections page), scope it in the surfacing-path phase rather than assuming pure-data.

**Warning signs:**
- A challenger with a `Candidate for U.S. House` office but no `race_candidates` row → invisible on Elections page.
- A `race_candidates` row with NULL `politician_id` → no stances, no photo (PHOTO_LATERAL keys off `rc.politician_id`).
- Candidate visible on a politician detail page but not in the user's address-based Elections result.

**Phase to address:** Surfacing-path resolution phase (early — determines pure-data vs. code change). Gate: a test address in each Wave-1 state returns its House race with the full candidate field on the Elections feed.

---

### Pitfall 6: Thin-sourcing for low-profile challengers → over-filling instead of honest-skip

**What goes wrong:**
Many of the 144 districts include obscure challengers (third-party, perennial, late-filing) with almost no fetchable record. The temptation is to fill a fuller stance set than evidence supports, or to skip the candidate entirely and leave the race field incomplete.

**Why it happens:**
- A race "looks done" with the incumbent + one major challenger, but a third ballot-qualified candidate has only a one-page site.
- Source walls: Ballotpedia/VoteSmart/voter-guide pages return 403/blank via WebFetch.

**How to avoid:**
- Seed the candidate **record** (name, party-on-race, headshot if findable) even when stances are thin — the field must reflect the actual ballot.
- Honest-skip stance topics with no evidence; a low-profile House challenger commonly yields ~5–9 honest stances max (matches the Senate experience: Davis 9, the 7-challenger spread 8–20). Campaign site + a local-news candidate Q&A is the usable vein.
- Whole-record honest-skip (record seeded, 0 stances, documented) is acceptable and gate-pinnable — like Rutledge/Dunn in the MD work.

**Warning signs:**
- A perennial/third-party candidate with a full 24-topic set.
- A race field missing a ballot-qualified candidate because "no sources."

**Phase to address:** Stance-research phases; gate allows documented whole-record skips pinned by id.

---

### Pitfall 7: Headshot sourcing for obscure challengers + antipartisan display constraint

**What goes wrong:**
(a) Obscure challengers have no clean headshot, leading to missing photos or a low-quality scrape. (b) Party gets attached to the candidate card instead of the race, violating the antipartisan mission.

**Why it happens:**
- Headshots for low-profile candidates often exist only as a Ballotpedia thumb or a campaign couple-photo needing a crop.
- Importers habitually put party on the candidate; the platform's convention is party on the race.

**How to avoid:**
- Headshots: follow find-headshots conventions — upload to `politician_photos/<politician_id>/default.jpg`, insert `essentials.politician_images` `type='default'`, set `photo_origin_url`. Process to 600x750 (4:5, Lanczos, q90), composite alpha→white. Ballotpedia thumbs (200x300) are the reliable `press_use` fallback; crop campaign group/couple photos when that's all that exists.
- Antipartisan: **party context lives on the RACE (`races.primary_party`), never on the candidate** — enforced at the query layer (`electionService.ts` header comment). Do not populate party as a displayed candidate attribute in the elections feed.

**Warning signs:**
- Candidate cards displaying party in the elections feed.
- Missing `politician_images` row → no photo even though `photo_url` looks set.

**Phase to address:** Headshot phase + the surfacing-path phase (verify no party on candidate card).

---

### Pitfall 8: FEC rate limits / name-match failures at 144-district scale

**What goes wrong:**
FEC ingestion times out or silently name-mismatches the committee (the project already has a known FEC name-match queue with LaMalfa/Swalwell-type failures). At 144 districts × multiple candidates, rate limits and mismatches multiply.

**Why it happens:**
- FEC committee lookup is name-keyed and brittle; high request volume hits rate limits (the Senate run had persistent timeouts on ~5 federal politicians).

**How to avoid:**
- Treat FEC finance as best-effort enrichment, not a blocker (`finance_summary` is nullable; null for non-federal already handled).
- Throttle requests; reuse the existing fix-FEC-name-mismatches script pattern; record which candidates have no FEC ID rather than retrying indefinitely.

**Warning signs:**
- Repeated FEC timeouts on the same IDs; finance attributed to the wrong committee.

**Phase to address:** Optional finance-enrichment phase (low priority; not on the critical path for the "see your race" goal).

---

### Pitfall 9: Malformed CSV from research agents + stale-quote duplication on re-push

**What goes wrong:**
(a) Stance-researcher agents emit malformed CSVs constantly — a stray trailing comma yields 11 fields, a missing field yields 9 (canonical 10). (b) On a quote-text correction, the push INSERTs a NEW quote and leaves the stale one selected, so the candidate shows a stale/duplicate quote. Apostrophe/encoding in quote text compounds this.

**Why it happens:**
- Agents don't enforce a fixed field count; quote pushes are insert-only with no replace.

**How to avoid:**
- **Field-count-validate and normalize every CSV before `_push_*.ts`** (re-parse → re-stringify to canonical 10 fields).
- On any quote correction: **wipe `essentials.quotes` for the pid, then re-push** the verified set for a clean quote set.
- New low-profile records (NULL external_id) push via `_push_uuid.ts`; sitting-official records (external_id) push via `_push.ts`.
- Bash cwd resets between calls — `cd /c/EV-Accounts/backend &&` in the SAME compound command; run node with `--env-file=.env`.

**Warning signs:**
- Push errors on field count; a candidate showing two quotes for one topic or a quote that contradicts the corrected value.

**Phase to address:** Every stance-research phase (push hygiene sub-step).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hard-DELETE primary losers instead of `is_active=false` | One-line cleanup | Destroys stances/headshot/FEC; breaks FKs; loses audit trail | Never — use `is_active=false` + `candidate_status='withdrawn'` |
| New politician row for an incumbent "candidate" | Importer is simpler (no de-dup) | Duplicate records (v2.4 Andy Barr; migration 1074 cleanup) | Never — reuse existing record |
| Infer a chair from party when source is thin | Fuller-looking coverage | Trust erosion; mass deletions in verification pass | Never — honest-skip |
| Seed challengers only as offices (Senate Path A) for House | Mirrors prior milestone | Invisible on Elections feed (which reads `race_candidates`) | Never for House — use `race_candidates` |
| Skip FEC enrichment for hard name-matches | Avoids rate-limit churn | Some candidates lack finance | Acceptable — finance is best-effort, nullable |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Reps feed (`essentialsService`) | Expecting challengers to appear | It filters `is_incumbent=true` — only the sitting rep shows; challengers surface via the elections feed |
| Elections feed (`electionService`) | Seeding candidate as an office only | Seed a `race_candidates` row (+ linked `politician_id` for stances/photo) |
| Ballotpedia | WebFetch the page | Blocked — use Wikipedia or Playwright for primary results / headshot thumbs |
| FEC | Retry timeouts indefinitely; trust name-match | Throttle; reuse fix-name-mismatch script; record "no FEC ID" |
| `race_candidates.politician_id` | Leaving NULL | NULL → no stances and no photo (PHOTO_LATERAL keys off it) |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Displaying party on candidate card | Violates antipartisan mission (a product/trust requirement) | Party lives on `races.primary_party` only; enforced at query layer |
| Surfacing a withdrawn/retired candidate | Misinforms voters about the ballot | Prune both paths (`is_active=false` + `candidate_status='withdrawn'`) |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing a defeated incumbent as a 2026 candidate | Voter sees a non-candidate; misses real nominee | Verify nominee per district; defeated incumbent stays in reps feed, not the general field |
| Incomplete race field (missing ballot-qualified candidate) | Race looks done but a real candidate is absent | Seed every ballot-qualified candidate even if stances are thin |
| Stale/duplicate quote on a candidate | Contradictory or wrong attribution | Wipe `essentials.quotes` for the pid then re-push |

## "Looks Done But Isn't" Checklist

- [ ] **Incumbent reuse:** Every incumbent-nominee candidacy links to the EXISTING `politician_id` — verify zero duplicate `full_name` within a state.
- [ ] **Nominee correctness:** Each district's general field matches a verified primary-results source — verify NY-10, NY-13, and any other flagged lost-incumbent.
- [ ] **Both surfacing paths:** A test address in CA/TX/FL/NY returns its House race on the Elections feed — verify the challenger field is present, not just the incumbent.
- [ ] **`race_candidates.politician_id` set:** Every candidate with stances/headshot links its politician — verify no NULL where data exists.
- [ ] **Stance verification pass:** Every pinned chair re-checked against a raw quote — verify 0 unsourced, 0 polarity-inference.
- [ ] **Party placement:** No party on candidate cards — verify it reads from `races.primary_party`.
- [ ] **Re-check task scheduled:** FL Aug 18 (+ other late primaries) deferred prune task documented with the two-path method.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Duplicate incumbent record | MEDIUM | Migration-1074 pattern: pick survivor (richest stances/headshot/race link), move offices onto it, delete dup's redundant children + row, guard by name |
| Wrong nominee surfaced | LOW | Add/activate the real nominee's `race_candidates` row; `withdrawn`/`is_active=false` the non-candidate |
| Over-read stances shipped | LOW–MEDIUM | Re-fetch raw quotes; delete inference rows (16-row precedent); wipe + re-push quotes |
| Loser hard-deleted | HIGH | Re-seed record + re-research stances + re-source headshot/FEC from scratch |
| Candidate in one path only | LOW | Add the missing `race_candidates` row or link `politician_id` |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Duplicate incumbent records | Diagnostic phase (first) | Gate: 0 duplicate full_name per state; incumbent-nominee links to existing politician_id |
| Lost-primary / wrong nominee | Nominee-resolution phase | Gate: general field matches primary-results source; NY-10/NY-13 confirmed |
| Stance over-read | Each stance phase (verification sub-step) | Gate: 0 unsourced; spot-check chairs vs raw quotes |
| Seed-now / prune-later | Deferred re-check task (per primary date) | Both paths pruned; records preserved |
| Two surfacing paths | Surfacing-path phase (early) | Gate: test address returns full House field on Elections feed |
| Thin-source over-fill | Stance phases | Gate: documented whole-record skips pinned by id |
| Headshots + antipartisan | Headshot phase | All new candidates have `politician_images`; no party on card |
| FEC rate/name-match | Finance enrichment (optional) | Best-effort; "no FEC ID" recorded |
| Malformed CSV / stale quotes | Each stance phase (push hygiene) | Field-count-validated CSV; clean quote set per pid |

## Sources

- `backend/src/lib/essentialsService.ts` (reps-feed query; `is_incumbent=true` filter, ~lines 1495–1599) — HIGH
- `backend/src/lib/electionService.ts` (elections feed; `race_candidates` path, antipartisan rationale, visibility window) — HIGH
- `backend/migrations/196_us_senate_candidates_2026.sql` (candidate-office seeding pattern, idempotency) — HIGH
- `backend/migrations/1074_dedupe_david_brock_smith.sql` (duplicate-record recovery pattern) — HIGH
- `backend/migrations/042_election_schema.sql` (`candidate_status` enum: active/withdrawn/filed) — HIGH
- Project memory `project_2026_senate_coverage.md` (Path A, LA re-check, malformed-CSV/stale-quote traps) — HIGH
- Project memory `feedback_stance_no_assumption.md`, `feedback_chairs_not_polarity.md` (no-inference rules, 16 deleted rows) — HIGH
- PROJECT.md v2.20 milestone definition (surfacing-path open question, stance-gap diagnostic, seed-now/re-check) — HIGH

---
*Pitfalls research for: 2026 US House candidate coverage (v2.20)*
*Researched: 2026-06-27*
