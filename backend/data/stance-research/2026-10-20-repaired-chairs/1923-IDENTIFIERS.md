# The identifier pass — migration 1923

**2026-10-21.** Migration 1922 closed the three rows seated on inadmissible evidence and recorded
that six more failed the chair-evidence gate for a different reason: each *appeared* to name a real
act or vote in a form the lexical pattern cannot match. 1922 said the remedy was **"an identifier,
not a blank"**.

Third in the sequence: [`LEDGER.md`](LEDGER.md) (the 40-row read) → [`1922-REMEDY.md`](1922-REMEDY.md).

---

## ⚖⚖ The finding that matters more than the six rows

> **1922's note was right for four of the six and wrong for two — and only the source could say which.**

"The gate is lexically blind here" is a claim about the **pattern**. "The row names a real
instrument" is a claim about the **world**. 1922 asserted the second from the first, for all six at
once, **without opening a single page**. Opening them found that two name no instrument at all: one
rests on a union's internal staffing decision, and the other **asserts a vote that the roll call
shows went the other way**.

🔴 **A gate's false negative is not a licence to assume the row is sound.** The gate said nothing
about these rows except that it could not read them.

## The result

| | before 1923 | after 1923 |
|---|---:|---:|
| chair-setting rows live from this queue | 8 | **6** |
| …naming an identifier the gate can see | 1 | **5** |
| rows blanked as unsupportable | — | **+2** |

The one row still failing is **Harris-Dawson / redistricting**, which is `own-words` at local level
and therefore **correctly** names no instrument. The gate is blind there by design, not by defect.

Across the whole remedy: **0 of 10 → 5 of 6.**

---

## 🔴 R36 Deeds / same-sex-marriage — BLANKED. The row asserted a vote that went the other way

Migration 1921 re-seated him 3 → 2 on *"his recorded 2006 vote **against** the Virginia
constitutional amendment banning same-sex marriage."* Read at Virginia's own Legislative Information
System, **every recorded vote he cast on that amendment was for it**:

| resolution | date | result | Deeds |
|---|---|---|---|
| HJ 586 (2005, first reference) | 18 Feb 2005 | agreed to 27–10 | **YEA** |
| HJ 586 conference committee report | 26 Feb 2005 | 30–10 | **YEA** |
| **HJ 41 (2006, second resolution)** | **17 Feb 2006** | **agreed to by Senate 29–11** | **YEA** |

> YEAS—Bell, Blevins, Chichester, Colgan, Cuccinelli, **Deeds**, Devolites Davis, … —29.

HJ 41 became **Chapter 944** and placed the ban on the November 2006 ballot.

⚠ **Where the wrong claim came from, because the shape matters more than the row.** The cited
Wikipedia sentence says he *"was part of the unanimous Democratic coalition that voted to oppose"*
the amendment — and its two references are a **June 2006 party position** and an **October 2006
announcement that he would vote NO on Ballot Question #1**, the referendum, as a voter. Neither is a
legislative vote. **A reader who does not open the roll call cannot tell those apart**, and the
sentence reads naturally as a legislative one.

🔴 This is the most serious defect class in the corpus: a voter-facing row asserting that a named
living person cast a vote he did not cast. It cannot be repaired into rung 2, and it is not this
audit's business to seat him at rung 5 on a twenty-year-old vote he has since moved away from. The
roll call is **added to the row's sources** — a blank that says the record points the other way must
cite the record it read.

## 🔴 R24 Soto-Martinez / jail-capacity — BLANKED. A union's staffing decision is not a record

1921 re-seated him 2 → 1 on *"supporting Measure J"*. The cited page says something narrower:

> In 2020, he was **designated by his union** to be the labor liaison on Measure J.

