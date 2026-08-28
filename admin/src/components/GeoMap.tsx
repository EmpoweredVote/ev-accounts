/**
 * GeoMap — the small set of map primitives the coverage choropleth needs,
 * built straight on d3-geo, d3-zoom and topojson-client.
 *
 * This replaces react-simple-maps, which wrapped those same three libraries
 * behind a React peer-dependency range and stopped being published in 2023.
 * The libraries underneath declare no React peer, so no future React release
 * can block an upgrade the way react-simple-maps@3 blocked React 19.
 *
 * The zoom/pan maths is a like-for-like port of the old ZoomableGroup, so the
 * map's feel — drag, wheel, programmatic re-centring — is unchanged.
 */
import { useEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode, type RefObject } from 'react';
import { geoAlbersUsa, geoPath, type GeoPath, type GeoProjection } from 'd3-geo';
import { select } from 'd3-selection';
import { zoom as d3Zoom, zoomIdentity, type D3ZoomEvent, type ZoomBehavior } from 'd3-zoom';
import { feature as topoFeature } from 'topojson-client';
import type { Feature, FeatureCollection, Geometry } from 'geojson';
import type { GeometryCollection, Topology } from 'topojson-specification';

/** A feature from a us-atlas topology: FIPS code on `id`, place name in `properties`. */
export type MapFeature = Feature<Geometry, { name: string }>;

/* ------------------------------------------------------------------ geometry */

// Parsed topologies are kept for the life of the page. Parsing the counties
// topology is the expensive part, so re-entering a state should not pay twice.
const featureCache = new Map<string, MapFeature[]>();
const inFlight = new Map<string, Promise<MapFeature[]>>();

function loadFeatures(url: string): Promise<MapFeature[]> {
  const pending = inFlight.get(url);
  if (pending) return pending;

  const request = fetch(url)
    .then((res) => {
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
      return res.json() as Promise<Topology>;
    })
    .then((topology) => {
      // us-atlas files carry exactly one object collection ("states" / "counties").
      const collection = topology.objects[Object.keys(topology.objects)[0]] as GeometryCollection<{ name: string }>;
      const { features } = topoFeature(topology, collection) as FeatureCollection<Geometry, { name: string }>;
      featureCache.set(url, features);
      return features;
    })
    .finally(() => {
      inFlight.delete(url);
    });

  inFlight.set(url, request);
  return request;
}

/**
 * Fetch and parse a TopoJSON file, or nothing when `url` is null — pass null to
 * keep a large file (counties) off the wire until the view actually needs it.
 * Returns null while the file is loading or if it failed.
 */
export function useTopoFeatures(url: string | null): MapFeature[] | null {
  const [, rerender] = useState(0);

  useEffect(() => {
    if (!url || featureCache.has(url)) return;
    let live = true;
    loadFeatures(url).then(
      () => { if (live) rerender((n) => n + 1); },
      (err) => { console.error(`Could not load map geometry from ${url}:`, err); },
    );
    return () => { live = false; };
  }, [url]);

  // The cache is the state, so a change of `url` reads correctly on the very
  // first render rather than showing the previous file's shapes for a frame.
  return url ? featureCache.get(url) ?? null : null;
}

/* ---------------------------------------------------------------- projection */

/**
 * The composite US projection — Alaska and Hawaii as insets — fitted to a
 * width x height frame. Both returned values keep a stable identity, so path
 * strings derived from them can be memoised.
 */
export function useAlbersUsa(width: number, height: number): { projection: GeoProjection; path: GeoPath } {
  return useMemo(() => {
    const projection = geoAlbersUsa().translate([width / 2, height / 2]);
    return { projection, path: geoPath(projection) };
  }, [width, height]);
}

/* ------------------------------------------------------------------ zoom/pan */

interface Transform { x: number; y: number; k: number }

/** Screen centre of a zoom transform, in unprojected frame pixels. */
function frameCentre(width: number, height: number, t: Transform): [number, number] {
  const xOffset = (width * t.k - width) / 2;
  const yOffset = (height * t.k - height) / 2;
  return [width / 2 - (xOffset + t.x) / t.k, height / 2 - (yOffset + t.y) / t.k];
}

interface ZoomPanOptions {
  width: number;
  height: number;
  projection: GeoProjection;
  /** Geographic centre to move to, [longitude, latitude]. */
  center: [number, number];
  zoom: number;
  minZoom: number;
  maxZoom: number;
}

export interface ZoomPan {
  surfaceRef: RefObject<SVGGElement | null>;
  transform: string;
}

