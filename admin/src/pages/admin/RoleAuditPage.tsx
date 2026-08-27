import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../../lib/api';

// ── Types ─────────────────────────────────────────────────────────────────────

interface AuditEntry {
  id: string;
  actor_id: string;
  actor_display_name: string | null;
  target_user_id: string;
  target_display_name: string | null;
  action: 'granted' | 'revoked';
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
  created_at: string;
  snapshot_after: { role_slug?: string } | null;
}

interface AuditLogResponse {
  entries: AuditEntry[];
  total: number;
  page: number;
  page_size: number;
}

interface Filters {
  feature_scope: string;
  jurisdiction_geoid: string;
  from_date: string;
  to_date: string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const FEATURE_SCOPE_OPTIONS: { value: string; label: string }[] = [
  { value: '', label: 'All scopes' },
  { value: 'platform', label: 'Platform-wide' },
  { value: 'jurisdiction', label: 'Jurisdiction' },
  { value: 'resource', label: 'Resource (politician)' },
];

function scopeDisplay(entry: AuditEntry): React.ReactNode {
  if (entry.jurisdiction_geoid) {
    return (
      <span>
        Jurisdiction:{' '}
        <span className="font-mono text-xs">{entry.jurisdiction_geoid}</span>
      </span>
    );
  }
  if (entry.resource_id) {
    return (
      <span>
        Resource:{' '}
        <span className="font-mono text-xs">{entry.resource_id.slice(0, 8)}…</span>
      </span>
    );
  }
  return <span className="text-gray-400 dark:text-gray-500">Platform-wide</span>;
}

function formatTimestamp(iso: string): string {
  const d = new Date(iso);
  return `${d.toLocaleDateString()} ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
}

// ── RoleAuditPage ─────────────────────────────────────────────────────────────

export function RoleAuditPage() {
  const [filters, setFilters] = useState<Filters>({
    feature_scope: '',
    jurisdiction_geoid: '',
    from_date: '',
    to_date: '',
  });
  const [currentPage, setCurrentPage] = useState(1);
  const [results, setResults] = useState<AuditLogResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function buildQuery(f: Filters, page: number): string {
    const params = new URLSearchParams();
    if (f.feature_scope) params.set('feature_scope', f.feature_scope);
    if (f.jurisdiction_geoid.trim()) params.set('jurisdiction_geoid', f.jurisdiction_geoid.trim());
    if (f.from_date) params.set('from_date', f.from_date);
    if (f.to_date) params.set('to_date', f.to_date);
    params.set('page', String(page));
    params.set('page_size', '25');
    return params.toString();
  }

  async function fetchAuditLog(f: Filters = filters, page: number = currentPage) {
    setLoading(true);
    setError(null);
    try {
      const qs = buildQuery(f, page);
      const data = await apiFetch<AuditLogResponse>(`/admin/role-audit-log?${qs}`);
      setResults(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load audit log');
    } finally {
      setLoading(false);
    }
  }

  // Load on mount
  useEffect(() => {
    fetchAuditLog(filters, 1);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setCurrentPage(1);
    fetchAuditLog(filters, 1);
  }

  function handlePageChange(newPage: number) {
    setCurrentPage(newPage);
    fetchAuditLog(filters, newPage);
  }

  const pageSize = 25;
  const total = results?.total ?? 0;
  const start = total === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const end = Math.min(currentPage * pageSize, total);
  const hasPrev = currentPage > 1;
  const hasNext = currentPage * pageSize < total;

  return (
    <div className="max-w-5xl">
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Role Audit Log</h1>

      {/* Filter bar */}
      <form
        onSubmit={handleSearch}
        className="bg-white dark:bg-gray-900 rounded-lg shadow p-4 mb-6 flex flex-wrap gap-3 items-end"
      >
        {/* Scope filter */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-gray-500 dark:text-gray-400">Scope</label>
          <select
            value={filters.feature_scope}
            onChange={(e) => setFilters((f) => ({ ...f, feature_scope: e.target.value }))}
            className="border border-gray-300 dark:border-gray-600 rounded px-2 py-1.5 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {FEATURE_SCOPE_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        {/* Jurisdiction filter */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-gray-500 dark:text-gray-400">Jurisdiction</label>
          <input
            type="text"
            value={filters.jurisdiction_geoid}
            onChange={(e) => setFilters((f) => ({ ...f, jurisdiction_geoid: e.target.value }))}
            placeholder="Any jurisdiction"
            className="border border-gray-300 dark:border-gray-600 rounded px-2 py-1.5 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 w-40"
          />
        </div>

        {/* From date */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-gray-500 dark:text-gray-400">From</label>
          <input
            type="date"
            value={filters.from_date}
            onChange={(e) => setFilters((f) => ({ ...f, from_date: e.target.value }))}
            className="border border-gray-300 dark:border-gray-600 rounded px-2 py-1.5 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* To date */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-gray-500 dark:text-gray-400">To</label>
          <input
            type="date"
            value={filters.to_date}
            onChange={(e) => setFilters((f) => ({ ...f, to_date: e.target.value }))}
            className="border border-gray-300 dark:border-gray-600 rounded px-2 py-1.5 text-sm bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="px-4 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded disabled:opacity-50"
        >
          {loading ? 'Searching...' : 'Search'}
        </button>
      </form>

      {/* Error */}
      {error && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error}
        </div>
      )}

      {/* Results table */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-gray-100 dark:border-gray-800">
            <tr>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Timestamp</th>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Actor</th>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Target User</th>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Action</th>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Role</th>
              <th className="px-4 py-3 text-left font-medium text-gray-500 dark:text-gray-400">Scope</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
            {loading ? (
              // Skeleton rows
              Array.from({ length: 3 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td className="px-4 py-3"><div className="h-4 bg-gray-100 dark:bg-gray-800 rounded w-32" /></td>
                  <td className="px-4 py-3"><div className="h-4 bg-gray-100 dark:bg-gray-800 rounded w-24" /></td>
                  <td className="px-4 py-3"><div className="h-4 bg-gray-100 dark:bg-gray-800 rounded w-24" /></td>
                  <td className="px-4 py-3"><div className="h-5 bg-gray-100 dark:bg-gray-800 rounded w-16" /></td>
                  <td className="px-4 py-3"><div className="h-4 bg-gray-100 dark:bg-gray-800 rounded w-28" /></td>
                  <td className="px-4 py-3"><div className="h-4 bg-gray-100 dark:bg-gray-800 rounded w-24" /></td>
                </tr>
              ))
            ) : results?.entries.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500 text-sm">
                  No entries match your filters.
                </td>
              </tr>
            ) : (
              results?.entries.map((entry) => (
                <tr key={entry.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
                  <td className="px-4 py-3 text-gray-700 dark:text-gray-300 whitespace-nowrap">
                    {formatTimestamp(entry.created_at)}
                  </td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/admin/accounts/${entry.actor_id}`}
                      className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                    >
                      {entry.actor_display_name ?? entry.actor_id.slice(0, 8)}
                    </Link>
                  </td>
                  <td className="px-4 py-3">
                    <Link
                      to={`/admin/accounts/${entry.target_user_id}`}
                      className="text-blue-600 hover:text-blue-800 dark:text-ev-teal-light dark:hover:text-ev-teal-light/80"
                    >
                      {entry.target_display_name ?? entry.target_user_id.slice(0, 8)}
                    </Link>
                  </td>
                  <td className="px-4 py-3">
                    {entry.action === 'granted' ? (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400">
                        granted
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400">
                        revoked
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-700 dark:text-gray-300">
                    <span className="font-mono text-xs">
                      {entry.snapshot_after?.role_slug ?? entry.feature_scope}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-700 dark:text-gray-300 text-xs">
                    {scopeDisplay(entry)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        {/* Pagination */}
        {results && total > 0 && (
          <div className="px-4 py-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between">
            <span className="text-xs text-gray-500 dark:text-gray-400">
              Showing {start}–{end} of {total}
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={!hasPrev || loading}
                className="px-3 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded text-gray-700 dark:text-gray-300 disabled:opacity-40 hover:bg-gray-50 dark:hover:bg-gray-800"
              >
                Previous
              </button>
              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={!hasNext || loading}
                className="px-3 py-1 text-xs border border-gray-300 dark:border-gray-600 rounded text-gray-700 dark:text-gray-300 disabled:opacity-40 hover:bg-gray-50 dark:hover:bg-gray-800"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
