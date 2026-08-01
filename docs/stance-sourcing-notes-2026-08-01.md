# Note for Accounts — stance sourcing / evidence integrity, as of 2026-08-01

Short version: we spent this pass auditing the **citations behind published compass stances**. The
headline is not the number of bad rows — it is that **almost every "bad row" we found was our tooling
being wrong, not the data.** Across the whole workstream the detectors have now been corrected nine
times, and **not once** has one been right that a row should be deleted.

If you take one thing from this note: **treat any "unsourced/unverifiable" tally from these tools as a
reading queue, never as a delete list.**

---

## What actually changed in prod

| migration | what it did |
|---|---|
| 1512–1515 | 43 citation path repairs · 1 host change · 443 Ballotpedia Candidate-Connection deep-links · 55 scraper-proxy URLs unwrapped |
| 1516–1517 | 4 reasoning corrections · 5 retirements |
| **1518** *(this pass)* | **16 quote corrections** — no stance values changed, no rows retired, no sources swapped |

Every one was dry-run against prod with a script that **cannot commit** (`dry-run-migration.mjs`), with
a rollback record written to `backend/data/stance-retirement/` first.

## Why the quote corrections matter

`inform.politician_context.reasoning` is **voter-facing** — `Citations.jsx` renders it under *"Why this
position?"*. So quotation marks around words a candidate never said are a **fabricated quote on a live
profile**, regardless of whether the underlying stance is correct. That is the defect class 1518 fixed.

The dominant shape was compressed or paraphrased quotation over real substance:

- Troy Slaten's page says *"Money should **never** be a barrier to justice"* — the row wrote *"not"*.
- Jamie Joyce's says *"Get ICE off **our** streets"* — the row wrote *"the Streets"*.
- Missi Hesketh's says *"**Medicare** for all who want it"* — the row wrote *"Healthcare For All who
  Want It"*. That misquote mattered: "Medicare for all who want it" is the *public-option* phrasing,
  and the row's whole conclusion (opt-in coverage, not single-payer) rested on it.

Two rows carried quotations with **no source at all**; those were removed rather than re-attributed.

## The part worth internalising: five extractor bugs, all silent, all inflating the failure count

Every one of these made correctly-sourced rows look unsupported. None of them announced itself — and
that is the danger, because **a silent text loss looks exactly like an absent claim.**

1. **One stray `[` deleted 83% of a page.** Our text normaliser stripped `[...]` (meant for editorial
   inserts like `advocate[s]`) with no length bound, and it runs over the *page*, not just the quote.
   On one site a `[` at offset 5,517 paired with a `]` at 52,511 and removed **47,177 of 56,732
   characters**. Two quotes that are on that page **verbatim** were recorded as fabrications — and a
   human hand-check had already confirmed the wrong answer, because it searched the gutted text.
2. **We scoped extraction to `<main>`.** Everything a site builder put outside `<main>` vanished. On
   Webflow/Wix single-page campaign sites that is routinely **the entire issues section**. This nearly
   cost us four rows (below).
3. **The campaign-finance disclaimer lives in the footer**, which we stripped as boilerplate — and of
   all compass topics, Campaign Finance is the one whose real evidence *is* the "Paid for by…" line.
4. **We tested pages for our own compass answer text.** Rows name the chair they picked in quotation
   marks; the tool then searched campaign sites for *our* wording. 9 rows — **41% of the "quote absent"
   bucket**.
5. **A doubled apostrophe `''` reads as a closing double quote**, which silently discarded the quote
   before it was ever tested. (If you write stance text: use real `"` marks.)

⚠ **Two of these were "fixes" that reproduced the bug they were written to fix**, caught only by
re-testing against the actual failing page. Fix-then-verify-on-the-original-case, every time.

## The near-miss we want on the record

Four published rows for a **sitting Mayor Pro Tem** cited a campaign domain that has since been
**parked** — `http://` now bounces to a domain-parking host, and one fetch returned a software-download
page. A voter clicking that citation lands on an ad prompt.

