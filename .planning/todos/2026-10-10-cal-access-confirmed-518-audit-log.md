# CAL-ACCESS confirmed-518 audit — adjudication log

Working log for `.planning/todos/2026-10-10-cal-access-published-source-audit.md`.
Opened 2026-10-10. Method: the CAL-ACCESS **candidate** page (`/Campaign/Candidates/Detail.aspx?id=`),
read in Playwright after loading the homepage first, batched with in-page `fetch`.

## Progress

| | sources | money |
|---|---|---|
| adjudicated | 223 / 518 | $338,716,000 (**94.8%**) |
| remaining | 295 | $18,707,112 |

43 politicians cleared. 🟢 **Every remaining untestable source carries $0** — the money side of this
audit is effectively closed, and it closed clean.

## 🔴🔴 THE FINDING: 100 confirmed sources are surname buckets on DUPLICATE rows

The surname-bucket defect that `CC_0213`–`CC_0218` cleaned out of the **disputed** population is
**still live in the confirmed population**. It is not spread thin — it sits on **eight inactive
duplicate rows**, and **every one of those eight shadows a LIVE SEATED officeholder of the same name**.

| duplicate row (`is_active=false`) | confirmed sources | how many name that person | the live twin |
|---|---|---|---|
| Dan O'Brien `80207395` | **44** | **0** | Council Member, At-Large |
| Paulette Francis `7e7834d9` | **23** | 2 | — |
| Tasha Cerda `7e189f77` | 10 | 4 | Mayor, Gardena |
| Lauren Meister `55233c22` | 8 | 4 | Council Member, At-Large |
| Maria Davila `4931b7d2` | 6 | **0** | Council Member, At-Large |
| Haidar Awad `156a8cc8` | 4 | 2 | — |
| Marvin Crist `ba8b83fd` | 3 | 2 | — |
| Drew Boyles `39d282fe` | 2 | 1 | Council Member, At-Large |
| **total** | **100** | **15** | |

