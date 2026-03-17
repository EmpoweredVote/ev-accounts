import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { AuthGuard } from './components/AuthGuard';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
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

  // Keep stored token in sync if it changes (e.g. token refresh later)
  useEffect(() => {
    if (accessToken) {
      localStorage.setItem('ev_token', accessToken);
    }
  }, [accessToken]);

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route element={<AuthGuard />}>
        <Route path="/" element={<DashboardPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
