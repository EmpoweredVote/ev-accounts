import { useEffect, useState } from 'react';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { apiFetch } from '../../lib/api';

interface Stance {
  id: string;
  value: number;
  text: string;
}

interface Topic {
  id: string;
  title: string;
  short_title: string | null;
  question_text: string;
  is_live: boolean;
  created_at: string;
}

function LiveToggle({ topic, onUpdate }: { topic: Topic; onUpdate: () => void }) {
  const [isLive, setIsLive] = useState(topic.is_live);
  const [saving, setSaving] = useState(false);

  async function handleToggle(e: React.MouseEvent) {
    e.stopPropagation();
    const next = !isLive;
    setIsLive(next); // optimistic
    setSaving(true);
    try {
      await apiFetch(`/admin/compass/topics/${topic.id}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_live: next }),
      });
      onUpdate();
    } catch {
      setIsLive(!next); // revert
    } finally {
      setSaving(false);
    }
  }

  return (
    <button
      onClick={handleToggle}
      disabled={saving}
      className={`px-2 py-0.5 rounded-full text-xs font-medium shrink-0 ml-2 ${
        isLive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
      } disabled:opacity-50`}
    >
      {isLive ? 'Live' : 'Draft'}
    </button>
  );
}

export function TopicsPage() {
  const [topics, setTopics] = useState<Topic[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  async function refreshTopics() {
    try {
      const data = await apiFetch<{ topics: Topic[] }>('/admin/compass/topics');
      setTopics(data.topics);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load topics');
    }
  }

  useEffect(() => {
    apiFetch<{ topics: Topic[] }>('/admin/compass/topics')
      .then((data) => setTopics(data.topics))
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load topics'))
      .finally(() => setLoading(false));
  }, []);

  const selectedTopic = topics.find((t) => t.id === selectedId) ?? null;

  return (
    <div className="flex gap-6 h-full">
      {/* Left column: topic list */}
      <div className="w-80 shrink-0 flex flex-col gap-3 overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Topics</h1>
          <button
            onClick={() => setIsCreateOpen(true)}
            className="px-3 py-1.5 text-sm bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400"
          >
            New Topic
          </button>
        </div>

        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
            {error}
          </div>
        )}

        {loading ? (
          <div className="space-y-2">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="animate-pulse h-4 bg-gray-200 dark:bg-gray-700 rounded" />
            ))}
          </div>
        ) : topics.length === 0 ? (
          <p className="text-sm text-gray-400 dark:text-gray-500 px-3 py-2">No topics yet.</p>
        ) : (
          <div className="flex flex-col gap-1">
            {topics.map((t) => (
              <div
                key={t.id}
                onClick={() => setSelectedId(t.id)}
                className={`cursor-pointer flex items-center justify-between px-3 py-2 rounded-md border ${
                  selectedId === t.id
                    ? 'bg-yellow-50 border-ev-yellow'
                    : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                <span className="text-sm font-medium text-gray-900 dark:text-white truncate">{t.title}</span>
                <LiveToggle topic={t} onUpdate={refreshTopics} />
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Right panel: detail */}
      {selectedTopic && (
        <TopicDetailPanel topic={selectedTopic} onUpdate={refreshTopics} />
      )}

      <CreateTopicModal
        open={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onCreated={(t) => {
          refreshTopics();
          setSelectedId(t.id);
          setIsCreateOpen(false);
        }}
      />
    </div>
  );
}

// ── TopicDetailPanel ──────────────────────────────────────────────────────────

type SaveState = 'idle' | 'saving' | 'done' | 'error';

function SaveButton({
  onSave,
  label = 'Save',
}: {
  onSave: () => Promise<void>;
  label?: string;
}) {
  const [state, setState] = useState<SaveState>('idle');

  async function handleClick() {
    setState('saving');
    try {
      await onSave();
      setState('done');
      setTimeout(() => setState('idle'), 2000);
    } catch {
      setState('error');
      setTimeout(() => setState('idle'), 3000);
    }
  }

  const labels: Record<SaveState, string> = {
    idle: label,
    saving: 'Saving...',
    done: 'Saved',
    error: 'Error — retry',
  };

  return (
    <button
      onClick={handleClick}
      disabled={state === 'saving'}
      className={`px-3 py-1.5 text-sm rounded-md font-medium transition-colors ${
        state === 'done'
          ? 'bg-green-600 text-white'
          : state === 'error'
            ? 'bg-red-600 text-white'
            : 'bg-ev-yellow text-ev-black hover:bg-yellow-400 disabled:opacity-50'
      }`}
    >
      {labels[state]}
    </button>
  );
}

function TopicDetailPanel({
  topic,
  onUpdate,
}: {
  topic: Topic;
  onUpdate: () => void;
}) {
  const [stances, setStances] = useState<Stance[]>([]);
  const [stanceEdits, setStanceEdits] = useState<Record<string, string>>({});
  const [stancesLoading, setStancesLoading] = useState(false);

  useEffect(() => {
    setStancesLoading(true);
    apiFetch<Stance[]>(`/admin/compass/topics/${topic.id}/stances`)
      .then((data) => {
        setStances(data);
        setStanceEdits({});
      })
      .catch((err) => console.error(err))
      .finally(() => setStancesLoading(false));
  }, [topic.id]);

  async function saveStances() {
    const changed = stances.filter(
      (s) => stanceEdits[s.id] !== undefined && stanceEdits[s.id] !== s.text,
    );
    await Promise.all(
      changed.map((s) =>
        apiFetch(`/admin/compass/stances/${s.id}`, {
          method: 'PATCH',
          body: JSON.stringify({ text: stanceEdits[s.id] }),
        }),
      ),
    );
    // Re-fetch to get server-confirmed values
    const fresh = await apiFetch<Stance[]>(`/admin/compass/topics/${topic.id}/stances`);
    setStances(fresh);
    setStanceEdits({});
    onUpdate();
  }

  return (
    <div className="flex-1 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-6 overflow-y-auto">
      {/* Panel header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{topic.title}</h2>
          {topic.short_title && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{topic.short_title}</p>
          )}
        </div>
        <LiveToggle topic={topic} onUpdate={onUpdate} />
      </div>

      {/* Question text */}
      <div className="mb-6">
        <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
          Question
        </label>
        <p className="text-sm text-gray-700 dark:text-gray-300">{topic.question_text}</p>
      </div>

      {/* Stances section */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-3">
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Stances
          </label>
          {Object.keys(stanceEdits).length > 0 && (
            <SaveButton onSave={saveStances} label="Save stances" />
          )}
        </div>

        {stancesLoading ? (
          <div className="space-y-2">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="animate-pulse h-8 bg-gray-100 dark:bg-gray-800 rounded" />
            ))}
          </div>
        ) : (
          <div className="space-y-2">
            {stances.map((stance) => (
              <div key={stance.id} className="flex items-center gap-3">
                <span className="w-5 shrink-0 text-sm font-medium text-gray-400 dark:text-gray-500">
                  {stance.value}
                </span>
                <input
                  type="text"
                  value={stanceEdits[stance.id] ?? stance.text}
                  onChange={(e) =>
                    setStanceEdits((prev) => ({ ...prev, [stance.id]: e.target.value }))
                  }
                  className="flex-1 px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
                />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── CreateTopicModal ──────────────────────────────────────────────────────────

const EMPTY_FORM = {
  title: '',
  question_text: '',
  short_title: '',
  stances: ['', '', '', '', ''],
};

function CreateTopicModal({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: (v: boolean) => void;
  onCreated: (topic: Topic) => void;
}) {
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setForm(EMPTY_FORM);
      setError(null);
    }
  }, [open]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const result = await apiFetch<{ topic: Topic; stances: Stance[] }>(
        '/admin/compass/topics',
        {
          method: 'POST',
          body: JSON.stringify({
            title: form.title.trim(),
            question_text: form.question_text.trim(),
            short_title: form.short_title.trim() || undefined,
            // A new topic is created on the revision model — it needs a full
            // 5-rung ladder to display in a season and to be pinnable — so send
            // all five (the inputs are required, so none are blank).
            stances: form.stances.map((text, i) => ({ value: i + 1, text: text.trim() })),
          }),
        },
      );
      onCreated(result.topic);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create topic');
    } finally {
      setSaving(false);
    }
  }

  function setStance(index: number, value: string) {
    setForm((prev) => {
      const stances = [...prev.stances];
      stances[index] = value;
      return { ...prev, stances };
    });
  }

  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="bg-white dark:bg-gray-900 rounded-lg shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            New Topic
          </DialogTitle>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            {/* Title */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Title <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                value={form.title}
                onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Question text */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Question Text <span className="text-red-500">*</span>
              </label>
              <textarea
                rows={3}
                required
                value={form.question_text}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, question_text: e.target.value }))
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Short title */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Short Title <span className="text-gray-400">(optional)</span>
              </label>
              <input
                type="text"
                value={form.short_title}
                onChange={(e) =>
                  setForm((prev) => ({ ...prev, short_title: e.target.value }))
                }
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Stances */}
            <div>
              <label className="block text-xs font-medium text-gray-700 mb-2">
                Stances <span className="text-red-500">*</span>{' '}
                <span className="text-gray-400 font-normal">(all 5 required)</span>
              </label>
              <div className="flex flex-col gap-2">
                {form.stances.map((text, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <span className="w-16 shrink-0 text-xs text-gray-500 dark:text-gray-400">
                      Stance {i + 1}
                    </span>
                    <input
                      type="text"
                      required
                      value={text}
                      onChange={(e) => setStance(i, e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
                    />
                  </div>
                ))}
              </div>
            </div>

            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm dark:bg-red-950/40 dark:border-red-800/60 dark:text-red-400">
                {error}
              </div>
            )}

            {/* Actions */}
            <div className="flex justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => onClose(false)}
                className="px-3 py-1.5 text-sm text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={saving}
                className="px-3 py-1.5 text-sm bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400 disabled:opacity-50"
              >
                {saving ? 'Creating...' : 'Create Topic'}
              </button>
            </div>
          </form>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
