# Scheme-less citations — repaired by migration 1549

Every stance citation stored without an `http(s)://` scheme now has one. **Applied 2026-08-04.**
Probe artifact: `2026-08-04-schemeless-probe.json`. **Next free migration: 1550.**

## What the defect was

372 citations across 200 `politician_context` rows were stored as `votemiller.com`,
`laist.com/news/politics/voter-guides/…`, `ballotpedia.org/John_Logsdon` — **not URLs**. Nothing that
fetches a source could read them, so **every reachability verdict ever recorded for these rows was made
against an unfetchable string**, and every one of them silently passed as "not a problem".

**All 200 rows were wholly uncheckable**: their sources were *only* scheme-less strings. Not one carried a
citation a reader could follow. One research batch — the **Los Angeles 2026 primary cohort** (mayor, city
council, city attorney, LA County), 20 politicians, 71 distinct strings.

They were invisible to every tool until the citation-level host sweep's regex assumed a scheme, returned
the whole string as a "hostname", and failed DNS on it. **The bug in my own extractor is what surfaced
them** — worth remembering as a detection route, not just an embarrassment.

## 🔴 The count was 312, then 372 — and the dry run corrected me

My first measurement joined `politician_answers`, which silently excluded citations on **orphan context
rows**. The real split:

| | rows | scheme-less citations |
|---|---|---|
| context rows with an answer | 166 | 312 |
| **orphan context rows (no answer)** | **34** | **60** |
| **total** | **200** | **372** |

I reported 312 to the operator before the dry run caught it. Both numbers are now asserted in the
migration so neither can drift. ⚠ **The 34 orphan rows remain an open finding** — voter-facing reasoning
attached to a (politician, topic) pair with no answer, part of the 546-row anomaly migration 1548's
over-broad guard exposed. 1549 repaired their citations; it did **not** diagnose them.

## What the repaired URLs serve (probed BEFORE repairing)

| class | distinct | citations | notes |
|---|---|---|---|
| **200 OK** | 60 | **268** | repair yields a live page |
| 403 bot-blocked | 2 | 10 | `lapublicpress.org`, `19thnews.org` — valid URLs, render fine for a voter |
| 404 gone | 6 | 20 | `colterforla.com`, `andrej4la.com`, 2× `theeastsiderla.com`, `ladowntownnews.com`, `spectrumnews1.com` |
| no response | 2 | 14 | `acostaforla.com`, `aida4la.com` — lapsed campaign domains |

⚠ **The 34 citations that repair into a dead URL were repaired anyway, deliberately.** The defect fixed
here is "this is not a URL". Whether a page is reachable is a different question with its own queue and
its own evidence standard. Turning a dead string into a dead-but-well-formed URL is what makes it
**visible** to the reachability sweep — leaving it unparseable is precisely what hid it for months. Those
10 strings are named above so they enter that queue rather than looking repaired.

## ⚠ The CI gate count went UP, and that is the correct outcome

`PRIMARY_SITE_NO_PATH` **518 → 540** (+22 rows: `-` 35→47, `ca` 38→48). Those rows were falling through
every branch of the gate because they did not parse as URLs; repair made them **classifiable for the first
time**. Same effect migration 1527 had when it repaired prose-in-`sources` (635 → 669).
**Baseline ratcheted in the same commit**, as the gate's own header instructs.
`BALLOTPEDIA_ONLY` held at **159** — the 6 `ballotpedia.org/...` strings sit on rows that carry other
sources, so they do not qualify as Ballotpedia-only. (That number should only ever go down.)

**The gate count is not a measure of this workstream** — it is a measure of what the gate can see.

## Verified after applying

- **0** scheme-less citations remain, and **0** citations corpus-wide fail `^https?://[^ ]+$`.
- Citation count unchanged (nothing added or removed — only a prefix); element order preserved via
  `WITH ORDINALITY`.
- `politician_answers` **33,124** and `politician_context` **33,670** unmoved.
- Spot-checked by value, not count: `https://votemiller.com` and `https://ballotpedia.org/John_Logsdon`
  both present.
- Pre-flight asserted all 372 strings were **host-shaped** before any scheme was glued on, and that no row
  would gain a duplicate by acquiring the schemed twin of a bare string it already held.
