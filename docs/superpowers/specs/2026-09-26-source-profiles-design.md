# Source profiles — design

**Status:** draft for review (Chris Andrews, 2026-09-26). Not built.
**Parents:**
- `2026-09-25-confirm-basis-and-s2-checks-design.md` (CONFIRM record basis; its "per-state parsers"
  stays out of scope — a profile is not a parser, see Approach);
- `2026-09-25-stance-quote-codebook-reliability-design.md` (shadow pipeline, improvement loop §10).

**P1 remains SHADOW:** nothing here changes `decidePublish` or writes answers.

## Problem

CONFIRM reads official record pages with rules that are the same for every source. Each source prints a
vote differently, and a rule that is right for one page is wrong for the next. On 2026-09-26 alone:

| Page | Generic rule | What the page means |
|---|---|---|
| CA leginfo, AB 1955 | "Motion **Assembly** 3rd Reading" is the nearest chamber word | the vote was on the **Senate** floor; the motion names the bill's house of origin |
| IN iga, roll call 334 | "124TH **GENERAL ASSEMBLY**" matched the lower-chamber word | the whole legislature; the page is a Senate roll call |
| IN iga, SB 208 | the chamber is looked for *before* the author line | the chamber is *inside* it: "Authored by: Sen. Shelli Yoder" |
| CA leginfo, SB 57 | "Durazo" twice on the page = two members | one member, listed in two votes on one page |

Each fix was found only because a real saved page was run as a test. More states, counties and cities
will add more layouts. Local bodies are a different kind of record again: no chambers, votes by motion
("moved by X, seconded by Y"), unanimous consent, consent agendas.

The knowledge about sources is also scattered: in memory notes (iga pages are JavaScript-only; leginfo
vote pages are robots-disallowed), in the stance-researcher reference file, and in the head of whoever
ran the last batch.

## Approach — one file per source: prose for the collector, a small header for CONFIRM

Two different readers need the rules:

| Reader | Needs | Form |
|---|---|---|
| Collector session (agent or person) | where the records are, what can be fetched, which page proves what, traps | prose |
| CONFIRM (code) | where the chamber is, what separates one vote from the next, how names print | exact values |
| Coders | nothing new | unchanged: codebook + topic annex, the same input for every state |

A **source profile** is one Markdown file with a YAML front-matter header. The prose body is for the
collector. The header is for CONFIRM.

**The header chooses from rule kinds defined in code. It never holds a regex.** Each rule kind is written
and tested once, in code. A new source picks from the list, or adds one new rule kind together with its
test. So a profile cannot fail open through a bad pattern.

Rejected:
- **A parser for each state:** exact, but new code for every source.
- **An agent that reads prose rules during CONFIRM:** flexible, but it is a judgment, and it is not
  repeatable — the thing CONFIRM exists to avoid.
- **YAML only / JSON / TypeScript:** prose for the collector has no good home, and non-developers cannot
  add a source easily.
- **A `.yaml` + `.md` pair:** the two drift apart.

## 1. Layout

```
docs/sources/
  README.md                                   # template, rule-kind catalogue, how to add a source
  states/CA/leginfo-bill-votes.md
  states/CA/leginfo-bill-text.md
  states/IN/iga-roll-call.md
  states/IN/iga-bill-details.md
  counties/06037-los-angeles/board-of-supervisors-minutes.md   # later
  places/1805860-bloomington/city-council-minutes.md           # later
```

The folders use the steward's scope keys (USPS for states, FIPS for counties, GEOID for places), so a
profile is found the same way a jurisdiction lease is.

## 2. The header (front matter)

```yaml
---
profile: ca-leginfo-bill-votes        # unique id
version: 1                            # bump on any header change
scope: state:CA
body: legislature
match:
  url_prefixes:                       # plain strings, longest prefix wins
    - https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml
page_kind: vote                       # vote | author | bill-text | minutes
rules:
  vote_block: aye-count               # aye-count | whole-page
  chamber: word-before-floor          # word-before-floor | nearest-before | page-header | none
  not_chamber_after: [bill, reading]  # optional: extra words that make a chamber word a bill origin/stage
  name_format: surname                # surname | surname-initial | last-first | full-name
seat_titles:                          # office_title → chamber, for this body
  Senator: upper
  Assembly Member: lower
controls:                             # real saved pages; at least one `pass`
  - batch: 2026-09-25-shadow-durazo
    snapshot: aa219c5b                # prefix of snapshot_id
    person: Maria Elena Durazo
    office_title: Senator
    actor_quote: "Cortese, Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: 8666d0a3                # AB 1955: Senate floor vote of an Assembly bill
    person: Maria Elena Durazo
    office_title: Senator
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: pass
---
```

