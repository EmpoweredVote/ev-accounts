import type { ReactNode } from 'react';

interface AuthCardProps {
  children: ReactNode;
  className?: string;
}

export function AuthCard({ children, className = '' }: AuthCardProps) {
  return (
    <div
      className={`bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5 ${className}`.trim()}
    >
      {children}
    </div>
  );
}
