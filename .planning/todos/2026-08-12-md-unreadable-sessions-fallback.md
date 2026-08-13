# Maryland unreadable sessions — the fallback, specified (2026-08-12)

Blocks the remaining 71 Maryland rows in [[chairs_owed_evidence]]. **Do not blank any row whose
member has unreadable sessions until this runs** (mig 1732's rule).

---
## ✅ DONE 2026-08-12 — but NOT by the mechanism specified below. READ THIS FIRST.

`backend/scripts/md-session-rosters.mjs` is built and run. **54 unreadable (member, session) pairs → 0.**
7 rows that had ZERO chair-discriminating candidates — and were therefore about to be blanked — turned
out to hold evidence. Alonzo Washington alone went from 230 to 1,606 bills visible.

🔴🔴 **THE ROSTER MECHANISM SPECIFIED BELOW DOES NOT EXIST.** `Members/Index/house?ys=<session>` and
`Members/Index?ys=<session>` return 200 with a plausible roster and **ignore `ys` entirely**. Measured:
the 2013RS and 2019RS House responses are the same 220,196 bytes, and the only textual difference is
the `ys` echoed into the Facebook/Twitter share links. Both serve TODAY's roster — the tell is
`<img src="/2026RS/images/…">` on a page requested as 2019RS, and the "2019 Senate roster" listing
Sara Love, who did not join the Senate until June 2024. The page has no session `<select>` at all.
⚠ The "confirmation" recorded below (that the 2019 Senate roster carried `washington01`, `kramer02`,
`muse01`, `waldstreicher1`) **did not discriminate** — every one of those members is in the CURRENT
Senate too. [[md_sponsor_identity_traps]] §5 had already recorded that `Members/Index?ys=` ignores the
session; this spec was written against a premise that file had already refuted.

✅ **WHAT WORKS, and it is cheaper — 13 fetches, not 26:** the legislation-search page's sponsor
dropdown IS session-scoped, keyed on `session=` (lowercase), not `ys=`:
`https://mgaleg.maryland.gov/mgawebsite/Search/Legislation?session=2013rs` → `#valueSponsors` options
`value="<slug>#<h|s|o>"` carrying the full display name, e.g. `washington a#h = Washington, Alonzo T., Delegate`.

🔴 **A SLUG CAN CONTAIN A SPACE** — `washington a`, `kramer b`. That is why no surname+NN guessing ever
found them, and why the note claiming Alonzo's House record lived at `washington` was wrong:
`washington` is **Mary L.** Washington. Encode the slug.

Ran: `md-session-rosters.mjs` → `md-member-legislation.mjs --slugmap …` → `md-chair-candidates.mjs`.
Outputs: `2026-08-12-md-session-slugmap.json`, `…-md-legislation-v2.json`, `…-chair-candidates-MD-v2.json`.

✅ **Hester and Feldman resolved too** (a *different* defect: no `Members/Details` URL in their sources
at all, so md-member-legislation.mjs skipped them and they read ZERO sessions — it looks identical to
the chamber-scoping bug in the output and has nothing to do with it). The same index answers it by
FULL NAME, verified against the member page: `hester01` (senate) and `feldman` (senate). Hester now
reads 8 in-tenure sessions / 982 bills / 35 on-topic; Feldman 14 sessions / 2,577 bills / 14 on-topic.
`md-session-rosters.mjs` emits these as `base_slugs`; `md-member-legislation.mjs --slugmap` falls back
to them when `sources` yields no slug.

**Final state: 0 rows with unreadable sessions, 0 rows with no candidates, 0 members without a slug —
all 71 MD rows.** 26 have a chair-discriminating candidate; 45 are blank-spoke candidates. Neither
Hester's nor Feldman's row scores a discriminating candidate lexically, so both need a human read —
note Hester's chair 4 sits on the ACTION side of the REVERSED AI ladder, so the chair gate correctly
does not refuse her row.

⚠ **The sponsor index over-includes at a TERM BOUNDARY**: 2015RS lists 258 members, not 188, because
70 members of the outgoing 2011-2014 term are still in it. The RECORD test catches them
(`mcdermott?ys=2015RS` = 63 KB, no session portrait, 0 bills → rejected; `?ys=2014RS` = 404 KB,
`/2014RS/images/`, 200 bills → accepted). Never accept an index row without that check.

*The specification below is kept verbatim as the record of what was tried and why it failed. Do not
rebuild it.*
---

## 🔴 DON'T BUILD THE BILL CRAWL. It is the expensive path and it is not needed.

Measured, not guessed:

| approach | fetches | notes |
|---|---|---|
| Crawl every on-topic bill in the 13 unreadable sessions | **11,680 distinct bill pages** | ~3.5 h at the observed rate; 67,912 bills in those sessions, filtered by topic net to 13,648 instances / 11,680 distinct; **0 already cached** |
| **Resolve each member's session-correct slug, then re-read their own member page** | **~156** | 26 roster pages + ~130 member-session pages |

**The unreadable session was never a missing bill list — it was the wrong slug.** mgaleg member
records are chamber-scoped: ask `washington02` (Senate) for 2019RS and you get a page with zero
bills and no error, because that session's record lives under the member's House-era slug.

## ❌ The mechanism, "verified live" — THIS IS THE PART THAT WAS WRONG
(A 200 is not a session. Both endpoints ignore `ys` and serve today's roster — see the block at the top.)
Both roster endpoints return 200 with chamber-specific slugs:

```
https://mgaleg.maryland.gov/mgawebsite/Members/Index/house?ys=2019RS   → 141 slugs
https://mgaleg.maryland.gov/mgawebsite/Members/Index?ys=2019RS         →  47 slugs (Senate)
```

Confirmed the 2019 Senate roster carries `washington01`, `washington02`, `kramer02`, `muse01`,
`waldstreicher1` — i.e. the roster is the authoritative name→slug map *for that session*.

## Build
`scripts/md-session-rosters.mjs` (new):
1. For each of the **13 unreadable sessions**, fetch both chamber rosters (26 fetches), cache to
   `%TEMP%/ev-stance-cache/mdcorpus/roster-cache/<chamber>-<session>.html`.
2. Parse `Members/Details/<slug>` **with the displayed name**, building `{session, chamber, slug, name}`.
3. For each owed member × unreadable session, match on **FULL NAME**, never surname.
4. Re-run `md-member-legislation.mjs` with the resolved per-session slugs so those sessions become
   readable, then re-run `md-chair-candidates.mjs`.

### Sessions and who needs them
2013RS(4) 2014RS(5) 2015RS(5) 2016RS(5) 2017RS(4) 2018RS(4) 2019RS(5) 2020RS(5) 2021RS(5)
2022RS(4) 2023RS(4) 2024RS(3) 2025RS(1) — 128 (session, topic) pairs in all.
Members with 0 unreadable and therefore already complete: **Ellis, Kagan, Rosapepe, Benson.**

## 🔴🔴 Traps to carry in
- **SURNAME COLLISION IN THE ROSTER ITSELF.** The 2019 House roster's `watson02` is **Courtney
  Watson**, not Ron Watson. Matching a roster row by surname would attribute one member's entire
  legislative record to another — the same class as the Texas "Cassandra Garcia Hernandez" →
  `A3155` = *Ana* Hernandez mislink. **Match on full name; when several entries are subsets, take
  the most specific; then re-check the resulting page header against surname AND first name.**
- `washington01` and `washington02` are different people (Mary and Alonzo) and BOTH sat in the 2019
  Senate. A slug is identity; a surname is a guess.
- An empty member-session page is `UNAVAILABLE_SESSION`, never "sponsored nothing" — that is the
  defect this whole fallback exists to remove.
- Slugs rot: a dead slug is not a rival identity. A mismatch only counts when the rival slug still
  resolves.
- The committed 882-bill CR sponsor index was built with the lead-sponsor parser bug. Its POSITIVES
  stand; every "no on-topic bill" NEGATIVE from it is unreliable and must not be reused here.

## Acceptance
- Every one of the 13 sessions resolves to a slug for each member who needs it, or is recorded as
  genuinely absent from that chamber's roster (a real absence, not an unread one).
- `md-member-legislation.mjs` then reports **0 unreadable sessions** for the 16 members.
- Only then may a row be blanked, and only after reading its complete candidate list.
- `node scripts/audit-chair-evidence.mjs --check <rollback.json>` must exit 0 before any commit.
