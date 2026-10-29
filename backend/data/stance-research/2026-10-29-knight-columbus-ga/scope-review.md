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
| `attribution` | `(Councilor Crabb)` after an item title | **Columbus publishes no sponsor list.** This is the sponsorship equivalent — the channel that carried slices 3 and 4. ⚠ It has a second, opposite meaning; see below |
| `motion` | `Councilor X made a motion to adopt the ordinance` | an act, but mostly procedural — read the item first |
| `second` | `seconded by Councilor Y` | weakest; a second is not a position |
| `vote` | `with Councilors Chambers, Cook, Huff and Tucker voting yes, and Mayor Pro Tem Allen and Councilors Barnes, Cogle, Davis and Garrett voting no` | a **named divided roll call, in quotable prose** |
| `remark` | `Councilor X expressed / stated / explained …` | the member's own words, inside the record |

Instruments are numbered `Ordinance No. 26-021` and `Resolution (320-26)`, which
`NAMES_INSTRUMENT` matches.

`ccg_member_index.mjs` (this directory) indexes one member's hits across the corpus. It requires
`--since` and it ships a `--control`; read §4 for why both are not optional.

### 🔴 `(Councilor X)` MEANS TWO OPPOSITE THINGS, AND THE DIFFERENCE IS THE WHOLE CHANNEL

On a policy ordinance or resolution it names the councillor who **brought** the item: *"An Ordinance
… to abolish the Civic Center Advisory Board … (Councilor Crabb)"*, and Crabb then moves its
adoption. On a **rezoning** it names the councillor whose **district the parcel is in**: *"8300 /
8350 Fortson Road … (Councilor Davis)"*, and Councillor Tucker moves it.

Measured for Glenn Davis: of his 96 attributions, **54 are zoning cases and 42 are policy items**.
Reading a rezoning attribution as sponsorship would have credited him with a position on 54 parcels
he happened to represent. ▶ **Split on the item type before reading a single one.** The signal is
reliable: `REZN-`, "Zoning Atlas", `EXCP-`, "special exception", "variance".

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

### `gun-policy` — the city cannot regulate, but it has twice taken a position, and that is evidence

**O.C.G.A. § 16-11-173(b)(1)**: *"no county or municipal corporation, by zoning, by ordinance or
resolution, or by any other means … shall regulate in any manner: (A) Gun shows; (B) The possession,
ownership, transport, carrying, transfer, sale, purchase, licensing, or registration of firearms…"*

So no Columbus ordinance can seat a chair here.

🔴🔴 **AND THE FIRST VERSION OF THIS SECTION STOPPED THERE, WHICH WAS WRONG.** It read: *"The 77
mentions in the corpus are gun violence — policing, curfews, incident reports — not regulation of
firearms."* That sentence was written from a keyword count and never checked against the passages it
described. The Council has taken a recorded position on gun policy **twice**, both times through its
legislative agenda:

- **Resolution 340-25, 2025-10-14** — *"requesting the Local Delegation to support H.B. 601 which was
  introduced in the 2025 session of the Georgia General Assembly."* Carried unanimously by the eight
  members present; Davis and Hickey absent.
- **Resolution 322-25, 2025-09-23** — requesting statewide legislation to prohibit carrying weapons
  in a publicly owned recreation centre, amended on Garrett's suggestion so the prohibition would not
  reach the surrounding grounds. Carried unanimously by the nine members present; Crabb absent.

**H.B. 601 settles a chair, and only the bill's own text could.** Two search summaries disagreed
about whether it touches assault weapons, and one of them was openly AI-generated. The official
document (legis.ga.gov, `api/legislation/document/20252026/233626`) carries new Code Section
16-11-174: subsection (a) defines an *assault weapon* to include *"a semiautomatic rifle that has an
overall length of less than 30 inches"* and a semi-automatic centre-fire rifle taking a detachable
magazine with a listed feature, and subsection (b) provides that *"No purchase or transfer of any
assault weapon shall be conducted by a licensed importer, licensed manufacturer, licensed dealer, or
gun show vendor in this state for the period beginning July 1, 2025, through January 1, 2036."*

That is **chair 2** — *ban semi-automatic assault-style weapons, while allowing other firearms* —
and the other rungs are excluded by text rather than by elimination: chair 1 fails because other
firearms stay lawful to own, chair 3 fails because the bill does not *allow all types*, and chairs 4
and 5 fail because the bill adds restrictions rather than loosening them.

