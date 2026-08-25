# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|
| 07 | 2026-08-24 | NC House districts 61-70 (+1 backfill) | 10 | **13** | 0 | `2026-08-24-nc-batch07.csv` | `written-batch07.json` |
| 06 | 2026-08-24 | NC House districts 51-60 | 10 | **18** | 0 | `2026-08-24-nc-batch06.csv` | `written-batch06.json` |
| 05 | 2026-08-24 | NC House districts 41-50 | 10 | **20** | 0 | `2026-08-24-nc-batch05.csv` | `written-batch05.json` |
| 04 | 2026-08-24 | NC House districts 31-40 | 10 | **26** | 0 | `2026-08-24-nc-batch04.csv` | `written-batch04.json` |
| 03 | 2026-08-24 | NC House districts 21-30 (+3 backfills) | 10 | **17** | 0 | `2026-08-24-nc-batch03.csv` | `written-batch03.json` |
| 02 | 2026-08-24 | NC House districts 11-20 | 10 | **10** | 0 | `2026-08-24-nc-batch02.csv` | `written-batch02.json` |
| 01 | 2026-08-24 | NC House districts 1-10 | 10 | **8** | 0 | `2026-08-24-nc-batch01.csv` | `written-batch01.json` |
| pilot | 2026-08-24 | Ager (HD 114) · Mayfield (SD 49) · Kopac (Durham W1) | 3 | **8** | 5 parked, 0 inserted | `2026-08-24-nc-pilot-approved.csv` | `written-pilot.json` |

## Pre-campaign baselines (measured 2026-08-24, before any batch was pushed)

Task 6 compares the end state against these. Measure them again at close-out, not the delta.

| Measure | Baseline |
|---|---|
| `inform.politician_answers` rows, all corpora | 32,887 |
| `inform.politician_context` rows, all corpora | 33,541 |
| Context rows with no matching answer (orphan context) | **654** |
| Answer rows for anyone holding an NC seat | 326 |
| Answer rows for the 202 people in this campaign | 0 |

The orphan-context number is the one that must not grow. A context row without an answer is an
unpublished claim: it renders the moment someone writes an answer for that pair.

## Batch notes — pilot (2026-08-24)

**38 rows researched, 8 pushed.** Every instrument behind the 8 was opened and read on ncleg.gov
before the write; the reasoning was rewritten to name the bill in North Carolina's own style.

Held or dropped, and why — these are the shapes to expect for the other 199 people:

| Shape | Example | Disposition |
|---|---|---|
| Bill misdescribed | `school-vouchers` cited H87 as a voucher bill. H87 is a cell-phone-free education bill; the 114-3 vote was on cell phones. | dropped |
| Names no instrument | Mayfield `immigration` cited a campaign page describing "bipartisan legislation" with no number. | dropped |
| Direction, not magnitude | Mayfield `trans-athletes`: a No vote on a ban rules out chair 4 but cannot separate chair 1 from chair 2. | held |
| Bare roll-call vote | Mayfield `climate-change`: H951 passed the Senate 42-7. A vote 42 of 49 senators cast discriminates no personal chair. | held |
| Two adjacent chairs fit | Mayfield `childcare`: S412 raises subsidy rates but states no eligibility band, so chairs 2 and 3 both fit. | held |
| Aggregated across bills | Mayfield `housing` rested on S495 plus two unverified funding bills. S495 alone is a pure zoning mandate with no money, which reads closer to chair 4. | held |
| Chair is federal in scope | `same-sex-marriage` chair 1 requires recognition by all states and full federal benefits. No state bill can evidence either clause. | held, logged for season 2 |
| Promise, not instrument | All 7 of Kopac's rows rested on a campaign platform page. | held — he seated 0 |

Ager's `housing` survived the same test Mayfield's failed: House Bill 1056 is a **single** instrument
carrying both the deregulation and the $40 million subsidy, so chair 3 is the only chair that fits
both halves. Chair 4 has no room for the money.

**Two ladder defects for the ADR 0004 revision queue**, not workarounds for this campaign:
`medicare/aid` chair 2 reads "lower Medicare age to 55 and expand Medicaid significantly", and
`same-sex-marriage` chairs 1 and 2 are written at federal scope. A state legislator can never
evidence either fully, so those spokes are unreachable by construction for all 170.

## Batch notes — batch 01, NC House districts 1-10 (2026-08-24)

