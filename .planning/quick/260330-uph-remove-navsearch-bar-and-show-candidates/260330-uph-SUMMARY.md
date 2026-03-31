# Quick Task 260330-uph: Remove NavSearch bar and Show Candidates toggle

**Completed:** 2026-03-31

## Changes

### Removed NavSearch bar
- Removed `NavSearch` component rendering from `Layout.jsx`
- Deleted `components/NavSearch/` directory (NavSearch.jsx, NavSearchDropdown.jsx, NavSearchResult.jsx)
- Deleted `hooks/useNameSearch.js` hook
- Left `searchPoliticiansByName` in api.jsx for future reuse (global search will land elsewhere)

### Removed Show Candidates toggle
- Removed "Show Candidates" toggle button from `LocalFilterSidebar.jsx` (sidebar, desktop)
- Removed Candidates pill button from mobile Results view
- Removed candidate-related state: `showCandidates`, `candidateData`, `candidatesLoading`
- Removed `fetchCandidates` effect and import
- Removed `classifiedCandidates` and `candidateBySeat` memos
- Simplified `renderSeatGroup` (no longer merges challengers inline)
- Cleaned up `byTier` memo dependency on removed `classifiedCandidates`

### Rationale
- Candidates now live on the dedicated "Elections" page — the toggle on the Results page was redundant
- NavSearch (global politician search) created confusion with the sidebar filter (local results search) — a better home for global search will be decided later
- Sidebar "Search representative" filter remains as the sole search on Results page

## Build
Verified: `npm run build` passes cleanly.
