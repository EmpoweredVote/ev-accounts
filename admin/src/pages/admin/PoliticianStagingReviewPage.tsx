import { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate, Link } from 'react-router';
import { apiFetch } from '../../lib/api';

// ── Constants ─────────────────────────────────────────────────────────────────

const PARTIES = ['Democrat', 'Republican', 'Independent', 'Libertarian', 'Green', 'Unknown'];

const OFFICE_LEVELS = [
  { value: 'federal', label: 'Federal' },
  { value: 'state', label: 'State' },
  { value: 'municipal', label: 'Municipal' },
  { value: 'school_district', label: 'School District' },
];

const STATES = [
  { value: 'AL', label: 'Alabama' }, { value: 'AK', label: 'Alaska' },
  { value: 'AZ', label: 'Arizona' }, { value: 'AR', label: 'Arkansas' },
  { value: 'CA', label: 'California' }, { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' }, { value: 'DE', label: 'Delaware' },
  { value: 'FL', label: 'Florida' }, { value: 'GA', label: 'Georgia' },
  { value: 'HI', label: 'Hawaii' }, { value: 'ID', label: 'Idaho' },
  { value: 'IL', label: 'Illinois' }, { value: 'IN', label: 'Indiana' },
  { value: 'IA', label: 'Iowa' }, { value: 'KS', label: 'Kansas' },
  { value: 'KY', label: 'Kentucky' }, { value: 'LA', label: 'Louisiana' },
  { value: 'ME', label: 'Maine' }, { value: 'MD', label: 'Maryland' },
  { value: 'MA', label: 'Massachusetts' }, { value: 'MI', label: 'Michigan' },
  { value: 'MN', label: 'Minnesota' }, { value: 'MS', label: 'Mississippi' },
  { value: 'MO', label: 'Missouri' }, { value: 'MT', label: 'Montana' },
  { value: 'NE', label: 'Nebraska' }, { value: 'NV', label: 'Nevada' },
  { value: 'NH', label: 'New Hampshire' }, { value: 'NJ', label: 'New Jersey' },
  { value: 'NM', label: 'New Mexico' }, { value: 'NY', label: 'New York' },
  { value: 'NC', label: 'North Carolina' }, { value: 'ND', label: 'North Dakota' },
  { value: 'OH', label: 'Ohio' }, { value: 'OK', label: 'Oklahoma' },
  { value: 'OR', label: 'Oregon' }, { value: 'PA', label: 'Pennsylvania' },
  { value: 'RI', label: 'Rhode Island' }, { value: 'SC', label: 'South Carolina' },
  { value: 'SD', label: 'South Dakota' }, { value: 'TN', label: 'Tennessee' },
  { value: 'TX', label: 'Texas' }, { value: 'UT', label: 'Utah' },
  { value: 'VT', label: 'Vermont' }, { value: 'VA', label: 'Virginia' },
  { value: 'WA', label: 'Washington' }, { value: 'WV', label: 'West Virginia' },
  { value: 'WI', label: 'Wisconsin' }, { value: 'WY', label: 'Wyoming' },
  { value: 'DC', label: 'District of Columbia' },
];

const CONTACT_TYPES = ['phone', 'email', 'website', 'fax', 'twitter', 'facebook', 'instagram'];
const EXPERIENCE_TYPES = ['work', 'office', 'military', 'other'];

const OFFICE_LEVEL_LABELS: Record<string, string> = {
  federal: 'Federal', state: 'State', local: 'Local',
  municipal: 'Municipal', school_district: 'School District',
};

// ── Types ─────────────────────────────────────────────────────────────────────

interface ContactEntry { type: string; value: string; source?: string }
interface DegreeEntry { degree: string; major?: string; school: string; grad_year?: string }
interface ExperienceEntry { title: string; organization: string; type?: string; start?: string; end?: string }

interface StagingPolitician {
  id: string;
  fullName: string;
  party: string;
  office: string;
  officeLevel: string;
  state: string;
  district: string;
  bioText?: string;
  photoUrl?: string;
  contacts?: ContactEntry[];
  degrees?: DegreeEntry[];
  experiences?: ExperienceEntry[];
  status: string;
  addedBy: string;
  reviewCount: number;
  reviewedBy: string[];
  createdAt: string;
  lockedBy: string | null;
  lockedAt: string | null;
}

type Mode = 'view' | 'edit' | 'reject';

// ── Field components ──────────────────────────────────────────────────────────

function Field({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null;
  return (
    <div>
      <span className="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">
        {label}
      </span>
      <p className="text-sm text-gray-700 dark:text-gray-300 mt-0.5">{value}</p>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="space-y-3">
      <p className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider border-b border-gray-100 dark:border-gray-800 pb-1">
        {title}
      </p>
      {children}
    </div>
  );
}

// ── Main component ────────────────────────────────────────────────────────────

export function PoliticianStagingReviewPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [politician, setPolitician] = useState<StagingPolitician | null>(null);
  const [lockAcquired, setLockAcquired] = useState(false);
  const [lockConflict, setLockConflict] = useState<{ lockedBy: string; lockedAt: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mode, setMode] = useState<Mode>('view');
  const [rejectComment, setRejectComment] = useState('');

  const [fullName, setFullName] = useState('');
  const [party, setParty] = useState('');
  const [office, setOffice] = useState('');
  const [officeLevel, setOfficeLevel] = useState('');
  const [state, setState] = useState('');
  const [district, setDistrict] = useState('');
  const [bioText, setBioText] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [contacts, setContacts] = useState<ContactEntry[]>([]);
  const [degrees, setDegrees] = useState<DegreeEntry[]>([]);
  const [experiences, setExperiences] = useState<ExperienceEntry[]>([]);

  const releaseLock = useCallback(() => {
    if (lockAcquired && id) {
      apiFetch(`/staging/politicians/${id}/lock`, { method: 'DELETE' }).catch(() => {});
    }
  }, [lockAcquired, id]);

  useEffect(() => {
    return () => { releaseLock(); };
  }, [releaseLock]);

  useEffect(() => {
    if (id) load();
  }, [id]);

  function populateForm(p: StagingPolitician) {
    setFullName(p.fullName ?? '');
    setParty(p.party ?? '');
    setOffice(p.office ?? '');
    setOfficeLevel(p.officeLevel ?? '');
    setState(p.state ?? '');
    setDistrict(p.district ?? '');
    setBioText(p.bioText ?? '');
    setPhotoUrl(p.photoUrl ?? '');
    setContacts(Array.isArray(p.contacts) ? p.contacts : []);
    setDegrees(Array.isArray(p.degrees) ? p.degrees : []);
    setExperiences(Array.isArray(p.experiences) ? p.experiences : []);
  }

  async function takeover() {
    if (!id) return;
    try {
      await apiFetch(`/staging/politicians/${id}/lock`, { method: 'DELETE' });
      await apiFetch(`/staging/politicians/${id}/lock`, { method: 'POST' });
      setLockConflict(null);
      setLockAcquired(true);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to take over lock');
    }
  }

  async function load() {
    setLoading(true);
    setError(null);
    setLockConflict(null);
    try {
      const data = await apiFetch<StagingPolitician>(`/staging/politicians/${id}`);
      setPolitician(data);
      populateForm(data);

      try {
        await apiFetch(`/staging/politicians/${id}/lock`, { method: 'POST' });
        setLockAcquired(true);
      } catch {
        if (data.lockedBy) {
          setLockConflict({ lockedBy: data.lockedBy, lockedAt: data.lockedAt ?? '' });
        } else {
          setError('Could not acquire lock — record may be open elsewhere');
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load politician');
    } finally {
      setLoading(false);
    }
  }

  async function handleApprove() {
    if (!id) return;
    setSaving(true);
    setError(null);
    try {
      await apiFetch(`/staging/politicians/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'approve' }),
      });
      setLockAcquired(false);
      navigate('/admin/review?tab=politicians');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to approve');
      setSaving(false);
    }
  }

  async function handleReject() {
    if (!id) return;
    setSaving(true);
    setError(null);
    try {
      await apiFetch(`/staging/politicians/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'reject', comment: rejectComment || undefined }),
      });
      setLockAcquired(false);
      navigate('/admin/review?tab=politicians');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to reject');
      setSaving(false);
    }
  }

  async function handleEditAndApprove() {
    if (!id || !fullName.trim() || !office || !state) return;
    setSaving(true);
    setError(null);
    try {
      const validContacts = contacts.filter((c) => c.value?.trim());
      const validDegrees = degrees.filter((d) => d.school?.trim() || d.degree?.trim());
      const validExperiences = experiences.filter((e) => e.title?.trim() || e.organization?.trim());

      await apiFetch(`/staging/politicians/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          full_name: fullName.trim(),
          party: party || undefined,
          office,
          office_level: officeLevel || undefined,
          state,
          district: district.trim() || undefined,
          bio_text: bioText.trim() || undefined,
          photo_url: photoUrl.trim() || undefined,
          contacts: validContacts.length > 0 ? validContacts : undefined,
          degrees: validDegrees.length > 0 ? validDegrees : undefined,
          experiences: validExperiences.length > 0 ? validExperiences : undefined,
        }),
      });
      await apiFetch(`/staging/politicians/${id}/review`, {
        method: 'POST',
        body: JSON.stringify({ action: 'approve' }),
      });
      setLockAcquired(false);
      navigate('/admin/review?tab=politicians');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save and approve');
      setSaving(false);
    }
  }

  const addContact = () => setContacts([...contacts, { type: 'phone', value: '' }]);
  const removeContact = (i: number) => setContacts(contacts.filter((_, idx) => idx !== i));
  const updateContact = (i: number, field: keyof ContactEntry, val: string) => {
    const updated = [...contacts];
    updated[i] = { ...updated[i], [field]: val };
    setContacts(updated);
  };

  const addDegree = () => setDegrees([...degrees, { degree: '', school: '' }]);
  const removeDegree = (i: number) => setDegrees(degrees.filter((_, idx) => idx !== i));
  const updateDegree = (i: number, field: keyof DegreeEntry, val: string) => {
    const updated = [...degrees];
    updated[i] = { ...updated[i], [field]: val };
    setDegrees(updated);
  };

  const addExperience = () =>
    setExperiences([...experiences, { title: '', organization: '', type: 'work' }]);
  const removeExperience = (i: number) => setExperiences(experiences.filter((_, idx) => idx !== i));
  const updateExperience = (i: number, field: keyof ExperienceEntry, val: string) => {
    const updated = [...experiences];
    updated[i] = { ...updated[i], [field]: val };
    setExperiences(updated);
  };

  const inputCls =
    'w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-red';
  const selectCls =
    'w-full px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-ev-red';

  if (loading) return <p className="text-sm text-gray-500 dark:text-gray-400">Loading...</p>;

  if (!politician) {
    return (
      <div>
        <p className="text-sm text-red-600 dark:text-red-400">{error ?? 'Politician not found'}</p>
        <Link to="/admin/review?tab=politicians" className="mt-2 text-sm text-gray-500 underline">
          Back to queue
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-2xl">
      <div className="mb-6">
        <Link
          to="/admin/review?tab=politicians"
          className="text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white transition-colors"
        >
          ← Review Queue
        </Link>
        <h1 className="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
          {politician.fullName}
        </h1>
        <p className="text-gray-500 dark:text-gray-400 text-sm">
          {politician.office}
          {politician.state ? ` — ${politician.state}` : ''}
        </p>
      </div>

      {lockConflict && (
        <div className="mb-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300 rounded-md text-sm flex items-center justify-between gap-4">
          <span>
            Locked by <strong>{lockConflict.lockedBy}</strong>
            {lockConflict.lockedAt && (
              <> since {new Date(lockConflict.lockedAt).toLocaleTimeString()}</>
            )}
          </span>
          <button
            onClick={takeover}
            className="shrink-0 px-3 py-1 bg-yellow-100 hover:bg-yellow-200 dark:bg-yellow-800/40 dark:hover:bg-yellow-800/60 text-yellow-900 dark:text-yellow-200 text-xs font-medium rounded transition-colors"
          >
            Take over
          </button>
        </div>
      )}

      {error && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 rounded-md text-sm">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-6 space-y-5">
        <div className="flex gap-4 text-sm text-gray-500 dark:text-gray-400 pb-4 border-b border-gray-100 dark:border-gray-800">
          <span>
            Added by{' '}
            <strong className="text-gray-700 dark:text-gray-300">{politician.addedBy}</strong>
          </span>
          {politician.reviewCount > 0 && <span>{politician.reviewCount}/2 approvals</span>}
          {politician.reviewedBy?.length > 0 && (
            <span>Reviewed by: {politician.reviewedBy.join(', ')}</span>
          )}
        </div>

        {mode === 'view' && (
          <>
            <Section title="Core Info">
              <Field label="Full Name" value={politician.fullName} />
              <Field label="Party" value={politician.party || 'Not specified'} />
              <Field label="Office" value={politician.office} />
              <Field
                label="Level"
                value={OFFICE_LEVEL_LABELS[politician.officeLevel] ?? politician.officeLevel}
              />
              <Field label="State" value={politician.state} />
              {politician.district && <Field label="District" value={politician.district} />}
            </Section>

            {(politician.bioText || politician.photoUrl) && (
              <Section title="Bio & Photo">
                {politician.photoUrl && (
                  <img
                    src={politician.photoUrl}
                    alt={politician.fullName}
                    className="w-20 h-20 rounded-md object-cover"
                  />
                )}
                {politician.bioText && (
                  <p className="text-sm text-gray-700 dark:text-gray-300">{politician.bioText}</p>
                )}
              </Section>
            )}

            {politician.contacts && politician.contacts.length > 0 && (
              <Section title="Contacts">
                {politician.contacts.map((c, i) => (
                  <div key={i} className="text-sm text-gray-700 dark:text-gray-300">
                    <span className="font-medium capitalize">{c.type}:</span> {c.value}
                  </div>
                ))}
              </Section>
            )}

            {politician.degrees && politician.degrees.length > 0 && (
              <Section title="Education">
                {politician.degrees.map((d, i) => (
                  <p key={i} className="text-sm text-gray-700 dark:text-gray-300">
                    {d.degree}
                    {d.major ? ` in ${d.major}` : ''}
                    {d.school ? ` — ${d.school}` : ''}
                    {d.grad_year ? ` (${d.grad_year})` : ''}
                  </p>
                ))}
              </Section>
            )}

            {politician.experiences && politician.experiences.length > 0 && (
              <Section title="Experience">
                {politician.experiences.map((exp, i) => (
                  <p key={i} className="text-sm text-gray-700 dark:text-gray-300">
                    <strong>{exp.title}</strong>
                    {exp.organization ? ` at ${exp.organization}` : ''}
                    {(exp.start || exp.end) && (
                      <span className="text-gray-500"> ({exp.start ?? '?'} – {exp.end ?? 'present'})</span>
                    )}
                  </p>
                ))}
              </Section>
            )}

            <div className="flex gap-3 pt-2">
              <button
                onClick={handleApprove}
                disabled={saving || !lockAcquired}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Saving...' : 'Approve'}
              </button>
              <button
                onClick={() => setMode('edit')}
                disabled={!lockAcquired}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 disabled:opacity-40 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Edit & Approve
              </button>
              <button
                onClick={() => setMode('reject')}
                disabled={!lockAcquired}
                className="px-4 py-2 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:hover:bg-red-900/40 disabled:opacity-40 text-red-700 dark:text-red-400 text-sm font-medium rounded-md transition-colors"
              >
                Reject
              </button>
            </div>
          </>
        )}

        {mode === 'reject' && (
          <>
            <div>
              <label className="block text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-1">
                Reason (optional)
              </label>
              <textarea
                value={rejectComment}
                onChange={(e) => setRejectComment(e.target.value)}
                rows={3}
                placeholder="Explain why this politician entry is being rejected..."
                className={inputCls + ' resize-y'}
              />
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setMode('view')}
                disabled={saving}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={saving}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Rejecting...' : 'Confirm Reject'}
              </button>
            </div>
          </>
        )}

        {mode === 'edit' && (
          <div className="space-y-4">
            <p className="text-xs text-gray-500 dark:text-gray-400 italic">
              Editing will update the record and approve it in one step.
            </p>

            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Full Name *</label>
                <input type="text" value={fullName} onChange={(e) => setFullName(e.target.value)} className={inputCls} />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Party</label>
                <select value={party} onChange={(e) => setParty(e.target.value)} className={selectCls}>
                  <option value="">Select...</option>
                  {PARTIES.map((p) => <option key={p} value={p}>{p}</option>)}
                  <option value="Other">Other</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Office Level</label>
                <select value={officeLevel} onChange={(e) => setOfficeLevel(e.target.value)} className={selectCls}>
                  <option value="">Select...</option>
                  {OFFICE_LEVELS.map((l) => <option key={l.value} value={l.value}>{l.label}</option>)}
                </select>
              </div>

              <div className="col-span-2">
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Office *</label>
                <input type="text" value={office} onChange={(e) => setOffice(e.target.value)} className={inputCls} />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">State *</label>
                <select value={state} onChange={(e) => setState(e.target.value)} className={selectCls}>
                  <option value="">Select...</option>
                  {STATES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">District</label>
                <input type="text" value={district} onChange={(e) => setDistrict(e.target.value)} className={inputCls} />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Biography</label>
              <textarea value={bioText} onChange={(e) => setBioText(e.target.value)} rows={3} className={inputCls + ' resize-y'} />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-1">Photo URL</label>
              <input type="url" value={photoUrl} onChange={(e) => setPhotoUrl(e.target.value)} className={inputCls} />
            </div>

            <div>
              <p className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider border-b border-gray-100 dark:border-gray-800 pb-1 mb-2">Contacts</p>
              {contacts.map((c, i) => (
                <div key={i} className="flex gap-2 mb-2">
                  <select value={c.type} onChange={(e) => updateContact(i, 'type', e.target.value)} className="w-28 px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs">
                    {CONTACT_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                  <input type="text" value={c.value} onChange={(e) => updateContact(i, 'value', e.target.value)} placeholder="Value" className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-sm" />
                  <button onClick={() => removeContact(i)} className="text-gray-400 hover:text-red-500 px-1 text-lg leading-none">×</button>
                </div>
              ))}
              <button onClick={addContact} className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">+ Add contact</button>
            </div>

            <div>
              <p className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider border-b border-gray-100 dark:border-gray-800 pb-1 mb-2">Education</p>
              {degrees.map((d, i) => (
                <div key={i} className="grid grid-cols-4 gap-2 mb-2">
                  <input placeholder="Degree" value={d.degree} onChange={(e) => updateDegree(i, 'degree', e.target.value)} className="px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                  <input placeholder="Major" value={d.major ?? ''} onChange={(e) => updateDegree(i, 'major', e.target.value)} className="px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                  <input placeholder="School" value={d.school} onChange={(e) => updateDegree(i, 'school', e.target.value)} className="px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                  <div className="flex gap-1">
                    <input placeholder="Year" value={d.grad_year ?? ''} onChange={(e) => updateDegree(i, 'grad_year', e.target.value)} className="w-full px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                    <button onClick={() => removeDegree(i)} className="text-gray-400 hover:text-red-500 px-1 text-lg leading-none">×</button>
                  </div>
                </div>
              ))}
              <button onClick={addDegree} className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">+ Add degree</button>
            </div>

            <div>
              <p className="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider border-b border-gray-100 dark:border-gray-800 pb-1 mb-2">Experience</p>
              {experiences.map((exp, i) => (
                <div key={i} className="grid grid-cols-5 gap-2 mb-2">
                  <input placeholder="Title" value={exp.title} onChange={(e) => updateExperience(i, 'title', e.target.value)} className="col-span-2 px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                  <input placeholder="Organization" value={exp.organization} onChange={(e) => updateExperience(i, 'organization', e.target.value)} className="col-span-2 px-2 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs" />
                  <div className="flex gap-1">
                    <select value={exp.type ?? 'work'} onChange={(e) => updateExperience(i, 'type', e.target.value)} className="w-full px-1 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-xs">
                      {EXPERIENCE_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
                    </select>
                    <button onClick={() => removeExperience(i)} className="text-gray-400 hover:text-red-500 px-1 text-lg leading-none">×</button>
                  </div>
                </div>
              ))}
              <button onClick={addExperience} className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">+ Add experience</button>
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => { setMode('view'); if (politician) populateForm(politician); }}
                disabled={saving}
                className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 text-sm font-medium rounded-md transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleEditAndApprove}
                disabled={saving || !fullName.trim() || !office || !state}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-40 text-white text-sm font-medium rounded-md transition-colors"
              >
                {saving ? 'Saving...' : 'Save & Approve'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
