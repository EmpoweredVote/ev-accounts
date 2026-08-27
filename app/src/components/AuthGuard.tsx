import { Outlet } from 'react-router';
import { useAuthStore } from '../store/authStore';

export function AuthGuard() {
  const { isAuthenticated, isLoading } = useAuthStore();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    // Redirect to accounts auth hub with return URL
    const returnUrl = encodeURIComponent(window.location.origin + window.location.pathname);
    window.location.href = `https://login.empowered.vote/login?redirect=${returnUrl}`;
    // Return spinner while redirect happens
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return <Outlet />;
}
