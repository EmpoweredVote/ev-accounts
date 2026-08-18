/**
 * CoverageMap — self-contained choropleth. Owns its own zoom/pan + hover state;
 * the parent passes the score maps + selection (which state/county is active,
 * to drive the breadcrumb + table) and gets onSelectState/onSelectCounty back.
 *
 * Completeness mode: honest single-gradient fill (composite score → sage→purple
 * →yellow) + a cursor-following hover card + a gradient legend overlaid in the
 * map. Elections mode: original single-hue fill + text readout (unchanged).
 *
 * The map auto-frames the selected state from its county geometry, so selecting
 * a state via the US table (not just clicking the map) also zooms the map in.
 */
import { useEffect, useRef, useState, useCallback, type ReactNode } from 'react';
import { ComposableMap, Geographies, Geography, ZoomableGroup } from 'react-simple-maps';
import { completenessColor, NOT_STARTED } from './completenessColor';
import { CompletenessLegend } from './CompletenessLegend';
import { ElectionsTierLegend } from './ElectionsTierLegend';
import { StateHoverCard, CountyHoverCard, FederalHoverCard } from './CoverageHoverCard';
import type { StateScore, CountyScore, StateElection, CountyElection, Metric } from './coverageTypes';

const STATES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json';
const COUNTIES_TOPO = 'https://cdn.jsdelivr.net/npm/us-atlas@3/counties-10m.json';
const NO_RACE_DATA = '#3f3f46';
const MAP_W = 800;
const MAP_H = 600;
// Cap the rendered map height so the table below it stays visible without scrolling.
const MAP_MAX_HEIGHT_VH = 56;

