import { apiFetch } from './api';

export const getStates = async () => {
  try {
    return await apiFetch('/api/states');
  } catch (_) {
    return [
      'Andhra Pradesh', 'Telangana', 'Karnataka', 'Tamil Nadu', 
      'Maharashtra', 'Kerala', 'Odisha', 'West Bengal', 'Gujarat', 
      'Rajasthan', 'Punjab', 'Haryana', 'Uttar Pradesh', 'Madhya Pradesh', 
      'Bihar', 'Chhattisgarh', 'Jharkhand', 'Assam'
    ];
  }
};

export const getMandis = async (state) => {
  try {
    const query = state ? `?state=${encodeURIComponent(state)}` : '';
    return await apiFetch(`/api/mandis${query}`);
  } catch (_) {
    return [];
  }
};

export const getMarketPrices = async (state, mandi, crop) => {
  try {
    const params = new URLSearchParams();
    if (state) params.append('state', state);
    if (mandi) params.append('mandi', mandi);
    if (crop) params.append('crop', crop);
    
    return await apiFetch(`/api/market-prices?${params.toString()}`);
  } catch (_) {
    // Fallback data
    return [
      {
        id: 1,
        state: state || 'Andhra Pradesh',
        mandi: mandi || 'Guntur Market Yard',
        crop: crop || 'Red Chilli',
        min_price: 18500,
        max_price: 22000,
        modal_price: 20500,
        price_change: 450,
        percentage_change: 2.24,
        trend: 'Rising',
        updated_at: 'Today, 09:30 AM'
      },
      {
        id: 2,
        state: state || 'Andhra Pradesh',
        mandi: mandi || 'Kurnool APMC',
        crop: 'Paddy (Common)',
        min_price: 2180,
        max_price: 2350,
        modal_price: 2280,
        price_change: -30,
        percentage_change: -1.3,
        trend: 'Falling',
        updated_at: 'Today, 10:15 AM'
      }
    ];
  }
};
