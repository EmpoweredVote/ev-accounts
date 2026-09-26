# CONFIRM record basis (D1) + Season 2 checks — design

**Status:** approved in session (Chris Andrews, 2026-09-25). Not built.
**Parents:**
- `2026-09-25-stance-quote-codebook-reliability-design.md` (P1 shadow pipeline);
- `2026-09-25-codebook-p1-findings.md` (defect D1);
- Chris Cantrell's Season 2 PRs (#535, #537, #549, #579).

**P1 remains SHADOW:** nothing here changes `decidePublish` or writes answers.

## Problem

1. **D1.** `confirmRow` checks every `rests_on` passage *alone*. A vote record is two pages:
   - the **vote page** names the person but carries no bill text;
   - the **bill text** carries the provision but names no voters.

   So a correct record basis always fails, with `person-not-in-snapshot` + `provision-missing` (Durazo
   voting-rights, 2026-09-25).
2. **Missing checks.** Cantrell's Season 2 re-verification catches defect classes our pipeline cannot
   see today:
   - a "YES vote" on a bill that died in committee (Sara Love / SB 539);
   - a near-unanimous vote carrying a chair;
   - a surname that two members share on one vote sheet (the two Watsons);
   - statute vocabulary ("Medical Assistance Program" for Medicaid);
   - wrong Season 1 citations that nobody checks again (Durazo / SB 494).

## Approach — the coders copy facts word for word; code checks them

The rejected alternatives:
- **Parsers for each state:** exact, but new code for every state.
- **A fourth fact-checking agent:** one more judgment, with the same kind of error.

The chosen pattern is the one `provision_quote` already uses. The coder copies the exact text of a fact
from a snapshot. Code checks that the text is verbatim, then reads what it needs from that text. A
coder cannot invent a fact, because an invented fact is not on the page.

## 1. Codebook 0.3 (MAJOR): two new passage fields

| Field | Required when | Content |
|---|---|---|
| `actor_quote` | `v3_class = record` | The words showing the person acted, verbatim from this snapshot: the vote list segment that contains the surname ("Ayes Allen, Archuleta, … Durazo, …"), or the author/sponsor line ("Authored by: Sen. Shelli Yoder"). |
| `tally_quote` | the record is a vote | The count text, verbatim ("Ayes Count 29 Noes Count 8", "Yea 42 … Nay 6"). |
| `record_kind` | `v3_class = record` | `vote` · `sponsor` · `author` · `other-act` (a lawsuit, a signed letter, a veto). |

`instrument` must carry the bill **and the session** (e.g. `SB 1174 (2023-2024)`), because the basis
check groups passages by it.

The validator (`coderLabel.ts`) adds these checks:
- the fields are present when required;
- `actor_quote` and `tally_quote` are verbatim in their snapshot;
- `record_kind` is from its list.

Codebook text changes:
- V3 gains the three fields and one worked example for each kind.
- V4.1 (the vote ladder) references `tally_quote`.
- Each topic annex gains a **Synonyms** line.

**Version:** 0.2 → 0.3 (a new variable = MAJOR; spec §2). Batches coded under 0.2 are coded again.

## 2. CONFIRM: judge the record basis as a set (fixes D1)

`confirmRow` groups the consensus `rests_on` passages by `instrument`.

- **Record group** (any passage with `v3_class = record`) passes only if all of these hold:
  1. **Actor.** Some passage in the group has an `actor_quote`, and the person's surname is in it.
     - If the surname appears more than once on that snapshot, the `actor_quote` must also contain the
       first name or initial of the seat holder. Otherwise: `name-collision`.
  2. **Provision.** `provision_quote` is verbatim on *some* passage of the group (not on every one).
  3. **One instrument.** Every passage in the group names the same `instrument`. Otherwise:
     `instrument-mismatch`.
  4. **A vote needs a vote page.** A group whose `record_kind` is `vote` must include a passage whose
     `actor_quote` comes from a vote list. Otherwise: `vote-not-evidenced`. This also covers a dead
     bill: a bill that never reached the floor has no vote page.
  5. **Divided.** Code reads the Aye and No counts from `tally_quote`. If No < 10% of those voting:
     `near-unanimous-vote`. That vote cannot carry the chair alone.
  6. **Person proximity.** The existing `person-not-in-snapshot` check applies to the **actor
     passage** only. The bill text never names voters.
- **Statement passages** keep the current checks, one passage at a time.
- **Unchanged:** identity (office/jurisdiction), `rests-on-pointer`, the date checks, and
  `revision-drift`.
- **New `ConfirmFinding` values:** `name-collision`, `instrument-mismatch`, `vote-not-evidenced`,
  `near-unanimous-vote`, `tally-unreadable`.
- **Removed behaviour:** `provision-missing` and `person-not-in-snapshot` no longer fire on a passage
  that is part of a valid record group.

**Tally parsing** is one small pure function. It finds the numbers labelled
`Ayes|Yea|Yeas|Aye` and `Noes|Nay|Nays|No` in `tally_quote`. It returns
`{ ayes, noes }`, or `tally-unreadable`, so it fails closed.

## 3. Collector side (no coder change)

- **`s1-leads.json`**, written by a small read-only script next to `build-coder-inputs`. For each
  bundle topic it holds the person's newest pre-open-season answer, its reasoning, and the cited
  source URLs.
  - It is a collector reading aid: check these citations first.
  - **It never enters a coder prompt.** A test checks that `buildCoderPrompt` output contains none of
    its reasoning text.
- **Fresh or stale seed flag per row** in `coding-report.json`: `fresh` when the older season's pin is
  the same revision as the open season's **pin**, otherwise `stale` (seasons design, "seed state").
  (Corrected 2026-09-25: this line first said "served revision", which made every lead stale.) It is information only.
- **Annex Synonyms line** (template + `school-vouchers` example). The SKILL shadow section tells the
  collector to search with them before recording "found nothing".

## 4. Re-check the two batches

1. Code Yoder and Durazo again under 0.3, with the same snapshots and rebuilt inputs, using the
   `claude-ev -p --tools Write` dispatch.
2. Run `code-stance-batch` on both.
3. Add a 0.2 → 0.3 comparison to the findings. Expected: Durazo / voting-rights now fails only on a
   *real* ground (V2 adjacency), or on `near-unanimous-vote` if applicable — not on D1.

## Tests (TDD, vitest)

- **The real pair, as fixtures:** the SB 1174 vote page and bill text.
  - Valid group → no D1 findings.
  - Remove the vote page → `vote-not-evidenced`.
- **IN roll call 334 text:** tally 42/6 is readable; not near-unanimous (12.5% No); Yoder is the actor.
- **A 40–0 vote** → `near-unanimous-vote`.
- **"Walker G" / "Walker K"** on one sheet → `name-collision` unless the `actor_quote` has the
  initial.
- **Instrument mismatch** across the group → `instrument-mismatch`.
- **Validator:** a missing `actor_quote` on a record → error; a non-verbatim `tally_quote` → error.
- **`s1-leads` never reaches the prompt.**
- **`stancePublishPolicy.test.ts` passes unchanged** (shadow property).

## Out of scope

- The display of carried Season 1 chairs (with Cantrell);
- the blank write format (P3);
- per-state parsers.
