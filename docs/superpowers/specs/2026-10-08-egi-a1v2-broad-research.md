# education-gender-identity — broad research on draft ladder A1 v2 (offline)

Date: 2026-10-08. For Chris Andrews. **Offline only: nothing was written to prod.** No
`compass_topic_revisions` row, no season pin, no `politician_answers` / `politician_context`, no review-queue
row, no `source_snapshots` row. Prod was read through the session pooler with
`SET default_transaction_read_only = on` (confirmed `on`; a test `CREATE TABLE` was refused).

Ladder: A1 v2 as approved 2026-10-08 ([`2026-10-08-egi-pilot-draft-ladders.md`](2026-10-08-egi-pilot-draft-ladders.md), PR #945).
Rules: codebook 0.4 + the 2026-10-08 rulings ([`2026-10-07-season3-ladder-evaluation.md`](2026-10-07-season3-ladder-evaluation.md), PR #944).
Roles (CA_0302): school = record, state = record, federal = own words, local = own words.

| rung | text |
|---:|---|
| 1 | Require staff to keep a student's gender identity from parents unless the student consents. |
| 2 | Forbid rules that require schools to tell parents. |
| 3 | Require schools to tell parents when parents ask. |
| 4 | Require schools to notify parents. |
| 5 | Require parental permission before staff use a different name or pronouns. |

## Result in one paragraph

Of **476 people** in three counties, the coder seated **10**: six Wisconsin legislators at **rung 5** on AB 103
(2025), and four Indiana legislators at **rung 4** on HEA 1608 (2023). **I recommend that the four Indiana
seats are reviewed as direction-only** (see "Reviewer flags"), which would leave 6. **No one was seated on
rungs 1, 2 or 3, no challenger was seated, and no own-words chair was seated at any level.** Most blanks are
honest no-source rows: 333 local officials and candidates said nothing findable on this question. The
largest *informative* blank is Utah: 14 legislators voted for SB 100 (2023), and the coder placed it on no
rung, because SB 100 acts on the **education record**, not on telling parents or on what staff call a
student. That is the main ladder gap (below).

## 1. Seat table

Basis = what can seat a chair at that level. Counts are people. "dir-only" = the evidence shows a side but
not a rung; "no-evidence" = sources were coded but cannot seat (federal records; a near-unanimous vote; a No
on a multi-subject bill); "no-source" = nothing found to code. Full per-person rows, with the coder's
reasoning: `backend/data/stance-research/2026-10-08-egi-a1v2/seat-table.csv`.

### Incumbents

| area | level | basis | n | r1 | r2 | r3 | r4 | r5 | dir-only | no-evidence | no-source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Monroe IN | school | record | 12 | · | · | · | · | · | 5 | · | 7 |
| Monroe IN | state | record | 6 | · | · | · | 4 ⚑ | · | 1 | 1 | · |
| Monroe IN | federal | own-words | 3 | · | · | · | · | · | 2 | · | 1 |
| Monroe IN | local | own-words | 65 | · | · | · | · | · | · | · | 65 |
| Racine WI | school | — | 0 | | | | | | | | |
| Racine WI | state | record | 9 | · | · | · | · | 6 | 3 | · | · |
| Racine WI | federal | own-words | 3 | · | · | · | · | · | · | 1 | 2 |
| Racine WI | local | own-words | 135 | · | · | · | · | · | · | · | 135 |
| Utah County UT | school | record | 21 | · | · | · | · | · | · | · | 21 |
| Utah County UT | state | record | 26 | · | · | · | · | · | 14 | 1 | 11 |
| Utah County UT | federal | own-words | 4 | · | · | · | · | · | 1 | 2 | 1 |
| Utah County UT | local | own-words | 123 | · | · | · | · | · | 1 | · | 122 |

⚑ = reviewer flag: under V4.1 these read direction-only (below).

### Challengers (2026 candidates who do not hold the seat they seek)

| area | level | basis | n | r1 | r2 | r3 | r4 | r5 | dir-only | no-evidence | no-source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Monroe IN | school | record | 3 | · | · | · | · | · | · | · | 3 |
| Monroe IN | state | record | 3 | · | · | · | · | · | · | · | 3 |
| Monroe IN | federal | own-words | 2 | · | · | · | · | · | 1 | · | 1 |
| Monroe IN | local | own-words | 10 | · | · | · | · | · | · | · | 10 |
| Racine WI | state | record | 9 | · | · | · | · | · | 2 | · | 7 |
| Racine WI | federal | own-words | 1 | · | · | · | · | · | · | · | 1 |
| Utah County UT | state | record | 22 | · | · | · | · | · | 3 | · | 19 |
| Utah County UT | federal | own-words | 9 | · | · | · | · | · | · | 1 | 8 |
| Utah County UT | local | own-words | 10 | · | · | · | · | · | · | · | 10 |

(No Racine school or local challenger rows: Wisconsin school-board and municipal elections are in April,
so the November ballot holds none. No Utah school-board challenger is in the database.)

### Records vs own words

- **Every seat rests on a record** (a recorded Yes on final passage, plus authorship for two people).
- **Own words seated nothing.** Own words found: Banks (statement + S. 2702 sponsorship), Owens (release),
  Houchin (op-ed), Wanggaard (release), Yoder (caucus release). Each says *parents should know* or opposes
  *forced outing*, and none chooses between "when parents ask", "notify" and "permission first". That
  matches the pilot's note: supporters rarely choose between rungs 3 and 4 in their own words, and
  opponents rarely state a rule of their own.
- **Challengers seated nothing** (46 campaign sites / questionnaires searched; 6 generic "parental rights"
  lines, all direction-only, none coded).

### The seated rows

| person | area | rung | evidence | vote |
|---|---|---:|---|---|
| Robin Vos | Racine (AD 33) | 5 | Yes, AB 103 (2025) | 50-43 |
| Bob Wittke | Racine (AD 63) | 5 | Yes, AB 103 (2025); author of AB 510 (2023) | 50-43 |
| Chuck Wichgers | Racine (AD 84) | 5 | coauthor + Yes, AB 103 (2025) | 50-43 |
| Julian Bradley | Racine (SD 28) | 5 | Yes, AB 103 (2025) | 18-15 |
| Steve Nass | Racine (SD 11) | 5 | Yes, AB 103 (2025) | 18-15 |
| Van Wanggaard | Racine (SD 21) | 5 | Yes, AB 103 (2025) | 18-15 |
| Bob Heaton ⚑ | Monroe (HD 46) | 4 | Yes on concurrence, HEA 1608 (2023) (co-author of the bill as filed, which had no notice clause) | 63-29 |
| Dave Hall ⚑ | Monroe (HD 62) | 4 | Yes on concurrence, HEA 1608 (2023) | 63-29 |
| Peggy Mayfield ⚑ | Monroe (HD 60) | 4 | Yes on concurrence, HEA 1608 (2023) | 63-29 |
| Eric Koch ⚑ | Monroe (SD 44) | 4 | Yes on Senate passage, HEA 1608 (2023) | 37-12 |

## 2. Instruments found and the rung each seats

| instrument | operative act | rung (coder) | who it reached |
|---|---|---:|---|
| **WI AB 103 (2025)**, vetoed 2026-03-31 | staff may not use a name/pronoun not aligned with sex "without written authorization from the pupil's parent" — single subject | **5** | 6 Yes seated; Cruz, Neubauer, Wirch No → direction-only |
| WI AB 510 (2023), vetoed | parents' bill of rights; one clause: parents' "right to determine the names and pronouns used for the child while at school" | none (multi-subject, V4.1) | direction-only; Schutt's only record |
| WI AB 963 (2021), vetoed | same clause, earlier session | none (multi-subject) | direction-only |
| **IN HEA 1608 (2023)**, enacted | IC 20-33-7.5-2: "A school shall notify in writing at least one (1) parent" of a name/pronoun request; no safety exception. Also bans K-3 human-sexuality instruction and amends counselor privilege | **4** (coder) / direction-only (reviewer, V4.1) | Heaton, Hall, Mayfield, Koch Yes; Pierce, Yoder No |
| IN HB 1608 as passed by the House (02.COMH) | staff may use a different name/pronoun **only if a parent requests it in writing** | (would be 5) | House Yes 65-29 — the Senate removed this clause; nobody was coded on it alone |
| IN HB 1608 Senate Amendment #11 (Yoder), failed 14-34 | a student may withdraw the request to avoid notice | none — fits no rung | Yoder (author), Koch No |
| **UT SB 100 (2023)**, enacted (53E-9-205) | school may not bar a parent from the education record; may not change the record's gender identity "without written parental consent" | **none** — "acts on the education record" | 14 direction-only. House vote 59-6 is near-unanimous (<10% No); Senate 22-6 is contested |
| UT HB 250 (2025), died in Senate committee | no discipline for staff who use the parent-preferred (or student-preferred) name | none — fits no rung (not coded) | McCay floor sponsor; House 51-13 |
| US H.R. 5 (118th), House 213-208 | multi-subject; parental **consent** before changing gender markers, pronouns or preferred name **"on any school form"** | none (federal = own words; multi-subject) | Steil, Owens, Houchin, Banks, Curtis Yes |
| US H.R. 2616 (119th), House 217-198 | single subject; same consent-on-school-forms rule | none (federal = own words) | Houchin, Steil, Owens, Maloy, Kennedy Yes |
| US S. 2702 (119th), Banks lead sponsor | express parental consent before staff take any step to affirm a student's identity; bars concealment | none (coded as a record at a no-lever level) | Banks — see question Q2 |
| MCCSC Resolution 2023-07 | "strongly opposes" HB 1608; declares a safe place; sets no notice rule | none | 5 roster trustees direction-only |
| Provo SD Policy 3300 (2025) | preferred name in records only on parent request; staff use identified pronouns | not coded — no attributable vote | gap (mixed policy) |

Board policies: MCCSC Policy 3519 (2024) follows state law (fits no rung, no named vote); Alpine and Nebo have
staff guidance only, no board vote found; Richland-Bean Blossom, nothing. **Racine County school boards are
not in the database at all** (no districts, offices or people), so that cell is empty by construction.

## 3. Gaps and rung pairs

### Gap A — record/form rules (common; the ladder has no rung)

Two of the three state instruments and all three federal bills govern the **school record or school forms**,
not telling parents and not what staff say:
- UT SB 100: no shielding of the education record + consent before a gender change *on the record*.
- H.R. 5 / H.R. 2616 / H.R. 736: consent before changing gender markers, pronouns or name *"on any school form"*.

The coder consistently refused them on rung 5 ("before staff use") and on rung 3 ("tell parents when they
ask") — 14 Utah legislators and every federal record. Each of these laws is a real, enacted or passed
position between rungs 3 and 5. **If the ladder is meant to place them**, one option is to widen rung 5 to
"…before staff use or record a different name or pronouns" (one act, L7 "or"), and/or rung 3 to cover a
parent's right to the record. That is a material rewrite under the 2026-08-28 rule, but A1 v2 holds 0 seats
today, so it costs no re-audit.

### Gap B — protecting staff who use the parent's choice (UT HB 250, 2025)

A discipline shield for staff fits no rung. It died, so it is rare in this sample.

### Gap C — Yoder's amendment (IN, 2023)

"The student may withdraw the request, and then nobody is told" is a student-controlled position short of
rung 1. One instance only.

### Rung pairs the coder could not separate

- **3 vs 4 vs 5 in own words.** Every own-words statement (Banks, Owens, Houchin, Wanggaard) sits on the
  parents' side but does not choose between "when parents ask", "notify" and "permission". This is the
  pilot's known behaviour, now seen on real people: own words on this ladder carry direction, not a rung.
- **1 vs 2 in opposition.** Every opponent (Cruz, Neubauer, Wirch, Pierce, Yoder, the MCCSC trustees) was
  coded direction-only: opposing a notice or consent law does not choose between "require secrecy" and
  "forbid notice rules". No instrument in these three states states rung 1 or 2.
- **4 vs 5 held.** The coder separated them cleanly where the text was clear: AB 103 → 5, HEA 1608 (enrolled)
  → 4, and it noted that the House version of HB 1608 would have been 5.

## Reviewer flags (my review, not the coder's — the coder's rows are kept unchanged)

1. **HEA 1608 is multi-subject.** The enrolled act also bans K-3 human-sexuality instruction and amends
   counselor privilege. Codebook V4.1: Yes on final passage of a multi-subject bill shows "direction at most".
   The same coder run applied that rule to Pierce's No vote on the same act, and to AB 510 / AB 963 in
   Wisconsin, but seated Heaton, Hall, Mayfield and Koch at rung 4. I read those four as **direction-only**
   unless you rule that the notice chapter is a separate subject. Heaton's co-authorship does not change
   this: as filed (01.INTR), the bill held only the K-3 instruction ban and had no notice clause at all, so
   sponsorship (which evidences the bill as filed, C37) says nothing on this topic.
2. **Run-to-run noise.** One Opus run per person (the pilot setup). Expect ±1 on boundary cases.

## Questions for you

- **Q1 (ladder).** Should rung 5 and/or rung 3 cover record and school-form rules (Gap A)? As drafted, the
  most common enacted and passed laws in this sample seat nobody.
- **Q2 (rule).** Does the 2026-10-08 "sponsored resolution = own words" rule extend to a **bill** that a person
  lead-sponsored at a no-lever level? If yes, Banks (S. 2702: consent before any affirming step) is a
  candidate for rung 5 and should be re-coded with that rule in the prompt. The codebook still has that
  point as `_owed:_`, so the coder treated S. 2702 as a record.
- **Q3 (V4.1).** Confirm the HEA 1608 flag: are the four Indiana rung-4 rows direction-only?

## 4. Coder rows kept as files (not pushed)

`backend/data/stance-research/2026-10-08-egi-a1v2/` — one directory per coded person (43 people), each with
`sources.json`, `snapshots.json`, `coder-inputs/coder-1.md` (the exact prompt), `labels/coder-1.json` (the
coder's row), `coder-logs/`. Also `seat-table.csv`, `seat-matrix.md`, the build specs (`spec-*.json`), the
roster (`roster.csv`, `roster.sql`), the research leads (`leads/*.json`), the saved texts of PDFs the fetcher
could not read (`saved-pages/`), `run_egi.py` (the offline driver) and `seat_table.py`.

How it ran: per person, `build-stance-topic-bundle` (read-only) → replace `topics.json` with the A1 v2 alias
`egi-draft-a1v2` (setup from the transcript session; no annex file exists for that key, so the coder
prompt says "no annex — apply the codebook alone"; the driver asserts both) → `coding:snapshot` **without
`--apply`** → `coding:inputs` (read-only) → Opus slot 1, `claude -p` with Write only. 43 coder runs,
API-price equivalent **$43** (plan quota).

Source discovery used six research sub-agents (state × 3, federal, local sweep, challenger sweep). The skill
asks for inline research; I used agents because the coder never sees an agent's claim, only pages that the
snapshot step fetched itself, so an agent cannot seat a chair by asserting one. Pages that the fetch tiers
could not read (le.utah.gov and iga.in.gov PDFs, and a scanned MCCSC resolution) were saved by
`pdf-snapshot.ts --file` or OCR, with the source URL in each file.

**To push after approval** (each step needs your yes):
1. Write A1 v2 as a revision, approve it, and pin it into the Season 3 draft `7b3a066c-…`.
2. Re-point each person's batch from the alias to the real topic: rebuild the bundle with `--season draft`,
   rewrite `topic_id` / `served_revision_id` in `labels/coder-1.json`, then `labels_to_research.py` →
   `stance-gate` → `verify-stance-research --season draft` (review-all; never `--auto-push`).
3. Apply your rulings on Q1-Q3 first. A Q1 rewrite means re-coding the affected people (the specs re-run in
   one command).

Leases held: `county:18105`, `county:55101`, `county:49049`. I release them once you decide.
