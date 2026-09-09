# Sending WorkOS auth emails from our own Resend — research & recommendation

- **Date:** 2026-09-02
- **Status:** ✅ Implemented 2026-09-02 — WorkOS custom email provider (Resend) enabled and confirmed working. No application code changed. Research below retained for rationale.
- **Scope:** Which auth transactional emails can be sent from our own Resend sender instead of by WorkOS, and whether the WorkOS custom-domain add-on ($99/mo) is needed for any of it.
- **Related:** [`HEADLESS-LOGIN-DESIGN.md`](HEADLESS-LOGIN-DESIGN.md), [`HEADLESS-LOGIN-STAGING-CHECKLIST.md`](HEADLESS-LOGIN-STAGING-CHECKLIST.md), memory note `workos-authkit-migration-state`.

---

## Bottom line

1. **The $99/mo custom-domain add-on is NOT needed to send auth emails from our own domain.** WorkOS has a **separate, free feature — "custom email provider" (bring-your-own ESP)** — that makes WorkOS dispatch all its transactional emails through *our* Resend account, from *our* verified domain. The $99 add-on only puts a vanity domain (CNAME) on WorkOS's *own* hosted surfaces (the AuthKit hosted page, Admin Portal, Authentication API) and on WorkOS's *own* email-sending infrastructure. It changes the domain, not who sends.
2. **The original assumption that "WorkOS won't give us the verification code" is now false.** Current WorkOS docs expose the code: `GET /user_management/email_verification/{id}` returns the `code` field, and `POST /user_management/magic_auth` returns the `code` in its create response. So a fully self-sent path is possible too — but we do not need it.
3. **Recommended path: turn on the free WorkOS custom-email-provider (Resend) in the dashboard.** It is config-only, roughly one hour, touches no application code, and carries **no risk to the `email_verified` login gate** because WorkOS still generates the code and still runs the verification grant. It only changes the delivery pipe and the from-address.

---

## Update — implemented 2026-09-02

Enabled and confirmed working. In the WorkOS dashboard (**Emails → Providers → Resend**):

- **From:** `noreply@empowered.vote` — matches the app's own `emailService` sender; domain is DKIM-verified in Resend.
- **Reply To:** `info@empowered.vote`.
- **API key:** must be a Resend **Full access** key, not "sending only" — WorkOS reads/validates the sending domain, not only sends. (This corrects the "sending only" wording in the task block below.)
- Confirmed by a fresh-email signup: the 6-digit verification code arrived from `empowered.vote` and let the user log in.

### Where Resend lives (so nobody re-discovers this)

- **DNS:** `resend._domainkey.empowered.vote` DKIM TXT record in Route 53 (confirmed 2026-09-02). Resend is built on Amazon SES, so the `send.empowered.vote` SPF/MX records point at `amazonses.com` — that is Resend's plumbing, **not** a separate Amazon SES setup, and not a reason to pick the "Amazon SES" option in WorkOS.
- **App key:** `RESEND_API_KEY` env var on the **`ev-accounts-api`** Render service. The app's [`emailService.ts`](../backend/src/lib/emailService.ts) uses it for password reset + admin notices. It is optional at the code level — if unset, emails are silently skipped.
- **WorkOS key:** a Resend **Full-access** key stored in WorkOS Vault (dashboard config), used only for WorkOS's transactional emails. Prefer a dedicated key named `workos` so it can be rotated/revoked independently of the app key.
- **Resend account:** sign in at resend.com with Google (`empowered.vote` Workspace). The Domains / API Keys / Logs pages show verification status and real delivery history — check **Logs** for deliverability.

---

## 1. Inventory of auth transactional emails

