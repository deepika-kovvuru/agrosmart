import { apiFetch } from './api';

export const askAI = async (message) => {
  try {
    const res = await apiFetch('/api/ask-ai', {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
    return { success: true, response: res.response || res.message };
  } catch (err) {
    return {
      success: false,
      error: err.message,
      response: 'I apologize, I am unable to connect to the backend server right now. Please check your internet connection.',
    };
  }
};
