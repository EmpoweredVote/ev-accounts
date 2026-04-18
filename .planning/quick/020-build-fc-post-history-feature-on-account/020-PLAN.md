---
phase: quick-020
plan: 020
type: execute
wave: 1
depends_on: []
files_modified:
  - app/src/components/PostHistory.tsx
  - app/src/pages/DashboardPage.tsx
autonomous: true

must_haves:
  truths:
    - "User visits /app dashboard and sees a 'Posts' tab alongside Profile | Referrals | Contributor"
    - "Clicking 'Posts' tab fetches the user's FC post history from https://fc.empowered.vote/api/users/:id/posts using their own user ID"
    - "Each post row shows community name, thread title (linked to the thread URL), post excerpt, authorPseudonym, createdAt timestamp, and an '(edited)' badge when isEdited is true"
    - "The thread title link opens https://fc.empowered.vote/communities/{communitySlug}/threads/{threadId} in a new tab"
    - "Posts render in server order (newest-first); no client-side re-sort"
    - "When meta.hasMore is true, a 'Load more' button fetches the next page using meta.cursor and appends results; the button disappears when hasMore becomes false"
    - "On 401 response, the authStore is cleared (triggers redirect to login via AuthGuard)"
    - "On 403 response, a generic 'Access denied' message is shown"
    - "On 500/network failure, 'Failed to load post history' message is shown with a 'Retry' button"
    - "Legal name is never rendered — only authorPseudonym appears in author position"
  artifacts:
    - path: "app/src/components/PostHistory.tsx"
      provides: "Post history component that fetches FC posts and renders rows with cursor pagination, loading/empty/error states"
      min_lines: 120
      exports: ["default"]
    - path: "app/src/pages/DashboardPage.tsx"
      provides: "Updated dashboard with 'Posts' tab that renders <PostHistory /> when activeTab === 'posts'"
      contains: "activeTab === 'posts'"
  key_links:
    - from: "app/src/components/PostHistory.tsx"
      to: "https://fc.empowered.vote/api/users/{user.id}/posts"
      via: "fetch with Authorization: Bearer ${accessToken} header"
      pattern: "fc\\.empowered\\.vote/api/users"
    - from: "app/src/components/PostHistory.tsx"
      to: "useAuthStore"
      via: "reads user.id and accessToken from Zustand store"
      pattern: "useAuthStore"
    - from: "app/src/pages/DashboardPage.tsx"
      to: "app/src/components/PostHistory.tsx"
      via: "default import and conditional render when activeTab === 'posts'"
      pattern: "import PostHistory"
---

<objective>
Add a Post History feature to the user's profile/dashboard in the `/app` React app. Users will see their own Forum/Civic Spaces (FC) posts — fetched from the external FC service at `https://fc.empowered.vote/api/users/:id/posts` — inside a new "Posts" tab on the DashboardPage.

Purpose: Give members visibility into their own community posting activity from their profile hub. This is v1 of a fan-out pattern that will be reused for Civic Spaces.

Output:
- New `PostHistory` React component that fetches, paginates (cursor-based), and renders posts with proper loading/empty/error states.
- DashboardPage tab bar updated with a "Posts" tab that renders the component for the authenticated user.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@app/src/store/authStore.ts
@app/src/pages/DashboardPage.tsx
@app/src/lib/api.ts

# Auth note: the handoff spec said `supabase.auth.getSession()`. This repo does NOT expose
# a supabase client in the /app frontend. Auth state lives in Zustand (`useAuthStore`).
# Read `accessToken` and `user.id` directly from the store — that token IS the Supabase
# access token (issued by the backend at /api/auth/session, stored under `ev_token`).
#
# apiFetch in lib/api.ts is for the LOCAL backend (VITE_API_URL + /api). It prepends the
# API_BASE and cannot be used for external FC calls. Use raw `fetch()` for FC requests
# and pass the Authorization header manually.

# Tab bar pattern: DashboardPage currently toggles `activeTab: 'profile' | 'referrals'`.
# Add 'posts' to this union and add a new <button> to the tab bar that mirrors the
# styling of the existing buttons (border-b-2 active / border-transparent inactive).

