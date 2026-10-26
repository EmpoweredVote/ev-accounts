# Contradiction check — the eight largest groups, read in full

Migration **1942**. Applied to production 2026-10-25 and verified through a separate connection.

Source queue: `backend/scripts/check-instrument-rung-contradictions.mjs --sole` (PR #1085), run
against production on 2026-10-25. The check groups rows that cite ONE instrument, take the SAME
side of it, and sit on DIFFERENT rungs of ONE ladder revision, so at most one member of a group can
be right.

| | before | after |
|---|---:|---:|
| groups reported (`--sole`) | 149 | **142** |
| rows covered | 1,127 | **945** |

Seven groups closed; 182 rows left the queue, of which 114 were written and 68 were already correct
members of groups that became uniform.

---

## 1 · The result

| rows | instrument | ladder | side | decision | written |
|---:|---|---|---|---|---:|
| 45 | Inflation Reduction Act | climate-change | FOR | ▶▶ **WITHDRAWN from the pass** — see §3 | 0 |
| 36 | For the People Act | redistricting | FOR | re-seat the 8 at chair 1 → chair 2 | 8 |
| 29 | For the People Act | redistricting | SPONSOR | re-seat the 11 at chair 1 → chair 2 | 11 |
| 25 | For the People Act | redistricting | AGAINST | withdraw all | 25 |
| 25 | Safe Communities Act | deportation | SPONSOR | withdraw all | 25 |
| 23 | Protection of Women and Girls in Sports Act | trans-athletes | FOR | re-seat the 1 at chair 5 → chair 4 | 1 |
| 22 | Texas HB 229 (89R) | trans-athletes | SPONSOR | withdraw all | 22 |
| 22 | Fair Districts for Maryland Act | redistricting | SPONSOR | re-seat 21 → chair 2, withdraw 1 | 22 |

**41 re-seated · 73 withdrawn · 113 left exactly as they are.**

---

## 2 · 🔴🔴 Every one of these 227 rows serves from Season 1, and that changed the write shape

Migrations 1926, 1927, 1930 and 1941 all UPDATED Season 2 rows in place. Not one row in this
population has a Season 2 shadow — the check's own `serving` CTE prefers Season 2 and fell back to
Season 1 for all 227. Season 1 is closed and immutable (ADR 0005 §1.6), so **the only way to change
what a voter reads is to INSERT a Season 2 row.** Measured before writing: 114 target pairs, 114
Season 1 answers, 114 Season 1 contexts, **zero rows in any other season**, 114 active people.

✅ Verified in code, not assumed, that a Season 2 row shadows a Season 1 one: `compassService.ts`
`getPoliticianAnswers` and the citations query both collapse with
`DISTINCT ON (topic_id) … ORDER BY s.number DESC` and then drop `value = 0`. So an inserted Season 2
blank removes the spoke and an inserted re-seat replaces the chair.

✅ Verified after writing, through a separate connection: Mark Takano now serves **Season 2
chair 2**, *"independent redistricting commissions with equal representation…"*; Mike Lee now serves
**Season 2 value 0** — the chair-1 inversion is off the site.

### 🔴🔴 And it changes which ladder the new row is read against

**ADR 0006 (Option Y), quoted from `compassService.ts`:** *"title, tension name, stance text and the
ladder below all come from ONE revision — the served revision … of the version pinned by the season
this block shows. That is the ANSWER's season: **an answer is locked to the ladder it was given
against**, so its recorded pin (`pa.topic_revision_id`) decides, not the open season."*

`servedRevisionLateral` resolves the pin to the latest published/superseded revision **of that
pin's VERSION**, so a Season 1 answer stays on the Season 1 version's text. Resolved per topic
before writing:

| topic | Season 1 pin | Season 2 pin | does the chair mean the same thing? |
|---|---|---|---|
| redistricting | v1r1 `c7f973fc` | **the same** `c7f973fc` | yes — one revision, pinned by S1, S2 and S3 |
| trans-athletes | v1r1 `af2c6427` → serves v1r3 `c47c957a` | v1r1 `af2c6427` → serves v1r3 | yes at chairs 4 and 5; only chair 3 was reworded |
| deportation | v1r1 `673c3758` | v2r2 `55c3167e` | immaterial — every deportation row here is a blank |
| climate-change | v1r1 `da9cf777` | v2r3 `5f1403f3` | 🔴 **NO — see §3** |

⚠ The trans-athletes row is worth its own line: both seasons PIN `af2c6427`, but that revision is
`superseded`, so the served text is actually **v1 revision 3 `c47c957a`**. The contradiction check
groups on the pin, the voter reads the resolved revision. They agree at chairs 4 and 5, which is
the whole of this group, but the next reader should not assume the pin is what is served.

---

## 3 · ▶▶ The group that was adjudicated and then withdrawn — and why it is the most useful finding

**Inflation Reduction Act → climate-change, 45 rows (3 at chair 1, 28 at chair 2, 14 at chair 3).**
The adjudication was written, guarded, and dry-run against production before being taken out.

### 🔴🔴 `--sole` guarantees one **KEYED** instrument, not one instrument

The check compares only rows whose reasoning yields exactly one instrument key, precisely so that a
rung reflecting the SUM of a row's evidence is not compared with a rung reflecting less. But the
keyer is lexical. It never keys **"the Green New Deal"** (H.Res. 109), and:

| of the 31 rows at chairs 1–2 | n |
|---|---:|
| also cite Green New Deal co-sponsorship | **13** |
| cite a dated decarbonisation target in the member's own words (2030 / 2050 / net-zero / carbon-free) | 9 |
| cite neither — the Act plus a League of Conservation Voters score | **15** |

Those 13 are not comparable with the rows citing the Act alone, so **the group is not one unit of
defect and the contradiction it reports is partly an artefact of the grouping.**

⚖ This is the mirror of the lesson in [[project_cluster_mapping_pass]]: there, a cluster was not a
unit of defect because its fingerprint named a SOURCE TYPE rather than an instrument. Here the
fingerprint does name an instrument — and it is still not a unit of defect, because the keyer could
not see the SECOND instrument. **Ask of any group: is this the whole of each row's evidence?**

### ⚠ The underlying reading still looks right, and is recorded for whoever picks it up

Season 1 chair 2 reads *"rapidly transition to renewable energy and phase out fossil fuels by
2030"*. The Act's own **§50265(b)** forbids the Secretary, for TEN YEARS, to issue a wind or solar
right-of-way on Federal land unless an onshore oil-and-gas lease sale was held in the previous 120
days covering at least 2,000,000 acres in the previous year, and to issue an offshore wind lease
unless at least 60,000,000 acres were offered for offshore oil and gas in the previous year.
**§50264** reinstates Gulf Lease Sale 257 and mandates Sales 258 and 259. An Act that makes
renewable development conditional on continued fossil leasing for a decade does not evidence a 2030
phase-out.

▶ **That reaches the 15 rows resting on the Act plus an LCV score** — a scorecard is a direction,
not a rung. Those 15 need reading one at a time against H.Res. 109, not as a group.
Enacted text: `https://www.govinfo.gov/content/pkg/PLAW-117publ169/html/PLAW-117publ169.htm`

### 🔴 A second finding, logged and not acted on: the climate ladder was rewritten under an identity `rung_map`

```
Season 1 (v1r1)  1 declare a climate emergency and ban all activities that increase carbon emissions
                 2 rapidly transition to renewable energy and phase out fossil fuels by 2030
                 3 invest in clean energy while gradually reducing reliance on fossil fuels
                 4 let market forces drive any transition to cleaner energy sources
                 5 reject climate change policies and focus on economic growth instead
Season 2 (v2r3)  1 Require a shift to clean energy through mandates and firm deadlines.
                 2 Fund clean energy with major subsidies, tax credits, and public investment.
                 3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
                 4 Stay neutral on energy and let the market choose among all sources.
                 5 End government subsidies and mandates for clean energy.
```

The first ranks **AMBITION**; the second ranks **INSTRUMENT**. They are not a rewording of one
another — chair 3 moves from "gradual reduction" to "permitting reform and the grid", which is a
different claim about a different thing. And yet `compass_topic_revisions.rung_map` for v2r3 is the
**IDENTITY MAP** `{1:1,2:2,3:3,4:4,5:5}`.

That map is load-bearing. `getTopicAnswerStats` withholds the agreement line only for topics whose
`rung_map` has ever been non-identity, and its comment states the rule plainly: *"Everywhere else a
value means the position it always meant, which is already the assumption the compass makes when it
scores a voter against an official."* Under that rule a Season 1 climate answer of 3 is counted as a
Season 2 chair 3, i.e. as a permitting-reform position.

▶ **OPEN ITEM, Season 3 / ladder governance:** either v2r3's `rung_map` is wrong and the
climate-change ladder needs a non-identity map (or `invalidated` rungs), or the Season 2 revision
should not have reused version 2's rung numbering. Roughly 1,100 Season 1 climate answers sit behind
this. Nothing in migration 1942 depends on the answer; the group that would have been affected was
withdrawn.

---

## 4 · The seven adjudications

Each rests on the **enacted or introduced text** of the instrument, retrieved and read — never the
title, never a summary, never a news report.

### B · For the People Act → redistricting, FOR and SPONSOR — re-seat 19 from chair 1 to chair 2

All 19 target rows were read in full; each rests on the Act alone.

- chair 1: *"independent citizens' commissions with no elected officials involved at **any** level."*
- chair 2: *"independent redistricting commissions with equal representation from both major parties."*

**§2414(b)** requires each State to appoint a **Select Committee on Redistricting of four sitting
state legislators** — one member of each chamber appointed by the leader of the largest party and
one by the leader of the second largest — and that committee **approves or disapproves the selection
pool** from which every commissioner must be drawn (§2412(b)(1)). Elected officials hold the gate.
**§2411(a)(1)** composes the commission of 15: five majority-category, five minority-category, five
independent — chair 2's limb exactly.

⚖ **§2412(a)(2)** does disqualify officeholders, candidates, party officers, lobbyists and their
immediate families from SERVING. That is a bar on membership, which is what the 19 rows were
reaching for. It is not the absence of elected officials from the process.

🔑 Two of the 19 carry their own refutation: one spells the commission out as *"five Democrats, five
Republicans, and five independents"* and then concludes chair 1; another adds support for Virginia's
2020 constitutional amendment, whose commission is eight legislators and eight citizens.

Text: `https://www.govinfo.gov/content/pkg/BILLS-117hr1eh/html/BILLS-117hr1eh.htm`

### C · For the People Act → redistricting, AGAINST — withdraw all 25

A vote proves the **SIDE**, never the **RUNG**. Opposing a federal bill that would impose
commissions on every State establishes rejection of that mandate; it does not choose between chair 4
(*"state legislatures with court oversight"*) and chair 5 (*"the party that controls the state
legislature without outside interference"*), neither of which the Act proposed.

All 25 were read. Every one performs the inference in its own text — *"his opposition **implies**
preference for state legislative control"*, *"by opposing this reform he **effectively** supports…"*
— and one concedes the member *"has not explicitly advocated for unchecked partisan map-drawing"*
while seating him at chair 5 anyway.

🔴 **The clearest single defect this queue has produced.** Mike Lee was seated at **chair 1**, the
most pro-commission rung, on reasoning that opens *"Lee strongly opposes independent redistricting
commissions"* and quotes him calling an independent commission *"a strategy to give Democrats an
edge they can't win through fair elections."* His own words do put him on the anti-commission side,
but between chairs 4 and 5 they do not choose: he attacks a Utah judge for **drawing** a map rather
than for reviewing one, and separately calls a Virginia Democratic gerrymander *"a naked power
grab"*, which is not the posture of chair 5.

⚠ One row has a genuine argument the other way and is withdrawn anyway: a former Wisconsin Senate
Majority Leader who personally defended the 2011 maps a federal panel called an unconstitutional
gerrymander. That is conduct, not a stated position on who should draw maps — and he defended them
**in court**, which is chair 4's oversight, not chair 5's absence of it.

### D · Safe Communities Act → deportation — withdraw all 25

Already ruled, twice. **Migration 1927** blanked three rows seated at deportation chair 1 on this
Act; **migration 1930** extended it to sanctuary ordinances under the title *"a sanctuary ordinance
cannot seat a deportation chair"*. These 25 are the remainder of that cluster, invisible to the
earlier passes because they serve from Season 1 while those migrations worked Season 2 rows.

The Act limits what **Massachusetts police** may do. The ladder asks **who should be deported**,
which is federal. Chair 2 reads *"only deport people convicted of serious violent crimes"*; the Act
states no removal threshold at all.

🔑 The rows name their own leap: *"ends state and local involvement in civil immigration enforcement
— **effectively** limiting deportation cooperation to serious criminal cases."* Limiting
COOPERATION is a different proposition from limiting REMOVAL.

⚠ The two chair-1 rows do not survive either. One adds a mayor's directive and a city sanctuary
ordinance — same axis. The other adds five ICE bills the member filed (*"get ICE out of families"*,
*"de-ICE Massachusetts law enforcement"*, *"support the pursuit of justice against ICE"*, *"melt ICE
defenses"*, *"uncover ICE"*). **Their texts were not retrievable** from malegislature.gov — the bill
pages carry a title and a committee referral and no text — and every title names the agency's
conduct in Massachusetts, which cannot carry *"stop deportations entirely"*.
▶ If any of those texts is obtained and states a removal position, that row re-seats on it.

⚠ There is a separate **local-immigration** ladder on which this Act is squarely on-axis; where a
member has no such row, the blank leaves a gap to **seed by research**, which is not a reason to
keep an unevidenced chair (migration 1930 made the same call).

### E · Protection of Women and Girls in Sports Act → trans-athletes — re-seat 1 from chair 5 to 4

The Act adds **one** operative subsection, 20 U.S.C. 1681(d): a Title IX violation *"to permit a
person whose sex is male to participate in an athletic program or activity that is designated for
women or girls"*, with sex *"recognized based solely on a person's reproductive biology and genetics
at birth"*, and **(d)(4)** expressly preserving a recipient's ability to let males train or practise
with a women's programme where no female loses a place or benefit.

It reaches women's and girls' programmes only and bars nobody from men's or mixed competition, so
chair 5 — *"completely ban all transgender athletes from competing in any organized sports"* —
overstates it. Chair 4 is the Act almost in the ladder's own words, and 22 colleagues citing the
same Act sit correctly there.

The 2023 (H.R. 734, 118th) and 2025 (H.R. 28, 119th) Acts carry the **same** operative amendment;
both were read, because the outlier cites 2023 and the other 22 cite 2025.
Texts: `BILLS-118hr734eh`, `BILLS-119hr28eh` on govinfo.

### F · Texas HB 229 (89R) → trans-athletes — withdraw all 22

🔑 **A FINDINGS CLAUSE IS NOT AN OPERATIVE PROVISION.** The enrolled Act has three operative
sections:

- **SECTION 2** adds definitions of *"boy"*, *"father"*, *"female"*, *"girl"*, *"male"*, *"mother"*
  and *"sex"* to Government Code 311.005.
- **SECTION 3** adds Government Code 2051.252: a governmental entity collecting vital statistics
  information that identifies sex *"shall identify each individual as either male or female"*.
- **SECTION 4** is the effective date.

**Nothing in the Act regulates athletic participation.** *"Athletics"* occurs only in SECTION 1, the
legislative findings, in a list of contexts — with prisons, shelters, locker rooms and restrooms —
where the legislature finds sex distinctions may be legitimate.

The rows show the leap in two grades. The careful ones call HB 229 *"the **enforcement mechanism**
for sex-based sports eligibility"*, conceding the eligibility rule is somewhere else. The careless
ones assert that it *"bans transgender athletes from competing on teams matching their gender
identity"*, which the enrolled text does not say.

⚠ Texas **does** restrict athletic participation by birth sex — the Save Women's Sports Act
(HB 25, 87R) and SB 15 (88R) — and a member who authored one of those can be seated on it. This
blank says only that HB 229 is not that statute.

▶ An off-axis instrument is wrong at **every** rung, so the 4/5 split that flagged the group is not
resolved by choosing one of them. Both go.
Text: `https://capitol.texas.gov/tlodocs/89R/billtext/html/HB00229F.htm`

### G · Fair Districts for Maryland Act → redistricting — re-seat 21 to chair 2, withdraw 1

The cleanest shape in the queue: **22 sponsors of one bill, near-identical reasoning, split exactly
11/11 between two chairs. Both halves are wrong.**

**§8-7A-05(A)** of HB 482 (2026RS) gives the Commission **ten members, four of them sitting by
virtue of elected office** — the President of the Senate, the Speaker of the House, the Minority
Leader of the Senate and the Minority Leader of the House of Delegates — plus one appointee of each
of those four, plus two gubernatorial appointees subject to unanimous approval of the Senate
Executive Nominations and House Rules committees. Elected officials are a **plurality** of the
commission, so chair 1's *"no elected officials involved at any level"* fails outright.

Chair 4, *"state legislatures with court oversight"*, is further off: proposed **Article XXI §2(B)**
makes the Commission *"the **exclusive means** to adopt any plan"*, displacing the General Assembly
rather than preserving it. ⚠ The eleven rows at chair 4 did not describe a chair at all — they
recorded a **motive** (*"a Republican-led redistricting reform effort opposing Democratic-drawn
maps"*), and a motive is not a position on a ladder.

**Why chair 2:** Article XXI §2(C)(2) constitutes the Commission *"an **independent unit** of State
government"*, and its membership is balanced four-and-four between the two major parties by
construction.

⚖ **Chair 3 was weighed and declined.** Its supermajority limb fits — §8-7A-06(A)(2) requires seven
of ten votes for any plan — but its noun, *"bipartisan legislative **committees**"*, does not,
because §2(B) displaces the legislature instead of working through it.

▶ **One withdrawal.** Jefferson L. Ghrist's row cites only his own member page, and he is not among
the 28 sponsors HB 482 lists on its face (Buckel, Pippy, Adams, Anderson, Arentz, Baker, Beauchamp,
Chisholm, Griffith, Hartman, Hinebaugh, Hornberger, Hutchinson, Jacobs, Kipke, R. Long, Mangione,
McComas, Metzgar, Miller, T. Morgan, Nkongolo, Reilly, Rose, Schmidt, Tomlinson, Valentine, Wivell),
nor on the Senate companion SB 2102. A row whose stated evidence cannot be located is **withdrawn
rather than moved**, because moving it would carry an unverified claim to a new chair. If a
sponsorship in an earlier session is found, it re-seats at chair 2 with the rest.
Text: `https://mgaleg.maryland.gov/2026RS/bills/hb/hb0482F.pdf`

---

## 5 · Gates

| gate | when | result |
|---|---|---|
| `audit-chair-evidence.mjs --csv` | pre-write, on the migration's own notice text | **OK, 41/41** |
| migration guards 1–6 | dry run in a rolled-back transaction, then on apply | **all passed** |
| `audit-chair-evidence.mjs --check` | post-write, 41 re-seats, `season_id`-scoped | **OK, 41 rows — not vacuous** |
| `check:stance-sources` | before and after | **789 across 4 checks, identical. No baseline moved.** |
| `check-instrument-rung-contradictions --sole` | after | 149/1,127 → **142/945** |

🔑 The gate CSV is **generated from the migration's own `$txt$` blocks**, so the text the gate scored
is necessarily the text the migration wrote.

🔑 `--check` carries `"season_id": "86d893a1-…"`. Without it the lookup joins every context row to
every answer row and can judge the untouched **Season 1** row instead of the Season 2 row this
migration inserted — and here every pair has one of each, so that trap was armed for all 41.

🔑 The stance-sources baseline did **not** move, as predicted before applying: all 41 re-seats carry
their Season 1 citations forward unchanged, every one of those URLs has a path, and none is
Ballotpedia-only. So master stays green and no baseline commit is owed.

---

## 6 · Open items

1. ▶▶ **The Inflation Reduction Act group (45 rows) is unresolved and back in the queue.** The 15
   rows resting on the Act plus an LCV score need reading one at a time against H.Res. 109. §3.
2. 🔴 **The climate-change `rung_map` question** — an identity map across a ladder that was
   rewritten to ask a different question, with ~1,100 Season 1 answers behind it. A ladder-governance
   decision, not a stance repair. §3.
3. ⚠ **`--sole` is weaker than its name.** It means one *keyed* instrument. Before adjudicating any
   group, read every member and ask whether the keyer saw all of each row's evidence. Resolutions
   (`H.Res. N`), scorecards and campaign platforms are invisible to it.
4. ▶ **The Safe Communities Act blanks leave a gap.** Several of the 25 have no `local-immigration`
   row, so the co-sponsorship now has no on-axis home. A row to SEED by research, not an
   adjudication. Same shape as migration 1930's residue.
5. ▶ **141 groups covering ~900 rows remain unread.** The next largest are the Climate Solutions Now
   Act (33, climate-change), the Tax Cuts and Jobs Act (33, taxes), the Blueprint for Maryland's
   Future (20, school-vouchers) and the Respect for Marriage Act AGAINST side (20,
   same-sex-marriage). ⚠ The RFMA group is **not** a direction-only blank like the FOR side migration
   1925 worked: most of its rows carry an own-words statement defining marriage as one man and one
   woman, which is chair 5's limb, so it needs a per-row read. Note also that one row at chair 4
   cites votes for a constitutional ban — chair 5 evidence under a chair 4 seating.
6. ⚠ **The trans-athletes pin is not what is served.** Both seasons pin a `superseded` revision and
   the served text is v1 revision 3. Harmless here; check it before judging any trans-athletes chair 3.
