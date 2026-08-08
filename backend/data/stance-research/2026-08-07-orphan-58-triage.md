# The 58 orphan characterisation rows — citation triage, 2026-08-07

Works the cohort isolated by the ORPHAN_CONTEXT diagnosis
(`data/stance-retirement/2026-08-07-orphan-context-findings.md`) and gated at baseline 58.
**Read-only. Nothing changed, nothing deleted.**

## Headline: these are not a defect. They are a research backlog that stopped one step short.

**Every one of the 58 rows has at least one live, substantial citation. Zero are wholly
bad-sourced.** 60 distinct URLs were probed as stored:

| classification | urls | note |
|---|---|---|
| HTTP 200, substantial body | **43** | none thin — no JS shells in this cohort |
| resolves but will not connect from here | 8 | `ontheissues.org` x7, `acostaforla.com` — **UNKNOWN, not dead** |
| 403 bot block | 5 | `ad36.asmrc.org` x2, `lapublicpress.org`, `vote411`, `newskudo` — renders for voters |
| 404 on a live host | 2 | `andrej4la.com` root, `celinaedc.com` article |
| parked | 1 | `aida4la.com` — invalid cert, and `curl -k` returns a **485-byte** placeholder |
| NXDOMAIN | **1** | `davidfbristol.com` — the only genuinely dead host in the cohort |

So the rows' problem is the **missing answer**, not the sourcing. Deleting them would destroy 58 rows
of real, cited research to fix a defect they do not have.

## 🔴 The probe's own first verdict was wrong, and the DNS check is what caught it

A straight `fetch()` sweep reported **10 URLs "DEAD"**. Only **one** was. The other nine resolve:

- `ontheissues.org` → **A 68.178.204.78**. Seven consecutive timeouts looked like a dead outlet; it is
  a live, well-known aggregator that simply refuses connections from here. Recording it as gone would
  have been the willametteweek error in reverse — and it matters, because Barr's and Allen's rows were
  sole-sourced to it until migration 1604 replaced them hours earlier.
- `acostaforla.com` → **A 64.207.152.120**, same class.
- `aida4la.com` → resolves; the failure is a **TLS cert altname mismatch**, and behind it sits a
  485-byte parking page.

**Generalise, again: a fetch failure is not absence.** Resolve the host before calling anything dead.
This is the third form of the same error in one day — after the `www.`-stripped DNS test (1600) and
host-vs-path liveness (1602).

## Cohort shape

58 rows / 25 politicians / 24 live topics. Two clusters dominate:

- **LA June-2026 city candidates** (Ashouri 5, Huang 5, Hyman 5, Kim 4, Alnajjar 3, Acosta 3,
  Logsdon 3, Lopez 2, Selivra 1, McKinney 1, Cheng 1, Zamora 1). Their evidence base is unusually
  good: the **LAist voter guides** (14 citations) and **Patch candidate profiles** (8) are all live
  200s with 8k–57k of visible text.
- **Collin County / Prosper TX** (Ray 2, Tubbs 2, Bartley 1, Bristol 1, Smith 1) on communityimpact,
  prospertx.gov, murphymonitor — all live.
- Plus federal/state singles: Vindman 4, Barr 3, Nixon 2, Fleming 2, Niello 2, Pratt 2, White 1,
  Gonzalez 1.

## What still must happen before any of these is promoted

A chair has never been recorded for any of them, so promoting a row **publishes its reasoning
verbatim** under "Why this position?" the moment an answer is written. That is the latent risk the
ORPHAN_CONTEXT gate exists to hold.

🔴 **~11 of the 58 carry language this workstream has already condemned** and must be rewritten
before, not after, a chair is assigned:
- 6 inference verbs (`suggests` / `indicates` / `signals` / `appears to`)
- 3 argue from absence
- 2 **narrate a score that does not exist** — e.g. Bartley's *"Her leans-slow-growth score reflects
  Prosper's broader council posture"*. That phrasing is the signature of the partial write: the topic
  was scored, the prose stored, the answer lost.