# Styling conventions to follow:
# - Card: `bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5`
# - Section label: `text-xs font-semibold text-gray-400 uppercase tracking-wider`
# - Primary text: `text-ev-black dark:text-white`
# - Secondary text: `text-gray-400` / `text-gray-500`
# - Links: `text-ev-teal hover:underline`
# - Primary button: `bg-ev-teal text-white rounded-xl hover:bg-ev-teal/90`
# - Error accent: `text-ev-red bg-ev-red/10`
# - No framer-motion. Use Tailwind transitions only.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create PostHistory component with fetch, pagination, and states</name>
  <files>app/src/components/PostHistory.tsx</files>
  <action>
Create a new file `app/src/components/PostHistory.tsx` that exports a default React component `PostHistory`.

Types (define inline at top of file):
```ts
interface FCPost {
  postId: string;
  threadId: string;
  threadTitle: string;
  communityId: string;
  communityName: string;
  communitySlug: string;
  postExcerpt: string;
  createdAt: string;       // ISO timestamp
  isEdited: boolean;
  authorPseudonym: string;
}

interface FCPostsResponse {
  data: FCPost[];
  meta: { cursor: string | null; hasMore: boolean };
}

type LoadState = 'idle' | 'loading' | 'loaded' | 'error-access' | 'error-generic';
```

Component behavior:
1. Read `user` and `accessToken` from `useAuthStore()` (import from `../store/authStore`).
2. State:
   - `posts: FCPost[]` (initial `[]`)
   - `cursor: string | null` (initial `null`)
   - `hasMore: boolean` (initial `false`)
   - `state: LoadState` (initial `'idle'`)
   - `loadingMore: boolean` (initial `false`)
3. Implement a `loadPage` function:
   - Takes an optional `afterCursor: string | null` argument.
   - If no `user` or `accessToken`, no-op.
   - Builds URL: `https://fc.empowered.vote/api/users/${user.id}/posts`. If `afterCursor` is truthy, append `?cursor=${encodeURIComponent(afterCursor)}`.
   - Calls `fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } })`.
   - On `res.status === 401`: call `useAuthStore.getState().clearAuth()` (this causes AuthGuard to redirect). Do not set local error state.
   - On `res.status === 403`: set `state` to `'error-access'`, return.
   - On any other non-ok: set `state` to `'error-generic'`, return.
   - On ok: parse JSON as `FCPostsResponse`. If `afterCursor` was null, REPLACE `posts` with `data`. Otherwise APPEND `data` to existing `posts`. Set `cursor = meta.cursor`, `hasMore = meta.hasMore`, `state = 'loaded'`. **Do NOT re-sort** — server returns newest-first and we must preserve that order.
   - Wrap in try/catch; on thrown error set `state = 'error-generic'`.
4. `useEffect` on mount (and when `user?.id` changes): set `state = 'loading'`, call `loadPage(null)`.
5. `handleLoadMore`: set `loadingMore = true`, await `loadPage(cursor)`, then `loadingMore = false`. Disable the button while `loadingMore`.
6. `handleRetry`: reset state to `'loading'`, call `loadPage(null)`.

Rendering (outer wrapper `<div className="space-y-4">`):

- If `state === 'loading'` AND `posts.length === 0`:
  Render a card with centered text "Loading your posts…" (`text-sm text-gray-400`).

- If `state === 'error-access'`:
  Render a card with "Access denied" (`text-sm font-medium text-ev-red`) and a secondary line "You don't have permission to view post history." (`text-xs text-gray-500`).

- If `state === 'error-generic'`:
  Render a card containing:
  - "Failed to load post history" (`text-sm font-medium text-ev-black dark:text-white`)
  - A button `onClick={handleRetry}` with classes `mt-3 px-4 py-2 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors` and label "Retry".

- If `state === 'loaded'` AND `posts.length === 0`:
  Render a card with "No posts yet" (`text-sm text-gray-400`) and a secondary line "When you post in a community, it'll show up here." (`text-xs text-gray-500`).

