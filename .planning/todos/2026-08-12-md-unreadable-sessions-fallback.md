# Maryland unreadable sessions — the fallback, specified (2026-08-12)

Blocks the remaining 71 Maryland rows in [[chairs_owed_evidence]]. **Do not blank any row whose
member has unreadable sessions until this runs** (mig 1732's rule).

## 🔴 DON'T BUILD THE BILL CRAWL. It is the expensive path and it is not needed.

Measured, not guessed:

| approach | fetches | notes |
|---|---|---|
| Crawl every on-topic bill in the 13 unreadable sessions | **11,680 distinct bill pages** | ~3.5 h at the observed rate; 67,912 bills in those sessions, filtered by topic net to 13,648 instances / 11,680 distinct; **0 already cached** |
| **Resolve each member's session-correct slug, then re-read their own member page** | **~156** | 26 roster pages + ~130 member-session pages |

**The unreadable session was never a missing bill list — it was the wrong slug.** mgaleg member
records are chamber-scoped: ask `washington02` (Senate) for 2019RS and you get a page with zero
bills and no error, because that session's record lives under the member's House-era slug.

## ✅ The mechanism, verified live
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
