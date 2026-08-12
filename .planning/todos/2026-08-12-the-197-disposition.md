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