Marcus Ray / Taxes remains the worked example of why this cannot be bulk-promoted: *"His Finance
Committee role and consistent skepticism toward development approvals **suggest** a fiscally
conservative orientation"* — a textbook attribute-prior row, the class 1521 retired. Assigning it a
chair would publish that sentence.

## ▶ LA cluster worked 2026-08-07 — and it is NOT the easy cluster

I picked LA first because its citations are live and rich. That reasoning was wrong, and the reason
is worth more than the rows: **the LAist voter guide and Patch profiles are excellent sources that
answer different questions than the compass topics ask.**

The LAist LA-mayor guide was read in full (57k visible chars, direct quotes for 9 of the 12
candidates). Against it, the 34 LA rows fall out as:

**CLEANLY PROMOTABLE — 1 row.**
- **Juanita Lopez / Homelessness Response → chair 4.** LAist carries her programme verbatim: a
  database of unhoused people with photographs and fingerprints, returning those with outstanding
  warrants, detaining those who refuse assistance for mandatory detoxification, and exploring
  Permanent Supportive Housing for the rest. Coercive intervention as the primary tool while keeping
  services = chair 4 ("enforce ... as the primary tool while maintaining basic outreach"). Not 5 —
  she does propose PSH, so she is not minimising spending on services.

**🔴 CONTRADICTED BY THE LIVE EVIDENCE — 1 row, a real defect.**
- **Bryant Acosta / Local Immigration Enforcement.** The row says he *"appears to support sanctuary
  city policies ... consistent with his overall progressive-to-moderate positioning"* — an inference
  from positioning, with no quote. His actual words in the guide: *"I'll work with the White House
  when it benefits Los Angeles and push back hard when it doesn't."* That is not sanctuary advocacy.
  The row inferred a stance the evidence does not support. It is unpublished, so no voter has seen
  it — but it must be rewritten or dropped, never promoted.

**NOT SCORABLE FROM THIS EVIDENCE — the rest.** Three distinct reasons, none fixable by fetching more:

1. **The source addresses a different topic than the row.** Andrew Kim's only immigration quote is
   about *enforcement* (*"the necessary and measured enforcement of U.S. immigration laws ... will be
   respected and supported"*), but his row sits on **Immigration**, which asks about admission levels
   and services access. He states no position on either. Rich evidence, wrong question.
2. **The candidate's position is genuinely self-contradictory.** Alnajjar would *"cancel General
   Order 40 so that LAPD takes the lead on identifying immigrants' status"* AND process every
   undocumented Angeleno through TPS to legalise them within 90 days. The row honestly records the
   contradiction; no single chair represents it.
3. **The guide explicitly records absence.** For Hyman it states "no specific positions stated" on
   housing/rent — yet her rows assert she *"plans to cap rents"*. For Acosta and Huang it records no
   transportation, healthcare or climate positions at all, which several rows nonetheless characterise.

⚠ **So the LA cluster's live citations do not rescue its rows.** The gap is not reachability — it is
that a candidate questionnaire and a 36-topic compass do not line up. Promoting from these sources
would mean scoring topics the candidates never addressed, which is how the attribute-prior class got
written in the first place.

**Scope correction to my own recommendation below:** "the LA cohort is the obvious first cluster,
chairs can be assigned from evidence rather than inference" was optimistic and is now withdrawn.
1 of 34 rows survived contact with the evidence.

## Recommendation

1. **Do not delete any of the 58.** No row is unsupported; the citations are live and substantial.
2. **Treat them as a per-cluster research queue**, not a data repair. The LA cohort is the obvious
   first cluster — 30+ rows, all resting on LAist voter guides and Patch profiles that are live and
   quotable, so chairs can be assigned from evidence rather than inference.
3. **Rewrite the ~11 condemned-language rows first.** A correct chair resting on inference is still a
   fabrication risk — the Mejia/Climate lesson from 1604.
4. **Leave the gate at 58** until a cluster is actually promoted, then ratchet down.
5. Four citations are worth replacing whenever their rows are touched, though none is load-bearing:
   `aida4la.com` (parked, Ashouri x5 — but all 5 also cite live LAist/Patch), `davidfbristol.com`
   (NXDOMAIN, 1 row), `andrej4la.com` (404, 1 row), `celinaedc.com` (404, 1 row).
