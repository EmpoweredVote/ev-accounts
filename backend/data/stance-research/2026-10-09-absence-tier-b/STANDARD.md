# The absence-queue adjudication standard

**Derived from the 101 KEEP rulings and the boundary BLANKs in `LEDGER.md`, not written from
opinion.** It exists because a blind re-read of 24 already-adjudicated rows agreed only 17/24, with
every miss on the KEEP side. A standard that two passes cannot both apply is not a standard.

Apply it in three steps, in order. Steps 1 and 2 decide almost every row.

---

## Step 1 — Find the row's POSITIVE evidence, and ask three things of it

**(a) Is it the person's OWN?**
A statement, vote, authored or moved instrument, platform, questionnaire answer, or an act taken in
office.

- ✅ **Moving a motion is their act even when the vote is 9-0.** (Jacobs, local-environment)
- ✅ **A score IS a record when the row names the votes behind it** — "33 anti-environment votes to
  0, against clean air, efficiency standards and renewables" (Wied); "NAY on every tracked
  restriction 2023-25, H.R. 21 named" (Menendez). A bare "97% LCV" is not.
- ❌ The **body's** act, the **caucus's** act, an endorsement *of* them, district demographics, a
  bare rating, an adjacent topic.
- ❌ **Office duties are not a position.** Investigating Medicaid fraud, administering disclosure
  law, implementing a court order. (Raoul ×2, Henderson redistricting)

**(b) Is it on THIS ladder's axis?** The ladder's own subject, not a neighbouring one. A sanctuary
designation is not athletics; PFAS is not climate; a solar PPA is not development standards.

**(c) Does it establish a DIRECTION on that axis?**

**If any of the three fails → BLANK.** The absence, or the affiliation, is supplying the direction.
This is the whole defect class: party, caucus, committee seat, ideology label, endorsement or rating
standing in for a position.

---

## Step 2 — Ask what the ABSENCE is doing

✅ **KEEP — it declines a neighbour that would require MORE than the evidence shows.**
This is the commonest legitimate shape in the ledger; roughly a quarter of all KEEPs say it in so
many words — *"the absence rules out rung 1 on top of that"*. A pro-choice platform with no
public-funding language seats rung 2 and not rung 1, correctly.

✅ **KEEP — an omission INSIDE the person's own document, where the rung is about EMPHASIS or
FRAMEWORK.** "The Northcut shape": a transportation page that is road-only, an energy page that is
all-of-the-above with no emissions content, a healthcare section that is competition and telemedicine
throughout. That *characterises the platform* — it is evidence, not a gap in the world.

❌ **BLANK — the absence supplies the direction itself.** "No documented position … as a Republican
he would be expected to be sceptical."

❌ **BLANK — the absence moves the seat to a rung the evidence points AWAY from.** Positive evidence
at one end, an absence dragging the seat toward the middle.

❌ **BLANK — the rung asks for an AFFIRMATIVE COMMITMENT and the omission is offered as it.** Never
mentioning vouchers is not a commitment to *eliminate* vouchers. 🔑 **Ask what the rung is a claim
ABOUT before reading an omission as evidence.**

---

## Step 3 — Rung match

Does the seated rung's own **text** describe what the evidence shows? Read the rung, not its number.

⚖ **A defensive record IS the "maintain / improve current programmes" rung.** Opposing privatisation
and benefit cuts is not a failure to pick a rung; it is that rung. (Frankel, medicare/aid)

---

## 🔴 What is NOT a reason to blank

- **⚠ VINTAGE.** Dated evidence is **flagged, not blanked**. Seven ledger KEEPs carry a vintage flag,
  the oldest from 2006. Staleness earns an annotation and a place in a re-research queue.
  ⚠ Exception already ruled: a **party change** is a supersession event ([[corpus_detector_run]]).
- **Band-vs-rung used alone.** The standard does **not** require the positive evidence to exclude
  both neighbours by itself — step 2's narrowing is allowed to do that work. Band-vs-rung blanks a
  row only when the evidence fails step 1(c) or step 3.
  🔴 **This is exactly where the 2026-10-09 re-read drifted: 4 of 6 misses were rows where attributed
  on-axis evidence set the direction and an absence declined the stronger neighbour.**

## 🔴 And one correction to the record

Mike Riley's transportation row was blanked by the ledger for a **rung-match** reason, not for
staleness — and on inspection the rung text ("invest equally in roads and multimodal options") does
describe the "roughly even mix" the row reports. **That ruling looks wrong.** So "staleness relative
to the current office" is *not* a seventh defect shape; the earlier note saying so is withdrawn.
True drift in the calibration was **6 of 24, all one-directional**, not 7.

---

## Two rules added after the second calibration (2026-10-09)

**4. ⚠ VINTAGE is a flag that ROUTES, and a KEEP on a vintage row is PROVISIONAL.**
The ledger flagged 7 KEEPs as vintage; migration 1916 re-researched that queue and **6 of 8 failed**
— Scott Brown, Goodenough ×2, Alan Wong, Bengs and Ricketts are all blanked to 0 in production now.
So "vintage is flagged, not blanked" is right at step 1 and **must not be read as a clearance**: the
row leaves the absence queue and enters the re-research queue, where most of them die.
⚠ **A party change is a supersession event** and blanks at stage 1.

**5. 🔴 A RUNG NUMBER IN THE PROSE MAY BE STALE. Test the prose's DESCRIPTION against the rung TEXT,
never against its number.** Aaron Ford's row says *"aligns with stance 2"* and is seated at 3 — but
its own parenthetical gloss of "stance 2" is **word for word the Season 2 rung 3 text**. The row was
written on the Season 1 numbering and carried forward. The seating is correct and the number in the
prose is stale ([[stale_prose_after_chair_fix]] — repair is to write forward, not to blank).
I blanked it on the number and was wrong. Same family as "never read the frozen `title`".

## ⚠ The labelled set is partly stale

**11 of the 101 ledger KEEPs have since acquired a Season 2 answer** (6 blanked to 0 by mig 1916,
5 re-seated). Anyone refitting on `labelled_a.json` should refresh those labels from production
first, or the model learns a verdict that has been overturned.

---

## Measured: does the standard take?

Second calibration, **24 fresh rows never seen** (stratified 12/12, blind):

| | first pass, no standard | with the standard |
|---|---|---|
| agreement | 17/24 = **71%** | 22/24 = **92%** |
| ledger-KEEPs called BLANK | 6/12 = **50%** | 2/12 = **17%** |
| ledger-BLANKs called KEEP | 1/12 = 8% | **0/12** |

Both residual misses have identified causes, neither of them drift: **Bengs** is a *stale label* (the
ledger KEPT him; mig 1916 later blanked him, and my BLANK matches production), and **Ford** is rule 5
above, now written down. Counting Bengs as agreement with the current state of the data gives
**23/24 = 96%**.
