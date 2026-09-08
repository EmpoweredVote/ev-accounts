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

Every refusal and its reason is in `backend/data/stance-research/2026-09-07-miamidade-refusals.md`.
**Read that before re-researching anybody** — a refusal is a result, and it records what would close
each gap. It now covers two whole-Board passes: housing (123 matters) and transportation (83).

## The toolchain (all committed, 189 tests green)

| script | answers |
| --- | --- |
| `miamidade-sponsorship-leads.mjs` | what has this commissioner put their name on? |
| `miamidade-voting-record.mjs` | how did they vote, per matter, per body (`--body=CDMZ\|HOUS\|TRNS\|IEIC`) |
| `miamidade-matter-detail.mjs` | **who actually owns it** — every sponsor with their role |
| `push-stance-csv.mjs` | season-aware upsert, `assertWritten` on both writes, `--dry-run` |

Run order is leads → detail → (votes where sponsorship under-determines) → read → push.

🟢 **AND THE FULL INSTRUMENT TEXT IS REACHABLE, WHICH IS THE STEP THAT KEEPS CHANGING ANSWERS.**
`matter.asp?matter=NNNNNN&file=true&fileAnalysis=false&yearFolder=YNNNN` links
`legistarfiles/Matters/Y<year>/<matter>.pdf` — recitals and operative sections, not just the title.
Ordinance 26-51 was read as pro-cycling from its title and its own recitals, and its operative
section does the opposite. ⚠ That link **404s as HTTP 200 with 2,625 bytes of "Web Error" HTML** for
some matters; always fetch a known-good one in the same run as a control before recording an absence.

## What the work taught, in priority order

1. 🔴 **A sponsor report is not proof of sponsorship.** Open the matter page and read `prime_sponsors`.
   Three live cases: `261305` sits in Bastien's report and is Rodriguez's; `R-678-26` sits in
   Steinberg's and Garcia's and is Regalado's; `261104` sits in **eight** reports and is Rodriguez's.
2. 🔴 **`requester` is the discriminator, not volume.** A department item a member carried is weaker
   evidence than one they originated. That split is what decided the housing pass, and it is what
   left Bermudez and Gonzalez unseatable on transportation.
3. 🔴 **Read the instrument, never the label — and read past the recitals to the operative section.**
   `26-59` looked like rung-5 deregulation and is a same-day permitting service that *adds* county
   obligations. `26-51` is titled micromobility and its recitals "support the safe use" of e-bikes,
   while its operative §2-98.3(1) authorises municipalities to **restrict** them and disclaims any
   finding that riding is safe. `LU-8H` read verbatim turned a refusal into two seated rows.
4. 🔴 **Probe recency first.** Miami-Dade's Legistar answers HTTP 200 with well-formed JSON frozen at
   2018 and contains none of the sitting commissioners.
5. 🔴 **A uniform answer is a broken detector until controlled.** One sponsor on every matter;
   `section 8` matching "SECTION 8-9 OF THE CODE" on 18 of 123 housing matters; 104 of 106 Yes votes
   that cannot be read as approvals. ⚠ But sometimes the uniformity is real: the Transportation
   Committee is **one non-Yes vote in 435**, and the control is that the one No was found.
6. 🔴 **A keyword can move a matter into the wrong topic and the write-up will inherit it.** Bare
   `surtax` put a transit resolution (R-992-25) in the housing corpus, and Regalado's published
   housing prose then described the **transportation** surtax as the housing surtax. Corrected
   2026-09-08; the value did not move, and the other nine rows were controlled and are clean.
7. **Never write an identifier you did not look up.** Five of seven source URLs written from memory
   were wrong; a control comparing every cited id to its prime sponsor caught them.
8. **Which report is the right instrument depends on the topic.** Growth decisions are
   *applications* commissioners vote on and never sponsor, so sponsorship under-determines there.
   Transportation policy is *initiated* by commissioners, so sponsorship is sufficient and the
   committee vote report adds almost nothing. Decide this before paying for a report.

## Cheapest next steps

- **`local-environment`** — 57 leads, untouched, and **Steinberg holds 16 of them**, the most
  concentrated untouched person-topic pair on the Board. `--body=RTRC` pairs with it.
- **`residential-zoning`** — 70 leads. The RTZ matter detail already pulled for transportation is
  reusable, and the RTZ parcel additions that were *procedural* for transportation are *on-axis*
  here.
- **`city-sanitation`** — 61 leads; Regalado 17, Bastien 11.
- **Steinberg, Garcia, Lopez on housing** — refused for thin or mixed records; each would need one
  substantive own instrument to resolve.
- **Gilbert on transportation** — needs a funding mechanism he proposes rather than a study of
  possible ones.
- ⚠ **`growth-and-development` now carries CRA administration** (board appointments, budgets,
  pothole resurfacing) because CRA vocabulary was moved there from `economic-development`. Splitting
  CRA *creation and expansion* from CRA *housekeeping* would clean up ~14 of Cohen Higgins' 21.

## Cautions for whoever resumes

- Season 2 is open; Season 1 is closed. Writes land in Season 2 automatically via `seasonService`.
- **Every pre-existing Season 2 row has `editor_id = NULL`**; these eleven are attributed to
  `chris@empowered.vote` (`4e6dde8f-2bd0-4054-824f-4164744165ea`). Pass `EV_EDITOR_ID` or they will
  be unattributable. Look the id up from an existing row; do not retype it from memory.
- 🔴 **`miamidade-sponsorship-leads.jsonl` AS COMMITTED PREDATES THE `section 8` PATTERN FIX.** Matter
  `261305` still carries `housing` in it for five commissioners, so its housing counts (155 leads)
  are the pre-fix ones. `git diff` the patterns file against the sweep commit before trusting a lead
  count for a topic; `transportation-priorities` was byte-identical, so those leads were current.
- 🔴 **RE-MEASURE A BASELINE BEFORE SPENDING ON IT.** The line that stood here said "Hardemon
  `growth-and-development` — 21 leads". 21 is **Cohen Higgins'** count. Hardemon has **5**.
- Research CSVs are gitignored (`.gitignore:55`), so the database write and the reasoning stored with
  it are the durable record, not the CSV. The machine-local jurisdiction file is
  `backend/data/stance-research/2026-09-07-miamidade.csv` and it now mirrors all eleven rows;
  `push-stance-csv.mjs` re-reads it, so update a row in place rather than appending a duplicate.
- The county serves **U+FFFD** where quotation marks were, in most matter titles. It is unrecoverable
  and flagged per item; repair at the point of quoting, never in bulk.
- The `ev-accounts-mdc` worktree is recreated per session. This pass used
  `feat/miamidade-stances-2` off master; the previous one was PR #401. Never work in `C:/EV-Accounts`.
