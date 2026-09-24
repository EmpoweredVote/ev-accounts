---
created: 2026-09-23T00:00
title: CA 2026 general — ballot designations and judicial retention contests (skipped, need decisions)
area: data
files:
  - backend/migrations/CA_0202_seed_ca_2026_general_legislature.sql
  - backend/src/lib/electionService.ts
  - backend/src/lib/districtQueries.ts
---

Both were found while seeding the CA 2026 general from the SoS Official Certified List of Candidates
(8/27/2026). Both were deliberately **skipped** on 2026-09-23 (operator: Chris Andrews). They need a
decision before any data is written.

## 1. Ballot designations — no reader exists

The certified list gives a ballot designation for every candidate (e.g. "Agricultural
Businessman/Father", "State Senator/Businesswoman"). `essentials.race_candidates.occupational_designation`
holds it, but **nothing reads that column**: no code under `backend/src` references it, and the
`elections-by-address` candidate object carries only `candidate_id, candidate_status, first_name,
full_name, is_incumbent, last_name, photo_url, politician_id, result`. So filling it changes nothing a
voter sees. 358 of ~1,300 CA race_candidates already carry one, from other seeds.

To make it worth doing: add the field to the elections API response (+ test), add it to the
Essentials UI in its own repo, then fill every CA 2026 general candidate in one pass. The parser used
for CA_0202 (headers `State Senate District N` / `State Assembly Member District N`; candidate line =
name[*] + party, next line = designation) already extracts it.

## 2. Judicial retention — needs a model first

The list has **63** yes/no retention contests (Supreme Court + Courts of Appeal). Nothing in the data
models a retention contest: no `races` row anywhere belongs to an `election_type = 'retention'`
election, and `offices.faces_retention_vote` is only an office flag. An ordinary one-candidate race
would render as an unopposed race, which is wrong.

The seats are also mostly missing: the 7 Supreme Court offices exist (6 seated), but of the six
Courts of Appeal districts only the Second exists (24 offices, 8 seated). A retention model and the
missing appellate seats have to come before any retention data.
