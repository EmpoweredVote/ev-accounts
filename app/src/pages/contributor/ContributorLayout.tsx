import { Link, Outlet } from 'react-router';

export default function ContributorLayout() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-ev-black">
      {/* Back navigation header */}
      <header className="bg-white dark:bg-gray-950 border-b border-gray-100 dark:border-gray-800 sticky top-0 z-10">
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center gap-3">
          <Link
            to="/"
            className="flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-ev-teal transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
            Back to Profile
          </Link>
        </div>
      </header>

      <Outlet />
    </div>
  );
}
