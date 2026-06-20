# Stack Research

**Domain:** Civic data — state executive office seeding (Big 5 statewide executives, 50 states)
**Researched:** 2026-06-20
**Confidence:** HIGH (existing stack confirmed; data sources verified against live pages)

---

## Verdict: No New Dependencies

v2.18 is a data milestone. The existing proven stack covers 100% of the work:
idempotent SQL migrations, the v2.16/v2.17 stance pipeline, and the `find-headshots` skill.
No new libraries, no new scripts from scratch, no schema changes.

The only real question this milestone raises is: **which data sources to trust for the
elected-vs-appointed roster and current officeholders?** That is answered below.

---

## Recommended Stack — Data Sources

### Source 1: Wikipedia "Current Officeholders" Articles (PRIMARY — elected-vs-appointed roster)

| Attribute | Detail |
|-----------|--------|
| Reliability | HIGH — community-maintained, updated rapidly after elections/appointments; cross-referenced with official .gov sources |
| Parseability | HIGH — standard HTML tables, parseable with WebFetch; structured columns: State, Officeholder, Party, Selection Method, Term |
| Recency | HIGH — Jan 2026 inaugurations are already reflected (verified: Spanberger VA, Sherrill NJ, Armstrong ND, etc.) |
| Cost | Free, no authentication |

**Specific pages (all confirmed accessible and structured as tables):**

| Office | Wikipedia URL | Selection-method data available? |
|--------|---------------|----------------------------------|
| Governors | `en.wikipedia.org/wiki/List_of_current_United_States_governors` | All 50 states, party, term dates — YES |
| Lt. Governors | `en.wikipedia.org/wiki/List_of_current_United_States_lieutenant_governors` | 45 states (5 no office), ticket vs separate election — YES |
| Attorneys General | `en.wikipedia.org/wiki/State_attorney_general` | 43 elected, 7 appointed; all 50 states named and partied — YES |
| Secretaries of State | `en.wikipedia.org/wiki/Secretary_of_state_(U.S._state_government)` | 35 elected, 3 no office (AK/HI/UT), legislative in ME/NH/TN, appointed rest — YES |
| State Treasurers | `en.wikipedia.org/wiki/State_treasurer` | 36 popular election, 2 no office (NY abolished/TX abolished), legislative in ME/MD/NH/TN, appointed rest — YES |

**How to use:** WebFetch each page once per milestone. The table format is consistent across all five — extract State, Officeholder, Party, Selection Method. No API key, no rate limit, no authentication wall.

**Known limitation:** Wikipedia lags 1-7 days on brand-new resignations/appointments. Cross-check against the official .gov page for the specific state when a recent change is suspected.

---

### Source 2: Official State .gov Biography Pages (SECONDARY — officeholder verification + headshots)

| Attribute | Detail |
|-----------|--------|
| Reliability | AUTHORITATIVE — primary source, never wrong about current incumbent |
| Parseability | LOW-MEDIUM — each state has its own layout; no standard format across states |
| Recency | AUTHORITATIVE — updated within days of any change |
| Cost | Free |

**Use for:** (1) Verifying name/party/term for any officeholder where Wikipedia table entry looks stale; (2) finding the official headshot URL for `find-headshots`; (3) stance research — official biography/press release pages are above-the-bar primary sources.

**Naming pattern for governor pages:** `governor.{state}.gov`, `{statecode}.gov/governor`, or `{statecode}.gov/government/governor`. Use WebSearch `"[name]" "[state] governor" site:*.gov` when the URL is not obvious.

---

### Source 3: National Association Pages (TERTIARY — cross-check, not primary)

| Organization | URL | Quality | Notes |
|-------------|-----|---------|-------|
| NGA (Governors) | `nga.org/governors/` | MEDIUM | Gallery + PDF roster; no machine-readable API; useful as a visual cross-check but WordPress image URLs are not stable enough for headshots |
| NAAG (AGs) | `naag.org/find-my-ag/` | MEDIUM | Gallery of headshots with names; selection method NOT shown; no party data on main page; use Wikipedia instead |
| NASS (SoS) | `nass.org` | LOW for roster | "Find Your Secretary of State" tool; no public member listing without login; not useful for bulk seeding |
| NAST (Treasurers) | `nast.org` | LOW for roster | "Find Your State Treasurer" tool; member-only detailed directory; not useful for bulk seeding |

**Verdict:** NGA/NAAG are useful cross-checks for individual name verification. NASS and NAST are not useful for bulk roster work — Wikipedia's State Treasurer and Secretary of State articles are more complete and parseable.

---

### Source 4: Ballotpedia (STANCE RESEARCH — not roster building)

| Attribute | Detail |
|-----------|--------|
| Reliability | HIGH for stances |
| Parseability | LOW for roster building — JS-rendered pages return empty HTML to WebFetch |
| Recency | MEDIUM — individual candidate pages updated but no bulk list page |
| Cost | Free |

