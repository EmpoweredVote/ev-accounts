import type { ReactNode } from 'react';

interface PrimaryButtonProps {
  children: ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
  disabled?: boolean;
  className?: string;
}

export function PrimaryButton({
  children,
  onClick,
  type = 'button',
  disabled = false,
  className = '',
}: PrimaryButtonProps) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`w-full bg-ev-blue text-white rounded-xl py-3 font-bold text-base hover:bg-ev-blue/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors ${className}`.trim()}
    >
      {children}
    </button>
  );
}
