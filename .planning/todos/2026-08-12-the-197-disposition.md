# The 197 — disposition record (2026-08-12)

Entry point: `[[project_national_generic_sourcing]]`. Source cut:
`backend/data/stance-retirement/2026-08-11-tier-b-coverage.json`, filtered
`verdict=HAS_POSITIONS_SECTION AND coverage=TOPIC_ABSENT`.

## 🔑 First correction: it is 196 rows, not 197

197 is a count of **row-citations**, not rows. One pair (Kelly A. Dooner / Campaign Finance)
appears twice because that row carries **two** encyclopaedia sources and the Tier-B query emits one
record per source. Distinct `(politician_id, topic_id)` pairs: **196**.

## 🔑 Second correction: 96 of the 196 were ALREADY in the Tier A queue

| | rows |
|---|---|
| also in `2026-08-11-tier-a-generic-member-pages.json` | **96** (MD 78 · MA 18) |
| of those, naming an instrument | 12 |
| genuinely new to this cut | **100** |

Their sources are a legislature member page **and** an encyclopaedia article, so they satisfy both
tier definitions. ⚠ **Tier A's 1,641 and Tier B's 2,031 overlap and must never be added together.**
The upside: those 96 now carry two independent negatives, not one.

## 🔴 Third correction: the TOPIC_ABSENT test has real false positives

The coverage cut keys on a **topic lexicon**. A row can rest on a passage that never uses the
topic's vocabulary. `scripts/the-197-claim-on-page.mjs` re-tests each page against the **row's own
words** — quoted phrases, bill designators, multiword proper nouns — and found the cited page is
**not silent** on 81 of 196.

Most of those 81 are noise (a bio page contains "Montgomery County"), but these are genuine, and the
row is **disqualified from absent-topic retirement**:

| row | phrase verified present in the cited page |
|---|---|
| Casey Shepard / Reproductive Rights | "bodily autonomy" — the row's whole claim |
| Anna Paulina Luna / Transgender Athletes | "radical left-wing gender theory" |
| Patrick Morrisey / Data Centers | "50 by 50" |
| Mikel Wein / Ukraine | "halt military support for other countries" |
| Briscoe Cain / Transgender Athletes | "bathroom bill" |
| Gina Hinojosa / Reproductive Rights | "Healthy Texas Act of 2019" |
| Mark DeSaulnier / AI Oversight | **"H.R. 2860"** — the Bots Research Act is on his own article |
| Frank J. Mrvan / Ukraine | "H.Con.Res. 21" |

🔑 **Same failure mode as `probe-topic-evidence.mjs`**, which scored passages on topic-lexicon hits
so the sentence ten rows actually rested on scored 0 and never appeared in its own output.
**Absence of the topic word is a SORT. Absence of the CLAIM is the verdict.**

⚠ Two matches in that run were my regex misfiring, not evidence: Todd Rokita "instrument: s 4" came
from "4% LCV rating", and Roger Wicker "quoted: Americans" is a stopword. Read the hits.

## ✅ DONE — migration 1710, applied and pushed-pending

12 rows re-sourced to recorded federal roll calls + 1 chair correction. See the commit for the
verifier's four self-inflicted failures (roll number from memory, bill-number-only match, multiple
passage votes per bill, Clerk surname disambiguation). Production verified to match the file
byte for byte; context 33,092 / answers 32,551 unchanged, orphans 0.

## ▶ REMAINING — 183 rows

### A. Maryland instrument claims (~10 rows) — corpus says most are WRONG
Corpus: `%TEMP%/ev-stance-cache/mdcorpus/md-bill-corpus.json`.
⚠ **It carries a degraded duplicate of every bill** (`title:"2", sponsor:"2"`); filter
`title.length > 5` → 36,616 usable of 73,232.
🔴 **2012RS has ZERO usable bills.** An empty 2012 result is a corpus gap, NOT a negative — this is
what blocks the two Justin Ready rows.

