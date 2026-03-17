import { create } from 'zustand';

export interface User {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  displayName: string | null;
  completedOnboarding: boolean;
  locationConsent: boolean;
}

interface AuthState {
  accessToken: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  setAuth: (token: string, user: User) => void;
  updateUser: (patch: Partial<User>) => void;
  clearAuth: () => void;
  setLoading: (loading: boolean) => void;
}

const TOKEN_KEY = 'ev_token';

export const useAuthStore = create<AuthState>((set, get) => ({
  accessToken: null,
  user: null,
  isAuthenticated: false,
  isLoading: true,
  setAuth: (token, user) => {
    localStorage.setItem(TOKEN_KEY, token);
    set({ accessToken: token, user, isAuthenticated: true, isLoading: false });
  },
  updateUser: (patch) => {
    const user = get().user;
    if (user) set({ user: { ...user, ...patch } });
  },
  clearAuth: () => {
    localStorage.removeItem(TOKEN_KEY);
    set({ accessToken: null, user: null, isAuthenticated: false, isLoading: false });
  },
  setLoading: (loading) => set({ isLoading: loading }),
}));

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
