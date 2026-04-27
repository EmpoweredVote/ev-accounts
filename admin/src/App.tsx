import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { AdminGuard } from './components/AdminGuard';
import { AuthGuard } from './components/AuthGuard';
import { AdminLayout } from './pages/admin/AdminLayout';
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AccountsPage } from './pages/admin/AccountsPage';
import { AccountDetailPage } from './pages/admin/AccountDetailPage';
import { InvitesPage } from './pages/admin/InvitesPage';
import { InviteTreePage } from './pages/admin/InviteTreePage';
import { AccessRequestsPage } from './pages/admin/AccessRequestsPage';
import { CronLogPage } from './pages/admin/CronLogPage';
import { RolesPage } from './pages/admin/RolesPage';
import { RoleAuditPage } from './pages/admin/RoleAuditPage';
import { TopicsPage } from './pages/admin/TopicsPage';
import { PoliticiansPage } from './pages/admin/PoliticiansPage';
import { CategoriesPage } from './pages/admin/CategoriesPage';
import { PromotionsPage } from './pages/admin/PromotionsPage';
import { InviteOverridesPage } from './pages/admin/InviteOverridesPage';
import Login from './pages/Login';
import Signup from './pages/Signup';
import InformSignup from './pages/InformSignup';
import PrivacyPage from './pages/PrivacyPage';
import ProfilePage from './pages/ProfilePage';
import { useAuthStore } from './store/authStore';
import { apiFetch } from './lib/api';

function App() {
  const { setAuth, clearAuth, setLoading, accessToken } = useAuthStore();

  useEffect(() => {
    const token = sessionStorage.getItem('admin_token');
    if (token) {
      useAuthStore.setState({ accessToken: token });
      apiFetch<{
        id: string;
        email: string;
        is_admin: boolean;
        tier: string;
        completed_onboarding: boolean;
      }>('/account/me')
        .then((me) => {
          setAuth(token, {
            id: me.id ?? '',
            email: me.email ?? '',
            isAdmin: me.is_admin ?? false,
            tier: (me.tier as 'inform' | 'connected' | 'empowered') ?? 'inform',
            completedOnboarding: me.completed_onboarding ?? false,
          });
        })
        .catch(() => {
          sessionStorage.removeItem('admin_token');
          clearAuth();
        });
    } else {
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (accessToken) {
      sessionStorage.setItem('admin_token', accessToken);
    }
  }, [accessToken]);

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/signup/inform" element={<InformSignup />} />
      <Route path="/privacy" element={<PrivacyPage />} />

      {/* Authenticated (any tier) */}
      <Route element={<AuthGuard />}>
        <Route path="/profile" element={<ProfilePage />} />
      </Route>

      {/* Admin only */}
      <Route element={<AdminGuard />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<AdminDashboard />} />
          <Route path="accounts" element={<AccountsPage />} />
          <Route path="accounts/:userId" element={<AccountDetailPage />} />
          <Route path="promotions" element={<PromotionsPage />} />
          <Route path="invites" element={<InvitesPage />} />
          <Route path="invites/tree" element={<InviteTreePage />} />
          <Route path="invites/tree/:userId" element={<InviteTreePage />} />
          <Route path="invite-overrides" element={<InviteOverridesPage />} />
          <Route path="access-requests" element={<AccessRequestsPage />} />
          <Route path="cron-log" element={<CronLogPage />} />
          <Route path="roles" element={<RolesPage />} />
          <Route path="role-audit" element={<RoleAuditPage />} />
          <Route path="topics" element={<TopicsPage />} />
          <Route path="politicians" element={<PoliticiansPage />} />
          <Route path="categories" element={<CategoriesPage />} />
        </Route>
      </Route>

      {/* Default: send unauthenticated users to login */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;
