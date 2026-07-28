# WI state-leg wave — overnight handoff (2026-07-28)

**No database writes were made.** Everything here is files + read-only queries. Nothing is committed
to git either — the new scripts are untracked in `backend/scripts/`.

## What got done

1. **Scoped the gap against prod.** 132 seats, all occupied; 22 stance answers across 11 people;
   1 headshot. 2026 field is 256 candidates, 247 at zero stances. See `WAVE_PLAN.md` §1.
2. **Verified the topic scale.** All 44 UUIDs in `_TOPIC_SCALE_FULL.txt` match prod exactly and
   `inform.topic_rewrites` is empty — but the *applicable* set for a state legislator is the **26**
   topics prod scopes to `role_scope='state'`, not all 44. §2.
3. **Exported the roster** — `roster_full.csv` (256), `roster_contested.csv` (60),
   `roster_incumbents.csv` (132), via `scripts/gen-wi-2026-stateleg-roster.mjs`.
4. **Built the evidence layer** — 132 members, 38,478 member-vote rows, 60,148 authorship rows,
   562 roll calls with subject headings and tallies. All free, no API spend.
5. **Cross-checked occupancy** — prod's `office_current_holder` agrees with the WI Legislature
   roster on **132/132 seats**.
6. **Verified headshots** — all 132 official roster JPEGs download as distinct valid images.
7. **Triaged roll calls to topics** and found the real ceiling: **48 usable** of 562.
8. **Adjudicated 2 bills end-to-end** as a method reference — both came out unusable.
   `ADJUDICATION_LOG.md`. Progress: 3/48 rows.

## The two things that change your plan

**Candidates are already seeded.** All 256 WI state-leg candidates for the Aug 11 primary exist with
resolved `politician_id`s. "Candidates next, then their stances" collapses to just stances — and
headshots.

**The evidence ceiling is much lower than the corpus size suggests.** 38,478 votes sounds rich; only
48 roll calls are divided *and* substantive *and* on a state-scope topic, and both bills I adjudicated
failed the chair-shape test. 10 of 26 topics have no roll-call route at all, and 159 of 256 candidates
are challengers with no voting record. Plan for sparse, honest compasses.

## DONE since this handoff was first written (2026-07-28, later the same day)

- **Wave 0 headshots — SHIPPED.** Migration **1482**, `132/132` sitting legislators (was 1/132).
  56 high-res member-site portraits + 76 official roster portraits. Verified: 132 distinct CDN URLs
  all serving an image, all with `photo_origin_url`. Visual reject list for the 23 unusable
  member-site candidates is tracked at `wi-headshot-visual-rejects.json`.
- **AD55 name corrected.** Migration **1483**: `Gus Gustafson` → `Nate Gustafson`, official middle
  initial recorded, the real nickname preserved in `alternate_names`, and
  `full_name_manual_override = true` so the `openstates-v3-wi` sync cannot revert it.
- Committed and pushed through `846021a3`; all Render deploys green.
- **26-topic state scope confirmed** as the rule for this wave (see `WAVE_PLAN.md` §2).

## PAUSED HERE — 2026-07-28

Stances were deliberately not started. Nothing is half-applied: no partial prod writes, no
uncommitted work, no stance rows added beyond the 22 pre-existing Madison-delegation rows.

**The clock:** the WI partisan primary is **2026-08-11**. Wave 1 (24 contested primaries / 60
candidates) is the only time-boxed piece; after Aug 11 the field shrinks to the general and the
pre-primary window is simply gone. Everything else here is not date-gated.

## CALIBRATION BATCH DONE — 2026-07-28

8 more bills adjudicated to measure whether the incumbent roll-call route is worth a full pass
before committing to it. **3 of 12 roll calls usable — a 25% survival rate** — but the yield per
bill is high, because one chair-shaped bill pins a chair for **every Yes voter at once**:

| bill | roll calls | topic | verdict |
|---|---|---|---|
| AJR 102 | av0137, sv0140 | civil-rights | **Yes → chair 5** |
| AB 840 | av0182 | data-centers | **Yes → chair 2** |

