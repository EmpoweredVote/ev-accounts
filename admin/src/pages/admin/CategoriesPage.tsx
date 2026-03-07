import { useState, useEffect } from 'react';
import { apiFetch } from '../../lib/api';

interface Category {
  id: number;
  title: string;
  created_at: string;
}

interface Topic {
  id: number;
  title: string;
}

// NOTE: PUT /api/admin/compass/topics/:id/categories replaces ALL category assignments
// for that topic (replace semantics, not append). Sending { category_ids: [category.id] }
// will set this as the topic's ONLY category. Acceptable for Alpha seeding where topics
// typically belong to one category. For multi-category support, fetch topic's current
// categories first and merge before sending.
function CategoryCard({
  category,
  allTopics,
  onAssigned,
}: {
  category: Category & { topics: Topic[] };
  allTopics: Topic[];
  onAssigned: () => void;
}) {
  const unassignedTopics = allTopics.filter(
    (t) => !category.topics.some((ct) => ct.id === t.id),
  );
  const [selectedTopicId, setSelectedTopicId] = useState<string>('');
  const [assigning, setAssigning] = useState(false);

  async function handleAssign() {
    if (!selectedTopicId) return;
    setAssigning(true);
    try {
      await apiFetch(`/admin/compass/topics/${selectedTopicId}/categories`, {
        method: 'PUT',
        body: JSON.stringify({ category_ids: [category.id] }),
      });
      setSelectedTopicId('');
      onAssigned();
    } catch (err) {
      console.error('Failed to assign topic:', err);
    } finally {
      setAssigning(false);
    }
  }

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-semibold text-gray-900">{category.title}</h3>
        <span className="text-xs text-gray-400">
          {category.topics.length} topic{category.topics.length !== 1 ? 's' : ''}
        </span>
      </div>

      {/* Assigned topics */}
      {category.topics.length > 0 && (
        <div className="flex flex-wrap gap-1.5 mb-3">
          {category.topics.map((t) => (
            <span
              key={t.id}
              className="px-2 py-0.5 text-xs bg-yellow-50 text-ev-black border border-ev-yellow rounded-full"
            >
              {t.title}
            </span>
          ))}
        </div>
      )}

      {/* Add topic */}
      {unassignedTopics.length > 0 && (
        <div className="flex gap-2 mt-2">
          <select
            value={selectedTopicId}
            onChange={(e) => setSelectedTopicId(e.target.value)}
            className="flex-1 px-2 py-1.5 text-xs border border-gray-300 rounded-md bg-white"
          >
            <option value="">Assign a topic...</option>
            {unassignedTopics.map((t) => (
              <option key={t.id} value={String(t.id)}>
                {t.title}
              </option>
            ))}
          </select>
          <button
            onClick={handleAssign}
            disabled={!selectedTopicId || assigning}
            className="px-3 py-1.5 text-xs bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400 disabled:opacity-50"
          >
            {assigning ? 'Assigning...' : 'Assign'}
          </button>
        </div>
      )}
    </div>
  );
}

export function CategoriesPage() {
  const [categories, setCategories] = useState<Array<Category & { topics: Topic[] }>>([]);
  const [allTopics, setAllTopics] = useState<Topic[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newCategoryTitle, setNewCategoryTitle] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories'),
      apiFetch<{ topics: Topic[] }>('/admin/compass/topics'),
    ])
      .then(([catData, topicData]) => {
        setCategories(catData.categories);
        setAllTopics(topicData.topics);
      })
      .catch((err: unknown) =>
        setError(err instanceof Error ? err.message : 'Failed to load data'),
      )
      .finally(() => setLoading(false));
  }, []);

  async function refreshCategories() {
    const data = await apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>(
      '/compass/categories',
    );
    setCategories(data.categories);
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!newCategoryTitle.trim()) return;
    setCreating(true);
    setCreateError(null);
    try {
      await apiFetch('/admin/compass/categories', {
        method: 'POST',
        body: JSON.stringify({ title: newCategoryTitle.trim() }),
      });
      setNewCategoryTitle('');
      await refreshCategories();
    } catch (err) {
      setCreateError(err instanceof Error ? err.message : 'Failed to create category');
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="max-w-2xl">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Categories</h1>
      </div>

      {/* Inline create form */}
      <form onSubmit={handleCreate} className="flex gap-3 mb-6">
        <input
          type="text"
          value={newCategoryTitle}
          onChange={(e) => setNewCategoryTitle(e.target.value)}
          placeholder="New category title..."
          className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-yellow focus:border-ev-yellow"
        />
        <button
          type="submit"
          disabled={creating || !newCategoryTitle.trim()}
          className="px-4 py-2 text-sm bg-ev-yellow text-ev-black rounded-md font-medium hover:bg-yellow-400 disabled:opacity-50"
        >
          {creating ? 'Creating...' : 'Add Category'}
        </button>
      </form>

      {createError && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
          {createError}
        </div>
      )}

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
          {error}
        </div>
      )}

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="animate-pulse h-16 bg-gray-100 rounded-lg" />
          ))}
        </div>
      ) : categories.length === 0 ? (
        <p className="text-sm text-gray-400">No categories yet.</p>
      ) : (
        <div className="space-y-4">
          {categories.map((category) => (
            <CategoryCard
              key={category.id}
              category={category}
              allTopics={allTopics}
              onAssigned={refreshCategories}
            />
          ))}
        </div>
      )}
    </div>
  );
}
