# gun-policy — Season 3 draft, revision 4 (v3 r4, Draft B, CA_0338)

**Revision 4:** not yet applied. CA_0338 proposes and approves it (approved and parked) and pins it in the draft
Season 3. The revision id is filled in on apply.

**Status:** drafted 2026-10-30 in the Stage 4 package of the season-topic-prep skill (research folder
`~/Documents/GitHub/.planning/research/s3-prep-gun-policy/`). The Season 2 annex (`../gun-policy.md`) stays as it is
for Season 2 rows. Rulings by Chris Andrews: R0a-1, census Q1, J1–J8, Stage 2 Q1–Q7 (2026-10-29); D1–D4 and P1
(2026-10-30); the Stage 4 package (2026-10-30).

**Question:** "How should the government regulate firearms?"

**Guidance (voters see it):** "Where the balance falls between access to firearms and restrictions meant to reduce
harm."

**Spectrum (L1):** how far the law restricts civilian guns. Pole 1: "Civilians may not own guns, except licensed
hunting or sport guns". Pole 5: "No permit or registration is needed to own or carry a gun". Stored as the first line
of the revision's rationale; not shown to voters yet.

**Orientation:** standard. Rung 1 is the most restriction, rung 5 the least. Rungs 1–3 add restrictions; rungs 4–5
remove them.

**Levels with a lever:** federal, state; local only where state law allows a local gun rule (most states forbid
one). **Asked at:** federal, state, local (`compass_topic_roles`). Local records support own words and never seat
alone (RULINGS.md "Local records support own words, never seat alone").

**Synonyms:** "assault weapon", "assault-style", "semi-automatic", "large-capacity magazine", "universal background
checks", "private sale", "gun-show loophole", "transfer", "red flag" / "extreme risk protection order", "minimum age",
"permit to purchase" / "licence to buy", "concealed carry", "permitless carry" / "constitutional carry",
"reciprocity", "must-issue" / "shall-issue", "National Firearms Act" (NFA), "registration", "ghost gun".

**Rungs:**
1. Ban civilian gun ownership, except with a licence for hunting or sport.
2. Ban a type of firearm or magazine, such as assault-style weapons.
3. Limit who may have a gun, such as by checking every buyer or by court orders that take guns from a person found
   dangerous.
4. Make carrying a gun easier, such as honoring carry permits from other states.
5. Repeal laws that require a permit or registration for a gun, such as the permit to carry.

**Rung map from revision 3:** identity (1→1 … 5→5).

**Reading.** Each rung is one kind of gun law, ordered from the most restriction to the least. A record acts on one
object — which guns, who may have one, or carrying — and a person sits at the **furthest act** their record states.

**Scope line — "firearms law".** On-question: a law that bans civilian ownership or a type of firearm or magazine; a
law on who may buy, receive or keep a gun; a law that widens where or how a person may carry; a law that repeals a
permit, licence or registration requirement. Out of scope → `adjacent` (codebook V2): rules on how guns are stored,
marketed, advertised, taxed or insured; dealer business rules; research funding; sentencing for crimes committed with
a gun; school-safety measures; and a law that only decides which level may set gun rules (preemption, V2 / H12),
since no rung is about which level decides (see Q5 for the one exception).

## Lines for every rung

- **Furthest act.** A record that states the acts of two neighbouring rungs sits on the rung of its furthest act;
  each lower act must still be stated, and nothing is inferred from silence. Acts from both sides of the middle (a
  restriction from rungs 1–3 and a loosening from rungs 4–5) in one record → BLANK `adjacent-chairs`. Across a
  person's records, the newest governs only where it contradicts an older one (V5 `superseded-by-later`); two records
  on different objects on the same side are read together under furthest act.
- **Rung 1** needs a stated ban on civilian ownership of firearms in general (a licence exception for hunting or
  sport is allowed and need not be stated). A ban on one type, however wide its list → 2. No record is known at any
  level; own words are the likely route.
- **Rung 2** needs a ban on the sale, transfer or possession of a type of firearm or magazine defined in the text (by
  features, by a list, or by capacity). The definition is the boundary; no clause about other firearms is needed. A
  bill that extends an existing type ban to more weapons → 2. A grandfather clause or registration of weapons
  already owned does not move the record off 2. A **magazine-capacity ban** alone → 2 (Q3, ruled 2026-10-29; replaces
  the Season 2 line that sent it to `direction-only`).
  - **D1 (ruled 2026-10-30).** A type ban with a route to buy for a person who completes a state course and a check
    (Colorado SB25-003, 2025) is a type ban → 2. The route is an exception the law states, not an escape open to
    everyone (V4.2).
- **Rung 3** needs a law that adds a condition on **who** may buy, receive or keep a gun: a background check on any
  set of sales (every sale, gun shows, private sales, buyers under 21); a court order that removes guns from a person
  found to be a danger (extreme-risk or red-flag orders; surrender orders tied to domestic-violence findings); a
  minimum age to buy or possess; a licence or permit to buy. A check that only restates the federal dealer check →
  `no-evidence`.
  - Rules that apply to every buyer alike and do not decide who (waiting periods, limits on how many guns a buyer may
    buy in a period) are not rung 3 → `direction-only` (restriction side). Storage rules → `adjacent`.
  - A law that adds a red-flag order and widens carry (both sides of the middle) → BLANK `adjacent-chairs`.
  - **D2 (ruled 2026-10-30).** A rule that makes agencies report records to the background-check system (Fix NICS) is
    record-keeping, not a rule on who may have a gun → not a rung 3 act. The 2017 House reciprocity bill (H.R.38,
    115th), which carried it, stays on 4.
  - **D4 (ruled 2026-10-30).** A notice from the background-check system to immigration enforcement about a failed
    check (H.R.8, 116th, 922(t)(3)(E)) routes a check for a person the gun law already bars. It is not `deportation`
    evidence, so the bill stays single-subject, rung 3.
