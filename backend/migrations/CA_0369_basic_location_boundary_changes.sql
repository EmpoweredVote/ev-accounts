-- CA_0369 — basic accounts are asked to re-enter their address after a boundary change.
BEGIN;

-- Design: docs/superpowers/specs/2026-11-07-basic-account-location-reconfirm-design.md
-- Approved 2026-11-07, Chris Andrews.
--
-- A basic account's districts (inform.account_jurisdictions, CA_0368) can never be re-resolved:
-- we keep no point for it. So when a map changes under it we must ASK it to re-enter the
-- address. This migration records every boundary change and answers "does this account need to
-- confirm?" at read time.
--
-- 🔴 essentials.geofence_boundaries.imported_at CANNOT be the signal (measured 2026-11-07):
--   * load-state-tiger-boundaries.ts inserts ON CONFLICT DO NOTHING, so a re-run never touches it;
--   * 32 writers change `geometry` in place without touching imported_at;
--   * a deleted boundary leaves no row at all.
-- So a trigger records the change, whoever writes it.
--
-- Nothing existing is overwritten. Three new objects, one new trigger:
--   essentials.boundary_changes                   the log
--   essentials.log_boundary_change()              trigger function (+ trigger on geofence_boundaries)
--   inform.basic_location_needs_confirmation(uuid) the read-time answer

-- ── 1. The log ───────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS essentials.boundary_changes (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  changed_at  timestamptz NOT NULL DEFAULT now(),
  kind        text NOT NULL CHECK (kind IN ('insert', 'update', 'delete')),
  geo_id      text,
  mtfcc       text,
  -- 2-digit FIPS, as on geofence_boundaries.state. NULL when the source row had none.
  state       text,
  -- Bounding box of the shape, SRID 4326: the OLD shape for a delete, the box around old and
  -- new for an update. A box, not the shape: small, and it survives the delete.
  extent      public.geometry NOT NULL
);

COMMENT ON TABLE essentials.boundary_changes IS
  'CA_0369: one row per change to a geofence_boundaries shape in a layer that basic-account districts '
  'are resolved from. Written only by the trigger essentials.log_boundary_change. Read by '
  'inform.basic_location_needs_confirmation to ask basic accounts to re-enter their address.';

CREATE INDEX IF NOT EXISTS boundary_changes_state_changed_at_idx
  ON essentials.boundary_changes (state, changed_at);
CREATE INDEX IF NOT EXISTS boundary_changes_extent_idx
  ON essentials.boundary_changes USING gist (extent);

-- Default-deny. Only the API and service_role read it; only the trigger (definer) writes it.
ALTER TABLE essentials.boundary_changes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON essentials.boundary_changes FROM PUBLIC, anon, authenticated;
GRANT SELECT ON essentials.boundary_changes TO ev_api, service_role;

