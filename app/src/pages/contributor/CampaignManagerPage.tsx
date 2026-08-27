import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { apiFetch } from '../../lib/api';

interface ContributorPolitician {
  id: string;
  first_name: string | null;
  last_name: string | null;
  full_name: string | null;
  office_title: string;
  photo_url: string;
  home_jurisdiction_geoid: string | null;
}

interface CompassTopic {
  id: string;
  title: string;
  short_title: string;
  question_text: string;
  is_live: boolean;
  stances: { id: string; value: number; text: string }[];
}

interface PoliticianAnswer {
  topic_id: string;
  value: number;
  write_in_text: string | null;
}

interface PoliticianContext {
  topic_id: string;
  sources: string[];
}

export default function CampaignManagerPage() {
  const [politicians, setPoliticians] = useState<ContributorPolitician[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [listError, setListError] = useState<string | null>(null);

  const [selectedPolitician, setSelectedPolitician] = useState<ContributorPolitician | null>(null);
  const [topics, setTopics] = useState<CompassTopic[]>([]);
  const [existingAnswers, setExistingAnswers] = useState<PoliticianAnswer[]>([]);
  const [existingContext, setExistingContext] = useState<PoliticianContext[]>([]);
  const [loadingEditor, setLoadingEditor] = useState(false);
  const [editorError, setEditorError] = useState<string | null>(null);

  const [changedStances, setChangedStances] = useState<Record<string, number | null>>({});
  const [changedSources, setChangedSources] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastError, setToastError] = useState(false);

  useEffect(() => {
    apiFetch<ContributorPolitician[]>('/compass/contributors/politicians')
      .then(setPoliticians)
      .catch(() => setListError('Failed to load candidate. Please try again.'))
      .finally(() => setLoadingList(false));
  }, []);

  function showToastMessage(message: string, isError = false) {
    setToastMessage(message);
    setToastError(isError);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 2500);
  }

  async function openEditor(politician: ContributorPolitician) {
    setSelectedPolitician(politician);
    setChangedStances({});
    setChangedSources({});
    setEditorError(null);
    setLoadingEditor(true);
    setTopics([]);
    setExistingAnswers([]);
    setExistingContext([]);

    try {
      const [topicsData, answersData, contextData] = await Promise.all([
        apiFetch<CompassTopic[]>('/compass/topics'),
        apiFetch<PoliticianAnswer[]>(`/compass/politicians/${politician.id}/answers`),
        apiFetch<PoliticianContext[]>(`/compass/politicians/${politician.id}/context`),
      ]);
      setTopics(topicsData.filter(t => t.is_live));
      setExistingAnswers(answersData);
      setExistingContext(contextData);
    } catch {
      setEditorError('Failed to load topics or stances. Please try again.');
    } finally {
      setLoadingEditor(false);
    }
  }

  function getExistingValue(topicId: string): number | null {
    const answer = existingAnswers.find(a => a.topic_id === topicId);
    return answer ? answer.value : null;
  }

  function getDisplayValue(topicId: string): number | null {
    if (changedStances[topicId] !== undefined) return changedStances[topicId];
    return getExistingValue(topicId);
  }

  function getExistingSource(topicId: string): string {
    const ctx = existingContext.find(c => c.topic_id === topicId);
    return ctx?.sources?.[0] ?? '';
  }

  function getDisplaySource(topicId: string): string {
    if (changedSources[topicId] !== undefined) return changedSources[topicId];
    return getExistingSource(topicId);
  }

  function handleStanceSelect(topicId: string, value: number) {
    const current = getDisplayValue(topicId);
    if (current === value) {
      if (getExistingValue(topicId) !== null) {
        setChangedStances(prev => ({ ...prev, [topicId]: null }));
      } else {
        setChangedStances(prev => { const next = { ...prev }; delete next[topicId]; return next; });
      }
    } else {
      setChangedStances(prev => ({ ...prev, [topicId]: value }));
    }
  }

  function handleStanceReset(topicId: string) {
    if (getExistingValue(topicId) !== null) {
      setChangedStances(prev => ({ ...prev, [topicId]: null }));
    } else {
      setChangedStances(prev => { const next = { ...prev }; delete next[topicId]; return next; });
    }
  }

  function handleSourceChange(topicId: string, url: string) {
    setChangedSources(prev => ({ ...prev, [topicId]: url }));
  }

  async function handleSave() {
    if (!selectedPolitician) return;

    const stances = Object.entries(changedStances)
      .filter(([, v]) => v !== null)
      .map(([topic_id, value]) => ({ topic_id, value: value as number }));
    const clear_topic_ids = Object.entries(changedStances)
      .filter(([, v]) => v === null)
      .map(([topic_id]) => topic_id);
    const sourcesToSave = Object.entries(changedSources)
      .filter(([topic_id, url]) => url !== getExistingSource(topic_id))
      .map(([topic_id, source_url]) => ({ topic_id, source_url }));

    if (stances.length === 0 && clear_topic_ids.length === 0 && sourcesToSave.length === 0) {
      showToastMessage('No changes to save.');
      return;
    }
    setSaving(true);
    try {
      const saves: Promise<unknown>[] = [];

      if (stances.length > 0 || clear_topic_ids.length > 0) {
        saves.push(apiFetch(`/compass/stances/${selectedPolitician.id}/bulk`, {
          method: 'PUT',
          body: JSON.stringify({ stances, clear_topic_ids }),
        }));
      }
      if (sourcesToSave.length > 0) {
        saves.push(apiFetch(`/compass/contributors/${selectedPolitician.id}/sources`, {
          method: 'PUT',
          body: JSON.stringify({ sources: sourcesToSave }),
        }));
      }

      await Promise.all(saves);
      setChangedStances({});
      setChangedSources({});

      setExistingAnswers(prev => {
        let updated = [...prev];
        stances.forEach(({ topic_id, value }) => {
          const idx = updated.findIndex(a => a.topic_id === topic_id);
          if (idx >= 0) updated[idx] = { ...updated[idx], value };
          else updated.push({ topic_id, value, write_in_text: null });
        });
        return updated.filter(a => !clear_topic_ids.includes(a.topic_id));
      });
      setExistingContext(prev => {
        const updated = [...prev];
        sourcesToSave.forEach(({ topic_id, source_url }) => {
          const idx = updated.findIndex(c => c.topic_id === topic_id);
          const sources = source_url.trim() ? [source_url.trim()] : [];
          if (idx >= 0) updated[idx] = { ...updated[idx], sources };
          else updated.push({ topic_id, sources });
        });
        return updated;
      });

      showToastMessage('Saved successfully');
    } catch {
      showToastMessage('Failed to save. Please try again.', true);
    } finally {
      setSaving(false);
    }
  }

  const politician = politicians[0] ?? null;

  const politicianDisplayName = (p: ContributorPolitician) =>
    p.full_name ?? [p.first_name, p.last_name].filter(Boolean).join(' ') ?? 'Unknown Politician';

  const scopeBadgeLabel = politician
    ? `${politicianDisplayName(politician)} — ${politician.office_title}`
    : 'Candidate Coordinator';

  return (
    <div className="max-w-3xl mx-auto px-4 py-6">

      {/* Tab bar */}
      <nav className="flex gap-6 border-b border-gray-200 dark:border-gray-800 mb-6">
        <Link
          to="/"
          className="pb-2 border-b-2 border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 font-medium text-sm"
        >
          Profile
        </Link>
        <Link
          to="/contributor"
          className="pb-2 border-b-2 border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 font-medium text-sm"
        >
          Contributor
        </Link>
      </nav>

      {/* Header */}
      <div className="flex items-start justify-between gap-3 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Candidate Coordinator</h1>
          {!selectedPolitician && (
            <p className="text-xs text-gray-400 mt-0.5">
              Manage stances for your assigned candidate
            </p>
          )}
        </div>
        {/* Scope badge — always visible */}
        {!loadingList && politician && (
          <span className="text-xs font-semibold px-3 py-1.5 rounded-full bg-ev-red/15 text-ev-red border border-ev-red/20 whitespace-nowrap flex-shrink-0 max-w-[220px] text-right leading-tight">
            {scopeBadgeLabel}
          </span>
        )}
      </div>

      {/* Politician list view (single-item) */}
      {!selectedPolitician && (
        <>
          {loadingList ? (
            <div className="flex items-center justify-center py-16">
              <div className="w-6 h-6 border-2 border-ev-red border-t-transparent rounded-full animate-spin" />
            </div>
          ) : listError ? (
            <div className="bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 rounded-2xl p-5">
              <p className="text-sm text-red-600 dark:text-red-400">{listError}</p>
            </div>
          ) : !politician ? (
            <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-6 text-center">
              <p className="text-gray-500 text-sm">No candidate assigned to your role.</p>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="bg-white dark:bg-gray-950 rounded-2xl border border-ev-red/20 bg-ev-red/5 p-5 flex items-center gap-4">
                {/* Photo */}
                <div className="w-14 h-14 rounded-full overflow-hidden bg-ev-red/10 flex-shrink-0">
                  {politician.photo_url ? (
                    <img
                      src={politician.photo_url}
                      alt={politicianDisplayName(politician)}
                      className="w-full h-full object-cover"
                      onError={e => {
                        (e.currentTarget as HTMLImageElement).style.display = 'none';
                      }}
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-ev-red font-bold text-xl">
                      {(politicianDisplayName(politician)[0] ?? '?').toUpperCase()}
                    </div>
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-ev-black dark:text-white truncate">
                    {politicianDisplayName(politician)}
                  </p>
                  <p className="text-xs text-gray-500 truncate">{politician.office_title}</p>
                  <p className="text-xs text-ev-red font-medium mt-0.5">Your assigned candidate</p>
                </div>

                {/* CTA */}
                <button
                  onClick={() => openEditor(politician)}
                  className="flex-shrink-0 px-4 py-2 bg-ev-red text-white text-sm font-semibold rounded-xl hover:bg-ev-red/90 transition-colors"
                >
                  Edit Stances
                </button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Stance editor view */}
      {selectedPolitician && (
        <>
          {/* Sub-header with back link */}
          <div className="flex items-center gap-3 mb-5">
            <button
              onClick={() => {
                setSelectedPolitician(null);
                setChangedStances({});
              }}
              className="text-sm text-gray-500 hover:text-ev-red flex items-center gap-1 transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
              </svg>
              Back
            </button>
            <span className="text-gray-300 dark:text-gray-700">|</span>
            <p className="text-sm font-semibold text-ev-black dark:text-white">
              {politicianDisplayName(selectedPolitician)}
            </p>
            <span className="text-xs text-gray-500">{selectedPolitician.office_title}</span>
          </div>

          {loadingEditor ? (
            <div className="flex items-center justify-center py-16">
              <div className="w-6 h-6 border-2 border-ev-red border-t-transparent rounded-full animate-spin" />
            </div>
          ) : editorError ? (
            <div className="bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 rounded-2xl p-5">
              <p className="text-sm text-red-600 dark:text-red-400">{editorError}</p>
            </div>
          ) : (
            <>
              <div className="space-y-4">
                {topics.map(topic => {
                  const currentValue = getDisplayValue(topic.id);
                  return (
                    <div
                      key={topic.id}
                      className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <p className="text-sm font-bold text-ev-black dark:text-white">{topic.title}</p>
                          <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{topic.question_text}</p>
                        </div>
                        {currentValue !== null && (
                          <button
                            onClick={() => handleStanceReset(topic.id)}
                            title="Clear this stance"
                            className="flex-shrink-0 mt-0.5 w-5 h-5 flex items-center justify-center rounded-full text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors"
                          >
                            <svg className="w-3 h-3" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        )}
                      </div>
                      {/* Stance selector */}
                      <div className="flex flex-wrap gap-2">
                        {topic.stances
                          .slice()
                          .sort((a, b) => a.value - b.value)
                          .map(stance => {
                            const isSelected = currentValue === stance.value;
                            return (
                              <button
                                key={stance.id}
                                onClick={() => handleStanceSelect(topic.id, stance.value)}
                                className={[
                                  'flex-1 min-w-[80px] text-xs font-medium px-2.5 py-2 rounded-xl border transition-all text-center leading-snug',
                                  isSelected
                                    ? 'bg-ev-red border-ev-red/60 text-white font-semibold shadow-sm'
                                    : 'bg-transparent border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-ev-red/40 hover:text-ev-black dark:hover:text-white',
                                ].join(' ')}
                              >
                                <span className="block text-[10px] font-bold mb-0.5 opacity-60">{stance.value}</span>
                                {stance.text}
                              </button>
                            );
                          })}
                      </div>

                      {/* Source URL */}
                      <div className="pt-1 border-t border-gray-100 dark:border-gray-800">
                        <label className="block text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1">
                          Source URL
                        </label>
                        <div className="flex items-center gap-2">
                          <input
                            type="url"
                            value={getDisplaySource(topic.id)}
                            onChange={e => handleSourceChange(topic.id, e.target.value)}
                            placeholder="https://example.com/article"
                            className="flex-1 text-xs px-2.5 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 bg-transparent text-gray-700 dark:text-gray-300 placeholder-gray-300 dark:placeholder-gray-600 focus:outline-none focus:border-ev-red/60"
                          />
                          {getDisplaySource(topic.id) && (
                            <a
                              href={getDisplaySource(topic.id)}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="flex-shrink-0 text-gray-400 hover:text-ev-red transition-colors"
                              title="Open source"
                            >
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                              </svg>
                            </a>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Save button */}
              <div className="mt-6 pb-6">
                <button
                  onClick={handleSave}
                  disabled={saving || (Object.keys(changedStances).length === 0 && Object.keys(changedSources).length === 0)}
                  className="w-full py-3 bg-ev-red text-white text-sm font-bold rounded-xl hover:bg-ev-red/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {saving ? 'Saving…' : 'Save All'}
                </button>
              </div>
            </>
          )}
        </>
      )}

      {/* Toast */}
      {showToast && (
        <div
          className={[
            'fixed bottom-6 left-1/2 -translate-x-1/2 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-medium pointer-events-none',
            toastError
              ? 'bg-red-600 text-white'
              : 'bg-gray-900 text-white',
          ].join(' ')}
        >
          {toastMessage}
        </div>
      )}
    </div>
  );
}
