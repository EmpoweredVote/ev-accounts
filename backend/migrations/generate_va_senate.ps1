# generate_va_senate.ps1
# Generates migration 307: Virginia State Senate (40 senators)
# No vacant seats. [VERIFIED: apps.senate.virginia.gov, 2026-06-08]
#
# Adapted from generate_md_senate.ps1 with 7 VA-specific substitutions:
#   1. FIPS prefix '51' (not '24') for geo_id construction
#   2. 'Virginia Senate' / 'State of Virginia' / AND state = 'VA' in government subquery
#   3. d.state = 'va' (lowercase) for STATE_UPPER district lookup
#   4. p.id IS NOT NULL guard on CROSS JOIN (retained from MD senate pattern)
#   5. representing_state = 'VA' (not 'MD')
#   6. external_id range: -5110001 (SD-1) through -5110040 (SD-40)
#   7. geo_id format '51' + dist.PadLeft(3, '0')  e.g. SD-1 -> '51001', SD-40 -> '51040'
#
# Source analogs: 273_md_state_senators.sql, generate_md_senate.ps1
# Phase: 101 (VA State Government DB)
# Requirement: VA-GOV-03
#
# CRITICAL: d.state = 'va' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER
# CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 51001-51040 exist in BOTH
#           STATE_UPPER and STATE_LOWER (100% overlap); omitting district_type causes 2 offices per senator
# CRITICAL: Idempotent - ON CONFLICT (external_id) DO NOTHING; NOT EXISTS (district_id, chamber_id)

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/307_va_state_senators.sql"
)

function EscSql([string]$s) { $s.Replace("'", "''") }

function SenatorBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '51' + ([int]$r.dist).ToString().PadLeft(3, '0')
@"
-- ===== SD-$($r.dist) ($gid): $($r.full) ($($r.party)) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '$f', '$fn', '$ln', '$pa',
          true, false, false, true, $($r.ext_id))
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Virginia Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Senator', 'VA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_UPPER' AND d.state = 'va'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Virginia Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Virginia' AND state = 'VA'))
  );

"@
}

