# generate_or_senate.ps1
# Generates migration 226: Oregon State Senate (30 senators)
# All 30 districts filled — no vacancies.
#
# Verified against oregonlegislature.gov/senate/Pages/SenatorsAll.aspx (2026-05-29):
# - All party affiliations confirmed
# - SD-01: "David Brock Smith" (full name, not just "Smith")
# - SD-07: "James I. Manning Jr." (middle initial + suffix)
# - SD-08: "Sara Gelser Blouin" (compound surname)
# - SD-13: "Courtney Neron Misslin" (compound surname)
# - SD-18: "Wlnsvey Campos" (unusual first name — verified from official roster)

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/226_or_state_senators.sql"
)

function EscSql([string]$s) { $s.Replace("'", "''") }

function SenatorBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '41' + ([int]$r.dist).ToString().PadLeft(3, '0')
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
        WHERE name = 'Oregon Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon')),
       p.id,
       'Senator', 'OR', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_UPPER' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'Oregon Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon'))
  );

"@
}

# 30-entry roster (verified from oregonlegislature.gov/senate/Pages/SenatorsAll.aspx, 2026-05-29)
$roster = @(
    @{ dist=1;  ext_id=-4110001; full='David Brock Smith';       first='David';     last='Brock Smith';       party='Republican' }
    @{ dist=2;  ext_id=-4110002; full='Noah Robinson';           first='Noah';      last='Robinson';          party='Republican' }
    @{ dist=3;  ext_id=-4110003; full='Jeff Golden';             first='Jeff';      last='Golden';            party='Democratic' }
    @{ dist=4;  ext_id=-4110004; full='Floyd Prozanski';         first='Floyd';     last='Prozanski';         party='Democratic' }
    @{ dist=5;  ext_id=-4110005; full='Dick Anderson';           first='Dick';      last='Anderson';          party='Republican' }
    @{ dist=6;  ext_id=-4110006; full='Cedric Hayden';           first='Cedric';    last='Hayden';            party='Republican' }
    @{ dist=7;  ext_id=-4110007; full='James I. Manning Jr.';    first='James';     last='Manning';           party='Democratic' }
    @{ dist=8;  ext_id=-4110008; full='Sara Gelser Blouin';      first='Sara';      last='Gelser Blouin';     party='Democratic' }
    @{ dist=9;  ext_id=-4110009; full='Fred Girod';              first='Fred';      last='Girod';             party='Republican' }
    @{ dist=10; ext_id=-4110010; full='Deb Patterson';           first='Deb';       last='Patterson';         party='Democratic' }
    @{ dist=11; ext_id=-4110011; full='Kim Thatcher';            first='Kim';       last='Thatcher';          party='Republican' }
    @{ dist=12; ext_id=-4110012; full='Bruce Starr';             first='Bruce';     last='Starr';             party='Republican' }
    @{ dist=13; ext_id=-4110013; full='Courtney Neron Misslin';  first='Courtney';  last='Neron Misslin';     party='Democratic' }
    @{ dist=14; ext_id=-4110014; full='Kate Lieber';             first='Kate';      last='Lieber';            party='Democratic' }
    @{ dist=15; ext_id=-4110015; full='Janeen Sollman';          first='Janeen';    last='Sollman';           party='Democratic' }
    @{ dist=16; ext_id=-4110016; full='Suzanne Weber';           first='Suzanne';   last='Weber';             party='Republican' }
    @{ dist=17; ext_id=-4110017; full='Lisa Reynolds';           first='Lisa';      last='Reynolds';          party='Democratic' }
    @{ dist=18; ext_id=-4110018; full='Wlnsvey Campos';          first='Wlnsvey';   last='Campos';            party='Democratic' }
    @{ dist=19; ext_id=-4110019; full='Rob Wagner';              first='Rob';       last='Wagner';            party='Democratic' }
    @{ dist=20; ext_id=-4110020; full='Mark Meek';               first='Mark';      last='Meek';              party='Democratic' }
    @{ dist=21; ext_id=-4110021; full='Kathleen Taylor';         first='Kathleen';  last='Taylor';            party='Democratic' }
    @{ dist=22; ext_id=-4110022; full='Lew Frederick';           first='Lew';       last='Frederick';         party='Democratic' }
    @{ dist=23; ext_id=-4110023; full='Khanh Pham';              first='Khanh';     last='Pham';              party='Democratic' }
    @{ dist=24; ext_id=-4110024; full='Kayse Jama';              first='Kayse';     last='Jama';              party='Democratic' }
    @{ dist=25; ext_id=-4110025; full='Chris Gorsek';            first='Chris';     last='Gorsek';            party='Democratic' }
    @{ dist=26; ext_id=-4110026; full='Christine Drazan';        first='Christine'; last='Drazan';            party='Republican' }
    @{ dist=27; ext_id=-4110027; full='Anthony Broadman';        first='Anthony';   last='Broadman';          party='Democratic' }
    @{ dist=28; ext_id=-4110028; full='Diane Linthicum';         first='Diane';     last='Linthicum';         party='Republican' }
    @{ dist=29; ext_id=-4110029; full='Todd Nash';               first='Todd';      last='Nash';              party='Republican' }
    @{ dist=30; ext_id=-4110030; full='Mike McLane';             first='Mike';      last='McLane';            party='Republican' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 226: Oregon State Senate Officials")
$null = $sb.AppendLine("-- 30 senators, all districts filled, no vacancies.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Oregon Senate chamber from Phase 73 migration 222 (no chamber INSERT).")
$null = $sb.AppendLine("-- Uses existing STATE_UPPER districts from Phase 72 TIGER load (no district INSERT).")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- external_id range: -4110001 (SD-01) through -4110030 (SD-30)")
$null = $sb.AppendLine("-- geo_id format: '41' + district_num.PadLeft(3, '0')  e.g. SD-01 -> '41001', SD-17 -> '41017'")
$null = $sb.AppendLine("-- CRITICAL: d.state = 'or' (lowercase) - TIGER loader casing for STATE_UPPER/STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: district_type = 'STATE_UPPER' required - geo_ids 41001-41030 exist in BOTH")
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
$null = $sb.AppendLine("  AND p.external_id BETWEEN -4110030 AND -4110001")
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
Write-Host "CTE blocks (senators): $cteCount  (expected 30)"
