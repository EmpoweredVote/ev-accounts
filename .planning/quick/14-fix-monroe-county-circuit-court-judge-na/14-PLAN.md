---
phase: quick-14
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql
  - EV-Backend/scripts/gov_structure.json
autonomous: true
requirements: [QUICK-14]
must_haves:
  truths:
    - "Geoffrey J. Bradley (Division 1), Valeri Haughton (Division 2), Christine Talley Haseman (Division 3), Catherine B. Stafford (Division 4), Mary Ellen Diekhoff (Division 5), Kara E. Krothe (Division 6), Holly M. Harvey (Division 7), Emily A. Salzmann (Division 8), Darcie L. Fawcett (Division 9) appear with correct names and division labels"
    - "No judge record shows a Seat label or the old incorrect seat number"
    - "district_id on each judge's district row matches the correct division number (1-9)"
  artifacts:
    - path: "EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql"
      provides: "Idempotent SQL migration correcting names and seat→division relabeling"
  key_links:
    - from: "essentials.offices"
      to: "essentials.districts"
      via: "politician_id join path"
      pattern: "Seat N → Division N update"
---

<objective>
Correct Monroe County 10th Circuit Court judge names and relabel all seat references to division numbers in the Supabase database.

Purpose: Official in.gov data shows Division 1–9 labels and fuller judge names; the DB currently has shortened names and mismatched Seat N labels that do not correspond to the correct division numbers.
Output: SQL migration file applied to the database, all 9 judges display correctly.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/Users/chrisandrews/Documents/GitHub/.planning/STATE.md

Pattern reference (existing migration):
@/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/migrations/normalize_congressional_district_labels.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write and apply SQL migration for judge names and division relabeling</name>
  <files>EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql</files>
  <action>
Create the migration file at EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql following the BEGIN/COMMIT/idempotent pattern used in existing migrations.

The migration must perform these updates inside a single transaction:

**Section 1 — Fix politician names (essentials.politicians)**

Update these four rows by politician_id:

| politician_id | first_name | middle_initial | full_name |
|---|---|---|---|
| 999a9d38-9894-45f0-80c7-228880089699 | Geoffrey | J | Geoffrey J. Bradley |
| 36af947b-b548-4964-8003-889cffbf7dad | Christine | Talley | Christine Talley Haseman |
| 1db5eafb-b7c5-4716-b3a8-ad0ff8a7dc63 | Catherine | B | Catherine B. Stafford |
| 3e95fc5c-6927-492c-9f1c-6d65b5b7b9cb | Mary | Ellen | Mary Ellen Diekhoff |

Use individual UPDATE statements filtering on politician_id. The other five judges need no name changes.

**Section 2 — Relabel districts (essentials.districts)**

Each judge has a row in essentials.districts linked by district_id (current seat number). The current seat numbers do NOT match division numbers — use the mapping table below.

For each judge, identify their current district row using their district_id (current seat), then update:
- `label` → replace "Seat N" with "Division N" using the correct division number
- `district_id` → set to the correct division number as a string

Mapping (current seat → correct division):

| politician_id | judge | current seat (district_id) | correct division |
|---|---|---|---|
| 999a9d38-9894-45f0-80c7-228880089699 | Bradley | 9 | 1 |
| 741be6f7-eac1-4458-bef1-6576ba5acd98 | Haughton | 6 | 2 |
| 36af947b-b548-4964-8003-889cffbf7dad | Haseman | 2 | 3 |
| 1db5eafb-b7c5-4716-b3a8-ad0ff8a7dc63 | Stafford | 3 | 4 |
| 3e95fc5c-6927-492c-9f1c-6d65b5b7b9cb | Diekhoff | 4 | 5 |
| 048cb4ba-9b07-42e6-b45d-f4dffad2a088 | Krothe | 5 | 6 |
| 52a1db12-bef7-4e68-9daf-bdd17c82f6c0 | Harvey | 1 | 7 |
| 4e058a9c-a4ab-403c-88d3-32918e860cc8 | Salzmann | 7 | 8 |
| d60ef0ea-b764-47eb-989a-3d5f1c461d10 | Fawcett | 8 | 9 |

Each judge has a UNIQUE district row (UUID PK), chamber row (UUID PK), and office row (UUID PK). Update by PK for safety.

**Exact PKs and mapping (current seat → correct division):**

