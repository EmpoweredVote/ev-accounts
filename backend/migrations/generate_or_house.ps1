# generate_or_house.ps1
# Generates migration 227: Oregon House of Representatives (60 house reps)
# All 60 districts filled -- no vacancies.
#
# Verified against oregonlegislature.gov/house/Pages/RepresentativesAll.aspx (2026-05-29):
# - All party affiliations confirmed
# - HD-15: "Shelly Boshart Davis" (compound surname) -> last='Boshart Davis'
# - HD-16: "Sarah Finger McDonald" (compound surname) -> last='Finger McDonald'
# - HD-22: "Lesly Munoz" (stored with tilde-n: Munoz) -> full='Lesly Munoz'
# - HD-38: "Daniel Nguyen" (stored with Vietnamese diacritical: Nguyeen) -> full='Daniel Nguyeen'
# - HD-43: "Tawna D. Sanchez" (middle initial retained in full_name)
# - HD-45: "Thuy Tran" (stored with Vietnamese diacriticals: Thuy Tran) -> full='Thuy Tran'
# - HD-55: "E. Werner Reschke" (initial retained in full_name)
# NOTE: Non-ASCII stored correctly via UTF-8 NoBOM output; EscSql handles single quotes only.
# The actual Unicode full_name values (Munoz, Nguyen, Tran with diacriticals) are hardcoded in the roster below.

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/227_or_state_house.sql"
)

function EscSql([string]$s) { $s.Replace("'", "''") }

function RepBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '41' + ([int]$r.dist).ToString().PadLeft(3, '0')
@"
-- ===== HD-$($r.dist) ($gid): $($r.full) ($($r.party)) =====
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
        WHERE name = 'Oregon House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Representative', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_LOWER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon House of Representatives'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

"@
}

