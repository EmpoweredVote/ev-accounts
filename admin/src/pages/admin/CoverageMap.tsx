/**
 * CoverageMap — self-contained choropleth. Owns its own zoom/pan + hover state;
 * the parent passes the score maps + selection (which state/county is active,
 * to drive the breadcrumb + table) and gets onSelectState/onSelectCounty back.
 *
 * Completeness mode: BIVARIATE fill (breadth × depth) + rich hover cards + 2D
 * legend. Elections mode: original single-hue fill + text readout (unchanged).
 */
import { useEffect, useRef, useState, useCallback, type ReactNode } from 'react';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import { bivariateColor, NOT_STARTED } from './coverageBivariate';
import { BivariateLegend } from './BivariateLegend';
import { StateHoverCard, CountyHoverCard } from './CoverageHoverCard';
import type { StateScore, CountyScore, StateElection, CountyElection, Metric } from './coverageTypes';

const STATES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json';
const COUNTIES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/counties-10m.json';
const NO_RACE_DATA = '#3f3f46';
const MAP_W = 800;
const MAP_H = 600;

// Elections single-hue ramp (UNCHANGED from the old map).
const RAMP_FROM = [0x8c, 0xcd, 0xd9];
const RAMP_TO = [0x00, 0x4e, 0x63];
function scoreColor(score: number | undefined): string {
  if (score == null || score <= 0) return NOT_STARTED;
  const t = Math.pow(Math.min(1, score / 100), 0.55);
  const ch = (i: number) => Math.round(RAMP_FROM[i] + (RAMP_TO[i] - RAMP_FROM[i]) * t);
  return `rgb(${ch(0)}, ${ch(1)}, ${ch(2)})`;
}
function electionStateColor(s: StateElection | undefined): string { return s ? scoreColor(s.coverage) : NOT_STARTED; }
function electionCountyColor(c: CountyElection | undefined): string {
  if (!c) return NOT_STARTED;
  if (c.status === 'unknown') return NO_RACE_DATA;
  return scoreColor(c.coverage <= 0 ? 0.01 : c.coverage);
}

type Hover = { level: 'state' | 'county'; fips: string; name: string } | null;

interface Props {
  metric: Metric;
  stateByFips: Map<string, StateScore>;
  countyByFips: Map<string, CountyScore>;
  elecStatesByFips: Map<string, StateElection>;
  elecCountiesByFips: Map<string, CountyElection>;
  elecDate: { date: string; type: string } | null;
  selected: { fips: string; name: string; code?: string } | null;
  selectedCountyFips: string | null;
  onSelectState: (fips: string, name: string, geo: unknown) => void;
  onSelectCounty: (fips: string) => void;
}

