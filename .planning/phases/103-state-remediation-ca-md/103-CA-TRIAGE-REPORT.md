# Phase 103 — CA State Source Triage Report

## Pre-flight discoveries (Plan 01 Task 1)

### A. CA district_type values present in essentials.districts
[{"district_type":"COUNTY"},{"district_type":"JUDICIAL"},{"district_type":"LOCAL"},{"district_type":"LOCAL_EXEC"},{"district_type":"NATIONAL_LOWER"},{"district_type":"NATIONAL_UPPER"},{"district_type":"SCHOOL"},{"district_type":"STATE_EXEC"},{"district_type":"STATE_LOWER"},{"district_type":"STATE_UPPER"}]

State-tier types present: STATE_EXEC, STATE_LOWER, STATE_UPPER
Non-state types present (excluded): COUNTY, JUDICIAL, LOCAL, LOCAL_EXEC, NATIONAL_LOWER, NATIONAL_UPPER, SCHOOL

### B. Available state-column on essentials.districts
[{"column_name":"state"}]

Column name confirmed: `state` (not `state_code` or `state_abbr`). Task 2 uses `d.state = 'CA'`.

### C. Per-district_type CA active politician counts
[{"district_type":"COUNTY","politician_count":"3"},{"district_type":"LOCAL","politician_count":"375"},{"district_type":"LOCAL_EXEC","politician_count":"97"},{"district_type":"NATIONAL_LOWER","politician_count":"52"},{"district_type":"NATIONAL_UPPER","politician_count":"2"},{"district_type":"SCHOOL","politician_count":"383"},{"district_type":"STATE_EXEC","politician_count":"18"},{"district_type":"STATE_LOWER","politician_count":"80"},{"district_type":"STATE_UPPER","politician_count":"40"}]

State-tier breakdown:
- STATE_LOWER (CA Assembly): 80 politicians — all 80 Assembly seats present
- STATE_UPPER (CA Senate): 40 politicians — all 40 Senate seats present
- STATE_EXEC (CA statewide executives): 18 politicians — includes Governor, Lt. Governor, AG, etc.
Total CA state-tier politicians: 138

### D. Gavin Newsom district_type confirmation
[{"full_name":"Gavin Newsom","district_type":"STATE_EXEC","state":"CA"}]

Gavin Newsom's district_type is `STATE_EXEC`. This confirms that `STATE_EXEC` MUST be included in the Task 2 IN() list per CONTEXT.md D-02. Pitfall 1 (CA District Type Coverage) is averted.

### E. Final district_type IN() list for Task 2 CTE
'STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC'

Rationale:
- `STATE_LOWER`: CA Assembly (80 politicians) — required, non-negotiable
- `STATE_UPPER`: CA Senate (40 politicians) — required, non-negotiable
- `STATE_EXEC`: CA statewide executives (18 politicians, includes Gavin Newsom) — required per CONTEXT.md D-02

Excluded:
- `STATE_BOARD`: Not present in CA district records in the live DB — excluded (no rows match)
- `COUNTY`, `JUDICIAL`, `LOCAL`, `LOCAL_EXEC`, `NATIONAL_LOWER`, `NATIONAL_UPPER`, `SCHOOL`: Not state-tier — excluded per plan scope

Total CA state politicians in scope: 80 + 40 + 18 = 138
