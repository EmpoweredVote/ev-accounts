# Infrastructure Checklist: accounts.empowered.vote → login.empowered.vote

**IMPORTANT:** Complete ALL steps below and verify each one BEFORE deploying the code changes from Task 2. The code is safe to commit and push, but the Render deploy must not go live until DNS, Render custom domain, Supabase Auth, and CORS are all configured.

---

## Step 1: DNS — Add login.empowered.vote CNAME

- [ ] Go to your DNS provider (likely Cloudflare or your domain registrar)
- [ ] Add a CNAME record for `login.empowered.vote` pointing to the same target as `accounts.empowered.vote` (the Render static site hostname, e.g. `your-service.onrender.com`)
- [ ] Keep the `accounts.empowered.vote` CNAME in place (it stays as an alias during transition)
- [ ] Wait for DNS propagation
- [ ] Verify propagation: run `dig login.empowered.vote` or `nslookup login.empowered.vote` and confirm you see the Render hostname

---

## Step 2: Render — Add login.empowered.vote as Custom Domain

- [ ] Go to [Render Dashboard](https://dashboard.render.com) → the admin/login static site service
- [ ] Navigate to **Settings → Custom Domains → Add Custom Domain**
- [ ] Enter `login.empowered.vote` and save
- [ ] Render will auto-provision a TLS certificate (may take a few minutes)
- [ ] Keep `accounts.empowered.vote` as a custom domain on the same service (alias)
- [ ] Verify: visit `https://login.empowered.vote` in browser — should serve the admin/login app with valid TLS (green padlock)

---

## Step 3: Supabase Auth — Update Redirect Allow-List and Site URL

- [ ] Go to [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Authentication → URL Configuration**
- [ ] In **Redirect URLs**, add the following entries (keep all existing `accounts.empowered.vote` entries):
  - `https://login.empowered.vote`
  - `https://login.empowered.vote/**`
- [ ] Update **Site URL** from `https://accounts.empowered.vote` to `https://login.empowered.vote`
- [ ] Save changes

---

## Step 4: Render API — Add login.empowered.vote to CORS_ORIGIN

- [ ] Go to [Render Dashboard](https://dashboard.render.com) → the `ev-accounts-api` service
- [ ] Navigate to **Environment → Edit** on the `CORS_ORIGIN` environment variable
- [ ] Append `https://login.empowered.vote` to the comma-separated list (keep all existing entries, including `https://accounts.empowered.vote`)
  - Example result: `https://accounts.empowered.vote,https://app.empowered.vote,https://login.empowered.vote`
- [ ] Save the environment variable
- [ ] Trigger a manual deploy of the API service (or wait for the next deploy) to pick up the change

---

## Verification

Once all 4 steps are complete, verify end-to-end:

- [ ] Visit `https://login.empowered.vote/login` — login page loads with valid TLS (no certificate warning)
- [ ] Visit `https://accounts.empowered.vote/login` — still works (alias)
- [ ] Open browser **DevTools → Network tab**, log in via `https://login.empowered.vote`, and confirm no CORS errors appear in the console or network responses

**Once all 4 steps are verified, the code changes in Task 2 are safe to deploy.**

---

## Post-Migration Cleanup (Later)

These items are intentionally deferred and do NOT block this deployment:

- **`docs/*.md` files** reference `accounts.empowered.vote` extensively — update in a follow-up documentation pass
- **`.planning/**` files** contain historical references to `accounts.empowered.vote` — leave as-is (they are historical records, not runtime references)
- **Comment in `app/src/App.tsx` line 82** mentions `accounts.empowered.vote` — cosmetic comment only, update if desired
- **Eventually** remove `accounts.empowered.vote` DNS record, Render custom domain, Supabase Auth entries, and CORS entries once all external consumers (CTC, other apps, documentation, external links) have been updated to use `login.empowered.vote`
