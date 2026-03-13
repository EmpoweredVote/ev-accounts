---
phase: quick-12
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-prototypes/package.json
  - EV-prototypes/netlify.toml
  - EV-prototypes/index.html
autonomous: false
must_haves:
  truths:
    - "Treasury Tracker exists as standalone repo on GitHub (chrisandrewsedu)"
    - "Empowered Badges exists as standalone repo on GitHub (chrisandrewsedu)"
    - "Fallacy Finders exists as standalone repo on GitHub (chrisandrewsedu)"
    - "Each standalone repo builds successfully with npm run build"
    - "EV-prototypes no longer references removed projects in build scripts or Netlify config"
  artifacts:
    - path: "treasury-tracker (standalone repo)"
      provides: "Independent Treasury Tracker app"
    - path: "empowered-badges (standalone repo)"
      provides: "Independent Empowered Badges app"
    - path: "fallacy-finders (standalone repo)"
      provides: "Independent Fallacy Finders app"
  key_links:
    - from: "Each standalone repo"
      to: "GitHub chrisandrewsedu"
      via: "gh repo create + git push"
---

<objective>
Extract treasury-tracker, empowered-badges, and fallacy-finders from the EV-prototypes monorepo into standalone GitHub repositories, then clean up EV-prototypes to only reference the remaining projects (read-rank, data-entry).

Purpose: These projects are mature enough for independent repos, matching the pattern already established by EV-ReadRank. Standalone repos enable independent Netlify deploys, cleaner CI, and easier collaboration.

Output: Three new GitHub repos under chrisandrewsedu, EV-prototypes cleaned up.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md

EV-prototypes is its own git repo at /Users/chrisandrews/Documents/GitHub/EV-prototypes with remotes:
- origin: https://github.com/EmpoweredVote/EV-prototypes.git
- fork: https://github.com/chrisandrewsedu/EV-prototypes.git

Each sub-project has its own package.json, node_modules, vite config, and dist/ folder.
Vite base paths are currently set for nested deployment (e.g., `/treasury-tracker/dist/`).

Pattern reference: EV-ReadRank at /Users/chrisandrews/Documents/GitHub/EV-ReadRank is a standalone
repo on GitHub at EmpoweredVote/read-rank with its own netlify.toml.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create three standalone repos from EV-prototypes sub-projects</name>
  <files>
    (new repos at /Users/chrisandrews/Documents/GitHub/treasury-tracker)
    (new repos at /Users/chrisandrews/Documents/GitHub/empowered-badges)
    (new repos at /Users/chrisandrews/Documents/GitHub/fallacy-finders)
  </files>
  <action>
For each of the three projects (treasury-tracker, empowered-badges, fallacy-finders):

1. Copy the project directory from EV-prototypes to workspace root:
   `cp -r /Users/chrisandrews/Documents/GitHub/EV-prototypes/{project} /Users/chrisandrews/Documents/GitHub/{project}`

2. Remove node_modules and dist from the copy (will be reinstalled fresh):
   `rm -rf node_modules dist`

3. Update vite config — change `base` from `'/{project}/dist/'` to `'/'` (root-level deploy now)

4. Add a `.gitignore` with standard entries: node_modules, dist, .env, .env.local, .DS_Store

5. Add a `netlify.toml` for standalone SPA deployment:
   ```toml
   [build]
     command = "npm run build"
     publish = "dist"

   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```
   For treasury-tracker, also add the API proxy redirect (copy from EV-prototypes netlify.toml — the /api/* redirect to ev-backend-h3n8.onrender.com).

6. Initialize git repo, commit all files, create GitHub repo under chrisandrewsedu:
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/{project}
   git init
   git add -A
   git commit -m "Initial commit: extract from EV-prototypes monorepo"
   gh repo create chrisandrewsedu/{project} --private --source=. --push
   ```

7. Verify the project builds: `npm install && npm run build`

IMPORTANT: Do NOT copy any .env or .env.local files. Do NOT include node_modules in git.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/treasury-tracker && npm run build && cd /Users/chrisandrews/Documents/GitHub/empowered-badges && npm run build && cd /Users/chrisandrews/Documents/GitHub/fallacy-finders && npm run build</automated>
  </verify>
  <done>Three standalone repos exist on GitHub (chrisandrewsedu), each builds successfully, vite base paths updated to '/', each has .gitignore and netlify.toml</done>
</task>

<task type="auto">
  <name>Task 2: Clean up EV-prototypes monorepo</name>
  <files>
    EV-prototypes/package.json
    EV-prototypes/netlify.toml
    EV-prototypes/index.html
  </files>
  <action>
In the EV-prototypes repo at /Users/chrisandrews/Documents/GitHub/EV-prototypes:

1. Update package.json scripts — remove build:treasury, build:badges, build:fallacy-finders from both individual scripts and the build:all command. build:all should only run build:read-rank and build:data-entry.

2. Update netlify.toml — remove the redirect rules for /treasury-tracker/*, /empowered-badges/*, and /fallacy-finders/*. Keep /read-rank/*, /data-entry/*, and the /api/* proxy.

3. Update index.html — remove the feature cards for Treasury Tracker, Empowered Badges, and Fallacy Finders (but do NOT remove Read & Rank, Community Verification System, or external links like Compass, Essentials, Civic Trivia).

4. Do NOT delete the actual treasury-tracker/, empowered-badges/, fallacy-finders/ directories from EV-prototypes yet — the user may want to verify standalone repos work before removing originals. Add a note in the commit message about this.

5. Commit changes to EV-prototypes repo (not the workspace root):
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/EV-prototypes
   git add package.json netlify.toml index.html
   git commit -m "Remove treasury-tracker, empowered-badges, fallacy-finders references

   These projects have been extracted to standalone repos.
   Original directories preserved until standalone deploys are verified."
   ```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-prototypes && npm run build:all</automated>
  </verify>
  <done>EV-prototypes build:all only builds read-rank and data-entry, netlify.toml has no redirects for removed projects, index.html only shows remaining projects</done>
</task>

<task type="checkpoint:human-verify" gate="non-blocking">
  <what-built>Three standalone repos created on GitHub and EV-prototypes cleaned up</what-built>
  <how-to-verify>
    1. Visit https://github.com/chrisandrewsedu?tab=repositories and confirm treasury-tracker, empowered-badges, and fallacy-finders repos exist
    2. Optionally connect each to Netlify for standalone deployment when ready
    3. Once standalone deploys are verified working, delete the original directories from EV-prototypes
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
- All three standalone repos exist on GitHub under chrisandrewsedu
- Each standalone repo builds with `npm run build`
- EV-prototypes `npm run build:all` succeeds with only read-rank and data-entry
- No secrets or node_modules committed to any repo
</verification>

<success_criteria>
- treasury-tracker, empowered-badges, fallacy-finders are independent GitHub repos
- Each has correct vite base path ('/'), .gitignore, netlify.toml
- EV-prototypes package.json, netlify.toml, index.html no longer reference removed projects
- EV-prototypes build:all still succeeds
</success_criteria>

<output>
After completion, create `.planning/quick/12-move-treasury-tracker-empowered-badges-a/12-SUMMARY.md`
</output>
