import { apiFetch } from './api';

export const getCropAdvisories = async (userId) => {
  try {
    return await apiFetch(`/crop_advisories/${userId}`);
  } catch (_) {
    return [
      {
        id: 1,
        crop_name: 'Paddy (Rice)',
        stage: 'Vegetative Tillering',
        soil_type: 'Clay Loam',
        irrigation_advice: 'Maintain 2-3 cm standing water. Drain water 2 days before urea top-dressing.',
        fertilizer_advice: 'Apply 25 kg Urea + 10 kg MOP per acre as first top-dressing.',
        pest_warning: 'Scout weekly for stem borer dead hearts and BPH base buildup.',
      },
      {
        id: 2,
        crop_name: 'Cotton',
        stage: 'Square Formation',
        soil_type: 'Black Cotton Soil',
        irrigation_advice: 'Provide light irrigation at 10-day intervals. Avoid waterlogging.',
        fertilizer_advice: 'Apply 35 kg Neem-coated Urea + 15 kg Potash per acre.',
        pest_warning: 'Monitor pink bollworm using pheromone traps (4 traps/acre).',
      }
    ];
  }
};

export const getFarmSchedule = async (userId) => {
  try {
    return await apiFetch(`/farm_schedule/${userId}`);
  } catch (_) {
    return [];
  }
};
