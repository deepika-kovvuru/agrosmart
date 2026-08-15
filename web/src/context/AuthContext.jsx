import React, { createContext, useContext, useState, useEffect } from 'react';
import { apiFetch } from '../services/api';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('agrosmart_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Refresh user state if session exists
    const checkAuth = async () => {
      const savedUser = localStorage.getItem('agrosmart_user');
      if (savedUser) {
        try {
          const res = await apiFetch('/get_current_user');
          if (res && res.user) {
            setUser(res.user);
            localStorage.setItem('agrosmart_user', JSON.stringify(res.user));
          }
        } catch (_) {
          // Token expired or server unreachable
        }
      }
    };
    checkAuth();
  }, []);

  const login = async (emailOrPhone, password) => {
    setLoading(true);
    try {
      const res = await apiFetch('/login', {
        method: 'POST',
        body: JSON.stringify({ email: emailOrPhone, password }),
      });
      
      const userData = res.user || { name: emailOrPhone, email: emailOrPhone, id: res.user_id || 1 };
      setUser(userData);
      localStorage.setItem('agrosmart_user', JSON.stringify(userData));
      if (res.token) {
        localStorage.setItem('agrosmart_token', res.token);
      }
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
      const payload = {
        name: formData.username || formData.name,
        email: formData.email || `${formData.username || 'farmer'}@agrosmart.com`,
        phone: formData.phone,
        password: formData.password,
        confirm_password: formData.confirm_password || formData.password,
        state: formData.state,
      };

      const res = await apiFetch('/signup', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      return { success: true, message: res.message || 'User registered successfully!' };
    } catch (err) {
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    try {
      await apiFetch('/logout', { method: 'POST' });
    } catch (_) {}
    setUser(null);
    localStorage.removeItem('agrosmart_user');
    localStorage.removeItem('agrosmart_token');
  };

  const updateProfile = async (updatedData) => {
    if (!user || !user.id) return { success: false, error: 'User ID missing' };
    try {
      const res = await apiFetch(`/profile/${user.id}`, {
        method: 'PUT',
        body: JSON.stringify(updatedData),
      });
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
