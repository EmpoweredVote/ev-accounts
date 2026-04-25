---
quick_id: 260425-h57
slug: fix-quotes-office-join
title: Fix LEFT JOIN offices row multiplication in /api/essentials/quotes
date: 2026-04-25
status: in-progress
---

# Fix LEFT JOIN offices row multiplication in /api/essentials/quotes

## Problem
`LEFT JOIN essentials.offices o ON o.politician_id = p.id` in the `/api/essentials/quotes` query multiplies rows when a politician has multiple offices. Result: 124 rows for 92 unique quote IDs — duplicate quotes in the Read & Rank app.

## Fix
Replace the flat LEFT JOIN with a LATERAL subquery that returns at most one office per politician.

## File
`ev-accounts/backend/src/routes/essentials.ts` — lines ~211

## Change
Replace:
```sql
LEFT JOIN essentials.offices o ON o.politician_id = p.id
```
With:
```sql
LEFT JOIN LATERAL (
  SELECT title FROM essentials.offices
  WHERE politician_id = p.id
  ORDER BY id DESC
  LIMIT 1
) o ON true
```

## Tasks
- [ ] Edit essentials.ts to use LATERAL subquery
- [ ] Verify typecheck passes
- [ ] Commit
