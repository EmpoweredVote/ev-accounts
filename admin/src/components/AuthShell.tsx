import type { ReactNode } from 'react';

interface AuthShellProps {
  /** Optional tier/context badge shown centered above the heading (e.g. the Inform pill). */
  badge?: ReactNode;
  /** Card title, e.g. "Log in" or "Enter your code". Omit for none. */
  heading?: string;
  /** Optional short line under the heading (e.g. reset instructions). */
  subheading?: ReactNode;
  /** Card max-width. Default 'sm'; signup forms use 'md'. */
  width?: 'sm' | 'md';
  children: ReactNode;
}

/**
 * Shared chrome for every auth page (login, signup, password reset, etc.):
 * the brand-tinted background, the centered card with a teal→coral top accent,
 * and the theme-aware Empowered Vote logo. Presentational only — pages own all
 * form state, handlers, and links and pass them as `children`.
 */
export default function AuthShell({ badge, heading, subheading, width = 'sm', children }: AuthShellProps) {
  return (
    <div className="auth-bg min-h-screen flex items-center justify-center px-4 py-12">
      <div
        className={`relative w-full ${width === 'md' ? 'max-w-md' : 'max-w-sm'} overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-8 shadow-[0_12px_40px_-12px_rgba(0,101,124,0.18),0_2px_8px_rgba(16,24,40,0.04)] dark:shadow-[0_16px_48px_-16px_rgba(0,0,0,0.6)]`}
      >
        {/* teal→coral accent, echoing the two logo colors */}
        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-ev-teal to-ev-red dark:from-ev-teal-light dark:to-ev-red" />

        {/* theme-aware logo: dark-teal lockup on light, lighter-teal on dark */}
        <div className="flex justify-center mb-6">
          <img
            src="/Empowered_Vote_Logo_2026.png"
            alt="Empowered Vote"
            className="block dark:hidden h-10 w-auto object-contain"
          />
          <img
            src="/logo.png"
            alt="Empowered Vote"
            className="hidden dark:block h-10 w-auto object-contain"
          />
        </div>

        {badge && <div className="flex justify-center mb-3">{badge}</div>}

        {heading && (
          <h1 className="text-xl font-bold tracking-tight text-center text-gray-900 dark:text-white">
            {heading}
          </h1>
        )}
        {subheading && (
          <p className="mt-1.5 text-sm text-center text-gray-500 dark:text-gray-400">
            {subheading}
          </p>
        )}

        <div className={heading || subheading || badge ? 'mt-6' : ''}>{children}</div>
      </div>
    </div>
  );
}