**8 rows across 6 people. Four members seated nothing.** Researched inline, primary sponsorships
first, every cited bill opened and read.

| District | Member | Rows |
|---|---|---|
| 1 | Edward C. Goodwin | 0 — veterans and commemorative bills only |
| 2 | B. Ray Jeffers | redistricting 1 |
| 3 | Steve Tyson | data-centers 2 |
| 4 | Jimmy Dixon | 0 — agriculture bills; a Medicaid rebase is routine funding, not a chair |
| 5 | Bill Ward | **0 — blanked by his own conflict** |
| 6 | Joseph Pike | data-centers 1 |
| 7 | Matthew Winslow | housing 4 |
| 8 | Gloristine Brown | childcare 2 · housing 3 · redistricting 1 |
| 9 | Timothy Reeder, MD | 0 |
| 10 | John R. Bell, IV | housing 3 |

### The Ward conflict, and why it matters

Ward is a **primary sponsor of both** House Bill 1189, which imposes a datacenter permit moratorium
(chair 1), **and** House Bill 638, which instead makes data centers pay for their own dispatchable
power (chair 2). Two adjacent chairs, both his own bills. His `data-centers` spoke is blank.

The same check cleared three others: Tyson is not on House Bill 1189, Pike is not on House Bill 638,
and Ager (pilot) is a cosponsor of 1189 only. **Check every member against every instrument on the
topic before seating, not just the one you found first.**

### Housing 3 versus housing 4 is a real distinction, not a partisan one

Ager, Gloristine Brown and Bell all sit at chair 3; Winslow sits at chair 4. The discriminator is
whether public money is present. Ager's House Bill 1056 pairs deregulation with a $40 million
subsidy; Brown pairs House Bill 404's Housing Trust Fund money with House Bill 626's easier
permitting; Bell's House Bill 1072 is $50 million in below-market loans. Winslow's two bills — House
Bill 765 and House Bill 627 — spend nothing and work purely by removing local rules, which is what
chair 4 says. **Bell is the House Majority Leader and lands on the same chair as two Democrats.**
That is the compass working as designed.

### 🔴 A SHORT TITLE IS NOT EVIDENCE. Five bills in ten members contradicted their own titles

- `Beyond The Choice Act` (H422) — veterans' tuition, not abortion
- `Expedited Removal of Unauthorized Persons` (H96) — amends the trespass statutes; squatters, not immigration
- `Energy Security Act of 2025` (H73) — physical security at electrical substations
- `Save the American Dream Act` (H765) — a local development-regulation omnibus
- `Limit Use of AI Medicaid/Commercial Insurance` (H565) — the text returned an organ-donor tax provision

**Cross-check by sponsor list.** When a bill's text and its title disagree, compare the sponsors on
the text page against the sponsors on the lookup page. If they match, the text is the right bill and
the title is just branding (H765). If it cannot be resolved, leave the spoke blank — H565 would have
been the campaign's only `ai-regulation` row and it is not worth seating on a self-contradicting
source.

### 🔴 Fourth ladder defect: voting-rights is asymmetric

Tyson is primary sponsor of House Bill 66, which shortens early voting by about a week. Chair 2
explicitly names *expanding* early voting periods, but **no chair names reducing them** — the
restrictive chairs are about photo ID, voter-roll maintenance and mail-in voting, none of which the
bill touches. So the ladder will seat members who expand early voting and blank members who restrict
it, on the same axis. That is a coverage bias built into the scale, and it belongs in the ADR 0004
revision queue with the `medicare/aid` and `same-sex-marriage` scope defects.

## Batch notes — batch 02, NC House districts 11-20 (2026-08-24)

**10 rows across 4 people. Six members seated nothing.**

| District | Member | Rows |
|---|---|---|
| 11 | Allison A. Dahle | redistricting 1 · civil-rights 2 · housing 3 |
| 12 | Chris Humphrey | housing 3 |
| 13 | Celeste C. Cairns | 0 |
| 14 | Wyatt Gable | 0 |
| 15 | Phil Shepard | 0 |
| 16 | Carson Smith | 0 |
| 17 | Frank Iler | 0 |
| 18 | Deb Butler | redistricting 1 · civil-rights 2 · abortion 2 · campaign-finance 2 · data-centers 1 |
| 19 | Charles W. Miller | 0 |
| 20 | Ted Davis, Jr. | ai-regulation 3 |