**85 of the 100 name somebody else outright**, in the committee's own official name — so the
committee name is the primary evidence and no candidate page is needed. Dan O'Brien's 44 include
committees to elect **David W., Sean, Frank, Mike, Rennie, Kate, Cindy, Gerald, Richard, Shannon,
Jason, Bill, Edward, Martha, Michelle and Eimear O'Brien**. Not one says Dan. Paulette Francis's 23
include **Francis Carbajal** and **Francis Tsang** — matched on the *forename* Francis, not the
surname at all. Haidar Awad's four include `AWAD FOR MAYOR 2020; HAWTHORNE CITIZENS **OPPOSING**
HAIDAR` — a committee formed against him, published as his own fundraising.

### 🔴 Why this is urgent rather than tidy

They carry $0 and they sit on inactive rows, so nothing publishes **today**. But each row is a
duplicate of a live officeholder, and the dedupe programme merges duplicates into live rows.
**That merge is exactly the `CC_0220` incident** — 18 foreign committees landed on Bryan Fish's and
Angie Reyes English's live rows — **at 100 sources and eight officeholders wide.**

▶ **Disposition these BEFORE the dedupe programme reaches any of the eight names.** The 85 that name
another person go `disputed` → `not_applicable`. The 15 that name the person are kept and should be
moved to the live row as part of the merge, not left on the duplicate.

⚠ **The candidate-page method cannot resolve these** — none of the eight are CAL-ACCESS *state*
candidates, so no candidate page exists. Positive-controlled: a `letter=O` sweep over 13 sessions
returns `O'DONNELL` but no `O'BRIEN`, while the same code finds `LACKEY` under `L`.

## 🔴 The plan's ordering should change — measured, not assumed

The handoff says "start with the 259 that carry money, heaviest first". The first 10 heaviest
politicians (80 sources, $265M) produced **one** defect, and it carries **$0**. Money does not
predict error. What predicts it is whether the committee name carries a **forename tail**, because
that is the only thing `confirm-cal-access.ts`'s surname match could have been checked against.

| bucket | sources | with money | money |
|---|---|---|---|
| forename present | 318 | 171 | $197,596,923 |
| **NO forename tail** | **192** | **86** | **$131,542,449** |
| **no committee name at all** | **8** | **2** | **$28,270,811** |

**200 sources — 45% of the money — cannot be tested by any name-based rule.** That is the risk
surface, not the 259.

🟢 **The 8 with no committee name are now CLOSED for money.** Both money-carrying ones were verified
on their candidate's own page, and the committee page gave us the missing names:

- `1414018` → `NEWSOM FOR CALIFORNIA GOVERNOR 2022` — Newsom's. $23,008,654.
- `1413981` → `KOUNALAKIS FOR LIEUTENANT GOVERNOR 2022; RE-ELECT ELENI` — hers. $5,262,157.
- `1441328` → `BASS FOR MAYOR 2022 OFFICEHOLDER; KAREN` — Karen Bass's. $0.

▶ **Backfill those three names** in the same migration as the dispositions below.

## 🔴 Defect found: one, and it is the no-forename-tail class

`1446273` **`HURTADO FOR SENATE 2026`** sits `confirmed` on **Melissa Hurtado** (live, incumbent).
It is on **ESMERALDA HURTADO**'s candidate page (filer `1446266`), not Melissa's (filer `1401463`).
Melissa's own 2026 committee is `1456951` `HURTADO FOR SENATE 2026; VALLEY FAMILIES FOR MELISSA`.

- It carries **0 contributions**, so no money moves.
- ⚠ **There is no `Esmeralda Hurtado` politician row** — only `cal_access_discovery` placeholders.
  So the disposition is `disputed` → `not_applicable`, **not** a move to her.
- It is exactly the predicted shape: no forename tail, so no name test could have caught it.

## ▶ Three open items, carried to the next pass

| source | committee | money | question |
|---|---|---|---|
| `1480126` | `DIXON FOR SUPERVISOR 2026; DIANE` | **$798,784** | Absent from Diane Dixon's candidate page — but her **2022** supervisor committee (`1438441`) IS on it, so "local committees are not listed" does not explain this one. |
| `1451483` | `SOLACHE FOR CITY COUNCIL 2022; FRIENDS OF` | $76,121 | Absent from Jose Solache's page. Lynwood city committee, so plausibly the known coverage gap. |
| `1376762` | `MALHI FOR ASSEMBLY 2016` | $31,050 | On **`MALHI, SATINDER S.`**'s page (`1376581`). Our row is **`Raj Malhi`**. Same person under a short name, or two people? Needs a primary source that states it. |

⚠ The committee page does **not** name the controlling candidate, so none of these three can be
closed from it. `1438441` happens to print `(OFFICEHOLDER: ASSEMBLY DISTRICT 72)`; the other three
print no officeholder line at all, so that field is not a reliable second test.

## Confirmed clean (candidate page lists every one of our sources)

Rob Bonta 9 · Fiona Ma 9 · Al Muratsuchi 9 · Tony Strickland 8 · Jacqui Irwin 7 · Mike A. Gipson 11 ·
Jesse Gabriel 8 · Eleni Kounalakis 4 · Tom Lackey 8 · Adrin Nazarian 10 · Isaac G. Bryan 5 ·
Ali Saleh 4 · Joel Fajardo 5 · Jessica M. Caloza 2 · Caroline Menjivar 2 · Elen Asatryan 3 ·
Michael A. Cacciotti 1 · Sam Gallucci 1 · Ardy Kassakhian 2

## 🔴 The lookalike filers are real, and the audit must keep loading them

Every one of these exists as a **separate CAL-ACCESS candidate filer** sharing a surname with one of
our politicians. None of them had stolen a committee except Esmeralda Hurtado — but the method only
proves that because their pages were loaded too. **Load the lookalikes, not just the target.**

`BONTA, MIA` · `STRICKLAND, AUDRA` · `STRICKLAND, PAUL` · `HURTADO, ESMERALDA` · `IRWIN, KRISTINA` ·
`MA, OLIVER` · `GIPSON, PATRICK LEE` · `DIXON, RONDA` · `BASS, DAVE`

## Method notes that cost time

- ⚠ **The candidate list is NOT session-scoped in practice** — a candidate appears under every
  session list. An early read said otherwise; that was a regex that did not match across `\r\n`,
  not the data. **Positive-control a "not found" before believing it.**
- ⚠ **Our `committee_name` drifts from CAL-ACCESS's on the same filer id**, and in both directions:
  ours says `DIXON FOR CITY COUNCIL 2014`, theirs `2018`; ours `SOLACHE ... 2013`, theirs `2018`;
  ours `STRICKLAND FOR HB CITY COUNCIL 2022`, theirs `2026`. **Match on the id. Never on the name.**
- ⚠ **A politician can hold two candidate filer ids** (Al Muratsuchi: `1315952` and `1478875`). The
  second listed nine of the first's ten committees. Union them.
- 🟢 One `browser_evaluate` did 21 candidate pages, and another did 154 list pages. Batch it.
