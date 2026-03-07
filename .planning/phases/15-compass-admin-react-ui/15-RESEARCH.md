# Phase 15: Compass Admin React UI - Research

**Researched:** 2026-03-06
**Domain:** React admin UI — list/panel layout, modal forms, inline editing, API integration
**Confidence:** HIGH

## Summary

Phase 15 extends an existing React + Vite + Tailwind v4 admin app (no external UI library beyond
@headlessui/react v2.2.9). The existing pages follow a clear pattern: `apiFetch` for all API calls,
`useState` + `useEffect` for data fetching, and Tailwind utility classes for all styling. No form
library, no query library, no state manager beyond Zustand (used only for auth). All three new
pages (Topics, Politicians, Categories) follow this same pattern — no new dependencies required.

The key UI decisions from CONTEXT.md are: slide-out panels alongside lists (not navigation to a
separate page), a modal dialog for topic creation, Headless UI components for accessible interactive
patterns (Dialog, RadioGroup, Disclosure), and inline save feedback (spinner → checkmark on the
button itself rather than a toast notification). All of these are well-supported by the already-
installed @headlessui/react v2.2.9.

The backend (Phase 14) is complete. The route manifest is fully documented and verified. All 12
routes exist at `/api/admin/compass/*` and require admin JWT. The frontend has one thin
`apiFetch` wrapper that handles auth headers automatically. No new backend work is required.

**Primary recommendation:** Build all three compass pages using the existing admin patterns
(apiFetch + useState + Tailwind) with @headlessui/react for Dialog (topic creation modal) and
Disclosure (expandable topic rows in politician panel). No new npm packages needed.

## Standard Stack

### Core (already installed — zero new dependencies)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 18.3.1 | UI framework | Already in project |
| react-router-dom | 6.30.3 | Routing | Already in project |
| @headlessui/react | 2.2.9 | Accessible Dialog, RadioGroup, Disclosure | Already installed, covers all needed interaction patterns |
| Tailwind v4 | 4.0.0 | Styling | Already configured with brand tokens |
| Zustand | 5.0.11 | Auth store | Already used — read accessToken only |
| TypeScript | 5.6.0 | Type safety | Already configured |

### No New Dependencies Required

The existing stack covers all requirements:
- Modal dialog → `Dialog` + `DialogPanel` + `DialogTitle` from @headlessui/react
- Slide-out panel → positioned `div` with `Transition` from @headlessui/react
- Expandable topic rows → `Disclosure` + `DisclosureButton` + `DisclosurePanel` from @headlessui/react
- Radio-style stance selector → `RadioGroup` + `Radio` from @headlessui/react
- Inline save state → local `useState` per save button (idle/saving/done/error)
- API calls → existing `apiFetch` in `admin/src/lib/api.ts`

**Installation:**
```bash
# No new packages needed
```

## Architecture Patterns

### Recommended Project Structure
```
admin/src/pages/admin/
├── TopicsPage.tsx           # List + slide-out panel (split layout)
├── PoliticiansPage.tsx      # List + slide-out panel (split layout)
├── CategoriesPage.tsx       # Simple list + create form
```

Note: No separate component subfolder needed for this phase — each page file is self-contained,
following the existing pattern (AccountsPage.tsx, RolesPage.tsx). If components grow large,
extract to named sub-components in the same file with local `function` declarations.

### Pattern 1: Split List + Slide-Out Panel Layout

**What:** Page renders two columns: left is the scrollable list, right is a fixed panel for the
selected item. No navigation — both visible simultaneously.

**When to use:** Topics page (select topic → see detail/stances), Politicians page (select
politician → see profile + answers).

**Implementation approach:**
```tsx
// admin/src/pages/admin/TopicsPage.tsx
export function TopicsPage() {
  const [topics, setTopics] = useState<Topic[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  const selectedTopic = topics.find(t => t.id === selectedId) ?? null;

  return (
    <div className="flex gap-6 h-full">
      {/* Left: list */}
      <div className="w-80 shrink-0 flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Topics</h1>
          <button onClick={() => setIsCreateOpen(true)} className="...">New Topic</button>
        </div>
        {/* topic rows */}
        {topics.map(topic => (
          <div
            key={topic.id}
            onClick={() => setSelectedId(topic.id)}
            className={`... cursor-pointer ${selectedId === topic.id ? 'bg-blue-50 border-blue-300' : ''}`}
          >
            <span>{topic.title}</span>
            {/* live/draft toggle inline */}
            <LiveToggle topic={topic} onUpdate={refreshTopics} />
          </div>
        ))}
      </div>

      {/* Right: detail panel */}
      {selectedTopic && (
        <div className="flex-1 bg-white rounded-lg shadow p-6 overflow-auto">
          <TopicDetailPanel topic={selectedTopic} onUpdate={refreshTopics} />
        </div>
      )}

      {/* Create modal */}
      <CreateTopicModal
        open={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onCreated={(newTopic) => {
          refreshTopics();
          setSelectedId(newTopic.id);
          setIsCreateOpen(false);
        }}
      />
    </div>
  );
}
```