**First `ai-regulation` row in the campaign.** House Bill 375 requires AI-generated political content
to carry disclosure and embedded provenance and makes creators liable for resulting harm, with
criminal penalties and damages to $10,000 — chair 3. It requires no safety testing and bans no
category of use, which excludes chair 4. Remember this ladder runs the opposite way from most:
chair 1 is the *least* oversight.

### 🔴 CORRECTION to batch 01's "a short title is not evidence"

The batch 01 note listed five bills as contradicting their titles. That is too strong for two of
them, and the real situation is worse in a different way:

- **H422 and H96 are settled.** Both were judged from BillLookUp *metadata* — the statute chapters
  and keywords — which is independent of the title. `Beyond The Choice Act` amends Chapter 116
  (colleges and universities); `Expedited Removal of Unauthorized Persons` amends Chapter 14
  (trespass). Those conclusions stand.
- **H765 is settled.** The sponsors on the text page matched the lookup page, and the content matches
  the title's evident purpose. `Save the American Dream Act` genuinely is a development-deregulation
  omnibus.
- **H565 and H727 are UNRESOLVED, and both are blank because of it.** The member list and the lookup
  page agree that H565 is `Limit Use of AI Medicaid/Commercial Insurance` (keyword ARTIFICIAL
  INTELLIGENCE, amending Chapters 108C, 58 and 90) and that H727 is `Limit Medicaid Reimb. for
  Facility Fees`. But **editions 1 and 2 of both, served from `/Sessions/2025/Bills/House/HTML/`,
  are different subjects entirely** — organ-donor tax enrolment and marriage-and-family-therapist
  licensure — with the correct sponsors attached. A gut-and-replace would explain it, but the later
  edition still shows the old subject, so that theory does not hold either.

**The rule: when the served text and the title disagree and cannot be reconciled, leave the spoke
blank.** H565 would have seated `ai-regulation` for Reeder (district 9), Shepard (district 15),
Potts and Huneycutt. It is worth resolving properly — by reading the PDF rather than the HTML — but
not worth guessing.

### Refusals worth recording

- **House Bill 282** (Butler, primary) changes bike and pedestrian funding from "shall not provide"
  to "may provide". Someone who wants to *prioritise* walking and transit (chair 1) and someone who
  wants it *selectively* (chair 3) would both file it. Two chairs fit, so it seats nothing.
- **House Bill 318** (Carson Smith, primary) creates a judicial hold process for ICE detainers with a
  48-hour cap. It does not decide *who* is deported, which is what the `deportation` ladder asks.
- **House Bill 799** (Gable, primary) bars state funds for DEI programs, but by its own terms does not
  reach voluntary initiatives or admissions. Chair 5 requires eliminating affirmative action **and
  all** race-based government programs; chair 4 is about limiting *federal* enforcement. Neither is
  named.

### 🔴 Fifth ladder observation: `civil-rights` is asymmetric the same way `voting-rights` is

Chair 2 is reachable by a state bill — Equality for All seats it cleanly, twice in this batch. But
chair 4 is written about **federal** enforcement, which no state legislator can do, and chair 5
demands **all** race-based programs be eliminated, which a partial DEI funding ban does not achieve.
So the restrictive half of this axis is close to unreachable for the people we are scoring, exactly
like early voting on `voting-rights`. Both belong in the ADR 0004 queue as coverage bias.

## Batch notes — batch 03, NC House districts 21-30 (2026-08-24)

**17 rows: 14 for districts 21-30, plus 3 backfills into earlier batches.** Four members seated nothing.

| District | Member | Rows |
|---|---|---|
| 21 | Ya Liu | abortion 2 · redistricting 1 |
| 22 | William D. Brisson | 0 — one primary bill in the session, on corn farming |
| 23 | Shelly Willingham | housing 3 |
| 24 | Dante Pittman | 0 |
| 25 | Allen Chesser | housing 3 |
| 26 | Donna McDowell White | 0 |
| 27 | Rodney D. Pierce | abortion 2 · redistricting 1 · **taxes 1** |
| 28 | Larry C. Strickland | 0 — budget bills only |
| 29 | Vernetta Alston | abortion 2 · redistricting 1 · housing 3 |
| 30 | Marcia Morey | abortion 2 · redistricting 1 · data-centers 1 · campaign-finance 2 |