export function CoverageMap(props: Props) {
  const { metric, stateByFips, countyByFips, elecStatesByFips, elecCountiesByFips, selected, selectedCountyFips } = props;
  const [center, setCenter] = useState<[number, number]>([-96, 38]);
  const [zoom, setZoom] = useState(1);
  const [hover, setHover] = useState<Hover>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const pathRef = useRef<any>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const projRef = useRef<any>(null);

  const fitToFeature = useCallback((geo: unknown) => {
    const path = pathRef.current;
    const proj = projRef.current;
    if (!path || !proj) { setCenter([-96, 38]); setZoom(3); return; }
    const [[x0, y0], [x1, y1]] = path.bounds(geo) as [[number, number], [number, number]];
    const boxW = x1 - x0;
    const boxH = y1 - y0;
    if (!Number.isFinite(boxW) || !Number.isFinite(boxH) || boxW <= 0 || boxH <= 0) { setZoom(3); return; }
    const k = Math.min(MAP_W / boxW, MAP_H / boxH) * 0.85;
    const inv = proj.invert?.([(x0 + x1) / 2, (y0 + y1) / 2]) as [number, number] | null;
    if (inv && Number.isFinite(inv[0]) && Number.isFinite(inv[1])) setCenter(inv);
    setZoom(Math.min(12, Math.max(1, k)));
  }, []);

  // Reset framing + hover when the parent clears the selection (back to US).
  useEffect(() => {
    if (!selected) { setCenter([-96, 38]); setZoom(1); setHover(null); }
  }, [selected]);

  const handleSelectState = (fips: string, name: string, geo: unknown) => {
    setHover(null);
    fitToFeature(geo);
    props.onSelectState(fips, name, geo);
  };

  // Completeness hover card.
  let hoverCard: ReactNode = null;
  if (hover && metric === 'completeness') {
    if (hover.level === 'state') {
      const sc = stateByFips.get(hover.fips);
      if (sc) hoverCard = <StateHoverCard s={sc} />;
    } else {
      const cs = countyByFips.get(hover.fips);
      if (cs) hoverCard = <CountyHoverCard c={cs} />;
    }
  }

  // Elections text readout.
  let elecReadout: ReactNode = null;
  if (hover && metric === 'elections') {
    if (hover.level === 'state') {
      const es = elecStatesByFips.get(hover.fips);
      elecReadout = (
        <>
          <span className="font-medium">{hover.name}</span>
          {es ? <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400">{es.coverage}%</span> : <span className="ml-2 text-gray-400">no upcoming election</span>}
        </>
      );
    } else {
      const ec = elecCountiesByFips.get(hover.fips);
      elecReadout = (
        <>
          <span className="font-medium">{hover.name}</span>
          {!ec || ec.status === 'unknown' ? <span className="ml-2 text-gray-400">no race data</span> : <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400">{ec.coverage}%</span>}
        </>
      );
    }
  }

  return (
    <div className="relative">
      <div className="relative overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
        {hoverCard && <div className="pointer-events-none absolute left-3 top-3 z-20">{hoverCard}</div>}
        <ComposableMap projection="geoAlbersUsa" width={MAP_W} height={MAP_H} style={{ width: '100%', height: 'auto' }}>
          <ZoomableGroup center={center} zoom={zoom} minZoom={1} maxZoom={12}>
            {!selected ? (
              <Geographies geography={STATES_TOPO}>
                {({ geographies, path, projection }) => {
                  pathRef.current = path;
                  projRef.current = projection;
                  return geographies.map((geo) => {
                    const sc = stateByFips.get(geo.id as string);
                    const es = elecStatesByFips.get(geo.id as string);
                    const fill = metric === 'elections' ? electionStateColor(es) : (sc ? bivariateColor(sc.breadth, sc.depth) : NOT_STARTED);
                    return (
                      <Geography
                        key={geo.rsmKey}
                        geography={geo}
                        onMouseEnter={() => setHover({ level: 'state', fips: geo.id as string, name: geo.properties.name })}
                        onMouseLeave={() => setHover(null)}
                        onClick={() => handleSelectState(geo.id as string, geo.properties.name, geo)}
                        style={{
                          default: { fill, stroke: '#fff', strokeWidth: 0.5, outline: 'none' },
                          hover: { fill, stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: 'pointer' },
                          pressed: { fill, outline: 'none' },
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
                      const ec = elecCountiesByFips.get(geo.id as string);
                      const fill = metric === 'elections' ? electionCountyColor(ec) : (cs ? bivariateColor(cs.breadth, cs.depth) : NOT_STARTED);
                      const isSel = selectedCountyFips === geo.id;
                      return (
                        <Geography
                          key={geo.rsmKey}
                          geography={geo}
                          onMouseEnter={() => setHover({ level: 'county', fips: geo.id as string, name: geo.properties.name })}
                          onMouseLeave={() => setHover(null)}
                          onClick={() => props.onSelectCounty(geo.id as string)}
                          style={{
                            default: { fill, stroke: isSel ? '#00657c' : '#fff', strokeWidth: isSel ? 1.5 : 0.5, outline: 'none' },
                            hover: { fill, stroke: '#00657c', strokeWidth: 1.2, outline: 'none', cursor: 'pointer' },
                            pressed: { fill, outline: 'none' },
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

      {/* Readout (elections) + legend */}
      <div className="mt-2 flex items-center justify-between text-sm">
        <div className="text-gray-600 dark:text-gray-300">
          {metric === 'elections'
            ? (elecReadout ?? <span className="text-gray-400">{selected ? 'Hover a county' : 'Hover a state'}</span>)
            : <span className="text-gray-400">{selected ? 'Click a county; hover for detail' : 'Click a state to drill in; hover for detail'}</span>}
        </div>
        {metric === 'completeness' ? (
          <BivariateLegend />
        ) : (
          <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
            {props.elecDate && <span className="font-medium capitalize text-gray-600 dark:text-gray-300">{props.elecDate.type} · {props.elecDate.date}</span>}
            <span className="inline-flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NO_RACE_DATA }} /> no race data</span>
            <span className="inline-flex items-center gap-1.5"><span>low</span><div className="h-2 w-24 rounded-full" style={{ background: `linear-gradient(to right, ${scoreColor(5)}, ${scoreColor(45)}, ${scoreColor(100)})` }} /><span>high</span></span>
          </div>
        )}
      </div>
    </div>
  );
}