He held **no office in 2020** — elected to the Council in November 2022 — so this is neither his
vote, nor his bill, nor his motion, and `jail-capacity @ local` is basis **`record`**. Being
assigned to a campaign by one's employer is the same shape as the **Marcus Simon row this queue
already blanked** (ledger R30: appointment to a redistricting commission "is an office duty, not a
position").

⚠ 1921 justified the re-seat by noting *"Hernandez sits at rung 1 on the same measure"* — but the
same page records Hernandez as a **co-chair of the Measure J campaign**, an act of her own. **Two
people connected to one ballot measure in different capacities are not the same evidence.**

> 🔑 **Open question recorded, not acted on.** Jails in California are a **county** function, and
> `role_scope` `'local'` covers city and county alike. A **city** councilmember has no lever on
> county jail capacity at all — the 2026-10-06 test for marking a (topic, level) `own-words`. That
> is a ruling; `compass_topic_roles` is untouched.

---

## The four repairs — ⚠ a repair must not move a chair, and none of these does

| row | chair | identifier, read at the primary source |
|---|---|---|
| **R25** Soto-Martinez / public-safety | 1 → 1 | **LA Council File 23-0862**, MOU 24 with the LAPPL. Council vote **23 Aug 2023, 12–3–0**: `EUNISSES HERNANDEZ 1 NO … NITHYA RAMAN 4 NO … HUGO SOTO-MARTINEZ 13 NO` |
| **R28** Tran / abortion | 1 → 1 | **Virginia HB 2491 (2019)**, "Abortion; eliminate certain requirements" — LIS: *"Introduced by: Kathy K.L. Tran"* |
| **R39** VanValkenburg / housing | 5 → 5 | **Virginia SB 346** (Chief Patron; Senate 38–2, House 92–6, **Chapter 20**, effective 1 Jul 2026) and **SB 454** (Chief Patron; passed Senate, **Failed**) |
| **R05** Chen / growth-and-development | 1 → 1 | Recorded **No** on the Family Zoning Plan rezoning, SF Board of Supervisors, **2 Dec 2025** |

**⚠ Two of the four needed an honest word about outcome that 1921 omitted.** HB 2491 **did not
pass** — "Left in Courts of Justice", 5 Feb 2019. SB 454 **failed** — "Left in Counties, Cities and
Towns", 10 Mar 2026. Sponsorship evidences the bill **as filed**, which is what a position is, but
the row should not let a reader assume it became law.

**⚠ The date is part of the citation for R25.** Council File 23-0862 carries a **second** vote on
19 Aug 2025 (12–0–3) in which Soto-Martinez voted **YES** on a later action. A reference to the file
number alone does not identify the 2023 vote.

### 🔴 Two detector failures found while sourcing R05, both worth keeping

1. **San Francisco's public Legistar API is stale.** `webapi.legistar.com/v1/sfgov` answers without
   a key, but its newest `MatterIntroDate` is **2005** and its newest "Rezoning" matter is **2018**.
   Every date-filtered query returned `[]` — **indistinguishable from "no such record"**. A positive
   control on the same endpoint returned rows, which is how the staleness was established rather
   than believed. *A uniform zero is a broken detector until a control says otherwise.*
2. **A name-only match would have cited the wrong ordinance.** Searching Legistar's web UI for
   "Family Zoning" returns **File 250719**, the unrelated ordinance redefining *"Family"* as
   *"Household"* — passed the same week. Plausible, adjacent, and wrong.

The Board file number for the rezoning is therefore **not cited**, and the reason is recorded in the
row itself rather than hidden. The vote is sourced to the contemporaneous report that names every
opponent.

## ▶ Still open

- **`same-sex-marriage @ state`** and **`jail-capacity @ local`** may both be mis-marked `record`.
  Rulings, not migrations.
- **R36 and R24 route to re-research**, as does R38 Zbur from the original pass.
- 🔴 **LA council and SF board vocabulary remain invisible to the chair-evidence pattern.**
  `Council File 23-0862` matches no alternative; R25 passes only because its reasoning also says
  "voted NO". The pattern has been widened six times, each time paired with rows verified at source.
  A seventh is now **earned** — but it belongs in its own change, with its test, not in the pass
  that fails it.
- **396 rows of the 436-class** have still never been sampled.
