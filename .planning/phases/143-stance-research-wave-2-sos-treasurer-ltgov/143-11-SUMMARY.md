# 143-11 SUMMARY — Phase-143 gate (verify-phase-143.sql)

**Status:** ✅ Complete — gate runs GREEN against prod, all assertions PASS (psql exit 0).

## Result
`backend/scripts/verify-phase-143.sql` — read-only labeled-assertion gate, keyed on `(district_type='STATE_EXEC', role_canonical IN ('secretary_of_state','treasurer','lt_governor'))`, NEVER external_id ranges. Run: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-143.sql`.

Assertions (all PASS, prod-verified 2026-06-21):
- **SEXS-02e** — SoS coverage = 34 (31 wave-2 + 3 pre-stanced; SC SoS Hammond -4500004 honest-skip).
- **SEXS-02f** — Treasurer coverage = 34 (30 wave-2 + 4 pre-stanced; 4 honest-skips; incl. FL CFO + NY/TX Comptroller mapped to treasurer).
- **SEXS-02g** — Lt Gov coverage = 39 (33 wave-2 + 6 pre-stanced; 4 honest-skips; AZ LtGov deferred per Prop 131).
- **SEXS-02-skip** — the uncovered in-scope set is EXACTLY the 9 documented whole-record honest-skips (belt-and-suspenders, USHS-14a pattern), pinned by exact external_id: Hammond -4500004 (SC SoS); Boozer -100005 / Metcalf -2100005 / McRae -2800005 / Haeder -4600005 (Treasurers); Cournoyer -1900002 / Kelly -3100002 / Tressel -3900002 / Pinnell -4000002 (LtGovs).
- **SEXS-02h** — zero-unsourced: 0 Wave-2-role answer rows lack an http-sourced paired context row.
- **SEXS-02i** — scope hygiene: role_canonical join key populated for all answered execs.

## Phase 143 totals
- **103 in-scope unstanced execs → 94 covered + 9 documented whole-record honest-skips, 0 unsourced.**
- Wave-2 coverage across all three roles: SoS 34 / Treasurer 34 / LtGov 39 = **107 total covered** (94 wave-2 + 13 pre-stanced).
- 10 batch dirs `backend/data/stance-research/exec-w2-batch-{a..j}/`; plans 143-01..10 + this gate committed.

## Notes
- Authoring caught one self-inflicted bug: the SEXS-02-skip `v_expected` string initially had the wrong sort order vs the query's `ORDER BY role_canonical, external_id` — fixed (data was always correct; assertion now matches). Lesson: when pinning an ordered set in a gate, match the exact ORDER BY in the expected literal.
- The 9 honest-skips are all genuine: ceremonial/no-record LtGovs (Tressel ex-football-coach, Kelly career-prosecutor, Pinnell withdrew, Cournoyer IA-legislature-walled) and businessman/dead-source Treasurers (Boozer, Metcalf, McRae, Haeder) + ministerial SC SoS (Hammond). All confirmed on re-research.
- Phase 144 (consolidated `verify-phase-141-144.sql` + feed smoke-test) will absorb these Wave-2 assertions.