### Pattern 2: Topic Creation Modal (Headless UI Dialog)

**What:** Dialog with topic fields + 5 stance text fields. Submits POST /api/admin/compass/topics.
After success: modal closes, new topic's panel auto-opens.

**Headless UI v2 Dialog API (verified from installed types):**

Key facts about @headlessui/react v2 Dialog:
- `Dialog` accepts `open: boolean` and `onClose: (value: boolean) => void`
- `DialogPanel` is the scrollable content wrapper
- `DialogTitle` for accessible title (renders as `h2` by default)
- `transition` prop on `DialogPanel` enables CSS-class-driven enter/leave animation
- The sub-component dot notation (`Dialog.Panel`, `Dialog.Title`) is deprecated in v2 — use
  named exports (`DialogPanel`, `DialogTitle`) directly

```tsx
// Source: node_modules/@headlessui/react/dist/components/dialog/dialog.d.ts
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

function CreateTopicModal({ open, onClose, onCreated }) {
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // local form state for title, question_text, short_title, stances[1..5]
  const [form, setForm] = useState({
    title: '',
    question_text: '',
    short_title: '',
    stances: ['', '', '', '', ''], // indices 0-4 map to values 1-5
  });

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const result = await apiFetch<{ topic: Topic; stances: Stance[] }>(
        '/admin/compass/topics',
        {
          method: 'POST',
          body: JSON.stringify({
            title: form.title,
            question_text: form.question_text,
            short_title: form.short_title || undefined,
            stances: form.stances.map((text, i) => ({ value: i + 1, text }))
                         .filter(s => s.text.trim()),
          }),
        }
      );
      onCreated(result.topic);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create topic');
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="bg-white rounded-lg shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-auto">
          <DialogTitle className="text-lg font-semibold text-gray-900 mb-4">
            New Topic
          </DialogTitle>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* title, question_text, short_title fields */}
            {/* Stance fields 1-5 */}
            {[1,2,3,4,5].map(val => (
              <div key={val}>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Stance {val}
                </label>
                <input
                  type="text"
                  value={form.stances[val - 1]}
                  onChange={e => {
                    const next = [...form.stances];
                    next[val - 1] = e.target.value;
                    setForm(f => ({ ...f, stances: next }));
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm ..."
                />
              </div>
            ))}
            {error && <div className="text-red-600 text-sm">{error}</div>}
            <div className="flex gap-3 justify-end">
              <button type="button" onClick={() => onClose(false)} className="...">Cancel</button>
              <button type="submit" disabled={saving} className="...">
                {saving ? 'Creating...' : 'Create Topic'}
              </button>
            </div>
          </form>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
```

### Pattern 3: Inline Save Feedback (Spinner → Checkmark)

**What:** Save button cycles through states: `'idle' | 'saving' | 'done' | 'error'`. After success,
shows checkmark for 2 seconds, then resets to idle.

**Why inline over toast:** Decided by user in CONTEXT.md. Admin context — the actor knows what
they just saved, no need for a notification that persists outside the action.

```tsx
type SaveState = 'idle' | 'saving' | 'done' | 'error';

function SaveButton({ onSave, label = 'Save' }: { onSave: () => Promise<void>; label?: string }) {
  const [state, setState] = useState<SaveState>('idle');

  async function handleClick() {
    setState('saving');
    try {
      await onSave();
      setState('done');
      setTimeout(() => setState('idle'), 2000);
    } catch {
      setState('error');
      setTimeout(() => setState('idle'), 3000);
    }
  }

  const labels: Record<SaveState, string> = {
    idle: label,
    saving: 'Saving...',
    done: 'Saved',
    error: 'Error — retry',
  };

  return (
    <button
      onClick={handleClick}
      disabled={state === 'saving'}
      className={`px-3 py-1.5 text-sm rounded-md font-medium transition-colors ${
        state === 'done' ? 'bg-green-600 text-white' :
        state === 'error' ? 'bg-red-600 text-white' :
        'bg-ev-yellow text-ev-black hover:bg-yellow-400 disabled:opacity-50'
      }`}
    >
      {labels[state]}
    </button>
  );
}
```

