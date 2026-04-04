import { useEffect, useState } from 'react';
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

function getJurisdictionLabel(politicians: ContributorPolitician[]): string {
  const geoid = politicians[0]?.home_jurisdiction_geoid;
  if (geoid) return geoid;
  return 'Your Jurisdiction';
}

export default function EssentialsEditorPage() {
  const [politicians, setPoliticians] = useState<ContributorPolitician[]>([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [selected, setSelected] = useState<ContributorPolitician | null>(null);

  // Editor field state
  const [bio, setBio] = useState('');
  const [preferredName, setPreferredName] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [saving, setSaving] = useState(false);

  // Toast state
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastError, setToastError] = useState(false);

  function showToastMsg(msg: string, isError = false) {
    setToastMessage(msg);
    setToastError(isError);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 2500);
  }

  useEffect(() => {
    apiFetch<ContributorPolitician[]>('/compass/contributors/politicians')
      .then(setPoliticians)
      .catch((err: unknown) => {
        setFetchError(err instanceof Error ? err.message : 'Failed to load politicians');
      })
      .finally(() => setLoading(false));
  }, []);

  function handleSelect(pol: ContributorPolitician) {
    setSelected(pol);
    setBio('');
    setPreferredName('');
    setPhotoUrl('');
  }

  function handleBack() {
    setSelected(null);
    setBio('');
    setPreferredName('');
    setPhotoUrl('');
  }

  async function handleSave() {
    if (!selected) return;

    const body: Record<string, string> = {};
    if (bio.trim()) body.bio = bio.trim();
    if (preferredName.trim()) body.preferred_name = preferredName.trim();
    if (photoUrl.trim()) body.photo_origin_url = photoUrl.trim();

    if (Object.keys(body).length === 0) {
      showToastMsg('No changes to save.', true);
      return;
    }

    setSaving(true);
    try {
      await apiFetch(`/essentials/politicians/${selected.id}`, {
        method: 'PATCH',
        body: JSON.stringify(body),
      });
      showToastMsg('Changes saved successfully');
      setBio('');
      setPreferredName('');
      setPhotoUrl('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Save failed';
      if (msg.includes('403')) {
        showToastMsg("You don't have permission to edit this politician.", true);
      } else if (msg.includes('422') || msg === 'RESTRICTED_FIELD') {
        showToastMsg('Invalid field in request.', true);
      } else {
        showToastMsg(msg || 'Save failed. Please try again.', true);
      }
    } finally {
      setSaving(false);
    }
  }

  const inputClass =
    'w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 py-2 text-sm text-ev-black dark:text-white focus:outline-none focus:ring-2 focus:ring-ev-teal/40';

  return (
    <div className="max-w-3xl mx-auto px-4 py-6 space-y-6">

      {/* Header */}
      <div className="space-y-1">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Essentials Editor</h1>
          {!loading && politicians.length > 0 && (
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-ev-teal/15 text-ev-teal">
              {getJurisdictionLabel(politicians)}
            </span>
          )}
        </div>
        {!selected && (
          <p className="text-sm text-gray-500">
            Select a politician to update their biographical information.
          </p>
        )}
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-16">
          <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* Fetch error */}
      {!loading && fetchError && (
        <div className="rounded-xl border border-red-200 bg-red-50 dark:bg-red-900/10 dark:border-red-800 p-4">
          <p className="text-sm text-red-600 dark:text-red-400">{fetchError}</p>
        </div>
      )}

      {/* Politician list view */}
      {!loading && !fetchError && !selected && (
        <>
          {politicians.length === 0 ? (
            <div className="rounded-2xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-950 p-6 text-center">
              <p className="text-sm text-gray-500">No politicians found for your jurisdiction.</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {politicians.map((pol) => (
                <div
                  key={pol.id}
                  className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-4"
                >
                  {/* Photo + name */}
                  <div className="flex items-center gap-3">
                    {pol.photo_url ? (
                      <img
                        src={pol.photo_url}
                        alt={pol.full_name ?? 'Politician photo'}
                        className="w-12 h-12 rounded-full object-cover flex-shrink-0 bg-gray-100 dark:bg-gray-800"
                      />
                    ) : (
                      <div className="w-12 h-12 rounded-full flex-shrink-0 bg-ev-teal/10 flex items-center justify-center">
                        <svg className="w-6 h-6 text-ev-teal" fill="none" stroke="currentColor" strokeWidth={1.8} viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                        </svg>
                      </div>
                    )}
                    <div className="min-w-0">
                      <p className="text-sm font-bold text-ev-black dark:text-white truncate">
                        {pol.full_name ?? (`${pol.first_name ?? ''} ${pol.last_name ?? ''}`.trim() || 'Unknown')}
                      </p>
                      <p className="text-xs text-gray-500 truncate">{pol.office_title}</p>
                    </div>
                  </div>

                  <button
                    onClick={() => handleSelect(pol)}
                    className="w-full py-2 rounded-xl text-sm font-semibold bg-ev-teal text-white hover:bg-ev-teal/90 transition-colors"
                  >
                    Edit Details
                  </button>
                </div>
              ))}
            </div>
          )}
        </>
      )}

      {/* Field editor view */}
      {!loading && selected && (
        <div className="space-y-6">
          {/* Sub-header */}
          <div className="flex items-center gap-3">
            <button
              onClick={handleBack}
              className="flex items-center gap-1.5 text-sm text-ev-teal hover:text-ev-teal/80 font-medium transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
              </svg>
              Back to list
            </button>
            <span className="text-gray-300 dark:text-gray-600">|</span>
            <p className="text-sm font-semibold text-ev-black dark:text-white truncate">
              {selected.full_name ?? (`${selected.first_name ?? ''} ${selected.last_name ?? ''}`.trim() || 'Politician')}
            </p>
          </div>

          {/* Editor card */}
          <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-5">
            <h2 className="text-base font-bold text-ev-black dark:text-white">Edit Biographical Info</h2>

            {/* Preferred Name */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Preferred Name
              </label>
              <input
                type="text"
                className={inputClass}
                placeholder="e.g. Mike (leave blank to keep current)"
                value={preferredName}
                onChange={(e) => setPreferredName(e.target.value)}
              />
            </div>

            {/* Bio */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Bio
              </label>
              <textarea
                className={`${inputClass} min-h-[100px] resize-y`}
                placeholder="Short biography for the candidate profile (leave blank to keep current)"
                value={bio}
                onChange={(e) => setBio(e.target.value)}
              />
            </div>

            {/* Photo URL */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Photo URL
              </label>
              <input
                type="url"
                className={inputClass}
                placeholder="https://example.com/photo.jpg (leave blank to keep current)"
                value={photoUrl}
                onChange={(e) => setPhotoUrl(e.target.value)}
              />
            </div>

            {/* Save button */}
            <button
              onClick={handleSave}
              disabled={saving}
              className="w-full py-2.5 rounded-xl text-sm font-semibold bg-ev-teal text-white hover:bg-ev-teal/90 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      )}

      {/* Toast */}
      {showToast && (
        <div
          className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-opacity ${
            toastError
              ? 'bg-red-600 text-white'
              : 'bg-gray-900 text-white'
          }`}
        >
          {toastMessage}
        </div>
      )}
    </div>
  );
}
