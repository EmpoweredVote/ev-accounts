import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { AuthGuard } from './components/AuthGuard';
import { OnboardingGuard } from './components/OnboardingGuard';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import WelcomeScreen from './pages/WelcomeScreen';
import DashboardPage from './pages/DashboardPage';
import ProfilePage from './pages/ProfilePage';
import OnboardingPage from './pages/onboarding/OnboardingPage';
import UpdateLocationPage from './pages/settings/UpdateLocationPage';
import { useAuthStore, getStoredToken, User } from './store/authStore';
import { apiFetch } from './lib/api';
import ContributorLayout from './pages/contributor/ContributorLayout';
import ContributorDashboard from './pages/contributor/ContributorDashboard';
import CompassEditorPage from './pages/contributor/CompassEditorPage';
import CampaignManagerPage from './pages/contributor/CampaignManagerPage';
import EssentialsEditorPage from './pages/contributor/EssentialsEditorPage';

interface MeResponse {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  display_name: string | null;
  completed_onboarding: boolean;
  location_consent: boolean;
}

function App() {
  const { setAuth, clearAuth, setLoading, accessToken } = useAuthStore();

  useEffect(() => {
    // SECURITY: this app deliberately does NOT accept an access token from its
    // own URL hash, and must not be changed to.
    //
    // A URL fragment carries no proof of who put it there, so accepting one
    // lets a link decide who you are signed in as. A link of the form
    //   https://app.empowered.vote/#access_token=<a token the sender holds>
    // would silently sign the visitor into the SENDER's account, and anything
    // they then entered — home address, compass answers, stances — would be
    // written into an account that person can read at will.
    //
    // Nothing needs it here. This app gets its session from the ev_session
    // cookie via the silent SSO check below, which is same-site to the API and
    // is the documented mechanism (docs/INTEGRATION-GUIDE-v2.md 3.3). The one
    // caller that used to hand a token to this app in a fragment — the
    // contributor role links on the admin Profile page — was changed to a plain
    // link in the same commit.
    //
    // Partner apps on other domains still use the documented fragment handoff.
    // That is a separate question from this app, which shares a domain with the
    // login and therefore shares the cookie.
    //
    // Strip a token someone put there anyway, so it does not linger in the
    // address bar, history or a shared link. Only touch the hash when it
    // carries a token, so ordinary #anchor links keep working.
    if (window.location.hash.includes('access_token=')) {
      window.history.replaceState(null, '', window.location.pathname + window.location.search);
    }

    const token = getStoredToken();
    if (token) {
      useAuthStore.setState({ accessToken: token });
      apiFetch<MeResponse>('/account/me')
        .then((me) => {
          const user: User = {
            id: me.id,
            email: me.email,
            tier: me.tier,
            displayName: me.display_name,
            completedOnboarding: me.completed_onboarding,
            locationConsent: me.location_consent,
          };
          setAuth(token, user);
        })
        .catch(() => {
          clearAuth();
        });
    } else {
      // Silent SSO check — inherit ev_session cookie from accounts.empowered.vote
      const silentSsoCheck = async (): Promise<{ access_token: string; refresh_token: string } | null> => {
        const API_URL = import.meta.env.VITE_API_URL || '';
        const url = `${API_URL}/api/auth/session`;

        const doFetch = async (): Promise<{ access_token: string; refresh_token: string } | null> => {
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 3000);
          try {
            const res = await fetch(url, {
              credentials: 'include',
              signal: controller.signal,
            });
            clearTimeout(timeoutId);
            if (res.status === 401) return null;
            if (res.ok) return res.json() as Promise<{ access_token: string; refresh_token: string }>;
            // 5xx — will retry once
            if (res.status >= 500) throw new Error('server_error');
            return null;
          } catch (err: unknown) {
            clearTimeout(timeoutId);
            const isAbort = err instanceof Error && err.name === 'AbortError';
            if (isAbort) return null;
            throw err; // re-throw for retry
          }
        };

        try {
          return await doFetch();
        } catch {
          // Retry once after 1 second on 5xx or network error
          await new Promise<void>((resolve) => setTimeout(resolve, 1000));
          try {
            return await doFetch();
          } catch {
            return null;
          }
        }
      };

      // Keep isLoading=true until SSO check completes — prevents AuthGuard redirect race
      silentSsoCheck().then((result) => {
        if (result) {
          localStorage.setItem('ev_token', result.access_token);
          useAuthStore.setState({ accessToken: result.access_token });
          apiFetch<MeResponse>('/account/me')
            .then((me) => {
              const user: User = {
                id: me.id,
                email: me.email,
                tier: me.tier,
                displayName: me.display_name,
                completedOnboarding: me.completed_onboarding,
                locationConsent: me.location_consent,
              };
              setAuth(result.access_token, user);
            })
            .catch(() => {
              clearAuth();
            });
        } else {
          setLoading(false);
        }
      });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (accessToken) {
      localStorage.setItem('ev_token', accessToken);
    }
  }, [accessToken]);

  // Cross-app logout sync — detect ev_session cookie cleared by another app
  useEffect(() => {
    if (!accessToken) return;

    const API_URL = import.meta.env.VITE_API_URL || '';
    const SESSION_URL = `${API_URL}/api/auth/session`;

    const poll = async () => {
      if (document.visibilityState !== 'visible') return;
      try {
        const res = await fetch(SESSION_URL, { credentials: 'include' });
        if (res.status === 401) {
          clearAuth();
        } else if (res.ok) {
          const data = await res.json() as { access_token: string; refresh_token: string };
          if (data.access_token && data.access_token !== accessToken) {
            localStorage.setItem('ev_token', data.access_token);
            useAuthStore.setState({ accessToken: data.access_token });
          }
        }
      } catch {
        // Network error — don't log out (transient failure)
      }
    };

    const id = setInterval(poll, 60_000);
    return () => clearInterval(id);
  }, [accessToken, clearAuth]);

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />
      <Route path="/welcome" element={<WelcomeScreen />} />

      {/* Authenticated */}
      <Route element={<AuthGuard />}>

        {/* Onboarding — accessible to connected users regardless of onboarding state */}
        <Route path="/onboarding" element={<OnboardingPage />} />

        {/* Requires completed onboarding for connected/empowered users */}
        <Route element={<OnboardingGuard />}>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/settings/location" element={<UpdateLocationPage />} />
          <Route path="/contributor" element={<ContributorLayout />}>
            <Route index element={<ContributorDashboard />} />
            <Route path="compass-editor" element={<CompassEditorPage />} />
            <Route path="campaign-manager" element={<CampaignManagerPage />} />
            <Route path="essentials-editor" element={<EssentialsEditorPage />} />
          </Route>
        </Route>

      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