| row | claim | corpus verdict |
|---|---|---|
| Hettleman / Civil Rights | sponsored SB0847 (2025) antihate/antidiscrimination | ✅ **TRUE**, sponsor "Senator Hettleman" |
| Feldman / Civil Rights | sponsored SB0293 (2025) County Board Antibias Training Act | ✅ **TRUE**, sponsor "Senator Feldman" |
| Guzzone / Reproductive Rights | sponsored SB0848 (2025) Public Health Abortion Grant Program | ✅ **TRUE**, sponsor "Senator Guzzone" |
| Feldman / Civil Rights + Same-Sex Marriage | voted for SB0119 (2024) gender-affirming care | bill is real (sponsor Lam); **the VOTE is unverified** — needs the MD roll call |
| Cardin / Reproductive Rights | co-sponsored "HB 1171, Pregnant Person's Freedom Act of 2024" | 🔴 **WRONG.** 2024 HB1171 is *Nonprescription Drugs and Devices…* (Delegate Williams). The Pregnant Person's Freedom Act is **2022 SB0669 / HB0626**. There is no 2024 version. |
| Sara Love / Medicare-Medicaid | "voted YES on SB 539 (2023) expanding Medicaid" | 🔴 **WRONG.** 2023 SB0539 is *Economic Development – Tri-County Council for Southern Maryland – Membership*. Nothing to do with Medicaid. |
| Sara Love / Reproductive Rights | "voted YES on SB 798 (2023 Abortion Care Access Act)" | ⚠ **half wrong.** 2023 SB0798 is *Declaration of Rights – Right to Reproductive Freedom*, a real on-topic bill. The **Abortion Care Access Act is 2022 SB0890/HB0937**. Bill right, act name wrong. |
| A. Washington, Sara Love, Waldstreicher / Childcare | "supported the Blueprint for Maryland's Future" | Blueprint = 2019 SB1030/HB1413 + 2020 SB1000/HB1300. All three were in office. Needs the roll call. |

🔴 **TWO SURNAME COLLISIONS FOUND IN THE CORPUS — the sponsor string is a surname, not an identity.**
- **"Senator Washington, M." is Mary Washington, not Alonzo T. Washington.** The 2023 childcare
  bills SB0873/SB0881 are hers. Alonzo's own childcare bill is **2026RS SB0672**, *Prince George's
  County – Expanding Access to Early Childhood Education and Child Care* ("Washington, A.").
- **"Delegate Love" is two people**: 2013–2014 (Mary Ann Love) and 2019–2024 (Sara Love).

🔑 **AND A PRE-TENURE VERDICT I ALMOST GOT WRONG.** I was about to record Sara Love's Blueprint claim
as pre-tenure on the assumption she took office in 2023. The corpus shows "Delegate Love" sponsoring
6–16 bills every session **2019RS through 2024RS**, then "Senator Love" in 2025–26 — she has been in
office since **2019**, so the 2020 Blueprint is **in tenure and not retirable on tenure grounds**.
⚠ Her current mgaleg page (`love02`) shows only 2024–2025 and would have "confirmed" the wrong
answer — the pass-6b trap exactly: **a member's current mgaleg page hides prior-chamber service.**

### ✅ B. DONE — migration 1711. 3 re-sourced, 9 retired, 5 left alone

🔑 **This looked like the cleanest retirement class in the set, because the author had already
searched and reported the absence. Searching independently moved 3 of 14 OUT of it.** Retirement is
what is left after looking, not the first move.

⚠ **My hand-count of "~12" was wrong** — the detector found **19 rows** carrying an absence phrase,
17 of them naming no instrument. Detector: `scripts/the-197-class-b.mjs`.

🔑 **THE TEST IS NOT THE PHRASE, IT IS WHAT THE PHRASE DOES.** "No evidence" appears in two opposite
kinds of row:
- **NARROWING and legitimate** — Paxton / Medicare says "no evidence he seeks to phase out Medicare
  and Medicaid entirely (value 5), so the value is set to 4", on a row carried by *California v.
  Texas*, which IS cited. McClain / Same-Sex Marriage does the same on a row carried by a recorded
  NAY. **These are the opposite of the defect.**
