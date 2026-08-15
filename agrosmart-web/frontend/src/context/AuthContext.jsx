import React, { createContext, useContext, useState, useEffect } from 'react';
import { loginUser, signupUser, getCurrentUser, logoutUser, updateProfile as apiUpdateProfile } from '../services/authService';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('agrosmart_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      const savedUser = localStorage.getItem('agrosmart_user');
      if (savedUser) {
        try {
          const res = await getCurrentUser();
          if (res && res.user) {
            setUser(res.user);
            localStorage.setItem('agrosmart_user', JSON.stringify(res.user));
          }
        } catch (_) {}
      }
    };
    checkAuth();
  }, []);

  const login = async (emailOrPhone, password) => {
    setLoading(true);
    try {
      const res = await loginUser(emailOrPhone, password);
      const userData = res.user || { name: emailOrPhone, email: emailOrPhone, id: res.user_id || 1 };
      setUser(userData);
      localStorage.setItem('agrosmart_user', JSON.stringify(userData));
      if (res.token) localStorage.setItem('agrosmart_token', res.token);
      return { success: true, user: userData };
    } catch (err) {
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  const signup = async (formData) => {
    setLoading(true);
    try {
      const res = await signupUser(formData);
      return { success: true, message: res.message || 'User registered successfully!' };
    } catch (err) {
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    try {
      await logoutUser();
    } catch (_) {}
    setUser(null);
    localStorage.removeItem('agrosmart_user');
    localStorage.removeItem('agrosmart_token');
  };

  const updateProfile = async (updatedData) => {
    if (!user || !user.id) return { success: false, error: 'User ID missing' };
    try {
      const res = await apiUpdateProfile(user.id, updatedData);
      const newUserData = { ...user, ...updatedData };
      setUser(newUserData);
      localStorage.setItem('agrosmart_user', JSON.stringify(newUserData));
      return { success: true, message: res.message };
    } catch (err) {
      return { success: false, error: err.message };
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, signup, logout, updateProfile }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
