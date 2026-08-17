import { useEffect, useMemo, useState, type CSSProperties } from 'react';
import { apiFetch } from '../../lib/api';

interface StanceCount { id: string; value: number; text: string; users: number; politicians: number; }
interface BetweenCount { value: number; users: number; politicians: number; }
interface TopicBreakdown {
  topicId: string;
  title: string;
  shortTitle: string | null;
  isLive: boolean;
  userResponses: number;
  politicianAnswers: number;
  userWriteIns: number;
  politicianWriteIns: number;
  stances: StanceCount[];
  betweens: BetweenCount[];
}
interface StanceBreakdownReport {
  totals: { userResponses: number; users: number; politicianAnswers: number; politicians: number };
  topics: TopicBreakdown[];
}

type Cohort = 'politicians' | 'users';

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

function cohortTotal(topic: TopicBreakdown, cohort: Cohort): number {
  return cohort === 'users' ? topic.userResponses : topic.politicianAnswers;
}

interface Segment {
  key: string;
  label: string;
  text: string | null;
  users: number;
  politicians: number;
  colorClass: string;
  hatch: boolean;
  sortValue: number;
}

function allSegments(topic: TopicBreakdown): Segment[] {
  return [
    ...topic.stances.map((s) => ({
      key: `s${s.value}`,
      label: `Stance ${s.value}`,
      text: s.text,
      users: s.users,
      politicians: s.politicians,
      colorClass: stanceBg(s.value),
      hatch: false,
      sortValue: s.value,
    })),
    ...topic.betweens.map((b) => ({
      key: `b${b.value}`,
      label: `${b.value} · write-in placement`,
      text: null,
      users: b.users,
      politicians: b.politicians,
      colorClass: BETWEEN_BG,
      hatch: true,
      sortValue: b.value,
    })),
  ].sort((a, b) => a.sortValue - b.sortValue);
}

function SegmentTooltip({ seg, topic, cohort }: { seg: Segment; topic: TopicBreakdown; cohort: Cohort }) {
  const other: Cohort = cohort === 'users' ? 'politicians' : 'users';
  return (
    <div className="pointer-events-none absolute bottom-full left-1/2 z-20 mb-1.5 hidden w-64 -translate-x-1/2 rounded-md border border-gray-200 bg-white p-2 text-left shadow-lg group-hover:block dark:border-gray-600 dark:bg-gray-800">
      <p className="text-xs font-semibold text-gray-900 dark:text-gray-100">
        {seg.label} — {seg[cohort]} · {pct(seg[cohort], cohortTotal(topic, cohort))}% of {cohort}
      </p>
      <p className="text-xs text-gray-500 dark:text-gray-400">
        {seg[other]} · {pct(seg[other], cohortTotal(topic, other))}% of {other}
      </p>
      {seg.text && (
        <p className="mt-0.5 text-xs leading-snug text-gray-600 dark:text-gray-300">{seg.text}</p>
      )}
    </div>
  );
}

