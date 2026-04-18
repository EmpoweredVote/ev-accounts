# Phase 122 Wave 0 Baseline

**Date:** 2026-04-17

## Treasury API Shape Verification

`GET https://api.empowered.vote/api/treasury/cities` — CONFIRMED SHAPE:

```json
[
  {
    "id": "d9ddb0b7-333b-4006-8263-967752c200bf",
    "name": "Agoura Hills",
    "state": "CA",
    "entity_type": "city",
    "population": 19770,
    "hero_image_url": null,
    "created_at": null,
    "updated_at": null,
    "available_datasets": [
      { "fiscal_year": 2024, "dataset_type": "operating" },
      { "fiscal_year": 2024, "dataset_type": "revenue" },
      ...
    ]
  }
]
```

Required INTG-03 fields all present: `id`, `name`, `state`, `available_datasets`.
`available_datasets` is an array. Has-data predicate: `available_datasets.length > 0` — confirmed working.

Multiple CA cities present in the response (Agoura Hills, Alhambra, etc.). Bloomington, IN expected from prior Treasury import.

## INTG-02 Verification (D-07 — code-read evidence, no fix needed)

`CompassV2/src/components/ComparePanel.jsx:120`:
```jsx
<a href={`${ESSENTIALS_URL}/politician/${politician.id}${serializeCompassFragment()}`}>
```

- `ESSENTIALS_URL` = `import.meta.env.VITE_ESSENTIALS_URL || "https://essentials.empowered.vote"` — correct
- `politician.id` = UUID from `/api/compass/politicians` which returns `essentials.politicians.id` — unified UUID confirmed
- `serializeCompassFragment()` — already appended, confirmed in code
- Essentials `App.jsx:53-56` has `/politician/:id` route — resolves UUIDs

**Conclusion:** INTG-02 is already correct. No code change required. Closing per D-07.

## INTG-01 Root Cause Identified

`essentials/src/contexts/CompassContext.jsx` line 128: `clearGuestCompass()` was called unconditionally whenever `authedUser` is present, regardless of whether `fetchUserAnswers()` returned results.

**Fix applied in Task 0.1 commit (essentials@d266215):** When `authedUser` is logged in but `answersResult.length === 0`, the code now falls back to `loadGuestCompass()` before clearing. If guest cache exists, it is used as display data and preserved. The guest cache is only cleared when API answers are present (the clean-separation case remains intact).
