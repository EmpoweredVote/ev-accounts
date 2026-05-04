import type { ReactNode } from 'react';

interface AppNavProps {
  children?: ReactNode;
}

export function AppNav({ children }: AppNavProps) {
  return (
    <header className="bg-white dark:bg-ev-navy border-b border-gray-200 dark:border-white/10 sticky top-0 z-10">
      <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <a href="https://login.empowered.vote/profile">
            <img
              src="/logo.png"
              alt="Empowered Vote"
              className="h-6 w-auto dark:invert-0 invert"
            />
          </a>
        </div>
        {children && (
          <div className="flex items-center gap-3">
            {children}
          </div>
        )}
      </div>
    </header>
  );
}
