# Privacy Data Model — Target Architecture

**Status:** Working design (not yet a locked decision). Date: 2026-09-02.
**Owner:** Chris Andrews.
**Relationship to other docs:** This is the concrete data model that realizes the
goals in `ev-cto/knowledge/PRIVACY-ARCHITECTURE.md` (the goals brief). The brief states
*target properties*; this doc states *where data lives and how it is keyed* to meet them.
It builds on the WorkOS migration (ADR 0002) and the headless-login work
(`docs/HEADLESS-LOGIN-DESIGN.md`).

---

## 1. Purpose and scope

Design the **data model** — what we store, and where — so that a person's real-world
identity cannot be trivially linked to their political views, and so we are pointed toward
GDPR compliance as we expand beyond the US.

**In scope (this doc):** the storage shape. Three data realms, a link vault, per-tier rules,
what WorkOS holds, and how location is stored.

**Explicitly deferred (named here, designed later):**
- **Track B — verification & ban crypto.** How a person proves they are one unique human
  without EV keeping their identity, and how a banned person is stopped from returning,
  without unmasking. This replaces the legal name. See §7.
- **Key-custody hardening.** Making "even EV can't read it" actually true. See §6.
- **GDPR access & erasure.** Data export and delete-everything flows. See §8.
- **Data residency.** EU-region storage for EU users on global expansion. See §8.

---

## 2. The core problem today

There is **one Postgres database** with schema separation, and **one universal join key**:

```
public.users.id  =  auth.users.id  =  WorkOS external_id  =  (old Supabase sub)
```

Every behavior table foreign-keys to that one UUID, and so do the identity fields. So a
single id links **who you are** to **what you think**:

- **Identity:** `connect.connected_profiles.legal_name`, `auth.users.email`.
- **Behavior:** `inform.compass_responses`, votes, XP, gems, social graph, `connect.user_districts`.

Schema separation and hiding fields from other users does **not** protect this. Anyone who can
read the database — a breach, or an insider — can join name to stances in one query. That is
exactly what the goals brief says must be impossible for a Connected account.

### What is already good (keep it)

- **WorkOS holds no names.** Provisioning deliberately keeps `display_name` / `legal_name`
  out of WorkOS (`backend/src/lib/workosProvisionService.ts`). WorkOS = email + credential +
  the join key (`external_id`).
- **One mapping chokepoint.** `backend/src/lib/tokenIdentity.ts` is the sole reader of the
  external↔internal join; `workosProvisionService.ts` is the sole writer.
- **Tier is derived, not a flag.** Inform = no Connected profile; Connected = a verified
  `connect.connected_profiles`; Empowered = an active `empower.empowered_profiles`
  (`backend/src/middleware/tierGuards.ts`). Keep this.
- **No raw street address.** Migration `060_drop_home_address.sql` removed it. Location is
  stored as encrypted coordinates; the raw address is transient enrollment state only.

---

## 3. Account states, and where the rules attach

Four states (clarified by Chris, 2026-09-02). Feature access is broad from the start; what changes
up the ladder is **persistence**, then **the right to post**, then **being public**.

| State | Login? | Post on Connect? | Identity | Uniqueness enforced? |
|---|---|---|---|---|
| **No account** | none — local to one browser/device | no — view only | pseudonymous, local data | no |
| **Inform** | yes — saved profile, any device | no — view only | pseudonym; multiple accounts OK | no |
| **Connect** | yes | **yes** — civic spaces etc. | pseudonym; real name NOT stored | **yes — one person, one account** |
| **Empowered** | yes | yes | **real name, fully public** | yes (inherits Connect) |

Key consequences for this design:
- **No account vs Inform is only persistence.** Same features. No-account data lives locally on one
  browser and is lost if not saved; Inform saves it to a portable profile. A convenience boundary,
  not a privacy boundary.
- **Uniqueness attaches at the Connect upgrade, not at signup.** The "prove one unique human" step
  (§7) gates the *right to post*, because that is the first point a person can act publicly. Inform
  needs no personhood proof — multiples are fine, since they cannot post.
- **Pseudonyms everywhere except Empowered.** Empowered is a deliberate, user-chosen
  de-anonymization; transparency is the nature of the role. It links name→activity directly — no vault.
