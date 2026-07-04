# 159-04 SUMMARY — VA new-candidate headshots + federal-24 stances + 3 thin-incumbent top-ups

**Status:** ✅ COMPLETE (both tasks; 0-unsourced gate green for the batch)
**Executed:** 2026-07-01/02 (inline — headshot pipeline + politician-stance-researcher ≤3 concurrent)

## Task 1 — Headshots (6/46)

`backend/scripts/seed-va-house-headshots.py` (band -511199..-510101). **6 uploaded, 40 honest-skip.**
- Auto (4): Bob Good, Tom Perriello, Elaine Luria, Randall Terry.
- Manual (2): Bree Fram (PD military photo), Beth Macy (CC BY 4.0). Manual file `159-04-va-headshots.manual.txt`.
- 40 honest-skips = down-ballot challengers with no free-license image (precedent 155:8/37, 157:1/15). Idempotent.

## Task 2 — Federal-24 stances (0 unsourced)

Pipeline: `politician-stance-researcher` ≤3 concurrent, chairs-not-polarity, WebFetch-only; CSVs in `backend/data/stance-research/va-2026-house/`; repaired via `_repair_batch.mts` (relax-parse + canonical re-stringify + federal-24 filter, 2 stray `data-centers` rows dropped); pushed by external_id via `_push.ts`. **256 answers for the batch, 0 unsourced.**

**24 VA new candidates stanced** (partial-to-full):
Bob Good 18, Elaine Luria 17, Tom Perriello 15, Beth Macy 14, Ericka Kopp 14, Melanie Lucero 14, Mo Seifeldein 13, Tim Cywinski 12, Jason Knapp 10, Randall Terry 10, Philip Harding 9, Joy Powers 9, Robert Tracinski 9, Shannon Taylor 8, Elizabeth Beggs 7, Bill Fleming 7, Bree Fram 6, Lorena Bruner 6, Tony Sabio 6, Dave Beckwith 5, Michael Duffin 4, Nila Devanath 3, Salaam Bhatti 3, Julie Perry 2.

**~~22~~ → 9 VA whole-record stance skips** (CORRECTED by 2026-07-02 spot-audit — see addendum; pinned for gate):
-511103 Nathan Headrick (site down, no survey, launch boilerplate only) · -511003 Anthony Suttles ($0 campaign, site under construction) · -510906 Michael Jackson (VA-9 indep; site 503; priorities off-scale) · -510905 Brandon Cook (WITHDREW pre-primary, $0) · -510902 Brandi Hall (WITHDREW pre-primary, $0) · -510401 Andre Kersey (site live but values-only) · -510302 James "Zeb" Taylor (campaign domain lapsed, dormant) · -510206 Bishop Staten (only evidence = local revenue-office race; force-fit row deleted per Waters precedent) · -510205 Makiba Gaines (site is bio+slogan only).

**2026-07-02 SPOT-AUDIT ADDENDUM (post-MI false-skip lesson):** all 22 pinned skips were re-researched with the domain-discovery playbook (DDG-via-jina, `[name]forcongress`-style guesses, BallotReady, r.jina.ai-proxied Ballotpedia). **13 of 22 were FALSE skips** — real fetchable records existed. Corrected + pushed (67 rows, 0 unsourced; VA new-candidate band now **37 stanced / 288 rows**): Tull 9, Brown II 10, Dunigan 8 (adam4congress.com), Ollivant 6 (dougforvirginia.com), Mosolf 6, Register 6 ("Bill of American Renewal" PDF), Murphy 5 (murphy4va.com), Krzyzanowski 4 (drkforcongress.com + Cville Tomorrow Q&A), Crockett 4 (crockettnow.com), Rivera 3, Roma 3, Smithers 2 (JS-SPA site needs r.jina.ai), Van Meter 1.
**NEW ballot-status flags → 159-05 cull:** Amy Roma -511102 WITHDREW (Ballotpedia; ~$1.28M raised/spent, $0 CoH) · Michael Van Meter -511104 WITHDREW from GOP primary · Brandon Cook -510905 WITHDREW · Brandi Hall -510902 WITHDREW (active VA-9 D field = Crockett/Murphy/Powers). Root causes mirrored MI: rate-limited pre-crash session + unguessable campaign domains.

**3 thin-incumbent top-ups** (existing records, researched only lacking topics — no overwrite of pre-existing sourced answers):
- Vindman -5102007: 1 → **12**
- Subramanyam -5102010: 1 → **12**
- McGuire -5102009 (NOT -5102005 — the plan/CONTEXT external_id was transposed; -5102005 is Cline w/15): 2 → **11**

The other 8 VA incumbents were left as-is (partial), untouched.

## ⚠ Cull findings for 159-05 (surfaced during research — NOT acted on here)

- **Bree Fram (-511101) WITHDREW from VA-11 on 2026-05-13** (after the VA redistricting-map ruling). Her 6 stances remain as valid data; mark `withdrawn` at the cull.
- **VA-11 Democratic primary may be uncontested** — Fairfax County BoE shows no VA-11 D primary; vademocrats lists Walkinshaw as unopposed nominee. Amy Roma "not listed in any Virginia district." So the seeded VA-11 D challengers (Fram/Roma; Pekarsky reused) likely all withdrew/failed to qualify. **Reconcile the VA-11 D field against official results at 159-05.**

## Verification notes

- Primary-source spot-verified the validation batch (Good/Luria) by re-fetching cited URLs — confirmed genuine. Bob Good abortion=4 kept (source shows strong anti-abortion but not the documented no-exceptions+criminal-penalties a 5 requires).
- Vindman voting-rights=2 is lightly inferential (SAVE Act opposition via LCV + campaign platform; specific floor vote not directly confirmed) — retained on real source chain; flag if the gate wants it stricter.

Scripts: `backend/scripts/seed-va-house-headshots.py`, `backend/data/stance-research/_repair_batch.mts`, `backend/data/stance-research/va-2026-house/{*.csv,_push.ts}`.
