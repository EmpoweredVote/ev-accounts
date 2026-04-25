import type { InputHTMLAttributes } from 'react';

interface AuthInputProps {
  label: string;
  type?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  autoComplete?: string;
  required?: boolean;
  autoFocus?: boolean;
  inputProps?: Omit<
    InputHTMLAttributes<HTMLInputElement>,
    'type' | 'value' | 'onChange' | 'placeholder' | 'autoComplete' | 'required' | 'autoFocus'
  >;
  inputClassName?: string;
}

export function AuthInput({
  label,
  type = 'text',
  value,
  onChange,
  placeholder,
  error,
  autoComplete,
  required,
  autoFocus,
  inputProps,
  inputClassName = '',
}: AuthInputProps) {
  const borderClass = error
    ? 'border-ev-red focus:ring-ev-red'
    : 'border-gray-700 focus:ring-ev-blue';

  return (
    <div>
      <label className="block text-sm font-medium text-gray-300 mb-1.5">{label}</label>
      <input
        {...inputProps}
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete={autoComplete}
        required={required}
        autoFocus={autoFocus}
        className={`w-full bg-gray-800 border ${borderClass} rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 text-base ${inputClassName}`.trim()}
      />
      {error && <p className="mt-1.5 text-ev-red text-sm">{error}</p>}
    </div>
  );
}
