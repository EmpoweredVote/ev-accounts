SET statement_timeout='5min';
with ov as (
  select district_layer mtfcc, district_geoid geo_id from essentials.district_county_overlap where county_geoid='06037'
  union select 'G4110', p.geo_id from essentials.geofence_boundaries p, essentials.geofence_boundaries c
    where c.mtfcc='G4020' and c.geo_id='06037' and p.mtfcc='G4110' and p.state='06' and ST_Intersects(c.geometry, ST_PointOnSurface(p.geometry))
  union select 'G4020','06037'),
d as (
  select distinct d.id district_id, d.district_type, d.label from essentials.districts d join ov on ov.geo_id=d.geo_id and (d.mtfcc=ov.mtfcc or d.mtfcc is null)
  union select d.id, d.district_type, d.label from essentials.districts d where d.district_type='NATIONAL_UPPER' and d.state in ('CA','06')),
offs as (select d.*, o.id office_id, o.title from d join essentials.offices o on o.district_id=d.district_id),
holders as (
  select distinct on (h.politician_id) '06037' county, 'holder' kind, h.politician_id pid, p.full_name, offs.district_type, offs.label, offs.title, offs.office_id, null::text race
  from offs join essentials.office_current_holder h on h.office_id=offs.office_id join essentials.politicians p on p.id=h.politician_id
  where h.politician_id is not null order by h.politician_id, offs.district_type),
cands as (
  select distinct '06037' county, 'candidate' kind, rc.politician_id pid, rc.full_name, offs.district_type, offs.label, offs.title, offs.office_id, r.position_name race
  from offs join essentials.races r on r.office_id=offs.office_id join essentials.elections e on e.id=r.election_id
  join essentials.race_candidates rc on rc.race_id=r.id
  where e.election_date >= '2026-10-01' and rc.candidate_status <> 'withdrawn' and coalesce(rc.result,'') not in ('lost','withdrew','not_nominated') and rc.politician_id is not null),
cands_unlinked as (
  select distinct '06037' county, 'candidate_unlinked' kind, rc.id pid, rc.full_name, offs.district_type, offs.label, offs.title, offs.office_id, r.position_name race
  from offs join essentials.races r on r.office_id=offs.office_id join essentials.elections e on e.id=r.election_id
  join essentials.race_candidates rc on rc.race_id=r.id
  where e.election_date >= '2026-10-01' and rc.candidate_status <> 'withdrawn' and coalesce(rc.result,'') not in ('lost','withdrew','not_nominated') and rc.politician_id is null)
select * from holders union all select * from cands union all select * from cands_unlinked order by 5,6,2,4;