### 🔴 BACKFILL: fetching a bill's full sponsor list found rows the person-first pass missed

House Bill 509's cosponsor list contains **G. Brown (batch 01)** and **Dahle (batch 02)**, and House
Bill 375's contains **Pike (batch 01)**. All three were missed because those batches were worked
member-by-member without pulling each instrument's complete sponsor list.

**Pull the full sponsor list for every chair-shaped bill, once, and check it against every batch —
including batches already pushed.** The bills that carry most of the coverage so far are H20, H509,
H1189, H1229, H1056, H538, H1072, H1118 and H375.

### The first `taxes` row, and why it is chair 1 and not chair 2

`CLAUDE.md` uses this exact ladder as its warning: a bill establishing direction cannot separate
*significantly raise* (1) from *moderately raise* (2). House Bill 1073 escapes that because it states
a **rate and a destination** — a 7% bracket on income above $1 million, paid into the State Public
School Fund. On top of North Carolina's existing flat rate that more than doubles the tax above the
threshold, which no ordinary reading calls moderate, and the money adds to existing school funding.
Chair 2 does not fit; chair 1 does.

### Conflicts and refusals

- **House Bill 934, the AI Regulatory Reform Act, pins nothing by itself.** Section 1 creates criminal
  and civil liability for deepfakes while Section 2 grants AI developers immunity — "the developer of
  the artificial intelligence product is not liable for any errors". One bill pointing at opposite
  ends of the ladder. Alston is a primary sponsor, so her `ai-regulation` spoke is blank.
  ⚠ **Clark, G. Pierce and Ward are on BOTH H934 and H375** — conflicted, blank them when their
  batches come up. Davis (batch 02) was checked and is on H375 only, so his row stands.
- **House Bill 951** funds childcare for state employees and first responders. That is targeted by
  *occupation*, not by income, and no chair on the childcare ladder names an employer-provided
  facility. Blank for Liu.
- **House Bill 46** constrains future health-benefit mandates procedurally without saying who gets
  covered; every healthcare chair is about coverage. Blank for Chesser.
- **`medicare/aid` is blanked for White**, consistent with Ager and Reeder. She is primary sponsor on
  several Medicaid rate and coverage improvements, but chair 3 reads "improve current programs
  **while controlling costs**" and the cost-control clause is never evidenced. Note that the WI
  Madison wave resolved this differently — it seated state-leg Medicaid expanders at chair 3 on the
  reasoning that chair 2's Medicare clause is unreachable. **This campaign is stricter.** If that is
  the wrong call, the fix is a ladder revision, not a per-row exception, and White, Ager and Reeder
  should all be revisited together.

### 🔴 Editions, resolved: the member list shows the CURRENT title, edition 1 shows the ORIGINAL text

House Bill 437 makes this plain. The member list titles it `Drug-Free Zones/Unauthorized Public
Camping`, but editions 1 **and** 2 are titled "Establish Drug-Free Homeless Service Zones" and contain
no camping provisions at all. So a later edition added them, and **reading edition 1 can understate a
bill**. The same shape explains H565 and H727. Where the later editions still do not show the current
subject, the bill stays unresolved and the spoke stays blank — that is now three bills
(H437, H565, H727) parked for a PDF read rather than guessed.

## Batch notes — batch 04, NC House districts 31-40 (2026-08-24)

**26 rows, and for the first time every member in the batch seated something.** Three times the
previous best, on **four** new source reads instead of twenty-five, because the batch was worked
bill-first: pull each chair-shaped bill's full sponsor list once, then read it across the roster.

| District | Member | Rows |
|---|---|---|
| 31 | Zack Hawkins | redistricting 1 · abortion 2 · campaign-finance 2 · housing 3 |
| 32 | Bryan Cohn | redistricting 1 · housing 3 |
| 33 | Monika Johnson-Hostler | abortion 2 · housing 3 |
| 34 | Tim Longest | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 |
| 35 | Mike Schietzelt | ai-regulation 3 · housing 3 |
| 36 | Julie von Haefen | redistricting 1 · abortion 2 · housing 3 |
| 37 | Erin Paré | **childcare 4** |
| 38 | Abe Jones | redistricting 1 |
| 39 | James Roberson | redistricting 1 · abortion 2 · housing 3 · data-centers 1 |
| 40 | Phil Rubin | redistricting 1 · abortion 2 · housing 3 |

