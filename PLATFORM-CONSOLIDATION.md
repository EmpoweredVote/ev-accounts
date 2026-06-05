# Empowered Vote Platform Consolidation Plan

**Goal:** Merge all Empowered Vote backend services into a single database, a single API server, and a single auth system.

**Date:** 2026-03-19
**Status:** Planning

---

## Part 1: The Big Picture (Plain English)

### Why Are We Doing This?

Right now, Empowered Vote has its data spread across **four separate databases** and **two different API servers** written in **two different programming languages**:

- **EV-Backend** (Go) has its own database with compass quizzes, politician profiles, geofence boundaries, budget data, meeting transcripts, and its own user accounts.
- **ev-accounts** (TypeScript/Express) has a separate database with a completely different user account system, plus its own copy of compass data, XP, gems, tiers, and invite codes.
- **Validation Quests** has yet another database for quiz verification data.
- **Civic Trivia** has its own database for trivia questions and player scores.

This happened naturally — each feature was built independently with AI assistance, and each time, a new project was created from scratch with its own database. There was no "master plan" for how they'd connect.

The problem is that all of these features need to share the same users and the same politician data. When a user answers compass questions, earns XP from trivia, confirms stances in validation quests, and looks up their representatives in essentials — that's all one person doing related things. But right now, each system thinks of them as a different user (or doesn't know about them at all).

### What's Wrong With Multiple Databases?

**Imagine a filing cabinet analogy.** You have four filing cabinets in four different buildings. Each one has its own folder for "Chris Andrews" — but they don't talk to each other. If Chris changes his address in one building, the other three still have the old address. If Chris earns a gold star in Building A, Building B has no idea.

That's your current setup. Specifically:

1. **Duplicated data, diverging truths.** Compass topics exist in both EV-Backend and ev-accounts. If someone edits a topic in one, the other is now wrong. Politicians exist in both places with different levels of detail.

2. **No shared identity.** A user who signed up via the Go backend can't use that account in Civic Trivia or Validation Quests (which use ev-accounts). They'd need to sign up again.

3. **Security gaps.** The Go backend has no Row Level Security (RLS) — a database-level protection that prevents one user from seeing another user's data even if there's a bug in the code. ev-accounts has RLS on every table. Your users' political views (compass answers) are currently stored in the less-protected system.

4. **Double the maintenance.** Two servers to monitor, two sets of deploy pipelines, two sets of environment variables, two sets of CORS configurations, two SSL certificates to manage. When something breaks at 2am, you have twice as many places to look.

5. **Impossible integrations.** You can't build a feature like "show me how my compass answers compare to my local representatives" without the compass data and the essentials data being in the same database. Right now that requires an HTTP call between two servers, with all the latency and failure modes that introduces.

### What Does "Consolidation" Mean?

