# Miami-Dade compass stances — resumable, last worked 2026-09-08

**This is the start of the stance program the Knight cities spec deferred** ("Out of scope: compass
stances. Stances are a separate program that follows this one, together with the deferred Nashville
stances" — `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md:6`).

## Where it stands

**Eleven rows live in Season 2**, seven of thirteen commissioners, all pushed and verified against
the season's pinned ladder revision:

| topic | value | who |
| --- | --- | --- |
| `housing` | 4 | Bastien · Hardemon · McGhee · Regalado · Rodriguez |
| `growth-and-development` | 2 | Cohen Higgins · Steinberg · Garcia |
| `growth-and-development` | 4 | Rodriguez |
| `economic-development` | 3 | Cohen Higgins |
| `transportation-priorities` | 3 | Regalado |

**Three whole-Board topic passes are done:** `housing` (123 matters), `transportation-priorities`
(83 matters, 1 seated / 13 refused) and `local-environment` (43 matters, **0 seated** / 14 refused).

Every refusal and its reason is in `backend/data/stance-research/2026-09-07-miamidade-refusals.md`.
**Read that before re-researching anybody** — a refusal is a result, and it records what would close
each gap.

## The toolchain (all committed)

| script | answers |
| --- | --- |
| `miamidade-sponsorship-leads.mjs` | what has this commissioner put their name on? |
| `miamidade-voting-record.mjs` | how did they vote, per matter, per body (`--body=CDMZ\|HOUS\|TRNS\|IEIC\|RTRC`) |
| `miamidade-matter-detail.mjs` | **who actually owns it** — every sponsor with their role |
| `push-stance-csv.mjs` | season-aware upsert, `assertWritten` on both writes, `--dry-run` |

Run order is leads → detail → (votes where sponsorship under-determines) → read → push.
Gate the CSV **before** pushing: `node scripts/audit-chair-evidence.mjs --csv <file>`.

🟢 **THE FULL INSTRUMENT TEXT IS THE STEP THAT KEEPS CHANGING ANSWERS.**
`matter.asp?matter=NNNNNN&file=true&fileAnalysis=false&yearFolder=YNNNN` links
`legistarfiles/Matters/Y<year>/<matter>.pdf` — recitals and operative sections, not just the title.
⚠ That link **404s as HTTP 200 with 2,625 bytes of "Web Error" HTML** for some matters; always fetch
a known-good one in the same run as a control before recording an absence.

## 🔴 BEFORE STARTING A TOPIC, TEST THE AXIS — IT IS THE CHEAPEST THING HERE

Two of the three passes so far found the lead pattern was asking a different question from the
ladder, and one of them (`local-environment`) burned a whole pass to discover it. The check is ten
minutes:

1. Read the five rungs. Write down the **one question** they all answer.
2. Read twenty lead titles. If they answer a *different* question, the axis is wrong — stop and
   retune before reading anything else. Direction is rarely the problem; the axis usually is.
3. 🔴 **The leads file cannot tell you what the pattern MISSED**, because it only stores what the
   pattern matched. To ask "does an on-axis instrument exist at all?", re-fetch the **unfiltered**
   sponsor reports (~2,559 matters, 14 members, a few minutes) and grep raw titles for the ladder's
   own vocabulary. That is what found the two instruments `local-environment` was blind to.
4. 🔴 **Put a positive control in that scan** — a term certain to appear, e.g. "resolution". A blind
   scan and a genuine absence are indistinguishable without one.

## What the work taught, in priority order

1. 🔴 **A sponsor report is not proof of sponsorship.** Open the matter page and read `prime_sponsors`.
   `261305` sits in Bastien's report and is Rodriguez's; `R-678-26` sits in Steinberg's and Garcia's
   and is Regalado's; `261104` sits in **eight** reports and is Rodriguez's.
2. 🔴 **`requester` is the discriminator, not volume.** A department item a member carried is weaker
   evidence than one they originated. **Every EEL and wetlands item in the corpus is a DERM request.**
3. 🔴 **Read the instrument, and read past the recitals to the operative section.** `26-51`'s recitals
   "support the safe use" of e-bikes while its operative §2-98.3(1) authorises municipalities to
   **restrict** them. `26-59` looked like deregulation and adds county obligations. `252337` looked
   like a tree policy and merely **spends** the Tree Trust Fund.
4. 🔴 **A STUDY DIRECTIVE IS NOT A CHAIR, AND THE STANDARD MUST HOLD BOTH WAYS.** Gilbert was refused
   on `transportation-priorities` for a resolution directing a plan of *possible* funding mechanisms.
   Bermudez was refused on `local-environment` the same day, on the same ground, despite being the
   only commissioner with a coherent on-axis direction. Wanting a row is not a reason.
5. 🔴 **Probe recency first.** Miami-Dade's Legistar answers HTTP 200 with well-formed JSON frozen at
   2018 and contains none of the sitting commissioners.
6. 🔴 **A uniform answer is a broken detector until controlled.** One sponsor on every matter;
   `section 8` matching "SECTION 8-9 OF THE CODE". ⚠ Sometimes the uniformity is real: the
   Transportation Committee is **one non-Yes vote in 435**, and the control is that the one No was found.
7. 🔴 **A keyword can move a matter into the wrong topic and the write-up will inherit it.** Bare
   `surtax` put a transit resolution in the housing corpus, and Regalado's published housing prose
   then described the transportation surtax as the housing surtax. Corrected 2026-09-08.
8. 🔴 **THE COUNTY'S RECORD IS LIVE.** The same query over the same window returns **more** (member,
   matter) pairs later, because sponsors are added to a matter after filing. A diff between two runs
   is not purely a measure of your own change.
