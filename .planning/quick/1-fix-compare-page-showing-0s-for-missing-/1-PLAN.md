---
phase: quick-fix
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - CompassV2/src/components/ComparePanel.jsx
  - CompassV2/src/pages/Compass.jsx
  - EV-Backend/data/stance_research.csv
  - EV-Backend/data/ThomsonBanksYoungHouchin.csv
autonomous: true
must_haves:
  truths:
    - "When a politician has no stance on a topic, the ComparePanel shows ONLY the 'X hasn't answered this topic yet' message with no stance option buttons"
    - "When a politician HAS a stance on a topic, all stance options render normally with colored dots"
    - "Kerry Thomson has no trans-athletes stance record in the database"
    - "The radar chart renders 0-value compare spokes as absent/unanswered rather than as a point at 0"
  artifacts:
    - path: "CompassV2/src/components/ComparePanel.jsx"
      provides: "Conditional stance list rendering"
    - path: "CompassV2/src/pages/Compass.jsx"
      provides: "Filtered compareAnswers excluding 0-value entries"
  key_links:
    - from: "CompassV2/src/pages/Compass.jsx"
      to: "ComparePanel.jsx"
      via: "compareAnswers object"
      pattern: "compareAnswers"
---

<objective>
Fix two bugs in the compare feature: (1) ComparePanel shows stance option buttons with implicit "0" values when a politician has no stance on a topic -- it should only show the "hasn't answered" message. (2) Remove inaccurate Kerry Thomson trans-athletes stance data from source CSVs and database.

Purpose: Eliminate misleading data display and bad data from the compare experience.
Output: Clean ComparePanel behavior for unanswered topics, Kerry Thomson trans-athletes records removed.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CompassV2/src/components/ComparePanel.jsx
@CompassV2/src/pages/Compass.jsx
@EV-Backend/internal/compass/models.go

<interfaces>
<!-- ComparePanel receives compareAnswers from CompassContext -->
<!-- compareAnswers is an object: { [short_title]: value } where value=0 means unanswered -->

From CompassV2/src/pages/Compass.jsx (line 555-565):
```javascript
// allAnswers: [{topic_id, value}, ...]
const mapped = selectedTopics
  .map((id) => {
    const a = allAnswers.find((x) => x.topic_id === id);
    const t = topicsRef.current.find((tt) => tt.id === id);
    if (!t) return null;
    return [t.short_title, a ? a.value : 0];  // <-- 0 for unanswered
  })
  .filter(Boolean);
setCompareAnswers(Object.fromEntries(mapped));
```

From CompassV2/src/components/ComparePanel.jsx (line 100):
```javascript
const polHasAnswered = polValue && polValue > 0;
```