# 40-entry roster [VERIFIED: apps.senate.virginia.gov/Senator/districtdesclist.php + Wikipedia, 2026-06-08]
# Party: 21 Democrats, 19 Republicans. No vacancies.
# Name parsing: suffix (Jr., III) dropped from last; hyphenated names count as one token
# SD-33 Carroll Foy: last='Foy' (final word per MD compound rule)
# SD-39 Bennett-Parker: last='Bennett-Parker' (hyphenated = one token)
# SD-24 J.D. "Danny" Diggs: embedded double-quotes are literal in SQL single-quoted string
$roster = @(
    @{ dist=1;  ext_id=-5110001; full='Timmy French';                    first='Timmy';          last='French';            party='Republican' }
    @{ dist=2;  ext_id=-5110002; full='Mark D. Obenshain';               first='Mark D.';        last='Obenshain';         party='Republican' }
    @{ dist=3;  ext_id=-5110003; full='Christopher T. Head';             first='Christopher T.'; last='Head';              party='Republican' }
    @{ dist=4;  ext_id=-5110004; full='David R. Suetterlein';            first='David R.';       last='Suetterlein';       party='Republican' }
    @{ dist=5;  ext_id=-5110005; full='T. Travis Hackworth';             first='T. Travis';      last='Hackworth';         party='Republican' }
    @{ dist=6;  ext_id=-5110006; full='Todd E. Pillion';                 first='Todd E.';        last='Pillion';           party='Republican' }
    @{ dist=7;  ext_id=-5110007; full='William M. Stanley, Jr.';         first='William M.';     last='Stanley';           party='Republican' }
    @{ dist=8;  ext_id=-5110008; full='Mark J. Peake';                   first='Mark J.';        last='Peake';             party='Republican' }
    @{ dist=9;  ext_id=-5110009; full='Tammy Brankley Mulchi';           first='Tammy';          last='Brankley Mulchi';   party='Republican' }
    @{ dist=10; ext_id=-5110010; full='Luther H. Cifers, III';           first='Luther H.';      last='Cifers';            party='Republican' }
    @{ dist=11; ext_id=-5110011; full='R. Creigh Deeds';                 first='R. Creigh';      last='Deeds';             party='Democrat' }
    @{ dist=12; ext_id=-5110012; full='Glen H. Sturtevant, Jr.';         first='Glen H.';        last='Sturtevant';        party='Republican' }
    @{ dist=13; ext_id=-5110013; full='Lashrecse D. Aird';               first='Lashrecse D.';   last='Aird';              party='Democrat' }
    @{ dist=14; ext_id=-5110014; full='Lamont Bagby';                    first='Lamont';         last='Bagby';             party='Democrat' }
    @{ dist=15; ext_id=-5110015; full='Michael J. Jones';                first='Michael J.';     last='Jones';             party='Democrat' }
    @{ dist=16; ext_id=-5110016; full='Schuyler T. VanValkenburg';       first='Schuyler T.';    last='VanValkenburg';     party='Democrat' }
    @{ dist=17; ext_id=-5110017; full='Emily M. Jordan';                 first='Emily M.';       last='Jordan';            party='Republican' }
    @{ dist=18; ext_id=-5110018; full='L. Louise Lucas';                 first='L. Louise';      last='Lucas';             party='Democrat' }
    @{ dist=19; ext_id=-5110019; full='Christie New Craig';              first='Christie';       last='New Craig';         party='Republican' }
    @{ dist=20; ext_id=-5110020; full='Bill DeSteph';                    first='Bill';           last='DeSteph';           party='Republican' }
    @{ dist=21; ext_id=-5110021; full='Angelia Williams Graves';         first='Angelia';        last='Williams Graves';   party='Democrat' }
    @{ dist=22; ext_id=-5110022; full='Aaron R. Rouse';                  first='Aaron R.';       last='Rouse';             party='Democrat' }
    @{ dist=23; ext_id=-5110023; full='Mamie E. Locke';                  first='Mamie E.';       last='Locke';             party='Democrat' }
    @{ dist=24; ext_id=-5110024; full='J.D. "Danny" Diggs';              first='J.D.';           last='Diggs';             party='Republican' }
    @{ dist=25; ext_id=-5110025; full='Richard H. Stuart';               first='Richard H.';     last='Stuart';            party='Republican' }
    @{ dist=26; ext_id=-5110026; full='Ryan T. McDougle';                first='Ryan T.';        last='McDougle';          party='Republican' }
    @{ dist=27; ext_id=-5110027; full='Tara A. Durant';                  first='Tara A.';        last='Durant';            party='Republican' }
    @{ dist=28; ext_id=-5110028; full='Bryce E. Reeves';                 first='Bryce E.';       last='Reeves';            party='Republican' }
    @{ dist=29; ext_id=-5110029; full='Jeremy S. McPike';                first='Jeremy S.';      last='McPike';            party='Democrat' }
    @{ dist=30; ext_id=-5110030; full='Danica A. Roem';                  first='Danica A.';      last='Roem';              party='Democrat' }
    @{ dist=31; ext_id=-5110031; full='Russet W. Perry';                 first='Russet W.';      last='Perry';             party='Democrat' }
    @{ dist=32; ext_id=-5110032; full='Kannan Srinivasan';               first='Kannan';         last='Srinivasan';        party='Democrat' }
    @{ dist=33; ext_id=-5110033; full='Jennifer D. Carroll Foy';         first='Jennifer D.';    last='Foy';               party='Democrat' }
    @{ dist=34; ext_id=-5110034; full='Scott A. Surovell';               first='Scott A.';       last='Surovell';          party='Democrat' }
    @{ dist=35; ext_id=-5110035; full='David W. Marsden';                first='David W.';       last='Marsden';           party='Democrat' }
    @{ dist=36; ext_id=-5110036; full='Stella G. Pekarsky';              first='Stella G.';      last='Pekarsky';          party='Democrat' }
    @{ dist=37; ext_id=-5110037; full='Saddam Azlan Salim';              first='Saddam';         last='Salim';             party='Democrat' }
    @{ dist=38; ext_id=-5110038; full='Jennifer B. Boysko';              first='Jennifer B.';    last='Boysko';            party='Democrat' }
    @{ dist=39; ext_id=-5110039; full='Elizabeth B. Bennett-Parker';     first='Elizabeth B.';   last='Bennett-Parker';    party='Democrat' }
    @{ dist=40; ext_id=-5110040; full='Barbara A. Favola';               first='Barbara A.';     last='Favola';            party='Democrat' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 307: Virginia State Senate Officials")
$null = $sb.AppendLine("-- 40 senators, no vacancies.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Source analogs: 273_md_state_senators.sql, generate_md_senate.ps1")
$null = $sb.AppendLine("-- Phase: 101 (VA State Government DB)")
$null = $sb.AppendLine("-- Requirement: VA-GOV-03")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Virginia Senate chamber from Phase 101 migration 304.")
$null = $sb.AppendLine("-- Uses existing STATE_UPPER districts from Phase 100 TIGER load.")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING; WHERE NOT EXISTS on offices.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- external_id range: -5110001 (SD-1 French) through -5110040 (SD-40 Favola)")
$null = $sb.AppendLine("-- geo_id format: '51' + district_num.PadLeft(3, '0')  e.g. SD-1 -> '51001', SD-40 -> '51040'")
$null = $sb.AppendLine("-- CRITICAL: d.state = 'va' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 51001-51040 exist in BOTH")
$null = $sb.AppendLine("--           STATE_UPPER and STATE_LOWER (100% overlap); omitting causes 2 offices per senator")
$null = $sb.AppendLine("-- CRITICAL: Idempotent via ON CONFLICT (external_id) + NOT EXISTS (district_id, chamber_id)")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("BEGIN;")
$null = $sb.AppendLine("")

foreach ($r in $roster) {
    $null = $sb.AppendLine((SenatorBlock $r))
}

$null = $sb.AppendLine("-- ===== office_id back-fill =====")
$null = $sb.AppendLine("UPDATE essentials.politicians p")
$null = $sb.AppendLine("SET office_id = o.id")
$null = $sb.AppendLine("FROM essentials.offices o")
$null = $sb.AppendLine("WHERE o.politician_id = p.id")
$null = $sb.AppendLine("  AND p.external_id BETWEEN -5110040 AND -5110001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# Write UTF-8 without BOM (required for psql compatibility)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify CTE count
$content = Get-Content $Out -Raw
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
Write-Host "CTE blocks (senators): $cteCount  (expected 40)"