9. **Never write an identifier you did not look up.** Five of seven source URLs written from memory
   were wrong; a control comparing every cited id to its prime sponsor caught them.
10. **Which report is the right instrument depends on the topic.** Growth decisions are *applications*
    commissioners vote on and never sponsor. Transportation and environment policy is *initiated*.
    Decide before paying for a report.

## Cheapest next steps

- **`residential-zoning`** — 70 leads, the densest untouched ladder. 🟢 The RTZ matter detail already
  pulled for transportation is **directly reusable**: those parcel-addition ordinances were
  *procedural* for transportation and are *on-axis* here.
- **`city-sanitation`** — 61 leads; Regalado 17, Bastien 11.
- **Steinberg, Garcia, Lopez on housing** — refused for thin or mixed records; each needs one
  substantive own instrument.
- **Gilbert on transportation** — needs a funding mechanism he proposes, not a study of possible ones.
- **Bermudez on local-environment** — needs `250607` or `261179` adopted, or Board action on the
  mitigation-bank report.
- ⚠ **`growth-and-development` carries CRA administration** (board appointments, budgets, pothole
  resurfacing) because CRA vocabulary moved there from `economic-development`. Splitting CRA
  *creation and expansion* from CRA *housekeeping* would clean up ~14 of Cohen Higgins' 21.
- ⚠ **`rent-regulation` looks mis-specified and was NOT touched** — `landlord` matches the county
  leasing a room to a non-profit (`261389`). Measure before changing it.
- ⚠ **Nothing matches bay water quality, septic-to-sewer or sea-level-rise resilience any more.**
  That is deliberate: no ladder asks about them. Whoever reads the `climate-change` ladder should
  decide whether they belong there. **Do not add them back to `local-environment`.**

## Cautions for whoever resumes

- Season 2 is open; Season 1 is closed. Writes land in Season 2 automatically via `seasonService`.
- **Every pre-existing Season 2 row has `editor_id = NULL`**; these eleven are attributed to
  `chris@empowered.vote` (`4e6dde8f-2bd0-4054-824f-4164744165ea`). Pass `EV_EDITOR_ID` or they will
  be unattributable. Look the id up from an existing row; do not retype it from memory.
- 🟢 **The leads cache was regenerated 2026-09-08** over 2025-01-01 → 2026-09-05 and now agrees with
  the patterns (580 → 522 leads). It had predated the `section 8` fix. **`git diff` the patterns file
  against the cache's commit before trusting a lead count** — that is how the staleness was caught.
- 🔴 **RE-MEASURE A BASELINE BEFORE SPENDING ON IT.** An earlier version of this file said "Hardemon
  `growth-and-development`, 21 leads". 21 was **Cohen Higgins'**; Hardemon has 5. And
  `local-environment` was chosen because Steinberg had "16 leads" — all 16 were off-axis.
- Research CSVs are gitignored, so the database rows and their stored `reasoning` are the durable
  record. The machine-local jurisdiction file is
  `backend/data/stance-research/2026-09-07-miamidade.csv` and it mirrors all eleven rows;
  `push-stance-csv.mjs` re-reads it, so **update a row in place rather than appending a duplicate**.
- The county serves **U+FFFD** where quotation marks were, in most matter titles. Unrecoverable and
  flagged per item; repair at the point of quoting, never in bulk.
- The `ev-accounts-mdc` worktree is recreated per session. 2026-09-08 used
  `feat/miamidade-stances-2` (PR #415) off master. Never work in `C:/EV-Accounts`.
