import { NavLink, Outlet, useNavigate } from 'react-router';
import { useAuthStore } from '../../store/authStore';
import { workosSignOut } from '../../lib/workosAuth';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

const navItems = [
  { label: 'Dashboard', to: '/admin', exact: true },
  { label: 'Accounts', to: '/admin/accounts' },
  { label: 'Promotions', to: '/admin/promotions' },
  { label: 'Invites', to: '/admin/invites' },
  { label: 'Invite Tree', to: '/admin/invites/tree' },
  { label: 'Invite Overrides', to: '/admin/invite-overrides' },
  { label: 'Access Requests', to: '/admin/access-requests' },
  { label: 'Cron Log', to: '/admin/cron-log' },
  { label: 'Roles', to: '/admin/roles' },
  { label: 'Role Audit', to: '/admin/role-audit' },
  { label: 'Topics', to: '/admin/topics' },
  { label: 'Seasons', to: '/admin/seasons' },
  { label: 'Stance Breakdown', to: '/admin/stance-breakdown' },
  { label: 'Politicians', to: '/admin/politicians' },
  { label: 'Categories', to: '/admin/categories' },
  { label: 'Coverage', to: '/admin/coverage', exact: true },
  { label: 'Review Queue', to: '/admin/review' },
  { label: 'Evidence Review', to: '/admin/review/evidence' },
  { label: 'Read & Rank Quotes', to: '/admin/readrank-quotes' },
  { label: 'Read & Rank Coverage', to: '/admin/readrank-coverage' },
];

export function AdminLayout() {
  const navigate = useNavigate();
  const { clearAuth } = useAuthStore();

  async function handleLogout() {
    const token = useAuthStore.getState().accessToken;
    // Mirrors ProfilePage.tsx's handleSignOut: end the session server-side
    // (credentials: 'include' so the ev_wos_session/ev_wos_pending cookies are
    // cleared too — see backend/src/routes/auth.ts POST /auth/logout) and end
    // the WorkOS SDK session when this login came through AuthKit. Without
    // the backend call, the 30-day ev_wos_session cookie survives and
    // App.tsx's embedded-auth bootstrap silently restores the session on the
    // next load. Resilient: local state is cleared and we navigate away even
    // if either call fails.
    try {
      await fetch(`${API_BASE}/auth/logout`, {
        method: 'POST',
        credentials: 'include',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
    } catch { /* ignore */ }
    try { await workosSignOut(); } catch { /* ignore */ }
    clearAuth();
    sessionStorage.removeItem('admin_token');
    navigate('/login');
  }

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-950">
      {/* Sidebar */}
      <aside className="w-64 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-700 flex flex-col">
        <div className="px-6 py-4 bg-ev-black">
          <img src="/logo.png" alt="Empowered Vote" className="h-8 w-auto mb-2" />
          <p className="text-xs text-white/70">Empowered Accounts Admin</p>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.exact}
              className={({ isActive }) =>
                `block px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-red-50 text-ev-red dark:bg-ev-red/10'
                    : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-gray-200 dark:border-gray-700">
          <button
            onClick={handleLogout}
            className="w-full px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white rounded-md text-left transition-colors"
          >
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        <div className="p-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
