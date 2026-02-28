import { useEffect, useState } from 'react';
import { apiFetch } from '../../lib/api';

interface DashboardStats {
  users_by_tier: {
    inform: number;
    connected: number;
    empowered: number;
  };
  users_by_standing: {
    active: number;
    suspended: number;
  };
  invite_activity: {
    total_codes: number;
    claimed_codes: number;
    pending_codes: number;
  };
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <p className="text-sm font-medium text-gray-500">{label}</p>
      <p className={`text-3xl font-bold mt-1 ${color}`}>{value}</p>
    </div>
  );
}

function SkeletonCard() {
  return (
    <div className="bg-white rounded-lg shadow p-6 animate-pulse">
      <div className="h-4 bg-gray-200 rounded w-24 mb-3"></div>
      <div className="h-8 bg-gray-200 rounded w-16"></div>
    </div>
  );
}

export function AdminDashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<DashboardStats>('/admin/dashboard')
      .then(setStats)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
          {error}
        </div>
      )}

      <div className="mb-6">
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Users by Tier
        </h2>
        <div className="grid grid-cols-3 gap-4">
          {loading ? (
            <>
              <SkeletonCard />
              <SkeletonCard />
              <SkeletonCard />
            </>
          ) : (
            <>
              <StatCard label="Inform" value={stats?.users_by_tier?.inform ?? 0} color="text-gray-600" />
              <StatCard label="Connected" value={stats?.users_by_tier?.connected ?? 0} color="text-blue-600" />
              <StatCard label="Empowered" value={stats?.users_by_tier?.empowered ?? 0} color="text-green-600" />
            </>
          )}
        </div>
      </div>

      <div className="mb-6">
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Users by Standing
        </h2>
        <div className="grid grid-cols-3 gap-4">
          {loading ? (
            <>
              <SkeletonCard />
              <SkeletonCard />
            </>
          ) : (
            <>
              <StatCard label="Active" value={stats?.users_by_standing?.active ?? 0} color="text-green-600" />
              <StatCard label="Suspended" value={stats?.users_by_standing?.suspended ?? 0} color="text-red-600" />
            </>
          )}
        </div>
      </div>

      <div>
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Invite Activity
        </h2>
        <div className="grid grid-cols-3 gap-4">
          {loading ? (
            <>
              <SkeletonCard />
              <SkeletonCard />
              <SkeletonCard />
            </>
          ) : (
            <>
              <StatCard label="Total Codes" value={stats?.invite_activity?.total_codes ?? 0} color="text-gray-900" />
              <StatCard label="Claimed" value={stats?.invite_activity?.claimed_codes ?? 0} color="text-blue-600" />
              <StatCard label="Pending" value={stats?.invite_activity?.pending_codes ?? 0} color="text-yellow-600" />
            </>
          )}
        </div>
      </div>
    </div>
  );
}