We're going to:
1. **Pick one database** (ev-accounts' Supabase project) and move everything into it
2. **Pick one API server** (ev-accounts' Express server) and port the Go endpoints into it over time
3. **Pick one auth system** (Supabase JWT, already used by ev-accounts, Trivia, and VQ) and retire the Go session-cookie auth

### Why ev-accounts Wins

| Factor | EV-Backend (Go) | ev-accounts (Express) | Winner |
|--------|-----------------|----------------------|--------|
| Auth system | Custom session cookies | Supabase JWT (industry standard) | ev-accounts |
| Security (RLS) | None | Every table protected | ev-accounts |
| Security (encryption) | None | AES-256 for location data | ev-accounts |
| Security (rate limiting) | None | Auth + invite endpoints | ev-accounts |
| Security (audit logging) | None | Full admin audit trail | ev-accounts |
| Other services already use it | No | Trivia + VQ both delegate auth here | ev-accounts |
| Supabase SDK support | Go (limited) | TypeScript (first-class) | ev-accounts |
| Input validation | Basic null checks | Zod schema validation | ev-accounts |
| Helmet/security headers | None | Full suite | ev-accounts |

The Go backend does some things well (essentials geofence matching, legislative data pipelines), but those are features to port, not reasons to keep a separate server.

### Is One Database Safe?

Yes — and it's actually **safer** than what you have now. Here's why:

**Row Level Security (RLS)** is like having a security guard on every table in the database. Even if your application code has a bug that forgets to check "is this user allowed to see this data?", the database itself will block the unauthorized access. Your Go backend currently has no RLS — if a bug skips the session middleware, the database happily returns everything.

**Encrypted location data** stays encrypted. ev-accounts already encrypts user coordinates with AES-256 using a key stored in Supabase Vault (a secrets manager). The raw lat/lng never exists in plaintext in the database. Even if someone got access to the database, they'd see encrypted blobs, not addresses.

**One auth system means one attack surface.** Right now you have two systems that could be compromised independently. With one system, you have one set of security practices to get right and one place to patch.

**Schema isolation provides separation.** Even though everything is in one database, each feature lives in its own schema (`essentials.*`, `compass.*`, `trivia.*`). Schemas are like folders — you can set permissions on each one independently. The trivia system can't accidentally read compass answers.

### What About Scalability?

At your current scale (dev team only, no public users yet), a single Supabase PostgreSQL instance can handle everything effortlessly. PostgreSQL is used by companies with millions of users. You are nowhere near needing multiple databases for performance reasons.

When/if you reach a scale where the database becomes a bottleneck, the correct solution is read replicas and connection pooling — not separate databases per feature. Supabase supports both.

The microservices pattern (many small servers, each with their own database) is designed for large organizations where different teams need to deploy independently. With a small team building with AI, it adds complexity without any of the benefits.

---

## Part 1B: Response to Integration Docs (Counterproposal)

Two integration documents have been written to guide how CompassV2 and Essentials connect to the ev-accounts API:

- **COMPASSV2-INTEGRATION.md** — How CompassV2 authenticates and uses compass endpoints via ev-accounts
- **ESSENTIALS-INTEGRATION.md** — How Essentials uses jurisdiction, auth, and XP/gem awards via ev-accounts

Both documents are well-written, with clear endpoint contracts, good anti-pattern warnings, and solid code examples. This section explains where we agree, where we propose changes, and why — so both developers are aligned before implementation begins.

### What We Agree On (Keep As-Is)

These aspects of both integration docs are correct and should be implemented as written:

**Auth model — unanimous agreement.**
- Supabase JWT with Bearer tokens (not session cookies)
- Auth Hub redirect flow (apps don't handle login/signup directly)
- Token in URL hash fragment (not query parameter) for security
- `localStorage` for token storage under `ev_token`
- 401 AUTH_ERROR → clear token → redirect to Auth Hub
- No refresh token flow for external apps

**Tier architecture — unanimous agreement.**
- Three tiers: Inform / Connected / Empowered
- Tier detected from `me.tier` field in `/api/account/me`
- Inform users get full read access to all public data
- Connected users get persistence, XP, gems, jurisdiction
- Empowered users behave like Connected for most features

**Jurisdiction principle — unanimous agreement.**
- Never ask a Connected user for their address
- Jurisdiction auto-populates from `/api/account/me`
- Null jurisdiction → show address/ZIP input (same as Inform)
- Location consent is managed exclusively by the accounts app

**Essentials access states (ESSENTIALS-INTEGRATION.md Section 4) — unanimous agreement.**
- Inform: full anonymous experience with address/ZIP input
- Connected with jurisdiction: auto-populated locality
- Connected without jurisdiction: treat like Inform for location UI
- XP/gem awards are additive, not gating

**Error handling — unanimous agreement.**
- Parse `code`, never `message`
- Error code reference table is correct
- Idempotency keys on all award calls

**Compass guest state migration (COMPASSV2-INTEGRATION.md Section 8) — agree with concern.**
- The `guest_state` URL parameter approach works for small payloads
- Concern: a user with 20+ answers and write-ins could exceed URL length limits (~2KB)
- Proposal: if `guest_state` exceeds 1500 characters, store in `sessionStorage` and pass a `guest_state=session` flag instead, with the Auth Hub reading from `sessionStorage` (same origin not required — but this needs Auth Hub cooperation). Alternative: accept the URL length limit and truncate to most recent N answers.

### Where We Diverge: Full Consolidation to Express

**The integration docs implicitly assume two API servers will continue to exist.** The Essentials doc references only 5 ev-accounts endpoints and leaves the core essentials features (PostGIS address search, politician profiles, legislative data) unaddressed. The Compass doc focuses on the ev-accounts compass endpoints but doesn't mention what happens to the Go backend's additional compass endpoints (compare, verdicts, admin CRUD).

**We propose retiring the Go backend entirely and porting all endpoints to the ev-accounts Express server.** Here's why this matters for both integration docs:

#### Why Not Keep the Go Backend Running?

The integration docs work fine if we assume "ev-accounts handles auth/accounts, EV-Backend handles everything else." But that assumption has real costs:

**1. Two servers means two points of failure.**
When something breaks, you're checking two sets of Render logs, two sets of environment variables, two CORS configurations. At 2am, you want one place to look.

**2. The Go backend has no security protections.**
We audited both codebases. The Go backend has:
- No Row Level Security (RLS) — if a bug skips session middleware, the database returns all data to anyone
- No rate limiting on any endpoint (including login)
- No security headers (no Helmet, no HSTS, no CSP)
- No audit logging for admin actions
- No input validation beyond null checks

The ev-accounts Express server has all of these. Every table has RLS. Auth endpoints have rate limiting. Helmet provides security headers. Admin actions are audit-logged. Inputs are validated with Zod schemas. Location data is AES-256 encrypted with Vault-managed keys.

Users' political views (compass answers) and home addresses are sensitive data. They should be served by the more secure system.

**3. TypeScript + Supabase is a better fit.**
Supabase's first-class SDK is JavaScript/TypeScript. Auto-generated types, RLS-aware client, built-in auth helpers. In Go, we're using GORM with raw connection strings and getting none of these benefits. The PostGIS queries that seem like they need Go are actually just SQL — they run identically whether sent from Go or TypeScript:

```typescript
// The "complex PostGIS query" in Express — same SQL, same performance
const { data } = await supabase.rpc('find_politicians_by_location', {
  p_lat: lat,
  p_lng: lng,
});
```

**4. One language means AI assistance works better.**
When we ask AI to build a feature that touches auth + compass + essentials, it needs to understand one codebase in one language, not two codebases in two languages with different patterns, different ORMs, and different middleware conventions.

**5. One Render bill instead of two+.**
Each Render web service has a base cost. We're paying for two API servers when one would do.

#### Impact on COMPASSV2-INTEGRATION.md

The Compass integration doc is **almost entirely correct as-is**. The auth flow, endpoint shapes, tier behavior, and error handling all stay the same. Changes needed:

| Section | Current Doc | Proposed Change |
|---------|------------|-----------------|
| Endpoint table (Section 1) | 16 endpoints listed | Add ~11 missing endpoints (compare, verdicts, admin CRUD) currently only in Go backend |
| Value range | States 0.5–5.5 | Correct, but ev-accounts' `compass_stances` CHECK constraint currently says 1–5. Needs migration to update to 0.5–5.5 |
| Politician type (Section 4) | Minimal: id, names, office_title, photo_url | Expand to include district_type, district_id, representing_state, and other fields CompassV2 currently uses from the Go backend's politician response |
| Guest state (Section 8) | URL parameter | Add size limit guidance or alternative transport for large payloads |

**Missing endpoints that need to be added to ev-accounts:**

```
Comparison:
  POST /api/compass/compare                    — user vs. politician similarity score

Read & Rank:
  GET  /api/compass/verdicts                   — user's quote verdicts
  POST /api/compass/verdicts                   — create/update verdict

Admin (topic management):
  POST  /api/compass/topics/create             — create topic with stances
  PATCH /api/compass/topics/update             — update topic metadata
  DELETE /api/compass/topics/delete/:id        — delete topic (cascades)
  PATCH /api/compass/stances/update            — update/add/remove stances
  PATCH /api/compass/topics/categories/update  — manage topic-category links

Admin (politician data):
  POST /api/compass/politicians/context        — add/update reasoning + sources
  PUT  /api/compass/politicians/:id/answers    — upsert politician stance answers

Batch:
  POST /api/compass/politicians/:id/answers/batch — batch fetch politician answers
```

#### Impact on ESSENTIALS-INTEGRATION.md

The Essentials integration doc has a **significant gap**: it only covers 5 endpoints — the ones that already exist on ev-accounts. The core essentials features (the reason the app exists) aren't addressed:

**Endpoints that need to be built in ev-accounts Express:**

```
Address Search (core feature):
  GET /api/essentials/address-search?address=...
    → Google Maps geocode → PostGIS ST_Intersects → matched politicians
    → This is the main user-facing feature of Essentials

Politician Profiles:
  GET /api/essentials/politicians/:id
    → Full profile: bio, education, experience, contacts, photos, endorsements

Legislative Data:
  GET /api/essentials/politicians/:id/legislative
    → Bills sponsored, votes cast, committee memberships
  GET /api/essentials/politicians/:id/committees
  GET /api/essentials/politicians/:id/bills
  GET /api/essentials/politicians/:id/votes

Supporting Data:
  GET /api/essentials/governments/:id
  GET /api/essentials/chambers/:id
  GET /api/essentials/districts/:id
```

**The integration doc should be updated to include these endpoints** once they're ported to Express. The auth, jurisdiction, and XP/gem sections remain correct.

#### Impact on Politician Data

Both integration docs reference politicians, but they assume different data sources:

- **Compass doc** references `inform.politicians` (ev-accounts) — minimal records for stance comparison
- **Essentials doc** references `essentials.politicians` (EV-Backend) — full records with 35 related tables
- **These are different tables with different UUIDs for the same people**

After consolidation, there will be **one politician table: `essentials.politicians`**. The compass stance data (`inform.politician_answers`, `inform.politician_context`) will FK to `essentials.politicians` instead of `inform.politicians`. Both integration docs should reference the same politician IDs.

This means:
- The Compass `Politician` type gains richer fields (district_type, bio, contacts, etc.)
- The Essentials politician endpoints return the same IDs that compass uses for comparison
- A user can look up their rep in Essentials, then see that same rep's compass stances — same ID, no mapping

### Summary of Proposed Changes to Integration Docs

| Document | What Stays | What Changes |
|----------|-----------|-------------|
| **COMPASSV2-INTEGRATION.md** | Auth flow, tier behavior, error handling, jurisdiction principle, guest state migration, all existing endpoint contracts | Add ~11 missing endpoints. Expand Politician type. Fix value range constraint. Add size guidance for guest_state. |
| **ESSENTIALS-INTEGRATION.md** | Auth flow, access states, jurisdiction principle, XP/gem awards, error handling, detection pattern | Add ~10 core endpoints (address search, profiles, legislative). Reference essentials.politicians (not inform.politicians). Document PostGIS query pattern. |
| **Both** | Token lifecycle, anti-patterns, checklist structure | Update base URL to `api.empowered.vote` after DNS cutover (Phase 7). Reference single politician ID space. |

### What We're Asking the Other Developer

1. **Review this consolidation plan.** Does the reasoning for one database + one Express server make sense?
2. **Update the integration docs** to include the missing endpoints once they're built.
3. **Coordinate on politician ID unification** — the bridge table approach (Phase 2 of this plan) needs input from whoever manages the `inform.politicians` data.
4. **Coordinate on the `compass_stances` value range** — the CHECK constraint needs to change from `1–5` to `0.5–5.5`. This is a migration on the ev-accounts database.
5. **Confirm whether `guest_state` URL size is a concern** — if the Auth Hub can handle large redirect URLs, the current approach works. If not, we need an alternative transport.

---

## Part 2: Current Inventory

### Databases (4 Supabase Projects)

#### Database A: EV-Backend (Project: kxsdzaojfaibhuzmclfq)
| Schema | Tables | Purpose | Needs Migration |
|--------|--------|---------|----------------|
| `app_auth` | 2 | Session-based auth (users, sessions) | **DROP** — replaced by Supabase Auth |
| `compass` | 7 | Topics, stances, answers, contexts, verdicts, user_compasses | **DROP** — already rebuilt in ev-accounts `inform` schema |
| `essentials` | 35 | Politicians, offices, districts, geofences, legislative data, images, contacts, endorsements, quotes | **MIGRATE** to ev-accounts |
| `staging` | 6 | Volunteer data entry with review workflow | **MIGRATE** to ev-accounts |
| `treasury` | 4 | Municipal budget data (cities, budgets, categories, line items) | **MIGRATE** to ev-accounts |
| `meetings` | 7 | CouncilScribe (meetings, speakers, segments, summaries, votes) | **MIGRATE** to ev-accounts |

**Total: 61 tables. Drop 9, migrate 52.**

#### Database B: ev-accounts (Target — already exists)
| Schema | Tables | Purpose |
|--------|--------|---------|
| `public` | ~10 | Supabase Auth integration, roles, admin, notifications |
| `connect` | 9 | Connected tier profiles, gems, XP, invites, social |
| `empower` | 4 | Empowered tier profiles, consent |
| `inform` | 14 | Compass topics/stances/responses, politicians, politician_answers, politician_context, district_boundaries |

**Total: ~37 tables. These stay as-is.**

#### Database C: Validation Quests (Separate Supabase)
| Schema | Tables | Purpose |
|--------|--------|---------|
| `validation_quests` | 14 | Quests, submissions, consensus, veracity profiles |

**Total: 14 tables. Migrate to ev-accounts.**

#### Database D: Civic Trivia (Project: kxsdzaojfaibhuzmclfq — shares with EV-Backend!)
| Schema | Tables | Purpose |
|--------|--------|---------|
| `trivia` | 9 | Topics, collections, questions, player stats, election races |

**Note:** Trivia is already in the same Supabase project as EV-Backend. It migrates with the rest.

### API Servers (2 on Render)

| Server | URL | Language | Modules |
|--------|-----|----------|---------|
| EV-Backend | api.empowered.vote | Go | essentials, compass, treasury, staging, meetings, auth |
| ev-accounts | ev-accounts-api.onrender.com | Express/TS | auth, accounts, compass, tiers, XP, gems, invites, roles, social, admin, candidates, essentials (basic), VQ integration |

### Frontend Apps (6+ on Cloudflare Pages)

| App | Current API | Auth Method | Changes Needed |
|-----|------------|-------------|---------------|
| CompassV2 | api.empowered.vote | Session cookies | Switch to Bearer tokens + ev-accounts API |
| Essentials | api.empowered.vote | Session cookies | Switch to Bearer tokens + ev-accounts API |
| Read & Rank | api.empowered.vote | Session cookies | Switch to Bearer tokens + ev-accounts API |
| Treasury Tracker | api.empowered.vote | None (public data) | Point to ev-accounts API |
| Civic Trivia | ev-accounts-api | Bearer tokens | No auth changes needed |
| Validation Quests | ev-accounts-api | Bearer tokens | No auth changes needed |
| ev-accounts app | ev-accounts-api | Bearer tokens | No changes needed |

---

## Part 3: Migration Phases

### Overview

```
Phase 0: Preparation & Backup
Phase 1: Database Migration (move schemas into ev-accounts Supabase)
Phase 2: Resolve Politician Table Duplication
Phase 3: Port Go Endpoints to Express (essentials, treasury, staging, meetings)
Phase 4: Update Frontend Apps (CompassV2, Essentials, Read & Rank, Treasury)
Phase 5: Add Missing Compass Endpoints to ev-accounts
Phase 6: Retire EV-Backend
Phase 7: DNS Cutover (api.empowered.vote → ev-accounts)
```

---

### Phase 0: Preparation & Backup

**What's happening (plain English):**
Before we move anything, we take a complete snapshot of both databases. This is like photocopying every page in both filing cabinets before we start reorganizing. If anything goes wrong, we can always restore from the backup.

**Technical steps:**

0.1. **Snapshot both Supabase projects**
- Use Supabase dashboard to create a point-in-time backup of both projects
- Also export with `pg_dump` for portable backups:
  ```bash
  # From EV-Backend's database
  pg_dump --schema=essentials --schema=staging --schema=treasury --schema=meetings \
    --no-owner --no-privileges \
    -f ev-backend-export.sql \
    "$EV_BACKEND_DATABASE_URL"

  # From Trivia's tables (same database as EV-Backend)
  pg_dump --schema=trivia \
    --no-owner --no-privileges \
    -f trivia-export.sql \
    "$EV_BACKEND_DATABASE_URL"

  # From Validation Quests' database
  pg_dump --schema=validation_quests \
    --no-owner --no-privileges \
    -f vq-export.sql \
    "$VQ_DATABASE_URL"
  ```

0.2. **Document current connection strings**
- Record all `DATABASE_URL` values from Render dashboards for EV-Backend, VQ, and Trivia
- Record the ev-accounts Supabase project connection string (this is the target)

0.3. **Verify ev-accounts Supabase plan**
- Check storage limits — essentials has PostGIS geofence data which can be large
- Ensure PostGIS extension is enabled (`CREATE EXTENSION IF NOT EXISTS postgis`)
- Ensure pgcrypto is enabled (for existing encryption functions)

0.4. **Create a migration branch**
- Branch each repo that will be modified: `git checkout -b consolidation/phase-N`

**Exit criteria:** Backups verified, ev-accounts Supabase has required extensions, all connection strings documented.

---

### Phase 1: Database Migration

**What's happening (plain English):**
We're moving the filing cabinets. The essentials data (politicians, districts, geofences), treasury data (budgets), staging data (volunteer entries), and meetings data (CouncilScribe) all move from the EV-Backend database into the ev-accounts database. We're also moving Validation Quests and Trivia data.

We are NOT moving the old `compass` or `app_auth` schemas — ev-accounts already has better versions of both.

Think of it like moving offices: we're carrying the furniture (essentials, treasury, staging, meetings) to the new building, but leaving behind the old reception desk (app_auth) and the old conference room (compass) because the new building already has nicer ones.

**Technical steps:**

1.1. **Create schemas in ev-accounts Supabase**
```sql
-- Run against ev-accounts database
CREATE SCHEMA IF NOT EXISTS essentials;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS treasury;
CREATE SCHEMA IF NOT EXISTS meetings;
CREATE SCHEMA IF NOT EXISTS validation_quests;
-- trivia schema likely already exists if Trivia was on same Supabase project
CREATE SCHEMA IF NOT EXISTS trivia;
```

1.2. **Enable required extensions**
```sql
CREATE EXTENSION IF NOT EXISTS postgis;           -- for essentials geofences
CREATE EXTENSION IF NOT EXISTS pgcrypto;          -- for UUIDs
CREATE EXTENSION IF NOT EXISTS pg_trgm;           -- if used for text search
```

1.3. **Import schemas (structure only, then data)**

Option A — pg_dump/pg_restore (recommended for large datasets like geofences):
```bash
# Structure only first
pg_dump --schema=essentials --schema-only --no-owner --no-privileges \
  -f essentials-structure.sql "$EV_BACKEND_DATABASE_URL"

# Then import to ev-accounts
psql "$EV_ACCOUNTS_DATABASE_URL" < essentials-structure.sql

# Then data
pg_dump --schema=essentials --data-only --no-owner \
  -f essentials-data.sql "$EV_BACKEND_DATABASE_URL"

psql "$EV_ACCOUNTS_DATABASE_URL" < essentials-data.sql
```

Repeat for `staging`, `treasury`, `meetings`, `trivia`, `validation_quests`.

Option B — Supabase migration files (better for reproducibility):
- Convert GORM model definitions to CREATE TABLE SQL statements
- Write as numbered Supabase migration files
- Run via `supabase db push` or `supabase migration up`

**Recommendation:** Use Option A for the initial data move (faster, handles PostGIS geometry columns correctly), then write Supabase migration files that document the schema for future reference.

1.4. **Verify data integrity**
```sql
-- Run count checks on both databases
-- EV-Backend (source)
SELECT 'politicians' as tbl, COUNT(*) FROM essentials.politicians
UNION ALL SELECT 'offices', COUNT(*) FROM essentials.offices
UNION ALL SELECT 'districts', COUNT(*) FROM essentials.districts
-- ... etc for all tables

-- ev-accounts (target) — same queries, compare counts
```

1.5. **Set up RLS policies for new schemas**

This is critical — the migrated schemas currently have NO RLS. We need to add it.

```sql
-- Essentials: public read (politicians are public officials)
ALTER TABLE essentials.politicians ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_politicians" ON essentials.politicians
  FOR SELECT TO anon, authenticated USING (true);

-- Staging: authenticated users only, with role checks
ALTER TABLE staging.stances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_read_staging" ON staging.stances
  FOR SELECT TO authenticated USING (true);
-- Write policies: restrict to admin/reviewer roles

-- Treasury: public read (government budget data)
ALTER TABLE treasury.budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_budgets" ON treasury.budgets
  FOR SELECT TO anon, authenticated USING (true);

-- Meetings: public read (government meetings are public record)
ALTER TABLE meetings.meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_meetings" ON meetings.meetings
  FOR SELECT TO anon, authenticated USING (true);
```

1.6. **Set up GRANT permissions**
```sql
-- Public data schemas
GRANT USAGE ON SCHEMA essentials TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA essentials TO anon, authenticated;

GRANT USAGE ON SCHEMA treasury TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA treasury TO anon, authenticated;

GRANT USAGE ON SCHEMA meetings TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA meetings TO anon, authenticated;

-- Restricted schemas (API server writes only, via service role)
GRANT USAGE ON SCHEMA staging TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO authenticated;
-- INSERT/UPDATE/DELETE only via service role (API server)
```

**Exit criteria:** All tables exist in ev-accounts database with correct data, row counts match source, RLS enabled on all tables, GRANT permissions set.

---

### Phase 2: Resolve Politician Table Duplication

**What's happening (plain English):**
Right now there are two lists of politicians: a detailed one in essentials (with photos, bios, legislative records, district boundaries — 35 related tables) and a simple one in ev-accounts' inform schema (just names, titles, and compass stances). We need to merge these into one authoritative list.

Think of it like having two contact lists for the same people — one has full profiles with photos and employment history, the other just has names and phone numbers. We keep the full one and make the phone numbers point to it.

**Technical steps:**

2.1. **Audit the two politician tables**

```
essentials.politicians (from EV-Backend):
  - UUID primary key
  - Full bio: first_name, last_name, bio_text, slug, total_years_in_office
  - Linked to: offices, chambers, districts, geofences, images, contacts,
    degrees, experiences, endorsements, legislative data
  - ~791+ records (LA County + Bloomington + federal/state)

inform.politicians (from ev-accounts):
  - UUID primary key (different UUIDs than essentials)
  - Minimal: first_name, last_name, preferred_name, full_name, office_title,
    photo_origin_url, is_active, district_type, representing_city/state
  - Linked to: politician_answers, politician_context
  - Likely fewer records (only those with compass stances)
```

2.2. **Create ID mapping table**

Since the two tables use different UUIDs for the same politicians, we need a mapping:

```sql
CREATE TABLE public.politician_id_bridge (
  essentials_id UUID REFERENCES essentials.politicians(id),
  inform_id UUID REFERENCES inform.politicians(id),
  matched_by TEXT,  -- 'name', 'manual', 'bioguide_id'
  PRIMARY KEY (essentials_id, inform_id)
);
```

Match algorithm:
- First pass: exact match on (first_name, last_name, office_title)
- Second pass: fuzzy match on name variants (preferred_name, etc.)
- Third pass: manual review of unmatched records

2.3. **Migrate compass stance data to use essentials IDs**

```sql
-- Update politician_answers to reference essentials.politicians
-- Using the bridge table
UPDATE inform.politician_answers pa
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pa.politician_id = bridge.inform_id;

-- Same for politician_context
UPDATE inform.politician_context pc
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pc.politician_id = bridge.inform_id;
```

2.4. **Update foreign keys**

```sql
-- Drop old FK to inform.politicians
ALTER TABLE inform.politician_answers
  DROP CONSTRAINT IF EXISTS politician_answers_politician_id_fkey;

-- Add new FK to essentials.politicians
ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

-- Same for politician_context
-- Same for empower.empowered_profiles (politician_id column)
-- Same for connect.vq_confirmation_results (politician_id column)
```

2.5. **Drop inform.politicians**

Once all references point to essentials.politicians:
```sql
DROP TABLE inform.politicians;
```

2.6. **Add compass-specific columns to essentials.politicians if needed**

ev-accounts' `inform.politicians` had some columns that `essentials.politicians` might not:
- `is_vacant` — add if not present
- `district_label`, `chamber_name`, `chamber_name_formal`, `government_name` — check if these exist in essentials via related tables (offices, chambers, governments) rather than denormalized columns

**Exit criteria:** Single `essentials.politicians` table. All compass answers, context, VQ confirmations, and empowered profiles reference it. `inform.politicians` dropped.

---

### Phase 3: Port Go Endpoints to Express

**What's happening (plain English):**
The Go server currently handles requests for politician lookup, budget data, volunteer data entry, and meeting transcripts. We need the Express server (ev-accounts) to handle these instead. This is like training a new employee to do everything the departing employee does — we go through each responsibility one by one.

This is the largest phase and can be done incrementally, one module at a time. The Go server stays running during this phase — we port one module, verify it works, then move to the next.

**Port order (by complexity, simplest first):**

#### 3.1 Treasury (4 tables, ~5 endpoints, read-only)

Treasury is the simplest — it's public budget data with no auth requirements.

**Go endpoints to replicate:**
```
GET  /treasury/cities           → list all cities
GET  /treasury/cities/:id       → single city
GET  /treasury/budgets          → budgets for a city/year
GET  /treasury/categories       → budget categories
GET  /treasury/line-items       → line items for a category
```

**Express implementation:**
- Create `backend/src/routes/treasury.ts`
- Create `backend/src/lib/treasuryService.ts`
- All endpoints use `optionalAuth` middleware (public data)
- Query via Supabase client (anon key, RLS allows public read)
- Mount at `/api/treasury/*` in index.ts

**LLM task prompt:**
```
Port the treasury module from EV-Backend (Go) to ev-accounts (Express/TypeScript).

Source: /EV-Backend/internal/treasury/
- models.go defines: City, Budget, BudgetCategory, BudgetLineItem
- handlers.go has the endpoint logic
- routes.go has the route definitions

Target: /ev-accounts/backend/src/
- Create routes/treasury.ts and lib/treasuryService.ts
- Follow the patterns in existing routes (e.g., compass.ts)
- Use Supabase client for queries (not raw SQL)
- All endpoints are public read (use optionalAuth or no auth)
- Tables are in the 'treasury' schema
- Mount on /api/treasury in index.ts

Write a Supabase migration file for the treasury schema if one doesn't exist yet.
```

#### 3.2 Meetings (7 tables, ~8 endpoints, read-only + admin write)

**Go endpoints to replicate:**
```
GET  /meetings                  → list meetings
GET  /meetings/:id              → single meeting with segments
GET  /meetings/:id/summary      → meeting summary
GET  /meetings/:id/speakers     → speakers in a meeting
GET  /meetings/:id/votes        → votes from a meeting
POST /meetings                  → create meeting (admin)
POST /meetings/:id/summary      → generate/save summary (admin)
```

**LLM task prompt:**
```
Port the meetings module from EV-Backend (Go) to ev-accounts (Express/TypeScript).

Source: /EV-Backend/internal/meetings/
Target: /ev-accounts/backend/src/routes/meetings.ts + lib/meetingsService.ts

Models: Meeting, Speaker, Segment, MeetingSummary, SummarySection, Vote, VoteRecord
All GET endpoints are public. POST/PUT endpoints require admin auth.
Follow existing patterns in ev-accounts routes.
Tables are in the 'meetings' schema.
```

#### 3.3 Staging (6 tables, ~15 endpoints, auth required)

Staging has more complexity — it includes a review workflow with approval states, locking mechanisms, and role-based access.

**Go endpoints to replicate:**
```
GET    /staging/stances              → list stances (with filters)
POST   /staging/stances              → create stance
PATCH  /staging/stances/:id          → update stance
DELETE /staging/stances/:id          → delete stance
POST   /staging/stances/:id/lock     → acquire edit lock
POST   /staging/stances/:id/review   → submit review decision
GET    /staging/politicians           → list staging politicians
POST   /staging/politicians           → create politician
PATCH  /staging/politicians/:id       → update politician
POST   /staging/politicians/:id/review → submit review decision
GET    /staging/building-photos       → list building photos
POST   /staging/building-photos       → create building photo
PATCH  /staging/building-photos/:id   → update building photo
POST   /staging/building-photos/:id/review → submit review decision
```

**LLM task prompt:**
```
Port the staging module from EV-Backend (Go) to ev-accounts (Express/TypeScript).

Source: /EV-Backend/internal/staging/
Target: /ev-accounts/backend/src/routes/staging.ts + lib/stagingService.ts

Key behaviors:
- Review workflow: draft → needs_review → approved (requires 2 approvals)
- 10-minute locking mechanism for concurrent editing
- All endpoints require authentication
- Review/approve endpoints require admin role
- Tables are in the 'staging' schema

Follow existing patterns. Use requireAuth/requireAdmin middleware.
```

#### 3.4 Essentials (35 tables, ~25 endpoints, most complex)

Essentials is the most complex module — PostGIS geofence matching, multiple data import pipelines, legislative data.

**Go endpoints to replicate (main user-facing ones):**
```
GET  /essentials/address-search     → Google Maps → PostGIS geofence → politicians
GET  /essentials/politicians/:id    → full politician profile
GET  /essentials/politicians/:id/legislative → legislative record
GET  /essentials/politicians/:id/committees  → committee memberships
GET  /essentials/politicians/:id/bills       → sponsored/cosponsored bills
GET  /essentials/politicians/:id/votes       → voting record
GET  /essentials/governments/:id    → government body details
GET  /essentials/chambers/:id       → chamber details
```

**Note:** ev-accounts already has basic essentials routes:
- `GET /api/essentials/politicians` — grouped by office_title
- `GET /api/essentials/candidates/:zip` — candidates by ZIP

These need to be expanded significantly to cover the full essentials feature set.

**Data import endpoints (admin/CLI only):**
```
POST /essentials/import/tiger       → import TIGER geofences
POST /essentials/import/congress    → import Congress.gov data
POST /essentials/import/legiscan    → import LegiScan data
POST /essentials/import/openstates  → import Open States data
```

**LLM task prompt:**
```
Port the essentials module from EV-Backend (Go) to ev-accounts (Express/TypeScript).

Source: /EV-Backend/internal/essentials/
Target: /ev-accounts/backend/src/routes/essentials.ts + lib/essentialsService.ts

This is the most complex module. Key concerns:
- PostGIS queries (ST_Intersects for geofence matching) — use raw SQL via Supabase rpc() or database.sql
- 35 related tables in the essentials schema
- Legislative data endpoints with multiple JOINs
- Data import pipelines (admin-only, can be separate CLI scripts)

ev-accounts already has basic routes in essentialsPoliticians.ts and essentialsCandidates.ts.
Expand these rather than creating new files.

Port user-facing endpoints first. Data import pipelines can remain as standalone scripts.
Tables are in the 'essentials' schema.
```

#### 3.5 Compass Additions (missing endpoints)

ev-accounts has most compass endpoints but is missing some that EV-Backend has:

```
POST /compass/compare               → compare user answers with politician
POST /compass/politicians/:id/answers/batch → batch fetch politician answers for specific topics
GET  /compass/verdicts               → Read & Rank quote verdicts
POST /compass/verdicts               → create verdict
PATCH /compass/topics/update         → admin: update topic
POST  /compass/topics/create         → admin: create topic with stances
PATCH /compass/stances/update        → admin: update stances
PATCH /compass/topics/categories/update → admin: manage topic categories
POST  /compass/politicians/context   → admin: add/update politician reasoning
PUT   /compass/politicians/:id/answers → admin: upsert politician answers
DELETE /compass/topics/delete/:id    → admin: delete topic
```

**LLM task prompt:**
```
Add missing compass endpoints to ev-accounts.

Source: /EV-Backend/internal/compass/handlers.go (reference implementation)
Target: /ev-accounts/backend/src/routes/compass.ts

Missing endpoints to add:
1. POST /compare — compare user answers with politician answers (returns similarity scores)
2. POST /politicians/:id/answers/batch — batch fetch politician answers for specific topic IDs
3. GET/POST /verdicts — Read & Rank quote verdicts (create verdict model + migration)
4. Admin CRUD: topic create/update/delete, stance update, category management, politician context/answers

The compass.ts file already has 11 endpoints. Add to it following the existing patterns.
Admin endpoints should use requireAdmin middleware.

Value range is 0.5-5.5 (step 0.5). Update the compass_stances CHECK constraint
from (1-5) to (0.5-5.5) via a new migration file.
```

**Exit criteria for Phase 3:** Every endpoint that currently exists on the Go server has an equivalent on the Express server. Both can be tested in parallel.

---

### Phase 4: Update Frontend Apps

**What's happening (plain English):**
Now that the Express server can handle everything, we need to tell the frontend apps to talk to it instead of the Go server. We also need to switch from the old login system (where the app sends a username and password directly) to the new one (where the app redirects to a central login page and gets back a token).

This is like changing the phone number everyone calls for customer service. The service is the same, but the number is different, and the way you identify yourself when you call has changed.

**Technical steps:**

4.1. **CompassV2** (largest change — has its own Login/Register pages)

Changes needed:
- Delete `src/pages/Login.jsx` and `src/pages/Register.jsx`
- Implement Auth Hub redirect flow per COMPASSV2-INTEGRATION.md (Section 3)
- Replace all `credentials: "include"` fetch calls with `Authorization: Bearer` headers
- Change `VITE_API_URL` from `https://api.empowered.vote` to `https://accounts.empowered.vote` (or new unified URL)
- Update CompassContext.jsx:
  - Replace session check (`/auth/me`) with token check + `/api/account/me`
  - Replace `handleLogin`/`handleRegister` with `handleAuthReturn()` (hash fragment extraction)
  - Keep localStorage for guest/Inform users (offline capability preserved)
  - Add token lifecycle management (store in localStorage, clear on AUTH_ERROR)
- Update routes: remove `/login`, `/register`, add auth redirect trigger
- Update Layout.jsx logout to call `POST /api/auth/logout` with Bearer token, then clear `ev_token`

**LLM task prompt:**
```
Integrate CompassV2 with the ev-accounts API using the COMPASSV2-INTEGRATION.md guide.

Key changes:
1. Remove Login.jsx and Register.jsx (auth is handled by Auth Hub redirect)
2. Create src/lib/auth.ts with:
   - handleAuthReturn() — extract token from URL hash fragment
   - getToken() — read from localStorage
   - redirectToAuthHub() — redirect to accounts.empowered.vote/login
   - clearAuth() — remove token, redirect to logged-out state
3. Create src/lib/api.ts with:
   - apiFetch(path, options) — adds Bearer token header automatically
   - Handles AUTH_ERROR (401) by clearing token and redirecting
4. Update CompassContext.jsx:
   - On mount: handleAuthReturn() ?? getToken(), then fetch /api/account/me
   - Replace isLoggedIn with user object from /account/me (includes tier)
   - Keep all localStorage logic for Inform (guest) users
   - POST /compass/answers returns null for guests — display locally, don't treat as error
5. Update all fetch() calls to use apiFetch()
6. Update VITE_API_URL to point to ev-accounts API
7. Keep offline/localStorage capability for Inform tier users

Reference: /CompassV2/COMPASSV2-INTEGRATION.md
Current code: /CompassV2/src/components/CompassContext.jsx
```

4.2. **Essentials app**

Changes needed:
- Replace `credentials: "include"` with Bearer token auth
- Change `VITE_API_URL` to ev-accounts API
- Keep address search as primary feature (endpoint path may change)
- Add optional auth — if user has token, send it (enables jurisdiction personalization)

4.3. **Read & Rank (EV-readrank)**

Changes needed:
- Replace auth to use Bearer tokens
- Change API base URL
- Verdict endpoints now at ev-accounts

4.4. **Treasury Tracker**

Changes needed:
- Change API base URL only (treasury is public data, no auth needed)
- Minimal change

**Exit criteria:** All frontend apps point to ev-accounts API, use Bearer token auth, no references to api.empowered.vote remain.

---

### Phase 5: Migrate Validation Quests & Trivia Databases

**What's happening (plain English):**
Validation Quests and Civic Trivia already talk to ev-accounts for auth, but their feature data (quests, trivia questions) lives in separate databases. We move that data into the main database too, so everything is in one place.

These apps already use JWT auth and the ev-accounts API for user identity — only the database connection for their own feature data needs to change.

**Technical steps:**

5.1. **Import schemas** (same pg_dump/pg_restore process as Phase 1)
```bash
# Validation Quests
pg_dump --schema=validation_quests --no-owner -f vq-export.sql "$VQ_DATABASE_URL"
psql "$EV_ACCOUNTS_DATABASE_URL" < vq-export.sql

# Trivia (if not already in same Supabase project)
pg_dump --schema=trivia --no-owner -f trivia-export.sql "$TRIVIA_DATABASE_URL"
psql "$EV_ACCOUNTS_DATABASE_URL" < trivia-export.sql
```

5.2. **Update DATABASE_URL on Render**
- VQ backend: change `SUPABASE_URL` and related vars to ev-accounts project
- Trivia backend: same

5.3. **Add RLS policies** for imported schemas

5.4. **Update foreign keys** to reference `essentials.politicians` where applicable (VQ has `politician_id` references)

**Exit criteria:** VQ and Trivia backends connect to the consolidated database. Feature functionality verified.

---

### Phase 6: Retire EV-Backend

**What's happening (plain English):**
The Go server has no more responsibilities. Every frontend now talks to the Express server. We turn off the Go server and stop paying for it.

**Technical steps:**

6.1. **Verify zero traffic to EV-Backend**
- Check Render metrics for api.empowered.vote
- Confirm no frontend is still calling it
- Search all frontend codebases for `api.empowered.vote` references

6.2. **Remove Render service**
- Scale Go backend to zero instances (don't delete yet — keep as rollback option)
- Monitor for 1 week
- Delete Render service

6.3. **Archive the EV-Backend repo**
- The Go code is now historical reference
- Don't delete — useful for understanding data import logic, pipeline configs, etc.

**Exit criteria:** Go server stopped, no traffic, archived.

---

### Phase 7: DNS Cutover

**What's happening (plain English):**
Right now, `api.empowered.vote` points to the Go server. We change it to point to the Express server so that the URL stays clean and professional.

**Technical steps:**

7.1. **Add `api.empowered.vote` as custom domain on ev-accounts Render service**
7.2. **Update Route 53 DNS** to point `api.empowered.vote` to the ev-accounts Render service
7.3. **Update CORS origins** in ev-accounts to include all subdomains
7.4. **Update all frontend `VITE_API_URL`** environment variables to use `api.empowered.vote`
7.5. **Update integration docs** — `accounts.empowered.vote/api` becomes `api.empowered.vote/api` (or keep both)

**Exit criteria:** `api.empowered.vote` serves ev-accounts Express API. All frontends use this URL.

---

## Part 4: Risk Mitigation

### What Could Go Wrong

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Data loss during migration | High | pg_dump backups before every phase; verify row counts |
| Politician ID mismatch | Medium | Bridge table + manual review; test compare features |
| PostGIS queries slower on new DB | Low | Same Supabase tier; benchmark address-search before/after |
| Frontend breaks during API switch | Medium | Hard switch is OK (dev team only); feature-flag if needed |
| Supabase project hits storage limit | Medium | Check plan limits before importing geofence data |
| RLS policies block legitimate queries | Medium | Test every endpoint after adding RLS; have service role fallback |

### Rollback Plan

Each phase has an independent rollback:
- **Phase 1:** Old database is untouched; just drop new schemas in ev-accounts
- **Phase 2:** Restore inform.politicians from backup
- **Phase 3:** Revert Express code; Go endpoints still work
- **Phase 4:** Revert frontend env vars back to api.empowered.vote
- **Phase 5-7:** Restart Go server, revert DNS

---

## Part 5: Post-Consolidation Architecture

### Final State

```
┌─────────────────────────────────────────────────────────┐
│  One Supabase Project                                   │
│                                                         │
│  auth.*              Supabase Auth (all users)          │
│  public.*            Roles, admin, notifications        │
│  connect.*           Connected tier, gems, XP, invites  │
│  empower.*           Empowered tier, consent            │
│  inform.*            Compass topics, stances, responses │
│  essentials.*        Politicians, geofences, legislative│
│  treasury.*          Budget data                        │
│  staging.*           Data entry workflow                 │
│  meetings.*          CouncilScribe                      │
│  validation_quests.* Quest data                         │
│  trivia.*            Trivia data                        │
│                                                         │
└────────────────────────┬────────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │  Express API        │
              │  api.empowered.vote │
              │                     │
              │  One server.        │
              │  One deploy.        │
              │  One auth system.   │
              │  One set of logs.   │
              └──────────┬──────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────┴────┐    ┌──────┴──────┐  ┌─────┴─────┐
   │Cloudflare│    │ Cloudflare  │  │Cloudflare │
   │ Pages    │    │ Pages       │  │ Pages     │
   │          │    │             │  │           │
   │CompassV2 │    │ Essentials  │  │ Trivia    │
   │ReadRank  │    │ Treasury    │  │ VQ        │
   │Badges    │    │             │  │ Accounts  │
   └──────────┘    └─────────────┘  └───────────┘
```

### What You Gain

- **One `DATABASE_URL`** to manage across all services
- **One set of RLS policies** protecting all user data
- **One auth flow** (Supabase JWT) for every app
- **One Render bill** instead of 3+
- **Foreign keys that actually work** across features
- **One place to look** when something breaks
- **Features can reference each other** — compass can show jurisdiction-relevant politicians, trivia can reference compass topics, VQ can link to essentials politician profiles

---

## Appendix A: Supabase Project Inventory

| Project | ID | Purpose After Consolidation |
|---------|----|-----------------------------|
| ev-accounts | (target) | **Primary** — all data lives here |
| EV-Backend / Trivia | kxsdzaojfaibhuzmclfq | **Archive** — pause or delete after migration |
| Validation Quests | (check dashboard) | **Archive** — pause or delete after migration |

## Appendix B: Environment Variables (Final State)

All services share these core vars (values differ per environment):

```
SUPABASE_URL=https://<ev-accounts-project>.supabase.co
SUPABASE_ANON_KEY=<ev-accounts anon key>
SUPABASE_SERVICE_ROLE_KEY=<ev-accounts service role key>
DATABASE_URL=postgresql://...<ev-accounts connection string>
```

## Appendix C: Files Modified Per Phase

### Phase 3 (Express porting) — new files:
```
ev-accounts/backend/src/routes/treasury.ts
ev-accounts/backend/src/routes/meetings.ts
ev-accounts/backend/src/routes/staging.ts
ev-accounts/backend/src/routes/essentials.ts (expand existing)
ev-accounts/backend/src/lib/treasuryService.ts
ev-accounts/backend/src/lib/meetingsService.ts
ev-accounts/backend/src/lib/stagingService.ts
ev-accounts/backend/src/lib/essentialsService.ts
ev-accounts/backend/src/index.ts (add route mounts)
ev-accounts/supabase/migrations/047_*.sql (treasury schema)
ev-accounts/supabase/migrations/048_*.sql (meetings schema)
ev-accounts/supabase/migrations/049_*.sql (staging schema)
ev-accounts/supabase/migrations/050_*.sql (essentials schema)
ev-accounts/supabase/migrations/051_*.sql (RLS policies)
```

### Phase 4 (Frontend updates) — modified files:
```
CompassV2/src/components/CompassContext.jsx (major rewrite)
CompassV2/src/pages/Login.jsx (DELETE)
CompassV2/src/pages/Register.jsx (DELETE)
CompassV2/src/App.jsx (remove login/register routes)
CompassV2/src/components/Layout.jsx (update logout)
CompassV2/src/lib/auth.ts (NEW)
CompassV2/src/lib/api.ts (NEW)
CompassV2/.env.production (update VITE_API_URL)
essentials/.env.production (update VITE_API_URL)
essentials/src/**/*.jsx (replace credentials:include with Bearer)
EV-readrank/.env.production (update VITE_API_URL)
treasury-tracker/.env.production (update VITE_API_URL)
```
