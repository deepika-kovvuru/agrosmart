import { apiFetch } from './api';

export const getPestAlerts = async (region = '', crop = '') => {
  try {
    const params = new URLSearchParams();
    if (region) params.append('region', region);
    if (crop) params.append('crop', crop);
    return await apiFetch(`/pest_alerts?${params.toString()}`);
  } catch (_) {
    return [
      {
        id: 1,
        region: 'Andhra Pradesh & Telangana',
        crop: 'Cotton',
        pest_name: 'Whitefly & Aphids',
        severity: 'High',
        description: 'Sucking pest infestation causing leaf yellowing and honeydew mold formation.',
        symptoms: 'Yellow spots on leaf surface, sticky leaves, stunted plant growth.',
        prevention: 'Install yellow sticky traps (10/acre) and avoid excess nitrogen fertilizer.',
        treatment: 'Spray Neem Oil 5ml/L or Acetamiprid 20% SP @ 0.2g/L water.'
      },
      {
        id: 2,
        region: 'Karnataka & Maharashtra',
        crop: 'Paddy / Rice',
        pest_name: 'Brown Planthopper (BPH)',
        severity: 'High',
        description: 'Pests congregate at the base of plants causing hopperburn patches.',
        symptoms: 'Circular patches of drying brown plants in the middle of field.',
        prevention: 'Alternate wetting and drying (AWD) irrigation; avoid dense planting.',
        treatment: 'Apply Pymetrozine 50% WDG @ 0.6g/L or Imidacloprid 17.8% SL @ 0.3ml/L.'
      }
    ];
  }
};

export const getTreatments = async () => {
  try {
    return await apiFetch('/treatments');
  } catch (_) {
    return [];
  }
};
