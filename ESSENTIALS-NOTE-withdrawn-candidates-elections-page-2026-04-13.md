# Elections Page — Withdrawn Candidate Display

**From:** Accounts team  
**To:** Essentials team  
**Date:** 2026-04-13  
**Re:** Showing withdrawn candidates with a visual badge on the Elections page

---

## Context

Eric Swalwell has been marked `candidate_status = 'withdrawn'` in the CA Governor race
(2026 LA County Primary). The user intent is for withdrawn candidates to remain visible
on the Elections page with a "WITHDRAWN" banner or overlay across their photo, rather
than being silently removed from the list.

This applies to the **Elections page only** — not Representatives, Compass, or any other
feature.

---

## Current behavior

All election queries (`getElectionsByCoordinate`, `getElectionsByGeoIds`) filter out
withdrawn candidates at the JOIN level:

```sql
LEFT JOIN essentials.race_candidates rc
  ON rc.race_id = r.id
  AND rc.candidate_status != 'withdrawn'   ← withdrawn candidates never appear
```

So Swalwell is currently invisible in all election results.

---

## What needs to change

### Backend (Accounts team will do this)

Remove the `candidate_status != 'withdrawn'` filter from the JOIN in both election
query functions in `electionService.ts`. Withdrawn candidates will then appear in the
`candidates` array of each race. The response shape already includes `candidate_status`
on every candidate object — no schema change needed.

`candidate_status` values the frontend will receive: `'active'`, `'filed'`, `'withdrawn'`

We will make this change and push it. Let us know if you need it sooner.

### Frontend (Essentials team)

In `ElectionsView` (or wherever individual candidates are rendered on the Elections page):

1. **Render withdrawn candidates** — do not filter them out client-side. They now appear
   in the same `candidates` array as active candidates.

2. **Visual treatment for `candidate_status === 'withdrawn'`:**
   - Overlay a "WITHDRAWN" banner/ribbon across the candidate's photo
   - Reduce opacity or add a muted style to the card
   - Suggested: diagonal ribbon across the photo corner (red or grey), similar to
     an "out of stock" treatment on an e-commerce card

3. **Sort order** — recommend sorting withdrawn candidates to the bottom of the
   candidate list within each race, after all active/filed candidates.

4. **Do not apply this treatment outside the Elections page.** Compass, profile views,
   and Representatives should not change.

---

## Why not a separate fetch?

A separate `GET /elections/me/withdrawn` endpoint was considered but rejected:
- The response already contains `candidate_status` per candidate — the frontend has
  everything it needs in one call
- A second fetch adds a round-trip and coordination complexity for minimal gain
- Sorting/interleaving active + withdrawn candidates within a race is easier with a
  single array than merging two separate responses

---

## Current state in the DB

| Race | Candidate | Status |
|------|-----------|--------|
| CA Governor (2026 LA County Primary) | Eric Swalwell | `withdrawn` |

Additional candidates may be marked withdrawn as the filing/qualification period
closes. The `candidate_status` field is the authoritative signal — no coordination
needed for future withdrawals beyond us updating the DB record.

---

## CA Governor candidate list (authoritative)

Source: [Calmatters — California Governor Candidates 2026](https://calmatters.org/politics/2026/03/california-governor-candidates/)
as of 2026-03-06. 9 active candidates as of 2026-04-13 (Swalwell withdrawn):

| Candidate | Status |
|-----------|--------|
| Xavier Becerra | active |
| Chad Bianco | active |
| Steve Hilton | active |
| Matt Mahan | active |
| Katie Porter | active |
| Tom Steyer | active |
| Eric Swalwell | **withdrawn** |
| Tony Thurmond | active |
| Antonio Villaraigosa | active |
| Betty Yee | active |
