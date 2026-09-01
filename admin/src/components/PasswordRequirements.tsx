/**
 * PasswordRequirements — a live checklist shown under a new-password field.
 * Each rule turns green with a checkmark as it is satisfied, so a user knows
 * WHY a password is or isn't accepted instead of only seeing a "too weak" error.
 *
 * NOTE: WorkOS scores password *strength* (zxcvbn-style), not a fixed rule set,
 * so this checklist is guidance, not the authoritative gate — a password that
 * meets every rule here still passes through WorkOS's strength check on submit,
 * and the form surfaces WorkOS's specific message on the rare miss. We do NOT
 * hard-block submit on these rules: a long passphrase can be strong while
 * lacking, say, a symbol, and we must not reject it.
 */

interface Rule {
  label: string;
  test: (pw: string) => boolean;
}

const RULES: Rule[] = [
  { label: 'At least 8 characters', test: (pw) => pw.length >= 8 },
  { label: 'A lowercase letter (a–z)', test: (pw) => /[a-z]/.test(pw) },
  { label: 'An uppercase letter (A–Z)', test: (pw) => /[A-Z]/.test(pw) },
  { label: 'A number (0–9)', test: (pw) => /\d/.test(pw) },
  { label: 'A symbol (! ? @ # …)', test: (pw) => /[^A-Za-z0-9]/.test(pw) },
];

/** True when every displayed rule is satisfied (exported for optional callers). */
export function passwordMeetsAll(password: string): boolean {
  return RULES.every((rule) => rule.test(password));
}

export default function PasswordRequirements({ password }: { password: string }) {
  return (
    <ul className="mt-2 space-y-1" aria-label="Password requirements">
      {RULES.map((rule) => {
        const met = rule.test(password);
        return (
          <li
            key={rule.label}
            className={`flex items-center gap-2 text-xs transition-colors ${
              met ? 'text-green-600 dark:text-green-400' : 'text-gray-400 dark:text-gray-500'
            }`}
          >
            <span
              aria-hidden
              className={`inline-flex h-4 w-4 shrink-0 items-center justify-center rounded-full text-[10px] font-bold ${
                met
                  ? 'bg-green-100 text-green-600 dark:bg-green-900/40 dark:text-green-400'
                  : 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500'
              }`}
            >
              {met ? '✓' : '○'}
            </span>
            <span>{rule.label}</span>
            <span className="sr-only">{met ? '— met' : '— not met'}</span>
          </li>
        );
      })}
    </ul>
  );
}
