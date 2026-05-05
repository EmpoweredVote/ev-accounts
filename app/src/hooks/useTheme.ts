import { useState } from 'react';

const KEY = 'ev:color-scheme';

export function useTheme() {
  const [isDark, setIsDark] = useState(
    () => document.documentElement.classList.contains('dark')
  );

  function toggle() {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.classList.toggle('dark', next);
    localStorage.setItem(KEY, next ? 'dark' : 'light');
  }

  return { isDark, toggle };
}
