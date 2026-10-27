import { useState } from 'react';

const KEY = 'ev:color-scheme';
const COOKIE = 'ev_theme';

// 🔴 THE CROSS-APP TRUTH IS THE ev_theme COOKIE, NOT localStorage. Storage is per-origin, so it
// cannot carry a choice between essentials, Profile and Admin. essentials has written this cookie
// since the theme was introduced and its boot script calls it "the cross-app truth"; these two apps
// never did — so a light choice made here stayed here, and the person got a dark public site.
// Both halves are written now, and index.html reads them in this same order: cookie, then storage.
function writeTheme(value: 'dark' | 'light') {
  const expires = new Date();
  expires.setFullYear(expires.getFullYear() + 1);
  // ⚠ On localhost the browser rejects a .empowered.vote cookie, so in dev only the localStorage
  // half takes effect and the theme will not follow you between apps. Expected, not a bug to chase.
  document.cookie = `${COOKIE}=${value}; domain=.empowered.vote; path=/; expires=${expires.toUTCString()}; SameSite=Lax`;
  try {
    localStorage.setItem(KEY, value);
  } catch {
    // Blocked or full storage. The cookie above already carries the choice, so the toggle still
    // works and still survives a reload — this is deliberately not treated as a failure.
  }
}

export function useTheme() {
  const [isDark, setIsDark] = useState(
    () => document.documentElement.classList.contains('dark')
  );

  function toggle() {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.classList.toggle('dark', next);
    writeTheme(next ? 'dark' : 'light');
  }

  return { isDark, toggle };
}
