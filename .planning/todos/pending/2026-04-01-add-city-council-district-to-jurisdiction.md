---
created: 2026-04-01T00:00
title: Add city council district to jurisdiction data
area: database
files:
  - backend/src/routes/account.ts
  - app/src/pages/DashboardPage.tsx
---

## Problem

The jurisdiction data stored on `connect.connected_profiles` covers congressional, state senate, state house, county, and school district — but not city council. City council is the most local elected race most users vote in, representing their immediate neighborhood. This gap means "Your Connected Spaces" on the profile page can't show the user's most proximate representative identity (e.g., "Los Angeles, City Council District 11"). It's also the level where Civic Spaces (civicspaces.empowered.vote) is most relevant.

## Solution

- Add `city_council_geo_id` and `city_council_district_name` columns to `connect.connected_profiles` (same pattern as existing district columns)
- Populate via geo lookup when location is set (same pipeline as Phase 49 district resolution)
- Expose in `/api/account/me/jurisdiction` response and `GET /api/account/me` jurisdiction block
- Surface in `DashboardPage.tsx` "Your Connected Spaces" section as the local identity line, e.g., "Los Angeles, City Council District 11"
