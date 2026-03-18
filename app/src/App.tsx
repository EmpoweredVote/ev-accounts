import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { AuthGuard } from './components/AuthGuard';
import { OnboardingGuard } from './components/OnboardingGuard';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import DashboardPage from './pages/DashboardPage';
import OnboardingPage from './pages/onboarding/OnboardingPage';
import UpdateLocationPage from './pages/settings/UpdateLocationPage';
import { useAuthStore, getStoredToken, User } from './store/authStore';
import { apiFetch } from './lib/api';

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
    // Check for token passed via hash fragment from accounts login
    const hash = window.location.hash;
    if (hash.includes('access_token=')) {
      const params = new URLSearchParams(hash.substring(1)); // strip the #
      const hashToken = params.get('access_token');
      if (hashToken) {
        // Clean the URL immediately (remove hash fragment with token)
        window.history.replaceState(null, '', window.location.pathname + window.location.search);
        // Set token in store so apiFetch picks it up
        useAuthStore.setState({ accessToken: hashToken });
        // Persist to localStorage
        localStorage.setItem('ev_token', hashToken);
        // Fetch user profile with this token
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
            setAuth(hashToken, user);
          })
          .catch(() => {
            clearAuth();
          });
        return; // Skip localStorage check — we have a fresh token
      }
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
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (accessToken) {
      localStorage.setItem('ev_token', accessToken);
    }
  }, [accessToken]);

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />

      {/* Authenticated */}
      <Route element={<AuthGuard />}>

        {/* Onboarding — accessible to connected users regardless of onboarding state */}
        <Route path="/onboarding" element={<OnboardingPage />} />

        {/* Requires completed onboarding for connected/empowered users */}
        <Route element={<OnboardingGuard />}>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/settings/location" element={<UpdateLocationPage />} />
        </Route>

      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
