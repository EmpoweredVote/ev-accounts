import { useAuthStore } from '../store/authStore';

export default function DashboardPage() {
  const { user, clearAuth } = useAuthStore();

  return (
    <div className="min-h-screen bg-white dark:bg-ev-black p-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-8">
          <h1 className="text-xl font-bold text-ev-teal">Empowered Vote</h1>
          <button
            onClick={clearAuth}
            className="text-sm text-gray-500 hover:text-ev-red transition-colors"
          >
            Sign out
          </button>
        </div>

        <p className="text-ev-black dark:text-white">
          Welcome{user?.displayName ? `, ${user.displayName}` : ''}. Dashboard coming soon.
        </p>
      </div>
    </div>
  );
}