- **So the double-blind / "can we ever unmask" question is specifically a Connect question.** Inform
  holds only an email + pseudonymous behavior (no verified identity to unmask). The vault and the
  sever/escrow decision (§8a) live at the Connect tier.

The realm separation (§4) applies to **every logged-in account** (Inform, Connect, Empowered),
because an email next to political behavior is sensitive at any tier. It matters *most* at Connect,
where a verified unique person is behind the account.

---

## 4. Target model — three realms + a link vault

```
 IDENTITY REALM         VAULT            BEHAVIOR REALM       LOCATION REALM
 (who logs in)      (the only links)     (what you think)     (where you vote)
┌─────────────┐    ┌───────────────┐   ┌────────────────┐   ┌────────────────┐
│ WorkOS      │    │ account_id    │   │ pseudonym_id   │   │ location_id    │
│  email      │◄──►│    ⇅  ⇅       │◄─►│  stances/votes │   │  encrypted lat/│
│  password   │    │ pseudonym_id  │   │  XP, social    │   │  lng           │
│  external_id│    │ location_id   │   └────────────────┘   │  derived       │
│ Account:tier│    │ locked+destroy│                        │  districts     │
└─────────────┘    └───────────────┘                        └────────────────┘
 knows email       guarded crown-jewel  knows politics       knows geography
 not politics      (Connected only)     not name/address     not name/politics
```

**Principle:** behavior keys on a **`pseudonym_id`**, not on the login UUID. Location keys on a
**`location_id`**. The only place an account, a pseudonym, and a location meet is the **vault**.

- A breach of the **behavior realm** yields pseudonyms — no names, no addresses.
- A breach of the **location realm** yields encrypted coordinates + districts — no names, no politics.
- **Location links to the account, never to the stances.** Serving officials needs
  "this account → these districts." It never needs "these stances → this location."

### The vault

One small table, in its **own schema behind a locked database role**, read through a **single
guarded function**. It maps `account_id ⇄ pseudonym_id` and `account_id ⇄ location_id`.

- It is the crown jewel. All hardening effort concentrates here.
- For a Connected account, its rows are **deletable** — severing the link is how we reach the
  full double-blind end-state (goals-brief property B), once Track B verification exists (§7).

---

## 5. Concrete table changes

**Keep as-is (identity realm)**
- **WorkOS** — `email`, `password`, `email_verified`, `external_id`. Nothing else (see §5a).
- **`public.users`** — becomes the pure account record: tier-deriving links, timestamps.
  `display_name` moves out to the behavior realm.

**New**
- **`behavior_pseudonyms`** — `pseudonym_id` PK; holds `display_name`.
- **The vault** — `account_id ⇄ pseudonym_id ⇄ location_id`, own schema, locked role,
  single reader function, per-Connected-account destroyable.

**Re-key from `user_id` → `pseudonym_id`**
- `inform.compass_responses` (currently PK `user_id, topic_id`)
- `connect.xp_transactions`, `connect.gem_transactions`
- `connect.social_relationships`, `connect.peer_connections`, `connect.account_follows`
- `connect.vq_confirmation_results`
- `public.cta_events`
- `inform.compass_change_history`

**Move to the location realm (key on `location_id`)**
- `encrypted_lat` / `encrypted_lng` (today on `connect.connected_profiles`)
- `connect.user_districts` (derived districts)

**Drop**
- `connect.connected_profiles.legal_name`
- `verification_sessions.legal_name_draft`, `home_address_draft` — transient enrollment state only,
  nulled at completion. At `POST /complete` the real name and raw address are sealed into `id_vault`
  (when enabled), then `complete_connect_flow` nulls both drafts atomically (migration `CA_0121`);
  rows completed before the fix are purged retroactively (migration `CA_0122`). Implemented
  2026-09-17 — the earlier "deleted the moment districts are resolved" intent went unbuilt until then.

**Unchanged (Empowered is public by design)**
- `empower.empowered_profiles.legal_name` (public), `candidate_page_slug`, `politician_id`.
  Empowered activity is public; its name-to-behavior link is expected, so it sits outside the vault.

### 5a. What WorkOS should store

