# Columbus, Georgia — scope and source review

Batch `2026-10-29-knight-columbus-ga`. Written 2026-10-29, before any row was researched.

Slice 3 (Minnesota) established that this review has to happen **per state and per rung**, not by
copying the last slice's answer: `cannabis-policy` was live in Florida and blank in Minnesota, for
reasons neither state's review could have guessed from the other. Georgia reverses Minnesota again.

---

## 1. The record channel: Municode Meetings, and it is better than Legistar

Columbus publishes approved council minutes as PDFs at
`columbus-ga.municodemeetings.com`. **441 documents are listed on one page, 205 of them full
minutes**; 202 fetched (3 were dead links).

🟢 **THE VERIFIER EXTRACTS PDF TEXT, SO THESE PAGES ARE CITABLE.**
`src/lib/verificationFetch.ts` routes a PDF response through `extractPdfText` before matching a
snippet. A minutes PDF is therefore an ordinary source — fetch it, quote it, cite its URL. This is
worth stating plainly because slice 4's equivalent was not: Philadelphia's per-member roll calls
were an HTML **table**, authoritative and impossible to quote, so every chair had to be cited to
something else.

The extracted text carries five channels, all in prose:

| Channel | What it looks like | Why it matters |
| --- | --- | --- |
| `attribution` | `(Councilor Crabb)` after an item title | **Columbus publishes no sponsor list.** This is the sponsorship equivalent — the channel that carried slices 3 and 4 |
| `motion` | `Councilor X made a motion to adopt the ordinance` | an act, but mostly procedural — read the item first |
| `second` | `seconded by Councilor Y` | weakest; a second is not a position |
| `vote` | `with Councilors Chambers, Cook, Huff and Tucker voting yes, and Mayor Pro Tem Allen and Councilors Barnes, Cogle, Davis and Garrett voting no` | a **named divided roll call, in quotable prose** |
| `remark` | `Councilor X expressed / stated / explained …` | the member's own words, inside the record |

Instruments are numbered `Ordinance No. 26-021` and `Resolution (320-26)`, which
`NAMES_INSTRUMENT` matches.

`ccg_member_index.mjs` (this directory) indexes one member's hits across the corpus. It requires
`--since` and it ships a `--control`; read §4 for why both are not optional.

### 🔴 2019 AND 2020 ARE SCANNED IMAGES — 41 MEETINGS WITH ZERO EXTRACTABLE TEXT

Measured, not assumed: **every one of the 15 meetings in 2019 and 25 of the 26 in 2020 extract to
0 characters** from PDFs of 240 KB to 1.7 MB. From 2021 the minutes are born-digital and extract
cleanly; one outlier, 2022-01-11, is also an image.

▶ **The usable corpus is 2021-01-05 → 2026-09-29, 161 meetings.** This is not only a research
limit — it is a **citation** limit. A scanned page extracts to nothing for the verifier too, so a
passage read out of one by eye could never be cited. Do not OCR these and quote them.

### 🔴🔴 DISTRICT 1 HAS HAD TWO COUNCILLOR BARNESES, AND THEY ARE FATHER AND DAUGHTER

Jerry "Pops" Barnes represented District 1 until his death in 2024. **Simi Barnes is his daughter**,
and holds the same seat from 2026-05-26. The minutes of 2026-05-28 record Mayor Pro Tem Allen
nominating her to finish her father's term, against Councillor Crabb's motion to nominate Byron
Hickey, which carried six to three — so the seat did **not** pass to her in 2024, and everything
"Councilor Barnes" did between 2021 and March 2024 is her father's record.

🔴 **NOTHING IN THE PIPELINE CAN SEE THIS.** `checkNameProximity` looks for the surname near the
snippet, and both Barneses satisfy it. C44 refuses a vote cast before the member took the seat, but
only a human knows which Barnes a 2023 passage is. **Simi Barnes's floor is 2026-05-26**, which
leaves her 10 meetings.

▶ The general rule: in a consolidated government, check whether the surname in the minutes is the
person you are researching before you check anything else.

---

## 2. What Columbus Council actually legislates on

A keyword sweep of the 161 readable meetings, counting mentions and the meetings carrying them:

| Subject | Mentions | Meetings | Reading |
| --- | ---: | ---: | --- |
| zoning / density | 1,408 | 130 | the council's main business |
| police / public safety | 1,355 | 150 | live, every meeting |
| transit / sidewalks | 753 | 124 | live |
| jail | 306 | 91 | live |
| sanitation | 216 | 78 | live |
| firearms | 77 | 32 | 🔴 preempted — see §3 |
| schools | 78 | 42 | a separate elected board; see §3 |
| homelessness | 73 | 20 | live |
| data centers | 62 | 12 | live and contested in 2026 |
| housing | 50 | 29 | live |
| immigration / ICE | 46 | 20 | partly preempted; see §3 |
| rent / tenants | 36 | 18 | 🔴 preempted — see §3 |
| civil rights | 30 | 16 | live |
| climate / energy | 19 | 11 | thin |
| childcare | 15 | 9 | thin |
| fossil fuels | 13 | 7 | thin |
| cannabis | 6 | 3 | 🟢 live in Georgia — see §3 |
| **ranked-choice voting** | **0** | **0** | documented zero |
| **campaign finance** | **0** | **0** | documented zero |
| **trans athletes** | **0** | **0** | documented zero |
| **religious freedom** | **0** | **0** | documented zero |
| **2020 election** | **0** | **0** | documented zero |