Those alone yield **125 stance rows across 74 of 132 legislators**, ~12.5 rows per bill read.

**The predictive rule.** A bill is chair-shaped when its ENTIRE PURPOSE is to set a posture on the
topic — constitutional amendments and comprehensive regulatory frameworks. Both survivors are that
shape. All nine failures are narrow provisions, sentencing enhancements, definitional carve-outs, or
administrative omnibuses, even when squarely on-topic.

**Three systematic dead ends** (full reasoning in `wi-rollcall-adjudications.json`):

1. **Narrow tax bills cannot pin the `taxes` chair.** That scale measures overall tax-and-spend
   posture; a cash-tips exemption fails chair 4's "for everyone AND scale back services" and fails
   chair 3's "close unfair loopholes". Likely disqualifies most of the 16-row taxes bucket, the
   largest topic in the pool.
2. **State bills on immigration are structurally unwinnable.** `immigration` chairs 4/5 and
   `deportation` chair 4 all lead with a legal-immigration-levels clause no state legislature can
   act on, so two adjacent chairs always fit equally on the surviving clause.
3. **Keyword triage finds topical WORDS, not AXES.** 3 of 8 were on the wrong axis entirely — a
   gender-transition medical ban on the trans-athletes SPORTS scale, a drug-sentencing enhancement
   on the homelessness PUBLIC-CAMPING scale. **Re-decide the topic at adjudication, never inherit
   it.**

Also added 4 procedural patterns the classifier missed (`REFER TO COMMITTEE`, `LAY ON TABLE`,
`SUSPENSION OF A RULE`, `SERGEANT AT ARMS`), correctly removing 7 rows. **Pool is now 41, with 29
left to adjudicate.**

## Open questions on resume

1. **Push the 125 rows from the 2 usable bills?** Nothing is written yet. This is the cheapest real
   stance coverage available: 74 of 132 legislators get a first chair, sourced to a named
   chair-shaped bill and their own recorded vote. Would go as a tracked `push_*.sql` in this dir.
2. **Continue adjudicating the remaining 29?** Skip the taxes bucket first given dead end #1 — that
   is most of what remains, so realistic additional yield is low. Prioritise constitutional
   amendments and comprehensive frameworks, which is where both survivors came from.
3. Wave 1 scope: "all 60 candidates, thin" or "the 6 contested incumbent races, deep"? 44 of the 60
   are challengers with no voting record. **Note the Aug 11 primary has likely passed by the time
   this is read — re-check before planning around it.**
4. Optional quality follow-up: 76 of the 132 headshots came from a 150×200 source and are visibly
   softer. Sharpening them means a per-member portrait hunt with the same visual review loop.
   Pipeline is now tracked: `scripts/seed-wi-legislature-headshots.py` +
   `scripts/verify-wi-headshot-person-match.mjs`.

## Files

```
WAVE_PLAN.md                    the plan, with measured numbers and every trap found
ADJUDICATION_LOG.md             worked bill adjudications + method reference
roster_full.csv                  256 candidates on the 2026-08-11 primary ballot
roster_contested.csv             60 in contested primaries
roster_incumbents.csv            132 sitting members (35 not on the 2026 ballot)
wi_legis_members.csv             roster + official headshot URLs
wi_legis_votes.csv               38,478 member-vote rows
wi_legis_authored.csv            60,148 authorship rows
wi_rollcalls.csv                 562 roll calls w/ subject headings + tallies
wi_rollcall_topic_triage.csv     the adjudication worksheet (3/48 done)
wi_divided_votes.csv             earlier bill-keyed cut; superseded by wi_rollcalls.csv
wi_headshot_probe.csv            HEAD-check results for all 132 headshots
```

New scripts in `backend/scripts/`: `gen-wi-2026-stateleg-roster.mjs`,
`scrape-wi-legis-members.mjs`, `scrape-wi-rollcalls.mjs`, `triage-wi-rollcalls-to-topics.mjs`.
