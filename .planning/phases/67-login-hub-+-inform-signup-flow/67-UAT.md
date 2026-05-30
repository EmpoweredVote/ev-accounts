---
status: complete
phase: 67-login-hub-+-inform-signup-flow
source: 67-01-SUMMARY.md, 67-02-SUMMARY.md, 67-03-SUMMARY.md
started: 2026-04-29T00:00:00Z
updated: 2026-04-29T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Login page — yellow Create an Account CTA visible
expected: Visit login.empowered.vote (or http://localhost:5173/login in dev). A yellow "Create an Account" button is visible on the login page without scrolling. Below it (or nearby) is a smaller teal link "Have an invite code? Create a Connected Account".
result: pass

### 2. InformConstraintsModal opens on CTA click
expected: Clicking the yellow "Create an Account" button opens a modal (not a page navigation). The modal title is "What is an Inform Account?" and shows three yellow checkmark bullets describing Inform capabilities (Compass/Essentials access, observe-only Connected features, yellow gems only).
result: pass

### 3. Modal primary CTA navigates to /signup/inform
expected: Clicking "Got it — Create my Inform Account" inside the modal closes it and navigates to /signup/inform. The page renders the Inform signup form (not the Connected signup).
result: pass

### 4. Modal secondary link navigates to /signup
expected: Clicking "Have an invite code? Create a Connected Account →" inside the modal navigates to /signup (the existing Connected invite-code signup). The InformConstraintsModal is not shown on that page.
result: pass

### 5. Inform signup form — three fields, no invite code
expected: At /signup/inform: heading reads "Create your Inform Account", subheading reads "Read civic data. Explore your representatives. No invite required." Three fields in order: Display name, Email, Password. No invite code field anywhere. Submit button is yellow with text "Create my Inform Account".
result: pass

### 6. Inform signup — success screen
expected: Fill in display name, email, and password (8+ chars) and submit. On success, the page renders a yellow "Check your email" screen: "Inform Account" yellow pill at top, heading "Check your email", body shows the email you typed, a "Sign in" link back to /login.
result: pass

### 7. Inform signup — account is Inform tier (no connected_profiles row)
expected: After submitting, the backend created an Inform-tier account. In Supabase (or via backend logs): a public.users row exists, NO connect.connected_profiles row exists, ONE inform.inform_profiles row exists.
result: pass
notes: Queried DB for alincoln@empowered.vote (id: de570b9e-6f7d-4330-8da3-f1997a0ca42f). display_name="Honest Abe" on public.users, connected_profiles=0 rows, inform_profiles=1 row (yellow_gem_balance=0). All correct.

### 8. display_name persisted to public.users
expected: The display_name you typed is saved on the public.users row (not null). After confirming email and logging in, the profile page shows the display name you entered at signup.
result: pass
notes: DB confirmed display_name="Honest Abe" on public.users. Profile page confirmed showing correct name post-login.

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