/**
 * Drag-and-wheel zoom/pan over an SVG group, plus programmatic re-centring
 * when `center`/`zoom` change. Gestures are not reported back out: the caller
 * drives the map, and the user's own panning is left alone until it does.
 */
export function useZoomPan({ width, height, projection, center, zoom, minZoom, maxZoom }: ZoomPanOptions): ZoomPan {
  const [lon, lat] = center;
  const [transform, setTransform] = useState<Transform>({ x: 0, y: 0, k: 1 });
  const surfaceRef = useRef<SVGGElement | null>(null);
  const behaviourRef = useRef<ZoomBehavior<SVGGElement, unknown> | null>(null);
  // Where the map last came to rest, in geographic coordinates, so a repeated
  // center/zoom prop does not yank the user back out of their own panning.
  const settled = useRef({ lon: 0, lat: 0, k: 1 });
  // Set while we drive d3-zoom ourselves, so its events do not fight the props.
  const programmatic = useRef(false);

  useEffect(() => {
    const surface = surfaceRef.current;
    if (!surface) return;
    const selection = select(surface);

    const behaviour = d3Zoom<SVGGElement, unknown>()
      // Leave ctrl+wheel to the browser's page zoom, and ignore non-primary buttons.
      .filter((event: MouseEvent) => !event.ctrlKey && !event.button)
      .scaleExtent([minZoom, maxZoom])
      .on('zoom', (event: D3ZoomEvent<SVGGElement, unknown>) => {
        if (programmatic.current) return;
        const { x, y, k } = event.transform;
        setTransform({ x, y, k });
      })
      .on('end', (event: D3ZoomEvent<SVGGElement, unknown>) => {
        if (programmatic.current) {
          programmatic.current = false;
          return;
        }
        const centred = projection.invert?.(frameCentre(width, height, event.transform));
        if (centred) settled.current = { lon: centred[0], lat: centred[1], k: event.transform.k };
      });

    behaviourRef.current = behaviour;
    selection.call(behaviour);
    // react-simple-maps never detached its listeners; do, so remounts stay clean.
    return () => { selection.on('.zoom', null); };
  }, [width, height, minZoom, maxZoom, projection]);

  useEffect(() => {
    const surface = surfaceRef.current;
    const behaviour = behaviourRef.current;
    if (!surface || !behaviour) return;

    const at = settled.current;
    if (lon === at.lon && lat === at.lat && zoom === at.k) return;

    // geoAlbersUsa returns null for anywhere outside its three insets.
    const projected = projection([lon, lat]);
    if (!projected) return;

    const next = { x: width / 2 - projected[0] * zoom, y: height / 2 - projected[1] * zoom, k: zoom };
    programmatic.current = true;
    select(surface).call(behaviour.transform, zoomIdentity.translate(next.x, next.y).scale(zoom));
    setTransform(next);
    settled.current = { lon, lat, k: zoom };
  }, [lon, lat, zoom, width, height, projection]);

  return { surfaceRef, transform: `translate(${transform.x} ${transform.y}) scale(${transform.k})` };
}

/** The group `useZoomPan` drives. Everything drawn on the map goes inside it. */
export function ZoomPanGroup({
  width,
  height,
  surfaceRef,
  transform,
  children,
}: ZoomPan & { width: number; height: number; children: ReactNode }) {
  return (
    <g ref={surfaceRef}>
      {/* Transparent hit target, so a drag anywhere in the frame pans the map. */}
      <rect width={width} height={height} fill="transparent" />
      <g transform={transform}>{children}</g>
    </g>
  );
}

/* --------------------------------------------------------------------- shape */

export interface ShapeStyle {
  default?: CSSProperties;
  hover?: CSSProperties;
  pressed?: CSSProperties;
}

interface GeoShapeProps {
  /** SVG path data, from `path(feature)`. */
  d: string;
  style: ShapeStyle;
  onMouseEnter?: () => void;
  onMouseLeave?: () => void;
  onClick?: () => void;
}

/** One projected feature, with the three-state styling the old map used. */
export function GeoShape({ d, style, onMouseEnter, onMouseLeave, onClick }: GeoShapeProps) {
  const [pressed, setPressed] = useState(false);
  // Hover and keyboard focus share a state, so tabbing highlights a shape too.
  const [active, setActive] = useState(false);

  return (
    <path
      tabIndex={0}
      d={d}
      style={pressed ? style.pressed : active ? style.hover : style.default}
      onMouseEnter={() => { setActive(true); onMouseEnter?.(); }}
      onMouseLeave={() => { setActive(false); setPressed(false); onMouseLeave?.(); }}
      onFocus={() => setActive(true)}
      onBlur={() => { setActive(false); setPressed(false); }}
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onClick={onClick}
    />
  );
}
