---
phase: quick
plan: 006
type: execute
wave: 1
depends_on: []
files_modified:
  - render.yaml
  - app/.env.production
autonomous: true

must_haves:
  truths:
    - "render.yaml defines a static site service for the /app frontend"
    - "VITE_API_URL is set to https://ev-accounts-api.onrender.com at build time"
    - "Existing admin deployment is not disturbed"
  artifacts:
    - path: "render.yaml"
      provides: "Render static site config for profile.empowered.vote"
      contains: "empowered-vote-app"
    - path: "app/.env.production"
      provides: "Fallback VITE_API_URL for non-Render builds"
      contains: "VITE_API_URL"
  key_links:
    - from: "render.yaml"
      to: "app/src/lib/api.ts"
      via: "VITE_API_URL env var injected at build time"
      pattern: "VITE_API_URL"
---

<objective>
Configure the /app (profile.empowered.vote) for Render static site deployment.

Purpose: The backend API and admin UI are already deployed on Render. The end-user /app frontend needs its own static site service pointing at the production API.
Output: render.yaml with static site config + app/.env.production fallback
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@app/vite.config.ts
@app/package.json
@app/src/lib/api.ts
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create render.yaml and app/.env.production</name>
  <files>render.yaml, app/.env.production</files>
  <action>
Create `render.yaml` at repo root with a single static site service entry:

```yaml
services:
  - type: web
    name: empowered-vote-app
    runtime: static
    buildCommand: cd app && npm install && npm run build
    staticPublishPath: ./app/dist
    envVars:
      - key: VITE_API_URL
        value: https://ev-accounts-api.onrender.com
      - key: NODE_VERSION
        value: "20"
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

Key details:
- `runtime: static` (NOT `type: web` with node — this is a static site)
- The rewrite rule sends all paths to index.html for React Router client-side routing
- `staticPublishPath` is relative to repo root
- NODE_VERSION ensures consistent build environment
- Do NOT include the admin app or backend API — those are managed separately via Render dashboard

Create `app/.env.production`:

```
VITE_API_URL=https://ev-accounts-api.onrender.com
```

This is the fallback for local production builds (`npm run build` outside Render). Vite reads .env.production automatically when `NODE_ENV=production`.
  </action>
  <verify>
    - `cat render.yaml` shows static site config with correct buildCommand and envVars
    - `cat app/.env.production` shows VITE_API_URL
    - `cd app && npx vite build 2>&1 | tail -5` succeeds (build completes)
  </verify>
  <done>
    - render.yaml exists with empowered-vote-app static site service
    - app/.env.production exists with VITE_API_URL
    - Build succeeds with production env var
  </done>
</task>

</tasks>

<verification>
- render.yaml has exactly one service entry (no admin/backend contamination)
- VITE_API_URL matches https://ev-accounts-api.onrender.com in both files
- app build completes without errors
- SPA rewrite rule present for React Router
</verification>

<success_criteria>
- render.yaml ready to connect to Render dashboard for auto-deploy
- app/.env.production provides fallback for manual builds
- No changes to existing app source code required
</success_criteria>

<output>
After completion, create `.planning/quick/006-configure-app-render-static-site-deploy/006-SUMMARY.md`
</output>