-- ── 2. The trigger ───────────────────────────────────────────────────────────────────
-- The layers the two point resolvers read (CA_0368: resolve_jurisdiction_at_point and
-- resolve_congressional_2026_at_point). A change to any other layer cannot move a basic row.
CREATE OR REPLACE FUNCTION essentials.is_basic_district_layer(p_mtfcc text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT p_mtfcc IN ('G5200', 'G5200V26', 'G5210', 'G5220', 'G4020',
                     'G5400', 'G5410', 'G5420', 'G4040', 'G4110', 'G4120')
      OR p_mtfcc LIKE 'X%'
$function$;

-- A bounding box in SRID 4326. A geometry stored with SRID 0 is taken to be lon/lat already (the
-- CC_0319 repair case). Any other SRID gets the WHOLE-WORLD box — which re-asks every basic account
-- in that state — rather than a reprojection: reprojecting reads public.spatial_ref_sys, which anon
-- can write (ev-cto decision 0006, check-postgis-spatial-ref-guard.mjs). Measured 2026-11-07: all
-- 75,059 shaped boundaries are SRID 4326, so this branch is a safety net, not a path.
--
-- ⚠ As first applied to prod (2026-11-07) this ELSE branch reprojected instead; CI's decision-0006
-- guard caught it and CA_0370 replaced the function with this body. The branch never ran: every
-- boundary is 4326 and the log was empty when CA_0370 applied.
CREATE OR REPLACE FUNCTION essentials.boundary_extent_4326(p_geom public.geometry)
 RETURNS public.geometry
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT CASE
    WHEN p_geom IS NULL THEN NULL
    WHEN public.ST_SRID(p_geom) IN (0, 4326) THEN public.ST_SetSRID(public.ST_Envelope(p_geom), 4326)
    ELSE public.ST_MakeEnvelope(-180, -90, 180, 90, 4326)
  END
$function$;

CREATE OR REPLACE FUNCTION essentials.log_boundary_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  -- Opt-in escape hatch for repairs that move no line (an SRID fix, ST_MakeValid):
  --   SET LOCAL ev.boundary_change_silent = 'on';
  -- Without it a repair re-asks the people in that area, which is the safe failure.
  IF coalesce(current_setting('ev.boundary_change_silent', true), '') = 'on' THEN
    RETURN NULL;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF essentials.is_basic_district_layer(NEW.mtfcc) AND NEW.geometry IS NOT NULL THEN
      INSERT INTO essentials.boundary_changes (kind, geo_id, mtfcc, state, extent)
      VALUES ('insert', NEW.geo_id, NEW.mtfcc, NEW.state, essentials.boundary_extent_4326(NEW.geometry));
    END IF;
    RETURN NULL;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF essentials.is_basic_district_layer(OLD.mtfcc) AND OLD.geometry IS NOT NULL THEN
      INSERT INTO essentials.boundary_changes (kind, geo_id, mtfcc, state, extent)
      VALUES ('delete', OLD.geo_id, OLD.mtfcc, OLD.state, essentials.boundary_extent_4326(OLD.geometry));
    END IF;
    RETURN NULL;
  END IF;

  -- UPDATE. A re-key (geo_id or mtfcc) is the old boundary leaving and a new one arriving.
  IF OLD.geo_id IS DISTINCT FROM NEW.geo_id OR OLD.mtfcc IS DISTINCT FROM NEW.mtfcc THEN
    IF essentials.is_basic_district_layer(OLD.mtfcc) AND OLD.geometry IS NOT NULL THEN
      INSERT INTO essentials.boundary_changes (kind, geo_id, mtfcc, state, extent)
      VALUES ('delete', OLD.geo_id, OLD.mtfcc, OLD.state, essentials.boundary_extent_4326(OLD.geometry));
    END IF;
    IF essentials.is_basic_district_layer(NEW.mtfcc) AND NEW.geometry IS NOT NULL THEN
      INSERT INTO essentials.boundary_changes (kind, geo_id, mtfcc, state, extent)
      VALUES ('insert', NEW.geo_id, NEW.mtfcc, NEW.state, essentials.boundary_extent_4326(NEW.geometry));
    END IF;
    RETURN NULL;
  END IF;

  -- Same boundary. Log only when the SHAPE changed. Compare the bytes: PostGIS `=` on geometry
  -- is not shape equality on every version, and a no-op UPDATE must not re-ask anyone.
  IF essentials.is_basic_district_layer(NEW.mtfcc)
     AND public.ST_AsEWKB(OLD.geometry) IS DISTINCT FROM public.ST_AsEWKB(NEW.geometry) THEN
    INSERT INTO essentials.boundary_changes (kind, geo_id, mtfcc, state, extent)
    VALUES ('update', NEW.geo_id, NEW.mtfcc, coalesce(NEW.state, OLD.state),
            coalesce(
              essentials.boundary_extent_4326(public.ST_Collect(
                essentials.boundary_extent_4326(OLD.geometry),
                essentials.boundary_extent_4326(NEW.geometry))),
              essentials.boundary_extent_4326(OLD.geometry),
              essentials.boundary_extent_4326(NEW.geometry)));
  END IF;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION essentials.log_boundary_change() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS geofence_boundaries_log_change ON essentials.geofence_boundaries;
CREATE TRIGGER geofence_boundaries_log_change
  AFTER INSERT OR UPDATE OF geometry, geo_id, mtfcc OR DELETE
  ON essentials.geofence_boundaries
  FOR EACH ROW EXECUTE FUNCTION essentials.log_boundary_change();

-- ── 3. The read-time answer ──────────────────────────────────────────────────────────
-- true when a basic account should re-enter its address:
--   (a) one of its stored district geo_ids no longer exists as a boundary (deleted — including
--       before this log existed), or
--   (b) a logged change after resolved_at touches its county (the county's own shape), or, with
--       no county on file, its state; or, with neither, anywhere.
-- false for an account with no basic row (no address, or a Connected account — the weekly job
-- re-checks those from their point).
--
-- Computed, never stored: a cached "stale" flag would itself go stale.
CREATE OR REPLACE FUNCTION inform.basic_location_needs_confirmation(p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  r          inform.account_jurisdictions%ROWTYPE;
  v_county   public.geometry;
  v_state    text;
BEGIN
  SELECT * INTO r FROM inform.account_jurisdictions WHERE user_id = p_user_id;
  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- (a) A stored district whose boundary is gone.
  IF EXISTS (
    SELECT 1
      FROM unnest(ARRAY[r.congressional_geo_id, r.state_senate_geo_id, r.state_house_geo_id,
                        r.county_geo_id, r.school_district_geo_id, r.city_council_geo_id,
                        r.municipality_geo_id]) AS g(geo_id)
     WHERE g.geo_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = g.geo_id)
  ) THEN
    RETURN true;
  END IF;

  -- (b) A change since resolved_at in the account's county.
  IF r.county_geo_id IS NOT NULL THEN
    SELECT gb.geometry, gb.state INTO v_county, v_state
      FROM essentials.geofence_boundaries gb
     WHERE gb.geo_id = r.county_geo_id AND gb.mtfcc = 'G4020'
     LIMIT 1;
  END IF;

  IF v_county IS NOT NULL THEN
    RETURN EXISTS (
      SELECT 1 FROM essentials.boundary_changes c
       WHERE c.changed_at > r.resolved_at
         -- A district in another state cannot contain this person, even if its box crosses the line.
         AND (c.state = v_state OR c.state IS NULL OR v_state IS NULL)
         AND c.extent OPERATOR(public.&&) essentials.boundary_extent_4326(v_county)
         AND public.ST_Intersects(c.extent, essentials.boundary_extent_4326(v_county))
         AND public.ST_Intersects(c.extent, public.ST_SetSRID(v_county, 4326))
    );
  END IF;

  IF r.state_geo_id IS NOT NULL THEN
    RETURN EXISTS (
      SELECT 1 FROM essentials.boundary_changes c
       WHERE c.changed_at > r.resolved_at
         AND (c.state = r.state_geo_id OR c.state IS NULL)
    );
  END IF;

  RETURN EXISTS (SELECT 1 FROM essentials.boundary_changes c WHERE c.changed_at > r.resolved_at);
END;
$function$;

REVOKE ALL ON FUNCTION inform.basic_location_needs_confirmation(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION inform.basic_location_needs_confirmation(uuid) TO ev_api, service_role;

-- ── Post-verify gate ─────────────────────────────────────────────────────────────────
-- Every probe writes scratch rows inside a sub-block that is then rolled back by raising
-- 'ca0369_undo'; the results are kept in plpgsql variables, which survive the rollback.
DO $$
DECLARE
  v_n0 int; v_after_insert int; v_after_name int; v_after_shape int; v_after_silent int;
  v_after_other_layer int; v_after_delete int; v_delete_kind text; v_delete_box_ok boolean;
  v_user uuid; v_county_pt public.geometry; v_state text;
  v_far_pt public.geometry; v_far_state text;
  v_before boolean; v_in_county boolean; v_far boolean; v_missing boolean; v_nobody boolean;
  v_sq public.geometry;
BEGIN
  -- Trigger behaviour on scratch boundaries.
  BEGIN
    SELECT count(*) INTO v_n0 FROM essentials.boundary_changes;
    v_sq := public.ST_SetSRID(public.ST_MakeEnvelope(-82.56, 35.59, -82.55, 35.60), 4326);

    INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
    VALUES ('ca0369-gate', 'CA_0369 gate', '37', 'G5210', public.ST_Multi(v_sq), 'ca0369-gate');
    SELECT count(*) - v_n0 INTO v_after_insert FROM essentials.boundary_changes;

    UPDATE essentials.geofence_boundaries SET name = 'CA_0369 gate renamed'
     WHERE geo_id = 'ca0369-gate' AND mtfcc = 'G5210';
    -- Same geometry written back: must not log either.
    UPDATE essentials.geofence_boundaries SET geometry = geometry
     WHERE geo_id = 'ca0369-gate' AND mtfcc = 'G5210';
    SELECT count(*) - v_n0 INTO v_after_name FROM essentials.boundary_changes;

    UPDATE essentials.geofence_boundaries
       SET geometry = public.ST_Multi(public.ST_SetSRID(public.ST_MakeEnvelope(-82.56, 35.59, -82.54, 35.60), 4326))
     WHERE geo_id = 'ca0369-gate' AND mtfcc = 'G5210';
    SELECT count(*) - v_n0 INTO v_after_shape FROM essentials.boundary_changes;

    PERFORM set_config('ev.boundary_change_silent', 'on', true);
    UPDATE essentials.geofence_boundaries SET geometry = public.ST_Multi(v_sq)
     WHERE geo_id = 'ca0369-gate' AND mtfcc = 'G5210';
    PERFORM set_config('ev.boundary_change_silent', '', true);
    SELECT count(*) - v_n0 INTO v_after_silent FROM essentials.boundary_changes;

    INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
    VALUES ('ca0369-gate', 'CA_0369 gate other layer', '37', 'G9999', public.ST_Multi(v_sq), 'ca0369-gate');
    SELECT count(*) - v_n0 INTO v_after_other_layer FROM essentials.boundary_changes;

    DELETE FROM essentials.geofence_boundaries WHERE geo_id = 'ca0369-gate' AND mtfcc = 'G5210';
    SELECT count(*) - v_n0 INTO v_after_delete FROM essentials.boundary_changes;
    SELECT kind, public.ST_Equals(extent, v_sq) INTO v_delete_kind, v_delete_box_ok
      FROM essentials.boundary_changes ORDER BY id DESC LIMIT 1;

    RAISE EXCEPTION 'ca0369_undo';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'ca0369_undo' THEN RAISE; END IF;
  END;

  IF v_after_insert <> 1 THEN RAISE EXCEPTION 'CA_0369 gate: insert logged % rows, expected 1', v_after_insert; END IF;
  IF v_after_name <> 1 THEN RAISE EXCEPTION 'CA_0369 gate: a name-only / same-shape update logged % extra rows', v_after_name - 1; END IF;
  IF v_after_shape <> 2 THEN RAISE EXCEPTION 'CA_0369 gate: a shape update logged % rows, expected 1', v_after_shape - 1; END IF;
  IF v_after_silent <> 2 THEN RAISE EXCEPTION 'CA_0369 gate: a silent update logged % rows, expected 0', v_after_silent - 2; END IF;
  IF v_after_other_layer <> 2 THEN RAISE EXCEPTION 'CA_0369 gate: a non-district layer logged % rows, expected 0', v_after_other_layer - 2; END IF;
  IF v_after_delete <> 3 OR v_delete_kind <> 'delete' OR NOT v_delete_box_ok THEN
    RAISE EXCEPTION 'CA_0369 gate: delete logged % rows (kind %, old box %), expected 1 delete with the old box',
      v_after_delete - 2, v_delete_kind, v_delete_box_ok;
  END IF;
  IF (SELECT count(*) FROM essentials.boundary_changes) <> v_n0 THEN
    RAISE EXCEPTION 'CA_0369 gate: scratch log rows survived the undo';
  END IF;

  -- No basic row → false.
  v_nobody := inform.basic_location_needs_confirmation('00000000-0000-0000-0000-000000000000');
  IF v_nobody THEN RAISE EXCEPTION 'CA_0369 gate: an account with no address reads true'; END IF;

  -- The read function, against a real basic row with a county (if there is one).
  SELECT aj.user_id, public.ST_PointOnSurface(gb.geometry), gb.state
    INTO v_user, v_county_pt, v_state
    FROM inform.account_jurisdictions aj
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = aj.county_geo_id AND gb.mtfcc = 'G4020'
   ORDER BY aj.resolved_at
   LIMIT 1;

  IF v_user IS NULL THEN
    RAISE NOTICE 'CA_0369 gate: no basic row with a county — read-function probes skipped';
  ELSE
    -- A county in another state, far away, for the negative probe.
    SELECT public.ST_PointOnSurface(gb.geometry), gb.state INTO v_far_pt, v_far_state
      FROM essentials.geofence_boundaries gb
     WHERE gb.mtfcc = 'G4020' AND gb.state <> v_state AND gb.state = '06'
     LIMIT 1;

    v_before := inform.basic_location_needs_confirmation(v_user);

    BEGIN
      INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
      VALUES ('ca0369-gate-far', 'CA_0369 gate far', v_far_state, 'G5220',
              public.ST_Multi(public.ST_Buffer(v_far_pt, 0.001, 2)), 'ca0369-gate');
      v_far := inform.basic_location_needs_confirmation(v_user);

      INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
      VALUES ('ca0369-gate-near', 'CA_0369 gate near', v_state, 'G5220',
              public.ST_Multi(public.ST_Buffer(v_county_pt, 0.001, 2)), 'ca0369-gate');
      v_in_county := inform.basic_location_needs_confirmation(v_user);
      RAISE EXCEPTION 'ca0369_undo';
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> 'ca0369_undo' THEN RAISE; END IF;
    END;

    BEGIN
      UPDATE inform.account_jurisdictions SET state_house_geo_id = 'ca0369-gate-missing' WHERE user_id = v_user;
      v_missing := inform.basic_location_needs_confirmation(v_user);
      RAISE EXCEPTION 'ca0369_undo';
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> 'ca0369_undo' THEN RAISE; END IF;
    END;

    IF v_before THEN RAISE EXCEPTION 'CA_0369 gate: basic row % reads true before any change', v_user; END IF;
    IF v_far THEN RAISE EXCEPTION 'CA_0369 gate: a change in another state (%) asked basic row %', v_far_state, v_user; END IF;
    IF NOT v_in_county THEN RAISE EXCEPTION 'CA_0369 gate: a change inside its county did not ask basic row %', v_user; END IF;
    IF NOT v_missing THEN RAISE EXCEPTION 'CA_0369 gate: a vanished district did not ask basic row %', v_user; END IF;
    IF inform.basic_location_needs_confirmation(v_user) THEN
      RAISE EXCEPTION 'CA_0369 gate: basic row % reads true after the undo', v_user;
    END IF;
  END IF;

  RAISE NOTICE 'CA_0369 gate OK: trigger 6/6 probes; read function before=% far=% in_county=% missing=% nobody=%',
    v_before, v_far, v_in_county, v_missing, v_nobody;
END $$;

COMMIT;
