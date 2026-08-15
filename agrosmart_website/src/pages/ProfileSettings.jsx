import React, { useState } from 'react';
import { User, Phone, MapPin, Globe, Moon, Sun, LogOut, CheckCircle2, Save } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { useLanguage } from '../context/LanguageContext';

export const ProfileSettings = () => {
  const { user, updateProfile, logout } = useAuth();
  const { isDark, toggleTheme } = useTheme();
  const { langCode, languages, changeLanguage, t } = useLanguage();

  const [phone, setPhone] = useState(user?.phone || '');
  const [state, setState] = useState(user?.state || 'Andhra Pradesh');
  const [crop, setCrop] = useState(user?.preferred_crop || 'Paddy (Rice)');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async (e) => {
    e.preventDefault();
    setMessage('');
    setError('');
    setSaving(true);

    const res = await updateProfile({ phone, state, preferred_crop: crop });
    setSaving(false);

    if (res.success) {
      setMessage('Profile updated successfully!');
    } else {
      setError(res.error || 'Could not update profile.');
    }
  };

  return (
    <div className="profile-page">
      <div className="hero-banner">
        <h1 className="hero-title">👤 {t('profile')}</h1>
        <p className="hero-subtitle">
          Manage your account credentials, regional state settings, language, and theme preferences.
        </p>
      </div>

      <div className="grid-2">
        {/* User Card */}
        <div className="card profile-info-card">
          <div className="avatar-header">
            <div className="profile-avatar-lg">
              {user?.username ? user.username[0].toUpperCase() : 'F'}
            </div>
            <div>
              <h2>{user?.username || 'Farmer Account'}</h2>
              <span className="badge badge-success">Active Farmer</span>
            </div>
          </div>

          <div className="info-list">
            <div className="info-item">
              <User size={18} className="text-brand" />
              <div>
                <span className="info-lbl">Username</span>
                <span className="info-val">{user?.username || 'N/A'}</span>
              </div>
            </div>
            <div className="info-item">
              <Phone size={18} className="text-brand" />
              <div>
                <span className="info-lbl">Phone Number</span>
                <span className="info-val">{user?.phone || 'Not provided'}</span>
              </div>
            </div>
            <div className="info-item">
              <MapPin size={18} className="text-brand" />
              <div>
                <span className="info-lbl">Registered State</span>
                <span className="info-val">{user?.state || 'Andhra Pradesh'}</span>
              </div>
            </div>
          </div>

          <button onClick={logout} className="btn btn-danger w-full mt-4">
            <LogOut size={18} /> {t('logout')}
          </button>
        </div>

        {/* Edit Form & Settings */}
        <div className="card">
          <h3>Edit Profile & Preferences</h3>

          {message && <div className="badge badge-success mb-3 p-2 w-full">{message}</div>}
          {error && <div className="badge badge-danger mb-3 p-2 w-full">{error}</div>}

          <form onSubmit={handleSave}>
            <div className="form-group">
              <label className="form-label">Phone Number</label>
              <input
                type="text"
                className="form-input"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">State</label>
              <select className="form-select" value={state} onChange={(e) => setState(e.target.value)}>
                <option value="Andhra Pradesh">Andhra Pradesh</option>
                <option value="Telangana">Telangana</option>
                <option value="Karnataka">Karnataka</option>
                <option value="Tamil Nadu">Tamil Nadu</option>
                <option value="Maharashtra">Maharashtra</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Preferred Primary Crop</label>
              <select className="form-select" value={crop} onChange={(e) => setCrop(e.target.value)}>
                <option value="Paddy (Rice)">Paddy (Rice)</option>
                <option value="Cotton">Cotton</option>
                <option value="Red Chilli">Red Chilli</option>
                <option value="Maize">Maize</option>
                <option value="Groundnut">Groundnut</option>
              </select>
            </div>

            <hr className="my-4" style={{ borderColor: 'var(--border-color)' }} />

            <div className="form-group">
              <label className="form-label">{t('language')}</label>
              <select
                className="form-select"
                value={langCode}
                onChange={(e) => changeLanguage(e.target.value)}
              >
                {languages.map((l) => (
                  <option key={l.code} value={l.code}>{l.flag} {l.name}</option>
                ))}
              </select>
            </div>

            <div className="form-group flex-between p-2 rounded" style={{ background: 'var(--bg-primary)' }}>
              <span>{t('darkMode')} Appearance</span>
              <button type="button" onClick={toggleTheme} className="btn btn-secondary btn-sm">
                {isDark ? <Sun size={16} color="#FFC107" /> : <Moon size={16} />}
                {isDark ? 'Dark Mode On' : 'Light Mode On'}
              </button>
            </div>

            <button type="submit" disabled={saving} className="btn btn-primary w-full mt-3">
              {saving ? <span className="spinner" /> : <><Save size={18} /> Save Changes</>}
            </button>
          </form>
        </div>
      </div>

      <style>{`
        .avatar-header { display: flex; align-items: center; gap: 16px; margin-bottom: 24px; }
        .profile-avatar-lg {
          width: 60px; height: 60px; border-radius: 50%;
          background: var(--brand-primary); color: white;
          display: flex; align-items: center; justify-content: center;
          font-size: 1.6rem; font-weight: 800;
        }

        .info-list { display: flex; flex-direction: column; gap: 16px; }
        .info-item { display: flex; align-items: center; gap: 12px; }
        .info-lbl { font-size: 0.75rem; color: var(--text-secondary); display: block; }
        .info-val { font-size: 0.95rem; font-weight: 700; color: var(--text-primary); }

        .my-4 { margin-top: 16px; margin-bottom: 16px; }
        .p-2 { padding: 8px 12px; }
        .rounded { border-radius: var(--radius-sm); }
      `}</style>
    </div>
  );
};