### 🔴 CORRECTION APPLIED IN PROD: Alston was described as a primary sponsor and is not

House Bill 1056's primary sponsor is **Dahle alone**; Alston is a cosponsor. The batch 03 row said
"Alston is a primary sponsor", which is wrong in text a voter reads. The chair is unaffected —
cosponsorship supports chair 3 the same way it does for Ager — so the fix was the sentence, not the
value. Updated in place.

**Root cause:** a member's `IntroducedBills` page was read as though every bill listed were primarily
sponsored. It is not. **Confirm primary sponsorship against the BILL's sponsor list, never against
the member's bill list.** Every other committed row claiming primary sponsorship was audited against
its bill's sponsor list and is correct.

This also means a reasoning-only correction cannot go through `push-nc-stances.mjs`: the value is
unchanged, so the row lands in the `unchanged` bucket and is skipped. It needs a targeted UPDATE.

### `childcare` finally has a chair on the other side

House Bill 412 lowers the lead-teacher requirement to one per two groups, widens who qualifies as a
lead teacher, allows larger toddler groups, deems school buildings compliant for after-school care,
and makes star ratings voluntary so reimbursement no longer depends on them — while leaving subsidy
rates alone. That is chair 4's first clause exactly. Chair 3 needs provider training and facility
grants (absent) and chair 5 needs subsidies gone (contradicted), so chair 4 uniquely fits. Set
against G. Brown's chair 2 on House Bill 316, the axis now has real spread.

### Hawkins is blank on `ai-regulation`, and it took three bills to see why

He is a primary sponsor of House Bill 934 (developer immunity), House Bill 1161 "Omnibus Artificial
Intelligence Protections" **and** House Bill 1177 "Consumer Protection AI Bill of Rights". That is
chair disagreement inside one member's own record. Rubin is blank for a different reason: he is a
cosponsor of House Bill 934 only, and that bill pins nothing by itself.

⚠ **House Bill 1161 and House Bill 1177 are unread.** They may seat `ai-regulation` for members who
are not on House Bill 934. Worth pulling both sponsor lists before the next AI-heavy batch.

## Batch notes — batch 05, NC House districts 41-50 (2026-08-24)

**20 rows across 9 of 10 members, on three new source reads.** The bill index carried the rest.

| District | Member | Rows |
|---|---|---|
| 41 | Maria Cervania | redistricting 1 · housing 3 · data-centers 1 · campaign-finance 2 |
| 42 | Mike Colvin | redistricting 1 |
| 43 | Diane Wheatley | 0 |
| 44 | Charles Smith | housing 3 |
| 45 | Frances Jackson, PhD | redistricting 1 · housing 3 · ai-regulation 3 |
| 46 | Brenden H. Jones | **civil-rights 5** |
| 47 | John L. Lowery | **civil-rights 5** · ai-regulation 3 |
| 48 | Garland E. Pierce | childcare 2 |
| 49 | Cynthia Ball | redistricting 1 · abortion 2 · housing 3 |
| 50 | Renée A. Price | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 |

### 🔴 CORRECTION to batch 02's fifth ladder observation

Batch 02 recorded that `civil-rights` chairs 4 and 5 were "close to unreachable" for a state
legislator, on the strength of House Bill 799 seating nothing. **That was overstated.**

House Bill 171 seats **chair 5** cleanly. It bars DEI programs *and* race-based consideration in
hiring, contracting and admissions, across state agencies, local government, the UNC system,
community colleges and any body receiving public funds — carving out only federal civil rights
compliance, instruction, research and student organisations. Chair 5 reads "eliminate affirmative
action **and all** race-based government programs" and both clauses are evidenced.

So the restrictive side of this axis **is** reachable; it needs a comprehensive bill. H799 simply is
not one. **Chair 4 remains unreachable**, because it is about limiting *federal* enforcement, which
no state legislator can do — but that is one chair, not half a ladder.

The `voting-rights` asymmetry from batch 01 still stands and was not affected by this: no chair on
that ladder names reducing early voting.

**The general lesson: do not call a chair unreachable after one bill fails to reach it.** Two bills
of the same apparent kind can sit on opposite sides of the bar, and the difference is scope, which
only shows up on a read.

### Refusals

- **House Bill 456** (Colvin) regulates surprise ambulance billing. The healthcare ladder is about
  coverage architecture, so billing regulation seats nothing — same call as House Bill 434.
