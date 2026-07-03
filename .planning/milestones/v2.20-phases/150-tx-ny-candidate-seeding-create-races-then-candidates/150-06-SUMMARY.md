# 150-06 SUMMARY — NY headshots

**Status:** ✅ Complete (6 imaged; 27 documented honest-skips, gate-pinned)
**Wave:** 4
**Artifact:** reused `backend/scripts/seed-tx-ny-house-headshots.py --state NY` (created in 150-05)

## NY result (33 new candidates)

- **6 auto-imaged** from Wikipedia (free-license, identity-verified):
  - Peter Oberacker NY-19 (-3611901, cc-by-2.0) — NY state senator
  - Micah Lasher NY-12 (-3611201, public_domain) — NY assemblyman
  - Brad Lander NY-10 (-3611001, cc-by-4.0) — NYC Comptroller (lost-primary winner)
  - Claire Valdez NY-7 (-3610701, cc-by-4.0) — NY assemblywoman
  - Mike LiPetri NY-3 (-3610301, cc-by-sa-4.0) — former NY assemblyman
  - Chris Gallant NY-1 (-3610101, cc0) — Army veteran/air-traffic-controller; identity confirmed via Wikipedia (won 6/23 primary)
- **27 documented honest-skips** — obscure NY challengers + minor-line candidates (incl. Bob Cohen, Robert Smullen, Darializa Avila Chevalier) with no discoverable free-license portrait. Pinned by external_id in `scripts/150-verify.sql` USHC-04 (ORDER BY external_id). No wrong-person/copyrighted image used.

## Gate status

**USHC-04 now PASSES** (11 total imaged across TX+NY: 5 TX + 6 NY; 70 gate-pinned honest-skips: 43 TX + 27 NY). Confirmed by full gate run: USHC-02/03/04 + D-02/D-05 all green. USHC-05a (0 unsourced) passes trivially pre-stance; USHC-05b correctly fails (107 in-scope candidates await stances — Waves 150-07..11).

## 27 NY honest-skip external_ids (gate-pinned, ORDER BY external_id)

-3612601, -3612501, -3612401, -3612301, -3612201, -3612103, -3612102, -3612101, -3612001, -3611801, -3611701, -3611601, -3611501, -3611401, -3611303, -3611302, -3611301, -3611202, -3611101, -3611002, -3610901, -3610801, -3610702, -3610601, -3610501, -3610401, -3610201

## Follow-up

Same as 150-05: a dedicated manual free-license-sourcing pass for the 70 skips (43 TX + 27 NY) is available as a future task; USHC-04 passes via documented gate-pins now.