The body follows: how to find the record, access (robots, JavaScript, human-saved), what the page
proves and what it does not, hard cases.

### Rule kinds (the catalogue)

Built now (they are the rules in `recordBasis.ts` today, turned into named kinds):

| Rule | Kind | Meaning |
|---|---|---|
| `vote_block` | `aye-count` | a vote runs from one labelled aye count to the next (today's rule) |
| | `whole-page` | the page is one vote |
| `chamber` | `nearest-before` | the nearest chamber word before the surname (today's rule) |
| | `word-before-floor` | the chamber word directly before "Floor" in the actor's block (CA) |
| | `page-header` | the first chamber word on the page (IN roll call) |
| | `none` | no chamber: a council, a board, a unicameral body (Nebraska) — the chamber test is skipped |
| `name_format` | `surname` | members print by surname; the collision rules of today apply |
| | `surname-initial` | "Walker G" is the qualified form |
| | `last-first` | "Watson, R." |
| | `full-name` | "Councilmember Jane Roe" — the full name is required |

Planned, designed now but built only when the first local batch needs them:
- `page_kind: minutes` with `vote_rule: named-roll | motion | unanimous-consent`.
  - `unanimous-consent` and a consent agenda are near-unanimous by nature: they can never carry a chair
    alone (the same rule as `near-unanimous-vote`).
  - `motion` records who moved and seconded. Moving a motion is a `sponsor`-like act; the vote on it still
    needs its tally.

## 3. How CONFIRM uses it

- `sourceProfiles.ts` loads every `docs/sources/**/*.md` once, parses the header with `js-yaml`, and
  **validates it strictly**: an unknown key, an unknown rule kind, a missing field or zero `pass` controls
  is an error, and the run stops. (`js-yaml` already reads YAML 1.2, so `no` stays a string.)
- For each actor passage, CONFIRM finds the profile by the snapshot's `url` (longest `url_prefixes` match).
  A human-saved page keeps its original URL, so it matches the same way.
- `checkRecordGroup` takes the profile's rules instead of its built-in ones. The seat's chamber comes from
  the profile's `seat_titles` first, and falls back to today's `seatChamber` rule.
- **No profile → generic rules still run, and CONFIRM adds `no-source-profile`.** It fails closed: the row
  goes to review. The coding report counts `no-source-profile` by site, so the next profile to write is the
  most common one (improvement loop, parent spec §10).
- Each row in `coding-report.json` records the `profile@version` it was judged under, so a result can be
  reproduced after a profile changes.

## 4. How the collector uses it

- SKILL shadow section, step 1: before collecting for a jurisdiction, read its profiles in
  `docs/sources/`. If a source has none, write one from the README template, with at least one saved page
  as a `pass` control, in the same batch.
- The profile body is where source knowledge now lives. Move what exists today:
  - CA: vote pages are robots-disallowed → save from the browser; bill text is fetchable by code.
  - IN: `iga.in.gov` pages are JavaScript-only → save from the browser; one roll-call PDF was downloaded
    by the operator.
- **Coders never see profiles.** Their input stays byte-exact, so a profile change never forces a
  re-code. A test checks that no profile text reaches `buildCoderPrompt`.

## 5. First profiles (this build)

Only what the two shadow batches use: CA `leginfo` bill votes and bill text; IN `iga` roll call and bill
details. Each with the real saved pages from 2026-09-25/26 as controls, including the four layouts in the
Problem table.

## Tests (TDD, vitest)

- **Every profile file** loads, validates, and runs each of its `controls` through `checkRecordGroup`
  with the expected result. A profile with no `pass` control fails.
- A header with an unknown key or rule kind → a load error that names the file and the key.
- Longest-prefix match: two profiles with nested prefixes pick the longer one.
- No match → `no-source-profile`, and the generic rules still produce their findings.
- `word-before-floor` on AB 1955 → Senate; `page-header` on IN roll call 334 → Senate; `none` skips the
  chamber test.
- The 24 real record groups of the two shadow batches give the same findings as `9a7a72b4`, and no
  `no-source-profile` (every source they use has a profile).
- No profile body text reaches `buildCoderPrompt`.
- `stancePublishPolicy.test.ts` passes unchanged.

## Out of scope

- Building the `minutes` rule kinds (designed above; built with the first local batch).
- Writing profiles for sources no batch has used.
- Generating profiles automatically.
- Any change to what coders see.
