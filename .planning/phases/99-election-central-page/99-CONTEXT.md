# Phase 99: Election Central Page — Context

## Problem

Voters need to discover what elections are happening in their area and who the candidates are. Currently the essentials app shows who *represents* you but not who is *running for office*.

## Solution

Add an Election Central page to `essentials.empowered.vote` that:
1. Takes an address input (like the existing Results page)
2. Calls `GET /api/essentials/elections-by-address?address=...`
3. Shows upcoming elections grouped by date
4. Shows races within each election grouped by jurisdiction level (Federal / State / Local)
5. Links candidates to their profile pages when a `politician_id` is present

## Antipartisan Principle

Per platform design: party affiliations are NEVER shown on candidates. The `primary_party` field on races indicates the primary type but is shown as "Primary" generically, not as a party label.

## Backend Contract (from 99-01)

`GET /api/essentials/elections-by-address?address={encoded}`

Response:
```json
{
  "elections": [
    {
      "election_id": "uuid",
      "election_name": "2026 Indiana Primary Election",
      "election_date": "2026-05-05",
      "election_type": "primary",
      "jurisdiction_level": "state",
      "races": [
        {
          "race_id": "uuid",
          "position_name": "U.S. Representative - District 9",
          "primary_party": null,
          "seats": 1,
          "district_type": "NATIONAL_LOWER",
          "candidates": [
            {
              "candidate_id": "uuid",
              "full_name": "Jane Smith",
              "first_name": "Jane",
              "last_name": "Smith",
              "photo_url": null,
              "is_incumbent": false,
              "candidate_status": "active",
              "politician_id": "uuid-or-null"
            }
          ]
        }
      ]
    }
  ]
}
```

Status codes:
- 200: elections array (may be empty)
- 422: missing/empty address param
- 503: geocoder unavailable

## Design Reference

See 99-UI-SPEC.md for visual design.

## Files Scope

- `essentials/src/pages/Elections.jsx` — new page
- `essentials/src/App.jsx` — add `/elections` route
- `essentials/src/lib/api.jsx` — add `fetchElectionsByAddress()`
