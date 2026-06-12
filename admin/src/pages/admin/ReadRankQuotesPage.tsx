import { useEffect, useState } from 'react';
import { apiFetch } from '../../lib/api';

interface PoliticianWithQuotes {
  id: string;
  name: string;
  officeTitle: string | null;
  state: string | null;
  quoteCount: number;
  selectedCount: number;
}
interface AdminQuote {
  id: string;
  quoteText: string;
  deidentifiedText: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  readrankSelected: boolean;
}
interface AdminTopicQuotes { topicKey: string; quotes: AdminQuote[]; }

export function ReadRankQuotesPage() {
  const [politicians, setPoliticians] = useState<PoliticianWithQuotes[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [listError, setListError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [stateFilter, setStateFilter] = useState('');

  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [topics, setTopics] = useState<AdminTopicQuotes[] | null>(null);
  const [loadingTopics, setLoadingTopics] = useState(false);
  const [topicsError, setTopicsError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  useEffect(() => {
    apiFetch<{ politicians: PoliticianWithQuotes[] }>('/admin/readrank-quotes/politicians')
      .then((d) => setPoliticians(d.politicians))
      .catch((e) => setListError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoadingList(false));
  }, []);

  const states = [...new Set(politicians.map((p) => p.state).filter(Boolean) as string[])].sort();

  const filtered = politicians.filter((p) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || p.name.toLowerCase().includes(q) || (p.officeTitle ?? '').toLowerCase().includes(q);
    const matchesState = !stateFilter || p.state === stateFilter;
    return matchesSearch && matchesState;
  });

  async function expand(p: PoliticianWithQuotes) {
    if (expandedId === p.id) { setExpandedId(null); setTopics(null); return; }
    setExpandedId(p.id); setTopics(null); setTopicsError(null); setLoadingTopics(true);
    try {
      const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
        `/admin/readrank-quotes?politician_id=${encodeURIComponent(p.id)}`,
      );
      setTopics(data.topics);
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to load quotes');
    } finally { setLoadingTopics(false); }
  }

  async function select(quoteId: string) {
    if (!expandedId) return;
    setSavingId(quoteId); setTopicsError(null);
    try {
      await apiFetch('/admin/readrank-quotes/select', {
        method: 'PUT',
        body: JSON.stringify({ quote_id: quoteId }),
      });
      const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
        `/admin/readrank-quotes?politician_id=${encodeURIComponent(expandedId)}`,
      );
      setTopics(data.topics);
      // refresh counts in list
      setPoliticians((prev) => prev.map((p) => {
        if (p.id !== expandedId) return p;
        const selected = data.topics.flatMap((t) => t.quotes).filter((q) => q.readrankSelected).length;
        return { ...p, selectedCount: selected };
      }));
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to select');
    } finally { setSavingId(null); }
  }

  return (
    <div className="p-6 max-w-4xl">
      <h1 className="text-xl font-semibold mb-5 text-gray-900 dark:text-white">Read &amp; Rank Quotes</h1>

      {/* Filters */}
      <div className="flex gap-3 mb-5">
        <input
          className="border border-gray-300 dark:border-gray-600 rounded px-3 py-2 flex-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-blue"
          placeholder="Search by name or office…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="border border-gray-300 dark:border-gray-600 rounded px-3 py-2 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-ev-blue"
          value={stateFilter}
          onChange={(e) => setStateFilter(e.target.value)}
        >
          <option value="">All states</option>
          {states.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>

      {loadingList && <p className="text-gray-500 dark:text-gray-400">Loading…</p>}
      {listError && <p className="text-ev-red mb-4">{listError}</p>}

      {!loadingList && filtered.length === 0 && !listError && (
        <p className="text-gray-500 dark:text-gray-400">No politicians found.</p>
      )}

      <ul className="space-y-2">
        {filtered.map((p) => (
          <li key={p.id}>
            <button
              className="w-full text-left px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 hover:border-ev-blue dark:hover:border-ev-blue transition-colors"
              onClick={() => expand(p)}
            >
              <div className="flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <p className="font-medium text-gray-900 dark:text-white truncate">{p.name}</p>
                  {p.officeTitle && (
                    <p className="text-sm text-gray-500 dark:text-gray-400 truncate">{p.officeTitle}</p>
                  )}
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {p.state && (
                    <span className="text-xs font-medium px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                      {p.state}
                    </span>
                  )}
                  <span className="text-xs px-2 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                    {p.quoteCount} quote{p.quoteCount !== 1 ? 's' : ''}
                  </span>
                  {p.selectedCount > 0 && (
                    <span className="text-xs px-2 py-0.5 rounded bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
                      {p.selectedCount} selected
                    </span>
                  )}
                  <svg
                    className={`w-4 h-4 text-gray-400 transition-transform ${expandedId === p.id ? 'rotate-180' : ''}`}
                    fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
            </button>

            {expandedId === p.id && (
              <div className="mt-1 ml-4 pl-4 border-l-2 border-gray-200 dark:border-gray-700">
                {loadingTopics && <p className="py-3 text-sm text-gray-500 dark:text-gray-400">Loading quotes…</p>}
                {topicsError && <p className="py-2 text-sm text-ev-red">{topicsError}</p>}
                {topics && topics.length === 0 && (
                  <p className="py-3 text-sm text-gray-500 dark:text-gray-400">No quotes for this politician.</p>
                )}
                {topics?.map((t) => (
                  <section key={t.topicKey} className="mt-3 mb-4">
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400 mb-2">{t.topicKey}</h3>
                    <ul className="space-y-2">
                      {t.quotes.map((q) => (
                        <li key={q.id} className="border border-gray-200 dark:border-gray-700 rounded-lg p-3 flex gap-3 items-start bg-white dark:bg-gray-900">
                          <input
                            type="radio"
                            name={`sel-${p.id}-${t.topicKey}`}
                            className="mt-1 shrink-0"
                            checked={q.readrankSelected}
                            disabled={!q.deidentifiedText || savingId === q.id}
                            onChange={() => select(q.id)}
                            title={q.deidentifiedText ? 'Use this quote for Read & Rank' : 'No de-identified text — cannot be selected'}
                          />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm text-gray-900 dark:text-white">
                              {q.deidentifiedText ?? (
                                <span className="italic text-gray-400 dark:text-gray-500">(no de-identified text)</span>
                              )}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">verbatim: {q.quoteText}</p>
                            {q.sourceUrl && (
                              <a className="text-xs text-ev-blue hover:underline" href={q.sourceUrl} target="_blank" rel="noreferrer">
                                {q.sourceName ?? q.sourceUrl}
                              </a>
                            )}
                          </div>
                        </li>
                      ))}
                    </ul>
                  </section>
                ))}
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
