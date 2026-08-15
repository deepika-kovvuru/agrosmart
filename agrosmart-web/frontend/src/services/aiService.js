import { apiFetch } from './api';

export const askAI = async (message) => {
  try {
    const res = await apiFetch('/api/ask-ai', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
    return {
      success: true,
      query: message,
      response: res.response || res.message,
      timestamp: res.timestamp || new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
  } catch (err) {
    return {
      success: false,
      query: message,
      error: err.message,
      response: 'I apologize, I am unable to connect to the backend server right now. Please check your internet connection.',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
  }
};
