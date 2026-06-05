# Accounts Team Request — LA Citywide Races Missing from 2026 Primary

**From:** Essentials team
**Date:** 2026-04-13
**Priority:** High
**Re:** Marissa Roy (LA City Attorney) and the broader citywide race coverage gap

---

## The Immediate Issue: Marissa Roy

Marissa Roy is running for **Los Angeles City Attorney** in the June 2, 2026 primary. She does not appear on the Elections page because:

1. No `LA City Attorney` race record exists in the `2026 LA County Primary` election
2. No Marissa Roy politician record exists — only two `cal_access_discovery` committee entries (`is_active: false`) derived from campaign finance filings

She is a viable, active candidate in a contested citywide race and is invisible to our users.

---

## The Broader Pattern: Citywide Offices Are Missing

Looking at the current race list for the 2026 LA County Primary, we have:

**What we have:**
- LA City Council (odd-numbered districts: 1, 3, 5, 7, 9, 11, 13, 15)
- LA County Board of Supervisors (Districts 1, 3)
- LA County Sheriff, LA County Assessor
- LAUSD Board of Education (Districts 2, 4, 6)
- CA state races (Governor, Legislature, etc.)
- US Rep District 34

**What's missing — LA citywide offices on the June 2 ballot:**
- LA City Attorney ← Marissa Roy is running here
- LA City Controller
- LA City Clerk

These are elected citywide offices that appear on the ballot for every Los Angeles voter. A user in CD-1 will see their City Council race but not the City Attorney race that's also on their ballot.

---

## Why This Happened

The ingestion approach used for this election was source-driven:
- **State races:** seeded from CA SoS certified candidate list
- **District races:** seeded by identifying specific districts (City Council, Board of Supervisors, Congressional)
- **County offices:** seeded individually (Sheriff, Assessor)

Citywide municipal offices (City Attorney, City Controller, City Clerk) were not on any of those source lists and weren't explicitly added. There's no systemic mechanism that says "for every city with district races in an election, also check for that city's at-large offices."

---

## This Applies to Every City We Cover

The same gap exists for any city where we've seeded district races. If a city has:
- A City Council (seeded by district) → we probably have it
- A City Attorney / City Controller / City Clerk / City Treasurer → we probably don't

For Monroe County, Indiana: this matters less because city attorney races are typically appointment-based there. But for California cities and other states with elected municipal officers, this is a systematic blind spot.

---

## What's Needed

### Immediate (LA County Primary, June 2, 2026)

1. **Add the LA City Attorney race** to the `2026 LA County Primary` election
2. **Seed candidates** — at minimum Marissa Roy; check lavote.gov for the full candidate list
3. **Create politician records** for any candidates without them and link via `politician_id`

Check lavote.gov for the full list of citywide races on the June 2 ballot:
- City Attorney (confirmed: Marissa Roy filed)
- City Controller (check)
- City Clerk (check)

### Systemic

4. **Establish a checklist for election seeding:** when adding district-level races for a city, explicitly audit that city's at-large/citywide offices and add those races too
5. **Consider using the full lavote.gov candidate filing list as the authoritative source** for LA County races — it lists every race and every filer, which would catch citywide offices that the CA SoS list and Calmatters tracker don't surface

---

## Source

LA City Attorney race confirmed via `cal_access_discovery` data already in the DB:
- Committee: `ROY FOR LOS ANGELES CITY ATTORNEY 2026; MARISSA`
- Committee: `MAZARIEGOS FOR CITY COUNCIL AND MARISSA ROY FOR CITY ATTORNEY 2026, SPONSORED BY ACCE ACTION; COMMUNITIES UNITED FOR ESTUARDO`

The campaign finance trail confirms she's an active candidate. The politician and race records just haven't been created yet.

---

*Filed: 2026-04-13*
*Contact: Essentials team*