⚠ **Recorded as `statement`, not `record`, and deliberately.** A vote to ask the legislature to act
is the member stating a position, not an exercise of a lever over the rung — the distinction the
2026-10-06 ruling draws. This follows the Philadelphia precedent of classifying a novel evidence
class as `statement` so it routes to a person rather than auto-pushing.

⚠ **Resolution 322-25 seats nothing on its own.** A carry restriction inside one class of public
building is not a rung: chair 4 fails because it *adds* a carry restriction, and chairs 1 to 3 are
about ownership, weapon types and background checks. It corroborates the direction and no more.

🔴 **The unanimous votes count only through the small-bodies exception** (codebook 0.6 V4.1): the
Council has ten voting members, each resolution was its own numbered action item with its own motion
and vote rather than a consent or en bloc item, and nothing in Georgia law obliges a city to endorse
a state bill. Check all three before leaning on any other unanimous Columbus vote.

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

## 2a. 🟢🟢 THE LEGISLATIVE AGENDA IS A POSITION CHANNEL, AND THE KEYWORD SWEEP HID IT

Columbus adopts an annual **legislative agenda**: a numbered series of resolutions asking the local
delegation to the Georgia General Assembly to pass, support or amend specific legislation. Each one
is its own action item with its own motion and vote. **40 such items appear in the readable corpus**,
clustered in October 2023, October 2024, September and October 2025 and November 2025.

This is where a Columbus councillor states a position on something the city cannot legislate. It is
the channel that carries every preempted topic, and §3 below had already written three of them off
before it was found.

| Item | Date | Bears on |
| --- | --- | --- |
| SUPPORT OF HOUSE BILL 601 | 2025-10-14 | 🟢 `gun-policy` — seats chair 2, see §3 |
| WEAPONS IN RECREATION CENTERS | 2025-09-23 | `gun-policy`, direction only |
| HOUSING AFFORDABILITY (Res 373-23) | 2023-10-10 | 🟢 `rent-regulation` — seats Crabb at 5 |
| SHORT TERM RENTALS | 2023-10-10, 2024-10-22 | `housing` / `residential-zoning` — unread |
| ADOPT THE MENTAL HEALTH MODEL · FUNDING FOR BEHAVIORAL HEALTH | 2023-10-10, 2024-10-22 | `healthcare`, which is own-words-only, so a vote cannot seat it |
| MILITARY RETIREE STATE TAX EXEMPTIONS | 2024-10-22, 2025-09-23 | `taxes`, own-words-only |
| OUT OF NETWORK AMBULANCE SERVICES · EMS REIMBURSEMENTS | 2025-10-14 | `healthcare`, own-words-only |

▶ **The rest of this table is unread.** Work it before writing another member's blanks.

🔴 **HOW IT WAS NEARLY MISSED, which is the part worth keeping.** The §2 sweep counted 77 firearms
mentions in 32 meetings, and this document summarised them in one line as *"gun violence —
policing, curfews, incident reports — not regulation of firearms"*. Nobody read them. That sentence
then justified writing `gun-policy` off as a dead topic, and a member's blank went into research.csv
saying nothing in the minutes recorded her acting on it — while she had voted for Resolution 340-25.
▶ **A keyword count tells you where to read. It is not a reading**, and a one-line characterisation
of a count is an assumption wearing a measurement's clothes.

## 3a. 🟢 THE FIRST INSTRUMENT, AND IT SEATS SIX OF THE TWELVE AT ONCE

**Ordinance 25-040**, adopted 2025-08-12, repeals and replaces Columbus Code § 14-13 with a new
section *"that prohibits camping on public property within Columbus, Georgia"*. Sponsored by
Councillor Crabb. Carried **nine to one**, Councillor Cogle opposed.

**C46 is satisfied without the small-bodies exception.** One vote against out of ten is exactly the
10% the rule asks for, and it was its own action item — City Attorney's Agenda, Ordinances, item 1 —
not a consent agenda. Georgia mandates no camping ban, so the provision is the body's own choice.

**The chair is 5, and the penalty clause is what decides it.** Chair 4 prohibits encampments
*"enforced through graduated warnings and **civil** penalties"*; chair 5 bans public camping and
sleeping *"with **criminal** penalties"*. Subsection (j) of the adopted text reads: *"Any person
violating any provision of this section 14-13. shall, upon conviction in the recorder's court, be
punished as provided in section 1-8 of this Code."* Conviction in a court is criminal. Subsection
(b) makes it *"unlawful for any person to camp on any public property"*, and the definition of
camping expressly covers *"sleeping activities, or making preparations to sleep"*.

