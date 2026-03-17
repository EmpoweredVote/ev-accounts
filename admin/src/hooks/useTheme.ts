import { useState } from 'react';

export function useTheme() {
  const [isDark, setIsDark] = useState(() =>
    document.documentElement.classList.contains('dark')
  );

  function toggle() {
    const next = !isDark;
    setIsDark(next);
    if (next) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('ev-theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('ev-theme', 'light');
    }
  }

  return { isDark, toggle };
}
