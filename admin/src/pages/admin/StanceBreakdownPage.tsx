import { useEffect, useMemo, useState, type CSSProperties } from 'react';
import { apiFetch } from '../../lib/api';

interface StanceCount { id: string; value: number; text: string; count: number; }
interface BetweenCount { value: number; count: number; }
interface TopicBreakdown {
  topicId: string;
  title: string;
  shortTitle: string | null;
  isLive: boolean;
  totalResponses: number;
  writeInCount: number;
  stances: StanceCount[];
  betweens: BetweenCount[];
}
interface StanceBreakdownReport {
  totals: { responses: number; users: number };
  topics: TopicBreakdown[];
}

// Diverging 5-step ramp (purple ↔ orange, neutral mid — deliberately NOT
// blue/red, which would read as party colors on stance poles). Both mode
// ramps validated: every pole↔midpoint pair clears CVD ΔE ≥ 8 and the
// normal-vision floor; sub-3:1 light steps get relief via tooltips and the
// expanded rows. Literal class strings so Tailwind's scanner picks them up.
const STANCE_BG = [
  'bg-[#6d28d9] dark:bg-[#c4b5fd]', // stance 1
  'bg-[#a78bfa] dark:bg-[#8b5cf6]', // stance 2
  'bg-[#d1d5db] dark:bg-[#6b7280]', // stance 3 (neutral mid)
  'bg-[#fb923c] dark:bg-[#f97316]', // stance 4
  'bg-[#ea580c] dark:bg-[#fdba74]', // stance 5
];
const stanceBg = (value: number) => STANCE_BG[value - 1] ?? STANCE_BG[2];

// Write-in placements between stances: neutral base + diagonal hatch so they
// never impersonate a stance color.
const BETWEEN_BG = 'bg-gray-400 dark:bg-gray-500';
const HATCH: CSSProperties = {
  backgroundImage:
    'repeating-linear-gradient(45deg, transparent 0 3px, rgba(0,0,0,0.35) 3px 5px)',
};

function pct(count: number, total: number): number {
  return total > 0 ? Math.round((count / total) * 100) : 0;
}

interface Segment {
  key: string;
  label: string;
  text: string | null;
  count: number;
  colorClass: string;
  hatch: boolean;
  sortValue: number;
}

function topicSegments(topic: TopicBreakdown): Segment[] {
  const segs: Segment[] = [
    ...topic.stances.map((s) => ({
      key: `s${s.value}`,
      label: `Stance ${s.value}`,
      text: s.text,
      count: s.count,
      colorClass: stanceBg(s.value),
      hatch: false,
      sortValue: s.value,
    })),
    ...topic.betweens.map((b) => ({
      key: `b${b.value}`,
      label: `${b.value} · write-in placement`,
      text: null,
      count: b.count,
      colorClass: BETWEEN_BG,
      hatch: true,
      sortValue: b.value,
    })),
  ]
    .sort((a, b) => a.sortValue - b.sortValue)
    .filter((s) => s.count > 0);
  return segs;
}

function SegmentTooltip({ seg, total }: { seg: Segment; total: number }) {
  return (
    <div className="pointer-events-none absolute bottom-full left-1/2 z-20 mb-1.5 hidden w-64 -translate-x-1/2 rounded-md border border-gray-200 bg-white p-2 text-left shadow-lg group-hover:block dark:border-gray-600 dark:bg-gray-800">
      <p className="text-xs font-semibold text-gray-900 dark:text-gray-100">
        {seg.label} — {seg.count} · {pct(seg.count, total)}%
      </p>
      {seg.text && (
        <p className="mt-0.5 text-xs leading-snug text-gray-600 dark:text-gray-300">{seg.text}</p>
      )}
    </div>
  );
}

function DistributionBar({ topic }: { topic: TopicBreakdown }) {
  const segs = topicSegments(topic);
  const total = topic.totalResponses;
  if (total === 0 || segs.length === 0) {
    return <div className="h-3 flex-1 rounded-full bg-gray-100 dark:bg-gray-800" />;
  }
  return (
    <div className="flex h-3 flex-1 items-stretch gap-[2px]">
      {segs.map((seg, i) => (
        <div
          key={seg.key}
          className={`group relative min-w-[6px] ${seg.colorClass} ${
            i === 0 ? 'rounded-l-full' : ''
          } ${i === segs.length - 1 ? 'rounded-r-full' : ''}`}
          style={{ width: `${(seg.count / total) * 100}%`, ...(seg.hatch ? HATCH : {}) }}
        >
          <SegmentTooltip seg={seg} total={total} />
        </div>
      ))}
    </div>
  );
}