- **House Bill 453** (Wheatley, White) raises Medicaid personal care and private duty nursing rates.
  Still no evidence for chair 3's "while controlling costs" clause, so `medicare/aid` stays blank —
  consistent with Ager, Reeder and White.
- **House Bill 951** (Colvin) funds childcare for state employees and first responders: targeted by
  occupation, not income, and no chair names an employer-provided facility.

## Batch notes — batch 06, NC House districts 51-60 (2026-08-24)

**18 rows across 8 of 10, on three source reads.**

| District | Member | Rows |
|---|---|---|
| 51 | John Sauls | 0 — four primary bills, none touching the 28 topics |
| 52 | Ben T. Moss, Jr. | data-centers 2 |
| 53 | Howard Penny, Jr. | 0 |
| 54 | Robert T. Reives, II | redistricting 1 · abortion 2 · housing 3 |
| 55 | Mark Brody | housing 4 |
| 56 | Allen Buansi | redistricting 1 · abortion 2 · housing 3 · ai-regulation 3 · taxes 1 |
| 57 | Tracy Clark | redistricting 1 · abortion 2 · housing 3 |
| 58 | Amos L. Quick, III | redistricting 1 · housing 3 · data-centers 1 |
| 59 | Jerry "Alan" Branson | ai-regulation 3 |
| 60 | Amanda P. Cook | campaign-finance 2 |

**Clark is blank on `ai-regulation` by the conflict rule** — he is on House Bill 375 and House Bill
934. The index caught it without a fetch, which is exactly what it is for.

**Brody's housing 4 needed a negative check, not a positive one.** House Bill 765 is chair 4 only if
the member has no housing appropriation anywhere; his record is building-code and inspection
deregulation throughout, so the chair holds. Same test that separated Winslow (chair 4) from Ager,
Dahle and Bell (chair 3).

## Batch notes — batch 07, NC House districts 61-70 (2026-08-24)

**13 rows across 7 people, one of them a backfill.** Five members seated nothing.

| District | Member | Rows |
|---|---|---|
| 61 | Pricey Harrison | redistricting 1 · abortion 2 · data-centers 1 · campaign-finance 2 · civil-rights 2 · ai-regulation 3 |
| 62 | John M. Blust | ai-regulation 3 |
| 63-65, 68 | Ross, Riddell, Pyrtle, Willis | 0 |
| 66 | Sarah Crawford | redistricting 1 · housing 3 |
| 67 | Cody Huneycutt | ai-regulation 3 |
| 69 | Dean Arp | childcare 4 |
| 70 | Brian Biggs | **homelessness 4** |
| 35 | Mike Schietzelt (backfill) | **homelessness 4** |

Harrison is the campaign's widest single record so far at six rows, all from bills she primarily
sponsored or cosponsored.

### `homelessness` opens, and the chair turns on the enforcement mechanism

House Bill 781 bars local governments from authorising camping or sleeping on public property. A
council may set aside its own land for up to a year, but only after documenting that shelter beds are
insufficient.

- **Chair 5 is excluded** because enforcement is **civil, not criminal** — residents, business owners
  or the Attorney General sue for an injunction. Chair 5 requires criminal penalties.
- **Chair 3 is excluded** because it conditions *enforcement* on beds being available. This bill does
  the reverse: it conditions *permission to allow camping* on beds being insufficient, and provides no
  citation-to-services diversion.
- **Chair 4 fits**: prohibiting encampments on public property, without criminal penalties.

### Refusals

- **House Bill 301** (Willis) is titled `Social Media & AI Safety` on the member list but is
  "Social Media Protections for Minors Under 16" in the text — age verification and account limits
  for under-16s, with nothing about how algorithms work or any AI duty. Blank.
- **House Bill 31** (Ross, Biggs) makes Election Day a state holiday. No chair on the voting-rights
  ladder names a holiday.

### Edition theory confirmed again

Biggs's member list gives House Bill 87's current short title as **"Educational Choice for Children
Act (ECCA)"**, while the edition-1 text read during the pilot was a cell-phone-free education bill.
That is the same pattern as House Bill 437: **the member list shows the current title, edition 1 shows
the original text.** It also means the pilot's dropped `school-vouchers` row was dropped for the right
reason — the vote cited was on the cell-phone text — but H87 in its current form may well be a voucher
bill, and is worth a PDF read alongside H565, H727 and H437.
