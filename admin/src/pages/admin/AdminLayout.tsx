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
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="px-6 py-4 border-b border-gray-200">
          <h1 className="text-lg font-bold text-gray-900">Admin</h1>
          <p className="text-xs text-gray-500 mt-0.5">Empowered Accounts</p>
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
                    ? 'bg-blue-50 text-blue-700'
                    : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-gray-200">
          <button
            onClick={handleLogout}
            className="w-full px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-md text-left transition-colors"
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