function StanceDot({ colorClass, hatch }: { colorClass: string; hatch?: boolean }) {
  return (
    <span
      className={`inline-block h-2.5 w-2.5 shrink-0 rounded-full ${colorClass}`}
      style={hatch ? HATCH : undefined}
    />
  );
}

function ExpandedDetail({ topic }: { topic: TopicBreakdown }) {
  const segs = topicSegments(topic);
  const rows: Segment[] = [
    // Show every stance (including zero-count) plus any betweens, in order.
    ...topic.stances.map((s) => ({
      key: `s${s.value}`,
      label: `${s.value}`,
      text: s.text,
      count: s.count,
      colorClass: stanceBg(s.value),
      hatch: false,
      sortValue: s.value,
    })),
    ...segs.filter((s) => s.hatch).map((s) => ({ ...s, label: s.label.split(' ')[0] })),
  ].sort((a, b) => a.sortValue - b.sortValue);

  const max = Math.max(...rows.map((r) => r.count), 1);
  return (
    <div className="border-t border-gray-100 px-4 py-3 dark:border-gray-800">
      <div className="space-y-2">
        {rows.map((r) => (
          <div key={r.key} className="flex items-start gap-3 text-sm">
            <span className="flex w-10 shrink-0 items-center gap-1.5 pt-0.5">
              <StanceDot colorClass={r.colorClass} hatch={r.hatch} />
              <span className="text-xs font-medium tabular-nums text-gray-500 dark:text-gray-400">
                {r.label}
              </span>
            </span>
            <span className="flex-1 leading-snug text-gray-800 dark:text-gray-200">
              {r.text ?? (
                <span className="italic text-gray-500 dark:text-gray-400">
                  write-in placed between stances
                </span>
              )}
            </span>
            <span className="flex w-40 shrink-0 items-center gap-2 pt-0.5">
              <span className="h-1.5 flex-1 rounded-full bg-gray-100 dark:bg-gray-800">
                <span
                  className={`block h-1.5 rounded-full ${r.colorClass}`}
                  style={{ width: `${(r.count / max) * 100}%`, ...(r.hatch ? HATCH : {}) }}
                />
              </span>
              <span className="w-14 text-right text-xs tabular-nums text-gray-600 dark:text-gray-300">
                {r.count} · {pct(r.count, topic.totalResponses)}%
              </span>
            </span>
          </div>
        ))}
      </div>
      {topic.writeInCount > 0 && (
        <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
          {topic.writeInCount} response{topic.writeInCount === 1 ? ' includes' : 's include'} write-in
          text.
        </p>
      )}
    </div>
  );
}

function TopicRow({
  topic,
  expanded,
  onToggle,
}: {
  topic: TopicBreakdown;
  expanded: boolean;
  onToggle: () => void;
}) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={expanded}
        className="flex w-full items-center gap-3 rounded-lg px-4 py-2.5 text-left hover:bg-gray-50 dark:hover:bg-gray-800/60"
      >
        <span
          className={`shrink-0 text-gray-400 transition-transform dark:text-gray-500 ${expanded ? 'rotate-90' : ''}`}
        >
          ▸
        </span>
        <span className="flex w-72 shrink-0 items-center gap-2">
          <span className="truncate font-medium text-gray-900 dark:text-gray-100" title={topic.title}>
            {topic.title}
          </span>
          {!topic.isLive && (
            <span className="shrink-0 rounded bg-gray-200 px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide text-gray-600 dark:bg-gray-700 dark:text-gray-300">
              not live
            </span>
          )}
        </span>
        <DistributionBar topic={topic} />
        <span className="w-14 shrink-0 text-right text-sm tabular-nums text-gray-600 dark:text-gray-300">
          {topic.totalResponses}
        </span>
      </button>
      {expanded && <ExpandedDetail topic={topic} />}
    </div>
  );
}

