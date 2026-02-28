import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../store/authStore';

const navItems = [
  { label: 'Dashboard', to: '/admin', exact: true },
  { label: 'Accounts', to: '/admin/accounts' },
  { label: 'Invites', to: '/admin/invites' },
  { label: 'Invite Tree', to: '/admin/invites/tree' },
  { label: 'Cron Log', to: '/admin/cron-log' },
  { label: 'Roles', to: '/admin/roles' },
];

export function AdminLayout() {
  const navigate = useNavigate();
  const { clearAuth } = useAuthStore();

  function handleLogout() {
    sessionStorage.removeItem('admin_token');
    clearAuth();
    navigate('/login');
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-ev-red flex flex-col">
        <div className="px-6 py-4 border-b border-white/20">
          <h1 className="text-lg font-bold text-white">Admin</h1>
          <p className="text-xs text-white/60 mt-0.5">Empowered Accounts</p>
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
                    ? 'bg-black/25 text-white'
                    : 'text-white/80 hover:bg-black/15 hover:text-white'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-white/20">
          <button
            onClick={handleLogout}
            className="w-full px-3 py-2 text-sm font-medium text-white/80 hover:bg-black/15 hover:text-white rounded-md text-left transition-colors"
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