⚠ **The eight-day notice is chair 4's mechanism and does not carry the chair.** Crabb's amendment
added written or oral notification and eight days to vacate, which is a graduated warning — but
chair 4 is compound and its penalty half fails. The council's own record corroborates the reading:
Crabb's referral of 2025-07-22 asks the Mayor for a discussion that is *"to include the criminal
aspect of the ordinance"*.

▶ **Seats `homelessness` 5 for Allen, Chambers, Crabb, Davis, Garrett and Tucker** — six of the
twelve local subjects, off one instrument, exactly as Duluth's 26-0100R seated four. Davis's row
carries the same evidence and will queue unverified; see the comma-list defect below.
⚠ Anker, Hickey and Huff also voted for it. Huff is out of scope (District 3, January handover);
Anker and Hickey have since left the council and were replaced by Barnes and Cook.

🟢 **AND IT GIVES SIMI BARNES HER OWN WORDS, BEFORE SHE HELD THE SEAT.** At the first reading on
2025-07-22 the minutes record her in public comment: *"Simi Barnes – Stated she believes it is a step
toward criminalizing homelessness."* Admissible under the 2026-10-06 campaign-statements ruling, and
it is the opposite pole from the chair her six future colleagues took. ⚠ It is a **direction, not a
chair** — it rules out 4 and 5 and does not choose among 1, 2 and 3. Blank, and say so.

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

### 🔴🔴 A COMMA-LIST ROLL CALL CANNOT VERIFY A COMMON SURNAME, AND IT IS REPO-WIDE

Columbus writes a divided vote as one sentence: *"carried by a nine-to-one vote, with Mayor Pro Tem
Allen and Councilors Anker, Chambers, Crabb, Davis, Garrett, Hickey, Huff and Tucker voting in
favor, and Councilor Cogle voting in opposition."* That is the ideal citation — quotable, verbatim,
and it names everyone.

**Measured against the real `checkNameProximity`, on the real page, for the real snippet:**

| Member | Verdict |
| --- | --- |
| Gary Allen | `verified` — rescued by the singular title in "Mayor Pro Tem Allen" |
| Charmaine Crabb · Toyia Tucker · Walker Garrett · Travis L. Chambers | `verified` |
| **Glenn Davis** | 🔴 **`name_not_present`** |

`davis` and `allen` are the only two Columbus surnames in `COMMON_LAST_NAMES`, and a common surname
needs a title within 30 characters. **Two independent things defeat it, and fixing either alone
would not help:**

1. `TITLE_PATTERN` matches `councilor` and **not the plural `councilors`** — the same gap slice 3
   recorded for "BY COUNCILORS JOHNSON". A tally is always plural.
2. Even with the plural accepted, **"Councilors Anker, Chambers, Crabb, " is 35 characters**, so the
   title cannot reach the fourth name. In a ten-member body that excludes most of the list.

▶ **This is the Philadelphia suffix bug's sibling**: the row is correct, the evidence is real, and it
**fails silently into the review queue** as unverified — which reads like a sourcing problem and
invites a re-research that cannot possibly fix it. Record it in `editor_note`, never in the
voter-facing reasoning, and let the reviewer confirm by eye.
▶ It generalises: **any city whose minutes write tallies as a comma-list of surnames will lose every
member with a common surname.** Check it before pricing a slice on roll calls.

### 🔴🔴 THE MINUTES HOST REFUSES OUR OWN USER AGENT, AND THE FETCH LADDER HAS NO SECOND ONE

`columbus-ga.municodemeetings.com` closes the connection on `EmpoweredVoteBot/1.0`. Isolated by
holding everything else constant — same URL, same minute:

| Request | Result |
| --- | --- |
| no user agent | **HTTP 200**, 481,977 bytes |
| `accept` header only | **HTTP 200** |
| browser user agent + `accept` | **HTTP 200** |
| **`EmpoweredVoteBot/1.0`** | 🔴 **connection closed** |
| `EmpoweredVoteBot/1.0` + `accept` | 🔴 **connection closed** |

