/**
 * CoverageMapPage — choropleth view of data coverage.
 *
 *   US states  → click a state → that state's counties → click a county →
 *   jurisdiction drill-down panel (reusing the shared coverage cells).
 *
 * Fill colour is a composite-completeness % from GET /api/admin/coverage/map.
 * Tracked states/counties get a teal gradient; untracked geographies render in
 * neutral grey ("not started"). TopoJSON (us-atlas) is fetched from CDN, so no
 * polygons are bundled and none ship through our API.
 */
import { useEffect, useMemo, useRef, useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import { apiFetch } from '../../lib/api';
import { Bool, Chip, Stances, Roster, ratioToTristate, type Tristate } from './coverageCells';

const STATES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json';
const COUNTIES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/counties-10m.json';

type MapLevel = 'county' | 'local' | 'school';

interface StateScore {
  fips: string;
  code: string;
  name: string;
  score: number;
  jurisdiction_count: number;
  populated_count: number;
}

interface JurisdictionScore {
  ocd_id: string;
  name: string;
  level: MapLevel;
  county_fips: string | null;
  score: number;
  populated: boolean;
  roster_actual: number;
  expected_seats: number | null;
  headshots: { withPhoto: number; total: number };
  stances: { researched: number; total: number };
  geofenced: boolean;
  treasury: Tristate;
  donors: Tristate;
}

interface CountyScore {
  fips: string;
  name: string;
  score: number;
  jurisdiction_count: number;
  populated_count: number;
  jurisdictions: JurisdictionScore[];
}

// ── colour ramp ──────────────────────────────────────────────────────────────
const NOT_STARTED = '#e5e7eb'; // gray-200 — untracked / no score
// light → EV muted-blue. Scores cluster low today, so even ~20% reads as a tint.
const RAMP_FROM = [0xee, 0xf6, 0xf8];
const RAMP_TO = [0x00, 0x65, 0x7c];

function scoreColor(score: number | undefined): string {
  if (score == null) return NOT_STARTED;
  const t = Math.max(0, Math.min(1, score / 100));
  const ch = (i: number) => Math.round(RAMP_FROM[i] + (RAMP_TO[i] - RAMP_FROM[i]) * t);
  return `rgb(${ch(0)}, ${ch(1)}, ${ch(2)})`;
}

const LEVEL_LABEL: Record<MapLevel, string> = { county: 'County govt', local: 'City / Town', school: 'School District' };

// ComposableMap viewBox dimensions — used to fit a state to the viewport.
const MAP_W = 800;
const MAP_H = 600;

// ── component ─────────────────────────────────────────────────────────────────
export function CoverageMapPage() {
  const [states, setStates] = useState<StateScore[]>([]);
  const [selected, setSelected] = useState<{ fips: string; name: string; code?: string } | null>(null);
  const [counties, setCounties] = useState<CountyScore[]>([]);
  const [selectedCounty, setSelectedCounty] = useState<CountyScore | null>(null);
  const [hover, setHover] = useState<{ name: string; score?: number } | null>(null);
  const [center, setCenter] = useState<[number, number]>([-96, 38]);
  const [zoom, setZoom] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Captured from the Geographies render-prop — the live projection is the same
  // for both topojson sources, so we can use it to fit a clicked state exactly.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const pathRef = useRef<any>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const projRef = useRef<any>(null);

  // Fit a feature (a state) to the viewport using its projected pixel bounds.
  const fitToFeature = useCallback((geo: unknown) => {
    const path = pathRef.current;
    const proj = projRef.current;
    if (!path || !proj) {
      setCenter([-96, 38]);
      setZoom(3);
      return;
    }
    const [[x0, y0], [x1, y1]] = path.bounds(geo) as [[number, number], [number, number]];
    const boxW = x1 - x0;
    const boxH = y1 - y0;
    if (!Number.isFinite(boxW) || !Number.isFinite(boxH) || boxW <= 0 || boxH <= 0) {
      setZoom(3);
      return;
    }
    const k = Math.min(MAP_W / boxW, MAP_H / boxH) * 0.85;
    const inv = proj.invert?.([(x0 + x1) / 2, (y0 + y1) / 2]) as [number, number] | null;
    if (inv && Number.isFinite(inv[0]) && Number.isFinite(inv[1])) setCenter(inv);
    setZoom(Math.min(12, Math.max(1, k)));
  }, []);

  // US-level scores
  useEffect(() => {
    apiFetch<{ states: StateScore[] }>(`/admin/coverage/map?level=state`)
      .then((res) => setStates(res.states))
      .catch((err) => setError(err.message));
  }, []);

  const stateByFips = useMemo(() => {
    const m = new Map<string, StateScore>();
    for (const s of states) m.set(s.fips, s);
    return m;
  }, [states]);

  const countyByFips = useMemo(() => {
    const m = new Map<string, CountyScore>();
    for (const c of counties) m.set(c.fips, c);
    return m;
  }, [counties]);

  const enterState = useCallback((fips: string, name: string, geo: unknown) => {
    const code = stateByFips.get(fips)?.code;
    setSelected({ fips, name, code });
    setSelectedCounty(null);
    setHover(null);
    fitToFeature(geo); // frame the state using its projected bounds
    if (!code) {
      setCounties([]);
      return;
    }
    setLoading(true);
    apiFetch<{ counties: CountyScore[] }>(`/admin/coverage/map?level=county&state=${code}`)
      .then((res) => setCounties(res.counties))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [stateByFips, fitToFeature]);

  const backToUS = useCallback(() => {
    setSelected(null);
    setCounties([]);
    setSelectedCounty(null);
    setHover(null);
    setCenter([-96, 38]);
    setZoom(1);
  }, []);

  return (
    <div>
      {/* Header + breadcrumb */}
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Coverage Map</h1>
          <Link
            to="/admin/coverage"
            className="rounded-md border border-gray-300 px-2.5 py-1 text-xs font-medium text-gray-600 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
          >
            ← Table view
          </Link>
        </div>
        <nav className="text-sm text-gray-500 dark:text-gray-400">
          <button onClick={backToUS} className="hover:text-ev-teal dark:hover:text-ev-teal-light">
            United States
          </button>
          {selected && (
            <>
              <span className="px-1.5">›</span>
              <span className="font-medium text-gray-900 dark:text-white">{selected.name}</span>
            </>
          )}
          {selectedCounty && (
            <>
              <span className="px-1.5">›</span>
              <span className="font-medium text-gray-900 dark:text-white">{selectedCounty.name}</span>
            </>
          )}
        </nav>
      </div>

      {error && (
        <div className="mb-4 rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {/* Map */}
        <div className="relative lg:col-span-2">
          <div className="overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
            <ComposableMap projection="geoAlbersUsa" width={MAP_W} height={MAP_H} style={{ width: '100%', height: 'auto' }}>
              <ZoomableGroup center={center} zoom={zoom} minZoom={1} maxZoom={12}>
                {!selected ? (
                  <Geographies geography={STATES_TOPO}>
                    {({ geographies, path, projection }) => {
                      pathRef.current = path;
                      projRef.current = projection;
                      return geographies.map((geo) => {
                        const sc = stateByFips.get(geo.id as string);
                        return (
                          <Geography
                            key={geo.rsmKey}
                            geography={geo}
                            onMouseEnter={() => setHover({ name: geo.properties.name, score: sc?.score })}
                            onMouseLeave={() => setHover(null)}
                            onClick={() => enterState(geo.id as string, geo.properties.name, geo)}
                            style={{
                              default: { fill: scoreColor(sc?.score), stroke: '#fff', strokeWidth: 0.5, outline: 'none' },
                              hover: { fill: scoreColor(sc?.score), stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: 'pointer' },
                              pressed: { fill: scoreColor(sc?.score), outline: 'none' },
                            }}
                          />
                        );
                      });
                    }}
                  </Geographies>
                ) : (
                  <Geographies geography={COUNTIES_TOPO}>
                    {({ geographies, path, projection }) => {
                      pathRef.current = path;
                      projRef.current = projection;
                      return geographies
                        .filter((geo) => (geo.id as string).startsWith(selected.fips))
                        .map((geo) => {
                          const cs = countyByFips.get(geo.id as string);
                          const isSel = selectedCounty?.fips === geo.id;
                          return (
                            <Geography
                              key={geo.rsmKey}
                              geography={geo}
                              onMouseEnter={() => setHover({ name: geo.properties.name, score: cs?.score })}
                              onMouseLeave={() => setHover(null)}
                              onClick={() => cs && setSelectedCounty(cs)}
                              style={{
                                default: { fill: scoreColor(cs?.score), stroke: isSel ? '#00657c' : '#fff', strokeWidth: isSel ? 1.5 : 0.5, outline: 'none' },
                                hover: { fill: scoreColor(cs?.score), stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: cs ? 'pointer' : 'default' },
                                pressed: { fill: scoreColor(cs?.score), outline: 'none' },
                              }}
                            />
                          );
                        });
                    }}
                  </Geographies>
                )}
              </ZoomableGroup>
            </ComposableMap>
          </div>

          {/* Hover readout + legend */}
          <div className="mt-2 flex items-center justify-between text-sm">
            <div className="text-gray-600 dark:text-gray-300">
              {hover ? (
                <>
                  <span className="font-medium">{hover.name}</span>
                  {hover.score != null ? (
                    <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400">{hover.score}%</span>
                  ) : (
                    <span className="ml-2 text-gray-400">not started</span>
                  )}
                </>
              ) : (
                <span className="text-gray-400">{selected ? 'Click a county for detail' : 'Click a state to drill in'}</span>
              )}
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
              <span>0%</span>
              <div
                className="h-2 w-24 rounded-full"
                style={{ background: `linear-gradient(to right, ${scoreColor(0)}, ${scoreColor(50)}, ${scoreColor(100)})` }}
              />
              <span>100%</span>
              {loading && <span className="ml-2 animate-pulse">loading…</span>}
            </div>
          </div>
        </div>

        {/* Detail panel */}
        <div className="lg:col-span-1">
          {!selected && (
            <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
              <h2 className="mb-2 text-sm font-semibold text-gray-700 dark:text-gray-300">Tracked states</h2>
              <ul className="space-y-1 text-sm">
                {states.length === 0 && <li className="text-gray-400">No coverage files yet.</li>}
                {[...states].sort((a, b) => b.score - a.score).map((s) => (
                  <li key={s.fips} className="flex items-center justify-between">
                    <span className="text-gray-700 dark:text-gray-300">{s.name}</span>
                    <span className="tabular-nums text-gray-500 dark:text-gray-400">{s.score}%</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {selected && !selectedCounty && (
            <div className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-900">
              <h2 className="mb-2 text-sm font-semibold text-gray-700 dark:text-gray-300">
                {selected.name} — counties
              </h2>
              {counties.length === 0 ? (
                <p className="text-sm text-gray-400">
                  {loading ? 'Loading…' : 'Not started — no coverage file for this state yet.'}
                </p>
              ) : (
                <ul className="max-h-[28rem] space-y-1 overflow-auto text-sm">
                  {[...counties].sort((a, b) => b.score - a.score).map((c) => (
                    <li key={c.fips}>
                      <button
                        onClick={() => setSelectedCounty(c)}
                        className="flex w-full items-center justify-between rounded px-2 py-1 text-left hover:bg-gray-50 dark:hover:bg-gray-800"
                      >
                        <span className="text-gray-700 dark:text-gray-300">{c.name}</span>
                        <span className="tabular-nums text-gray-500 dark:text-gray-400">{c.score}%</span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}

          {selectedCounty && (
            <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
              <div className="flex items-center justify-between border-b border-gray-100 p-4 dark:border-gray-800">
                <div>
                  <h2 className="text-sm font-semibold text-gray-900 dark:text-white">{selectedCounty.name}</h2>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    {selectedCounty.score}% · {selectedCounty.populated_count}/{selectedCounty.jurisdiction_count} jurisdictions populated
                  </p>
                </div>
                <button
                  onClick={() => setSelectedCounty(null)}
                  className="text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                >
                  ✕
                </button>
              </div>
              <div className="max-h-[26rem] overflow-auto">
                <table className="w-full text-sm">
                  <thead className="sticky top-0 border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
                    <tr>
                      {['Jurisdiction', 'Geofenced', 'Roster', 'Headshots', 'Stances', 'Treasury', 'Donors', 'Score'].map((h) => (
                        <th key={h} className="whitespace-nowrap px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                    {selectedCounty.jurisdictions.map((j) => (
                      <tr key={j.ocd_id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                        <td className="px-3 py-2">
                          <div className="font-medium text-gray-900 dark:text-white">{j.name}</div>
                          <div className="text-[10px] uppercase tracking-wide text-gray-400">{LEVEL_LABEL[j.level]}</div>
                        </td>
                        <td className="px-3 py-2"><Bool value={j.geofenced} /></td>
                        <td className="px-3 py-2">
                          <Roster
                            actual={j.roster_actual}
                            expected={j.expected_seats}
                            complete={j.expected_seats != null && j.roster_actual >= j.expected_seats}
                          />
                        </td>
                        <td className="px-3 py-2">
                          <Chip value={ratioToTristate(j.headshots.withPhoto, j.headshots.total)} />
                        </td>
                        <td className="px-3 py-2">
                          <Stances s={j.stances} />
                        </td>
                        <td className="px-3 py-2"><Chip value={j.treasury} /></td>
                        <td className="px-3 py-2"><Chip value={j.donors} /></td>
                        <td className="px-3 py-2 tabular-nums text-gray-600 dark:text-gray-400">{j.score}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