// Elections single-hue ramp (UNCHANGED from the old map).
const RAMP_FROM = [0x8c, 0xcd, 0xd9];
const RAMP_TO = [0x00, 0x4e, 0x63];
function scoreColor(score: number | undefined): string {
  if (score == null || score <= 0) return NOT_STARTED;
  const t = Math.pow(Math.min(1, score / 100), 0.55);
  const ch = (i: number) => Math.round(RAMP_FROM[i] + (RAMP_TO[i] - RAMP_FROM[i]) * t);
  return `rgb(${ch(0)}, ${ch(1)}, ${ch(2)})`;
}
function electionStateColor(s: StateElection | undefined): string {
  if (!s) return NOT_STARTED;
  if (s.races_total === 0) return NO_RACE_DATA;
  return scoreColor(s.depthScore <= 0 ? 0.01 : s.depthScore);
}
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
  // geo is consumed internally for viewport framing — the parent only needs fips + name.
  onSelectState: (fips: string, name: string) => void;
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
  // Which state we've already framed — prevents re-fitting on every re-render.
  const framedFipsRef = useRef<string | null>(null);

  // Hover-card positioning is done by direct DOM writes (no per-mousemove
  // setState) so dragging the cursor across thousands of counties stays smooth.
  const mapRef = useRef<HTMLDivElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  const posRef = useRef({ x: 0, y: 0, w: 0, h: 0 });

  const positionCard = useCallback(() => {
    const el = cardRef.current;
    if (!el) return;
    const { x, y, w, h } = posRef.current;
    const cw = el.offsetWidth || 256;
    const ch = el.offsetHeight || 180;
    const pad = 14;
    let nx = x + pad;
    let ny = y + pad;
    if (nx + cw > w) nx = x - cw - pad; // flip to the left of the cursor near the right edge
    if (nx < 4) nx = 4;
    if (ny + ch > h) ny = Math.max(4, h - ch); // keep the card inside the map vertically
    el.style.left = `${nx}px`;
    el.style.top = `${ny}px`;
  }, []);

  const onMouseMove = useCallback((e: React.MouseEvent) => {
    const r = mapRef.current?.getBoundingClientRect();
    if (!r) return;
    posRef.current = { x: e.clientX - r.left, y: e.clientY - r.top, w: r.width, h: r.height };
    positionCard();
  }, [positionCard]);

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

  // Reset framing + hover when the parent clears the selection (back to US),
  // or when the federal lens takes over (it always shows the whole US — there
  // is no county-level federal drill-down to zoom into).
  useEffect(() => {
    if (!selected || metric === 'federal') {
      setCenter([-96, 38]);
      setZoom(1);
      setHover(null);
      framedFipsRef.current = null;
    }
  }, [selected, metric]);

  // Re-place the card whenever its contents change (hover enter / level switch),
  // using the last known cursor position.
  useEffect(() => { positionCard(); }, [hover, positionCard]);

  // Completeness / federal hover cards.
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
  if (hover && metric === 'federal' && hover.level === 'state') {
    const sc = stateByFips.get(hover.fips);
    if (sc) hoverCard = <FederalHoverCard name={sc.name} f={sc.federal} />;
  }

  // Elections text readout.
  let elecReadout: ReactNode = null;
  if (hover && metric === 'elections') {
    if (hover.level === 'state') {
      const es = elecStatesByFips.get(hover.fips);
      elecReadout = (
        <>
          <span className="font-medium">{hover.name}</span>
          {es ? (
            <>
              <span className="ml-2 tabular-nums text-gray-500 dark:text-gray-400" title="research depth, 0–100">{es.depthScore}</span>
              <span className="ml-2 text-gray-400">
                ({es.tierCounts.t3} fully · {es.tierCounts.t2} partly · {es.tierCounts.t1} candidates-only)
              </span>
              <span className="ml-2 text-gray-400">
                · county:{' '}
                {es.countyCoverage.status === 'unknown' ? 'N/A — no county-level races' : <span className="tabular-nums">{es.countyCoverage.coverage}%</span>}
              </span>
            </>
          ) : (
            <span className="ml-2 text-gray-400">no upcoming election</span>
          )}
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
      <div
        ref={mapRef}
        onMouseMove={onMouseMove}
        onMouseLeave={() => setHover(null)}
        className="relative mx-auto overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900"
        style={{ maxWidth: `calc(${MAP_MAX_HEIGHT_VH}vh * ${MAP_W} / ${MAP_H})` }}
      >
        {/* Cursor-following hover card (completeness) */}
        {hoverCard && (
          <div ref={cardRef} className="pointer-events-none absolute z-30" style={{ left: 0, top: 0 }}>
            {hoverCard}
          </div>
        )}

        {/* Legend overlay (completeness + federal share the same honest ramp).
            Elections' tier decoder lives BELOW the map — as an overlay it covered it. */}
        {metric !== 'elections' && (
          <div className="absolute bottom-3 left-3 z-20 rounded-md border border-gray-200/70 bg-white/85 px-3 py-2 shadow-sm backdrop-blur-sm dark:border-gray-700/70 dark:bg-gray-900/85">
            <CompletenessLegend />
          </div>
        )}

        <ComposableMap projection="geoAlbersUsa" width={MAP_W} height={MAP_H} style={{ width: '100%', height: 'auto' }}>
          <ZoomableGroup center={center} zoom={zoom} minZoom={1} maxZoom={12}>
            {!selected || metric === 'federal' ? (
              <Geographies geography={STATES_TOPO}>
                {({ geographies, path, projection }) => {
                  pathRef.current = path;
                  projRef.current = projection;
                  return geographies.map((geo) => {
                    const sc = stateByFips.get(geo.id as string);
                    const es = elecStatesByFips.get(geo.id as string);
                    const fill =
                      metric === 'elections' ? electionStateColor(es)
                      : metric === 'federal' ? completenessColor(sc ? sc.federal.score : null)
                      : completenessColor(sc?.score ?? null);
                    const isSel = selected?.fips === geo.id;
                    return (
                      <Geography
                        key={geo.rsmKey}
                        geography={geo}
                        onMouseEnter={() => setHover({ level: 'state', fips: geo.id as string, name: geo.properties.name })}
                        onMouseLeave={() => setHover(null)}
                        onClick={() => { setHover(null); props.onSelectState(geo.id as string, geo.properties.name); }}
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
            ) : (
              <Geographies geography={COUNTIES_TOPO}>
                {({ geographies, path, projection }) => {
                  pathRef.current = path;
                  projRef.current = projection;
                  const stateGeos = geographies.filter((geo) => (geo.id as string).startsWith(selected.fips));
                  // Frame the state once (covers both map-click and US-table selection).
                  if (framedFipsRef.current !== selected.fips && stateGeos.length > 0) {
                    framedFipsRef.current = selected.fips;
                    const fc = { type: 'FeatureCollection', features: stateGeos };
                    queueMicrotask(() => fitToFeature(fc));
                  }
                  return stateGeos.map((geo) => {
                    const cs = countyByFips.get(geo.id as string);
                    const ec = elecCountiesByFips.get(geo.id as string);
                    const fill = metric === 'elections' ? electionCountyColor(ec) : completenessColor(cs?.score ?? null);
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

      {/* Elections readout + legends (completeness uses the in-map hover card + overlay legend) */}
      {metric === 'elections' && (
        <>
          <div className="mt-2 flex items-center justify-between text-sm">
            <div className="text-gray-600 dark:text-gray-300">
              {elecReadout ?? <span className="text-gray-400">{selected ? 'Hover a county' : 'Hover a state'}</span>}
            </div>
            <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
              {props.elecDate && <span className="font-medium capitalize text-gray-600 dark:text-gray-300">{props.elecDate.type} · {props.elecDate.date}</span>}
              <span className="inline-flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NO_RACE_DATA }} /> no race data</span>
              <span className="inline-flex items-center gap-1.5"><span>low</span><div className="h-2 w-24 rounded-full" style={{ background: `linear-gradient(to right, ${scoreColor(5)}, ${scoreColor(45)}, ${scoreColor(100)})` }} /><span>high</span></span>
            </div>
          </div>
          <div className="mt-2">
            <ElectionsTierLegend />
          </div>
        </>
      )}
    </div>
  );
}
