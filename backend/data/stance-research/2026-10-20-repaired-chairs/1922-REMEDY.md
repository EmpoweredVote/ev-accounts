# The remedy — migration 1922

**2026-10-21.** Migration 1921 re-seated 9 chairs out of the repaired-chairs queue. The
chair-evidence gate is a **pre-commit** gate for any migration that sets a chair, and 1921 was
applied before it was run. This is what running it found, and what was done about it.

Companion to [`LEDGER.md`](LEDGER.md), which carries the 40-row read itself.

---

## What the gate found, once it was pointed at the right rows

⚠ **The fixture must carry `season_id`.** Without one the lookup joins *every* season's context for
the pair and judges whichever row returns first — Season 1's text, which this pass never touched.
The first run failed 9 of 10 while quoting prose none of these rows carry any more, and **the wrong
verdict was indistinguishable from the right one**. A blanked pair (R34) is planted in the committed
fixture as a control: it is skipped as a blank only if the Season 2 answer is the one being read.

Scoped correctly:

| population | names an instrument |
|---|---:|
| the 436-class rows this queue did **not** touch | **304 / 388 — 78%** |
| all seated Season 2 rows | 1,986 / 3,718 — 53% |
| **the 9 re-seats + 1 repair written by 1921** | **0 / 10 — 0%** |

0 of 10 against 78% in the same class is not a lexical accident. It has two causes, and conflating
them is the mistake to avoid.

## 🔴 Cause one: three chairs were seated where the codebook does not allow it

Under the ruling of 2026-10-06 **a record needs a lever**, and the person's own words can seat a
chair **only** where `compass_topic_roles.evidence_basis` marks that (topic, level) `own-words`.
Four of the ten name no instrument at all. Checked row by row against that table:

| row | person / topic | level | basis | what the row cites | verdict |
|---|---|---|---|---|---|
| R32 | Harris-Dawson / redistricting | local | **own-words** | advocacy for an independent commission | ✅ **admissible, left alone** |
| **R04** | DeMaio / same-sex-marriage | **state** | **record** | an announcement, a 2014 campaign ad, an endorsement | 🔴 **blanked** |
| **R11** | Hernandez / growth-and-development | local | **record** | her own campaign sentence | 🔴 **blanked** |
| **R12** | Hernandez / housing | local | **record** | "pushed the city to build a social housing programme" | 🟢 **rescued — chair unmoved** |

⚖⚖ **The pass convened to refuse this evidence produced it.** 1921 exists because a citation repair
is forbidden from moving a chair, so a wrongly-seated row came out of the repair passes *looking
sourced*. In three cases 1921 moved a chair onto evidence of exactly the kind it was convened to
refuse. The remedy is the one that queue already used thirteen times: **a blank is correct.**

### A bounded rescue was attempted on all three first, which is why only two blanked

**🟢 R12 Hernandez / housing — RESCUED. The instrument was on the cited page the whole time and the
row never named it.** Read at the **primary source**, the City Clerk's own file rather than the
consultancy write-up Wikipedia footnotes: **Council File 23-0038-S6**, *"Measure ULA / ACT-LA /
Strategic Financing Tools / Permanent Affordability / Resident Governance / Social Housing"*,
introduced **28 May 2024**, **Mover: MARQUEECE HARRIS-DAWSON, EUNISSES HERNANDEZ, NITHYA RAMAN**,
approved as amended by the Housing and Homelessness Committee 7 August 2024, **adopted by Council 28
August 2024, 15–0–0**, with `EUNISSES HERNANDEZ 1 YES` in the recorded vote.
She is a **mover** of the file and **voted YES** on its adoption, so this is her own act, numbered.
Its content is rung 2's own distinguishing clause. ⚠ **A repair must not move a chair, and this one
does not**: 2 before, 2 after. The council file is **added to the row's sources**, so the row also
stops resting on a generic page alone.

**🔴 R11 Hernandez / growth-and-development — RESCUE FAILED, AND THE RECORD POINTS AWAY.** 1921
moved her 2 → 1 on the campaign sentence *"My plan to fight gentrification is to be the biggest
barrier I can to luxury and market-rate development."* Rung 1 reads *"Hold the pace of growth down —
cap major new development, **and let residents vote directly on the largest projects**."* Neither
limb survives her record **on the very page cited**:

- the **resident-vote limb is contradicted** — the page records her support for the *discretionary
  permit system*, which gives **council members** the land-use veto, not residents;
