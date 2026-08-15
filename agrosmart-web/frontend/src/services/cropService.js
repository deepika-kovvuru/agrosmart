import { apiFetch } from './api';

export const getCropAdvisories = async (userId = 1, crop = '') => {
  try {
    const query = crop ? `?crop=${encodeURIComponent(crop)}` : '';
    return await apiFetch(`/crop_advisories/${userId}${query}`);
  } catch (_) {
    return [
      {
        id: 1,
        crop_name: 'Paddy (Rice)',
        stage: 'Vegetative Tillering',
        soil_type: 'Clay Loam',
        priority: 'High',
        title: 'Nitrogen & Water Management',
        description: 'Maintain 2-3 cm standing water. Apply 25 kg Urea + 10 kg MOP per acre as top dressing.',
        irrigation_advice: 'Maintain 2-3 cm standing water.',
        fertilizer_advice: 'Apply 25 kg Urea + 10 kg MOP per acre.',
        pest_warning: 'Scout weekly for stem borer dead hearts and brown planthopper.',
        created_at: 'Today'
      },
      {
        id: 2,
        crop_name: 'Cotton',
        stage: 'Square Formation',
        soil_type: 'Black Cotton Soil',
        priority: 'Medium',
        title: 'Pest Monitoring & Irrigation',
        description: 'Provide light irrigation at 10-day intervals. Install yellow sticky traps for sucking pests.',
        irrigation_advice: 'Provide light irrigation at 10-day intervals.',
        fertilizer_advice: 'Apply 35 kg Neem-coated Urea + 15 kg Potash per acre.',
        pest_warning: 'Monitor pink bollworm using pheromone traps (4 traps/acre).',
        created_at: 'Yesterday'
      }
    ];
  }
};

export const addCropAdvisory = async (data) => {
  return await apiFetch('/crop_advisories', {
    method: 'POST',
    body: JSON.stringify(data),
  });
};

export const deleteCropAdvisory = async (advisoryId) => {
  return await apiFetch(`/crop_advisories/${advisoryId}`, {
    method: 'DELETE',
  });
};
