import type { ReactNode } from 'react';

interface SecondaryButtonProps {
  children: ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
  disabled?: boolean;
  className?: string;
}

export function SecondaryButton({
  children,
  onClick,
  type = 'button',
  disabled = false,
  className = '',
}: SecondaryButtonProps) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`w-full bg-gray-800 text-white border border-gray-700 rounded-xl py-3 font-bold text-base hover:bg-gray-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors ${className}`.trim()}
    >
      {children}
    </button>
  );
}
