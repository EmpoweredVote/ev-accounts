---
phase: 58-local-data-pipeline
plan: "02"
subsystem: database
tags: [python, beautifulsoup, psycopg2, rapidfuzz, onboard, bloomington, scraping]

# Dependency graph
requires:
  - phase: 58-01
    provides: feasibility report confirming OnBoard HTML is scrapable
provides:
  - Bloomington Common Council committee and legislation import script
  - 9/9 council members matched via nickname-expanded fuzzy matching
  - 4 committees imported (Common Council + 3 subcommittees)
  - Legislation import with sponsor attribution extraction
affects:
  - essentials.legislative_committees (4 Bloomington committees)
  - essentials.legislative_committee_memberships (council + subcommittee roles)
  - essentials.legislative_bills (sponsored legislation items)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Nickname expansion map (Dave->David, Bill->William, etc.) for fuzzy name matching"
    - "Role parsing from OnBoard seat_text prefix before 'Seat:' marker"
    - "Sponsor regex extraction from legislation detail pages"
    - "Progressive import: committees-only, legislation-only, or full"

key-files:
  created:
    - EV-Backend/scripts/import_local_bloomington.py
  modified: []

# Deviations
deviations:
  - "Dave Rollo required nickname expansion (Dave->David) to match David R Rollo in DB (score 91.7)"
  - "Courtney Daily was missing from DB — manually inserted with office record, replacing deactivated Shruti Rana (District 5)"
  - "Role parsing was incorrectly matching 'Appointed By: Council President' as role=president — fixed to extract role from prefix before 'Seat:' only"

# Self-Check: PASSED
---

## What was built

Python import script (`import_local_bloomington.py`, ~1000 lines) that scrapes Bloomington Common Council data from OnBoard HTML pages and imports committee assignments and legislation metadata into the database.

**Key results:**
- 9/9 council members matched to DB politicians (nickname expansion fixed Dave Rollo, Courtney Daily added to DB)
- 4 committees: Common Council, Council Processes, Fiscal, Sidewalk/Pedestrian Safety
- Roles correctly parsed: president, vice_president, chair, parliamentarian, member
- Legislation import scoped to items with sponsor attribution only

**Commits:**
- `b7dbf8a` feat(58-02): create Bloomington OnBoard committee and legislation import script
- `6940626` fix(58): add nickname expansion to fuzzy name matching
- `f3e8a90` fix(58-02): parse committee roles from prefix before 'Seat:' only

**Data fixes applied during execution:**
- Shruti Rana deactivated (served Jan-Feb 2024, relocated out of state)
- Courtney Daily inserted (sworn in March 2024, District 5)
- DB unique constraints added to legislative_sessions, committees, memberships, bills tables