### Pattern 4: Expandable Topic Rows in Politician Panel (Headless UI Disclosure)

**What:** Each topic in the politician's answer section is a collapsible row. Click header to
expand; shows answer selector + reasoning + sources when open.

**Headless UI v2 Disclosure API (verified from installed types):**
- `Disclosure` wraps one row — no `open` prop needed (manages own state)
- `DisclosureButton` is the clickable header
- `DisclosurePanel` is the collapsible content
- Both named exports (not dot notation) are the v2 API

```tsx
// Source: node_modules/@headlessui/react/dist/components/disclosure/disclosure.d.ts
import { Disclosure, DisclosureButton, DisclosurePanel } from '@headlessui/react';

function TopicAnswerRow({ topic, stances, answer, onSave }) {
  return (
    <Disclosure>
      <DisclosureButton className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 text-sm font-medium text-left rounded-md">
        <span>{topic.title}</span>
        <span className="text-xs text-gray-500">
          {answer ? `Stance ${answer.value}` : 'Not answered'}
        </span>
      </DisclosureButton>
      <DisclosurePanel className="px-4 py-3 space-y-3">
        {/* Stance selector using RadioGroup */}
        <StanceSelector
          stances={stances}
          value={answer?.value ?? null}
          onChange={...}
        />
        {/* Reasoning textarea */}
        {/* Sources list */}
        <SaveButton onSave={() => onSave(topicId, selectedValue, reasoning, sources)} />
      </DisclosurePanel>
    </Disclosure>
  );
}
```

### Pattern 5: Stance Selector (RadioGroup)

**What:** For a politician's answer, show all 5 stance texts as selectable options (not just
numeric). The admin must see the actual text, not a number, to know what they're assigning.

**Headless UI v2 RadioGroup API (verified from installed types):**
- `RadioGroup` accepts `value`, `onChange`
- `Radio` is the individual option (replaces deprecated `RadioGroup.Option`)
- Render prop on `Radio` provides `{ checked, hover, focus, disabled }`

```tsx
// Source: node_modules/@headlessui/react/dist/components/radio-group/radio-group.d.ts
import { RadioGroup, Radio } from '@headlessui/react';

function StanceSelector({ stances, value, onChange }) {
  return (
    <RadioGroup value={value} onChange={onChange} className="space-y-2">
      {stances.map(stance => (
        <Radio
          key={stance.value}
          value={stance.value}
          className={({ checked }) =>
            `flex items-start gap-3 p-3 rounded-md border cursor-pointer text-sm ${
              checked
                ? 'border-ev-yellow bg-yellow-50'
                : 'border-gray-200 hover:border-gray-300'
            }`
          }
        >
          <span className="font-medium text-gray-500 w-4 shrink-0">{stance.value}</span>
          <span className="text-gray-900">{stance.text}</span>
        </Radio>
      ))}
    </RadioGroup>
  );
}
```

### Pattern 6: Live/Draft Toggle

**What:** Toggle `is_live` for a topic. Appears both in list row and in panel header. Single PATCH
call on toggle.

**Implementation:** Plain `<button>` with optimistic local state update, then API call. On error,
revert.

```tsx
function LiveToggle({ topic, onUpdate }: { topic: Topic; onUpdate: () => void }) {
  const [isLive, setIsLive] = useState(topic.is_live);
  const [saving, setSaving] = useState(false);

  async function handleToggle(e: React.MouseEvent) {
    e.stopPropagation(); // don't trigger row click
    const next = !isLive;
    setIsLive(next); // optimistic
    setSaving(true);
    try {
      await apiFetch(`/admin/compass/topics/${topic.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_live: next }),
      });
      onUpdate();
    } catch {
      setIsLive(!next); // revert on error
    } finally {
      setSaving(false);
    }
  }

  return (
    <button
      onClick={handleToggle}
      disabled={saving}
      className={`px-2 py-0.5 rounded-full text-xs font-medium ${
        isLive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
      } disabled:opacity-50`}
    >
      {isLive ? 'Live' : 'Draft'}
    </button>
  );
}
```

### Pattern 7: Stance Inline Edit in Topic Panel

**What:** Each of the 5 stance texts is displayed as read-only text. Click any text to enter edit
mode for that stance. A single "Save stances" button commits all 5 via 5 sequential PATCH calls
(one per stance ID).

**Why 5 separate calls:** Backend exposes `PATCH /api/admin/compass/stances/:id` per stance. No
batch update endpoint exists.

```tsx
// State needed in TopicDetailPanel:
const [stanceEdits, setStanceEdits] = useState<Record<number, string>>({}); // stanceId -> newText
const [editingStances, setEditingStances] = useState(false);

