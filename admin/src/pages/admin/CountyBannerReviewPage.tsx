/**
 * The county banner review surface: choose one option per county, set both crop levers, and
 * mark the county keep or needs-another-look.
 *
 * 🔴 SAVING IS REPORTED, NEVER ASSUMED. On 2026-11-19 a crop editor's write path failed on its
 * first call and every later save returned early in silence; the page looked correct the whole
 * time and 73 counties of cropping were nearly lost. Four things here answer that, and they are
 * requirements of the spec rather than polish:
 *   1. A page-level line, from load, saying whether saving is switched on at all.
 *   2. A per-county stamp: saved with a time THE DATABASE RETURNED, or NOT SAVED with a reason.
 *   3. A failed READ stops the operator instead of showing an empty, workable-looking page.
 *   4. Loading is separate from ready-to-write, so one bad row cannot disable writing for the
 *      rest.
 *
 * Every decision this page makes lives in countyBannerReviewState.ts, which is unit-tested;
 * this file renders what those return. The geometry comes from countyBannerCrop.ts.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import { useCallback, useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../../lib/api';
import {
  ASSET_W, ASSET_H, DESKTOP_RATIO, MOBILE_RATIO, assetRect, bandRect, formatFocus, parseFocus,
} from './countyBannerCrop';
import {
  emptyKind, keepBlocker, savingLineText, saveStampText, frameStatus, creditLine,
  type CountyReviewRow, type CandidateRow, type SaveState,
} from './countyBannerReviewState';

interface StateSummary {
  stateUsps: string; counties: number; pending: number; keep: number; needsAnotherLook: number;
}

/** The preview: the whole 1700x540 asset, with the 6:1 desktop band drawn over it. */
function CropPreview({ c, anchor, focus }: { c: CandidateRow; anchor: number; focus: string }) {
  const src = assetRect(c.width, c.height, anchor);
  const band = bandRect(DESKTOP_RATIO, focus);
  const mobile = bandRect(MOBILE_RATIO, focus);
  // Scale the source so the chosen asset rect exactly fills a 1700x540 box, then show it at a
  // convenient width. object-position moves the source; the box is the asset.
  const scale = ASSET_W / src.w;
  return (
    <div className="space-y-1">
      <div
        className="relative overflow-hidden border border-gray-300 dark:border-gray-700"
        style={{ aspectRatio: `${ASSET_W} / ${ASSET_H}` }}
      >
        <img
          src={c.frameUrl}
          alt=""
          className="absolute max-w-none"
          style={{
            width: `${c.width * scale * (100 / ASSET_W)}%`,
            left: `${(-src.x * scale * 100) / ASSET_W}%`,
            top: `${(-src.y * scale * 100) / ASSET_H}%`,
          }}
        />
        {/* The desktop band, as a share of the asset. What is OUTSIDE it is dimmed. */}
        <div
          className="absolute inset-x-0 ring-2 ring-ev-red pointer-events-none"
          style={{ top: `${(band.y / ASSET_H) * 100}%`, height: `${(band.h / ASSET_H) * 100}%` }}
        />
        <div
          className="absolute inset-x-0 top-0 bg-black/40 pointer-events-none"
          style={{ height: `${(band.y / ASSET_H) * 100}%` }}
        />
        <div
          className="absolute inset-x-0 bottom-0 bg-black/40 pointer-events-none"
          style={{ height: `${((ASSET_H - band.y - band.h) / ASSET_H) * 100}%` }}
        />
      </div>
      <p className="text-xs text-gray-500">
        Full asset 1700×540 · desktop band {Math.round((band.h / ASSET_H) * 1000) / 10}% ·
        mobile shows {Math.round((mobile.h / ASSET_H) * 1000) / 10}%
      </p>
    </div>
  );
}

