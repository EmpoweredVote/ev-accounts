import { Navigate, Outlet } from 'react-router';
import { useAuthStore } from '../store/authStore';

export function AuthGuard() {
  const { isAuthenticated, isLoading } = useAuthStore();
  if (isLoading) return null;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <Outlet />;
}
