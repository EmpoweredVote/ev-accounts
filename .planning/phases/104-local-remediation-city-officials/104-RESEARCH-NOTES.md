# Phase 104 — Research Notes

**Plan:** 104-01 (Local Remediation — City Officials)
**Date:** 2026-06-07
**Requirements:** STAX-03, QUAL-01, QUAL-02

---

## Pre-Flight

**Executed:** 2026-06-07T (before agent dispatch)

### 1. Migration Version

```sql
SELECT MAX(version) FROM supabase_migrations.schema_migrations;
```

**Result:** `282`
**Next migration number:** `283`

### 2. Mahmood Pre-Flight Row

```sql
SELECT pa.value, pc.sources, t.topic_key, t.id AS topic_id
FROM inform.politician_answers pa
JOIN inform.compass_topics t ON t.id = pa.topic_id
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE pa.politician_id = 'd3c5004c-9ca0-444e-96d9-107d4315abcb'
  AND t.topic_key = 'abortion'
```

**Result:**
```json
{
  "value": "2.0",
  "sources": ["https://bilalmahmood.com/"],
  "topic_key": "abortion",
  "topic_id": "af2fdfd6-02c4-49df-b09c-cf8536f4773f"
}
```

**Matches D-01 triage record:** value=2.0, sources=['https://bilalmahmood.com/'] ✓

### 3. Moreno Pre-Flight Row

```sql
SELECT pa.value, pc.sources, t.topic_key, t.id AS topic_id
FROM inform.politician_answers pa
JOIN inform.compass_topics t ON t.id = pa.topic_id
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE pa.politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'
  AND t.topic_key = 'city-sanitation'
```

**Result:**
```json
{
  "value": "3.0",
  "sources": ["https://www.vivianmorenosd.com"],
  "topic_key": "city-sanitation",
  "topic_id": "7687de4f-4d0b-462a-b803-bdfb23b16b42"
}
```

**Matches D-01 triage record:** value=3.0, sources=['https://www.vivianmorenosd.com'] ✓

### 4. Live Stance Scales

#### Live Stance Scales — abortion

```json
{
  "id": "af2fdfd6-02c4-49df-b09c-cf8536f4773f",
  "topic_key": "abortion",
  "title": "Reproductive Rights and Abortion Access",
  "question_text": "What legal framework should govern abortion access?",
  "stances": [
    { "value": 1, "text": "ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy." },
    { "value": 2, "text": "keep abortion legal and accessible through the second trimester with rare exceptions afterward." },
    { "value": 3, "text": "allow abortion in the first trimester and in cases of rape, incest, or maternal health risks." },
    { "value": 4, "text": "restrict abortion to only cases involving rape, incest, or serious threats to the mother's life." },
    { "value": 5, "text": "ban abortion completely with no exceptions and impose criminal penalties for providers and patients." }
  ]
}
```

#### Live Stance Scales — city-sanitation

```json
{
  "id": "7687de4f-4d0b-462a-b803-bdfb23b16b42",
  "topic_key": "city-sanitation",
  "title": "City Sanitation and Cleanliness",
  "question_text": "How should your city approach street cleanliness and sanitation?",
  "stances": [
    { "value": 1, "text": "Significantly expand sanitation staffing, cleaning frequency, and free community disposal access; treat poor conditions as a services failure" },
    { "value": 2, "text": "Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness citywide" },
    { "value": 3, "text": "Maintain current sanitation services while enforcing anti-dumping laws for businesses and large property owners" },
    { "value": 4, "text": "Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible" },
    { "value": 5, "text": "Privatize sanitation services and require residents and businesses to contract for cleanup directly" }
  ]
}
```

---

## Agent Dispatch Order

Per D-04 (one agent at a time) and MEMORY.md rate-limit rule:
1. **Agent #1:** Bilal Mahmood / abortion (dispatched first, waited to complete)
2. **Agent #2:** Vivian Moreno / city-sanitation (dispatched only after Agent #1 completed)

---

## Mahmood / abortion — Research Outcome

**Outcome:** DELETE — no evidence found (D-04)