| # | Email | Currently sent by | Trigger point in code | In scope? |
|---|-------|-------------------|------------------------|-----------|
| 1 | **Password reset** | **US (Resend)** ✅ | `sendWorkosPasswordReset()` in [`backend/src/lib/workosAuthService.ts:124`](../backend/src/lib/workosAuthService.ts). Calls WorkOS `POST /user_management/password_reset` (returns `password_reset_token`, does **not** auto-send), then `sendEmail()` in [`backend/src/lib/emailService.ts`](../backend/src/lib/emailService.ts) with our own `login.empowered.vote/reset-password` link. | Already done — template pattern for the others |
| 2 | **Email verification code (6-digit)** | **WORKOS** ❌ | Two triggers: (a) `signUpWorkosFirst()` calls `POST /user_management/users/{id}/email_verification/send` — [`workosProvisionService.ts:264`](../backend/src/lib/workosProvisionService.ts) — but only when `sendVerificationEmail !== false`; (b) the embedded flow's `POST /api/auth/workos/authenticate` returns `email_verification_required`, and WorkOS emails the code as part of that step (completed by `authenticateWithEmailCode()`, the `email-verification:code` grant, [`workosAuthService.ts:104`](../backend/src/lib/workosAuthService.ts)). WorkOS generates and emails this code. | **YES — the one live email to move** |
| 3 | **Magic Auth code** | n/a (not used) | No Magic Auth calls in the codebase today. Listed because it is the passwordless option and, if ever added, its code is returned directly by the API. | Future only |
| 4 | **MFA codes** | n/a (not implemented) | `workosAuthService.ts` recognises an `mfa_required` outcome, but no enrolment/challenge is built; MFA is explicitly deferred (headless-login design decision 1). WorkOS MFA factors are TOTP (authenticator app — no email) and SMS (sent by WorkOS's SMS provider, not email). There is **no email-based MFA** to move. | Out of scope; see note below |
| 5 | **Invitations** | **Neither WorkOS nor backend email** | `inviteService.ts` generates and claims invite **codes** in `connect.invite_codes`/`invite_chains`; no `sendEmail` call and no WorkOS `invitations` API call exists. Invites are distributed as links/codes (`accounts.empowered.vote/signup?redirect=…`), not as a WorkOS transactional email. | Out of scope — not a WorkOS email |
| 6 | *(non-auth)* Access-request + On-the-Record discovery admin notices | US (Resend) | `auth.ts:784`, `discoveryService.ts`, `discoveryCron.ts` | Already ours; not auth |

**Net:** the only user-facing WorkOS-sent auth email that exists today is **#2, the email-verification code.**

---

## 2. Can each WorkOS-sent email move to our Resend without the $99 add-on?

Only #2 is live. It can move — three ways, all free. The mechanism that makes this possible is the same for any future WorkOS email (magic auth, invitations if we ever use WorkOS invitations).

### The enabling feature: WorkOS "custom email provider" (free)

- Configure in **WorkOS Dashboard → Emails → Providers**. Choose Resend (SES, Postmark, SendGrid also supported), paste a Resend API key (stored encrypted in WorkOS Vault), set the from / reply-to address.
- After that, **all** WorkOS transactional emails — email verification, magic auth, password reset, Admin Portal invitations — are sent **through our Resend account, from our verified domain**, while WorkOS still generates the codes/tokens.
- The sending domain is verified **inside Resend** (SPF/DKIM), which we already have for `empowered.vote`. This is *not* the $99 WorkOS custom-domain flow.
- WorkOS docs describe this as "a standard step when productionizing your environment." The pricing page lists it **nowhere** as an add-on — it is free.

---

## 3. The verification-code question and the `email_verified` gate

**Key question asked:** does any WorkOS API return the verification code so we could email it ourselves, the way `password_reset` returns its token?

**Answer: yes (this changed).** Per current docs:
- `GET /user_management/email_verification/{id}` → response includes `"code": "123456"`.
- `POST /user_management/magic_auth` → create response includes `"code": "123456"`.

So the historical "for security, WorkOS never hands back the code" assumption no longer holds. That said, the simplest option does not need the code at all.

The `email_verified` gate is the thing to protect: **WorkOS refuses the password grant with `403 email_verification_required` until the address is verified.** Any option that keeps WorkOS as the generator and verifier of the code leaves that gate fully intact.

### Options for moving the verification email

| Option | How it works | `email_verified` gate risk | Effort | Cost |
|--------|--------------|----------------------------|--------|------|
| **1 — BYO provider (RECOMMENDED)** | Dashboard config only. WorkOS still generates the code and runs the `email-verification:code` grant; it just dispatches the email through our Resend from `noreply@empowered.vote` (or a dedicated `auth@`/subdomain verified in Resend). No code change. Template edited in the WorkOS dashboard. | **None.** WorkOS still owns code generation and verification. The gate logic is untouched. | ~1 hour (config + Resend domain check + test send) | Free |
| **2 — Disable WorkOS emails, send the code ourselves** | Turn off default emails in the dashboard. Listen for the `email_verification.created` webhook to get the verification `id` + recipient, `GET /user_management/email_verification/{id}` to read `code`, then `sendEmail()` our own HTML — same pattern as password reset. (Magic auth would use the `code` from the create response directly.) | **Low–medium.** WorkOS still generates the code and still runs the verify grant, so the gate stays correct. But this adds a new failure mode on the login-critical path: if our webhook or send fails, the user gets no code, cannot verify, and cannot sign in (`email_verified` stays false → password grant 403). The embedded `authenticate` response returns only `pending_authentication_token`, **not** the verification `id`, so the webhook wiring is required. Needs retries + monitoring. | ~1–2 days | Free |
| **3 — Replace WorkOS verification entirely** | Generate our own code, email via Resend, verify against our own store, then `PUT /user_management/users/{id}` `{ email_verified: true }` (this write is supported — WorkOS documents it for migrated/pre-verified users). Bypass WorkOS's verification grant. | **High.** We take over the whole verify-before-login guarantee. If our flow marks `email_verified` too early or is bypassable, WorkOS will accept a password grant for an unverified address. It also restructures the signup/authenticate flow, which currently depends on `email_verification_required` → `email-verification:code`. | ~3–5 days + heavier test/security burden | Free |

Options 2 and 3 give more HTML control but add risk and moving parts for no benefit our users would see. Option 1 delivers the goal (our domain, our reputation, our deliverability) with the least surface area.

---

## 4. Recommendation

**Adopt Option 1: enable the free WorkOS custom email provider (Resend) in the dashboard.** Confidence: **high.**

- Moves the one live WorkOS auth email (the verification code) to our Resend and our domain.
- Config-only, ~1 hour, no application code, no new failure mode, no risk to the `email_verified` gate.
- Automatically covers any future WorkOS email (magic auth, WorkOS invitations) with no further work.
- Password reset (#1) already runs through our own `sendEmail`; leave it as-is. It will keep working, and it does not depend on this change.

**What would change this recommendation:** if we needed pixel-level control of the verification email HTML beyond what the WorkOS dashboard template allows, Option 2 becomes worth its extra cost. Nothing today requires that.

### What the $99/mo custom-domain add-on is actually for

- It puts a **vanity CNAME domain** on WorkOS's *own* hosted surfaces — the AuthKit hosted login page, the Admin Portal, the Authentication API — and on WorkOS's *own* email-sending infrastructure (so a WorkOS-sent email would show `auth.empowered.vote` instead of a WorkOS domain).
- It is **irrelevant to the from-address once we use our own Resend**: with the custom email provider on, the from-address is already ours, set in Resend, for free.
- Its original justification in our notes — the password-manager / "foreign `*.authkit.app` domain looks phishy" problem — was **already solved** by the embedded login form on `login.empowered.vote`. We rarely hit the hosted AuthKit page in the primary path.
- **Conclusion: the $99 add-on has no remaining need for email, and only a cosmetic need (vanity domains on hosted fallback pages we mostly bypass) otherwise.** Do not buy it for the email reason.

### Vendor / privacy check (CTO discipline)

- No new personal data reaches a new vendor. Resend already processes our users' email (password reset, admin notices); WorkOS already holds email + credential. The only new item is our **Resend API key stored in WorkOS** (encrypted, WorkOS Vault) — a secret-sharing consideration, scoped to a sending key, revocable in Resend at any time.
- Net privacy posture: neutral-to-positive — fewer third-party sending domains touch users, more delivery under our own reputation. No antipartisan or bylaws concern.

### Reversibility

- Option 1 is a dashboard toggle with **zero data lock-in**. Removing the provider reverts WorkOS to its default sender. No egress, no proprietary API entangled, no DNS change beyond the SPF/DKIM we already run for Resend.

### Risks and early warning signs

| Risk | Early warning sign |
|------|--------------------|
| Sending-domain not fully verified in Resend for the WorkOS from-address → codes land in spam or bounce | WorkOS Dashboard "Email Events" tab shows bounces/spam; test signup code not received |
| WorkOS Resend key revoked/rotated in Resend but not updated in WorkOS → verification emails silently stop → new users cannot verify → cannot log in | Spike in `403 email_verification_required` at `/api/auth/workos/authenticate`; support reports "no code arrived" |
| From-address mismatch (e.g. `auth@` subdomain not verified) | Resend API rejects the send; WorkOS Email Events shows failures |

---

## 5. Task for a dev/ops session (paste-ready)

```
Enable WorkOS custom email provider (Resend) so the email-verification code
is sent from our own domain, for free — no $99 custom-domain add-on.

Context: docs/WORKOS-AUTH-EMAILS-OWN-SENDER.md. This is config-only; no app
code changes. WorkOS still generates the code and runs the verification grant,
so the email_verified login gate is untouched.

Do it on STAGING WorkOS first (client_01M0Z75RM6WGFKV5ZP9DFZWG7X), verify,
then PROD (client_01M0Z75S0SDB4G4ZTSDH58YXWM). STOP AND ASK before the prod step.

Steps:
1. In Resend, confirm/verify the sending domain for the from-address you want
   (e.g. noreply@empowered.vote, already used by emailService; or a dedicated
   auth@ subdomain). Create a Resend FULL-ACCESS API key (WorkOS validates the
   domain, so a sending-only key is not enough); prefer a dedicated key named "workos".
2. WorkOS Dashboard (staging) → Emails → Providers → Resend. Paste the key.
   Set from = the verified address, reply-to as desired.
3. WorkOS Dashboard → Emails → edit the email-verification template branding
   (logo, copy) if wanted.
4. Send a test email from the dashboard; confirm it arrives from our domain.
5. Run a real staging signup that hits email_verification_required
   (backend/scripts/workos-headless-smoke.mjs / the B-series checklist in
   HEADLESS-LOGIN-STAGING-CHECKLIST.md). Confirm: code arrives from our domain,
   code verifies, password grant then succeeds (no 403).
6. Check WorkOS "Email Events" for the send status.
7. Repeat on PROD only after Chris approves.

Acceptance:
- Verification code email arrives from empowered.vote, not a WorkOS domain.
- A fresh-email signup can verify and log in end to end.
- No change needed in backend/src (confirm password reset #1 still sends via
  our emailService, unchanged).

Stop and ask if:
- The dashboard requires the $99 custom-domain add-on to save a provider
  (it should not — this is a free feature; if it asks, do not buy it, report back).
- Resend domain verification is missing for the chosen from-address.
```

---

## Sources

- [Email delivery – WorkOS Docs](https://workos.com/docs/email) — custom email provider is a separate, free step; domain verified in the ESP.
- [Custom Emails – AuthKit – WorkOS Docs](https://workos.com/docs/user-management/custom-emails) — disable defaults and send yourself; codes/tokens supplied via API/events.
- [Bring your own email provider to WorkOS (blog)](https://workos.com/blog/custom-email-providers) — Resend/SES/Postmark/SendGrid, all transactional emails via your provider and verified domains.
- [Email verification – API Reference – WorkOS Docs](https://workos.com/docs/reference/authkit/email-verification) — `GET /user_management/email_verification/{id}` returns `code`.
- [Magic Auth – API Reference – WorkOS Docs](https://workos.com/docs/reference/authkit/magic-auth) — `POST /user_management/magic_auth` create response returns `code`.
- [Update User – API Reference – WorkOS Docs](https://workos.com/docs/reference/user-management/user/update) — `email_verified` is a writable field (documented for migrated/pre-verified users).
- [Custom Domains – WorkOS Docs](https://workos.com/docs/custom-domains) — covers Email, AuthKit, Admin Portal, Authentication API domains (CNAME vanity), a paid service.
- [Pricing — WorkOS](https://workos.com/pricing) — "custom domain $99/mo"; no separate line item for custom email provider.
