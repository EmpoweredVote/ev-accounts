import { Router } from 'express';

const router = Router();

router.get('/', (_req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

// ---------------------------------------------------------------------------
// TEMPORARY — geocoding source egress probe.  REMOVE AFTER MEASUREMENT.
//
// Why this exists: the NAD fallback added in #312 works from a developer machine
// (9 of 10 cold lookups inside 12s) and mostly does not work from Render (1 of 6),
// with the attributed log line `[geocoding] NAD: timed out after 11978ms`. The
// suspicion is that ArcGIS Online throttles datacenter egress. That cannot be
// tested from a laptop — the whole question is what THIS network can reach — so
// the probe has to run here.
//
// Safety, since this is unauthenticated on a production API:
//   - Targets are a FIXED list of public government endpoints. No user input
//     reaches a URL, so this is not an SSRF vector.
//   - Results cache for 60s, so it cannot be used to generate outbound traffic.
//   - It returns timings and result counts only. No address, no coordinates.
//
// Delete this route, and PROBE_TARGETS, once the numbers are recorded.
// ---------------------------------------------------------------------------

const PROBE_TIMEOUT_MS = 20000;
const PROBE_CACHE_MS = 60000;

/** All four probes ask the same real question: where is 525 Citrine Ln, Arden NC 28704? */
const PROBE_TARGETS: Array<{ name: string; host: string; url: string; count: (b: any) => number }> = [
  {
    name: 'NAD (current fallback)',
    host: 'services.arcgis.com',
    url:
      'https://services.arcgis.com/xOi1kZaI0eWDREZv/ArcGIS/rest/services/' +
      'Address_Points_from_National_Address_Database_view/FeatureServer/0/query' +
      "?where=Add_Number%3D525%20AND%20Zip_Code%3D'28704'" +
      '&geometry=-82.66251599990272,35.41611400024333,-82.47586499968763,35.50190800021025' +
      '&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects' +
      '&outFields=Add_Number,St_Name&returnGeometry=true&outSR=4326&f=json',
    count: (b) => b?.features?.length ?? -1,
  },
  {
    name: 'NC OneMap AddressNC',
    host: 'services.nconemap.gov',
    url:
      'https://services.nconemap.gov/secure/rest/services/AddressNC/NC1Map_Addresses/MapServer/0/query' +
      "?where=UPPER(ST_NAME)%20LIKE%20'%25CITRINE%25'" +
      '&outFields=ST_NAME&returnGeometry=true&outSR=4326&resultRecordCount=5&f=json',
    count: (b) => b?.features?.length ?? -1,
  },
  {
    name: 'Buncombe County GeocodeServer',
    host: 'gis.buncombecounty.org',
    url:
      'https://gis.buncombecounty.org/arcgis/rest/services/AddressSearch2/GeocodeServer/findAddressCandidates' +
      '?SingleLine=525%20Citrine%20Ln&outSR=4326&outFields=*&f=json',
    count: (b) => b?.candidates?.length ?? -1,
  },
  {
    name: 'TIGERweb ZCTA (control, known good)',
    host: 'tigerweb.geo.census.gov',
    url:
      'https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/' +
      'PUMA_TAD_TAZ_UGA_ZCTA/MapServer/11/query' +
      "?where=BASENAME%3D'28704'&returnExtentOnly=true&outSR=4326&f=json",
    count: (b) => (b?.extent ? 1 : 0),
  },
];

let cached: { at: number; body: unknown } | null = null;

router.get('/geocode-sources', async (_req, res) => {
  if (cached && Date.now() - cached.at < PROBE_CACHE_MS) {
    res.json({ ...(cached.body as object), cached: true });
    return;
  }

  const results = [];
  for (const target of PROBE_TARGETS) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    const started = Date.now();
    try {
      const response = await fetch(target.url, {
        signal: controller.signal,
        headers: { 'User-Agent': 'EmpoweredVote/1.0 (+https://empowered.vote)', Accept: 'application/json' },
      });
      const body = await response.json();
      results.push({
        source: target.name,
        host: target.host,
        ms: Date.now() - started,
        http: response.status,
        results: target.count(body),
        error: (body as { error?: { message?: string } })?.error?.message ?? null,
      });
    } catch (err: unknown) {
      results.push({
        source: target.name,
        host: target.host,
        ms: Date.now() - started,
        http: null,
        results: -1,
        error: (err as { name?: string })?.name === 'AbortError' ? `aborted at ${PROBE_TIMEOUT_MS}ms` : 'network error',
      });
    } finally {
      clearTimeout(timer);
    }
  }

  const body = { probedAt: new Date().toISOString(), timeoutMs: PROBE_TIMEOUT_MS, results };
  cached = { at: Date.now(), body };
  res.json({ ...body, cached: false });
});

export default router;
