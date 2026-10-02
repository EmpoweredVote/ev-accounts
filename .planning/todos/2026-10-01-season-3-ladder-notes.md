# Season 3 ladder notes — staging list

**What this is:** ladder wording changes found while coding Season 2, held until Season 3 composition.
**Where they go when it is time:** each one becomes a `status = 'draft'` revision filed through the
revision editor (`POST /api/compass/revisions`, ADR 0004 §6–§7). That row needs a `rationale`
(internal) and a `public_note` (reader-facing), so each entry below is written in those two fields
already. Do not file them early: a draft on an open-season topic would sit in the review queue for
months.

**Before filing any entry:** count the seated rows on the rung (CLAUDE.md "Rewording a chair that
already holds seated politicians"). A *clarifying* change keeps seats; a *material* one needs a
re-audit, and the count goes in the rationale.

Add new notes at the bottom. Do not record gold item names here (keep them certifiable).

---

## climate-change — rung 3

- **Served (S2):** "Speed up clean energy by cutting permitting red tape and upgrading the grid."
- **Proposed:** "Speed up clean energy by cutting permitting red tape and modernizing grid rules."
  _(wording open — the point is "by rules, not by spending")_
- **Class:** clarifying (expected). Confirm with the seated count.
- **Rationale:** Ruling 2026-10-01: public money for the grid matches rung 2 ("public investment")
  and rung 3 ("upgrading the grid") at once, so coders must code a grid appropriation
  `direction-only`. Saying the rung-3 mechanism is rules removes the overlap.
- **Public note:** "Rung 3 now says the grid change is made by rules, to separate it from public
  spending in rung 2."
- **Source:** `docs/codebook/annex/climate-change.md`, rung 2.

## school-vouchers — rung 3

- **Served (S2):** "Allowing income-based voucher programs, open to a wider range of families under an
  income cap"
- **Proposed:** "Allowing income-based voucher programs, open to families under an income cap"
- **Class:** clarifying.
- **Rationale:** Ruling 2026-10-01: S2 has no low-income-only rung, so a narrow means-tested programme
  is coded rung 3, and "wider range" was read as a comparison with rung 2, not a separate test.
  Dropping "a wider range of" makes the text say what is coded.
- **Public note:** "Rung 3 wording simplified; it covers any income-limited voucher programme."
- **Source:** `docs/codebook/annex/school-vouchers.md`, rung 3.

## school-vouchers — rung 5

- **Served (S2):** "Providing universal vouchers so that education funding follows the student to any
  school — public, private, or religious — chosen by the family"
- **Proposed:** "… follows the student to any school or schooling — public, private, or religious —
  chosen by the family"
- **Class:** clarifying.
- **Rationale:** Operator's gold-desk note, ruled 2026-10-01: ESA money can pay for tutoring,
  therapy or home education, so "school" under-describes the programme. Coders already treat
  non-school spending as not excluding rung 5.
- **Public note:** "Rung 5 now says 'school or schooling', since education accounts can pay for more
  than tuition."
- **Source:** `docs/codebook/annex/school-vouchers.md`, hard cases.

## abortion — rungs 2, 3, 4 (candidate; not ruled)

- **Problem:** the rungs state limits in trimesters; laws state weeks. A limit at about 20 weeks sits
  between the rung-2 and rung-3 thresholds. A ban whose only exception is the mother's life fits
  neither rung 4 (rape, incest and life) nor rung 5 (no exceptions).
- **Status:** the annex will carry a weeks-to-rung reading first (see
  `docs/codebook/annex/README.md`, "Pending notes"). Decide at Season 3 whether the ladder itself
  should state weeks and cover the life-only ban.

## Judicial batch (from the 2026-10-01 annex drafting; wording proposals are drafts)

- **judicial-bail-pretrial — key/title:** "Bail and Pretrial" does not match the rungs, which ask how
  closely a judge watches prosecutors and never mention bail. Rename (for example "Judicial Scrutiny
  of Prosecutors") or re-axe onto bail. Rungs 1 and 2 are not clearly ordered; rungs 1, 4, 5 carry
  reason sentences.
- **judicial-access-to-justice — rungs 2/3 close;** clerks can reach only rung 1 (ruled: not coded in
  S2). Possible rung 2: "Apply the normal requirements, but use the court's discretion to forgive
  small mistakes so a real case is heard."
- **judicial-government-deference — rung 5 referent:** "elected officials and agencies" vs "the
  government" in rungs 1–4. Rungs 1/2 and 4/5 differ only in strength.
- **judicial-interpretation — rungs 4/5 overlap:** rung 5 names no method rung 4 lacks. Possible rung
  5: "Apply the plain words of the law as they read today, without looking to purpose or history; if
  it needs to change, that is for elected lawmakers."
- **judicial-police-accountability — rungs 2/3 overlap.** Possible rung 2: "Take misconduct
  complaints seriously, investigate each one fully, and act on the ones that hold up, without
  defending the employee in the meantime."
- **judicial-prosecution-priorities — rung 5** carries editorial phrases.
- **judicial-criminal-justice — rung 5** ("Impose the toughest penalties") is an act legislators
  cannot perform; they reach it only through own words.

## Education batch (accepted 2026-10-01 as ladder notes; wording proposals are drafts)

- **education-library-books — rung 3 double-barrel** (review finding + committee of educators and
  parents). Proposed: "Remove a challenged book only if a formal review finds it unsuitable", or move
  the reviewer into its own clause. Count seated rung-3 rows before filing (none in the open season on
  2026-10-01). **Rung 1** "every book" conflicts with routine weeding.
- **education-curriculum — rung 5** "that the community considers" does not say whose judgment counts.
  Proposed: "Prohibit lessons on race, gender, or sexuality that are divisive or not suitable for the
  students' age". Rung 1 is a triple compound ("race, gender, and social justice").
- **education-school-budget — gaps:** no rung for a modest increase paid by a tax, none for a
  significant increase with no tax. Proposed: rung 1 "Raise taxes if needed to significantly increase
  school funding", rung 2 "Increase funding modestly to keep pace with costs". Rung 4 is about
  composition, not level.
- **education-school-police — rung 5** "make arrests on campus" adds nothing (a sworn officer has arrest
  power). Proposed: "Place an officer in every school and let them handle student discipline as well
  as crime". Rungs 1 and 2 are both compounds.
- **education-charter-authorization — rung 2 referent.** Proposed: "Approve new charters rarely, only
  where district schools are clearly failing students". Re-check the state scope.
- **education-equity-programs — rung 5** "from the district" fits school boards only. Proposed:
  "Eliminate equity programs, training, and staff in schools". Also a triple compound.
- **education-gender-identity** (low priority): no rung for a flat ban on chosen names or pronouns.
- **education-ai** (low priority): rung 4 "light guidelines" and "teacher discretion" are hard to
  evidence separately.
