import React, { useState, useEffect } from 'react';
import { Tractor, MapPin, Sprout, Droplets, Layers, Save, CheckCircle2 } from 'lucide-react';
import { getFarmDetails, updateFarmDetails } from '../services/farmService';
import { useAuth } from '../context/AuthContext';

export const FarmDetails = () => {
  const { user } = useAuth();
  const [farm, setFarm] = useState({
    land_area: '',
    primary_crops: '',
    soil_type: '',
    irrigation: '',
    region: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchFarm = async () => {
      setLoading(true);
      const data = await getFarmDetails(user?.id || 1);
      setFarm(data);
      setLoading(false);
    };
    fetchFarm();
  }, [user]);

  const handleChange = (e) => {
    setFarm({ ...farm, [e.target.name]: e.target.value });
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setMessage('');
    setError('');
    setSaving(true);
    try {
      await updateFarmDetails(user?.id || 1, farm);
      setMessage('Farm details updated successfully!');
    } catch (err) {
      setError(err.message || 'Failed to update farm details.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="farm-details-page">
      <div className="hero-banner">
        <h1 className="hero-title">🚜 Farm Details & Soil Management</h1>
        <p className="hero-subtitle">
          Manage your land area, primary crops, soil type, irrigation facilities, and regional field parameters.
        </p>
      </div>

      <div className="grid-2">
        {/* Current Overview Card */}
        <div className="card">
          <h3 className="mb-3">🌾 Farm Specifications Overview</h3>

          <div className="farm-spec-list">
            <div className="spec-item">
              <Tractor size={20} color="#2D6A4F" />
              <div>
                <span className="spec-lbl">Land Area</span>
                <span className="spec-val">{farm.land_area || '5.5 Acres'}</span>
              </div>
            </div>

            <div className="spec-item">
              <Sprout size={20} color="#2D6A4F" />
              <div>
                <span className="spec-lbl">Primary Cultivated Crops</span>
                <span className="spec-val">{farm.primary_crops || 'Paddy, Cotton, Red Chilli'}</span>
              </div>
            </div>

            <div className="spec-item">
              <Layers size={20} color="#2D6A4F" />
              <div>
                <span className="spec-lbl">Soil Classification</span>
                <span className="spec-val">{farm.soil_type || 'Clay Loam / Black Soil'}</span>
              </div>
            </div>

            <div className="spec-item">
              <Droplets size={20} color="#2D6A4F" />
              <div>
                <span className="spec-lbl">Irrigation Type</span>
                <span className="spec-val">{farm.irrigation || 'Borewell & Drip Irrigation'}</span>
              </div>
            </div>

            <div className="spec-item">
              <MapPin size={20} color="#2D6A4F" />
              <div>
                <span className="spec-lbl">Region / District</span>
                <span className="spec-val">{farm.region || user?.state || 'Andhra Pradesh'}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Edit Farm Details Form */}
        <div className="card">
          <h3 className="mb-3">✏️ Update Farm Information</h3>

          {message && <div className="badge badge-success mb-3 p-2 w-full">{message}</div>}
          {error && <div className="badge badge-danger mb-3 p-2 w-full">{error}</div>}

          <form onSubmit={handleSave}>
            <div className="form-group">
              <label className="form-label">Total Land Area (Acres)</label>
              <input
                type="text"
                name="land_area"
                className="form-input"
                value={farm.land_area}
                onChange={handleChange}
                placeholder="e.g. 5.5 Acres"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Primary Crops</label>
              <input
                type="text"
                name="primary_crops"
                className="form-input"
                value={farm.primary_crops}
                onChange={handleChange}
                placeholder="e.g. Paddy, Cotton, Red Chilli"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Soil Type</label>
              <select name="soil_type" className="form-select" value={farm.soil_type} onChange={handleChange}>
                <option value="Clay Loam">Clay Loam</option>
                <option value="Black Cotton Soil">Black Cotton Soil</option>
                <option value="Red Sandy Soil">Red Sandy Soil</option>
                <option value="Alluvial Soil">Alluvial Soil</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Irrigation System</label>
              <input
                type="text"
                name="irrigation"
                className="form-input"
                value={farm.irrigation}
                onChange={handleChange}
                placeholder="e.g. Borewell & Drip System"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Region / Location</label>
              <input
                type="text"
                name="region"
                className="form-input"
                value={farm.region}
                onChange={handleChange}
                placeholder="e.g. Guntur, Andhra Pradesh"
              />
            </div>

            <button type="submit" disabled={saving} className="btn btn-primary w-full mt-2">
              {saving ? <span className="spinner" /> : <><Save size={18} /> Save Farm Details</>}
            </button>
          </form>
        </div>
      </div>

      <style>{`
        .farm-spec-list { display: flex; flex-direction: column; gap: 16px; margin-top: 12px; }
        .spec-item { display: flex; align-items: center; gap: 14px; padding: 12px; background: var(--bg-primary); border-radius: var(--radius-sm); }
        .spec-lbl { font-size: 0.75rem; color: var(--text-secondary); display: block; }
        .spec-val { font-size: 0.95rem; font-weight: 700; color: var(--text-primary); }
        .w-full { width: 100%; }
        .p-2 { padding: 8px 12px; }
      `}</style>
    </div>
  );
};