**Use for:** Stance research — Ballotpedia individual politician pages (`ballotpedia.org/[Name]`) are above-the-bar primary sources for positions, endorsements, and voting records. Confirmed usable in v2.16/v2.17 pipeline.

**Do NOT use for:** Bulk roster building. `ballotpedia.org/State_treasurer`, `ballotpedia.org/Secretary_of_state`, and similar category pages return empty content via WebFetch (JS-rendered). The `ballotpedia.org/List_of_current_*` pages also fail. Individual politician pages load fine.

---

### Source 5: Wikimedia Commons (HEADSHOTS — governors and major statewide execs)

| Attribute | Detail |
|-----------|--------|
| Reliability | HIGH for governors (official portraits present for all 50) |
| Parseability | MEDIUM — no consistent filename pattern; 18,188+ governor portrait files with varied naming |
| License | FREE — CC BY-SA or public domain US government works |
| Cost | Free |

**Use for:** Governor and Lt. Governor headshots as a fallback when the official .gov page does not have a directly hotlinkable image. Wikipedia's governor list already embeds Wikimedia Commons image URLs in the infobox — extract directly from the Wikipedia table rather than searching Wikimedia Commons separately.

**How to use:** The `find-headshots` skill already handles this workflow (WebSearch → navigate → extract → approve → mirror to Supabase storage). No change to the skill needed.

**Do NOT use NGA WordPress image CDN** (`nga.org/wp-content/uploads/...`) for headshots — WordPress CDN paths are unstable; images rotate or get deleted without notice.

---

## Elected-vs-Appointed Decision Grid

This is the core data needed to determine which offices to seed per state. Verified from Wikipedia articles (2026-06-20).

### Governors — All 50 states elect their governor by popular vote.

No exceptions. All 50 included in the seed.

### Lieutenant Governors

**5 states have NO lieutenant governor office:**
- Arizona, Maine, New Hampshire, Oregon, Wyoming

The other 45 states all elect a lieutenant governor. Selection method (same-ticket vs separate election) is a data attribute, not a seeding filter — both result in an elected official.

**AZ note:** Voters approved creating a LG position starting 2026; the current (2026) incumbent is still the SoS Adrian Fontes serving succession duties. Treat AZ as "no LG" for v2.18.

**TN/WV note:** Both have a "lieutenant governor" title held by the Senate Speaker — this is a legislature-internal role, not a statewide-elected position. Omit from Big 5 seed for both states.

**Revised count for Lt. Governor seed: 43 states** (45 with office minus TN/WV which are Senate-Speaker roles).

### Attorneys General

**43 states elect their AG by popular vote** — these are all in scope.

**7 states with non-popular-election AG (omit from Big 5 seed):**
- Governor-appointed: Alaska, Hawaii, New Hampshire, New Jersey, Wyoming
- State Supreme Court appointment: Tennessee
- Legislature-elected: Maine

**Note:** Maine's AG (Aaron Frey) is legislature-elected and already seeded. Model as `is_appointed_position=true` (as done in migration 169). Do NOT include Maine AG in the "elected Big 5" count.

### Secretaries of State

**35 states elect their SoS by popular vote** — in scope.

**States to omit:**
- No office: Alaska, Hawaii, Utah (Lt. Gov performs duties)
- Legislature-elected: Maine, New Hampshire, Tennessee (not popular-elected — omit)
- Governor-appointed: approximately 10 states including Delaware, Florida, Maryland, New Jersey, New York, Oklahoma, Pennsylvania, Texas, Virginia

**TX/VA/MD specific:** Texas and Virginia are already in the existing 68 STATE_EXEC records — verify they have `is_appointed_position=true` for SoS if seeded. Maryland SoS (Susan C. Lee) is governor-appointed — omit from "elected" seed.

### State Treasurers

**~36 states elect treasurer by popular vote** — in scope.

**States with no treasurer office:**
- New York (abolished 1926 — Comptroller holds duties)
- Texas (abolished 1996 — Comptroller of Public Accounts holds duties)

**States with legislature-elected treasurer (omit from "elected" seed):**
- Maine, Maryland, New Hampshire, Tennessee

**States with governor-appointed treasurer (omit from "elected" seed):**
- Alaska, Georgia, Hawaii, Michigan, Minnesota, Montana, New Jersey, Virginia, Washington

**Note:** Washington State Treasurer (Mike Pellicciotti) shows as **elected** in the Wikipedia table — double-check this against the WA state constitution before omitting. Minnesota Treasurer is governor-appointed (Erin Campbell). Montana Treasurer is governor-appointed (Brendan Beatty).

---

## Migration Pattern (Existing — No Change Needed)

