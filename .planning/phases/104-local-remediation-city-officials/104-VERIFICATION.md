# Phase 104 — STAX-03 Verification Record

**Phase:** 104 — Local Remediation — City Officials
**Plan:** 01
**Requirement:** STAX-03
**Date:** 2026-06-07
**Migration applied:** 283 (`supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql`)

---

## Cohort Scope

**v2.5 city-official cohort:**

```sql
p.external_id BETWEEN -689999 AND -630000
AND (p.external_id < -669999 OR p.external_id > -660000)
AND p.is_active = true
```

This range covers SF (63xx block), San Jose (64xx), San Diego (65xx), Fremont (67xx), and Berkeley (68xx).
Block 66xx (Sacramento) is excluded because Sacramento was not part of the v2.5 city-official expansion.
Citation: D-02 (104-CONTEXT.md) — authoritative cohort scope defined by external_id ranges.

---

## V1 Query — Unsourced Stance Count

**Definition:** A stance is unsourced when the politician_context row is missing, sources is NULL,
sources is an empty array, or all URL elements are blank strings.

```sql
SELECT COUNT(*) AS city_unsourced_count
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -689999 AND -630000
  AND (p.external_id < -669999 OR p.external_id > -660000)
  AND p.is_active = true
  AND (
    pc.politician_id IS NULL
    OR pc.sources IS NULL
    OR array_length(pc.sources, 1) IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) AS s(url)
      WHERE url IS NOT NULL AND trim(url) <> ''
    )
  );
```

**Result:** `city_unsourced_count = 0`

---

## V2 Query — Weak-Source Stance Count

**Definition:** A stance is weak-source-only when sources is non-empty but every non-blank URL matches
the bare-homepage regex `^https?://[^/]+/?$` (no path component beyond an optional trailing slash).

```sql
SELECT COUNT(*) AS city_weak_count
FROM inform.politician_answers pa
JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -689999 AND -630000
  AND (p.external_id < -669999 OR p.external_id > -660000)
  AND p.is_active = true
  AND pc.sources IS NOT NULL
  AND array_length(pc.sources, 1) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(pc.sources) AS s(url)
    WHERE url IS NOT NULL AND trim(url) <> ''
      AND url !~ '^https?://[^/]+/?$'
  );
```

**Result:** `city_weak_count = 0`

---

## Cross-Reference to Migration Apply Log

Both independent verification query results (V1=0, V2=0) match the migration's embedded RAISE NOTICE
output captured in `104-RESEARCH-NOTES.md` under "Migration Apply Log":

```
POST-MIGRATION v2.5 city-official cohort unsourced stances (V1): 0
POST-MIGRATION v2.5 city-official cohort weak-source stances (V2): 0
```

All three data points agree: apply-script smoke check, migration RAISE NOTICE, and independent verification.

---

## STAX-03 Status

**SATISFIED**

Both V1 (unsourced count) and V2 (weak-source-only count) for the v2.5 city-official cohort returned 0
post-migration 283. Every city official stance in the cohort (SF, San Jose, San Diego, Fremont, Berkeley)
is now backed by a real specific (non-homepage) source URL or has been permanently deleted.

**Actions taken:**
- Bilal Mahmood / abortion (former value=2) — DELETED. No specific primary source URL found after
  exhaustive research. Homepage `https://bilalmahmood.com/` does not satisfy QUAL-01.
- Vivian Moreno / city-sanitation (value upgraded 3→2) — UPGRADED. Specific URL appended:
  `https://www.vivianmorenosd.com/better` (preserves existing `https://www.vivianmorenosd.com`
  via ARRAY_CAT per D-04). Evidence: 65+ free disposal events, 2 new graffiti abatement officers,
  explicit D8 underserved-neighborhood prioritization.
