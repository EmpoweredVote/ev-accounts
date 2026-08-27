import { Navigate, Outlet } from 'react-router';
import { useAuthStore } from '../store/authStore';

export function AdminGuard() {
  const { isAuthenticated, user, isLoading } = useAuthStore();
  if (isLoading) return null;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!user?.isAdmin) return <Navigate to="/profile" replace />;
  return <Outlet />;
}
