/**
 * FederalDelegationPanel — per-member federal + state-office roster for one
 * state, shown when a state is selected in the Federal lens (any of the 56 —
 * no coverage YAML required) and, in Local mode, for untracked states where the
 * YAML tracker table has nothing to show.
 *
 * Non-voting / committee-only seats MUST render their representation_note with
 * the seat (ADR 0003) — the note is the explanation that keeps a tribal or
 * territorial seat from reading as an ordinary one.
 */
import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../../lib/api';
import { Bool } from './coverageCells';
import type { FederalMember, FederalTier } from './coverageTypes';

const TIER_LABEL: Record<FederalTier, string> = {
  senate: 'U.S. Senate',
  house: 'U.S. House',
  governor: 'Governor',
  statewide: 'Statewide officials',
  stateleg: 'State legislature',
  candidate: 'Tracked candidates (not officeholders)',
};
const TIER_ORDER: FederalTier[] = ['senate', 'house', 'governor', 'statewide', 'stateleg', 'candidate'];
// Big sections start collapsed — Utah's legislature alone is 104 rows.
const COLLAPSED_BY_DEFAULT = new Set<FederalTier>(['stateleg', 'candidate']);

/** '/cd:12' → 'CD-12', '/sldu:5' → 'SD-5', '/sldl:10' → 'HD-10', bare state → 'Statewide'. */
function districtLabel(ocd: string): string {
  const m = ocd.match(/\/(cd|sldu|sldl):([^/]+)$/);
  if (!m) return 'Statewide';
  const prefix = m[1] === 'cd' ? 'CD' : m[1] === 'sldu' ? 'SD' : 'HD';
  return `${prefix}-${m[2].toUpperCase()}`;
}

function MemberRow({ m }: { m: FederalMember }) {
  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800/40">
      <td className="px-3 py-2">
        <div className="font-medium text-gray-900 dark:text-white">{m.full_name}</div>
        {m.voting_powers !== 'full' && (
          <div className="mt-0.5 max-w-md text-[11px] leading-snug text-amber-700 dark:text-amber-400">
            <span className="mr-1 rounded bg-amber-100 px-1 py-px font-medium dark:bg-amber-900/40">
              {m.voting_powers === 'non_voting' ? 'non-voting' : 'committee-only'}
            </span>
            {m.representation_note}
          </div>
        )}
      </td>
      <td className="px-3 py-2 text-gray-600 dark:text-gray-400">{m.title ?? '—'}</td>
      <td className="px-3 py-2 text-xs text-gray-500 dark:text-gray-400">{districtLabel(m.district_ocd)}</td>
      <td className="px-3 py-2"><Bool value={m.has_photo} /></td>
      <td className="px-3 py-2"><Bool value={m.researched} /></td>
      <td className="px-3 py-2"><Bool value={m.has_donors} /></td>
    </tr>
  );
}

function TierSection({ tier, members }: { tier: FederalTier; members: FederalMember[] }) {
  const [open, setOpen] = useState(!COLLAPSED_BY_DEFAULT.has(tier));
  const researched = members.filter((m) => m.researched).length;
  return (
    <>
      <tr className="bg-gray-50/70 dark:bg-gray-800/40">
        <td colSpan={6} className="px-3 py-1.5">
          <button
            onClick={() => setOpen((o) => !o)}
            className="flex w-full items-center justify-between text-xs font-semibold uppercase tracking-wide text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
          >
            <span>
              {TIER_LABEL[tier]} <span className="font-normal normal-case">({members.length})</span>
            </span>
            <span className="font-normal normal-case tabular-nums">
              {researched}/{members.length} researched {open ? '▾' : '▸'}
            </span>
          </button>
        </td>
      </tr>
      {open && members.map((m) => <MemberRow key={`${m.politician_id}-${m.district_ocd}-${m.title}`} m={m} />)}
    </>
  );
}

interface Props {
  stateCode: string; // 2-letter lowercase
  stateName: string;
}

export function FederalDelegationPanel({ stateCode, stateName }: Props) {
  const [members, setMembers] = useState<FederalMember[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setMembers(null);
    setError(null);
    apiFetch<{ members: FederalMember[] }>(`/admin/coverage/federal?state=${stateCode}`)
      .then((res) => { if (!cancelled) setMembers(res.members); })
      .catch((err) => { if (!cancelled) setError(err.message); });
    return () => { cancelled = true; };
  }, [stateCode]);

  const byTier = useMemo(() => {
    const map = new Map<FederalTier, FederalMember[]>();
    for (const m of members ?? []) {
      const arr = map.get(m.tier) ?? [];
      arr.push(m);
      map.set(m.tier, arr);
    }
    return map;
  }, [members]);

  if (error) {
    return (
      <div className="rounded border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800/60 dark:bg-red-950/40 dark:text-red-400">
        {error}
      </div>
    );
  }
  if (members === null) {
    return (
      <div className="flex items-center gap-3 rounded-lg bg-white px-4 py-3 shadow dark:bg-gray-900">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-ev-teal dark:border-gray-600 dark:border-t-ev-teal-light" />
        <p className="text-sm text-gray-500 dark:text-gray-400">Loading {stateName} officials…</p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-900">
      <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-gray-800">
        <h2 className="text-sm font-semibold text-gray-900 dark:text-white">
          {stateName} — federal &amp; state officials{' '}
          <span className="font-normal text-gray-400">({members.length})</span>
        </h2>
        <span className="text-xs text-gray-400">✓ = has photo / stances researched / donor data</span>
      </div>
      {members.length === 0 ? (
        <p className="px-4 py-6 text-center text-sm text-gray-400">No federal or state officials loaded.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800">
              <tr>
                {['Name', 'Office', 'District', 'Photo', 'Stances', 'Donors'].map((h) => (
                  <th key={h} className="whitespace-nowrap px-3 py-2 text-left font-medium text-gray-500 dark:text-gray-400">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {TIER_ORDER.filter((t) => byTier.has(t)).map((tier) => (
                <TierSection key={tier} tier={tier} members={byTier.get(tier)!} />
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