**Nothing more — and a little less.** WorkOS holds only `email`, `password`, `email_verified`,
and `external_id` (the join key). The one cleanup: AuthKit's signup form collects
`first_name` / `last_name`; for Connected signups, stop sending real names into WorkOS.
Treat WorkOS as a dumb credential-and-join-key store. This keeps our most exposed third-party
surface free of anything that identifies a person's politics.

---

## 6. Location, and the key-custody finding

Location is a **third** sensitive category, and the most identifying — a street address points
to a person more precisely than a name.

**Current implementation (traced 2026-09-02):**
- Coordinates are encrypted with `pgp_sym_encrypt_bytea` (AES-256) —
  `backend/migrations/031_location_schema.sql`, `032_location_rpcs.sql`.
- The key is a **single shared secret**, `location_encryption_key`, stored in **Supabase Vault**,
  in the **same Supabase project** as the data. The location RPCs are `SECURITY DEFINER` and
  decrypt any user's coordinates on demand.

**Verdict:** real AES-256 encryption, **not** mere obfuscation — but a single platform-held key,
co-located with the data.

| Threat | Protected? |
|---|---|
| Stolen table dump / backup, no Vault access | ✅ ciphertext only |
| EV itself reads where someone lives | ❌ platform holds the key |
| Full breach of the Supabase project (DB + Vault) | ❌ key sits next to the data |

The migration's stated goal — *"EV should not be able to read where someone lives"* — is **not
met**. This is encryption-at-rest against theft, not sealing against the operator.

**The general lesson:** this is *the* central problem of the whole double-blind goal — **who holds
the keys.** "Even we can't know" is only true when EV does not hold the key that unlocks the link.
That means keys held by the **user**, or **split/escrowed** so no single party (EV included) can
use one alone. Every "even EV can't" property traces back to this. Hardening the location key is
the smallest concrete instance of the problem and a good first proving ground. (Deferred — §1.)

---

## 7. Replacing the legal name — uniqueness and ban (Track B)

The legal name was an early, weak proxy for two jobs: **prove one human, one voice** and
**enable a ban**. The name does neither well, and it is being dropped (§5). The data model above
leaves a **clean seam** for the real mechanism: the vault is exactly where "prove unique once,
then sever the link" plugs in.

The real mechanism (to be designed) is anonymous-credential territory: blind-signature /
privacy-pass credentials for one-time uniqueness, and **nullifiers** (one-way tokens, not personal
data) for ban-without-deanonymization. A nullifier is also GDPR-friendly — it survives an erasure
request without being personal data. This is deferred and researched at design time, not from memory.

**Key clarification (Chris, 2026-09-02) — uniqueness and ban do NOT require unmasking.** A nullifier
is a stable one-way fingerprint of a unique person. The same person re-deriving it lets us detect a
duplicate account (one-person-one-account) or block a banned person's re-registration (ban) — while
it reveals nothing about who they are and cannot be reversed to an identity. So both requirements are
satisfiable under **pure** double-blind; they do **not** force an escrow. The one dependency is a
trustworthy "proof of unique personhood" step at verification, designed so EV receives only the
nullifier, never the identity.

---

## 8. Accountability model (invite chains)

**Purpose:** if an invited person becomes a bad actor (e.g., spreading misinformation), EV wants
accountability to be traceable — **without** learning who the bad actor is in real life.

**Two distinct "who":**
- **Real-world identity** (name, face) — not needed, stays hidden.
- **Account provenance** (which account acted, who vouched for it) — needed, and privacy-safe
  because it is pseudonymous.

**Placement in the model:**
- The chain (`connect.invite_chains`) lives in the **account realm**, keyed by `account_id`. It
  links `account_A → account_B` — never real names, never the behavior realm.
- Consequence propagation already exists: `connect.adjust_inviter_tolerance_rating` dings an
  inviter's rating when their invitee is sanctioned. Accountability acts on **pseudonymous accounts
  + a vouching graph**, so it is fully compatible with the anonymity goal.

**What it is / is not:**
- **Is:** a social deterrent and a provenance trail. You vouch for people you trust; their
  misbehavior reflects on your standing; a node that keeps inviting bad actors can be throttled or
  lose invite privileges.
- **Is not:** a Sybil / one-human-one-account defense. A determined actor invites their own alts —
  that hard problem is Track B (nullifiers, §7). The two complement each other.

