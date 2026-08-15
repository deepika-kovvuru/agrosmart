import React, { useState, useEffect } from 'react';
import { Bug, ShieldAlert, CheckCircle2, Search, AlertTriangle } from 'lucide-react';
import { getPestAlerts } from '../services/pestService';
import { useLanguage } from '../context/LanguageContext';

export const PestManagement = () => {
  const { t } = useLanguage();
  const [alerts, setAlerts] = useState([]);
  const [query, setQuery] = useState('');

  useEffect(() => {
    const fetchPests = async () => {
      const data = await getPestAlerts();
      setAlerts(data);
    };
    fetchPests();
  }, []);

  const filtered = alerts.filter(a => 
    a.pest_name.toLowerCase().includes(query.toLowerCase()) ||
    a.crop.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="pest-page">
      <div className="hero-banner">
        <h1 className="hero-title">🐛 Pest & Disease Management</h1>
        <p className="hero-subtitle">
          Regional pest alerts, symptom identification, and organic/chemical control measures.
        </p>
      </div>

      <div className="card mb-4">
        <div className="search-input-wrap">
          <Search size={18} className="search-icon" />
          <input
            type="text"
            className="form-input search-input"
            placeholder="Search Pest or Crop (e.g. Whitefly, Cotton, BPH)"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
      </div>

      <div className="grid-2">
        {filtered.map((item) => (
          <div key={item.id} className="pest-card card">
            <div className="pest-card-header mb-3">
              <div>
                <span className="badge badge-warning mb-1">Region: {item.region}</span>
                <h3 className="pest-title">{item.pest_name}</h3>
                <span className="crop-tag">Affected Crop: <b>{item.crop}</b></span>
              </div>
              <span className={`badge ${item.severity === 'High' ? 'badge-danger' : 'badge-warning'}`}>
                {item.severity} Alert
              </span>
            </div>

            <div className="pest-info-box mb-2">
              <h4>🔍 Symptoms</h4>
              <p>{item.symptoms || item.description}</p>
            </div>

            <div className="pest-info-box mb-2">
              <h4>🛡️ Prevention Protocol</h4>
              <p>{item.prevention}</p>
            </div>

            <div className="pest-info-box treatment-box">
              <h4>🧪 Recommended Treatment</h4>
              <p>{item.treatment}</p>
            </div>
          </div>
        ))}
      </div>

      <style>{`
        .pest-card-header { display: flex; justify-content: space-between; align-items: flex-start; }
        .pest-title { font-size: 1.15rem; font-weight: 800; color: var(--text-primary); }
        .crop-tag { font-size: 0.8rem; color: var(--text-secondary); }
        .pest-info-box { background: var(--bg-primary); padding: 12px 14px; border-radius: var(--radius-sm); }
        .pest-info-box h4 { font-size: 0.825rem; font-weight: 700; margin-bottom: 4px; color: var(--brand-primary); }
        .pest-info-box p { font-size: 0.85rem; color: var(--text-primary); line-height: 1.4; }
        .treatment-box { background: rgba(82, 183, 136, 0.12); border: 1px solid var(--brand-light); }
      `}</style>
    </div>
  );
};
