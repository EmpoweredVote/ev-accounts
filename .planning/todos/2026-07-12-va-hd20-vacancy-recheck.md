# VA House District 20 — vacancy re-check

**Created:** 2026-07-12
**Status:** date-gated, re-check monthly

VA HD-20 (Prince William County / Manassas / Manassas Park) has **no incumbent
delegate seeded — correctly**. Wikipedia's Virginia House of Delegates roster
confirms the seat is vacant as of July 2026 (predecessor left after the Nov 2025
cycle). The DB shows 99/100 delegates; this is the missing seat.

**Action when filled:** a special election will fill it — seed the winner
(politician + attach to the existing HD-20 office/district row, mirror the TX
SD-4 / Brett Ligon pattern from mig 1328), pull headshot, run stance research.

**Check:** `https://en.wikipedia.org/wiki/Virginia_House_of_Delegates` roster
table, or VA Dept of Elections special-election calendar
(`https://www.elections.virginia.gov/casting-a-ballot/upcoming-elections/`).

**Query gotcha (repo-wide):** `essentials.districts.state` is mixed-case
(VA rows are `'va'`, ~5k lowercase rows across all states) — always compare
with `lower(d.state)` or use `offices.representing_state` (uppercase).