- **LOAD-BEARING and the defect** — Wicker / Campaign Finance: "No bill sponsorships or floor
  statements on tightening campaign finance were found", then a chair anyway.

**✅ RE-SOURCED (3) — the search found what the row said did not exist**
| row | evidence |
|---|---|
| Hyde-Smith / Campaign Finance | NAY on cloture, **S.4822 DISCLOSE Act**, 117-2 roll 346, 49-49, 2022-09-22; NAY on cloture, S.2747 Freedom to Vote, 117-1 roll 420. The row had said her record *"suggests opposition to DISCLOSE Act"* — she voted against it. |
| Wicker / Campaign Finance | the same two NAYs |
| Hyde-Smith / Redistricting | NAY on cloture S.2093 (For the People Act) 117-1 roll 246; NAY on discharging S.1, roll 358. Both mandate independent commissions. ⚠ Omnibus — the reasoning says so rather than over-claiming a 4-vs-5 distinction the votes cannot make. |
🔑 Found via the **Senate's own vote menu** (`vote_menu_<congress>_<session>.htm`) — searching for
"DISCLOSE" fails, because the menu prints the **formal title**: *"A bill to amend the Federal
Election Campaign Act of 1971…"*. Search the formal title, not the popular name.

**🔴 RETIRED (9)** — chair rests on a party/caucus/district prior plus a declared absence, and an
independent search of the member's own record found nothing on topic:
Schweikert / Tariffs · Tran / School Vouchers · Tran / Data Centers · Tran / AI ·
Slotkin / AI · Dooner / Religious Freedom · Dooner / Campaign Finance · Dooner / Same-Sex Marriage ·
Dooner / Reproductive Rights.
Nobody emptied: Schweikert 17→16, Tran 29→26, Slotkin 24→23, Dooner 22→18. Corpus 33,092→33,083.
- **Schweikert** is the worst of them: chair **1**, *"eliminate all tariffs and pursue completely
  free trade"* — the most absolute position on the scale — inferred from an absence.
- **Dooner**: her complete 194th General Court record (**49 sponsored + 40 cosponsored**) contains
  nothing on religion, marriage, abortion, or campaign finance. Her one election bill is about
  vote-by-mail administration, which says nothing about donations or spending.

