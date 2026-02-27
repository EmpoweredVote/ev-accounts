import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

function Forbidden() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-gray-900">Not Authorized</h1>
        <p className="mt-2 text-gray-600">You do not have admin access.</p>
      </div>
    </div>
  );
}

export function AdminGuard() {
  const { isAuthenticated, user, isLoading } = useAuthStore();
  if (isLoading) return null;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!user?.isAdmin) return <Forbidden />;
  return <Outlet />;
}
