import { Navigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import DashboardPage from '../pages/DashboardPage';
import InformLandingPage from '../pages/InformLandingPage';

export function RootRoute() {
  const { isAuthenticated, isLoading, user } = useAuthStore();

  // Loading spinner — identical pattern to AuthGuard.tsx. Critical: never render
  // InformLandingPage or DashboardPage before SSO check resolves (prevents FOUC).
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Unauthenticated → landing page (no redirect to login.empowered.vote)
  if (!isAuthenticated) {
    return <InformLandingPage />;
  }

  // Authenticated: mirror OnboardingGuard logic — connected/empowered users
  // who haven't completed onboarding go to /onboarding. Inform tier skips this check.
  if ((user?.tier === 'connected' || user?.tier === 'empowered') && !user?.completedOnboarding) {
    return <Navigate to="/onboarding" replace />;
  }

  return <DashboardPage />;
}