**⚠ LEFT ALONE (5), and why**
- **Carrie Isaac / Civil Rights** — 🔴 **"critical race theory" IS on her cited page, in prose**
  ("Isaac is a supporter of charter schools and opposes uncensored education, labeling it as critical
  race theory"). The lexicon missed it because **"race" is not "racial"** — a *near-miss stem*, a
  second false-positive vector distinct from the Casey Shepard different-vocabulary one.
- **Gimenez / Reproductive Rights** — its affirmative claim cites **ISideWith**, which is not in the
  sources array and not on the cited page. A **citation gap needing re-sourcing**, not an absent stance.
- **Paxton / Medicare** and **McClain / Same-Sex Marriage** — narrowing, as above.
- **Joyce / Medicare** — real votes exist (IRA **Nay** 2022 roll 420; OBBBA **Aye** 2025 rolls 145/190)
  but they are omnibus votes that pin no chair and, if anything, cut *against* the stored chair 3.
  A partial sample is not a search. ▶ Needs a proper record search.
- **Ron Reynolds / Climate** — 🔴 `capitol.texas.gov` **now redirects every BillSearchResults query to
  its search form** (140-byte "Object moved"), so his bill record could not be read at all.
  **UNASSESSED IS NOT VERIFIED-ABSENT.** ▶ Needs a working TX route.

⚠ Also found: **two `David Schweikert` politician rows** — `17e59190…` (incumbent, 17 answers) and
`0f95f4c1…` (0 answers, 0 context). The empty one is a harmless shell but belongs in
[[project_dedup_name_collisions]].

<details><summary>original class B sketch (superseded)</summary>

### B. The self-declared-no-evidence class (~12 rows) — the cleanest retirement candidates
Rows whose own reasoning states that nothing was found, cited to a bio that never mentions the topic:
Hyde-Smith/Campaign Finance ("No specific co-sponsorship … found"), Hyde-Smith/Redistricting,
Schweikert/Tariffs, Derek Tran/Data Centers ("No direct statement … was found"),
Tran/School Vouchers, Slotkin/AI, Moulton/AI ("No strong documented public position"),
Dooner/Campaign Finance, Dooner/Religious Freedom, Dooner/Same-Sex Marriage,
Torres/AI, Wicker/Campaign Finance ("No bill sponsorships or floor statements … were found"),
Ron Reynolds/Climate ("No direct climate bill evidence found but stance inferred").

🔑 **These are the strongest candidates in the whole set because the author already did the search
and reported the absence.** The stance is a party prior wearing a citation.
⚠ Still not automatic: **1678 retired 82 of 1,055 on this same test.** And the narrowing use of
"no evidence" is legitimate — McClain/Same-Sex Marriage says "no evidence … of advocating to make
same-sex marriage illegal" to choose between chairs 4 and 5, on a row backed by a real vote. Match
on *the row's only claim being an absence*, never on the phrase.
</details>

### C. The Maryland template class (~20 rows) — one sentence, filled in per legislator
"X co-sponsored civil rights legislation including anti-discrimination protections — strong
supporter of civil rights expansion in <County>." Pruski, Crosby, Dana Jones, Dana Stein, Terrasa,
Feldmark, N. Scott Phillips, Pam Guzzone, Beidle, Malcolm Augustine, Edith Patterson, Debra Davis,
Mark Chang, Dalya Attar, Nancy King, Mary-Dulany James, Cory McCray …
A template claim over a generic source. **Each names no instrument, so no tool moves them** — this
is the human reading queue. The corpus can test them: search each sponsor's own bill list for an
anti-discrimination bill before retiring.

### D. Verified-but-not-acted (2 rows, deliberately left)
- **Risch / Civil Rights** cites the First Step Act vote (confirmed NAY, 87-12) for a *civil rights*
  chair. On topic by **vocabulary, not by rationale** — a criminal-justice vote is not a civil-rights
  position. Left for a reader.
- **Grassley / Jail Capacity**: his Yea sits inside 87-12 and is not distinctive. His real claim is
  sponsorship of **S.3649**, which this pass did not verify.

### E. Not found / needs another route
- **Mike Ezell / Civil Rights** — "sponsored House Resolution 106 … passed the House in the 118th".
  The Clerk's 2023 index has **no roll call on H.RES.106**, consistent with a voice vote. Sponsorship
  is unverified; congress.gov 403s even with a browser UA, so this needs GovTrack.
- **Justin Ready** × 2 (MD Dream Act 2012, Civil Marriage Protection Act 2012) — blocked on the
  2012RS corpus gap; mgaleg `2012RS/billfile/` returns only ~6KB and needs a different reader.
- **Markey / Data Centers** cites an "**AI TRANSPARENCY Act**". ⚠ Not yet verified to exist — treat as
  a possible invented-instrument until checked (`[[project_invented_publications]]`).

## Tooling written this pass (all committed)
| script | does |
|---|---|
| `the-197-dump.mjs` | pulls the full DB record for the cut |
| `the-197-claim-on-page.mjs` | the guard above — page vs the ROW'S OWN WORDS |
| `fed-rollcall-verify.mjs` | House Clerk + Senate roll calls, index-resolved, self-checked |
| `verify-citation-urls.mjs` | fetches every URL a migration will write and checks it names its own bill |
| `verify-1710-applied.mjs` | parses the migration and proves production matches it exactly |

💾 Caches: `%TEMP%/ev-stance-cache/` — `tierb-cache/` 618 articles, `mdcorpus/`, and new
`fed-vote-cache/` (Clerk year indexes + roll-call XML). **Do not re-fetch.**
