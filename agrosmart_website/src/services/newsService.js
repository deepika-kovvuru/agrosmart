import { apiFetch } from './api';

export const getLiveNews = async (category = '', limit = 30) => {
  try {
    const params = new URLSearchParams();
    if (category && category !== 'All') params.append('category', category);
    params.append('limit', limit);
    return await apiFetch(`/api/live-news?${params.toString()}`);
  } catch (_) {
    // Fallback static articles
    return [
      {
        id: '1',
        category: 'Market Update',
        title: 'Kharif 2026 MSP declared for Paddy, Maize and Pulses',
        summary: 'The Cabinet Committee on Economic Affairs has announced Minimum Support Prices for major Kharif crops.',
        source: 'Agrosmart Market Daily',
        image_emoji: '📈',
        category_color: '#E07B39',
        is_featured: true,
        published_at: 'Today',
        link: '',
        live: false
      },
      {
        id: '2',
        category: 'Pest Alert',
        title: 'Fall Armyworm Advisory issued for Maize in Southern States',
        summary: 'Agricultural departments issued high-alert advisories following confirmed infestations in 4 districts.',
        source: 'Crop Protection News',
        image_emoji: '🐛',
        category_color: '#E53935',
        is_featured: false,
        published_at: '2h ago',
        link: '',
        live: false
      }
    ];
  }
};

export const refreshLiveNews = async () => {
  try {
    return await apiFetch('/api/live-news/refresh', { method: 'POST' });
  } catch (_) {
    return { count: 0 };
  }
};

export const getFarmingTips = async () => {
  try {
    return await apiFetch('/farming_tips');
  } catch (_) {
    return [
      {
        icon: '🌱',
        title: 'Seed Treatment',
        description: 'Treat seeds with bio-fungicide before sowing to prevent soil-borne fungal diseases.',
        tag: 'Pre-Sowing',
        category: 'Sowing'
      },
      {
        icon: '🌿',
        title: 'Intercropping Benefits',
        description: 'Growing legumes alongside cereals improves soil nitrogen naturally, saving 25% fertilizer.',
        tag: 'Soil Health',
        category: 'Soil'
      }
    ];
  }
};
