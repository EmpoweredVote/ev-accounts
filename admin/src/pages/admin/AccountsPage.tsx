import { useEffect, useState, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router';
import { apiFetch } from '../../lib/api';

interface Account {
  id: string;
  display_name: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  account_standing: string;
  created_at: string;
}

interface AccountsResponse {
  accounts: Account[];
  total: number;
  page: number;
  pages: number;
}

const TIER_BADGE: Record<string, string> = {
  inform: 'bg-gray-100 text-gray-700',
  connected: 'bg-blue-100 text-blue-700',
  empowered: 'bg-green-100 text-green-700',
};

const STANDING_BADGE: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  suspended: 'bg-red-100 text-red-700',
};

function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}

export function AccountsPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [tier, setTier] = useState('');
  const [standing, setStanding] = useState('');
  const [page, setPage] = useState(1);
  const [data, setData] = useState<AccountsResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Dropdown state
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const [searchResults, setSearchResults] = useState<Account[]>([]);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const debouncedSearch = useDebounce(search, 300);

  const fetchAccounts = useCallback(() => {
    setLoading(true);
    setError(null);
    const params = new URLSearchParams();
    if (debouncedSearch) params.set('search', debouncedSearch);
    if (tier) params.set('tier', tier);
    if (standing) params.set('standing', standing);
    params.set('page', String(page));

    apiFetch<AccountsResponse>(`/admin/accounts?${params}`)
      .then(setData)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [debouncedSearch, tier, standing, page]);

  useEffect(() => {
    fetchAccounts();
  }, [fetchAccounts]);

  // Reset page when filters change
  useEffect(() => {
    setPage(1);
  }, [debouncedSearch, tier, standing]);

  // Fetch dropdown results when debouncedSearch changes
  useEffect(() => {
    if (debouncedSearch.length < 2) {
      setSearchResults([]);
      setShowSearchDropdown(false);
      return;
    }

    const params = new URLSearchParams();
    params.set('search', debouncedSearch);
    params.set('page', '1');

    apiFetch<AccountsResponse>(`/admin/accounts?${params}`)
      .then((res) => {
        setSearchResults(res.accounts.slice(0, 8));
        setShowSearchDropdown(true);
      })
      .catch(() => {
        setSearchResults([]);
      });
  }, [debouncedSearch]);

  function handleSearchFocus() {
    if (blurTimerRef.current) {
      clearTimeout(blurTimerRef.current);
    }
    if (debouncedSearch.length >= 2 && searchResults.length > 0) {
      setShowSearchDropdown(true);
    }
  }

  function handleSearchBlur() {
    blurTimerRef.current = setTimeout(() => {
      setShowSearchDropdown(false);
    }, 150);
  }

  function handleDropdownClick(accountId: string) {
    setShowSearchDropdown(false);
    navigate(`/admin/accounts/${accountId}`);
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">Accounts</h1>

      {/* Filters */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow p-4 mb-6 flex gap-4">
        <div className="flex-1 relative">
          <input
            type="text"
            placeholder="Search by name or email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onFocus={handleSearchFocus}
            onBlur={handleSearchBlur}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
          />
          {showSearchDropdown && (
            <div className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg z-10 max-h-64 overflow-y-auto">
              {searchResults.length === 0 ? (
                <div className="px-4 py-3 text-sm text-gray-400 dark:text-gray-500">
                  No users found for &ldquo;{debouncedSearch}&rdquo;
                </div>
              ) : (
                searchResults.map((account) => (
                  <div
                    key={account.id}
                    onMouseDown={() => handleDropdownClick(account.id)}
                    className="flex items-center justify-between px-4 py-2.5 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer border-b border-gray-100 dark:border-gray-800 last:border-0"
                  >
                    <div>
                      <span className="block text-sm font-medium text-gray-900 dark:text-white">
                        {account.display_name}
                      </span>
                      <span className="block text-xs text-gray-500 dark:text-gray-400">{account.email}</span>
                    </div>
                    <span
                      className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[account.tier] ?? 'bg-gray-100 text-gray-700'}`}
                    >
                      {account.tier}
                    </span>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
        <select
          value={tier}
          onChange={(e) => setTier(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
        >
          <option value="">All Tiers</option>
          <option value="inform">Inform</option>
          <option value="connected">Connected</option>
          <option value="empowered">Empowered</option>
        </select>
        <select
          value={standing}
          onChange={(e) => setStanding(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-600 dark:text-white"
        >
          <option value="">All Standings</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
          {error}
        </div>
      )}

      {/* Table */}
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Name</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Email</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Tier</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Standing</th>
              <th className="text-left px-4 py-3 font-medium text-gray-500 dark:text-gray-400">Created</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td colSpan={5} className="px-4 py-3">
                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
                  </td>
                </tr>
              ))
            ) : data?.accounts?.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-gray-400 dark:text-gray-500">
                  No accounts found.
                </td>
              </tr>
            ) : (
              data?.accounts.map((account) => (
                <tr
                  key={account.id}
                  onClick={() => navigate(`/admin/accounts/${account.id}`)}
                  className="hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors"
                >
                  <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">{account.display_name}</td>
                  <td className="px-4 py-3 text-gray-600 dark:text-gray-400">{account.email}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${TIER_BADGE[account.tier] ?? 'bg-gray-100 text-gray-700'}`}>
                      {account.tier}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${STANDING_BADGE[account.account_standing] ?? 'bg-gray-100 text-gray-700'}`}>
                      {account.account_standing}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 dark:text-gray-400">
                    {new Date(account.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {data && data.pages > 1 && (
        <div className="mt-4 flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
          <span>
            Page {data.page} of {data.pages} ({data.total} total)
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Previous
            </button>
            <button
              onClick={() => setPage((p) => Math.min(data.pages, p + 1))}
              disabled={page >= data.pages}
              className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
