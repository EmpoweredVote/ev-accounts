# The wrong-bill citation repair pass — migration 1949

**The defect:** the row's prose names the right Act and the citation points at a different bill.
Found by hand four times in four adjudication passes (migrations 1945, 1947, 1948) and never by a
check. **A citation pass must not move a chair**, and none moved: every value and every ladder
revision here is read off the row and written back unchanged, asserted before the write (GUARD 7)
and after it (post-flight).

**21 serving rows written.** 19 Season 2 context rows updated in place; 2 Season 1-serving rows
carried forward as Season 2 inserts on the *same ladder revision*. 4 voter-facing rows carrying a
wrong citation are deliberately **not** written — section 5 says why for each.

| rows | defect | remedy | mode |
|---:|---|---|---|
| 13 | 2021 MA Climate Act cited as **H.4933** in prose *and* link | link → `/192/S9` | UPDATE |
| 1 | the same, plus a second bad pointer (H.2983) | link → `/192/S9` | UPDATE |
| 2 | prose says H.4933; the only link was H.2983 | `/192/S9` **added** | UPDATE |
| 1 | no Act link at all; the only link was H.2983 | `/192/S9` **added** | UPDATE |
| 2 | Safe Communities Act linked at `/194/H2288` | link → `/193/H2288` | UPDATE |
| 2 | MBTA Communities Act cited as **H.4933** | link → **Chapter 358 of 2020** | INSERT |

Measured result, live, after the write: voter-facing rows citing `/192/H4933` **18 → 2**;
citing `/194/H2288` **2 → 0**; citing `/192/S9` **24 → 41**.

---

## 1. 🔴🔴 A number-consistency detector cannot find this class — measured, not assumed

The obvious cheap detector is "compare the bill number in the prose with the bill number in the
cited URL". It was built and run over the **812 serving, voter-facing rows that cite a
malegislature.gov bill page** (1,248 citations, 726 distinct bill pages):

```
rows citing an MA bill page                812
  prose and URL share no bill number         5
  prose and URL overlap                    630
```

**Five.** None of them is one of the 20 rows this pass repaired. The reason is structural: **when a
row is miscited, the prose and the link carry the same wrong number.** `H.4933` appears in both
halves of all 14 climate rows; `/194/H2288` agrees with a prose sentence that is itself correct
about the 193rd. The two halves agree with each other and both disagree with reality, so any check
that compares them is blind by construction — the same shape as the contradiction check's
"uniformly wrong mapping produces no disagreement".

**The detector has to fetch the cited page and compare its title with the act named in the prose.**
That sweep is section 6.

## 2. The pages, opened (all 26 October 2026)

| path | kind | court | official title |
|---|---|---|---|
| `/Bills/192/S9` | Bill | 192nd | An Act creating a next-generation roadmap for Massachusetts climate policy |
| `/Bills/192/H4933` | **Order** | 192nd | certain matters concerning municipal governance |
| `/Bills/193/H2288` | Bill | 193rd | An Act to protect the civil rights and safety of all Massachusetts residents |
| `/Bills/194/H2288` | Bill | 194th | An Act relative to MBTA communities |
| `/Bills/191/H5250` | Bill | 191st | An Act enabling partnerships for growth |
| `/Bills/194/H2983` | Bill | 194th | An Act concerning investments of the Massachusetts PRIM |

🔑 **H.4933 is not an Act at all — it is an ORDER.** Sponsored by the Joint Committee on
Municipalities and Regional Government, referred to House Rules, accompanied by ~40 municipal
petitions: it is the vehicle by which a batch of petitions is sent to study. Migration 1948
described it as *"An Act relative to certain matters concerning municipal governance"*; the page
says **Order**, and the distinction is the whole point — the corpus was citing a procedural order
as a landmark climate law.

🔑 **The MBTA Communities Act is section 18 of Chapter 358 of the Acts of 2020**, *"An Act enabling
partnerships for growth"* (bill H.5250 of the 191st), approved **14 January 2021**, inserting
section 3A into chapter 40A: an *"MBTA community shall have a zoning ordinance or by-law that
provides for at least 1 district of reasonable size in which multi-family housing is permitted as
of right"*. The Governor's partial veto struck sections 48, 50, 55, 62, 63, 83, 85, 95, 102, 106
and 113 — **section 18 is not among them**, so the requirement is law. This also explains the
corpus's "2021": a 2020 session law signed in January 2021.

