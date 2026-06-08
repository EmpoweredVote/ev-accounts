import { useState } from 'react';
import { apiFetch } from '../../lib/api';

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
  const [politicianId, setPoliticianId] = useState('');
  const [topics, setTopics] = useState<AdminTopicQuotes[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  async function load(id: string) {
    setLoading(true); setError(null);
    try {
      const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
        `/admin/readrank-quotes?politician_id=${encodeURIComponent(id)}`,
      );
      setTopics(data.topics);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
      setTopics(null);
    } finally { setLoading(false); }
  }

  async function select(quoteId: string) {
    setSavingId(quoteId); setError(null);
    try {
      await apiFetch('/admin/readrank-quotes/select', {
        method: 'PUT',
        body: JSON.stringify({ quote_id: quoteId }),
      });
      await load(politicianId);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to select');
    } finally { setSavingId(null); }
  }

  return (
    <div className="p-6 max-w-4xl">
      <h1 className="text-xl font-semibold mb-4">Read &amp; Rank Quotes</h1>
      <form
        className="flex gap-2 mb-6"
        onSubmit={(e) => { e.preventDefault(); if (politicianId.trim()) load(politicianId.trim()); }}
      >
        <input
          className="border rounded px-3 py-2 flex-1"
          placeholder="Politician ID (uuid)"
          value={politicianId}
          onChange={(e) => setPoliticianId(e.target.value)}
        />
        <button className="px-4 py-2 bg-ev-muted-blue text-white rounded" type="submit">Load</button>
      </form>

      {loading && <p>Loading…</p>}
      {error && <p className="text-ev-coral mb-4">{error}</p>}

      {topics && topics.length === 0 && <p>No quotes for this politician.</p>}

      {topics?.map((t) => (
        <section key={t.topicKey} className="mb-6">
          <h2 className="font-medium mb-2">{t.topicKey}</h2>
          <ul className="space-y-2">
            {t.quotes.map((q) => (
              <li key={q.id} className="border rounded p-3 flex gap-3 items-start">
                <input
                  type="radio"
                  name={`sel-${t.topicKey}`}
                  className="mt-1"
                  checked={q.readrankSelected}
                  disabled={!q.deidentifiedText || savingId === q.id}
                  onChange={() => select(q.id)}
                  title={q.deidentifiedText ? 'Use this quote for Read & Rank' : 'No de-identified text — cannot be selected'}
                />
                <div className="flex-1">
                  <p className="text-sm">{q.deidentifiedText ?? <span className="italic text-gray-500">(no de-identified text)</span>}</p>
                  <p className="text-xs text-gray-500 mt-1">verbatim: {q.quoteText}</p>
                  {q.sourceUrl && (
                    <a className="text-xs text-ev-light-blue" href={q.sourceUrl} target="_blank" rel="noreferrer">
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
  );
}
