---
created: 2026-04-01T00:00
title: Set up LA City Council District 11 2026 race and candidates
area: database
files: []
---

## Problem

The District 11 City Council office (`c315bc5c-fd3d-427e-b8c8-15bfa4fc848d`) has no race/election record, so Faizah Malik and Traci Park (incumbent) cannot be properly linked as candidates. Faizah was incorrectly set as the office `politician_id` (current holder) — that's been nulled out — but she still needs to appear as a candidate in the race. Traci Park (`d0977350`) is the incumbent running for re-election.

## Solution

1. Ensure a 2026 LA City election record exists in `essentials.elections`
2. Create a race in `essentials.races` for this office + election
3. Add both candidates to `essentials.race_candidates`:
   - Traci Park (`d0977350-df68-4cfe-822e-816ba13f9213`, incumbent)
   - Faizah Malik (`a9882d8b-b20d-4b0c-b509-c2883b4352e0`, challenger)