**Property to accept:** invites trade a little anonymity for accountability **by construction** —
the inviter knows, in real life, who they invited. EV still does not; the edge of the graph is a
human who can identify their own invitee.

**Interaction with the realms:**
- Judging "misinformation" reads the behavior realm; dinging the inviter writes the account realm.
  Connecting the two is a **defined, audited use of the vault** (a moderation reader path), separate
  from the user's own-data access path.
- In the sealed end-state (Stage C), a severed link means you cannot go pseudonym→account after the
  fact. Accountability must then act on information retained **at issuance** (the credential /
  vouching record), not on an after-the-fact re-link. Track B territory.

### 8a. The crux — can EV ever unmask? (OPEN, pivotal)

**First, what does NOT drive this fork:** one-person-one-account and banning do **not** require an
unmask capability — nullifiers handle both blind (§7). So the crux is *not* about keeping uniqueness
or the ban lever. The **only** remaining driver for an unmask capability is external:
lawful-disclosure duties on global expansion and extreme-harm cases. That narrows the decision to a
pure policy choice, decoupled from the account machinery. It still determines whether the vault link
is ever destroyed or held under split custody.

- **Pure double-blind** — EV literally cannot unmask anyone, ever; the link is destroyed after
  verification. Maximally private; no lawful-disclosure path can exist, because the answer exists
  nowhere.
- **Escrowed break-glass** — EV *alone* can never unmask, but a split set of parties (e.g., two
  officers, or a court order plus an offline-held key) could open the link for an extreme case.
  Strong privacy with a defined, auditable, hard-to-abuse exit.

**Status: open — Chris to decide.** Everything downstream (Stage C sealing vs escrow, Track B
credential design, the GDPR disclosure posture) depends on this.

---

## 9. GDPR alignment (direction, not a task yet)

The three-realm + vault model points the right way as we expand globally:

- **Political opinions are "special category" data (GDPR Art. 9)** — extra protection is legally
  required. Isolating the behavior realm is the compliance posture for that, not just good hygiene.
- **Data minimization + purpose limitation (Art. 5):** already served by dropping the raw address
  and separating realms.
- **Right of access / portability (Art. 15, 20):** the vault lets us assemble a person's full
  record across realms. In the sealed end-state, the user's own login resolves their own data —
  EV never has to re-link.
- **Right to erasure (Art. 17):** the vault makes complete deletion findable across realms, plus
  deleting the WorkOS user.

**Tensions to resolve later:**
1. **`connect.invite_chains`** keeps a permanent inviter→invitee link for accountability (§8) — it
   collides with erasure. Decide: anonymize the chain on deletion, or reduce it to a non-personal token.
2. **Ban-without-identity (Track B)** must survive erasure. A nullifier fits — it is not personal data.
3. **Data residency:** EU users' data should live in an EU region (Supabase + WorkOS region choice).

---

## 10. Staged migration path

1. **Stage A — quick cleanup (low risk).** Drop `legal_name` from Connected. Stop sending real
   names into WorkOS. Delete the address draft as soon as districts resolve.
2. **Stage B — two/three realms + vault.** Introduce `pseudonym_id`, `location_id`, and the vault.
   Dual-write, migrate behavior and location foreign keys, flip reads. This is the substantial,
   risky change and gets its own implementation plan.
3. **Stage C — seal (end-state).** Once Track B verification exists, stop storing the vault link for
   Connected accounts (sever after uniqueness is proven), and move keys off single-party custody.

---

## 11. Open questions

- **Can EV ever unmask a Connected account?** The pivotal fork — pure double-blind vs escrowed
  break-glass (§8a). Everything downstream depends on it. Pending Chris.
- **Empowered → Connected demotion.** Unresolved. Past public (Empowered) activity stays public;
  going forward the person would get a pseudonym. Details TBD.
- **`invite_chains` vs erasure** (see §9, tension 1).
- **Key-custody remediation approach** (see §6) — user-held vs split/escrow vs external KMS.
- **No-account → account data migration.** How local (browser-only) compass/address data is carried
  into a profile on signup, and what happens to a guest's calibration if they never sign up. Product
  detail; the privacy model is unaffected, since local data never reached the server.
