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
        treatment: 'Spray Neem Oil 5ml/L or Acetamiprid 20% SP @ 0.2g/L water.',
        reported_at: 'Today'
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
        treatment: 'Apply Pymetrozine 50% WDG @ 0.6g/L or Imidacloprid 17.8% SL @ 0.3ml/L.',
        reported_at: 'Yesterday'
      }
    ];
  }
};

export const getTreatments = async (crop = '', type = '') => {
  try {
    const params = new URLSearchParams();
    if (crop) params.append('crop', crop);
    if (type) params.append('type', type);
    return await apiFetch(`/treatments?${params.toString()}`);
  } catch (_) {
    return [
      {
        id: 1,
        crop: 'Cotton',
        pest: 'Whitefly',
        treatment_type: 'Chemical',
        name: 'Acetamiprid 20% SP',
        dosage: '0.2g / L water',
        application: 'Foliar spray during evening hours when infestation appears.'
      },
      {
        id: 2,
        crop: 'All Crops',
        pest: 'Sucking Pests',
        treatment_type: 'Organic',
        name: 'Neem Seed Kernel Extract (NSKE 5%)',
        dosage: '50ml / L water',
        application: 'Spray every 10 days as a preventive barrier.'
      }
    ];
  }
};