The instruction was reasonable: retire them if there's no valid source. Two things nearly made that the
wrong call:

- A first archive query used `collapse=urlkey` and returned **2 snapshots**. Unfiltered, there are
  **46**, many of them good 200s.
- The archived homepage *looked* like a bio page with no policy content — because bug #2 above was
  hiding the issues section. With it fixed, the archive plainly contains **homelessness, public safety,
  housing and infrastructure** planks, including the exact phrase one row quotes: *"Treatment First,
  Housing Second."*

**The rows were right all along.** The remedy is to re-point them at the archive, not to delete them.
We also confirmed the Ballotpedia page for that name is **a different person** (a town councillor in
North Carolina) — a 200 response is not identity confirmation.

## Two habits that keep paying off

1. **Classify every non-200 before reading it as evidence.** `403` = bot block (renders fine in a
   browser). `202/429/503` = throttled, re-check. `404`/`0` = actually gone. We have hit this three
   times; once, 214 silent HTTP-202s nearly recorded **168 correctly-sourced rows as unsupported**.
2. **Before concluding a page lacks something, check what your extractor *kept*, not what you
   fetched.** Print the length of the text you actually searched. Three of the five bugs above would
   have been caught in seconds by that one line.

## What the CI gate does and does not tell you

`npm run check:stance-sources` is green at 662 recorded backlog rows. Please read it precisely:

> 🔴 A green run means **"no row cites Ballotpedia and nothing else."** It does **not** mean stances are
> sourced. It reads the *shape* of the `sources` array and never opens the cited page.

1518 corrected 16 rows of voter-facing text and **the gate number did not move, and never would have.**
Don't use it as a progress measure for correctness work. (It has since gone 662 → 655, but only because
1519 and 1520 happened to change the *shape* of seven rows' sources.)

## Where things stand

The `NOT_FOUND` cohort is worked. Of 114 rows:

| outcome | rows | |
|---|---|---|
| **quote corrected** — substance was on the page, wording wrong | 15 | 1518 |
| **extractor loss** — never defects, resolved by the `<main>` fix | 26 | — |
| **re-sourced to an archive** — live domain had been parked | 4 | 1519 |
| **retired as NO STANCE** — cited site does not discuss the topic at all | 5 | 1520, 1521 |
| never defects for other reasons (chair-label quotes, footer disclaimer, bracket bug) | ~12 | — |
| characterisation rows still to read (sampled majority-correct) | 85 | — |

**Five retirements out of 114**, and every one was verified against **raw HTML** *after* the extractor
bug was fixed — because the earlier reads predated it, and retiring is the one step you cannot walk
back. They are retired **until re-sourced**, and each topic is logged as owed.

The clearest cases were not close: one candidate's site does not contain the word *"taxes"* even once
while carrying a "cut taxes for everyone" stance; another's contains no *religion / church / conscience
/ exemption / worship* vocabulary at all while carrying a religious-freedom stance built from a single
biographical line about the candidate's own faith. **Presence is not support, and neither is absence of
contradiction.**

⚠ One of those retirements takes a candidate to **zero stances**. That is the right outcome — a profile
with no compass is honest, a profile with a fabricated chair is not — and because his
`last_stances_researched_at` is NULL he reads as *unresearched* and returns to the research queue. Note
the distinction, it matters: **NULL timestamp + zero answers means "nobody has looked yet"; a SET
timestamp + zero answers means "we looked and found nothing", which is a real finding and must never be
erased.**

**Next:** 104 Ballotpedia-only rows; the 12 newly-applyable deep-link citations; then the held Oregon
legislative-vote wave.

Full detail: `backend/data/stance-retirement/2026-08-01-not-found-hand-review.md` and the backlog at
`.planning/todos/2026-07-30-stance-resourcing-backlog.md` (its dated STATE block is authoritative).
