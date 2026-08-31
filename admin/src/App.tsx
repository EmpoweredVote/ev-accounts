import { Routes, Route, Navigate } from 'react-router';
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
import { SeasonCompositionPage } from './pages/admin/SeasonCompositionPage';
import { ProposeRevisionPage } from './pages/admin/ProposeRevisionPage';
import { PoliticiansPage } from './pages/admin/PoliticiansPage';
import { CategoriesPage } from './pages/admin/CategoriesPage';
import { CoveragePage } from './pages/admin/CoveragePage';
import { PromotionsPage } from './pages/admin/PromotionsPage';
import { InviteOverridesPage } from './pages/admin/InviteOverridesPage';
import { ReviewQueuePage } from './pages/admin/ReviewQueuePage';
import { TopicRevisionReviewPage } from './pages/admin/TopicRevisionReviewPage';
import { StanceReviewPage } from './pages/admin/StanceReviewPage';
import { PoliticianStagingReviewPage } from './pages/admin/PoliticianStagingReviewPage';
import { ResearchReviewPage } from './pages/admin/ResearchReviewPage';
import { ReadRankQuotesPage } from './pages/admin/ReadRankQuotesPage';
import { ReadRankCoveragePage } from './pages/admin/ReadRankCoveragePage';
import { StanceBreakdownPage } from './pages/admin/StanceBreakdownPage';
import Login from './pages/Login';
import Signup from './pages/Signup';
import InformSignup from './pages/InformSignup';
import EmailConfirmed from './pages/EmailConfirmed';
import ForgotPassword from './pages/ForgotPassword';
import ResetPassword from './pages/ResetPassword';
import PrivacyPage from './pages/PrivacyPage';
import ProfilePage from './pages/ProfilePage';
import { useAuthStore } from './store/authStore';
import { apiFetch } from './lib/api';
import { workosEnabled, hasWorkosSession, refreshWorkosToken, embeddedAuthEnabled } from './lib/workosAuth';

function App() {
  const { setAuth, clearAuth, setLoading, accessToken } = useAuthStore();

  useEffect(() => {
    const hydrateFromMe = (fallbackToken: string) =>
      apiFetch<{
        id: string;
        email: string;
        is_admin: boolean;
        tier: string;
        completed_onboarding: boolean;
      }>('/account/me').then((me) => {
        // Use the store's current token — apiFetch may have refreshed it since
        // the caller read its token.
        const currentToken = useAuthStore.getState().accessToken ?? fallbackToken;
        setAuth(currentToken, {
          id: me.id ?? '',
          email: me.email ?? '',
          isAdmin: me.is_admin ?? false,
          tier: (me.tier as 'inform' | 'connected' | 'empowered') ?? 'inform',
          completedOnboarding: me.completed_onboarding ?? false,
        });
      });

    const token = sessionStorage.getItem('admin_token');
    if (token) {
      useAuthStore.setState({ accessToken: token });
      hydrateFromMe(token).catch(() => {
        sessionStorage.removeItem('admin_token');
        clearAuth();
      });
    } else if (embeddedAuthEnabled) {
      // Cookie-backed WorkOS session restore: a new tab or hard reload has no
      // sessionStorage token. hydrateFromMe starts with no Authorization
      // header, so apiFetch('/account/me') 401s and its own refresh path
      // pulls a token from GET /api/auth/session (Task 6), which reads the
      // httpOnly ev_wos_session cookie. No SDK, no localStorage hint.
      hydrateFromMe('').catch(() => { clearAuth(); });
    } else if (workosEnabled && hasWorkosSession()) {
      // WorkOS session restore (decision 0002 transition): a new tab or hard
      // reload has no sessionStorage token — ask the AuthKit SDK before
      // treating the visitor as logged out.
      refreshWorkosToken()
        .then((workosToken) => {
          if (!workosToken) {
            clearAuth();
            return;
          }
          useAuthStore.setState({ accessToken: workosToken });
          return hydrateFromMe(workosToken);
        })
        .catch(() => clearAuth());
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
      {/* Break-glass: classic Supabase form, always shown, unadvertised.
          Slated for removal once Supabase Auth sign-ins are disabled (0002). */}
      <Route path="/login/classic" element={<Login allowClassic />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/signup/inform" element={<InformSignup />} />
      <Route path="/email-confirmed" element={<EmailConfirmed />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />
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
          <Route path="topics/:topicKey/propose" element={<ProposeRevisionPage />} />
          <Route path="seasons" element={<SeasonCompositionPage />} />
          <Route path="stance-breakdown" element={<StanceBreakdownPage />} />
          <Route path="politicians" element={<PoliticiansPage />} />
          <Route path="categories" element={<CategoriesPage />} />
          <Route path="coverage" element={<CoveragePage />} />
          <Route path="coverage/map" element={<Navigate to="/admin/coverage" replace />} />
          <Route path="review" element={<ReviewQueuePage />} />
          <Route path="review/stances/:id" element={<StanceReviewPage />} />
          <Route path="review/politicians/:id" element={<PoliticianStagingReviewPage />} />
          <Route path="review/research/:id" element={<ResearchReviewPage />} />
          <Route path="review/topics/:id" element={<TopicRevisionReviewPage />} />
          <Route path="readrank-quotes" element={<ReadRankQuotesPage />} />
          <Route path="readrank-coverage" element={<ReadRankCoveragePage />} />
        </Route>
      </Route>

      {/* Default: send unauthenticated users to login */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;
