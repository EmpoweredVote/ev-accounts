# Empowered Vote — Strategy Onboarding
*Last updated: 2026-06-07*

---

## What We're Building

Empowered Vote is a civic engagement platform built around three pillars: **Inform** (transparent political data), **Connect** (structured civic deliberation), and **Empower** (verified civic advocacy). The account infrastructure ties them together — one identity, one voice, shared across all features.

---

## Account Tiers

| Tier | Who | What They Can Do |
|------|-----|-----------------|
| **Inform** | Anyone — no login required | Browse politicians, view compass stances, see Elections Central |
| **Connected** | Invited users (one human, one voice) | Take compass, build profile, access all Connect features |
| **Empowered** | Verified advocates | Enhanced trust, unlock red gem quests, contributor roles |

**Architecture rule:** Tier is determined by the existence of child DB records, never a status flag.

---

## Platform Core — ev-accounts

The backbone of the platform. Everything else integrates with it.

**Local:** `C:\EV-Accounts` | **GitHub:** https://github.com/EmpoweredVote/ev-accounts.git

| App | URL | Description |
|-----|-----|-------------|
| Auth Hub / Profile | login.empowered.vote | Signup, login, tier-aware profile page, compass, admin tools |
| Dashboard | app.empowered.vote | End-user dashboard, referrals, contributor portal |

**What it owns:** Auth, account tiers, XP/gem ledger, role system, location/district cache, politician + stance database, geofencing (TIGER), elections data.

---

## Feature Apps

### Empowered Compass (CompassV2)
**Status: Live**
**Local:** `C:\EV-CompassV2` | **GitHub:** https://github.com/EmpoweredVote/CompassV2

Users answer questions on 21 policy topics and compare their stances to politicians. Supports write-in answers, change history, and politician comparison. The frontend lives in CompassV2; the API and politician/stance database live in ev-accounts.

---

### Civic Trivia Championships (CTC)
**Status: Live**
**Local:** `C:\Transparent Motivations\essentials` | **GitHub:** https://github.com/EmpoweredVote/Civic-Trivia-Championships | **URL:** ctc.empowered.vote

Civic trivia game. Integrated with ev-accounts via API — correct answers award XP and yellow gems to the user's Connected account. Ranked mode and advanced formats unlock at higher XP levels.

---

### Empowered Quests (Validation Quests)
**Status: Live**
**Local:** `C:\Validation Quests` | **GitHub:** https://github.com/EmpoweredVote/empowered-validation-quests.git

Structured quests where users verify civic facts. Tied to the Verification Rating system (VR 0–150). Red gem quests unlock at VR 90+. XP source type `validation_quest` feeds the shared XP ledger in ev-accounts.

---

### Empowered Essentials (Transparent Motivations)
**Status: Active development**
**Local:** `C:\Transparent Motivations` | **GitHub:** https://github.com/EmpoweredVote/transparent-motivations.git

Surfaces the motivations and funding behind politician positions — connects politician stances to their donor networks, voting records, and stated reasoning. Consumes politician data from ev-accounts via `GET /api/essentials/politicians`.

---

### Issues in Focus (inside Focused Communities)
**Status: In development**
**Local:** `C:\Focused Communities` | **GitHub:** https://github.com/EmpoweredVote/focused-communities.git

Dedicated civic forums for single issues that have been ratified as Empowered Compass topics. Serves a dual role:
- **Connect hub:** Authenticated deliberation — argument mapping, badge ratification, scheduled debates/symposiums, evidence collection
- **Inform monitor:** Verifies politician stances against voting records; produces calibration data for Essentials

Requires Connected Account (one voice per person). Designed around "memory over moderation" — mistakes are visible, not erased.

---

### Civic Spaces
**Status: Live (integration layer)**
**Local:** `C:\Civic Spaces` | **GitHub:** https://github.com/EmpoweredVote/civic-spaces.git

Civic community spaces. Uses `POST /api/roles/check` in ev-accounts as the volunteer gate — Civic Spaces checks the user's role before provisioning moderator access. Jurisdiction-aware (surfaces which spaces are relevant based on user's district).

---

### Empowered Listening
**Status: In development**
**Local:** `C:\Empowered Listening` | **GitHub:** https://github.com/EmpoweredVote/Empowered-Listening.git

Structured civic debate infrastructure. Framework for organizing and moderating asynchronous civic debates with shared fact-finding and argument mapping.

---

### Read & Rank
**Status: In development**
**Local:** `C:\read-rank` | **GitHub:** https://github.com/EmpoweredVote/read-rank.git

Users read civic content and rank arguments. Integrates with ev-accounts via SSO. Planned: push read/rank data to accounts API for display on the profile feature hub.

---

### Treasury Tracker
**Status: In development**
**Local:** `C:\treasury-tracker` | **GitHub:** https://github.com/EmpoweredVote/treasury-tracker.git

Tracks public spending and budget data. Appears on the profile feature hub alongside other Empowered Vote features. Planned integration with accounts API for user-specific data persistence.

---

## Politician & Stance Database (in ev-accounts)

| Tier | Coverage | Status |
|------|----------|--------|
| US Senate | 100 senators + 43 2026 candidates | Live |
| US House | ~430+ representatives | Live |
| CA State Legislature | ~120 (Assembly + Senate) | Live |
| MD State Legislature | ~140+ delegates | Live (Batches A–C) |
| City Officials | SF, San Jose, San Diego, Berkeley, Fremont | Live |
| DC Officials | Mayor, 13 Council, AG, Shadow Senators, EHN, SBOE | **In progress (Phase 105)** |

