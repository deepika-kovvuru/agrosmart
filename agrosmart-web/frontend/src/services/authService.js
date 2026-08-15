import { apiFetch } from './api';

export const signupUser = async (formData) => {
  return await apiFetch('/signup', {
    method: 'POST',
    body: JSON.stringify({
      name: formData.name || formData.username,
      email: formData.email,
      phone: formData.phone,
      password: formData.password,
      confirm_password: formData.confirm_password || formData.password,
      state: formData.state,
    }),
  });
};

export const loginUser = async (emailOrPhone, password) => {
  return await apiFetch('/login', {
    method: 'POST',
    body: JSON.stringify({ email: emailOrPhone, password }),
  });
};

export const getCurrentUser = async () => {
  return await apiFetch('/get_current_user');
};

export const logoutUser = async () => {
  return await apiFetch('/logout', { method: 'POST' });
};

export const updateProfile = async (userId, data) => {
  return await apiFetch(`/profile/${userId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
};