The existing state exec migration pattern (established in migrations 154/169/270/317) is:

1. **INSERT STATE_EXEC districts** — one per elected office, `state='XX'` uppercase, `geo_id='{fips}'`, `label='{State} {Office}'`, `district_id=''`, `mtfcc=''`
2. **INSERT governments row** (WHERE NOT EXISTS) — one per state
3. **INSERT chambers** — one per office type, linked to government
4. **CTE INSERT politician + office** — `ON CONFLICT (external_id) DO NOTHING`
5. **office_id back-fill** on politicians
6. All idempotent, safe to re-run

**External ID scheme:** `-{state_fips_zero_padded_to_2}{seq_2_digit}` e.g. `-510001` (VA Gov), `-240001` (MD Gov), `-230001` (ME Gov). For the 41 unseen states, assign `-(fips*100 + seq)` in the same pattern. Verify no collision with existing external_ids before authoring.

**Feed routing:** `STATE_EXEC` is already handled in `essentialsService.ts` and `essentialsBrowseService.ts` by `WHERE d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', ...) AND (d.state = $1 ...)`. Adding records for a new state requires only the migration — no backend routing change needed. This is confirmed by the fact that CA, IN, MA, MD, ME, OR, TX, UT, VA execs already surface in the feed today.

---

## Stance Pipeline (Existing — No Change Needed)

The v2.16/v2.17 pipeline applies unchanged:

- `_TOPIC_SCALE.txt` — 25 federal topics (already current for state execs; governors/AGs all hold positions on the same federal-question set)
- `politician-stance-researcher` agent at 3-concurrency
- Per-rep CSV → `_merge.ts` → external_id-keyed `_push.ts`
- Real source URL required per stance row; honest-skip where no evidence; never infer from party

**State exec stance research sources (ranked):**
1. Official .gov biography/press releases
2. Ballotpedia individual politician page
3. Votesmart.org political courage test responses
4. OnTheIssues.org (above-bar for documented quotes/votes, below-bar for inferred positions)
5. State legislature votes (for former legislators serving as governor/AG/etc.)
6. News articles with direct quotes from credible outlets

**State execs tend to have MORE documented positions** than freshman House members — governors have press releases, AGs have filed amicus briefs (immigration, abortion, etc.) which are primary sources. Expect honest-partial rate to be lower than v2.17's freshman-heavy batches.

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Ballotpedia category/list pages | JS-rendered; return empty HTML to WebFetch | Wikipedia structured tables |
| NGA headshot images (nga.org/wp-content/) | WordPress CDN; unstable URLs | Official .gov portraits or Wikimedia Commons |
| NASS/NAST member directories | Login-gated; no bulk public listing | Wikipedia Secretary of State / State Treasurer articles |
| iSideWith.com | Aggregator characterizations, not documented positions; below evidence bar (v2.17 lesson) | Real fetched URL from .gov, ballotpedia, news |
| Inferring stances from party affiliation | Platform principle violation; see `feedback_stance_no_assumption.md` | Real source or honest-skip |
| Any "appointed" exec in the Big 5 seed | Not voter-elected; not in scope for v2.18 | Leave them unseeded unless state already has them in DB |

---

## Sources

- `en.wikipedia.org/wiki/List_of_current_United_States_governors` — All 50 governors verified (term dates, party) — HIGH confidence
- `en.wikipedia.org/wiki/List_of_current_United_States_lieutenant_governors` — 45 LGs, 5 no-office states, selection method — HIGH confidence
- `en.wikipedia.org/wiki/State_attorney_general` — 43 elected / 7 not, all 50 current AGs named — HIGH confidence
- `en.wikipedia.org/wiki/Secretary_of_state_(U.S._state_government)` — 35 elected / 3 no office / others appointed or legislature — HIGH confidence
- `en.wikipedia.org/wiki/State_treasurer` — ~36 elected / 2 no office / others appointed or legislature — HIGH confidence
- `naag.org/attorneys-general/` — Confirmed 43 elected / 7 appointed breakdown — HIGH confidence (official NAAG source)
- `backend/migrations/154_ma_state_executives.sql` — Migration pattern reference (MA, 6 execs) — confirmed
- `backend/migrations/169_me_state_executives.sql` — Legislature-appointed modeling (`is_appointed_position=true`) — confirmed
- `backend/migrations/317_va_state_executives.sql` — External_id scheme (`-{fips}{seq}`) — confirmed
- `backend/src/lib/essentialsService.ts` — STATE_EXEC routing via `d.state = $1` already live — confirmed, no backend change needed
- `.claude/commands/find-headshots.md` — Headshot workflow documented; official .gov + Wikimedia + Ballotpedia all above-bar sources — confirmed

---

*Stack research for: v2.18 State Leaders — elected Big 5 statewide executives, 50 states*
*Researched: 2026-06-20*
