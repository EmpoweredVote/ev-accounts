import { useState } from 'react';
import { apiFetch } from '../../../lib/api';
import { useAuthStore } from '../../../store/authStore';

interface Props {
  currentDisplayName: string | null;
  onComplete: () => void;
}

export function PseudonymStep({ currentDisplayName, onComplete }: Props) {
  const [name, setName] = useState(currentDisplayName ?? '');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { updateUser } = useAuthStore();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) {
      setError('Please choose a name for your community.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      await apiFetch('/account/me', {
        method: 'PATCH',
        body: JSON.stringify({ display_name: trimmed }),
      });
      await apiFetch('/auth/complete-onboarding', { method: 'POST' });
      updateUser({ displayName: trimmed, completedOnboarding: true });
      onComplete();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-6">
      <div className="max-w-md w-full space-y-8">

        <div className="space-y-2 text-center">
          <p className="text-gray-500 dark:text-gray-400 text-sm">Last step</p>
          <h2 className="text-2xl font-bold text-ev-black dark:text-white leading-snug">
            How will your community know you?
          </h2>
        </div>

        <div className="bg-ev-teal/5 border border-ev-teal/20 rounded-2xl p-5 space-y-2">
          <p className="text-ev-black dark:text-white font-medium text-sm leading-relaxed">
            This is the name other members will see — not your legal name.
            Your civic voice, your way.
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            You can update this anytime from your profile.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-ev-black dark:text-white mb-1.5">
              Your civic name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Maria V."
              maxLength={50}
              autoFocus
              className="w-full border border-gray-300 dark:border-gray-600 rounded-xl px-4 py-3 bg-white dark:bg-gray-900 text-ev-black dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-ev-teal text-base"
            />
            {error && (
              <p className="mt-2 text-sm text-ev-red">{error}</p>
            )}
          </div>

          <button
            type="submit"
            disabled={loading || !name.trim()}
            className="w-full bg-ev-teal text-white rounded-xl py-3.5 font-semibold text-base hover:bg-ev-teal/90 disabled:opacity-40 transition-colors"
          >
            {loading ? 'Setting up your account…' : "That's me →"}
          </button>
        </form>
      </div>
    </div>
  );
}