## 3. 🔴🔴 H.2983 is a *different and worse* defect, and it is not repaired

Five serving rows describe **"H.2983 (100% Clean Energy by 2045)"** and link to `/Bills/194/H2983`,
the PRIM pension-investment bill. Every other wrong citation in this corpus has been **one court
off** — the same number in a neighbouring General Court *is* the act the prose names, which is what
makes them repairable. This one is not. H.2983 was opened in all five courts:

| court | H.2983 is |
|---|---|
| 190th | An Act regarding Massachusetts drug price relief |
| 191st | An Act establishing transit improvement districts |
| 192nd | An Act extending a property tax exemption to the surviving spouse of blind persons |
| 193rd | An Act relative to the enhanced disposition of surplus motor vehicles |
| 194th | An Act concerning investments of the Massachusetts PRIM |

**None is a clean-energy bill.** There is no correct target, so the citation is **left exactly as it
was** and recorded in each row's own notice. Replacing evidence with a guess is not a citation
pass's job, and *deleting* it would erase the only trace of the defect while the sentence resting on
it stays in the prose. GUARD 5 asserts the pointer survives, so a later edit cannot quietly start
deleting evidence under cover of a citation pass.

⚠ Four of the five rows keep their chair on the Act, which migration 1948 read. **The fifth is the
finding**: see section 5.

## 4. Why the prose is left verbatim, wrong number and all

The notice is **prepended** and the row's existing text kept byte for byte below it, as migrations
1947 and 1948 did. That leaves `H.4933` standing inside the original sentences, which is
deliberate — the published wording is the record of what was published. Each notice says so in as
many words and states the correct bill *before* the stale one is reached.

⚖ This is the one point where the pass departs from migration 1900, which **rewrote** the prose of
the rows it repaired, citing the stale-prose-after-a-fix defect of migration 1730. The difference is
that 1730's rows had no explanation attached: a reader met a corrected citation and an uncorrected
sentence with nothing to reconcile them. Here the correction is read first and names the stale
number explicitly. 1900 also replaced the whole reasoning with a note that *quoted* the old claim —
the same instinct, reached a different way.

## 5. The 4 voter-facing rows left alone

🔑 **The test that decided every one:** a Season 1-serving row can only be repaired by INSERTing a
Season 2 row (Season 1 is closed), and carrying the value across preserves the chair **only if the
Season 2 rung at that value says the same thing**.

| rows | who | why not |
|---:|---|---|
| 2 | Michael J. Moran, Rob Consalvo — climate-change c3 | 🔴 **The climate ladder was rewritten between seasons**, ambition → instrument. S1 c3 is *"invest in clean energy while gradually reducing reliance on fossil fuels"*; S2 c3 is *"Speed up clean energy by cutting permitting red tape and upgrading the grid"*. Carrying the 3 across publishes a different position. Repairing the citation would move the chair. |
| 1 | Adrian C. Madaro — fossil-fuels c2 | The whole row is *"co-sponsored 100% Clean Energy legislation (H.2983)"*. Per section 3 no such bill exists under that number in any court. ⚠ **A voter-facing chair resting entirely on a bill that cannot be found** — a stronger finding than a bad link, and an adjudication. |
| 1 | Dr. Joaquin Arambula — campaign-finance c2 | *"Voted Aye on SB-42 (Fair Elections Act Assembly Appropriations 8/15/24)"*. `202320240SB42` is the **CARE Court Program Act** and the vote is real; the Fair Elections Act is SB 42 of **2025-26** and cannot have been voted on in 2024. **The description is wrong, not the link** — swapping the link would manufacture a false claim. Migration 1945 withdrew 15 rows in exactly this position; this one escaped because it serves from Season 1. |
| 2 | Kevin G. Honan — transportation-priorities, residential-zoning | **Not blocked — written.** Listed here because they were found during this pass, not in the measured scope. See section 7. |

Plus 3 campaign-finance rows already withdrawn to 0 by migration 1945 (Valencia, Petrie-Norris,
Davies). Their links still point at CARE Court; they are not voter-facing and 1945's own notice
names the collision. Nothing to repair.

## 6. The title sweep — PARTIAL, and what it already found

`ma-bill-titles.tsv` holds the document kind, General Court and official title of **388 of the 726**
malegislature.gov bill pages this corpus cites from a serving voter-facing row. **Every published
line returned HTTP 200 and carries a title**; lines from failed fetches are excluded, not patched.
**It is not the whole sweep** — malegislature.gov degraded under the fetching and the remaining 338
pages are owed.

