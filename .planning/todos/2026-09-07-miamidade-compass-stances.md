# Miami-Dade compass stances — resumable, last worked 2026-09-08

**This is the start of the stance program the Knight cities spec deferred** ("Out of scope: compass
stances. Stances are a separate program that follows this one, together with the deferred Nashville
stances" — `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md:6`).

## Where it stands

**Twelve rows live in Season 2**, seven of thirteen commissioners:

| topic | value | who |
| --- | --- | --- |
| `housing` | 4 | Bastien · Hardemon · McGhee · Regalado · Rodriguez |
| `growth-and-development` | 2 | Cohen Higgins · Steinberg · Garcia |
| `growth-and-development` | 4 | Rodriguez |
| `economic-development` | 3 | Cohen Higgins |
| `transportation-priorities` | 3 | Regalado |
| `residential-zoning` | 3 | Regalado |

**Five whole-Board topic passes are done:** `housing` (123 matters), `transportation-priorities`
(83, 1 seated / 13 refused), `local-environment` (43, **0 seated** / 14 refused),
`residential-zoning` (49, 1 seated / 13 refused) and `rent-regulation` (**0 seated** / 14 refused —
and the ladder does not apply in Florida at all, see below).

Every refusal and its reason is in `backend/data/stance-research/2026-09-07-miamidade-refusals.md`.
**Read that before re-researching anybody.**

## The toolchain (all committed)

| script | answers |
| --- | --- |
| `miamidade-sponsorship-leads.mjs` | what has this commissioner put their name on? |
| `miamidade-voting-record.mjs` | how did they vote, per matter, per body (`--body=CDMZ\|HOUS\|TRNS\|IEIC\|RTRC`) |
| `miamidade-matter-detail.mjs` | **who actually owns it** — every sponsor with their role |
| `miamidade-axis-control.mjs` | 🟢 **what the pattern MISSED** — see below |
| `push-stance-csv.mjs` | season-aware upsert, `assertWritten` on both writes, `--dry-run` |

Run order: **axis test** → leads → detail → (votes where sponsorship under-determines) → read →
gate → push. Gate the CSV **before** pushing: `node scripts/audit-chair-evidence.mjs --csv <file>`.

🟢 **THE FULL INSTRUMENT TEXT IS THE STEP THAT KEEPS CHANGING ANSWERS.**
`matter.asp?matter=NNNNNN&file=true&fileAnalysis=false&yearFolder=YNNNN` links
`legistarfiles/Matters/Y<year>/<matter>.pdf` — recitals *and* operative sections.
⚠ That link **404s as HTTP 200 with 2,625 bytes of "Web Error" HTML** for some matters (`260174`,
`252269`, `261065` so far); always fetch a known-good one in the same run as a control.

## 🔴 TEST THE AXIS BEFORE STARTING A TOPIC — FOUR OF FIVE PASSES NEEDED IT

1. Read the five rungs. Write down the **one question** they all answer.
2. Read twenty lead titles. If they answer a *different* question, stop and retune first.
   Direction is rarely the problem; the axis usually is.
3. 🔴 **The leads file cannot tell you what the pattern MISSED** — it stores only what matched. Use
   **`node scripts/miamidade-axis-control.mjs --cache`** once, then `--grep=<regex>` or
   `--topic=<key>` to measure a retune offline against all 2,559 matters.
4. 🔴 The tool **refuses to report a zero** unless its positive control fires. Keep it that way.

**Scorecard so far:** `economic-development` carried bare `incentive` and CRA vocabulary ·
`housing` matched "SECTION 8-9 OF THE CODE" · `local-environment` asked about the health of the bay
and matched `RESILIENT AQUARIUM LLC` · `residential-zoning` matched a submerged-lands lease on
"LAND USE PLAN" and could not see the Rapid Transit Zone · `rent-regulation` was **23 of 23 false
positives**, all county property leases, all from bare `landlord`. **Assume the pattern is wrong
until measured.**

🟢 **MEASURE PER-ALTERNATIVE, NOT JUST OVERALL.** Running each alternative of `rent-regulation`
separately showed `landlord` scoring 30 and every other term scoring **0**, so the fix was one word
rather than a rewrite. `--grep` one alternative at a time; it takes a minute and it turns a guess
into a measurement.

## 🔴🔴 A LADDER CAN BE LEGALLY UNAVAILABLE AT THIS LEVEL — AND THE FAILURE MODE IS A FALSE ROW

**Fla. Stat. § 125.0103(2)** forbids any Florida county from adopting or maintaining "any law,
ordinance, rule, or other measure that would have the effect of imposing controls on rents", and the
old housing-emergency exception is gone from the current text. So on `rent-regulation`:

- rungs 1 and 2 are things a commissioner **may not lawfully do**;
- rungs 3 and 4 both describe the preempted baseline and separate nobody;
- 🔴🔴 **rung 5 — "oppose rent control entirely" — is an accurate description of STATE LAW and of
  nobody's stated position.** Work backwards from the outcome and you seat all thirteen at 5, having
  recorded a preemption as thirteen personal beliefs.

**The danger of a mis-scoped ladder is not a blank spoke; it is a confident wrong row.** Before any
new topic, ask whether the rungs are things this officeholder can actually do — the per-rung scope
ruling in CLAUDE.md. ⚠ `rent-regulation` is NOT invalid in general: it carries `local` and `state`
roles and 237 answers exist elsewhere. The defect is jurisdictional, and `compass_topic_roles` has no
per-state dimension, so the refusals file is the only place this can be recorded.

## What the work taught, in priority order

1. 🔴 **A sponsor report is not proof of sponsorship.** Read `prime_sponsors` on the matter page.
   `261305` sits in Bastien's report and is Rodriguez's; `261104` sits in **nine** and is Rodriguez's.
2. 🔴 **`requester` is the discriminator, not volume.** A department item a member carried is weaker
   than one they originated. **Every EEL and wetlands item in the corpus is a DERM request.**
3. 🔴 **Read past the recitals to the operative section.** `26-51`'s recitals "support the safe use"
   of e-bikes; its operative §2-98.3(1) lets municipalities **restrict** them. `26-59` looked like
   deregulation and adds obligations. `252337` looked like tree policy and merely **spends** a fund.
4. 🔴 **A STUDY DIRECTIVE IS NOT A CHAIR, AND THE STANDARD MUST HOLD BOTH WAYS.** Gilbert refused on
   transportation, Bermudez refused on local-environment the same day on the same ground — despite
   being the only commissioner there with a coherent direction. Wanting a row is not a reason.
5. 🔴 **THE SAME INSTRUMENT CAN BE PROCEDURAL FOR ONE LADDER AND ON-AXIS FOR ANOTHER.** An RTZ parcel
   addition says nothing about transport investment and genuinely upzones the parcel. Tag both; judge
   separately.
6. 🔴 **Probe recency first.** Legistar answers HTTP 200 with JSON frozen at 2018.
7. 🔴 **A uniform answer is a broken detector until controlled.** ⚠ Sometimes it is real: the
   Transportation Committee is **one non-Yes vote in 435**, and the control is that the one was found.
8. 🔴 **A keyword can move a matter into the wrong topic and the write-up will inherit it.** Bare
   `surtax` put a transit resolution in the housing corpus and into Regalado's published housing prose.
9. 🔴 **THE COUNTY'S RECORD IS LIVE.** The same query over the same window returns **more** pairs
   later, as sponsors are added after filing. A run-to-run diff is not purely your own change.
10. **Never write an identifier you did not look up.** Five of seven source URLs from memory were wrong.
11. **Which report fits depends on the topic.** Growth decisions are *applications* nobody sponsors;
    transportation, environment and zoning policy is *initiated*. Decide before paying for a report.

## Cheapest next steps

- **`city-sanitation`** — 61 leads, the densest untouched ladder; Regalado 17, Bastien 11.
  **Run the axis test first.**
- **`jail-capacity` (13) · `climate-change` (9) · `homelessness-response` (9)** — thin, and worth an
  axis test before any reading; on current form at least one of them is mis-specified.
- ✅ **`rent-regulation` is CLOSED and should not be re-attempted in Florida** — state preemption,
  above. Its pattern is fixed (30 leads → 0, which is the true answer).
- **Steinberg, Garcia, Lopez on housing** — each needs one substantive own instrument.
- **Lopez on residential-zoning** — needs a subzone she creates with standards, not parcel additions.
- **Gilbert on transportation** — needs a funding mechanism he proposes, not a study of possible ones.
- **Bermudez on local-environment** — needs `250607` or `261179` adopted, or Board action on the
  mitigation-bank report.
- ⚠ **`growth-and-development` carries CRA administration**; splitting CRA *creation* from CRA
  *housekeeping* would clean up ~14 of Cohen Higgins' 21.
- ⚠ **Nothing matches bay water quality, septic-to-sewer or sea-level-rise resilience any more.**
  Deliberate — no ladder asks. Whoever reads the `climate-change` ladder should decide; **do not add
  them back to `local-environment`.**
- 🔴 **Eileen Higgins is prime sponsor of the two most on-axis zoning policy instruments** (`250899`,
  `251728`) **and has left the Board.** Sitting members are co-sponsors only. If former members are
  ever in scope, that is where to start.

## Cautions for whoever resumes

- Season 2 is open; Season 1 is closed. Writes land in Season 2 via `seasonService`.
- **Every pre-existing Season 2 row has `editor_id = NULL`**; these twelve are attributed to
  `chris@empowered.vote` (`4e6dde8f-2bd0-4054-824f-4164744165ea`). Pass `EV_EDITOR_ID`. **Look it up
  from an existing row; do not retype it.**
- 🟢 **The leads cache was regenerated 2026-09-08** over 2025-01-01 → 2026-09-05 and agrees with the
  patterns. **`git diff` the patterns file against the cache's commit before trusting a lead count.**
- 🔴 **RE-MEASURE A BASELINE BEFORE SPENDING ON IT.** "Hardemon growth, 21 leads" was Cohen Higgins'
  (he has 5). `local-environment` was chosen because Steinberg had "16 leads" — all 16 off-axis.
- **An instrument may be cited on two ladders** if it answers both questions and each row argues its
  own (R-551-26 is on transportation and zoning). That is not the "one source → two chairs" case,
  which is about two chairs on ONE ladder.
- Research CSVs are gitignored; the DB rows and their `reasoning` are the durable record. The
  machine-local jurisdiction file is `backend/data/stance-research/2026-09-07-miamidade.csv` and
  mirrors all twelve rows — **update a row in place, never append a duplicate.**
- The county serves **U+FFFD** where quotation marks were. Unrecoverable; repair at the point of
  quoting, never in bulk.
- Worktree is recreated per session. 2026-09-08 used `feat/miamidade-stances-2` (PR #415) off master.
  Never work in `C:/EV-Accounts`.