It is not TLS fingerprinting and not general rate limiting: plain `node fetch` works.
`fetchViaHttp` always sends that user agent and has no fallback — **`LEGACY_BROWSER_UA` is declared
in the same file and never used anywhere.** Tier 2 is Wayback, and these PDFs have no capture, so
the ladder ends. The symptom a researcher sees is `all fetch tiers failed`, then `below-threshold`
on a row whose evidence is perfectly good.

**Part of the cause is ours.** Their `robots.txt` asks for `Crawl-delay: 15`, and this batch pulled
202 PDFs back to back. 🔴 **Our robots parser ignores `Crawl-delay` by design** — a comment in
`verificationFetch.ts` says so. Their robots file **allows** the minutes path, so this is a rate
defence we provoked, not a policy refusal.

▶ **The fix chosen (operator, 2026-10-29) is to archive each cited PDF to the Wayback Machine and
keep citing the official city URL**, so tier 2 serves it and the citation stays durable.

🟢🟢 **AND TIER 2 IS ALREADY DOING THAT FOR WHATEVER HAPPENS TO BE ARCHIVED — the block is not
total, and an earlier version of this section said it was.** Measured against CDX:

| Cited document | Capture | Rows |
| --- | --- | --- |
| 2958, minutes of 2025-10-14 | ✅ 2026-08-08 | `gun-policy` **verifies** for Allen, Garrett, Tucker |
| 2876 / 2877, minutes of 2023-10-10 and 10-24 | ✅ 2025-07-15 | `rent-regulation` **verifies** for Crabb |
| **2950, minutes of 2025-08-12** | 🔴 **none** | `homelessness` fails for all six |

So the live host being closed to us costs nothing where a capture exists. **One document gates half
the slice**: the minutes of 12 August 2025, which carry the camping ordinance vote.

🔴 **AND NEW ARCHIVING IS REFUSED.** Save Page Now returned HTTP 520 repeatedly on `GET /save`, and
the POST form answers **429 with an explicit message** — *"Your request is being blocked because our
system has flagged it as suspected abusive bot traffic that is degrading the performance of the
Wayback Machine."* Anonymous archiving is not available; this needs an Internet Archive account with
S3-style keys, which is an operator decision, not a research one.

⚠ Coverage of this corpus is sparse and unpredictable — of nine sampled meeting documents, four had
captures and five had none, with no pattern by date. ▶ **Where two meetings could evidence the same
act, check CDX and cite the archived one.** That is free and it is the difference between a published
citation and a queued row.

🔴🔴 **AND THE VERIFIER'S RESULT IS NOT STABLE RUN TO RUN, SO DO NOT READ ONE RUN AS A VERDICT.**
Two dry-runs twenty minutes apart over the same unchanged CSVs:

| Run | REVIEW | RE-RESEARCH |
| --- | ---: | ---: |
| first | 4 | 8 |
| second | **1** | **11** |

Nothing in the batch changed. Allen, Garrett and Tucker's `gun-policy` rows verified through the
Wayback capture of meeting 2958 in the first run and failed in the second, because archive.org was
degraded while the second ran — the same outage that is refusing new captures. Only Crabb's
`rent-regulation`, on the two 2023 meetings archived in July 2025, verified both times.

▶ **Do not run `--apply` against this batch until two consecutive dry-runs agree.** A row queued as
`below-threshold` during an archive outage looks exactly like a row with bad sourcing, and it invites
a re-research that cannot fix anything. The committed `publish-report.json` is a snapshot of one run,
not a judgement on the evidence.

The research is unaffected by any of this: it is cut from the local corpus and every snippet was
matched offline with the real `matchSnippet`. Re-run the verifier once archiving is possible; it is
idempotent.

⚠ **AND AN OFFLINE SERVICE RETURNED AN EMPTY LIST, NOT AN ERROR.** A CDX query for the minutes PDF
returned `[]` while archive.org was serving "Internet Archive services are temporarily offline" on
other endpoints. `[]` reads as *no capture exists*. A positive control — the same query for
`example.com` and `whitehouse.gov` — is what established that CDX itself was answering and the empty
result was real. Run that control before believing any "not archived".

### Known defect to work around

🔴 **`David A. Britt II` will fail snippet verification on the suffix bug** (slice 4, repo-wide):
`verify-stance-research.ts` takes the last token of the name as the surname, so it hunts for "II"
and every page printing "Tax Commissioner Britt" reads as `name_not_present`. It fails **silently
into the queue**, not into an error. He needs a source that prints his full name in prose near the
passage.