| Judge | Division | district PK | district_id old→new | chamber PK | office PK |
|---|---|---|---|---|---|
| Bradley | 1 | 07c65675-dabd-4fc1-b723-3c8af82d87f6 | 9→1 | 78c06524-a8cb-415a-9943-1b8aaa5ba39c | 44a339c0-e32a-4b4a-aa83-b5617277c8f2 |
| Haughton | 2 | 2a12897c-410a-4649-8bc8-1763d13ac4cb | 6→2 | a563c265-22ca-4c0e-a870-aeba00a11436 | 1b893cc9-0ff6-479b-810a-22120dd44e8a |
| Haseman | 3 | 06448769-df8b-4810-94a2-b73e87a0cbce | 2→3 | f480b81f-1e3f-4b6c-abc6-475a281eec6b | 79ad0a9b-8e51-4e53-a515-407217dddd23 |
| Stafford | 4 | f95266d5-2624-4a75-88f5-6229f426f25a | 3→4 | 20abf84a-a5fb-431e-bb13-76df1a1fa868 | e7445bb2-2f55-45bb-97bc-d910133d2d2f |
| Diekhoff | 5 | 412d8f9e-de03-46bf-9037-5e83e3faee5b | 4→5 | c2e818a7-fa54-44aa-bb3a-9957f5b67e41 | 1fceb227-022a-4089-a459-f080ca645e61 |
| Krothe | 6 | ed7421cf-47b7-43ee-98f9-06916748093d | 5→6 | 783c3991-5941-4a61-b9e7-acc6ffbb8e48 | 516ecc9a-2c82-4d51-aacd-67032634e26c |
| Harvey | 7 | 72f8d191-0c9a-421a-83fb-7680553c8978 | 1→7 | 043a199c-0b40-4e97-a3bb-3bac7f0d54b6 | ca3aa3fa-851b-4907-994a-aaeae011e0c4 |
| Salzmann | 8 | f482816e-0387-4623-b6b4-13bc7eac06ce | 7→8 | ea940b0e-348c-44bb-91f4-5c9e7fab46e2 | d6517a23-9864-4b18-b2cd-2cd539264c00 |
| Fawcett | 9 | abd6f087-de4d-4872-b8b6-b60bbb302eef | 8→9 | b98ce33f-1e6a-4061-a9a4-443b36f29186 | 2261f602-d241-41fe-806b-9048b492cfba |

**Current label format:** `Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat N`
**Target label format:** `Indiana Circuit Court Judge - 10th Circuit (Monroe County), Division N`

**Current chamber name format:** `Indiana Circuit Court Judge - 10th Circuit, Seat N`
**Target chamber name format:** `Indiana Circuit Court Judge - 10th Circuit, Division N`

**Current office title format:** `Indiana Circuit Court Judge - 10th Circuit, Seat N`
**Target office title format:** `Indiana Circuit Court Judge - 10th Circuit, Division N`

For each row, use UPDATE by PK (the `id` column), replacing "Seat {old}" with "Division {new}" AND updating district_id to the new division number string.

Add verification queries as comments at the bottom of the file. Include:
1. SELECT showing all 9 judges with their updated full_name, label, district_id
2. COUNT check confirming 0 rows still have "Seat" in label for Monroe County Circuit Court
3. COUNT check confirming 0 rows still have "Seat" in chamber name for Monroe County Circuit Court

After writing the file, apply it:
```
psql $DATABASE_URL -f EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql
```

If DATABASE_URL is not set in the shell, check EV-Backend/.env.local for the connection string and pass it inline.
  </action>
  <verify>
    <automated>psql $DATABASE_URL -c "SELECT p.full_name, d.label, d.district_id FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE p.id IN ('999a9d38','741be6f7','36af947b','1db5eafb','3e95fc5c','048cb4ba','52a1db12','4e058a9c','d60ef0ea') ORDER BY d.district_id::int;" 2>/dev/null || echo "Run verification queries from migration file comments in Supabase SQL Editor"</automated>
  </verify>
  <done>
- Geoffrey J. Bradley shows full_name="Geoffrey J. Bradley", label contains "Division 1", district_id="1"
- Christine Talley Haseman shows middle_initial="Talley", label "Division 3"
- Catherine B. Stafford shows middle_initial="B", label "Division 4"
- Mary Ellen Diekhoff shows middle_initial="Ellen", label "Division 5"
- All 9 judges show Division 1–9 labels in correct order per in.gov official data
- Zero rows in essentials.districts or essentials.chambers still reference "Seat" for Monroe County Circuit Court
  </done>
</task>

<task type="auto">
  <name>Task 2: Update gov_structure.json with circuit court naming convention</name>
  <files>EV-Backend/scripts/gov_structure.json</files>
  <action>
In EV-Backend/scripts/gov_structure.json, find the Indiana circuit court entry (the one with `"level": "circuit"` under the IN state config, around line 109-122).

Add a `naming_convention` object to this entry that documents how multi-division circuit courts should be labeled. Add it after the `"geo_scope": "county"` field.

The new field should be:
```json
"naming_convention": {
  "district_label": "Division {N}",
  "chamber_name": "{Court Name}, Division {N}",
  "office_title": "{Court Name}, Division {N}",
  "note": "Indiana circuit courts with multiple judges use 'Division' (not 'Seat'). Division numbers are assigned by the court, not by data source seat numbers. Verify division assignments against official court website (e.g., in.gov/counties/{county}/justice/circuit-court/)."
}
```

This ensures future data imports and standardization runs know to use "Division N" format for circuit court judges instead of the Cicero-sourced "Seat N" format.
  </action>
  <verify>
    <automated>grep -c "Division" EV-Backend/scripts/gov_structure.json</automated>
  </verify>
  <done>
- gov_structure.json circuit court entry has naming_convention with Division format
- Future imports have reference for correct circuit court labeling
  </done>
</task>

</tasks>

<verification>
After applying the migration, run the verification queries included as comments at the bottom of the migration file. All 9 judges should appear with correct full names and Division 1–9 labels. No "Seat" references should remain for Monroe County Circuit Court in districts or chambers tables.
</verification>

<success_criteria>
Migration file exists at EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql, has been applied to the database, and all 9 Monroe County Circuit Court judges display the correct official names and Division 1–9 labels matching in.gov data. gov_structure.json has been updated with naming convention for circuit court divisions.
</success_criteria>

<output>
After completion, note the commit hash in .planning/STATE.md under Quick Tasks Completed as entry #14.
</output>