**Research completed:** 2026-06-07

**URLs fetched (WebFetch only, no WebSearch):**
- https://ballotpedia.org/Bilal_Mahmood — 200, no abortion content
- https://bilalmahmood.com/platform/ — 200, covers Housing/Safety/Homelessness/Transit/Climate/Food/Civil Rights/Labor/Education/Small Business; abortion NOT mentioned
- https://bilalmahmood.com/endorsements — 200, shows PPNCA endorsement as text listing only, no policy statement
- https://en.wikipedia.org/wiki/Bilal_Mahmood — 200, no abortion content
- https://www.sfchronicle.com/opinion/editorials/article/endorsement-bilal-mahmood-supervisor-district-5-19789511.php — 200, paywall/structured data only, no abortion content
- Multiple sfbos.org official pages — 404 (Mahmood took office Jan 2025; old BOS site doesn't have his page yet)
- sf.legistar.com sponsored legislation search — Mahmood has no public legislation recorded yet
- 48hills.org, missionlocal.org, sfexaminer.com searches — 404 or no abortion content with Mahmood

**Reasoning for DELETE:** Bilal Mahmood's campaign platform page (https://bilalmahmood.com/platform/) does not mention abortion or reproductive rights. The Planned Parenthood Northern California Action Fund endorsement appears on his endorsements list page but that page contains only endorser names, not policy statements. No board resolution, press release, interview, or specific campaign page addressing abortion was found. Per D-04, a homepage URL (https://bilalmahmood.com/) or generic endorsement list does not satisfy QUAL-01. Single research pass complete — no retry.

**CSV:** Header-only (2026-06-07-104-mahmood-abortion.csv) — DELETE outcome.

---

## Moreno / city-sanitation — Research Outcome

**Outcome:** UPGRADE — value updated from 3 to 2, new specific URL found

**Research completed:** 2026-06-07

**URLs fetched (WebFetch only, no WebSearch):**
- https://ballotpedia.org/Vivian_Moreno — 200, disambiguation page only, no substantive content
- https://www.sandiego.gov/citycouncil/cd8 — 200, city nav page, no specific Moreno sanitation policy
- https://www.vivianmorenosd.com — 200, homepage (already in sources — not qualifying per D-04)
- https://www.vivianmorenosd.com/about — 200, bio page, no specific sanitation policy detail
- https://www.vivianmorenosd.com/better — 200, specific accomplishments page with explicit sanitation evidence
- https://www.vivianmorenosd.com/media — 200, media page, no sanitation content

**New specific URL:** `https://www.vivianmorenosd.com/better`

**Evidence found:** The `/better` page ("Building a Cleaner South San Diego County" section) documents:
- 65+ dumpster drop-offs removing 230+ tons of debris, providing free community disposal access
- Hiring 2 dedicated graffiti abatement officers after D8 had the lowest graffiti removal in city
- Tijuana River Valley pollution resolution
- Explicit framing: prioritizing historically underserved South San Diego neighborhoods

**Value determination:** Former value was 3.0 ("Maintain current sanitation services while enforcing anti-dumping laws for businesses and large property owners"). Evidence shows Moreno actively EXPANDED services (65+ free disposal events, new staff hires) and prioritized historically underserved D8 neighborhoods. This matches value=2: "Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness citywide."

**New value:** 2

**CSV:** One data row written (2026-06-07-104-moreno-city-sanitation.csv) — UPGRADE outcome with source `https://www.vivianmorenosd.com/better`.

---

## Migration Apply Log

**Command:** `cd backend && npx tsx scripts/_apply-migration-283.ts`
**Executed:** 2026-06-07

**Full stdout:**
```
Migration 283 applied successfully
V1 city-cohort unsourced count: 0 (target: 0)
V2 city-cohort weak-source count: 0 (target: 0)
STAX-03 SATISFIED: V1=0, V2=0
```

**V1 result (city cohort unsourced count):** 0 — target = 0 ✓
**V2 result (city cohort weak-source count):** 0 — target = 0 ✓
**STAX-03 status:** SATISFIED
