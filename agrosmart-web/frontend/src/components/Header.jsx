import React from 'react';
import { Sun, Moon, Globe, User as UserIcon } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';
import { useLanguage } from '../context/LanguageContext';
import { useAuth } from '../context/AuthContext';

export const Header = ({ title, activeTab, setActiveTab }) => {
  const { isDark, toggleTheme } = useTheme();
  const { langCode, languages, changeLanguage } = useLanguage();
  const { user } = useAuth();

  return (
    <header className="web-header">
      <div className="header-left">
        <h1 className="page-header-title">{title}</h1>
      </div>

      <div className="header-actions">
        {/* Language Selector */}
        <div className="lang-picker">
          <Globe size={18} className="picker-icon" />
          <select
            value={langCode}
            onChange={(e) => changeLanguage(e.target.value)}
            className="lang-select"
          >
            {languages.map((lang) => (
              <option key={lang.code} value={lang.code}>
                {lang.flag} {lang.name}
              </option>
            ))}
          </select>
        </div>

        {/* Dark Mode Toggle */}
        <button
          onClick={toggleTheme}
          className="theme-toggle-btn"
          title={isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
        >
          {isDark ? <Sun size={20} color="#FFC107" /> : <Moon size={20} color="#52796F" />}
        </button>

        {/* Profile Pill */}
        <button
          onClick={() => setActiveTab('profile')}
          className={`profile-pill ${activeTab === 'profile' ? 'active' : ''}`}
        >
          <UserIcon size={18} />
          <span className="profile-pill-name">{user?.name || user?.username || 'Account'}</span>
        </button>
      </div>

      <style>{`
        .web-header {
          height: 70px;
          background: var(--bg-surface);
          border-bottom: 1px solid var(--border-color);
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 24px;
          position: sticky;
          top: 0;
          z-index: 90;
        }

        .page-header-title {
          font-size: 1.35rem;
          font-weight: 700;
          color: var(--text-primary);
        }

        .header-actions {
          display: flex;
          align-items: center;
          gap: 14px;
        }

        .lang-picker {
          display: flex;
          align-items: center;
          gap: 6px;
          background: var(--bg-primary);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-full);
          padding: 6px 12px;
        }

        .picker-icon { color: var(--brand-primary); }

        .lang-select {
          background: transparent;
          border: none;
          color: var(--text-primary);
          font-family: var(--font-main);
          font-size: 0.825rem;
          font-weight: 600;
          cursor: pointer;
          outline: none;
        }

        .theme-toggle-btn {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          border: 1px solid var(--border-color);
          background: var(--bg-primary);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: var(--transition);
        }

        .theme-toggle-btn:hover { background: var(--bg-hover); }

        .profile-pill {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 8px 14px;
          background: var(--brand-mint);
          color: var(--brand-dark);
          border: 1px solid transparent;
          border-radius: var(--radius-full);
          font-weight: 600;
          font-size: 0.85rem;
          cursor: pointer;
          transition: var(--transition);
        }

        .profile-pill:hover, .profile-pill.active {
          background: var(--brand-primary);
          color: #FFFFFF;
        }
      `}</style>
    </header>
  );
};