The five zeros are honest: the same sweep in the same run returned four-figure counts for other
subjects, so the detector is not blind.

---

## 3. What Georgia law removes, rung by rung

Every claim here is cited to the statute text as fetched, not to a summary.

### `gun-policy` — no rung is a city lever

**O.C.G.A. § 16-11-173(b)(1)**: *"no county or municipal corporation, by zoning, by ordinance or
resolution, or by any other means … shall regulate in any manner: (A) Gun shows; (B) The possession,
ownership, transport, carrying, transfer, sale, purchase, licensing, or registration of firearms…"*

All five rungs are firearms regulation. The 77 mentions in the corpus are gun **violence** —
policing, curfews, incident reports — not regulation of firearms. **No record can seat this chair at
this level.** Own words still can (codebook V2, "No-lever level").

### `minimum-wage` — no rung is a city lever, and the statute names consolidated governments

**O.C.G.A. § 34-4-3.1(b)**: *"Any and all wage or employment benefit mandates adopted by any local
government entity are hereby preempted. … No local government entity may adopt, maintain, or enforce
… a wage or employment benefit mandate."* Subsection (a)(4) defines "local government entity" to
include a **consolidated government**, which is exactly what Columbus is. Subsection (c) closes the
contracting route as well.

### `rent-regulation` — rungs 1, 2 and 4 removed; 3 and 5 survive

**O.C.G.A. § 44-7-19**: *"No county or municipal corporation may enact, maintain, or enforce any
ordinance or resolution which would regulate in any way the amount of rent to be charged for
privately owned, single-family or multiple-unit residential rental property."*

⚠ **This is a rung-level answer, not a topic-level one.** Rungs 1, 2 and 4 all set or limit rents,
so they are gone. Rung 3 — *maintain current tenant protections while allowing market rents* — is
reachable, because a Georgia city may still legislate on tenant protections that are not rent
amounts. Rung 5 — *oppose rent control entirely* — is a position a member can hold and state.

### `local-immigration` — rung 1 removed; 2 to 5 survive

**O.C.G.A. § 36-80-23(b)**: *"No local governing body … shall enact, adopt, implement, or enforce any
sanctuary policy."* The definition at (a)(6) is narrow: a policy that *"prohibits or restricts local
officials or employees from communicating or cooperating with federal officials … with regard to
reporting immigration status information"*.

That is the second clause of **rung 1** word for word, so rung 1 is removed. Rungs 2 and 3 concern
detainers and the use of local resources, not status-information sharing, and are not barred by this
section. 🔴 **The Sheriff is a separate question** — Georgia HB 1105 (2024) places duties on jailers
that the City Council does not carry. Verify it against the statute before researching Sheriff
Countryman; it is not verified here.

### `ranked-choice-voting` — a documented zero, and probably also preempted

Zero mentions in 161 meetings. ⚠ Georgia's 2024 restriction on ranked-choice voting was **not**
verified for this review — § 21-2-285 is the ballot-form section and is not it. Do not cite a ban
without finding it. The blank rests on the measured zero and on ballot form being state business,
which is enough.

### 🟢 `cannabis-policy` — LIVE, AND THIS REVERSES THE MINNESOTA FINDING

Minnesota's § 342.13 bars a city from prohibiting cannabis, which made rung 4 the state law and the
ladder blank. Georgia is the opposite case: several Georgia cities have adopted local ordinances
reducing possession of small amounts to a civil fine, which is **rung 3** exactly. So rung 3 is a
genuine Columbus lever.

▶ Only 6 mentions across 3 meetings, so expect a blank in practice — but blank it on *"the council
has not acted"*, never on *"the city cannot act"*. Those are different sentences and only one of them
is true here.

### The three `education-*` lever topics — not this body's

`education-school-police`, `education-charter-authorization` and `education-school-budget` are local
levers in general, but **Muscogee County School District has its own separately elected board**. The
78 school mentions in the corpus are the council's dealings *with* the district — joint facilities,
SPLOST, courtesy appearances — not governance of it. A council member holds no rung here.

---

## 4. 🔴 TWO DETECTORS CAME BACK BLIND IN THIS SETUP, AND ONE WAS SILENT

Both are the same lesson, and both are the reason §1 ships a `--control`.

1. **`ccg_member_index.mjs` reported 0 hits for a member with 187 meetings.** The script had been
   written through a shell heredoc, which stripped one level of backslash out of every regex, so
   `\(\s*…\)` became `(s*…)` — a group that matches nothing. It threw no error and printed a clean
   JSON summary with zeros in it. Only a positive control on a passage known to be in the corpus
   exposed it. ▶ **Write a tool with a file write, not a heredoc, when its content is regex.**
2. **41 meetings extracted to zero characters** and the extraction run reported `ok=202 fail=0`,
   because an image-only PDF is not an extraction *failure*. ▶ **Count the characters, not the
   exits.**

### Known defect to work around

🔴 **`David A. Britt II` will fail snippet verification on the suffix bug** (slice 4, repo-wide):
`verify-stance-research.ts` takes the last token of the name as the surname, so it hunts for "II"
and every page printing "Tax Commissioner Britt" reads as `name_not_present`. It fails **silently
into the queue**, not into an error. He needs a source that prints his full name in prose near the
passage.
