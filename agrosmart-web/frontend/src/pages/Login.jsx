import React, { useState } from 'react';
import { Sprout, Lock, User, Phone, MapPin, ArrowRight } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLanguage } from '../context/LanguageContext';

export const Login = ({ onSwitchToSignup }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login, loading } = useAuth();
  const { t } = useLanguage();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (!username || !password) {
      setError('Please enter username and password');
      return;
    }

    const res = await login(username, password);
    if (!res.success) {
      setError(res.error || 'Login failed. Check your credentials.');
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card card">
        <div className="auth-header">
          <div className="auth-icon-wrap">
            <Sprout size={36} color="#FFFFFF" />
          </div>
          <h2>AGROSMART</h2>
          <p>Smart Agriculture Management Portal</p>
        </div>

        {error && <div className="auth-error-banner">{error}</div>}

        <form onSubmit={handleSubmit} className="auth-form">
          <div className="form-group">
            <label className="form-label">Email or Mobile Number</label>
            <div className="input-icon-wrap">
              <User size={18} className="input-icon" />
              <input
                type="text"
                className="form-input"
                placeholder="Enter email or mobile number"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <div className="input-icon-wrap">
              <Lock size={18} className="input-icon" />
              <input
                type="password"
                className="form-input"
                placeholder="Enter password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <button type="submit" disabled={loading} className="btn btn-primary auth-submit-btn">
            {loading ? <span className="spinner" /> : <><span>{t('login')}</span> <ArrowRight size={18} /></>}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            Don't have an account?{' '}
            <button onClick={onSwitchToSignup} className="auth-link-btn">
              {t('signup')}
            </button>
          </p>
        </div>
      </div>

      <style>{`
        .auth-container {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, var(--brand-dark) 0%, var(--brand-primary) 100%);
          padding: 20px;
        }

        .auth-card {
          width: 100%;
          max-width: 440px;
          padding: 36px 28px;
        }

        .auth-header {
          text-align: center;
          margin-bottom: 28px;
        }

        .auth-icon-wrap {
          width: 64px;
          height: 64px;
          border-radius: 18px;
          background: linear-gradient(135deg, var(--brand-primary), var(--brand-light));
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 14px auto;
          box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
        }

        .auth-header h2 {
          color: var(--text-primary);
          font-weight: 800;
          font-size: 1.6rem;
          margin-bottom: 4px;
        }

        .auth-header p {
          font-size: 0.85rem;
          color: var(--text-secondary);
        }

        .auth-error-banner {
          background: rgba(229, 57, 53, 0.12);
          border: 1px solid var(--accent-red);
          color: var(--accent-red);
          padding: 10px 14px;
          border-radius: var(--radius-md);
          font-size: 0.85rem;
          margin-bottom: 20px;
          text-align: center;
        }

        .input-icon-wrap {
          position: relative;
        }

        .input-icon {
          position: absolute;
          left: 14px;
          top: 50%;
          transform: translateY(-50%);
          color: var(--text-muted);
        }

        .input-icon-wrap .form-input {
          padding-left: 42px;
        }

        .auth-submit-btn {
          width: 100%;
          padding: 14px;
          font-size: 1rem;
          margin-top: 10px;
        }

        .auth-footer {
          text-align: center;
          margin-top: 24px;
          font-size: 0.875rem;
          color: var(--text-secondary);
        }

        .auth-link-btn {
          background: transparent;
          border: none;
          color: var(--brand-primary);
          font-weight: 700;
          cursor: pointer;
          font-family: inherit;
        }
      `}</style>
    </div>
  );
};

export const Signup = ({ onSwitchToLogin }) => {
  const [formData, setFormData] = useState({
    username: '',
    password: '',
    phone: '',
    state: 'Andhra Pradesh',
    crop: 'Paddy (Rice)',
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const { signup, loading } = useAuth();
  const { t } = useLanguage();

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!formData.username || !formData.password || !formData.phone) {
      setError('Please fill in all required fields');
      return;
    }

    const res = await signup(formData);
    if (res.success) {
      setSuccess('Account created successfully! You can now log in.');
      setTimeout(() => onSwitchToLogin(), 1500);
    } else {
      setError(res.error || 'Signup failed.');
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card card">
        <div className="auth-header">
          <div className="auth-icon-wrap">
            <Sprout size={36} color="#FFFFFF" />
          </div>
          <h2>Join AGROSMART</h2>
          <p>Create your farmer account</p>
        </div>

        {error && <div className="auth-error-banner">{error}</div>}
        {success && <div className="auth-success-banner">{success}</div>}

        <form onSubmit={handleSubmit} className="auth-form">
          <div className="form-group">
            <label className="form-label">Username</label>
            <div className="input-icon-wrap">
              <User size={18} className="input-icon" />
              <input
                type="text"
                name="username"
                className="form-input"
                placeholder="Choose username"
                value={formData.username}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Phone Number</label>
            <div className="input-icon-wrap">
              <Phone size={18} className="input-icon" />
              <input
                type="text"
                name="phone"
                className="form-input"
                placeholder="10-digit mobile number"
                value={formData.phone}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">State</label>
            <div className="input-icon-wrap">
              <MapPin size={18} className="input-icon" />
              <select name="state" className="form-select" style={{ paddingLeft: '42px' }} value={formData.state} onChange={handleChange}>
                <option value="Andhra Pradesh">Andhra Pradesh</option>
                <option value="Telangana">Telangana</option>
                <option value="Karnataka">Karnataka</option>
                <option value="Tamil Nadu">Tamil Nadu</option>
                <option value="Maharashtra">Maharashtra</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <div className="input-icon-wrap">
              <Lock size={18} className="input-icon" />
              <input
                type="password"
                name="password"
                className="form-input"
                placeholder="Choose a password"
                value={formData.password}
                onChange={handleChange}
              />
            </div>
          </div>

          <button type="submit" disabled={loading} className="btn btn-primary auth-submit-btn">
            {loading ? <span className="spinner" /> : <><span>{t('signup')}</span> <ArrowRight size={18} /></>}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            Already have an account?{' '}
            <button onClick={onSwitchToLogin} className="auth-link-btn">
              {t('login')}
            </button>
          </p>
        </div>
      </div>

      <style>{`
        .auth-success-banner {
          background: rgba(82, 183, 136, 0.15);
          border: 1px solid var(--brand-light);
          color: var(--brand-primary);
          padding: 10px 14px;
          border-radius: var(--radius-md);
          font-size: 0.85rem;
          margin-bottom: 20px;
          text-align: center;
        }
      `}</style>
    </div>
  );
};
