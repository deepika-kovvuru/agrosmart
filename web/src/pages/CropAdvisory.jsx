import React, { useState, useEffect } from 'react';
import { Sprout, Calendar, Droplets, ShieldAlert, Plus, CheckCircle2 } from 'lucide-react';
import { getCropAdvisories } from '../services/cropService';
import { useAuth } from '../context/AuthContext';

export const CropAdvisory = () => {
  const { user } = useAuth();
  const [advisories, setAdvisories] = useState([]);
  const [selectedCrop, setSelectedCrop] = useState('Paddy (Rice)');
  const [stage, setStage] = useState('Vegetative');
  const [soil, setSoil] = useState('Clay Loam');

  useEffect(() => {
    const fetchAdvisories = async () => {
      const data = await getCropAdvisories(user?.id || 1);
      setAdvisories(data);
    };
    fetchAdvisories();
  }, [user]);

  return (
    <div className="crop-advisory-page">
      <div className="hero-banner">
        <h1 className="hero-title">🌾 Personalized Crop Advisory</h1>
        <p className="hero-subtitle">
          Tailored irrigation schedules, nutrient management, and stage-wise crop protection.
        </p>
      </div>

      {/* Advisory Selector Form */}
      <div className="card mb-4">
        <h3>Customize Crop Parameters</h3>
        <div className="grid-3 mt-3">
          <div className="form-group">
            <label className="form-label">Crop Name</label>
            <select className="form-select" value={selectedCrop} onChange={(e) => setSelectedCrop(e.target.value)}>
              <option value="Paddy (Rice)">Paddy (Rice)</option>
              <option value="Cotton">Cotton</option>
              <option value="Red Chilli">Red Chilli</option>
              <option value="Maize">Maize</option>
              <option value="Groundnut">Groundnut</option>
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Growth Stage</label>
            <select className="form-select" value={stage} onChange={(e) => setStage(e.target.value)}>
              <option value="Pre-Sowing">Pre-Sowing / Seedling</option>
              <option value="Vegetative">Vegetative Tillering</option>
              <option value="Flowering">Flowering & Pod Formation</option>
              <option value="Maturity">Maturity & Harvest</option>
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Soil Type</label>
            <select className="form-select" value={soil} onChange={(e) => setSoil(e.target.value)}>
              <option value="Clay Loam">Clay Loam</option>
              <option value="Black Cotton Soil">Black Cotton Soil</option>
              <option value="Red Sandy Soil">Red Sandy Soil</option>
              <option value="Alluvial Soil">Alluvial Soil</option>
            </select>
          </div>
        </div>
      </div>

      {/* Advisories Grid */}
      <div className="grid-2">
        {advisories.map((item) => (
          <div key={item.id} className="advisory-card card">
            <div className="adv-header">
              <div className="adv-icon">🌱</div>
              <div>
                <h3>{item.crop_name}</h3>
                <span className="badge badge-success">{item.stage}</span>
              </div>
            </div>

            <div className="adv-block mb-3">
              <h4><Droplets size={16} color="#2196F3" /> Irrigation Schedule</h4>
              <p>{item.irrigation_advice}</p>
            </div>

            <div className="adv-block mb-3">
              <h4><CheckCircle2 size={16} color="#2D6A4F" /> Fertilizer & Nutrient Advice</h4>
              <p>{item.fertilizer_advice}</p>
            </div>

            <div className="adv-block warning-block">
              <h4><ShieldAlert size={16} color="#E53935" /> Pest & Disease Monitoring</h4>
              <p>{item.pest_warning}</p>
            </div>
          </div>
        ))}
      </div>

      <style>{`
        .mt-3 { margin-top: 16px; }
        .adv-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
        .adv-icon { font-size: 2.2rem; }
        .adv-block { background: var(--bg-primary); padding: 12px 14px; border-radius: var(--radius-sm); }
        .adv-block h4 { font-size: 0.85rem; display: flex; align-items: center; gap: 6px; margin-bottom: 4px; color: var(--text-primary); }
        .adv-block p { font-size: 0.85rem; color: var(--text-secondary); line-height: 1.45; }
        .warning-block { background: rgba(229, 57, 53, 0.08); border: 1px solid rgba(229, 57, 53, 0.2); }
      `}</style>
    </div>
  );
};
