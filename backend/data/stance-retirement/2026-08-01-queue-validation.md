# Working the top of the queue — out-of-sample result

First pass on the calibrated reading queue: the 4 `party/employer/endorser` rows and all 6 `hedges`
rows (the two highest-precision markers), plus the absence rows that shared their sites — **21 rows
across 12 sites**, read against raw HTML with `scripts/read-site.mjs`.

---

## Result: precision holds, lift is UNPROVEN

| | in-sample (78 labelled) | out-of-sample (this pass) |
|---|---|---|
| flagged rows classified | — | **9** |
| defects found | 60% | **5 — 56%** |
| of which severe (wrong chair shown) | 60% | 3 — 33% |

**56% against a 60% prediction is a good hold.** But precision alone does not show the signal *works*
— that needs the defect rate among **unflagged** rows, and the control sample failed to produce one:

- 6 unflagged rows sampled → **3 were unverifiable** (2 dead sites, 1 JS shell)
- of the 3 readable, **1 was a marker false negative**, not a true control member (below)
- leaving **n=2**. Nothing can be concluded from that.

🔴 **So the honest status is: the flagged rows are defective at roughly the predicted rate, and we
still do not know whether unflagged rows are any better.** Lift remains unmeasured. Do not quote the
5.3x figure as validated — it is in-sample only.

---

## The 9 classified flagged rows

**5 defects**

| row | finding |
|---|---|
| **Silvia Catten / Taxes** | 🔴 **"tax" is absent from all 3 pages (13,009c raw).** The row infers "implies modestly raising taxes on high earners" from *"working class policies… strengthen wages"*. Exactly the Bowen shape 1521 retired. **Retirement candidate.** |
| **Kathleen Anderson / Public Safety** | 🔴 **"police" and "staffing" absent** (1,631c body). The quoted complaint is verbatim — *"Public spaces are too often affected by drugs, crime, trash, vandalism and disorder"* — but chair 4 is "increase police staffing, equipment, and pay", and the row admits it "**implies** adding police staffing". **Retirement candidate.** |
| **Aaron Wiley / Healthcare** | Quotes verify verbatim (*"Healthcare shouldn't depend on your ZIP code"*, *"Emergency Room and Instacares to the Westside"*) but **"insurance" and "coverage" are absent**. The site is about *where facilities sit*; chair 2 is about *how care is paid for*. Wrong axis. **Chair unsupported.** |
| **Maria Lou Calanche / Transportation** | The row says *"Detailed transportation positions were not publicly available"* — **and that is false.** The issues page carries *"Free community transit and shuttles to connect communities"*. **Reasoning fix**; the chair may be better supported than the row claims. |
| **Ericka Kopp / Fossil Fuels** | *"Endorsing a Green New Deal"* and *"Prioritizing clean energy initiatives, including solar and wind energy"* are verbatim, but **fossil, drilling, permit, oil, gas are all absent**. Chair 2 is "stop issuing new permits". GND is definitionally a fossil phase-out, so the chair stands — but the reasoning must cite the page, not say "implies". **Reasoning fix.** |

**4 keeps** — Catten/Housing and Catten/Homelessness (both quoted verbatim, including *"prohibit
corporations from buying up housing stock"* and *"practical and compassionate solutions"*),
Hines/Campaign Finance (*"I do not take corporate PAC money, and I support a ban on members of
Congress trading individual stocks"* — verbatim, exactly as quoted), Kopp/Immigration.

---

## 🔴 The bigger finding: a quarter of the cited sites are no longer readable

Of **12 sites** attempted, **3 were unusable** — and they took **9 rows** with them:

| site | status | rows stranded |
|---|---|---|
| `erinforutah.com` | **404** on every variant (www, non-www, http) — DNS resolves, host serves 404 | 6 (Erin Jemison) |
| `faizahforla.com` | **404** | 1 |
| `moforla.com` | thin body, **180c** — JS shell, *not* an absent claim | 1 |
| `acostaforla.com` | fetch failed | 1 |

**The `DEAD_SITE` backlog item says 16 rows. This one 12-site sample stranded 9.** That item is badly
understated, and it is not a small cleanup — it is a class of rows a voter cannot check at all.

### Jemison is unverifiable, and deliberately not convicted

Her 6 queued rows quote specific language — *"opposes unchecked voucher expansion diverting funds from
neighborhood schools"* — and name endorsements (AFT Utah, Better Boundaries Accountability PAC). The
**one** Wayback capture (`20260216010533`, applying the 1519 lesson: query CDX **unfiltered**, the
`host*` form returned empty and the `host` form found it) is **2,026c** — a landing page whose entire
policy content is six slogans: *Improving Air Quality · Defending Democracy · Preserving the Great
Salt Lake · Investing in Public Education · Protecting Vulnerable Communities · Standing Up for
Working Families.* Every specific claim is absent from it; only the Domestic Violence Coalition line
survives.

⚠ **But the capture predates the site's death and may predate the content the research read.** So
these rows are **neither confirmed defects nor confirmed sound**, and they are excluded from the
precision figures above rather than counted as wins. They are owed re-research, not retirement.

---

## Two tool bugs found by this pass

1. 🔴 **`no mention` was missing from the absence pattern.** Anderson/Transportation reasons *"No
   mention of transit, bike lanes, or pedestrian infrastructure in her platform"* and went **unflagged
   into the control sample**, where it read as a defect. A false negative in the control inflates the
   control's defect rate and makes the signal look *worse* than it is. Fixed — the queue grew 42 → 50.
2. ⚠ **Raw-HTML search matches the doctype.** On `hildalsolis.org`, `transit` matched
   `HTML 4.0 **Transitional**//EN`. Harmless here because every hit was inspected, but it is exactly
   the kind of thing that becomes a false "the topic is on the page" if hits are ever counted rather
   than read.

**And one control row was a genuine defect: Hilda Solis / Residential Zoning.** *density*, *zoning*
and *community benefit* are all absent from her site; the only related content is "funding to build
thousands of affordable housing units". The row describes "increased housing density near transit
corridors… community benefit agreements… managed density increases". Unflagged by any marker — more
evidence the signal has recall problems, not precision problems.

---

## What I would do next, in order

1. **Sweep every distinct host in the 517 unread rows for reachability.** Mechanical, no judgement,
   and this sample says it will reclassify a large number of rows out of "suspect reasoning" into
   "uncheckable citation" — a different and cheaper remedy (re-source to Wayback, as 1519 did).
2. **Apply the 5 defects found here**, in the 1522–1524 shape.
3. Only then keep reading the queue. A proper control needs ~20 unflagged rows to survive the ~50%
   attrition seen here, and that is worth doing *after* the dead-site sweep removes the attrition.
