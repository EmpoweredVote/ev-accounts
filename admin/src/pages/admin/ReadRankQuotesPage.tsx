import { useEffect, useRef, useState } from 'react';
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
interface Politician {
  id: string;
  first_name: string;
  last_name: string;
  preferred_name: string | null;
  full_name: string | null;
  office_title: string | null;
  is_active: boolean;
}

function politicianLabel(p: Politician): string {
  const name = p.full_name ?? `${p.preferred_name ?? p.first_name} ${p.last_name}`;
  return p.office_title ? `${name} — ${p.office_title}` : name;
}

export function ReadRankQuotesPage() {
  const [politicians, setPoliticians] = useState<Politician[]>([]);
  const [query, setQuery] = useState('');
  const [showDropdown, setShowDropdown] = useState(false);
  const [selectedPolitician, setSelectedPolitician] = useState<Politician | null>(null);
  const [topics, setTopics] = useState<AdminTopicQuotes[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    apiFetch<{ politicians: Politician[] }>('/admin/compass/politicians')
      .then((d) => setPoliticians(d.politicians))
      .catch(() => {/* non-fatal */});
  }, []);

  const filtered = query.trim().length >= 2
    ? politicians.filter((p) =>
        politicianLabel(p).toLowerCase().includes(query.toLowerCase()),
      ).slice(0, 12)
    : [];

  async function loadQuotes(p: Politician) {
    setLoading(true); setError(null); setTopics(null);
    try {
      const data = await apiFetch<{ topics: AdminTopicQuotes[] }>(
        `/admin/readrank-quotes?politician_id=${encodeURIComponent(p.id)}`,
      );
      setTopics(data.topics);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally { setLoading(false); }
  }

  function pickPolitician(p: Politician) {
    setSelectedPolitician(p);
    setQuery(politicianLabel(p));
    setShowDropdown(false);
    loadQuotes(p);
  }

  async function select(quoteId: string) {
    if (!selectedPolitician) return;
    setSavingId(quoteId); setError(null);
    try {
      await apiFetch('/admin/readrank-quotes/select', {
        method: 'PUT',
        body: JSON.stringify({ quote_id: quoteId }),
      });
      await loadQuotes(selectedPolitician);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to select');
    } finally { setSavingId(null); }
  }

  return (
    <div className="p-6 max-w-4xl">
      <h1 className="text-xl font-semibold mb-4">Read &amp; Rank Quotes</h1>

      <div className="relative mb-6">
        <input
          ref={inputRef}
          className="border rounded px-3 py-2 w-full"
          placeholder="Search politician by name…"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setShowDropdown(true);
            if (selectedPolitician && politicianLabel(selectedPolitician) !== e.target.value) {
              setSelectedPolitician(null);
              setTopics(null);
            }
          }}
          onFocus={() => setShowDropdown(true)}
          onBlur={() => setTimeout(() => setShowDropdown(false), 150)}
          autoComplete="off"
        />
        {showDropdown && filtered.length > 0 && (
          <ul className="absolute z-10 w-full bg-white border rounded shadow mt-1 max-h-64 overflow-y-auto">
            {filtered.map((p) => (
              <li
                key={p.id}
                className="px-3 py-2 hover:bg-gray-100 cursor-pointer text-sm"
                onMouseDown={() => pickPolitician(p)}
              >
                {politicianLabel(p)}
              </li>
            ))}
          </ul>
        )}
        {showDropdown && query.trim().length >= 2 && filtered.length === 0 && (
          <div className="absolute z-10 w-full bg-white border rounded shadow mt-1 px-3 py-2 text-sm text-gray-500">
            No politicians found
          </div>
        )}
      </div>

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