🔴 **A further 92 paths returned 404 during the degraded window and are NOT published and NOT
treated as evidence.** A later spot-check returned **HTTP 500 for `/Bills/192/S9`**, a page verified
as 200 earlier the same day, so the site's failure responses that afternoon say nothing about
whether a bill exists. "This cited page 404s" would be a serious finding and it has not been
established; those paths simply count as unfetched.

Reproduce with `dump-ma-citations.mjs` (run from `backend/`), then `fetch-bill-titles.sh`, then
`compare-bill-titles.mjs`. ⚠ Fetch slowly and in ONE process — see the warning at the end.

Over the 769 citations that have a title, comparing the title's distinctive words against the
citing row's prose:

```
ok                574
NO_OVERLAP        159     prose shares not one content word with the page it cites
CITES_AN_ORDER     36     the cited document is an Order, not a bill
```

⚠ **This is a reading queue at well under 100% precision, not a defect count.** Confirmed false
positives in the first screen: rows repaired by migration 1902 whose prose is a repair notice and
therefore shares no words with bills that really are the member's; and Karen E. Spilka's VOTES Act
row, where the page title *"An Act fostering voter opportunities, trust, equity and security"* **is**
the VOTES Act spelled out and the prose uses the acronym. Only opening the page settles any of them.

### 🔴🔴 It found a sixth cohort immediately: `/Bills/192/S2977`, 18 rows

**18 voter-facing `voting-rights` rows** say the member *"voted for the 2022 VOTES Act"* and cite
`/Bills/192/S2977`, which is:

> **Order S.2977**, 192nd — *"Order relative to authorizing the joint committee on Mental Health,
> Substance Use and Recovery to make an investigation and study of a certain current Senate document
> relative to establishing a model school policy on suicide prevention"*

Same shape as H.4933 exactly: a **study order** cited as a landmark act, 18 rows, invisible to both
gates. And as with H.4933 the corpus already knows the right answer — migration 1900 recorded the
VOTES Act's vehicle as **S.2545 → S.2554 → S.2924, Chapter 92 of the Acts of 2022** (House 126-29,
Senate 37-3), and one row in this very queue cites `/192/S2545` correctly.

