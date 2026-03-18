import { useEffect, useState } from 'react';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { apiFetch } from '../../lib/api';

// ── Types ─────────────────────────────────────────────────────────────────────

interface Politician {
  id: string;
  first_name: string;
  last_name: string;
  preferred_name: string | null;
  full_name: string | null;
  office_title: string | null;
  photo_origin_url: string | null;
  is_active: boolean;
  is_candidate: boolean;
  answer_count: number;
}

interface Topic {
  id: string;
  title: string;
  short_title: string | null;
}

interface Stance {
  id: string;
  topic_id: string;
  value: number;
  text: string;
}

interface PoliticianAnswer {
  topic_id: string;
  value: number;
}

// ── PoliticiansPage ───────────────────────────────────────────────────────────

export function PoliticiansPage() {
  const [politicians, setPoliticians] = useState<Politician[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);
  const [topicStances, setTopicStances] = useState<Record<string, Stance[]>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  useEffect(() => {
    Promise.all([
      apiFetch<{ politicians: Politician[] }>('/admin/compass/politicians'),
      apiFetch<{ topics: Topic[] }>('/admin/compass/topics'),
    ])
      .then(([polData, topicData]) => {
        setPoliticians(polData.politicians);
        setTopics(topicData.topics);
      })
      .catch((err) => setError(err instanceof Error ? err.message : 'Failed to load'))
      .finally(() => setLoading(false));
  }, []);

  async function refreshPoliticians() {
    try {
      const data = await apiFetch<{ politicians: Politician[] }>('/admin/compass/politicians');
      setPoliticians(data.politicians);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to refresh politicians');
    }
  }

  const selectedPolitician = politicians.find((p) => p.id === selectedId) ?? null;

  function handleStancesNeeded(topicId: string) {
    if (!topicStances[topicId]) {
      apiFetch<Stance[]>(`/admin/compass/topics/${topicId}/stances`)
        .then((data) => setTopicStances((prev) => ({ ...prev, [topicId]: data })))
        .catch((err) => console.error(err));
    }
  }

  return (
    <div className="flex gap-6 h-full">
      {/* Left column: politician list */}
      <div className="w-80 shrink-0 flex flex-col gap-3 overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Politicians</h1>
          <button
            onClick={() => setIsCreateOpen(true)}
            className="px-3 py-1.5 text-sm bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400"
          >
            New Politician
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
              <div key={i} className="animate-pulse h-12 bg-gray-200 dark:bg-gray-700 rounded" />
            ))}
          </div>
        ) : politicians.length === 0 ? (
          <p className="text-sm text-gray-400 dark:text-gray-500 px-3 py-2">No politicians yet.</p>
        ) : (
          <div className="flex flex-col gap-1">
            {politicians.map((p) => (
              <div
                key={p.id}
                onClick={() => setSelectedId(p.id)}
                className={`cursor-pointer flex items-center justify-between px-3 py-2.5 rounded-md border transition-colors ${
                  !p.is_active ? 'opacity-50' : ''
                } ${
                  selectedId === p.id
                    ? 'bg-yellow-50 border-ev-yellow'
                    : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                <div className="flex flex-col min-w-0">
                  <span className="text-sm font-medium text-gray-900 dark:text-white truncate">
                    {p.full_name || `${p.first_name} ${p.last_name}`}
                    {!p.is_active && (
                      <span className="ml-1 text-xs text-gray-400 dark:text-gray-500">(inactive)</span>
                    )}
                  </span>
                  {p.office_title && (
                    <span className="text-xs text-gray-500 dark:text-gray-400 truncate">{p.office_title}</span>
                  )}
                </div>
                <span className="ml-2 text-xs text-gray-400 dark:text-gray-500 shrink-0">
                  {p.answer_count} answers
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Right panel: detail */}
      {selectedPolitician ? (
        <PoliticianDetailPanel
          politician={selectedPolitician}
          topics={topics}
          topicStances={topicStances}
          onUpdate={refreshPoliticians}
          onStancesNeeded={handleStancesNeeded}
        />
      ) : (
        <div className="flex-1" />
      )}

      <CreatePoliticianModal
        open={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onCreated={(result) => {
          setPoliticians((prev) => [...prev, result]);
          setSelectedId(result.id);
          setIsCreateOpen(false);
        }}
      />
    </div>
  );
}

// ── CreatePoliticianModal ─────────────────────────────────────────────────────

const EMPTY_CREATE_FORM = {
  first_name: '',
  last_name: '',
  preferred_name: '',
  full_name: '',
  office_title: '',
  photo_origin_url: '',
};

function CreatePoliticianModal({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: (politician: Politician) => void;
}) {
  const [form, setForm] = useState(EMPTY_CREATE_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setForm(EMPTY_CREATE_FORM);
      setError(null);
    }
  }, [open]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      const body: Record<string, string> = {
        first_name: form.first_name.trim(),
        last_name: form.last_name.trim(),
      };
      if (form.preferred_name.trim()) body.preferred_name = form.preferred_name.trim();
      if (form.full_name.trim()) body.full_name = form.full_name.trim();
      if (form.office_title.trim()) body.office_title = form.office_title.trim();
      if (form.photo_origin_url.trim()) body.photo_origin_url = form.photo_origin_url.trim();

      const result = await apiFetch<Politician>('/admin/compass/politicians', {
        method: 'POST',
        body: JSON.stringify(body),
      });
      onCreated(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create politician');
    } finally {
      setSaving(false);
    }
  }

  function field(key: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm((prev) => ({ ...prev, [key]: e.target.value }));
  }

  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="bg-white dark:bg-gray-900 rounded-lg shadow-xl w-full max-w-md p-6 max-h-[90vh] overflow-y-auto">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            New Politician
          </DialogTitle>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            {/* First name */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                First Name <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                value={form.first_name}
                onChange={field('first_name')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Last name */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Last Name <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                required
                value={form.last_name}
                onChange={field('last_name')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Preferred name */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Preferred Name <span className="text-gray-400">(optional)</span>
              </label>
              <input
                type="text"
                value={form.preferred_name}
                onChange={field('preferred_name')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Full name */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Full Name <span className="text-gray-400">(optional, overrides first+last)</span>
              </label>
              <input
                type="text"
                value={form.full_name}
                onChange={field('full_name')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Office title */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Office Title <span className="text-gray-400">(optional)</span>
              </label>
              <input
                type="text"
                value={form.office_title}
                onChange={field('office_title')}
                placeholder="e.g. U.S. Senator"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
            </div>

            {/* Photo URL */}
            <div>
              <label className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                Photo URL <span className="text-gray-400">(optional)</span>
              </label>
              <input
                type="url"
                value={form.photo_origin_url}
                onChange={field('photo_origin_url')}
                placeholder="https://..."
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white"
              />
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
                onClick={onClose}
                className="px-3 py-1.5 text-sm text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={saving}
                className="px-3 py-1.5 text-sm bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400 disabled:opacity-50"
              >
                {saving ? 'Creating...' : 'Create Politician'}
              </button>
            </div>
          </form>
        </DialogPanel>
      </div>
    </Dialog>
  );
}

// ── SaveButton ────────────────────────────────────────────────────────────────

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

// ── SourcesList ───────────────────────────────────────────────────────────────

function SourcesList({
  sources,
  onChange,
}: {
  sources: string[];
  onChange: (s: string[]) => void;
}) {
  const [newSource, setNewSource] = useState('');

  function add() {
    if (newSource.trim()) {
      onChange([...sources, newSource.trim()]);
      setNewSource('');
    }
  }

  return (
    <div className="space-y-1.5">
      <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
        Sources
      </label>
      {sources.map((src, i) => (
        <div key={i} className="flex items-center gap-2">
          <span className="flex-1 text-xs text-gray-600 dark:text-gray-400 truncate">{src}</span>
          <button
            onClick={() => onChange(sources.filter((_, j) => j !== i))}
            className="text-xs text-red-500 hover:text-red-700 shrink-0"
          >
            Remove
          </button>
        </div>
      ))}
      <div className="flex gap-2 mt-1">
        <input
          type="text"
          value={newSource}
          onChange={(e) => setNewSource(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), add())}
          placeholder="https://..."
          className="flex-1 px-2 py-1.5 text-xs border border-gray-300 rounded-md dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
        />
        <button
          onClick={add}
          className="px-2 py-1.5 text-xs border border-gray-300 rounded-md hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
        >
          Add
        </button>
      </div>
    </div>
  );
}

// ── StanceSelector ────────────────────────────────────────────────────────────

import { RadioGroup, Radio, Disclosure, DisclosureButton, DisclosurePanel } from '@headlessui/react';

function StanceSelector({
  stances,
  value,
  onChange,
}: {
  stances: Stance[];
  value: number | null;
  onChange: (v: number) => void;
}) {
  return (
    <RadioGroup value={value ?? undefined} onChange={onChange} className="space-y-1.5">
      {stances.map((stance) => (
        <Radio
          key={stance.value}
          value={stance.value}
          className={({ checked }: { checked: boolean }) =>
            `flex items-start gap-3 p-2.5 rounded-md border cursor-pointer text-sm ${
              checked ? 'border-ev-yellow bg-yellow-50' : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
            }`
          }
        >
          <span className="font-medium text-gray-400 dark:text-gray-500 w-4 shrink-0 mt-0.5">{stance.value}</span>
          <span className="text-gray-800 dark:text-gray-200">{stance.text}</span>
        </Radio>
      ))}
    </RadioGroup>
  );
}

// ── TopicAnswerRow ────────────────────────────────────────────────────────────

interface TopicAnswerRowProps {
  topic: Topic;
  stances: Stance[];
  existingAnswer: PoliticianAnswer | null;
  politicianId: string;
  onStancesNeeded: (topicId: string) => void;
}

function TopicAnswerRow({
  topic,
  stances,
  existingAnswer,
  politicianId,
  onStancesNeeded,
}: TopicAnswerRowProps) {
  const [selectedValue, setSelectedValue] = useState<number | null>(
    existingAnswer?.value ?? null,
  );
  const [reasoning, setReasoning] = useState('');
  const [sources, setSources] = useState<string[]>([]);

  useEffect(() => {
    if (stances.length === 0) onStancesNeeded(topic.id);
  }, [topic.id]);

  async function handleSave() {
    const calls: Promise<unknown>[] = [];
    if (selectedValue !== null) {
      calls.push(
        apiFetch(`/admin/compass/politicians/${politicianId}/answers`, {
          method: 'PUT',
          body: JSON.stringify({ answers: [{ topic_id: topic.id, value: selectedValue }] }),
        }),
      );
    }
    if (reasoning.trim() || sources.length > 0) {
      calls.push(
        apiFetch(`/admin/compass/politicians/${politicianId}/context`, {
          method: 'POST',
          body: JSON.stringify({ topic_id: topic.id, reasoning: reasoning.trim(), sources }),
        }),
      );
    }
    if (calls.length === 0) return;
    await Promise.all(calls);
  }

  return (
    <Disclosure>
      <DisclosureButton className="w-full flex items-center justify-between px-4 py-2.5 bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 text-sm font-medium text-left rounded-md border border-gray-200 dark:border-gray-700 text-gray-900 dark:text-white">
        <span>{topic.title}</span>
        <span className="text-xs text-gray-400 dark:text-gray-500 ml-2 shrink-0">
          {existingAnswer ? `Stance ${existingAnswer.value}` : 'Not answered'}
        </span>
      </DisclosureButton>
      <DisclosurePanel className="px-4 py-3 border border-t-0 border-gray-200 dark:border-gray-700 rounded-b-md space-y-3 bg-white dark:bg-gray-900">
        {stances.length === 0 ? (
          <div className="animate-pulse h-20 bg-gray-100 dark:bg-gray-800 rounded" />
        ) : (
          <StanceSelector stances={stances} value={selectedValue} onChange={setSelectedValue} />
        )}
        <div>
          <label className="block text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
            Reasoning
          </label>
          <textarea
            rows={3}
            value={reasoning}
            onChange={(e) => setReasoning(e.target.value)}
            placeholder="Enter reasoning..."
            className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
          />
        </div>
        <SourcesList sources={sources} onChange={setSources} />
        <div className="flex justify-end pt-1">
          <SaveButton onSave={handleSave} />
        </div>
      </DisclosurePanel>
    </Disclosure>
  );
}

// ── PoliticianDetailPanel ─────────────────────────────────────────────────────

function PoliticianDetailPanel({
  politician,
  topics,
  topicStances,
  onUpdate,
  onStancesNeeded,
}: {
  politician: Politician;
  topics: Topic[];
  topicStances: Record<string, Stance[]>;
  onUpdate: () => void;
  onStancesNeeded: (topicId: string) => void;
}) {
  const [answers, setAnswers] = useState<PoliticianAnswer[]>([]);
  const [answersLoading, setAnswersLoading] = useState(false);
  const [topicSearch, setTopicSearch] = useState('');

  useEffect(() => {
    setAnswersLoading(true);
    apiFetch<PoliticianAnswer[]>(`/compass/politicians/${politician.id}/answers`)
      .then((data) => setAnswers(Array.isArray(data) ? data : []))
      .catch((err) => console.error(err))
      .finally(() => setAnswersLoading(false));
  }, [politician.id]);

  // Suppress unused variable warning — onUpdate available for future profile edit save
  void onUpdate;

  const filteredTopics = topics.filter((t) =>
    t.title.toLowerCase().includes(topicSearch.toLowerCase()),
  );

  return (
    <div className="flex-1 bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 overflow-y-auto">
      {/* Profile header */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          {politician.full_name || `${politician.first_name} ${politician.last_name}`}
        </h2>
        {politician.office_title && (
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{politician.office_title}</p>
        )}
        {!politician.is_active && (
          <span className="inline-block mt-1 text-xs text-red-600 bg-red-50 px-2 py-0.5 rounded">
            Inactive
          </span>
        )}
      </div>

      {/* Compass answers */}
      <div className="p-6">
        <div className="flex items-center justify-between mb-3">
          <label className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Compass Answers
          </label>
          <input
            type="text"
            placeholder="Filter topics..."
            value={topicSearch}
            onChange={(e) => setTopicSearch(e.target.value)}
            className="px-2 py-1 text-xs border border-gray-300 rounded-md w-40 dark:bg-gray-800 dark:border-gray-600 dark:text-white dark:placeholder-gray-500"
          />
        </div>

        {answersLoading ? (
          <div className="space-y-1">
            {[1, 2, 3].map((i) => (
              <div key={i} className="animate-pulse h-10 bg-gray-100 dark:bg-gray-800 rounded" />
            ))}
          </div>
        ) : (
          <div className="space-y-1">
            {filteredTopics.map((topic) => (
              <TopicAnswerRow
                key={topic.id}
                topic={topic}
                stances={topicStances[topic.id] ?? []}
                existingAnswer={answers.find((a) => a.topic_id === topic.id) ?? null}
                politicianId={politician.id}
                onStancesNeeded={onStancesNeeded}
              />
            ))}
            {filteredTopics.length === 0 && (
              <p className="text-sm text-gray-400 dark:text-gray-500 py-4 text-center">
                No topics match &quot;{topicSearch}&quot;
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
