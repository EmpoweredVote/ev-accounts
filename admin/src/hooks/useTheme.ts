import { useState } from 'react';

const KEY = 'ev:color-scheme';

export function useTheme() {
  const [isDark, setIsDark] = useState(() => {
    // Stored choice first: the <html> class is not a source of truth — the
    // season-composition presentation view forces it on temporarily, and
    // sampling it mid-flight would latch the wrong initial state.
    const stored = localStorage.getItem(KEY);
    if (stored === 'dark') return true;
    if (stored === 'light') return false;
    return document.documentElement.classList.contains('dark');
  });

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
