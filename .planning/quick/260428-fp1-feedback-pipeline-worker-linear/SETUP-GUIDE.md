# Feedback Pipeline Setup Guide

Step-by-step instructions for configuring Linear, Cloudflare Turnstile, Resend, and Render static site hosting to complete the feedback pipeline.

---

## Section 1 — Linear Configuration

### 1. Get API Key, Team ID, and Project ID

**LINEAR_API_KEY:**
1. Go to [linear.app](https://linear.app) and log in
2. Navigate to **Settings → API → Personal API Keys**
3. Click **Create key**, name it `ev-accounts feedback`
4. Copy the generated key immediately (it is only shown once)
5. This value is `LINEAR_API_KEY`

**LINEAR_TEAM_ID:**
1. In Linear, go to **Settings → General**
2. Scroll to the bottom to find the **Team ID** field — it is a UUID
3. Copy it — this is `LINEAR_TEAM_ID`

**LINEAR_PROJECT_ID:**
1. In Linear, open the target project (e.g. "Empowered Vote" or your feedback project)
2. Look at the URL in your browser — it contains `/project/<uuid>`
3. Copy that UUID — this is `LINEAR_PROJECT_ID`
4. If you don't have a dedicated feedback project, create one first: **Projects → New Project**

---

### 2. Create Feature Labels

These labels let you filter feedback by which EV app it came from.

1. In Linear, go to **Settings → Labels → New Label**
2. Create each label below — use teal (`#00657C`) as the color for all:

| Label name | Value used in form |
|------------|-------------------|
| compass | compass |
| essentials | essentials |
| readrank | readrank |
| treasury | treasury |
| badges | badges |
| trivia | trivia |
| landing | landing |
| other | other |

---

### 3. Create Severity Labels

These are triage-only labels. They are not set by the form — applied manually during triage.

1. In Linear, go to **Settings → Labels → New Label**
2. Create each:

| Label name | Suggested color |
|------------|----------------|
| bug | Red (`#E5484D`) |
| data-error | Orange (`#F76B15`) |
| idea | Blue (`#0091FF`) |
| urgent | Red (`#E5484D`) |

---

### 4. Verify Workflow States

The feedback route creates issues without a `stateId`, so Linear defaults to the team's first workflow state. Verify the expected triage state is first:

1. In Linear, go to **Settings → Workflow** for your team
2. Confirm the first state is `Inbox` (or whatever your intake state is called)
3. If needed, drag the desired state to the top of the list

---

### 5. Add Environment Variables to Render

1. Go to the **Render dashboard** → `ev-accounts` service → **Environment**
2. Add each variable below:

| Key | Where to get it |
|-----|----------------|
| `LINEAR_API_KEY` | Step 1 above |
| `LINEAR_TEAM_ID` | Step 1 above |
| `LINEAR_PROJECT_ID` | Step 1 above |
| `RESEND_API_KEY` | See step 6 below |
| `TURNSTILE_SECRET_KEY` | See step 7 below |

**RESEND_API_KEY:**
1. Go to [resend.com](https://resend.com) and log in (or create an account)
2. Navigate to **API Keys → Create API Key**
3. Name it `ev-accounts`, select **Full access**
4. Copy the key — set it as `RESEND_API_KEY` in Render

**Note:** Before Resend will send from `no-reply@empowered.vote`, you must verify the `empowered.vote` domain under **Resend → Domains → Add Domain**. Follow their DNS record setup (MX, SPF, DKIM). This is a one-time setup.

---

### 6. Cloudflare Turnstile Setup

1. Go to [dash.cloudflare.com](https://dash.cloudflare.com) and log in
2. In the left sidebar, click **Turnstile**
3. Click **Add site**
4. Configure:
   - **Site name:** `ev-landing`
   - **Domain:** `ev-landing.empowered.vote`
   - **Widget type:** Managed (recommended)
5. After creating, you will see two keys:
   - **Site Key** (public — safe to commit): used in `feedback.html` as `data-sitekey`
   - **Secret Key** (private): set as `TURNSTILE_SECRET_KEY` in Render

**Update feedback.html:** Replace `REPLACE_WITH_SITE_KEY` in `ev-landing/feedback.html` with the actual Site Key:
```html
<div class="cf-turnstile" data-sitekey="YOUR_ACTUAL_SITE_KEY" data-theme="light"></div>
```

---

## Section 2 — Render Static Site Deployment (ev-landing)

### 1. Create New Static Site

1. Go to the **Render dashboard**
2. Click **New → Static Site**
3. Connect your GitHub repo: **EmpoweredVote/ev-landing**
4. If prompted, authorize Render for the repo

### 2. Configure the Static Site

| Setting | Value |
|---------|-------|
| **Name** | `ev-landing` |
| **Branch** | `main` |
| **Build Command** | _(leave empty — pure static HTML, no build step needed)_ |
| **Publish Directory** | `.` (root of repo — `index.html` and `feedback.html` are at root) |

Click **Create Static Site**.

### 3. Add Custom Domain

1. After the first deploy completes, go to **Settings → Custom Domains**
2. Click **Add Custom Domain**
3. Enter: `ev-landing.empowered.vote`
4. Render will show you a CNAME value to use in DNS

### 4. Configure DNS in AWS Route 53

1. Log in to **AWS Console → Route 53 → Hosted Zones**
2. Open the `empowered.vote` zone
3. Click **Create Record**:
   - **Record name:** `ev-landing`
   - **Record type:** `CNAME`
   - **Value:** (the CNAME value Render provided in step 3 above)
   - **TTL:** `300`
4. Click **Create records**

DNS propagation typically takes 2–10 minutes for Route 53. Render's TLS certificate provisioning may take a few minutes more.

### 5. Verify Deployment

After DNS propagates:
1. Open [https://ev-landing.empowered.vote](https://ev-landing.empowered.vote) — should load `index.html`
2. Open [https://ev-landing.empowered.vote/feedback.html](https://ev-landing.empowered.vote/feedback.html) — should load the feedback form

---

## Final Checklist

- [ ] LINEAR_API_KEY set in Render (ev-accounts service)
- [ ] LINEAR_TEAM_ID set in Render (ev-accounts service)
- [ ] LINEAR_PROJECT_ID set in Render (ev-accounts service)
- [ ] RESEND_API_KEY set in Render (ev-accounts service)
- [ ] TURNSTILE_SECRET_KEY set in Render (ev-accounts service)
- [ ] Turnstile Site Key copied and replaced in `ev-landing/feedback.html` (`data-sitekey` attribute)
- [ ] Feature labels created in Linear (compass, essentials, readrank, treasury, badges, trivia, landing, other)
- [ ] `empowered.vote` domain verified in Resend (for outbound email from `no-reply@empowered.vote`)
- [ ] ev-landing static site created on Render
- [ ] ev-landing.empowered.vote DNS CNAME pointing to Render
- [ ] https://ev-landing.empowered.vote/feedback.html loads successfully
- [ ] `ev-landing.empowered.vote` added to CORS_ORIGIN env var in Render (ev-accounts service)
