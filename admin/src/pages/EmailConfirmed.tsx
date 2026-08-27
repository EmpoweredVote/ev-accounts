import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { useAuthStore } from '../store/authStore';

const API_BASE = import.meta.env.VITE_API_URL
  ? `${import.meta.env.VITE_API_URL}/api`
  : '/api';

export default function EmailConfirmed() {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [error, setError] = useState(false);

  useEffect(() => {
    async function autoLogin() {
      const hash = new URLSearchParams(window.location.hash.slice(1));
      const accessToken = hash.get('access_token');
      const refreshToken = hash.get('refresh_token');

      if (!accessToken || !refreshToken) {
        setError(true);
        return;
      }

      try {
        const meRes = await fetch(`${API_BASE}/account/me`, {
          headers: { Authorization: `Bearer ${accessToken}` },
        });

        if (!meRes.ok) throw new Error('account/me failed');

        const meData = await meRes.json();

        setAuth(accessToken, {
          id: meData.id ?? '',
          email: meData.email ?? '',
          isAdmin: meData.is_admin ?? false,
          tier: meData.tier ?? 'inform',
          completedOnboarding: meData.completed_onboarding ?? false,
        });

        sessionStorage.setItem('admin_token', accessToken);

        // Navigate to /profile on the CURRENT origin (replace drops the token
        // hash from history). Hard-coding login.empowered.vote here threw users
        // who confirmed on another origin off-origin, losing the just-set session.
        navigate('/profile', { replace: true });
      } catch {
        setError(true);
      }
    }

    autoLogin();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (error) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">empowered.vote</h1>
        </div>
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-6 w-full max-w-sm space-y-4 text-center">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Email confirmed!</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Your email is verified. Please log in to continue.
          </p>
          <a
            href="/login"
            className="block w-full py-3 px-4 bg-ev-teal dark:bg-ev-teal-light hover:bg-ev-teal/90 text-white dark:text-ev-black font-semibold rounded-xl text-sm transition-colors text-center"
          >
            Log in
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black">
      <p className="text-sm text-gray-500 dark:text-gray-400">Confirming your email…</p>
    </div>
  );
}