- **Rung 4** needs a law that widens where, or by whom, a gun may be carried, while a permit or licence system stays
  in place: honoring other states' carry permits or carry rights; allowing carry in places it was barred (campuses,
  places of worship, public buildings); requiring officials to issue a carry permit to anyone who meets the stated
  criteria. A law that honours another state's carry rights is rung 4 even where the home state needs no permit: it
  repeals no permit law. A federal law that sets this rule for every state is `on-question`: it states the carry
  rule, not only which level decides.
  - **D3 (ruled 2026-10-30).** Protection for carrying an unloaded, locked gun through a state between places where
    it is lawful (18 U.S.C. 926A, as in S.Amdt 715, 2013, Sec. 128) does not widen where a gun may be carried → not a
    rung 4 act. S.Amdt 715 stays on 3.
- **Rung 5** needs a law that repeals a permit, licence or registration requirement for owning, buying or carrying a
  gun: removing the permit to carry for adults; removing a type of firearm or accessory from a registration law. A
  state law that removes its own carry permit → 5 (it also widens carry; furthest act). A minimum carry age that the
  permit-removal law sets on its own permit-free carry is part of the rung 5 act, not a rung 3 act (closure C3).
  - **Q5 (ruled 2026-10-29; topic-scoped).** A federal bill that bars states from requiring a carry permit → 5. It
    states the carry rule, so it is on-question despite codebook V2 / H12 (preemption). For this topic only.
  - **Q4 (ruled 2026-10-29).** Repeal of a type ban, a waiting period or a minimum age matches no rung →
    `direction-only` (loosening side).

## Hard cases

- **Status quo (Q2, ruled 2026-10-29).** No rung states "keep current law". A vote or a bare statement to keep
  current law, or against a new restriction, shows a side only → `direction-only`. Not finding a rung 5 record is not
  evidence for rung 4 (V4.2). **But** own words that back the person's **own jurisdiction's current gun law** place
  them on the rung of the furthest act that law states, read from the statute in force at the statement's date (a
  state with a type ban in force → 2; a state that has removed its carry permit → 5). Describing the law, or citing it
  only to oppose a new bill, does not count. Where the law in force states no rung act (current federal law: no type
  ban, checks on dealer sales only, permits left to states), or states acts from both sides of the middle, the record
  stays `direction-only` / `adjacent-chairs`. (Same reading as voting-rights W3-R8; RULINGS.md line proposed.)
- **Home-made and unserialised firearm rules (Q6, ruled 2026-10-29)** regulate how a gun is made or marked, not
  which type is banned or who may have one → `direction-only` (restriction side). Expected Stage 5 "doesn't fit"
  theme.
- **A No vote** on any firearms bill → BLANK `direction-only` (V4.1).
- **Single-subject (codebook V4.1; replaces the Season 2 line "budget and omnibus votes with a firearms item →
  multi-subject").** A firearms bill is `multi-subject` only when an operative part other than the firearms part
  would be V2 `on-question` evidence for **another topic served in the season being coded**. Parts that are
  `adjacent` here (storage, dealer rules, research money) do not make it multi-subject. Record the season's
  served-topic list and the codebook version with the verdict.
  - **A law's own penalty (census Q1, ruled 2026-10-29; general).** A penalty for breaking the bill's own gun rule is
    part of that rule. A separate sentence change for another crime makes the law multi-subject while
    `judicial-criminal-justice` is served.
  - **Self-defense parts (J7, ruled 2026-10-29; topic-scoped).** A no-duty-to-retreat change or a
    justifiable-homicide line (MO SB 656; MS HB 786) defines when force is lawful; it is not evidence for
    `judicial-criminal-justice`, which is about the response to lawbreaking. Such a law stays single-subject.
  - A section that bars state enforcement of federal rules judged unconstitutional is not on-question for any served
    topic (closure C2). A suicide-prevention fund is not `healthcare` access evidence (closure C4).
- **Higher-law duty.** Congress and state legislatures have more than 10 voting members, so only the 10%-No rule
  applies (gate `near-unanimous`). Local bodies of 10 or fewer: where state law forbids local gun rules, a council
  vote to repeal or amend its own ordinance to comply carries out a higher-law duty → `direction-only` (gate
  `higher-law-duty`). Standing duties: state preemption of local firearms rules (most states); federal dealer checks
  already required on dealer sales (a law that restates them is not a rung 3 act).
- **Records.** One record per instrument per chamber: its final vote. Where a veto override fails, the chamber's last
  passage or concurrence vote is the record (J6, ruled 2026-10-29; VA SB 2 2024 Senate, 2024-03-01, 21–19).

## Open for the next revision (rung backlog, P1 ruled 2026-10-30)

Kept in `preview/rung-backlog.md` of the research folder; none is ruled yet, and coders apply the lines above:
votes to cancel a federal agency gun rule (pistol braces); "no new limits" with no step to loosen; mixed records on
both sides of the middle across a person's records; a permit removal in vehicles only (4 or 5); title-only seats
(fetch bill text before Stage 5 writes); a cheaper carry permit (fee cut). Voters did not place "raise the age to 21
and add a waiting period" or "a licence to buy" on rung 3 (T7 24/30): Draft B seats those laws; its wording does not
yet show them to voters.
