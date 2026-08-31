import type { ReactNode } from 'react';
import { shortLensName, type CompassLens } from '../hooks/useCompassLenses';

const FALLBACK_COLOR = '#9ca3af'; // gray-400, for a lens with no color set

/** A small solid dot in the lens's colour. */
export function LensDot({ lens, className = '' }: { lens: CompassLens; className?: string }) {
  return (
    <span
      className={`inline-block h-2.5 w-2.5 shrink-0 rounded-full ${className}`}
      style={{ background: lens.color ?? FALLBACK_COLOR }}
      title={lens.name}
    />
  );
}

/** A dot + short name pill, for inline "this topic is in these lenses" lists. */
export function LensChip({ lens }: { lens: CompassLens }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 bg-white px-2 py-0.5 text-xs font-medium text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300">
      <LensDot lens={lens} />
      {shortLensName(lens.name)}
    </span>
  );
}

/**
 * Each lens as its own group, its member topics clustered under it (in the
 * lens's sort_order). Read-only — assigning topics to a lens is still a
 * migration. `titleFor` resolves a topic id to a display title; `metaFor` is an
 * optional trailing marker per topic (e.g. which season asks it).
 */
export function LensClusters({
  lenses,
  titleFor,
  metaFor,
  loading,
  error,
}: {
  lenses: CompassLens[];
  titleFor: (topicId: string) => string;
  metaFor?: (topicId: string) => ReactNode;
  loading?: boolean;
  error?: string | null;
}) {
  if (loading) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <div className="mb-3 h-4 w-24 rounded bg-gray-200 dark:bg-gray-700" />
            <div className="space-y-2">
              {[1, 2, 3].map((j) => (
                <div key={j} className="h-3 rounded bg-gray-100 dark:bg-gray-800" />
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  }
  if (error) {
    return (
      <p role="alert" className="rounded border border-amber-600 bg-amber-50 px-3 py-2 text-sm text-amber-900 dark:border-amber-500 dark:bg-amber-950/50 dark:text-amber-100">
        Could not load lenses — {error}
      </p>
    );
  }
  if (lenses.length === 0) {
    return <p className="text-sm text-gray-500 dark:text-gray-400">No active lenses.</p>;
  }
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {lenses.map((lens) => (
        <section
          key={lens.key}
          className="overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900"
        >
          <header className="flex items-center gap-2 border-b border-gray-100 px-3 py-2 dark:border-gray-800">
            <LensDot lens={lens} />
            <span className="text-sm font-semibold text-gray-900 dark:text-white">
              {shortLensName(lens.name)}
            </span>
            <span className="ml-auto rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-semibold tabular-nums text-gray-500 dark:bg-gray-800 dark:text-gray-400">
              {lens.topicIds.length}
            </span>
          </header>
          {lens.topicIds.length === 0 ? (
            <p className="px-3 py-2 text-xs italic text-gray-400 dark:text-gray-500">No topics assigned.</p>
          ) : (
            <ol className="divide-y divide-gray-100 dark:divide-gray-800">
              {lens.topicIds.map((id, i) => (
                <li key={id} className="flex items-center gap-2 px-3 py-1.5 text-sm">
                  <span className="w-4 shrink-0 text-right text-[11px] tabular-nums text-gray-400">{i + 1}</span>
                  <span className="min-w-0 flex-1 truncate text-gray-800 dark:text-gray-200">{titleFor(id)}</span>
                  {metaFor?.(id)}
                </li>
              ))}
            </ol>
          )}
        </section>
      ))}
    </div>
  );
}