# 60-entry roster (verified from oregonlegislature.gov/house/Pages/RepresentativesAll.aspx, 2026-05-29)
$roster = @(
    @{ dist=1;  ext_id=-4120001; full='Court Boice';              first='Court';     last='Boice';              party='Republican' }
    @{ dist=2;  ext_id=-4120002; full='Virgle Osborne';           first='Virgle';    last='Osborne';            party='Republican' }
    @{ dist=3;  ext_id=-4120003; full='Dwayne Yunker';            first='Dwayne';    last='Yunker';             party='Republican' }
    @{ dist=4;  ext_id=-4120004; full='Alek Skarlatos';           first='Alek';      last='Skarlatos';          party='Republican' }
    @{ dist=5;  ext_id=-4120005; full='Pam Marsh';                first='Pam';       last='Marsh';              party='Democratic' }
    @{ dist=6;  ext_id=-4120006; full='Kim Wallan';               first='Kim';       last='Wallan';             party='Republican' }
    @{ dist=7;  ext_id=-4120007; full='John Lively';              first='John';      last='Lively';             party='Democratic' }
    @{ dist=8;  ext_id=-4120008; full='Lisa Fragala';             first='Lisa';      last='Fragala';            party='Democratic' }
    @{ dist=9;  ext_id=-4120009; full='Boomer Wright';            first='Boomer';    last='Wright';             party='Republican' }
    @{ dist=10; ext_id=-4120010; full='David Gomberg';            first='David';     last='Gomberg';            party='Democratic' }
    @{ dist=11; ext_id=-4120011; full='Jami Cate';                first='Jami';      last='Cate';               party='Republican' }
    @{ dist=12; ext_id=-4120012; full='Darin Harbick';            first='Darin';     last='Harbick';            party='Republican' }
    @{ dist=13; ext_id=-4120013; full='Nancy Nathanson';          first='Nancy';     last='Nathanson';          party='Democratic' }
    @{ dist=14; ext_id=-4120014; full='Julie Fahey';              first='Julie';     last='Fahey';              party='Democratic' }
    @{ dist=15; ext_id=-4120015; full='Shelly Boshart Davis';     first='Shelly';    last='Boshart Davis';      party='Republican' }
    @{ dist=16; ext_id=-4120016; full='Sarah Finger McDonald';    first='Sarah';     last='Finger McDonald';    party='Democratic' }
    @{ dist=17; ext_id=-4120017; full='Ed Diehl';                 first='Ed';        last='Diehl';              party='Republican' }
    @{ dist=18; ext_id=-4120018; full='Rick Lewis';               first='Rick';      last='Lewis';              party='Republican' }
    @{ dist=19; ext_id=-4120019; full='Tom Andersen';             first='Tom';       last='Andersen';           party='Democratic' }
    @{ dist=20; ext_id=-4120020; full='Paul Evans';               first='Paul';      last='Evans';              party='Democratic' }
    @{ dist=21; ext_id=-4120021; full='Kevin Mannix';             first='Kevin';     last='Mannix';             party='Republican' }
    @{ dist=22; ext_id=-4120022; full="Lesly Mu$([char]0x00F1)oz";  first='Lesly';     last="Mu$([char]0x00F1)oz"; party='Democratic' }
    @{ dist=23; ext_id=-4120023; full='Anna Scharf';              first='Anna';      last='Scharf';             party='Republican' }
    @{ dist=24; ext_id=-4120024; full='Lucetta Elmer';            first='Lucetta';   last='Elmer';              party='Republican' }
    @{ dist=25; ext_id=-4120025; full='Ben Bowman';               first='Ben';       last='Bowman';             party='Democratic' }
    @{ dist=26; ext_id=-4120026; full='Sue Rieke Smith';          first='Sue';       last='Rieke Smith';        party='Democratic' }
    @{ dist=27; ext_id=-4120027; full='Ken Helm';                 first='Ken';       last='Helm';               party='Democratic' }
    @{ dist=28; ext_id=-4120028; full='Dacia Grayber';            first='Dacia';     last='Grayber';            party='Democratic' }
    @{ dist=29; ext_id=-4120029; full='Susan McLain';             first='Susan';     last='McLain';             party='Democratic' }
    @{ dist=30; ext_id=-4120030; full='Nathan Sosa';              first='Nathan';    last='Sosa';               party='Democratic' }
    @{ dist=31; ext_id=-4120031; full='Darcey Edwards';           first='Darcey';    last='Edwards';            party='Republican' }
    @{ dist=32; ext_id=-4120032; full='Cyrus Javadi';             first='Cyrus';     last='Javadi';             party='Democratic' }
    @{ dist=33; ext_id=-4120033; full='Shannon Isadore';          first='Shannon';   last='Isadore';            party='Democratic' }
    @{ dist=34; ext_id=-4120034; full='Mari Watanabe';            first='Mari';      last='Watanabe';           party='Democratic' }
    @{ dist=35; ext_id=-4120035; full='Farrah Chaichi';           first='Farrah';    last='Chaichi';            party='Democratic' }
    @{ dist=36; ext_id=-4120036; full='Hai Pham';                 first='Hai';       last='Pham';               party='Democratic' }
    @{ dist=37; ext_id=-4120037; full='Jules Walters';            first='Jules';     last='Walters';            party='Democratic' }
    @{ dist=38; ext_id=-4120038; full="Daniel Nguy$([char]0x1EBF)n"; first='Daniel';  last="Nguy$([char]0x1EBF)n"; party='Democratic' }
    @{ dist=39; ext_id=-4120039; full='April Dobson';             first='April';     last='Dobson';             party='Democratic' }
    @{ dist=40; ext_id=-4120040; full='Annessa Hartman';          first='Annessa';   last='Hartman';            party='Democratic' }
    @{ dist=41; ext_id=-4120041; full='Mark Gamba';               first='Mark';      last='Gamba';              party='Democratic' }
    @{ dist=42; ext_id=-4120042; full='Rob Nosse';                first='Rob';       last='Nosse';              party='Democratic' }
    @{ dist=43; ext_id=-4120043; full='Tawna D. Sanchez';         first='Tawna';     last='Sanchez';            party='Democratic' }
    @{ dist=44; ext_id=-4120044; full='Travis Nelson';            first='Travis';    last='Nelson';             party='Democratic' }
    @{ dist=45; ext_id=-4120045; full="Th$([char]0x1EE7)y Tr$([char]0x1EA7)n"; first="Th$([char]0x1EE7)y"; last="Tr$([char]0x1EA7)n"; party='Democratic' }
    @{ dist=46; ext_id=-4120046; full='Willy Chotzen';            first='Willy';     last='Chotzen';            party='Democratic' }
    @{ dist=47; ext_id=-4120047; full='Andrea Valderrama';        first='Andrea';    last='Valderrama';         party='Democratic' }
    @{ dist=48; ext_id=-4120048; full='Lamar Wise';               first='Lamar';     last='Wise';               party='Democratic' }
    @{ dist=49; ext_id=-4120049; full='Zach Hudson';              first='Zach';      last='Hudson';             party='Democratic' }
    @{ dist=50; ext_id=-4120050; full='Ricki Ruiz';               first='Ricki';     last='Ruiz';               party='Democratic' }
    @{ dist=51; ext_id=-4120051; full='Matt Bunch';               first='Matt';      last='Bunch';              party='Republican' }
    @{ dist=52; ext_id=-4120052; full='Jeff Helfrich';            first='Jeff';      last='Helfrich';           party='Republican' }
    @{ dist=53; ext_id=-4120053; full='Emerson Levy';             first='Emerson';   last='Levy';               party='Democratic' }
    @{ dist=54; ext_id=-4120054; full='Jason Kropf';              first='Jason';     last='Kropf';              party='Democratic' }
    @{ dist=55; ext_id=-4120055; full='E. Werner Reschke';        first='E. Werner'; last='Reschke';            party='Republican' }
    @{ dist=56; ext_id=-4120056; full='Emily McIntire';           first='Emily';     last='McIntire';           party='Republican' }
    @{ dist=57; ext_id=-4120057; full='Gregory Smith';            first='Gregory';   last='Smith';              party='Republican' }
    @{ dist=58; ext_id=-4120058; full='Bobby Levy';               first='Bobby';     last='Levy';               party='Republican' }
    @{ dist=59; ext_id=-4120059; full='Vikki Breese-Iverson';     first='Vikki';     last='Breese-Iverson';     party='Republican' }
    @{ dist=60; ext_id=-4120060; full='Mark Owens';               first='Mark';      last='Owens';              party='Republican' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 227: Oregon House of Representatives Officials")
$null = $sb.AppendLine("-- 60 house reps, all districts filled, no vacancies.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Oregon House of Representatives chamber from Phase 73 migration 222 (no chamber INSERT).")
$null = $sb.AppendLine("-- Uses existing STATE_LOWER districts from Phase 72 TIGER load (no district INSERT).")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- external_id range: -4120001 (HD-01) through -4120060 (HD-60)")
$null = $sb.AppendLine("-- geo_id format: '41' + district_num.PadLeft(3, '0')  e.g. HD-01 -> '41001', HD-33 -> '41033', HD-60 -> '41060'")
$null = $sb.AppendLine("-- CRITICAL: d.state = 'or' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: district_type = 'STATE_LOWER' required - geo_ids 41001-41030 exist in BOTH")
$null = $sb.AppendLine("--           STATE_UPPER and STATE_LOWER; omitting district_type causes ambiguous subquery")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("BEGIN;")
$null = $sb.AppendLine("")

foreach ($r in $roster) {
    $null = $sb.AppendLine((RepBlock $r))
}

$null = $sb.AppendLine("-- ===== office_id back-fill =====")
$null = $sb.AppendLine("UPDATE essentials.politicians p")
$null = $sb.AppendLine("SET office_id = o.id")
$null = $sb.AppendLine("FROM essentials.offices o")
$null = $sb.AppendLine("WHERE o.politician_id = p.id")
$null = $sb.AppendLine("  AND p.external_id BETWEEN -4120060 AND -4120001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# Write UTF-8 without BOM (required for psql)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw -Encoding UTF8
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
Write-Host "CTE blocks (representatives): $cteCount  (expected 60)"