**Data quality:** All stances now have verified source URLs as of v2.7 (2026-06-07).

---

## Location & District Infrastructure (in ev-accounts)

Users set their location → system resolves legislative districts → powers personalized politician feeds across all features.

- TIGER 2024 polygons loaded for: CA, TX, UT, IN, MA, ME, OR, MD — **DC in progress**
- Layers: US House, State Senate, State House/Assembly, School districts, DC Wards
- RPC: `resolve_user_districts(lat, lng)` → point-in-polygon, returns all matching districts

---

## Current Active Work

**v2.8 — District of Columbia Coverage** (in progress)

| Phase | Description | Status |
|-------|-------------|--------|
| 105 | DC Infrastructure — government stub, ward districts, TIGER polygons, 27 official records | **Task 3/4 active** |
| 106 | DC Stance Research — sourced stances for all ~27 DC officials | Queued |
| 107 | DC Finance — FEC for EHN, DC OCF for Mayor + Council | Queued |

---

## Shipped Milestones (ev-accounts)

| Version | Date | Summary |
|---------|------|---------|
| v1.0 | 2026-02-28 | Three-tier schema, auth, compass API, admin, public pages |
| v1.1 | 2026-03-04 | XP ledger + leveling system |
| v1.2 | 2026-03-07 | CompassV2 compatibility, compass admin |
| v1.3 | 2026-03-15 | Live Alpha, location infrastructure, 21 topics + 30 politicians |
| v1.4 | 2026-03-17 | Verification Rating, Profile Hub (feature cards for all apps) |
| v1.5 | 2026-03-19 | Referral dashboard, integration guides for all partner apps |
| v1.6 | 2026-03-30 | Platform consolidation, Go server decommission, DNS cutover |
| v1.7 | 2026-04-02 | Cross-app SSO across all EV apps |
| v1.8 | 2026-04-01 | Stored jurisdiction on connected profiles |
| v1.9 | 2026-04-06 | Role system, contributor portal, Civic Spaces integration |
| v2.1 | 2026-04-27 | Inform Account tier (anonymous browsing flow) |
| v2.2 | 2026-05-10 | TIGER geofencing — CA district polygons, user_districts cache |
| v2.3 | 2026-05-21 | US Senate — 100 senators, 50-state infrastructure |
| v2.4 | 2026-05-22 | 2026 Senate candidates — 43 records + stances |
| v2.5 | 2026-06-02 | City officials expansion — 4 Bay Area cities + SF |
| v2.6 | 2026-06-05 | Data quality audit + Elections Central (Utah 2026 primary) |
| v2.7 | 2026-06-07 | Source integrity — all stances now have verified source URLs |

---

## All Repos

| Feature / App | Local Path | GitHub |
|---------------|-----------|--------|
| **ev-accounts** — API, admin UI, dashboard, politician DB | `C:\EV-Accounts` | https://github.com/EmpoweredVote/ev-accounts.git |
| **CompassV2** — Empowered Compass frontend | `C:\EV-CompassV2` | https://github.com/EmpoweredVote/CompassV2 |
| **Civic-Trivia-Championships** — CTC | `C:\Transparent Motivations\essentials` | https://github.com/EmpoweredVote/Civic-Trivia-Championships |
| **transparent-motivations** — Empowered Essentials | `C:\Transparent Motivations` | https://github.com/EmpoweredVote/transparent-motivations.git |
| **empowered-validation-quests** — Empowered Quests / VQ | `C:\Validation Quests` | https://github.com/EmpoweredVote/empowered-validation-quests.git |
| **focused-communities** — Issues in Focus | `C:\Focused Communities` | https://github.com/EmpoweredVote/focused-communities.git |
| **civic-spaces** — Civic Spaces | `C:\Civic Spaces` | https://github.com/EmpoweredVote/civic-spaces.git |
| **Empowered-Listening** — Structured civic debates | `C:\Empowered Listening` | https://github.com/EmpoweredVote/Empowered-Listening.git |
| **read-rank** — Read & Rank | `C:\read-rank` | https://github.com/EmpoweredVote/read-rank.git |
| **treasury-tracker** — Treasury Tracker | `C:\treasury-tracker` | https://github.com/EmpoweredVote/treasury-tracker.git |
| **EV-Backend** — old Go server, decommissioned v1.6 | `C:\EV-Backend` | https://github.com/EmpoweredVote/EV-Backend |
| **ev-landing** — landing page (local only) | `C:\ev-landing\ev-landing-main\` | *(no remote)* |

---

## Key Design Principles

- **One voice, one human:** Connected accounts are invite-only for Alpha. Identity = accountability.
- **Anti-funnel:** Most users are Inform tier (anonymous browse). Connected is "Shared Solutions," not a conversion funnel. Copy invites, never pressures.
- **Memory over moderation:** In deliberative features (Issues in Focus), mistakes are made visible — not erased or algorithmically suppressed.
- **All features share one identity:** ev-accounts is the SSO and data hub. XP, gems, roles, and location all flow through it.
- **District-aware everywhere:** Features know which politicians are locally relevant to each user via the TIGER geofencing layer.