From EV-Backend/internal/compass/models.go:
```go
type Answer struct {
  ID           string    `gorm:"primaryKey" json:"id"`
  PoliticianID uuid.UUID `json:"politician_id"`
  TopicID      uuid.UUID `json:"topic_id"`
  Value        float64   `gorm:"default: 0" json:"value"`
}

type Context struct {
  ID           string         `gorm:"primaryKey" json:"id"`
  PoliticianID uuid.UUID      `json:"politician_id"`
  TopicID      uuid.UUID      `json:"topic_id"`
  Reasoning    string         `json:"reasoning"`
  Sources      pq.StringArray `gorm:"type:text[]" json:"sources"`
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Hide stance options when politician has no answer and filter 0-values from compareAnswers</name>
  <files>CompassV2/src/components/ComparePanel.jsx, CompassV2/src/pages/Compass.jsx</files>
  <action>
Two changes needed:

**ComparePanel.jsx** — In the stance list section (around line 166), wrap the stance buttons rendering in a condition so they only render when `polHasAnswered` is true OR when the user has answered (so they can still see/change their own stance). The key change: when `!polHasAnswered`, do NOT render the `stances.map(...)` block or the legend. Only render the "{polName} hasn't answered this topic yet." message.

Specifically, restructure the section inside `{topicSelected && selectedTopic && ( ... )}` so that:
- The topic heading (question text + tension name) always renders
- If `!polHasAnswered`:
  - Do NOT render the legend (You / polName dots)
  - Do NOT render the stances list (`stances.map(...)`)
  - Do NOT render the write-in block
  - DO render the "{polName} hasn't answered this topic yet." message
  - Do NOT render reasoning/sources section
- If `polHasAnswered`:
  - Render everything as before (legend, stances, write-in, message section removed, reasoning/sources)

**Compass.jsx** — In the compareAnswers builder (around line 557-563), instead of mapping unanswered topics to 0, exclude them entirely from the object. Change:
```javascript
return [t.short_title, a ? a.value : 0];
```
to:
```javascript
if (!a || a.value === 0) return null;
return [t.short_title, a.value];
```
This way unanswered topics produce `undefined` from `compareAnswers[dropdownValue]` instead of `0`, which is already handled by the `polHasAnswered` check (`undefined && undefined > 0` is falsy). This also fixes the radar chart: the RadarChart component will not receive 0-value entries in compareData, so unanswered spokes won't render a collapsed polygon point at 0.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/CompassV2 && npm run build</automated>
  </verify>
  <done>
    - When politician has no stance on selected topic: only topic heading and "hasn't answered" message visible, no stance buttons, no legend, no reasoning section
    - When politician has a stance: full stance list with dots, legend, and reasoning render as before
    - Radar chart no longer shows collapsed points at 0 for unanswered compare topics
    - Build succeeds with no errors
  </done>
</task>

<task type="auto">
  <name>Task 2: Remove Kerry Thomson trans-athletes bad data from CSVs and database</name>
  <files>EV-Backend/data/stance_research.csv, EV-Backend/data/ThomsonBanksYoungHouchin.csv</files>
  <action>
The Kerry Thomson trans-athletes stance data is inaccurate — the source URL (bloomington.in.gov/mayor) contains nothing about trans athletes, and there is no reasoning text. This needs to be removed from two places:

**1. Source CSV files (prevent re-import):**

- `EV-Backend/data/stance_research.csv` line 429: Remove the row `Kerry Thomson,,trans-athletes,2,https://bloomington.in.gov/mayor,,`
- `EV-Backend/data/ThomsonBanksYoungHouchin.csv`: Kerry Thomson does NOT have a trans-athletes row in this file (confirmed by inspection — her entries are abortion, same-sex-marriage, climate-change, fossil-fuels, civil-rights, housing, immigration, deportation). No change needed here.

**2. Database records:** Write and run a one-off SQL delete script. The executor should:
- First, find Kerry Thomson's politician ID: query `SELECT id, full_name FROM essentials.politicians WHERE full_name ILIKE '%Kerry Thomson%';`
- Then, find the trans-athletes topic ID: query `SELECT id, topic_key FROM compass.topics WHERE topic_key = 'trans-athletes';`
- Delete the answer: `DELETE FROM compass.answers WHERE politician_id = '<kerry_id>' AND topic_id = '<topic_id>';`
- Delete the context: `DELETE FROM compass.contexts WHERE politician_id = '<kerry_id>' AND topic_id = '<topic_id>';`
- Run these via `psql` using the DATABASE_URL from `.env.local`. If psql is not available or DATABASE_URL is not accessible, create a small Go script `cmd/fixdata/main.go` that connects via GORM and performs the deletes, then remove it after running.

NOTE: The ThomsonBanksYoungHouchin.csv file does NOT contain a Kerry Thomson trans-athletes row (it only has rows for topics: abortion, same-sex-marriage, climate-change, fossil-fuels, civil-rights, housing, immigration, deportation). Only stance_research.csv needs the row removed.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub && grep -c "Kerry Thomson.*trans-athlete" EV-Backend/data/stance_research.csv; test $? -eq 1 && echo "PASS: row removed" || echo "FAIL: row still present"</automated>
  </verify>
  <done>
    - Kerry Thomson trans-athletes row removed from stance_research.csv
    - Kerry Thomson trans-athletes answer and context records deleted from database (compass.answers and compass.contexts)
    - No other Kerry Thomson stances affected
  </done>
</task>

</tasks>

<verification>
1. `cd CompassV2 && npm run build` succeeds
2. `grep "Kerry Thomson.*trans-athlete" EV-Backend/data/stance_research.csv` returns no results
3. Manual verification: select a politician with missing stances on the compare page — only the "hasn't answered" message should appear, no stance buttons
</verification>

<success_criteria>
- ComparePanel hides stance option buttons when politician has no answer on selected topic
- ComparePanel shows only the "hasn't answered" message for unanswered topics
- Kerry Thomson trans-athletes data removed from source CSVs and database
- Radar chart does not render collapsed polygon points for unanswered compare topics
- Build passes cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/1-fix-compare-page-showing-0s-for-missing-/1-SUMMARY.md`
</output>
