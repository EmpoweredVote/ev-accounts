import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
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

export default function CampaignManagerPage() {
  const [politicians, setPoliticians] = useState<ContributorPolitician[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [listError, setListError] = useState<string | null>(null);

  const [selectedPolitician, setSelectedPolitician] = useState<ContributorPolitician | null>(null);
  const [topics, setTopics] = useState<CompassTopic[]>([]);
  const [existingAnswers, setExistingAnswers] = useState<PoliticianAnswer[]>([]);
  const [loadingEditor, setLoadingEditor] = useState(false);
  const [editorError, setEditorError] = useState<string | null>(null);

  // Map of topic_id -> selected value (only tracks changes)
  const [changedStances, setChangedStances] = useState<Record<string, number>>({});
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
    setEditorError(null);
    setLoadingEditor(true);
    setTopics([]);
    setExistingAnswers([]);

    try {
      const [topicsData, answersData] = await Promise.all([
        apiFetch<CompassTopic[]>('/compass/topics'),
        apiFetch<PoliticianAnswer[]>(`/compass/politicians/${politician.id}/answers`),
      ]);
      setTopics(topicsData.filter(t => t.is_live));
      setExistingAnswers(answersData);
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

  function handleStanceSelect(topicId: string, value: number) {
    setChangedStances(prev => ({ ...prev, [topicId]: value }));
  }

  async function handleSave() {
    if (!selectedPolitician) return;
    const stances = Object.entries(changedStances).map(([topic_id, value]) => ({ topic_id, value }));
    if (stances.length === 0) {
      showToastMessage('No changes to save.');
      return;
    }
    setSaving(true);
    try {
      await apiFetch(`/compass/stances/${selectedPolitician.id}/bulk`, {
        method: 'PUT',
        body: JSON.stringify({ stances }),
      });
      setChangedStances({});
      // Update existingAnswers to reflect saved values
      setExistingAnswers(prev => {
        const updated = [...prev];
        stances.forEach(({ topic_id, value }) => {
          const idx = updated.findIndex(a => a.topic_id === topic_id);
          if (idx >= 0) {
            updated[idx] = { ...updated[idx], value };
          } else {
            updated.push({ topic_id, value, write_in_text: null });
          }
        });
        return updated;
      });
      showToastMessage('Stances saved successfully');
    } catch {
      showToastMessage('Failed to save stances. Please try again.', true);
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
                      <div>
                        <p className="text-sm font-bold text-ev-black dark:text-white">{topic.title}</p>
                        <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{topic.question_text}</p>
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
                    </div>
                  );
                })}
              </div>

              {/* Save button */}
              <div className="mt-6 pb-6">
                <button
                  onClick={handleSave}
                  disabled={saving || Object.keys(changedStances).length === 0}
                  className="w-full py-3 bg-ev-red text-white text-sm font-bold rounded-xl hover:bg-ev-red/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {saving ? 'Saving…' : `Save All${Object.keys(changedStances).length > 0 ? ` (${Object.keys(changedStances).length} change${Object.keys(changedStances).length === 1 ? '' : 's'})` : ''}`}
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
