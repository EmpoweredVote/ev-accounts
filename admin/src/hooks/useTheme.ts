import { useState } from 'react';

const KEY = 'ev:color-scheme';
const COOKIE = 'ev_theme';

// 🔴 THE CROSS-APP TRUTH IS THE ev_theme COOKIE, NOT localStorage. Storage is per-origin, so it
// cannot carry a choice between essentials, Profile and Admin. essentials has written this cookie
// since the theme was introduced and its boot script calls it "the cross-app truth"; these two apps
// never did — so a light choice made here stayed here, and the person got a dark public site.
// Both halves are written now, and index.html reads them in this same order: cookie, then storage.
function readStoredTheme(): 'dark' | 'light' | null {
  const m = document.cookie.match(/(?:^|;\s*)ev_theme=([^;]+)/);
  const fromCookie = m ? m[1] : null;
  if (fromCookie === 'dark' || fromCookie === 'light') return fromCookie;
  try {
    const stored = localStorage.getItem(KEY);
    if (stored === 'dark' || stored === 'light') return stored;
  } catch {
    // Blocked storage — fall through to the caller's last resort.
  }
  return null;
}

function writeTheme(value: 'dark' | 'light') {
  const expires = new Date();
  expires.setFullYear(expires.getFullYear() + 1);
  // ⚠ On localhost the browser rejects a .empowered.vote cookie, so in dev only the localStorage
  // half takes effect and the theme will not follow you between apps. Expected, not a bug to chase.
  document.cookie = `${COOKIE}=${value}; domain=.empowered.vote; path=/; expires=${expires.toUTCString()}; SameSite=Lax`;
  try {
    localStorage.setItem(KEY, value);
  } catch {
    // Blocked or full storage. The cookie above already carries the choice.
  }
}

export function useTheme() {
  const [isDark, setIsDark] = useState(() => {
    // Stored choice first: the <html> class is not a source of truth — the
    // season-composition presentation view forces it on temporarily, and
    // sampling it mid-flight would latch the wrong initial state.
    //
    // 🔴 THE COOKIE OUTRANKS localStorage HERE, exactly as it does in index.html. This used to
    // read localStorage directly, which was correct only while storage was the sole record.
    // Now that a choice can arrive from essentials by cookie, reading storage first would latch
    // a stale local value, and the toggle would disagree with the page it is sitting on.
    const stored = readStoredTheme();
    if (stored) return stored === 'dark';
    return document.documentElement.classList.contains('dark');
  });

  function toggle() {
    const next = !isDark;
    setIsDark(next);
    if (next) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    writeTheme(next ? 'dark' : 'light');
  }

  return { isDark, toggle };
}
