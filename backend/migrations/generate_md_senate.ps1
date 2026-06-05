# generate_md_senate.ps1
# Generates migration 273: Maryland State Senate (47 senators)
# No vacant seats. [VERIFIED: mgaleg.maryland.gov, 2026-06-02]
#
# MD-specific deviations from generate_or_senate.ps1:
#   1. FIPS prefix '24' (not '41') for geo_id construction
#   2. 'Maryland Senate' / 'State of Maryland' / AND state = 'MD' in government subquery
#   3. d.state = 'md' (lowercase) for STATE_UPPER district lookup
#   4. p.id IS NOT NULL guard on CROSS JOIN (OR omits this; MD adds per RESEARCH.md anti-pattern note)
#   5. representing_state = 'MD' (not 'OR')
#   6. external_id range: -2410001 (SD-01 McKay) through -2410047 (SD-47 Augustine)
#
# CRITICAL: d.state = 'md' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER
# CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 24001-24047 exist in BOTH
#           STATE_UPPER and STATE_LOWER; omitting district_type causes ambiguous subquery
# CRITICAL: external_id range -2410047..-2410001 (no collision with execs -240001..-240005)
# CRITICAL: geo_id format '24' + dist.PadLeft(3,'0')  e.g. SD-01 -> '24001', SD-47 -> '24047'

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/273_md_state_senators.sql"
)

function EscSql([string]$s) { $s.Replace("'", "''") }

function SenatorBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '24' + ([int]$r.dist).ToString().PadLeft(3, '0')
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
        WHERE name = 'Maryland Senate'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Senator', 'MD', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_UPPER' AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Maryland Senate'
                             AND government_id = (SELECT id FROM essentials.governments
                                                  WHERE name = 'State of Maryland' AND state = 'MD'))
  );

"@
}

