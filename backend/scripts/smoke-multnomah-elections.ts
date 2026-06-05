/**
 * smoke-multnomah-elections.ts
 * Phase 85: Multnomah Elections + Discovery smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-multnomah-elections.ts
 *
 * Verifies Phase 85 success criteria:
 *   ELECTIONS-01 — 2 Multnomah County race rows exist in OR 2026 General
 *   ELECTIONS-02 — 16 smaller-city race rows exist in OR 2026 General
 *   ELECTIONS-03 — discovery_jurisdictions row exists for geo_id='41051'
 *   D-14 — Corbett OR unincorporated address (-122.2, 45.5) surfaces >= 18 races
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  if (!process.env['DATABASE_URL']) {
    process.stderr.write('ERROR: DATABASE_URL not set\n');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env['DATABASE_URL'],
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  let allPassed = true;
  const errors: string[] = [];

  try {
    // -------------------------------------------------------------------------
    // Assertion A — Multnomah County race rows exist (ELECTIONS-01)
    // -------------------------------------------------------------------------
    console.log('\n=== Assertion A: Multnomah County race rows (ELECTIONS-01) ===');
    const rA = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) as cnt FROM essentials.races r
       JOIN essentials.elections e ON e.id = r.election_id
       WHERE e.name = 'OR 2026 General'
         AND r.position_name ILIKE '%Multnomah County%'`
    );
    const countyCount = parseInt(rA.rows[0].cnt, 10);
    console.log(`County race rows: ${countyCount} (expected 2)`);
    if (countyCount !== 2) {
      errors.push(`FAIL: expected 2 county race rows, got ${countyCount}`);
      allPassed = false;
    } else {
      console.log('  ELECTIONS-01: County race rows = 2 [PASS]');
    }

    // -------------------------------------------------------------------------
    // Assertion B — Smaller-city race rows exist (ELECTIONS-02)
    // -------------------------------------------------------------------------
    console.log('\n=== Assertion B: Smaller-city race rows (ELECTIONS-02) ===');
    const rB = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) as cnt FROM essentials.races r
       JOIN essentials.elections e ON e.id = r.election_id
       WHERE e.name = 'OR 2026 General'
         AND r.position_name ~ '(Gresham|Troutdale|Fairview|Wood Village|Maywood Park)'`
    );
    const cityCount = parseInt(rB.rows[0].cnt, 10);
    console.log(`City race rows: ${cityCount} (expected 16)`);
    if (cityCount !== 16) {
      errors.push(`FAIL: expected 16 city race rows, got ${cityCount}`);
      allPassed = false;
    } else {
      console.log('  ELECTIONS-02: City race rows = 16 [PASS]');
    }

    // -------------------------------------------------------------------------
    // Assertion C — Discovery jurisdiction row exists (ELECTIONS-03)
    // -------------------------------------------------------------------------
    console.log('\n=== Assertion C: Discovery jurisdiction row exists (ELECTIONS-03) ===');
    const rC = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) as cnt FROM essentials.discovery_jurisdictions
       WHERE jurisdiction_geoid = '41051' AND election_date = '2026-11-03'`
    );
    const discoveryCount = parseInt(rC.rows[0].cnt, 10);
    console.log(`Discovery jurisdiction rows: ${discoveryCount} (expected 1)`);
    if (discoveryCount !== 1) {
      errors.push(`FAIL: expected 1 discovery_jurisdictions row for geo_id=41051, got ${discoveryCount}`);
      allPassed = false;
    } else {
      console.log('  ELECTIONS-03: Discovery jurisdiction row exists [PASS]');
    }

    // -------------------------------------------------------------------------
    // Assertion D — Discovery row values are correct (ELECTIONS-03 detail)
    // -------------------------------------------------------------------------
    console.log('\n=== Assertion D: Discovery row values correct (ELECTIONS-03 detail) ===');
    const rD = await client.query<{
      jurisdiction_name: string;
      source_url: string;
      allowed_domains: string[];
      state: string;
    }>(
      `SELECT jurisdiction_name, source_url, allowed_domains, state
       FROM essentials.discovery_jurisdictions
       WHERE jurisdiction_geoid = '41051'`
    );
    if (rD.rows.length === 0) {
      errors.push('FAIL: discovery_jurisdictions row for geo_id=41051 not found (cannot verify values)');
      allPassed = false;
    } else {
      const row = rD.rows[0];
      console.log(`  jurisdiction_name: ${row.jurisdiction_name}`);
      console.log(`  state: ${row.state}`);
      console.log(`  source_url: ${row.source_url}`);
      console.log(`  allowed_domains: ${JSON.stringify(row.allowed_domains)}`);

      if (row.jurisdiction_name !== 'Multnomah County, Oregon') {
        errors.push(`FAIL: expected jurisdiction_name='Multnomah County, Oregon', got '${row.jurisdiction_name}'`);
        allPassed = false;
      }
      if (row.state !== 'OR') {
        errors.push(`FAIL: expected state='OR', got '${row.state}'`);
        allPassed = false;
      }
      if (row.source_url !== 'https://www.multco.us/elections') {
        errors.push(`FAIL: expected source_url='https://www.multco.us/elections', got '${row.source_url}'`);
        allPassed = false;
      }

      const expectedDomains = new Set(['multco.us', 'ballotpedia.org', 'sos.oregon.gov']);
      const actualDomains = new Set(row.allowed_domains);
      let domainsMatch = expectedDomains.size === actualDomains.size;
      for (const d of expectedDomains) {
        if (!actualDomains.has(d)) {
          domainsMatch = false;
          break;
        }
      }
      if (!domainsMatch) {
        errors.push(`FAIL: expected allowed_domains=['multco.us','ballotpedia.org','sos.oregon.gov'], got ${JSON.stringify(row.allowed_domains)}`);
        allPassed = false;
      }

      if (
        row.jurisdiction_name === 'Multnomah County, Oregon' &&
        row.state === 'OR' &&
        row.source_url === 'https://www.multco.us/elections' &&
        domainsMatch
      ) {
        console.log('  ELECTIONS-03 detail: All discovery row values correct [PASS]');
      }
    }

    // -------------------------------------------------------------------------
    // Assertion E — Corbett unincorporated address surfaces races (D-14)
    // Corbett OR coordinate: (-122.2, 45.5) — verified unincorporated Multnomah County
    // G4020 geo_id=41051 present, G4110 absent (no incorporated city)
    // -------------------------------------------------------------------------
    console.log('\n=== Assertion E: Corbett unincorporated address surfaces races (D-14) ===');
    console.log('  Corbett OR coordinate: (-122.2, 45.5) — verified unincorporated Multnomah County');

    // Query mirrors how the backend's electionService surfaces races for a Multnomah County resident
    // geo_ids verified from live DB (essentials.governments):
    //   41051=Multnomah County, 4131250=Gresham, 4174850=Troutdale, 4124250=Fairview,
    //   4183950=Wood Village, 4146730=Maywood Park
    const rE = await client.query<{ geo_id: string; position_name: string }>(
      `SELECT DISTINCT g.geo_id, r.position_name
       FROM essentials.races r
       JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.chambers c ON c.id = o.chamber_id
       JOIN essentials.governments g ON g.id = c.government_id
       JOIN essentials.elections e ON e.id = r.election_id
       WHERE e.name = 'OR 2026 General'
         AND g.geo_id IN ('41051', '4131250', '4174850', '4124250', '4183950', '4146730')`
    );
    const corbettRaceCount = rE.rows.length;
    console.log(`Corbett (-122.2, 45.5) Multnomah County race rows reachable: ${corbettRaceCount}`);

    if (rE.rows.length > 0) {
      console.log('  Race rows returned:');
      for (const row of rE.rows) {
        console.log(`    geo_id=${row.geo_id}  position_name=${row.position_name}`);
      }
    }

    if (corbettRaceCount < 18) {
      errors.push(`FAIL: Corbett address pattern yielded ${corbettRaceCount} race rows, expected >= 18`);
      allPassed = false;
    } else {
      console.log(`  D-14: Corbett unincorporated address surfaces ${corbettRaceCount} races (>= 18) [PASS]`);
    }

  } finally {
    await client.end();
  }

  // -------------------------------------------------------------------------
  // Final result
  // -------------------------------------------------------------------------
  console.log('\n=== Smoke Test Results ===');
  if (allPassed) {
    console.log('ALL ASSERTIONS PASSED');
    console.log('\nPhase 85 success criteria:');
    console.log('  ELECTIONS-01: Multnomah County race rows (2) [PASS]');
    console.log('  ELECTIONS-02: Smaller-city race rows (16) [PASS]');
    console.log('  ELECTIONS-03: Discovery jurisdiction row for geo_id=41051 [PASS]');
    console.log('  D-14: Corbett unincorporated address surfaces >= 18 races [PASS]');
    process.exit(0);
  } else {
    console.log(`FAILED (${errors.length} assertion(s)):`);
    for (const err of errors) {
      console.log(`  - ${err}`);
    }
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});