🔴 **It is not repaired here, and could not be.** All 18 serve from the closed Season 1 (12 at
chair 1, 6 at chair 2) and **the voting-rights ladder was wholly replaced between seasons** — S1
ranks ballot access (*"automatically register all eligible citizens to vote and allow online
voting"*), S2 ranks voter ID (*"Require no identification to vote, verifying voters by signature or
existing records"*). Different revision, different question. Carrying a chair across would publish a
position on a subject the member was never assessed on. This is the same LADDER_SCOPE block
migration 1900 hit on this very topic. ▶ **Adjudication, not citation repair.**

### 🔴🔴 And two cohorts larger still, both on `immigration` — structurally unrepairable

| rows | cited page | is actually | the prose claims |
|---:|---|---|---|
| **20** | `/192/S2745` | *An Act relative to recovery high schools* | immigrant-advocacy records |
| **14** | `/192/H3256` | *An Act to establish municipal access to utility poles located in municipal rights-of-way* | *"the Work and Family Mobility Act (H.3256, 2022)"* |

All 34 are voter-facing and serve from Season 1 — and **`immigration` has no Season 2 question at
all** (`season_questions` returns 0 rows for it in Season 2). There is no Season 2 row to insert, so
unlike every other cohort here these cannot be repaired forward *by any means* until the topic gets
a Season 2 question. This is the known 1,678-stance orphan topic.

⚖ So the running total of wrong-bill rows found by this pass is **21 repaired, 4 blocked on a
rewritten ladder or a missing target, 18 blocked on the voting-rights ladder, and 34 blocked on a
topic with no open-season question** — and the sweep is only 53% complete.

### Other candidates, fetched but NOT individually re-opened

Flagged by the sweep and consistent with the H.4933 shape. Each still needs its page read before
anything is written — the site was refusing requests by the time these surfaced, so they are
reported as a queue, not as findings:

| row | prose says | cited page actually is |
|---|---|---|
| Jack P. Lewis, local-environment | *"the Environmental Justice bill (H.1677 / S.953)"* | `/194/H1677` An Act to improve contract provisions waiving certain rights |
| Meghan Kilcoyne, immigration | *"the Work and Family Mobility Act (H.3256, 2022)"* | `/192/H3256` An Act to establish municipal access to utility poles located in municipal rights-of-way |
| William F. MacGregor, housing | *"H.1362 (affordable housing development tax credits)"* | `/194/H1362` An Act relative to defining invasive surgical procedures |
| William F. MacGregor, healthcare | *"H.1657 (behavioral health workforce expansion)"* | `/194/H1657` An Act relative to expungement of juvenile and young adult records |
| Lydia M. Edwards, immigration | immigrant advocacy, no bill named | `/192/S2745` An Act relative to recovery high schools |

### ⚠ The sweep script bit me with the defect it was built to find

The long first run appeared to have stalled, so it was "resumed" — **but it was still alive**, and
the resume script reused a *fixed* temp filename it never deleted between iterations. So when a
fetch failed, the extractor read **the previous page's HTML** and recorded that page's title against
the new bill's path, while two processes appended to one output file. **15 rows were labelled with a
confidently wrong title.** It was caught by noticing HTTP `000` sitting beside a populated title
column — the status code was the only thing that disagreed.

🔑 **The failure mode of a title checker is a wrong title, and a wrong title looks exactly like a
finding.** Three rules, all now in the shipped script:
1. PID-scope the temp file and delete it every iteration, so a failed fetch yields an *empty* title
   rather than a borrowed one.
2. **Record the HTTP status beside every extracted value**, and publish only `200` rows. That single
   column is what made the corruption visible and what let the good rows be recovered afterwards —
   a 200 line is trustworthy no matter which process wrote it, because the bug only fires on failure.
3. Never run two copies against one output. "It looks stalled" is not evidence that it stopped;
   check before starting a second.

## 7. What the measured scope got wrong

The scope recorded before this pass was **20 + 2 + 1 rows across three cohorts**. Re-measuring found:

- **The H.4933 cohort is 18 voter-facing, not 20.** The note predicted 20 including "3 chair-3 and
  4 chair-4 rows"; in fact the 4 chair-4 rows were already repaired to S.9 by migration 1899, and
  only 2 of the chair-3 rows cite H.4933.
- **Two of the H.4933 citers are not climate rows at all.** Kevin G. Honan cites it on
  *transportation-priorities* and *residential-zoning* as **the MBTA Communities Act** — a different
  act, a different wrong number, and invisible to anyone looking only at the climate cohort.
- **🔑 Those two turned out to be repairable after all.** Both topics carry the **same
  `topic_revision_id` in Season 1 and Season 2**, so the Season 2 insert lands on the same rung *by
  identity* — not by a `rung_map`'s say-so, which [[project_season1_shadow_gap]] records can lie.
  GUARD 4 asserts the revision identity *and* byte-equality of the rung text before writing.
- **A fifth wrong bill, H.2983, was not in the scope at all** (section 3), on 5 rows.
- **The SB 42 cohort yields no citation repair.** Its one voter-facing row is a misdescription, not
  a miscitation.

⚠ The scope note said "re-measure before writing; do not inherit these numbers". Every number in it
moved.

## 8. Owed after this

Ordered by how many voter-facing rows are waiting on each.

1. 🔴🔴 **The 34 `immigration` rows** citing a recovery-high-schools bill (20) and a utility-pole
   bill (14) — section 6. **Blocked on the topic itself**: `immigration` has no Season 2 question,
   so there is nothing to write forward into. Nothing can be repaired here until that is resolved,
   which makes it an argument for resolving it.
2. 🔴 **The 18 `/192/S2977` VOTES Act rows** (section 6). The correct vehicle is already known from
   migration 1900 (S.2924, Chapter 92 of 2022); blocked on the replaced voting-rights ladder.
3. **The 4 adjudications in section 5** — the climate chair-3 pair, Madaro/fossil-fuels, Arambula.
4. **The H.2983 sentences** on 5 rows: is there a Massachusetts "100% clean energy" bill these
   members actually co-sponsored, and if not, what survives?
5. **Finish the title sweep** — 338 of 726 pages are unfetched (92 of them returned 404 only while
   the site was failing, so they must be re-checked). The 53% already done turned up cohorts of 20,
   18 and 14 rows. Then turn `compare-bill-titles.mjs` into a checked-in reading queue — it is the
   only thing that catches this class.
6. **Other legislatures.** This pass covered Massachusetts only. California's `bill_id` collisions
   (migration 1945) and the Texas reuse across the 85th–89th are the same defect with different
   URL shapes.
