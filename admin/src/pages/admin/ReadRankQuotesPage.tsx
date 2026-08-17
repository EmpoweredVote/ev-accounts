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
  editorNote: string | null;
  readrankSelected: boolean;
}
/** One selectable group = one QUESTION (migration 1377), not one topic. A topic can
 *  host several questions, so `topicKey` is not unique across groups — key React
 *  lists, radio groups and the clear button on `key` instead. */
interface AdminTopicQuotes {
  key: string;
  topicKey: string;
  questionId: string | null;
  questionText: string | null;
  quotes: AdminQuote[];
}

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
  const [savingTopic, setSavingTopic] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState({ quoteText: '', deidentifiedText: '', sourceUrl: '', sourceName: '', editorNote: '' });

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

  // Re-fetch the expanded politician's topics and refresh the list-row counts.
  async function refetchTopics(politicianId: string) {
    const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
      `/admin/readrank-quotes?politician_id=${encodeURIComponent(politicianId)}`,
    );
    setTopics(data.topics);
    const all = data.topics.flatMap((t) => t.quotes);
    setPoliticians((prev) => prev.map((p) =>
      p.id === politicianId
        ? { ...p, quoteCount: all.length, selectedCount: all.filter((q) => q.readrankSelected).length }
        : p,
    ));
  }

  async function select(quoteId: string) {
    if (!expandedId) return;
    setSavingId(quoteId); setTopicsError(null);
    try {
      await apiFetch('/admin/readrank-quotes/select', {
        method: 'PUT',
        body: JSON.stringify({ quote_id: quoteId }),
      });
      await refetchTopics(expandedId);
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to select');
    } finally { setSavingId(null); }
  }

  // Turn one QUESTION off: deselect this candidate's quotes answering it. Passing
  // question_id matters — omitting it clears every question in the topic, which is
  // how an editor could silently unselect a sibling question's live answer.
  async function clearSelection(group: AdminTopicQuotes) {
    if (!expandedId) return;
    setSavingTopic(group.key); setTopicsError(null);
    try {
      await apiFetch('/admin/readrank-quotes/deselect', {
        method: 'PUT',
        body: JSON.stringify({
          politician_id: expandedId,
          topic_key: group.topicKey,
          question_id: group.questionId,
        }),
      });
      await refetchTopics(expandedId);
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to clear selection');
    } finally { setSavingTopic(null); }
  }

  function startEdit(q: AdminQuote) {
    setEditingId(q.id);
    setTopicsError(null);
    setEditForm({
      quoteText: q.quoteText,
      deidentifiedText: q.deidentifiedText ?? '',
      sourceUrl: q.sourceUrl ?? '',
      sourceName: q.sourceName ?? '',
      editorNote: q.editorNote ?? '',
    });
  }

  async function saveEdit(quoteId: string) {
    if (!expandedId) return;
    setSavingId(quoteId); setTopicsError(null);
    const nullIfBlank = (s: string) => (s.trim() === '' ? null : s);
    try {
      await apiFetch('/admin/readrank-quotes', {
        method: 'PATCH',
        body: JSON.stringify({
          quote_id: quoteId,
          quote_text: editForm.quoteText,
          deidentified_text: nullIfBlank(editForm.deidentifiedText),
          source_url: nullIfBlank(editForm.sourceUrl),
          source_name: nullIfBlank(editForm.sourceName),
          editor_note: nullIfBlank(editForm.editorNote),
        }),
      });
      setEditingId(null);
      await refetchTopics(expandedId);
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to save quote');
    } finally { setSavingId(null); }
  }

  async function remove(quoteId: string) {
    if (!expandedId) return;
    if (!confirm('Delete this quote permanently?')) return;
    setSavingId(quoteId); setTopicsError(null);
    try {
      await apiFetch(`/admin/readrank-quotes/${encodeURIComponent(quoteId)}`, { method: 'DELETE' });
      if (editingId === quoteId) setEditingId(null);
      await refetchTopics(expandedId);
    } catch (e) {
      setTopicsError(e instanceof Error ? e.message : 'Failed to delete quote');
    } finally { setSavingId(null); }
  }

  const fieldClass = 'w-full text-sm border border-gray-300 dark:border-gray-600 rounded px-2 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-ev-blue';

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
                  <section key={t.key} className="mt-3 mb-4">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div className="min-w-0">
                        <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">{t.topicKey}</h3>
                        {/* A topic can host several questions; the question text is what
                            distinguishes two groups that share this heading. */}
                        {t.questionText && (
                          <p className="text-xs text-gray-600 dark:text-gray-300 mt-0.5">{t.questionText}</p>
                        )}
                      </div>
                      {t.quotes.some((q) => q.readrankSelected) && (
                        <button
                          className="text-xs shrink-0 text-gray-500 dark:text-gray-400 hover:text-ev-red hover:underline disabled:opacity-50"
                          disabled={savingTopic === t.key}
                          onClick={() => clearSelection(t)}
                          title={t.questionId
                            ? 'Turn this question off for Read & Rank — deselect its quotes'
                            : 'Turn this topic off for Read & Rank — deselect all quotes'}
                        >
                          {savingTopic === t.key ? 'Clearing…' : 'Clear selection'}
                        </button>
                      )}
                    </div>
                    <ul className="space-y-2">
                      {t.quotes.map((q) => (
                        <li key={q.id} className="border border-gray-200 dark:border-gray-700 rounded-lg p-3 flex gap-3 items-start bg-white dark:bg-gray-900">
                          <input
                            type="radio"
                            // Per QUESTION: one radio group per topic let the editor
                            // select only one answer across all of the topic's questions.
                            name={`sel-${p.id}-${t.key}`}
                            className="mt-1 shrink-0"
                            checked={q.readrankSelected}
                            disabled={!q.deidentifiedText || savingId === q.id}
                            onChange={() => select(q.id)}
                            title={q.deidentifiedText ? 'Use this quote for Read & Rank' : 'No de-identified text — cannot be selected'}
                          />
                          <div className="flex-1 min-w-0">
                            {editingId === q.id ? (
                              <div className="space-y-2">
                                <div>
                                  <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-0.5">Verbatim quote</label>
                                  <textarea
                                    className={fieldClass}
                                    rows={2}
                                    value={editForm.quoteText}
                                    onChange={(e) => setEditForm((f) => ({ ...f, quoteText: e.target.value }))}
                                  />
                                </div>
                                <div>
                                  <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-0.5">De-identified text</label>
                                  <textarea
                                    className={fieldClass}
                                    rows={2}
                                    value={editForm.deidentifiedText}
                                    onChange={(e) => setEditForm((f) => ({ ...f, deidentifiedText: e.target.value }))}
                                  />
                                </div>
                                <div>
                                  <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 mb-0.5">Editor note (why selected / what edited)</label>
                                  <textarea
                                    className={fieldClass}
                                    rows={2}
                                    value={editForm.editorNote}
                                    onChange={(e) => setEditForm((f) => ({ ...f, editorNote: e.target.value }))}
                                  />
                                </div>
                                <div className="flex gap-2">
                                  <input
                                    className={fieldClass}
                                    placeholder="Source URL"
                                    value={editForm.sourceUrl}
                                    onChange={(e) => setEditForm((f) => ({ ...f, sourceUrl: e.target.value }))}
                                  />
                                  <input
                                    className={fieldClass}
                                    placeholder="Source name"
                                    value={editForm.sourceName}
                                    onChange={(e) => setEditForm((f) => ({ ...f, sourceName: e.target.value }))}
                                  />
                                </div>
                                <div className="flex gap-2 pt-1">
                                  <button
                                    className="text-xs px-3 py-1 rounded bg-ev-blue text-white hover:bg-ev-blue/90 disabled:opacity-50"
                                    disabled={savingId === q.id || editForm.quoteText.trim() === ''}
                                    onClick={() => saveEdit(q.id)}
                                  >
                                    {savingId === q.id ? 'Saving…' : 'Save'}
                                  </button>
                                  <button
                                    className="text-xs px-3 py-1 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:border-ev-blue disabled:opacity-50"
                                    disabled={savingId === q.id}
                                    onClick={() => setEditingId(null)}
                                  >
                                    Cancel
                                  </button>
                                </div>
                              </div>
                            ) : (
                              <>
                                <p className="text-sm text-gray-900 dark:text-white">
                                  {q.deidentifiedText ?? (
                                    <span className="italic text-gray-400 dark:text-gray-500">(no de-identified text)</span>
                                  )}
                                </p>
                                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">verbatim: {q.quoteText}</p>
                                {q.editorNote && (
                                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                    <span className="font-medium">editor note:</span> {q.editorNote}
                                  </p>
                                )}
                                <div className="flex items-center gap-3 mt-1">
                                  {q.sourceUrl && (
                                    <a className="text-xs text-ev-blue hover:underline" href={q.sourceUrl} target="_blank" rel="noreferrer">
                                      {q.sourceName ?? q.sourceUrl}
                                    </a>
                                  )}
                                  <button
                                    className="text-xs text-ev-blue hover:underline disabled:opacity-50 ml-auto"
                                    disabled={savingId === q.id}
                                    onClick={() => startEdit(q)}
                                  >
                                    Edit
                                  </button>
                                  <button
                                    className="text-xs text-ev-red hover:underline disabled:opacity-50"
                                    disabled={savingId === q.id}
                                    onClick={() => remove(q.id)}
                                  >
                                    Delete
                                  </button>
                                </div>
                              </>
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
