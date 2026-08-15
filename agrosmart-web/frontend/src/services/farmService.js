import { apiFetch } from './api';

export const getFarmDetails = async (userId = 1) => {
  try {
    return await apiFetch(`/farm_details/${userId}`);
  } catch (_) {
    return {
      land_area: '5.5 Acres',
      primary_crops: 'Paddy, Cotton, Red Chilli',
      soil_type: 'Clay Loam / Black Soil',
      irrigation: 'Borewell & Drip System',
      region: 'Guntur, Andhra Pradesh'
    };
  }
};

export const updateFarmDetails = async (userId = 1, data) => {
  return await apiFetch(`/farm_details/${userId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
};

export const getFarmSchedule = async (userId = 1) => {
  try {
    return await apiFetch(`/farm_schedule/${userId}`);
  } catch (_) {
    return [
      {
        id: 1,
        activity: 'Urea Top Dressing & Weeding',
        crop: 'Paddy',
        date: '2026-08-18',
        time: '08:00 AM',
        status: 'Pending',
      },
      {
        id: 2,
        activity: 'Neem Oil Spraying for Whitefly Prevention',
        crop: 'Cotton',
        date: '2026-08-20',
        time: '05:00 PM',
        status: 'Pending',
      }
    ];
  }
};

export const addFarmSchedule = async (data) => {
  return await apiFetch('/farm_schedule', {
    method: 'POST',
    body: JSON.stringify(data),
  });
};

export const updateFarmSchedule = async (scheduleId, data) => {
  return await apiFetch(`/farm_schedule/${scheduleId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
};

export const deleteFarmSchedule = async (scheduleId) => {
  return await apiFetch(`/farm_schedule/${scheduleId}`, {
    method: 'DELETE',
  });
};
