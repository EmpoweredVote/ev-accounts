# Miami-Dade compass stances — paused 2026-09-07, resumable

**This is the start of the stance program the Knight cities spec deferred** ("Out of scope: compass
stances. Stances are a separate program that follows this one, together with the deferred Nashville
stances" — `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md:6`).

Paused so Civic Trivia Championships can write to ev-accounts. Nothing here blocks that: the
jurisdiction lease is released, no migration slot is held, and all work is on
`feat/miamidade-sponsorship-leads` / **PR #401**, never in the shared checkout.

## Where it stands

**Ten rows live in Season 2**, seven of thirteen commissioners, all pushed and verified against the
season's pinned ladder revision:

| topic | value | who |
| --- | --- | --- |
| `housing` | 4 | Bastien · Hardemon · McGhee · Regalado · Rodriguez |
| `growth-and-development` | 2 | Cohen Higgins · Steinberg · Garcia |
| `growth-and-development` | 4 | Rodriguez |
| `economic-development` | 3 | Cohen Higgins |

Every refusal and its reason is in `backend/data/stance-research/2026-09-07-miamidade-refusals.md`.
**Read that before re-researching anybody** — a refusal is a result, and it records what would close
each gap.

## The toolchain (all committed, 189 tests green)

| script | answers |
| --- | --- |
| `miamidade-sponsorship-leads.mjs` | what has this commissioner put their name on? |
| `miamidade-voting-record.mjs` | how did they vote, per matter, per body (`--body=CDMZ\|HOUS\|TRNS\|IEIC`) |
| `miamidade-matter-detail.mjs` | **who actually owns it** — every sponsor with their role |
| `push-stance-csv.mjs` | season-aware upsert, `assertWritten` on both writes, `--dry-run` |

Run order is leads → detail → (votes where sponsorship under-determines) → read → push.

## What the work taught, in priority order

1. 🔴 **A sponsor report is not proof of sponsorship.** Open the matter page and read `prime_sponsors`.
   Two live cases: `261305` sits in Bastien's report and is Rodriguez's; `R-678-26` sits in
   Steinberg's and Garcia's and is Regalado's.
2. 🔴 **`requester` is the discriminator, not volume.** A department item a member carried is weaker
   evidence than one they originated. That split is what decided the housing pass.
3. 🔴 **Read the instrument, never the label.** `26-59` looked like rung-5 deregulation and is a
   same-day permitting service for pools and re-roofs that *adds* county obligations. `LU-8H` read
   verbatim is what turned a refusal into two seated rows at opposite ends of one ordinance.
4. 🔴 **Probe recency first.** Miami-Dade's Legistar answers HTTP 200 with well-formed JSON frozen at
   2018 and contains none of the sitting commissioners.
5. 🔴 **A uniform answer is a broken detector.** One sponsor on every matter; `section 8` matching
   "SECTION 8-9 OF THE CODE" on 18 of 123 housing matters; 104 of 106 Yes votes that cannot be read
   as approvals because an "Adopted" CDMP disposition may be adopting a denial.
6. **Never write an identifier you did not look up.** Five of seven source URLs written from memory
   were wrong; a control comparing every cited id to its prime sponsor caught them.

## Cheapest next steps

- **Hardemon `growth-and-development`** — 21 leads, and he has the largest own-initiative record on
  the Board.
- **`transportation-priorities`** — 117 leads, the second-densest ladder, untouched. `--body=TRNS`
  on the voting record pairs with it.
- **Steinberg, Garcia, Lopez, Regalado on housing** — refused for thin or mixed records; each would
  need one substantive own instrument to resolve.
- ⚠ **`growth-and-development` now carries CRA administration** (board appointments, budgets, pothole
  resurfacing) because CRA vocabulary was moved there from `economic-development`. Splitting CRA
  *creation and expansion* from CRA *housekeeping* would clean up ~14 of Cohen Higgins' 21.

## Cautions for whoever resumes

- Season 2 is open; Season 1 is closed. Writes land in Season 2 automatically via `seasonService`.
- **Every pre-existing Season 2 row has `editor_id = NULL`**; these ten are attributed to
  `chris@empowered.vote` (`4e6dde8f-…`). Pass `EV_EDITOR_ID` or they will be unattributable.
- Research CSVs are gitignored (`.gitignore:55`), so the database write and the reasoning stored with
  it are the durable record, not the CSV.
- The county serves **U+FFFD** where quotation marks were, in most matter titles. It is unrecoverable
  and flagged per item; repair at the point of quoting, never in bulk.