function Legend() {
  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-600 dark:text-gray-300">
      {[1, 2, 3, 4, 5].map((v) => (
        <span key={v} className="flex items-center gap-1.5">
          <StanceDot colorClass={stanceBg(v)} />
          Stance {v}
        </span>
      ))}
      <span className="flex items-center gap-1.5">
        <StanceDot colorClass={BETWEEN_BG} hatch />
        write-in between stances
      </span>
    </div>
  );
}

type SortKey = 'responses' | 'title';

export function StanceBreakdownPage() {
  const [report, setReport] = useState<StanceBreakdownReport | null>(null);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');
  const [onlyAnswered, setOnlyAnswered] = useState(true);
  const [sortKey, setSortKey] = useState<SortKey>('responses');
  const [expanded, setExpanded] = useState<Set<string>>(new Set());

  useEffect(() => {
    apiFetch<StanceBreakdownReport>('/admin/compass-stats')
      .then(setReport)
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load'));
  }, []);

  const visible = useMemo(() => {
    if (!report) return [];
    const q = query.trim().toLowerCase();
    const filtered = report.topics.filter(
      (t) =>
        (!onlyAnswered || t.totalResponses > 0) &&
        (q === '' ||
          t.title.toLowerCase().includes(q) ||
          (t.shortTitle ?? '').toLowerCase().includes(q))
    );
    return [...filtered].sort((a, b) =>
      sortKey === 'title'
        ? a.title.localeCompare(b.title)
        : b.totalResponses - a.totalResponses || a.title.localeCompare(b.title)
    );
  }, [report, query, onlyAnswered, sortKey]);

  const answeredCount = report?.topics.filter((t) => t.totalResponses > 0).length ?? 0;
  const allVisibleExpanded = visible.length > 0 && visible.every((t) => expanded.has(t.topicId));

  function toggle(topicId: string) {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(topicId)) next.delete(topicId);
      else next.add(topicId);
      return next;
    });
  }

  function toggleAll() {
    setExpanded(allVisibleExpanded ? new Set() : new Set(visible.map((t) => t.topicId)));
  }

  return (
    <div className="p-6">
      <h1 className="mb-1 text-2xl font-semibold text-gray-900 dark:text-gray-100">
        Compass — Stance Breakdown
      </h1>
      <p className="mb-4 text-sm text-gray-600 dark:text-gray-400">
        How many users selected each stance, per topic. Bar segments follow stance order 1→5;
        half-step write-in placements are shown hatched, never rounded into a stance. Hover a
        segment for the stance text, or expand a topic for the full breakdown.
      </p>

      {error && <p className="mb-4 text-ev-red">{error}</p>}
      {!report && !error && <p className="text-gray-600 dark:text-gray-300">Loading…</p>}

      {report && (
        <>
          <div className="mb-3 flex flex-wrap gap-3 text-sm">
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{report.totals.responses}</strong> responses
            </span>
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{report.totals.users}</strong> users
            </span>
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{answeredCount}</strong> of {report.topics.length} topics answered
            </span>
          </div>

          <div className="mb-4">
            <Legend />
          </div>

          <div className="mb-4 flex flex-wrap items-center gap-4">
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Filter topics…"
              className="w-72 rounded border border-gray-300 px-3 py-2 text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100"
            />
            <select
              value={sortKey}
              onChange={(e) => setSortKey(e.target.value as SortKey)}
              className="rounded border border-gray-300 px-2 py-2 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200"
            >
              <option value="responses">Most responses</option>
              <option value="title">A–Z</option>
            </select>
            <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
              <input
                type="checkbox"
                checked={onlyAnswered}
                onChange={(e) => setOnlyAnswered(e.target.checked)}
              />
              Only topics with responses
            </label>
            <button
              type="button"
              onClick={toggleAll}
              className="text-sm text-ev-blue hover:underline"
            >
              {allVisibleExpanded ? 'Collapse all' : 'Expand all'}
            </button>
          </div>

          {visible.length === 0 ? (
            <p className="text-gray-600 dark:text-gray-300">No topics match.</p>
          ) : (
            <div className="space-y-2">
              {visible.map((t) => (
                <TopicRow
                  key={t.topicId}
                  topic={t}
                  expanded={expanded.has(t.topicId)}
                  onToggle={() => toggle(t.topicId)}
                />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
