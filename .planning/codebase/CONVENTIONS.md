# Coding Conventions

**Analysis Date:** 2026-02-17

## Naming Patterns

**Files:**
- React components: PascalCase (e.g., `Layout.jsx`, `CompassContext.jsx`, `Dashboard.jsx`, `SwipeInstructions.tsx`)
- Utility/logic files: camelCase (e.g., `useReadRankStore.ts`, `useDeviceType.ts`, `matchingAlgorithm.ts`)
- Go packages: lowercase, grouped under `internal/` by feature (e.g., `internal/auth/`, `internal/essentials/`, `internal/compass/`)
- Go files: lowercase, descriptive (e.g., `models.go`, `handlers.go`, `routes.go`, `setup.go`, `client.go`)

**Functions:**
- React components: PascalCase (e.g., `function Dashboard()`, `function Layout()`)
- React hooks: camelCase with `use` prefix (e.g., `useDeviceType()`, `useIsTouchDevice()`, `useCompass()`)
- Zustand stores: camelCase with `use` prefix (e.g., `useReadRankStore()`)
- Go exported functions: PascalCase (e.g., `NewClient()`, `Geocode()`)
- Go unexported functions: camelCase (e.g., `sessionCookie()`, `registerHandler()`)
- Go handler functions: PascalCase suffix `Handler` (e.g., `RegisterHandler()`, `LoginHandler()`, `TopicHandler()`)

**Variables:**
- React: camelCase (e.g., `selectedTopics`, `activeQuery`, `filteredPols`, `isLocalType`)
- Go: camelCase for unexported, PascalCase for exported (e.g., `sessionID`, `expiresAt`, `SessionID`, `ExpiresAt`)
- Constants: UPPER_SNAKE_CASE (observed in data: `SMOOTH_TRANSITION`, `LOCAL_ORDER`, `FEDERAL_ORDER`)
- Type aliases: PascalCase with suffix (e.g., `BadgeType`, `DeviceType`, `Phase`, `RankedQuote`)

**Types:**
- TypeScript interfaces: PascalCase (e.g., `Quote`, `RankedQuote`, `BadgeAssignment`, `ReadRankState`, `IssueProgress`)
- Go structs: PascalCase (e.g., `User`, `Session`, `Client`, `OfficialOut`, `DegreeOut`)
- Enum-like types with suffix convention: `Type` (e.g., `BadgeType`, `DeviceType`, `Phase`)

## Code Style

**Formatting:**
- JavaScript/TypeScript: No explicit Prettier config; indentation appears to be 2 spaces based on observed code
- JSX: Multi-line element formatting with props on new lines for readability
- Go: Standard Go formatting (implicit `gofmt`); no custom config detected

**Linting:**
- JavaScript/TypeScript: ESLint 9.x with flat config format (`eslint.config.js`)
- Rules enforced:
  - `no-unused-vars` with `varsIgnorePattern: '^[A-Z_]'` (allows unused uppercase/underscore-prefixed vars)
  - `react-refresh/only-export-components` warns if non-component exports from component files
  - React Hooks rules enforced (`react-hooks.configs.recommended`)
- Go: Standard linting via compiler; no explicit linter config

**Comments:**
- Line comments for simple explanations (e.g., `// Fetch topics from server`)
- Block comments for multi-line explanations or disabled code sections
- Comments placed above code they describe
- Avoid over-commenting obvious code; focus on "why" not "what"

## Import Organization

**JavaScript/TypeScript:**
Order by precedence:
1. React and React ecosystem imports (e.g., `import { useState, useEffect } from "react"`)
2. Third-party library imports (e.g., `import { create } from 'zustand'`, `import { DndContext } from "@dnd-kit/core"`)
3. Internal project imports (e.g., `import Dashboard from "../components/Dashboard"`, `import { usePoliticianData } from "../hooks/usePoliticianData"`)

Example from `Dashboard.jsx`:
```javascript
import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import PoliticianGrid from "../components/PoliticianGrid";
import { usePoliticianData } from "../hooks/usePoliticianData";
import {
  classifyCategory,
  STATE_ORDER,
  FEDERAL_ORDER,
  orderedEntries,
} from "../lib/classify";
```

**Go:**
Standard Go conventions with groups:
1. Standard library imports (e.g., `import "net/http"`, `"encoding/json"`, `"time"`)
2. Third-party imports (e.g., `"github.com/go-chi/chi/v5"`, `"gorm.io/gorm"`)
3. Internal imports (e.g., `"github.com/EmpoweredVote/EV-Backend/internal/db"`)

Example from `essentials/handlers.go`:
```go
import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/EmpoweredVote/EV-Backend/internal/db"
	"github.com/EmpoweredVote/EV-Backend/internal/essentials/ballotready"
	"github.com/EmpoweredVote/EV-Backend/internal/essentials/cicero"
	"github.com/EmpoweredVote/EV-Backend/internal/essentials/provider"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)
```

**Path Aliases:**
- React projects use relative imports (e.g., `"../components/CompassContext"`, `"../lib/classify"`)
- No path aliases configured; maintain relative path consistency

## Error Handling