- Otherwise (posts present): render a list. Container: `<div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 divide-y divide-gray-100 dark:divide-gray-800">`. For each post, render a row keyed by `post.postId` with classes `p-5 space-y-1.5`:

  Row structure (in this exact order per spec):
  1. Community breadcrumb: `<p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">{post.communityName}</p>`
  2. Thread title link:
     ```tsx
     <a
       href={`https://fc.empowered.vote/communities/${post.communitySlug}/threads/${post.threadId}`}
       target="_blank"
       rel="noopener noreferrer"
       className="block text-sm font-semibold text-ev-teal hover:underline"
     >
       {post.threadTitle}
     </a>
     ```
  3. Post excerpt: `<p className="text-sm text-ev-black dark:text-white leading-snug">{post.postExcerpt}</p>`
  4. Footer line (author + timestamp + edited badge):
     ```tsx
     <div className="flex items-center gap-2 text-xs text-gray-500 pt-1">
       <span className="font-medium">{post.authorPseudonym}</span>
       <span className="text-gray-300 dark:text-gray-600">•</span>
       <time dateTime={post.createdAt} className="tabular-nums">
         {new Date(post.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}
       </time>
       {post.isEdited && (
         <span className="ml-1 text-[11px] font-medium text-gray-400 italic">(edited)</span>
       )}
     </div>
     ```

  IMPORTANT: Render `post.authorPseudonym` only. Do NOT render any `displayName`, `legalName`, or similar field. Never fall back from `authorPseudonym` to anything else.

- When `hasMore === true` AND posts exist, render below the list:
  ```tsx
  <button
    onClick={handleLoadMore}
    disabled={loadingMore}
    className="w-full py-2.5 px-4 bg-white dark:bg-gray-950 border border-gray-200 dark:border-gray-700 text-ev-teal rounded-xl text-sm font-semibold hover:border-ev-teal/50 transition-colors disabled:opacity-50"
  >
    {loadingMore ? 'Loading…' : 'Load more'}
  </button>
  ```

WHY these choices:
- External fetch (not apiFetch) because `apiFetch` prefixes VITE_API_URL/api — FC is a different host.
- 401 → clearAuth rather than local error because AuthGuard redirects to /login on unauthenticated state, matching spec's "redirect to login".
- No client re-sort preserves newest-first cursor semantics.
- `(edited)` uses italic to avoid competing with the pseudonym's weight.
  </action>
  <verify>
cd app && npx tsc --noEmit 2>&1 | tail -20
# Expect: no errors mentioning PostHistory.tsx.
# Also grep to confirm sensitive patterns are absent:
grep -n "legalName\|legal_name\|displayName" app/src/components/PostHistory.tsx
# Expect: no matches.
grep -n "authorPseudonym" app/src/components/PostHistory.tsx
# Expect: at least 2 matches (type + render).
grep -n "fc.empowered.vote/api/users" app/src/components/PostHistory.tsx
# Expect: 1 match in the fetch URL.
  </verify>
  <done>
- File `app/src/components/PostHistory.tsx` exists and compiles under `tsc --noEmit`.
- Component reads `user` and `accessToken` from `useAuthStore`.
- Fetches `https://fc.empowered.vote/api/users/{user.id}/posts` with `Authorization: Bearer` header.
- Handles 401 (clearAuth), 403 (error-access), other errors (error-generic with Retry).
- Renders rows with the 4-line layout: community name, thread title (linked), excerpt, pseudonym + timestamp + optional (edited).
- "Load more" button appears iff `hasMore === true` and appends (does not replace) results.
- No reference to any legal name / displayName field in the source.
  </done>
</task>

<task type="auto">
  <name>Task 2: Add "Posts" tab to DashboardPage and mount PostHistory</name>
  <files>app/src/pages/DashboardPage.tsx</files>
  <action>
Edit `app/src/pages/DashboardPage.tsx` to add a third tab "Posts" between "Referrals" and the "Contributor" link.

Changes:

1. Add import at the top alongside other component imports:
   ```ts
   import PostHistory from '../components/PostHistory';
   ```

2. Widen the `activeTab` state union from `'profile' | 'referrals'` to `'profile' | 'referrals' | 'posts'`:
   ```ts
   const [activeTab, setActiveTab] = useState<'profile' | 'referrals' | 'posts'>('profile');
   ```

3. In the tab bar (the `<nav>` containing the Profile and Referrals buttons, plus the Contributor `<Link>`), insert a new tab button AFTER the Referrals button and BEFORE the Contributor Link. The button should only render when `cp` is truthy (same guard as Referrals — posts require Connected tier):
   ```tsx
   {cp && (
     <button
       onClick={() => setActiveTab('posts')}
       className={`pb-2 border-b-2 font-medium text-sm transition-colors ${activeTab === 'posts' ? 'border-ev-teal text-ev-teal' : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'}`}
     >
       Posts
     </button>
   )}
   ```

4. Add a new tab content block inside the `<main>` container. Place it immediately after the Referrals tab block (the `{activeTab === 'referrals' && cp && inviteesData && ( ... )}` block) and before the "Connected Spaces — profile tab only" comment/block:
   ```tsx
   {/* Posts tab content */}
   {activeTab === 'posts' && cp && (
     <PostHistory />
   )}
   ```

5. Update the three existing profile-only conditional blocks at the bottom of `<main>` so they continue to render only on the Profile tab. These already use `activeTab === 'profile' && …` — NO change needed to them; just verify they still read correctly after your inserts.

Do NOT touch any other logic (XP fetch, referral fetch, invitee logic, handlers). Keep all existing imports.

WHY:
- Gating on `cp` (connected_profile presence) matches existing Referrals gating — Inform-tier users won't have FC posts.
- Placing PostHistory inside its own tab (not inline on Profile) avoids forcing an extra network request on every dashboard visit; posts load only when the user clicks the tab.
  </action>
  <verify>
cd app && npx tsc --noEmit 2>&1 | tail -20
# Expect: no errors in DashboardPage.tsx.

grep -n "activeTab" app/src/pages/DashboardPage.tsx | head -20
# Expect: union includes 'posts'; a button with setActiveTab('posts'); a conditional `activeTab === 'posts'` rendering PostHistory.

grep -n "import PostHistory" app/src/pages/DashboardPage.tsx
# Expect: exactly 1 match.

# Manual smoke (run dev server):
cd app && npm run dev
# Visit the app in browser, log in as a Connected user, click "Posts" tab, verify:
#   - Network tab shows GET to fc.empowered.vote/api/users/{id}/posts with Authorization: Bearer
#   - Rows render in spec order (community, thread title link, excerpt, pseudonym + time + edited)
#   - Load more works; empty state and error + Retry work
  </verify>
  <done>
- `DashboardPage.tsx` has `activeTab` typed as `'profile' | 'referrals' | 'posts'`.
- A third tab button "Posts" appears (gated on `cp`) between Referrals and Contributor.
- `<PostHistory />` is rendered when `activeTab === 'posts'` and `cp` is truthy.
- `tsc --noEmit` passes for the /app project.
- Existing Profile and Referrals tabs still function unchanged.
  </done>
</task>

</tasks>

<verification>
Run the `/app` TypeScript check:
```
cd app && npx tsc --noEmit
```
All files must compile with no errors.

Run dev server and exercise the full flow:
```
cd app && npm run dev
```
1. Log in as a Connected user (`cp` truthy).
2. Navigate to dashboard. Confirm three tabs: Profile | Referrals | Posts (plus Contributor link).
3. Click Posts. Confirm network call to `https://fc.empowered.vote/api/users/{user.id}/posts` with `Authorization: Bearer …` header.
4. Confirm posts render newest-first with: community name → thread title link → excerpt → pseudonym + timestamp (+ "(edited)" when applicable).
5. Click a thread title — opens `https://fc.empowered.vote/communities/{slug}/threads/{threadId}` in a new tab.
6. If response has `meta.hasMore`, Load more button paginates with `?cursor=…` and appends.
7. Sanity: view DOM — nowhere does `legal_name` / `displayName` appear as the author value.
</verification>

<success_criteria>
- PostHistory component exists at `app/src/components/PostHistory.tsx` and compiles clean.
- DashboardPage shows a "Posts" tab (for Connected users) that mounts PostHistory.
- Posts fetched from the correct FC endpoint with a bearer token from `useAuthStore`.
- Rows follow the spec's 4-line layout in exact order.
- Thread links point to the spec-defined URL pattern.
- authorPseudonym is the only author field rendered.
- `(edited)` badge appears when `isEdited === true`.
- Cursor-based pagination via "Load more" appends results, no client re-sort.
- 401 → authStore cleared (triggers login redirect). 403 → "Access denied". 500/network → "Failed to load post history" + Retry button.
</success_criteria>

<output>
After completion, create `.planning/quick/020-build-fc-post-history-feature-on-account/020-SUMMARY.md` summarizing:
- Files created: `app/src/components/PostHistory.tsx`
- Files modified: `app/src/pages/DashboardPage.tsx`
- Any deviations from spec (e.g., auth source was `useAuthStore`, not `supabase.auth.getSession()`, because the /app frontend has no direct supabase client).
- Follow-ups for v2 (e.g., fan-out across FC + Civic Spaces with `Promise.allSettled`).
</output>