# 47-entry roster [VERIFIED: mgaleg.maryland.gov, 2026-06-02]
# Party affiliations verified from mgaleg.maryland.gov member pages
# MD-specific note: Bill Ferguson (SD-46) is President of the Senate (Democrat)
$roster = @(
    @{ dist=1;  ext_id=-2410001; full='Mike McKay';                    first='Mike';       last='McKay';              party='Republican' }
    @{ dist=2;  ext_id=-2410002; full='Paul D. Corderman';             first='Paul';       last='Corderman';          party='Republican' }
    @{ dist=3;  ext_id=-2410003; full='Karen Lewis Young';             first='Karen';      last='Lewis Young';        party='Democrat' }
    @{ dist=4;  ext_id=-2410004; full='William G. Folden';             first='William';    last='Folden';             party='Republican' }
    @{ dist=5;  ext_id=-2410005; full='Justin Ready';                  first='Justin';     last='Ready';              party='Republican' }
    @{ dist=6;  ext_id=-2410006; full='Johnny Ray Salling';            first='Johnny';     last='Salling';            party='Republican' }
    @{ dist=7;  ext_id=-2410007; full='J.B. Jennings';                 first='J.B.';       last='Jennings';           party='Republican' }
    @{ dist=8;  ext_id=-2410008; full='Carl Jackson';                  first='Carl';       last='Jackson';            party='Democrat' }
    @{ dist=9;  ext_id=-2410009; full='Katie Fry Hester';              first='Katie';      last='Fry Hester';         party='Democrat' }
    @{ dist=10; ext_id=-2410010; full='Benjamin Brooks';               first='Benjamin';   last='Brooks';             party='Democrat' }
    @{ dist=11; ext_id=-2410011; full='Shelly Hettleman';              first='Shelly';     last='Hettleman';          party='Democrat' }
    @{ dist=12; ext_id=-2410012; full='Clarence K. Lam';               first='Clarence';   last='Lam';                party='Democrat' }
    @{ dist=13; ext_id=-2410013; full='Guy Guzzone';                   first='Guy';        last='Guzzone';            party='Democrat' }
    @{ dist=14; ext_id=-2410014; full='Craig J. Zucker';               first='Craig';      last='Zucker';             party='Democrat' }
    @{ dist=15; ext_id=-2410015; full='Brian J. Feldman';              first='Brian';      last='Feldman';            party='Democrat' }
    @{ dist=16; ext_id=-2410016; full='Sara Love';                     first='Sara';       last='Love';               party='Democrat' }
    @{ dist=17; ext_id=-2410017; full='Cheryl C. Kagan';               first='Cheryl';     last='Kagan';              party='Democrat' }
    @{ dist=18; ext_id=-2410018; full='Jeff Waldstreicher';            first='Jeff';       last='Waldstreicher';      party='Democrat' }
    @{ dist=19; ext_id=-2410019; full='Benjamin F. Kramer';            first='Benjamin';   last='Kramer';             party='Democrat' }
    @{ dist=20; ext_id=-2410020; full='William C. Smith, Jr.';         first='William';    last='Smith';              party='Democrat' }
    @{ dist=21; ext_id=-2410021; full='Jim Rosapepe';                  first='Jim';        last='Rosapepe';           party='Democrat' }
    @{ dist=22; ext_id=-2410022; full='Alonzo T. Washington';          first='Alonzo';     last='Washington';         party='Democrat' }
    @{ dist=23; ext_id=-2410023; full='Ron Watson';                    first='Ron';        last='Watson';             party='Democrat' }
    @{ dist=24; ext_id=-2410024; full='Joanne C. Benson';              first='Joanne';     last='Benson';             party='Democrat' }
    @{ dist=25; ext_id=-2410025; full='Nick Charles';                  first='Nick';       last='Charles';            party='Democrat' }
    @{ dist=26; ext_id=-2410026; full='C. Anthony Muse';               first='C. Anthony'; last='Muse';               party='Democrat' }
    @{ dist=27; ext_id=-2410027; full='Kevin M. Harris';               first='Kevin';      last='Harris';             party='Democrat' }
    @{ dist=28; ext_id=-2410028; full='Arthur Ellis';                  first='Arthur';     last='Ellis';              party='Democrat' }
    @{ dist=29; ext_id=-2410029; full='Jack Bailey';                   first='Jack';       last='Bailey';             party='Republican' }
    @{ dist=30; ext_id=-2410030; full='Shaneka Henson';                first='Shaneka';    last='Henson';             party='Democrat' }
    @{ dist=31; ext_id=-2410031; full='Bryan W. Simonaire';            first='Bryan';      last='Simonaire';          party='Republican' }
    @{ dist=32; ext_id=-2410032; full='Pamela Beidle';                 first='Pamela';     last='Beidle';             party='Democrat' }
    @{ dist=33; ext_id=-2410033; full='Dawn Gile';                     first='Dawn';       last='Gile';               party='Democrat' }
    @{ dist=34; ext_id=-2410034; full='Mary-Dulany James';             first='Mary-Dulany'; last='James';             party='Democrat' }
    @{ dist=35; ext_id=-2410035; full='Jason C. Gallion';              first='Jason';      last='Gallion';            party='Republican' }
    @{ dist=36; ext_id=-2410036; full='Stephen S. Hershey, Jr.';       first='Stephen';    last='Hershey';            party='Republican' }
    @{ dist=37; ext_id=-2410037; full='Johnny Mautz';                  first='Johnny';     last='Mautz';              party='Republican' }
    @{ dist=38; ext_id=-2410038; full='Mary Beth Carozza';             first='Mary Beth';  last='Carozza';            party='Republican' }
    @{ dist=39; ext_id=-2410039; full='Nancy J. King';                 first='Nancy';      last='King';               party='Democrat' }
    @{ dist=40; ext_id=-2410040; full='Antonio Hayes';                 first='Antonio';    last='Hayes';              party='Democrat' }
    @{ dist=41; ext_id=-2410041; full='Dalya Attar';                   first='Dalya';      last='Attar';              party='Democrat' }
    @{ dist=42; ext_id=-2410042; full='Chris West';                    first='Chris';      last='West';               party='Republican' }
    @{ dist=43; ext_id=-2410043; full='Mary Washington';               first='Mary';       last='Washington';         party='Democrat' }
    @{ dist=44; ext_id=-2410044; full='Charles E. Sydnor, III';        first='Charles';    last='Sydnor';             party='Democrat' }
    @{ dist=45; ext_id=-2410045; full='Cory V. McCray';                first='Cory';       last='McCray';             party='Democrat' }
    @{ dist=46; ext_id=-2410046; full='Bill Ferguson';                 first='Bill';       last='Ferguson';           party='Democrat' }
    @{ dist=47; ext_id=-2410047; full='Malcolm Augustine';             first='Malcolm';    last='Augustine';          party='Democrat' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 273: Maryland State Senate Officials")
$null = $sb.AppendLine("-- 47 senators, no vacancies.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Maryland Senate chamber from Phase 93 migration 272.")
$null = $sb.AppendLine("-- Uses existing STATE_UPPER districts from Phase 91 TIGER load.")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING; WHERE NOT EXISTS on offices.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- external_id range: -2410001 (SD-01 McKay) through -2410047 (SD-47 Augustine)")
$null = $sb.AppendLine("-- geo_id format: '24' + district_num.PadLeft(3, '0')  e.g. SD-01 -> '24001', SD-47 -> '24047'")
$null = $sb.AppendLine("-- CRITICAL: d.state = 'md' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 24001-24047 exist in BOTH")
$null = $sb.AppendLine("--           STATE_UPPER and STATE_LOWER; omitting district_type causes ambiguous subquery")
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
$null = $sb.AppendLine("  AND p.external_id BETWEEN -2410047 AND -2410001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# Write UTF-8 without BOM (required for psql)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
Write-Host "CTE blocks (senators): $cteCount  (expected 47)"