**JavaScript/TypeScript:**
- Try/catch for async operations with graceful fallback
- Pattern from `CompassContext.jsx`:
```javascript
const refreshData = async () => {
  try {
    const [topicsRes, catsRes] = await Promise.all([
      fetch(`${API}/compass/topics`, {
        credentials: "include",
      }).then((r) => r.json()),
      fetch(`${API}/compass/categories`, {
        credentials: "include",
      }).then((r) => r.json()),
    ]);
    setTopics(topicsRes);
    setCategories(catsRes);
  } catch {
    // Server unreachable — state stays at defaults
  }
};
```
- `.catch(() => {})` or empty catch blocks for non-critical operations (API calls may silently fail)
- Errors logged to console only for debugging: `console.error(err)`
- User-facing errors displayed in UI components with error state rendering

**Go:**
- Early return pattern with error checking: `if err != nil { http.Error(...); return }`
- Error messages using `http.Error(w, message, statusCode)`
- Pattern from `handlers.go`:
```go
err = db.DB.First(&existing, "username = ?", user.Username).Error
if err == nil {
  http.Error(w, "Username already taken", http.StatusConflict)
  return
}
```
- Errors prefixed with context (e.g., `"DB error: " + result.Error.Error()`)
- No panic in handlers; return HTTP error responses
- GORM error handling: check `.Error` field on db operations
- Logging with `log` package for non-critical issues

## Logging

**JavaScript/TypeScript:**
- Primary: `console.error()` for exceptions
- Pattern: `console.error(err)` without elaborate formatting
- Minimal logging in production; mostly for debugging
- No structured logging framework detected

**Go:**
- Standard `log` package imported but usage not heavily enforced
- Error messages passed through `http.Error()` for HTTP responses
- No structured logging framework (e.g., logrus, zap) detected
- Errors propagated via return values, not logged internally

## Comments

**When to Comment:**
- Use JSDoc/TSDoc for exported functions and complex logic
- Explain "why" rather than "what" (code should be self-documenting for "what")

**JSDoc/TSDoc Pattern:**
From `useDeviceType.ts`:
```typescript
/**
 * Hook to detect whether the user is primarily using touch or mouse input.
 * Updates dynamically if the user switches input methods.
 */
export function useDeviceType(): DeviceType {
  // ...
}

/**
 * Returns true if the device is primarily touch-based
 */
export function useIsTouchDevice(): boolean {
  // ...
}
```

**Go Documentation Comments:**
- Package-level comments describe package purpose (e.g., `// Client is a GraphQL client for the BallotReady/CivicEngine API.`)
- Exported types/functions prefixed with `// FunctionName description` or `// TypeName description`
- Example from `ballotready/client.go`:
```go
// Client is a GraphQL client for the BallotReady/CivicEngine API.
type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

// NewClient creates a new BallotReady API client.
func NewClient(apiKey, endpoint string) *Client {
```

## Function Design

**Size:**
- Keep functions focused on single responsibility
- Examples in codebase range from ~5 lines (`useIsMouseDevice`) to ~80+ lines (`useReadRankStore` with full state management)
- Component functions and handlers tend toward 50-100 lines

**Parameters:**
- React: Props destructured in function signature or used as single object (e.g., `function Dashboard()` with hooks inside)
- Go handlers: Standard `(w http.ResponseWriter, r *http.Request)` signature
- Go helper functions: Pass necessary context explicitly (e.g., `NewClient(apiKey, endpoint string)`)

**Return Values:**
- React components: Return JSX/React elements
- React hooks: Return state, functions, or combined objects (e.g., `useCompass()` returns object with all state + actions)
- Go handlers: Return nothing; write to `http.ResponseWriter`
- Go functions: Single return value (result) or error pattern (e.g., `client.Geocode() (result, error)`)

## Module Design

**Exports:**
- React: Default export for components (e.g., `export default Dashboard`)
- React Context: Named export for provider, custom hook (e.g., `export function CompassProvider()`, `export const useCompass()`)
- TypeScript: Named exports for types and interfaces
- Go: All exports capitalized by convention; no explicit `export` keyword needed

**Barrel Files:**
- Not extensively used; relative imports preferred
- When aggregating, place imports in consuming component

## State Management Patterns

**React Context:**
- Used in CompassV2 via `CompassContext.jsx` with provider + custom hook pattern
- State includes topics, answers, selectedTopics, invertedSpokes
- Includes side-effect management (localStorage sync, server sync with debounce)
- Pattern: `export const useCompass = () => useContext(CompassContext)`

**Zustand:**
- Used in read-rank for complex cross-issue state (`useReadRankStore`)
- Includes `persist` middleware for localStorage integration
- Actions expose both immutable state updates and getter methods
- Pattern: Single store with per-issue progress tracking + legacy flat state for backwards compatibility

**Component State:**
- Local `useState` for UI state (active tabs, input values)
- `useMemo` for expensive computations dependent on state
- `useRef` for non-state side effect tracking (e.g., `serverLoaded`, `syncTimer`)

## Type Usage

**TypeScript:**
- Strict typing enforced; avoid `any` types
- Interface pattern for data structures (see `useReadRankStore.ts`)
- Type aliases for union types (e.g., `type Phase = 'hub' | 'evaluation' | 'ranking' | 'results'`)
- Discriminated unions for state variants

**Go:**
- Struct-based models with GORM tags (e.g., `gorm:"primaryKey"`, `json:"user_id"`)
- Exported struct fields start with capital letter
- Type assertions used but minimal; prefer concrete types

---

*Convention analysis: 2026-02-17*