async function saveStances() {
  // For each stance where stanceEdits[id] differs from current text:
  await Promise.all(
    stances
      .filter(s => stanceEdits[s.id] !== undefined && stanceEdits[s.id] !== s.text)
      .map(s =>
        apiFetch(`/admin/compass/stances/${s.id}`, {
          method: 'PATCH',
          body: JSON.stringify({ text: stanceEdits[s.id] }),
        })
      )
  );
  // refresh stances, clear edits
}
```

### Pattern 8: Sources Array (Add/Remove)

**What:** In politician panel, each expanded topic row has a sources list (string[]) with add/remove.

```tsx
function SourcesList({ sources, onChange }: { sources: string[]; onChange: (s: string[]) => void }) {
  const [newSource, setNewSource] = useState('');

  function add() {
    if (newSource.trim()) {
      onChange([...sources, newSource.trim()]);
      setNewSource('');
    }
  }

  return (
    <div className="space-y-2">
      <label className="block text-xs font-medium text-gray-600 uppercase tracking-wide">Sources</label>
      {sources.map((src, i) => (
        <div key={i} className="flex items-center gap-2">
          <span className="flex-1 text-sm text-gray-700 truncate">{src}</span>
          <button
            onClick={() => onChange(sources.filter((_, j) => j !== i))}
            className="text-xs text-red-500 hover:text-red-700"
          >
            Remove
          </button>
        </div>
      ))}
      <div className="flex gap-2">
        <input
          type="text"
          value={newSource}
          onChange={e => setNewSource(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && (e.preventDefault(), add())}
          placeholder="https://..."
          className="flex-1 px-2 py-1.5 text-sm border border-gray-300 rounded-md"
        />
        <button onClick={add} className="px-2 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50">
          Add
        </button>
      </div>
    </div>
  );
}
```

### Pattern 9: Topic Filter Search in Politician Panel

**What:** As topic count grows, a search field within the politician panel filters the visible topic
rows by title. Client-side filtering (all topics loaded at once).

```tsx
const [topicSearch, setTopicSearch] = useState('');
const filteredTopics = topics.filter(t =>
  t.title.toLowerCase().includes(topicSearch.toLowerCase())
);
```

### Anti-Patterns to Avoid

- **Using `Dialog.Panel` dot-notation:** Deprecated in @headlessui/react v2. Use named exports
  `DialogPanel`, `DialogTitle`, `DisclosureButton`, `DisclosurePanel`, `Radio` instead.
- **Using `RadioGroup.Option`:** Deprecated in v2 — use `Radio` directly.
- **Navigating to detail page instead of panel:** CONTEXT.md locks slide-out panel pattern. Do not
  add new routes for topic/:id or politician/:id detail pages.
- **Using `apiFetch` with `PUT` for topics/:id or stances/:id:** Backend uses `PATCH`, not `PUT`.
  `PUT` is only used for `/topics/:id/categories` and `/politicians/:id/answers`.
- **Batch saving stances via a non-existent bulk endpoint:** No bulk stance update exists. Must
  PATCH each stance ID individually.
- **Fetching stances inside POST /topics response only:** The GET /topics list response does NOT
  include stances. Stances must be fetched separately via
  `GET /api/admin/compass/topics/:id/stances` when a topic panel opens.
- **Showing numeric stance labels for politician answer selector:** CONTEXT.md explicitly requires
  showing actual stance text. The admin cannot meaningfully assign a stance without seeing the text.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessible modal dialog | Custom div with manual focus trap | `Dialog` from @headlessui/react | Focus trap, keyboard dismiss, scroll lock, ARIA attributes |
| Expandable accordion rows | Manual `open` state + conditional render | `Disclosure` from @headlessui/react | Proper ARIA expanded/controls, keyboard accessible |
| Radio-style selection | Custom div onClick handlers | `RadioGroup` + `Radio` from @headlessui/react | ARIA radiogroup/radio, keyboard navigation |
| Backdrop overlay | Manual fixed positioned div | Render as sibling of `DialogPanel` inside `Dialog` | Headless UI handles z-index and click-outside correctly |

**Key insight:** @headlessui/react is already installed and covers every interactive pattern in this
phase. There is no reason to add a UI library (MUI, shadcn, etc.) or build custom accessible
components.

## Common Pitfalls

### Pitfall 1: Stances Not Loaded When Panel Opens
**What goes wrong:** Topics list returns `{id, title, short_title, is_live}` — no stances. Opening
a topic panel with empty stances because the detail fetch wasn't wired.
**Why it happens:** Assuming POST /topics response is the source of truth for the panel. It isn't
(only returned on create).
**How to avoid:** When `selectedTopicId` changes, fetch `GET /api/admin/compass/topics/:id/stances`
and store the result in panel state alongside the topic. Don't derive stances from the list.
**Warning signs:** Stance editor renders 5 empty inputs on first panel open.

### Pitfall 2: Live Toggle Triggering Row Selection
**What goes wrong:** Clicking the live/draft toggle also selects the row (fires the parent `onClick`).
**Why it happens:** Click event bubbles from toggle button up to row div.
**How to avoid:** Call `e.stopPropagation()` in the toggle's onClick handler.
**Warning signs:** Panel opens/closes when toggling live status.

### Pitfall 3: Stale Stances After Save
**What goes wrong:** Admin updates stance text, saves, sees old text re-appear (stale state).
**Why it happens:** Panel state holds original stances fetched on open. After PATCH, local state
not updated.
**How to avoid:** After saving stances, re-fetch from `GET /api/admin/compass/topics/:id/stances`
and update panel state. Or apply the saved values directly from the PATCH responses.
**Warning signs:** Stance text reverts after "Saved" button shows success.

### Pitfall 4: Politician Answers + Context Are Separate API Calls
**What goes wrong:** Opening a politician panel only fetches profile data, not answers.
**Why it happens:** There is no single "get politician with all answers" endpoint.
**How to avoid:** When politician panel opens, issue two parallel fetches:
- `GET /api/admin/compass/politicians/:id/answers` → current answer values per topic
- All topics (already loaded at page level)
Merge answers into topic rows by `topic_id`. Context (reasoning + sources) is per-topic and fetched
lazily when a topic row expands, or eagerly all at once — choose eager for simplicity since topic
count is small for Alpha.
**Warning signs:** Politician panel shows all topic rows as "Not answered" even after answers exist.

### Pitfall 5: Context Not Persisted Before Answer Save
**What goes wrong:** Admin fills in reasoning + sources but saves answer value only (wrong endpoint
or missed fields).
**Why it happens:** The PUT /politicians/:id/answers endpoint takes `{answers: [{topic_id, value}]}`
— it does NOT accept reasoning/sources. Context is a separate POST to
`/politicians/:id/context` with `{topic_id, reasoning, sources}`.
**How to avoid:** The "Save" button for a politician topic row must fire TWO calls if context fields
are non-empty: first PUT answers (for the value), then POST context (for reasoning/sources). Both
calls are part of the same save action. If value is unchanged but reasoning changed, still need
the context call.
**Warning signs:** Answer values save but reasoning text disappears on panel re-open.

### Pitfall 6: Category Assignment Is a Replace Operation
**What goes wrong:** Admin assigns a new category to a topic, but the UI sends only the new
category ID, wiping existing assignments.
**Why it happens:** `PUT /api/admin/compass/topics/:id/categories` with `{category_ids}` replaces
ALL category assignments for that topic (full replace semantics, not append).
**How to avoid:** When assigning categories, always send the complete list of desired category IDs
(current assignments + any new ones). Fetch current assignments before rendering the UI or track
them in state.
**Warning signs:** Adding a second category removes the first one.

### Pitfall 7: AdminLayout `overflow-auto` on Main Content
**What goes wrong:** The split list+panel layout doesn't fill the viewport correctly — panel scrolls
with page instead of independently.
**Why it happens:** AdminLayout wraps content in `<main className="flex-1 overflow-auto"><div className="p-8">`.
The `p-8` wrapper div is not height-constrained.
**How to avoid:** For compass pages that need the split layout, override the default padding or
handle scroll within the panel's own container using `overflow-auto` on the right panel div with
`max-h` or `h-full` constraints. The list left column can scroll independently too.
**Warning signs:** The whole page scrolls as one unit instead of just the panel content.

## Code Examples

Verified patterns from codebase inspection:

### apiFetch Usage (from admin/src/lib/api.ts)
```typescript
// Source: admin/src/lib/api.ts (direct file read)
// GET with query params:
apiFetch<{ topics: Topic[] }>('/admin/compass/topics')

// POST:
apiFetch<{ topic: Topic; stances: Stance[] }>('/admin/compass/topics', {
  method: 'POST',
  body: JSON.stringify({ title, question_text, stances }),
})

// PATCH:
apiFetch<Topic>(`/admin/compass/topics/${id}`, {
  method: 'PATCH',
  body: JSON.stringify({ is_live: true }),
})

// PUT (for answers and category assignment):
apiFetch(`/admin/compass/politicians/${id}/answers`, {
  method: 'PUT',
  body: JSON.stringify({ answers: [{ topic_id, value }] }),
})
```

### Standard Loading Skeleton (from AccountsPage.tsx)
```tsx
// Source: admin/src/pages/admin/AccountsPage.tsx (direct file read)
{loading ? (
  Array.from({ length: 5 }).map((_, i) => (
    <tr key={i} className="animate-pulse">
      <td colSpan={5} className="px-4 py-3">
        <div className="h-4 bg-gray-200 rounded w-full"></div>
      </td>
    </tr>
  ))
) : ...}
```

### Standard Error Display
```tsx
// Pattern from AccountsPage.tsx and AccountDetailPage.tsx
{error && (
  <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
    {error}
  </div>
)}
```

### Standard Empty State
```tsx
// Pattern from AccountsPage.tsx
<tr>
  <td colSpan={5} className="px-4 py-8 text-center text-gray-400">
    No topics found.
  </td>
</tr>
```

### NavItem Addition to AdminLayout
```tsx
// Source: admin/src/pages/admin/AdminLayout.tsx (direct file read)
// Add to navItems array (flat — no Compass section grouping):
const navItems = [
  { label: 'Dashboard', to: '/admin', exact: true },
  { label: 'Accounts', to: '/admin/accounts' },
  { label: 'Invites', to: '/admin/invites' },
  { label: 'Invite Tree', to: '/admin/invites/tree' },
  { label: 'Cron Log', to: '/admin/cron-log' },
  { label: 'Roles', to: '/admin/roles' },
  // ADD:
  { label: 'Topics', to: '/admin/topics' },
  { label: 'Politicians', to: '/admin/politicians' },
  { label: 'Categories', to: '/admin/categories' },
];
```

### Route Registration in App.tsx
```tsx
// Source: admin/src/App.tsx (direct file read)
// Add inside the AdminLayout Route:
<Route path="topics" element={<TopicsPage />} />
<Route path="politicians" element={<PoliticiansPage />} />
<Route path="categories" element={<CategoriesPage />} />
```

## Complete API Contract Reference

This is the definitive contract for all 12 backend routes (source: Phase 14 plan verified against implementation):

| Method | Path | Request Body | Response Shape |
|--------|------|--------------|----------------|
| GET | `/api/admin/compass/topics` | — | `{ topics: [{id, title, short_title, is_live, created_at, updated_at}] }` |
| POST | `/api/admin/compass/topics` | `{title, question_text, short_title?, is_live?, stances?: [{value(1-5), text}]}` | `{topic: {...}, stances: [{id, value, text}]}` |
| PATCH | `/api/admin/compass/topics/:id` | `{title?, short_title?, question_text?, is_live?}` | updated topic record |
| GET | `/api/admin/compass/topics/:id/stances` | — | stances array for that topic |
| PATCH | `/api/admin/compass/stances/:id` | `{text?, value?}` | updated stance record |
| GET | `/api/admin/compass/categories` | — | `{ categories: [{id, title, created_at}] }` |
| POST | `/api/admin/compass/categories` | `{title}` | created category record |
| PUT | `/api/admin/compass/topics/:id/categories` | `{category_ids: string[]}` | `{ ok: true }` |
| GET | `/api/admin/compass/politicians` | — | `{ politicians: [{id, first_name, last_name, preferred_name, full_name, office_title, photo_origin_url, is_active, is_candidate, created_at, answer_count}] }` |
| POST | `/api/admin/compass/politicians` | `{first_name, last_name, preferred_name?, full_name?, office_title?, photo_origin_url?, is_candidate?}` | created politician record |
| PATCH | `/api/admin/compass/politicians/:id` | `{first_name?, last_name?, preferred_name?, full_name?, office_title?, photo_origin_url?, is_active?, is_candidate?}` | updated politician record |
| PUT | `/api/admin/compass/politicians/:id/answers` | `{answers: [{topic_id, value(1-5)}]}` | `{ ok: true }` |
| POST | `/api/admin/compass/politicians/:id/context` | `{topic_id, reasoning, sources?: string[]}` | upserted context record |

**Error shape:** `{ error: 'message' }` or `{ error: 'message', details: ... }` for validation failures.
**Auth:** All routes require `Authorization: Bearer <admin_jwt>` — handled automatically by `apiFetch`.

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `Dialog.Panel` dot notation | `DialogPanel` named export | v2 change; dot notation deprecated but still works |
| `RadioGroup.Option` | `Radio` | v2 change; `RadioGroup.Option` deprecated |
| `Transition.Root` / `Transition.Child` | `Transition` / `TransitionChild` | v2 change; old names deprecated |
| Separate page route for detail view | Slide-out panel same page | CONTEXT.md decision for this phase |

## Open Questions

1. **Context fetch strategy for politician panel**
   - What we know: There is no `GET /politicians/:id/context` route (Phase 14 only added POST).
     There's also no batch "get all context for this politician" endpoint.
   - What's unclear: Is context data needed on panel open, or only when a topic row is expanded?
   - Recommendation: Fetch context lazily per topic row on expansion. Track which topic rows have
     had their context fetched in local state (`Record<topicId, ContextData | null>`). On first
     expand of each topic, POST is available for save but there's no GET. Verify in backend
     adminService whether `politician_context` table supports SELECT by politician_id to expose
     a missing route, OR design the UI to treat context as write-only (set it, can't read it back
     in admin). Clarify before building PoliticiansPage.

2. **GET /api/admin/compass/politicians/:id/answers response shape**
   - What we know: The route exists (`GET /api/admin/compass/politicians/:id/answers`).
   - What's unclear: Exact response shape — does it return `{answers: [{topic_id, value}]}` or
     the full stance record? Need to verify by reading adminService.ts.
   - Recommendation: Read `backend/src/lib/adminService.ts` at plan time to confirm shape before
     writing the PoliticiansPage data-fetch code.

## Sources

### Primary (HIGH confidence)
- `admin/src/pages/admin/AdminLayout.tsx` — existing sidebar nav pattern, layout structure
- `admin/src/pages/admin/AccountsPage.tsx` — list page pattern, apiFetch usage, loading skeleton
- `admin/src/pages/admin/AccountDetailPage.tsx` — detail panel pattern, action buttons, error handling
- `admin/src/lib/api.ts` — apiFetch wrapper, auth header injection
- `admin/src/App.tsx` — route registration pattern
- `admin/package.json` — confirmed exact installed versions
- `admin/node_modules/@headlessui/react/dist/components/dialog/dialog.d.ts` — v2 Dialog API
- `admin/node_modules/@headlessui/react/dist/components/disclosure/disclosure.d.ts` — v2 Disclosure API
- `admin/node_modules/@headlessui/react/dist/components/radio-group/radio-group.d.ts` — v2 RadioGroup/Radio API
- `admin/node_modules/@headlessui/react/dist/components/transition/transition.d.ts` — v2 Transition API
- `.planning/phases/14-compass-admin-backend/14-03-PLAN.md` — complete route manifest with all 12 routes

### Secondary (MEDIUM confidence)
- None needed — all critical findings verified from installed source

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from package.json and node_modules directly
- Architecture: HIGH — patterns derived from reading actual existing page files
- API contract: HIGH — derived from Phase 14 final plan which documents the completed implementation
- Headless UI API: HIGH — derived from installed .d.ts type definitions (v2.2.9)
- Pitfalls: HIGH for backend contract pitfalls (verified routes); MEDIUM for UI state pitfalls
  (derived from patterns, not observed failures)

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable stack — headlessui and Tailwind v4 are stable)