function DistributionBar({ topic, cohort }: { topic: TopicBreakdown; cohort: Cohort }) {
  const total = cohortTotal(topic, cohort);
  const segs = allSegments(topic).filter((s) => s[cohort] > 0);
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
          style={{ width: `${(seg[cohort] / total) * 100}%`, ...(seg.hatch ? HATCH : {}) }}
        >
          <SegmentTooltip seg={seg} topic={topic} cohort={cohort} />
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

function ExpandedDetail({ topic, cohort }: { topic: TopicBreakdown; cohort: Cohort }) {
  const rows = allSegments(topic).filter((s) => !s.hatch || s.users > 0 || s.politicians > 0);
  const max = Math.max(...rows.map((r) => r[cohort]), 1);
  return (
    <div className="border-t border-gray-100 px-4 py-3 dark:border-gray-800">
      <div className="mb-1 flex items-center gap-3 text-[10px] font-medium uppercase tracking-wide text-gray-400 dark:text-gray-500">
        <span className="w-10 shrink-0" />
        <span className="flex-1" />
        <span className="w-24 shrink-0 text-right">{cohort === 'users' ? 'users' : 'politicians'}</span>
        <span className="w-24 shrink-0 text-right">{cohort === 'users' ? 'politicians' : 'users'}</span>
      </div>
      <div className="space-y-2">
        {rows.map((r) => {
          const other: Cohort = cohort === 'users' ? 'politicians' : 'users';
          return (
            <div key={r.key} className="flex items-start gap-3 text-sm">
              <span className="flex w-10 shrink-0 items-center gap-1.5 pt-0.5">
                <StanceDot colorClass={r.colorClass} hatch={r.hatch} />
                <span className="text-xs font-medium tabular-nums text-gray-500 dark:text-gray-400">
                  {r.sortValue}
                </span>
              </span>
              <span className="flex-1 leading-snug text-gray-800 dark:text-gray-200">
                {r.text ?? (
                  <span className="italic text-gray-500 dark:text-gray-400">
                    write-in placed between stances
                  </span>
                )}
                <span className="mt-1 block h-1.5 max-w-56 rounded-full bg-gray-100 dark:bg-gray-800">
                  <span
                    className={`block h-1.5 rounded-full ${r.colorClass}`}
                    style={{ width: `${(r[cohort] / max) * 100}%`, ...(r.hatch ? HATCH : {}) }}
                  />
                </span>
              </span>
              <span className="w-24 shrink-0 pt-0.5 text-right text-xs tabular-nums text-gray-800 dark:text-gray-200">
                {r[cohort]} · {pct(r[cohort], cohortTotal(topic, cohort))}%
              </span>
              <span className="w-24 shrink-0 pt-0.5 text-right text-xs tabular-nums text-gray-500 dark:text-gray-400">
                {r[other]} · {pct(r[other], cohortTotal(topic, other))}%
              </span>
            </div>
          );
        })}
      </div>
      {(topic.userWriteIns > 0 || topic.politicianWriteIns > 0) && (
        <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
          Write-in text on {topic.userWriteIns} user response{topic.userWriteIns === 1 ? '' : 's'}
          {topic.politicianWriteIns > 0 &&
            ` and ${topic.politicianWriteIns} politician answer${topic.politicianWriteIns === 1 ? '' : 's'}`}
          .
        </p>
      )}
    </div>
  );
}

function TopicRow({
  topic,
  cohort,
  expanded,
  onToggle,
}: {
  topic: TopicBreakdown;
  cohort: Cohort;
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
        <DistributionBar topic={topic} cohort={cohort} />
        <span className="w-16 shrink-0 text-right text-sm tabular-nums text-gray-600 dark:text-gray-300">
          {cohortTotal(topic, cohort)}
        </span>
      </button>
      {expanded && <ExpandedDetail topic={topic} cohort={cohort} />}
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
  const [cohort, setCohort] = useState<Cohort>('politicians');
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
        (!onlyAnswered || cohortTotal(t, cohort) > 0) &&
        (q === '' ||
          t.title.toLowerCase().includes(q) ||
          (t.shortTitle ?? '').toLowerCase().includes(q))
    );
    return [...filtered].sort((a, b) =>
      sortKey === 'title'
        ? a.title.localeCompare(b.title)
        : cohortTotal(b, cohort) - cohortTotal(a, cohort) || a.title.localeCompare(b.title)
    );
  }, [report, query, onlyAnswered, sortKey, cohort]);

  const answeredCount =
    report?.topics.filter((t) => cohortTotal(t, cohort) > 0).length ?? 0;
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

  const cohortBtn = (value: Cohort, label: string) => (
    <button
      type="button"
      onClick={() => setCohort(value)}
      aria-pressed={cohort === value}
      className={`px-3 py-1.5 text-sm font-medium ${
        cohort === value
          ? 'bg-ev-blue text-white'
          : 'bg-white text-gray-600 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
      }`}
    >
      {label}
    </button>
  );

  return (
    <div className="p-6">
      <h1 className="mb-1 text-2xl font-semibold text-gray-900 dark:text-gray-100">
        Compass — Stance Breakdown
      </h1>
      <p className="mb-4 text-sm text-gray-600 dark:text-gray-400">
        How many politicians and users are placed on each stance, per topic. Bar segments follow
        stance order 1→5; half-step write-in placements are shown hatched, never rounded into a
        stance. Hover a segment for the stance text, or expand a topic for the full breakdown with
        both cohorts.
      </p>

      {error && <p className="mb-4 text-ev-red">{error}</p>}
      {!report && !error && <p className="text-gray-600 dark:text-gray-300">Loading…</p>}

      {report && (
        <>
          <div className="mb-3 flex flex-wrap gap-3 text-sm">
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{report.totals.politicianAnswers.toLocaleString()}</strong> politician answers
              · <strong>{report.totals.politicians.toLocaleString()}</strong> politicians
            </span>
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{report.totals.userResponses.toLocaleString()}</strong> user responses ·{' '}
              <strong>{report.totals.users.toLocaleString()}</strong> users
            </span>
            <span className="rounded bg-gray-100 px-3 py-1.5 text-gray-900 dark:bg-gray-800 dark:text-gray-100">
              <strong>{answeredCount}</strong> of {report.topics.length} topics have{' '}
              {cohort === 'users' ? 'user' : 'politician'} answers
            </span>
          </div>

          <div className="mb-4">
            <Legend />
          </div>

          <div className="mb-4 flex flex-wrap items-center gap-4">
            <span className="inline-flex overflow-hidden rounded-md border border-gray-300 dark:border-gray-600">
              {cohortBtn('politicians', 'Politicians')}
              {cohortBtn('users', 'Users')}
            </span>
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
              <option value="responses">Most answers</option>
              <option value="title">A–Z</option>
            </select>
            <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
              <input
                type="checkbox"
                checked={onlyAnswered}
                onChange={(e) => setOnlyAnswered(e.target.checked)}
              />
              Only topics with answers
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
                  cohort={cohort}
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
