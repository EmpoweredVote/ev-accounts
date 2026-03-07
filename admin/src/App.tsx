import { Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';
import { AdminGuard } from './components/AdminGuard';
import { AdminLayout } from './pages/admin/AdminLayout';
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AccountsPage } from './pages/admin/AccountsPage';
import { AccountDetailPage } from './pages/admin/AccountDetailPage';
import { InvitesPage } from './pages/admin/InvitesPage';
import { InviteTreePage } from './pages/admin/InviteTreePage';
import { CronLogPage } from './pages/admin/CronLogPage';
import { RolesPage } from './pages/admin/RolesPage';
import { TopicsPage } from './pages/admin/TopicsPage';
import { PoliticiansPage } from './pages/admin/PoliticiansPage';
import { CategoriesPage } from './pages/admin/CategoriesPage';
import Login from './pages/Login';
import { useAuthStore } from './store/authStore';
import { apiFetch } from './lib/api';

function App() {
  const { setAuth, clearAuth, setLoading, accessToken } = useAuthStore();

  useEffect(() => {
    const token = sessionStorage.getItem('admin_token');
    if (token) {
      useAuthStore.setState({ accessToken: token });
      apiFetch<{ isAdmin: boolean }>('/admin/me')
        .then(() => {
          setAuth(token, { id: '', email: '', isAdmin: true });
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
      <Route element={<AdminGuard />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<AdminDashboard />} />
          <Route path="accounts" element={<AccountsPage />} />
          <Route path="accounts/:userId" element={<AccountDetailPage />} />
          <Route path="invites" element={<InvitesPage />} />
          <Route path="invites/tree" element={<InviteTreePage />} />
          <Route path="invites/tree/:userId" element={<InviteTreePage />} />
          <Route path="cron-log" element={<CronLogPage />} />
          <Route path="roles" element={<RolesPage />} />
          <Route path="topics" element={<TopicsPage />} />
          <Route path="politicians" element={<PoliticiansPage />} />
          <Route path="categories" element={<CategoriesPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/admin" replace />} />
    </Routes>
  );
}

export default App;