function CountyCard({ row, onSaved }: { row: CountyReviewRow; onSaved: (r: CountyReviewRow) => void }) {
  const [selected, setSelected] = useState<string | null>(row.chosenTitle);
  const [anchor, setAnchor] = useState<number>(row.verticalAnchor ?? 0.5);
  const [focusY, setFocusY] = useState<number>(parseFocus(row.focus ?? '')?.y ?? 0.5);
  const [sighted, setSighted] = useState<boolean>(row.captionSighted);
  const [save, setSave] = useState<SaveState>(
    row.decidedAt ? { kind: 'saved', decidedAt: row.decidedAt } : { kind: 'none' },
  );
  const [failedFrames, setFailedFrames] = useState<Set<string>>(new Set());

  const focus = formatFocus(0.5, focusY);
  // The blocker is computed against the crop the operator can see right now, not against the
  // row as it was loaded.
  const live = { ...row, focus, verticalAnchor: anchor };
  const blocker = keepBlocker(live, selected, sighted);
  const empty = emptyKind(row);
  const chosen = row.candidates.find((c) => c.commonsTitle === selected) ?? null;

  async function decide(status: 'keep' | 'needs_another_look') {
    setSave({ kind: 'saving' });
    try {
      const saved = await apiFetch<CountyReviewRow>(`/admin/county-banners/${row.geoid}/decision`, {
        method: 'POST',
        body: JSON.stringify({
          status,
          chosenTitle: status === 'keep' ? selected : null,
          verticalAnchor: status === 'keep' ? anchor : null,
          focus: status === 'keep' ? focus : null,
          captionSighted: sighted,
        }),
      });
      // 🔴 The stamp comes from the row the SERVER returned, never from this component's hope.
      setSave({ kind: 'saved', decidedAt: saved.decidedAt ?? new Date().toISOString() });
      onSaved(saved);
    } catch (err) {
      setSave({ kind: 'failed', reason: err instanceof Error ? err.message : String(err) });
    }
  }

  return (
    <section className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 space-y-3">
      <header className="flex items-baseline justify-between gap-4">
        <h2 className="font-semibold">
          {row.countyName} <span className="text-xs text-gray-500">{row.geoid}</span>
        </h2>
        <span className={`text-xs ${save.kind === 'failed' ? 'text-ev-red font-semibold' : 'text-gray-500'}`}>
          {saveStampText(save)}
        </span>
      </header>

      <p className="text-xs text-gray-500">
        {row.geometryCandidates} placed by coordinates · {row.captionCandidates} placed by caption
        {' '}· {row.filesSwept} files swept
      </p>

      {empty && <p className="text-sm text-amber-700 dark:text-amber-400">{empty.text}</p>}

      {row.candidates.length > 0 && (
        <>
          <div className="flex gap-2 flex-wrap">
            {row.candidates.map((c) => {
              const state = frameStatus(c, failedFrames);
              return (
                <button
                  key={c.commonsTitle}
                  onClick={() => setSelected(c.commonsTitle)}
                  className={`w-32 h-20 overflow-hidden border-2 ${
                    selected === c.commonsTitle ? 'border-ev-red' : 'border-transparent'
                  }`}
                  title={c.commonsTitle}
                >
                  {state === 'ok' ? (
                    <img
                      src={c.frameUrl}
                      alt={c.commonsTitle}
                      className="w-full h-full object-cover"
                      // 🔴 A frame that fails to load must SAY so. An empty box is how an
                      // operator ends up approving alt text.
                      onError={() => setFailedFrames((s) => new Set(s).add(c.frameUrl))}
                    />
                  ) : (
                    <span className="block w-full h-full grid place-items-center bg-red-50 text-ev-red text-[10px] p-1">
                      {state === 'missing' ? 'no frame was stored' : 'frame failed to load'}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {chosen && (
            <div className="space-y-2">
              <CropPreview c={chosen} anchor={anchor} focus={focus} />
              <label className="block text-xs">
                Vertical anchor (what mobile sees): {anchor.toFixed(2)}
                <input type="range" min={0} max={1} step={0.01} value={anchor}
                       onChange={(e) => setAnchor(Number(e.target.value))} className="w-full" />
              </label>
              <label className="block text-xs">
                Focus (what desktop sees): {focus}
                <input type="range" min={0} max={1} step={0.01} value={focusY}
                       onChange={(e) => setFocusY(Number(e.target.value))} className="w-full" />
              </label>
              <p className="text-xs text-gray-500">
                {creditLine(chosen.author)} · {chosen.licence} ·{' '}
                <a href={chosen.sourcePageUrl} target="_blank" rel="noreferrer" className="underline">
                  file page
                </a>
              </p>
              {chosen.locatedBy === 'caption' && (
                <div className="text-xs border border-amber-300 bg-amber-50 dark:bg-amber-900/20 p-2 space-y-1">
                  <p>Placed by its caption, not by coordinates: “{chosen.captionText}”</p>
                  <p>
                    <a href={chosen.captionSourceUrl ?? '#'} target="_blank" rel="noreferrer" className="underline">caption source</a>
                    {' · '}
                    <a href={chosen.confirmingSourceUrl ?? '#'} target="_blank" rel="noreferrer" className="underline">confirming source</a>
                  </p>
                  {chosen.placeListAvailable === false && (
                    <p>We hold no place polygons for {row.stateUsps}, so this caption could not be checked against our own place list.</p>
                  )}
                  <label className="flex items-center gap-2">
                    <input type="checkbox" checked={sighted} onChange={(e) => setSighted(e.target.checked)} />
                    I have looked at this and it is the place
                  </label>
                </div>
              )}
            </div>
          )}
        </>
      )}

      <div className="flex items-center gap-3">
        <button
          onClick={() => decide('keep')}
          disabled={blocker !== null || save.kind === 'saving'}
          className="px-3 py-1 text-sm rounded bg-ev-red text-white disabled:opacity-40"
        >
          Keep
        </button>
        <button
          onClick={() => { setSelected(null); decide('needs_another_look'); }}
          disabled={save.kind === 'saving'}
          className="px-3 py-1 text-sm rounded border"
        >
          Needs another look (ships blank)
        </button>
        {blocker && <span className="text-xs text-gray-500">{blocker}</span>}
      </div>
    </section>
  );
}

export function CountyBannerReviewPage() {
  const [states, setStates] = useState<StateSummary[] | null>(null);
  const [state, setState] = useState<string | null>(null);
  const [rows, setRows] = useState<CountyReviewRow[] | null>(null);
  const [health, setHealth] = useState<{ writable: boolean } | null>(null);
  const [readError, setReadError] = useState<string | null>(null);

  useEffect(() => {
    // The health probe is deliberately independent of the data read: one failing must not
    // disable the other. Separating loading from ready-to-write is a spec requirement.
    apiFetch<{ writable: boolean }>('/admin/county-banners/health')
      .then(setHealth)
      .catch(() => setHealth({ writable: false }));
    apiFetch<StateSummary[]>('/admin/county-banners/states')
      .then(setStates)
      .catch((e) => setReadError(e instanceof Error ? e.message : String(e)));
  }, []);

  const load = useCallback((usps: string) => {
    setState(usps);
    setRows(null);
    setReadError(null);
    apiFetch<CountyReviewRow[]>(`/admin/county-banners/${usps}`)
      .then(setRows)
      .catch((e) => setReadError(e instanceof Error ? e.message : String(e)));
  }, []);

  const onSaved = useCallback((saved: CountyReviewRow) => {
    setRows((prev) => prev?.map((r) => (r.geoid === saved.geoid ? { ...r, ...saved } : r)) ?? prev);
  }, []);

  const line = useMemo(() => savingLineText(health), [health]);

  return (
    <div className="p-6 space-y-4">
      <h1 className="text-xl font-semibold">County banners</h1>
      <p className={`text-sm ${health && !health.writable ? 'text-ev-red font-semibold' : 'text-gray-500'}`}>
        {line}
      </p>

      {/* 🔴 A failed READ stops the operator. An empty page that still looks workable is how an
          afternoon of decisions goes nowhere. */}
      {readError && (
        <div className="border border-ev-red bg-red-50 dark:bg-red-900/20 p-3 text-sm">
          <strong>Could not read the review table.</strong> Nothing below is trustworthy — stop
          and fix this first. {readError}
        </div>
      )}

      {!readError && states && (
        <div className="flex gap-2 flex-wrap">
          {states.map((s) => (
            <button
              key={s.stateUsps}
              onClick={() => load(s.stateUsps)}
              className={`px-3 py-1 text-sm rounded border ${state === s.stateUsps ? 'border-ev-red' : ''}`}
            >
              {s.stateUsps}
              <span className="text-xs text-gray-500">
                {' '}{s.keep}/{s.counties} kept · {s.pending} to do
              </span>
            </button>
          ))}
        </div>
      )}

      {!readError && rows && rows.map((r) => (
        <CountyCard key={r.geoid} row={r} onSaved={onSaved} />
      ))}
      {!readError && state && rows === null && <p className="text-sm text-gray-500">Loading {state}…</p>}
    </div>
  );
}

export default CountyBannerReviewPage;
