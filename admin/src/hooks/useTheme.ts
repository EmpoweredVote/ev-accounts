import { useState } from 'react';

const KEY = 'ev:color-scheme';

export function useTheme() {
  const [isDark, setIsDark] = useState(() =>
    document.documentElement.classList.contains('dark')
  );

  function toggle() {
    const next = !isDark;
    setIsDark(next);
    if (next) {
      document.documentElement.classList.add('dark');
      localStorage.setItem(KEY, 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem(KEY, 'light');
    }
  }

  return { isDark, toggle };
}
