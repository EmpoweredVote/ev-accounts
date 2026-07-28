# Bill adjudication log — WI 2026 state-leg wave

The gate for this wave: for each shortlisted roll call, read the **bill text** and decide whether the
bill is chair-shaped for a specific topic, and which chair a Yes vs a No supports. Adjudicate once
per bill, reuse across every member who voted on it.

Bill text comes from `https://docs.legis.wisconsin.gov/document/proposaltext/2025/REG/<BILL>` — that
endpoint serves **HTML**, not PDF, so the operative language is directly readable. The
`/2025/proposals/<bill>` page carries only the title and history; a WebFetch of it returns a
paraphrase and must not be used as the source.

---

## SJR 2 — photographic ID to vote (2nd consideration)

- Roll calls: `av0004` Assembly 54-45, `sv0003` Senate 17-15
- Triaged topic: `voting-rights`
- Text read: `document/proposaltext/2025/REG/SJR2`

**What it actually does.** Creates Art. III § 1m: "No qualified elector may cast a ballot in any
election unless the elector presents valid photographic identification…" The legislature sets
acceptable forms and *may* establish exceptions. An elector without ID "shall be permitted to cast a
provisional ballot," which is not counted unless ID is presented later.

**Verdict: NOT chair-shaped. Skip.**

Against the `voting-rights` scale:

- Chair **3** ("standardize voter ID requirements **while ensuring free IDs are available to all
  eligible citizens**") — the amendment is silent on free IDs. Second clause unevidenced.
- Chair **4** ("require photo ID for voting **and regularly update voter rolls to remove inactive
  registrations**") — the amendment is silent on roll maintenance. Second clause unevidenced.
- Chair **5** (requires eliminating mail-in voting except military overseas) — the amendment does not
  touch absentee voting at all.

"Require photo ID" is a clause **shared** by chairs 3, 4 and 5; nothing in the bill discriminates
between them. Two adjacent chairs both fit, so the rule is to skip. A No vote rules out the
restrictive end but still leaves {1, 2, 3} — also not pinnable.

Worth noting this is the single most obviously on-topic divided vote in the whole corpus, and it
still pins nothing. That is the point of the gate.

---

## AB 24 — county sheriff assistance with federal immigration functions

- Roll call: `av0026` Assembly 51-43 (vetoed 2026-04-03; override failed 2026-05-13)
- Triaged topic: `immigration`
- Text read: `document/proposaltext/2025/REG/AB24`

**What it actually does.** Requires sheriffs to request proof of lawful presence from individuals
confined in county jail "for an offense punishable as a felony", and to comply with DHS detainers and
administrative warrants for individuals held for a criminal offense. Annual certification to DOR;
non-certifying counties lose **15% of shared revenue**. Recordkeeping to DOJ.

**Verdict: NOT chair-shaped, and MIS-TRIAGED. Skip.**

First, the triage put this on `immigration`, whose scale axis is legal-immigration levels and access
to public services. The bill addresses neither — it is an enforcement-cooperation bill. The keyword
`IMMIGRA*` fired on "federal immigration functions" while the `deportation` keywords
(`DEPORTATION`, `IMMIGRATION ENFORCEMENT`, `SANCTUARY`) all missed it. **Triage topic assignment is
itself un-adjudicated and has to be re-decided at this step, not inherited.**

Re-adjudicated against the correct-axis topic, `deportation`:

- Chair **2** ("Only deport people convicted of serious violent crimes") — the bill reaches felony
  *charges*/confinement, not convictions, and is not limited to violent offences.
- Chair **4** ("Deport everyone without legal status, **starting with those who have criminal
  records**") — the "starting with criminal records" mechanism matches, but the bill nowhere reaches
  "everyone without legal status".

Both clauses fail on scope. Chairs 2 and 4 are each partly compatible and neither is fully
evidenced, so the bill pins neither.

---

## Running tally

| bill | roll calls | triaged topic | chair-shaped? | outcome |
|---|---|---|---|---|
| SJR 2 | av0004, sv0003 | voting-rights | no | skip — clause shared across chairs 3/4/5 |
| AB 24 | av0026 | immigration → deportation | no | skip — mis-triaged, then scope clause unevidenced |

**2 of 2 adjudicated so far are not usable.** n=2 is far too small to extrapolate a rate from, and
these two were picked *because* they looked like the strongest candidates — which biases toward
prominent, contested, and therefore broadly-worded measures. Narrower bills may well fare better.
But it does say the conservative yield estimate in `WAVE_PLAN.md` §4 is the right one to plan
against, and that no wave should be sized on the assumption that a divided on-topic vote produces a
stance.
