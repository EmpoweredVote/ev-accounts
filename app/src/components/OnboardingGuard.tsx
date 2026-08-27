import { Navigate, Outlet } from 'react-router';
import { useAuthStore } from '../store/authStore';

/**
 * For routes that require a fully onboarded Connected user.
 * Connected users who haven't finished onboarding are sent to /onboarding.
 */
export function OnboardingGuard() {
  const { user } = useAuthStore();

  if (!user) return null;

  if (user.tier === 'connected' || user.tier === 'empowered') {
    if (!user.completedOnboarding) {
      return <Navigate to="/onboarding" replace />;
    }
  }

  return <Outlet />;
}
