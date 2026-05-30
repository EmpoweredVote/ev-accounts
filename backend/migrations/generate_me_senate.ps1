# generate_me_senate.ps1
# Generates migration 172: Maine State Senate (35 senators, 132nd Legislature)
# All 35 districts filled — no vacancies expected.
#
# Verified against legislature.maine.gov/senate/senators/9536 (2026-05-19):
# - Middle initials confirmed from official alphabetical listing (full names differ from
#   individual page nicknames: "Jeff" = Jeffrey L., "Dick" = Richard, "Rick" = Richard A., "Mattie" = Matthea E. L.)
# - All party affiliations confirmed
# - District 28: "Talbot Ross" is compound last name

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/172_me_state_senate_officials.sql"
)

$CH = 'Maine Senate'

function EscSql([string]$s) { $s.Replace("'", "''") }

function SenatorBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '23' + ([int]$r.dist).ToString().PadLeft(3, '0')
@"
-- ===== District $($r.dist) ($gid): $($r.full) ($($r.party)) =====
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
       (SELECT id FROM essentials.chambers WHERE name = '$CH'),
       p.id,
       'Senator', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_UPPER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = '$CH')
  );

"@
}

# 35-entry roster (verified from legislature.maine.gov/senate/senators/9536, 2026-05-19)
# Full names taken from official alphabetical listing (not individual page nicknames).
$roster = @(
    @{ dist=1;  ext_id=-231001; full='Susan Bernard';          first='Susan';    last='Bernard';       party='Republican' }
    @{ dist=2;  ext_id=-231002; full='Trey L. Stewart';        first='Trey';     last='Stewart';       party='Republican' }
    @{ dist=3;  ext_id=-231003; full='Bradlee T. Farrin';      first='Bradlee';  last='Farrin';        party='Republican' }
    @{ dist=4;  ext_id=-231004; full='Stacey K. Guerin';       first='Stacey';   last='Guerin';        party='Republican' }
    @{ dist=5;  ext_id=-231005; full='Russell J. Black';       first='Russell';  last='Black';         party='Republican' }
    @{ dist=6;  ext_id=-231006; full='Marianne Moore';         first='Marianne'; last='Moore';         party='Republican' }
    @{ dist=7;  ext_id=-231007; full='Nicole C. Grohoski';     first='Nicole';   last='Grohoski';      party='Democrat' }
    @{ dist=8;  ext_id=-231008; full='Mike Tipping';           first='Mike';     last='Tipping';       party='Democrat' }
    @{ dist=9;  ext_id=-231009; full='Joseph M. Baldacci';     first='Joseph';   last='Baldacci';      party='Democrat' }
    @{ dist=10; ext_id=-231010; full='David Haggan';           first='David';    last='Haggan';        party='Republican' }
    @{ dist=11; ext_id=-231011; full='Chip Curry';             first='Chip';     last='Curry';         party='Democrat' }
    @{ dist=12; ext_id=-231012; full='Pinny H. Beebe-Center';  first='Pinny';    last='Beebe-Center';  party='Democrat' }
    @{ dist=13; ext_id=-231013; full='Cameron D. Reny';        first='Cameron';  last='Reny';          party='Democrat' }
    @{ dist=14; ext_id=-231014; full='Craig V. Hickman';       first='Craig';    last='Hickman';       party='Democrat' }
    @{ dist=15; ext_id=-231015; full='Richard Bradstreet';     first='Richard';  last='Bradstreet';    party='Republican' }
    @{ dist=16; ext_id=-231016; full='Scott Cyrway';           first='Scott';    last='Cyrway';        party='Republican' }
    @{ dist=17; ext_id=-231017; full='Jeffrey L. Timberlake';  first='Jeffrey';  last='Timberlake';    party='Republican' }
    @{ dist=18; ext_id=-231018; full='Richard A. Bennett';     first='Richard';  last='Bennett';       party='Independent' }
    @{ dist=19; ext_id=-231019; full='Joseph Martin';          first='Joseph';   last='Martin';        party='Republican' }
    @{ dist=20; ext_id=-231020; full='Bruce Bickford';         first='Bruce';    last='Bickford';      party='Republican' }
    @{ dist=21; ext_id=-231021; full='Peggy R. Rotundo';       first='Peggy';    last='Rotundo';       party='Democrat' }
    @{ dist=22; ext_id=-231022; full='James D. Libby';         first='James';    last='Libby';         party='Republican' }
    @{ dist=23; ext_id=-231023; full='Matthea E. L. Daughtry'; first='Matthea';  last='Daughtry';      party='Democrat' }
    @{ dist=24; ext_id=-231024; full='Denise Tepler';          first='Denise';   last='Tepler';        party='Democrat' }
    @{ dist=25; ext_id=-231025; full='Teresa S. Pierce';       first='Teresa';   last='Pierce';        party='Democrat' }
    @{ dist=26; ext_id=-231026; full='Timothy E. Nangle';      first='Timothy';  last='Nangle';        party='Democrat' }
    @{ dist=27; ext_id=-231027; full='Jill C. Duson';          first='Jill';     last='Duson';         party='Democrat' }
    @{ dist=28; ext_id=-231028; full='Rachel Talbot Ross';     first='Rachel';   last='Talbot Ross';   party='Democrat' }
    @{ dist=29; ext_id=-231029; full='Anne M. Carney';         first='Anne';     last='Carney';        party='Democrat' }
    @{ dist=30; ext_id=-231030; full='Stacy F. Brenner';       first='Stacy';    last='Brenner';       party='Democrat' }
    @{ dist=31; ext_id=-231031; full='Donna Bailey';           first='Donna';    last='Bailey';        party='Democrat' }
    @{ dist=32; ext_id=-231032; full='Henry L. Ingwersen';     first='Henry';    last='Ingwersen';     party='Democrat' }
    @{ dist=33; ext_id=-231033; full='Matt A. Harrington';     first='Matt';     last='Harrington';    party='Republican' }
    @{ dist=34; ext_id=-231034; full='Joseph Rafferty';        first='Joseph';   last='Rafferty';      party='Democrat' }
    @{ dist=35; ext_id=-231035; full='Mark W. Lawrence';       first='Mark';     last='Lawrence';      party='Democrat' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 172: Maine State Senate Officials (132nd Legislature)")
$null = $sb.AppendLine("-- 35 senators, all districts filled, no vacancies.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Maine Senate chamber from Phase 50 migration 168 (no chamber INSERT).")
$null = $sb.AppendLine("-- Uses existing STATE_UPPER districts from Phase 49 TIGER load (no district INSERT).")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.")
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
$null = $sb.AppendLine("  AND p.external_id BETWEEN -231035 AND -231001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# Write UTF-8 without BOM (required for psql)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
Write-Host "CTE blocks (senators): $cteCount  (expected 35)"
