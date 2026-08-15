// Centralized API Configuration & HTTP Client
const DEFAULT_API_URL = 'http://localhost:5000';

export const getApiBaseUrl = () => {
  return import.meta.env.VITE_API_BASE_URL || DEFAULT_API_URL;
};

export const apiFetch = async (endpoint, options = {}) => {
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;
  
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Bypass-Tunnel-Reminder': 'true',
  };

  const token = localStorage.getItem('agrosmart_token');
  if (token) {
    defaultHeaders['Authorization'] = `Bearer ${token}`;
  }

  const config = {
    ...options,
    headers: {
      ...defaultHeaders,
      ...(options.headers || {}),
    },
  };

  try {
    const response = await fetch(url, config);
    let data;
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      const text = await response.text();
      data = { message: text };
    }

    if (!response.ok) {
      throw new Error(data?.error || data?.message || `HTTP ${response.status} Error`);
    }

    return data;
  } catch (error) {
    console.error(`[API Error] ${endpoint}:`, error.message);
    throw error;
  }
};