- the **cap limb is contradicted by a recorded position** — fetched at LAist: when Raman moved to
  allow buildings up to 16 units in single-family zones, *"Councilmember Eunisses Hernandez echoed
  Raman's arguments, saying that preserving wealthy single-family neighborhoods represents a
  continuation of past segregationist policies"*, and the amendment failed with 10 against. She
  backed **more** housing in low-density areas. The same page records her dissenting in 2025 from
  the council majority opposing **SB 79** (dense housing near transit).

She is against luxury and market-rate development and **for** density that is affordable. This
ladder is a pure **pace** axis and cannot express that. Rung 2 is no better — "infrastructure" and
"capacity" appear nowhere. **Blanked.**

**🔴 R04 DeMaio / same-sex-marriage — RESCUE FAILED FOR WANT OF A RECORD, AND NONE CAN EXIST YET.**
The whole of the cited page's marriage evidence is one sentence: *"He announced his support for
same-sex marriage after 2008, has participated in LGBT Pride, and was endorsed by Log Cabin
Republicans."* Fetched and searched: **no Proposition 8, no Proposition 3, no ACA 5, no bill number
and no vote of any kind on marriage.** An announcement is own words; an endorsement is somebody
else's. ⚠ 1921's note that *"he is himself gay and married"* is a fact about the man, not a position
he has recorded, and is not evidence on this ladder. **Blanked.**

> 🔑 **AND THE ROW RAISES A QUESTION BIGGER THAN ITSELF, LEFT OPEN DELIBERATELY.** DeMaio took his
> Assembly seat in **December 2024**. California settled the question before he arrived — ACA 5
> passed in 2023, Proposition 3 was carried in November 2024 — so **there is no state instrument
> left for him to act on**. If no rung at that level has a lever, the 2026-10-06 ruling says the
> (topic, level) should read `own-words`, not `record`. **That is a ruling, not a migration**, and
> `compass_topic_roles` is not touched here. Were `same-sex-marriage @ state` re-marked later, this
> row could be re-seated on the announcement — as a separate reliability stratum, which is its own
> open item.

## Cause two: the gate cannot see what six rows plainly name — and the regex was NOT widened

Each of these names a real act or vote in a form the lexical pattern misses. **The remedy is to cite
the identifier, never to widen the pattern**, because a pattern widened to admit prose makes passing
mean nothing.

| row | what it names | why the pattern misses it |
|---|---|---|
| R28 Tran | the **Repeal Act** | written `REPEAL ACT`; `\bAct\b` is deliberately **case-sensitive** |
| R24 Soto-Martinez | **Measure J** | `Measure` requires a decimal (`Measure 1.1`); a lettered county measure is not admitted |
| R05 Chen · R25 Soto-Martinez · R36 Deeds | recorded votes | all say *"voted **against**"*; the pattern admits only `voted YES/No/Yea/Nay/Aye` |
| R39 VanValkenburg | two Virginia bills | named **by description**, neither by number |

▶ **Los Angeles council vocabulary is invisible to this gate.** `Council File 23-0038-S6` matches no
alternative in the pattern; R12 passes only because its repaired reasoning also says **"voted YES"**.
The pattern has been widened six times — for city councils, mayors, a commissioners court, the U.S.
Senate and a Florida county board — each time **paired with rows already verified at source**. An LA
council-file alternative would be the seventh, and it is **not** taken here: widening a gate in the
same pass that fails it is how a gate stops meaning anything.

## Result, measured

| | before 1922 | after 1922 |
|---|---:|---:|
| chair-setting rows live from this queue | 10 | **8** |
| …that name an instrument the gate can see | **0** | **1** |
| inadmissible under `evidence_basis` | **3** | **0** |

The one that now passes is R12, because its repaired reasoning names the council file **and** her
recorded YES.

## ⚠ Still open

- **Six rows owe an identifier**, not a blank — their chairs were read by hand and stand. Each needs
  its bill number, measure number or roll call fetched and written into the reasoning.
- **`same-sex-marriage @ state`** may be mis-marked `record`. A ruling, not a migration.
- **The class is 436 rows, not 40.** The other 396 cite at least one specific source, so nothing
  flags them. ⚠ Do not project this queue's rate onto them — these 40 are the worst-sourced end.
- 🔴 **Run the chair-evidence gate BEFORE applying, with `season_id` in the fixture.** That is the
  whole lesson of this remedy.
