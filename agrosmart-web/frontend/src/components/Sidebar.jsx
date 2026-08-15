import React from 'react';
import { 
  Home, 
  TrendingUp, 
  Sprout, 
  Scan, 
  Bug, 
  CloudSun, 
  Newspaper, 
  Bot, 
  User, 
  LogOut,
  Calendar,
  Tractor
} from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';
import { useAuth } from '../context/AuthContext';

export const Sidebar = ({ activeTab, setActiveTab }) => {
  const { t } = useLanguage();
  const { user, logout } = useAuth();

  const navItems = [
    { id: 'home', label: t('home'), icon: Home },
    { id: 'prices', label: t('marketPrices'), icon: TrendingUp },
    { id: 'advisory', label: t('cropAdvisory'), icon: Sprout },
    { id: 'scanner', label: t('smartScanner'), icon: Scan },
    { id: 'pest', label: t('pestManagement'), icon: Bug },
    { id: 'farm-details', label: t('farmDetails'), icon: Tractor },
    { id: 'farm-schedule', label: t('farmSchedule'), icon: Calendar },
    { id: 'weather', label: t('weather'), icon: CloudSun },
    { id: 'news', label: t('tipsAndNews'), icon: Newspaper },
    { id: 'ai', label: t('aiAssistant'), icon: Bot },
    { id: 'profile', label: t('profile'), icon: User },
  ];

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-logo">
          <Sprout size={28} color="#FFFFFF" />
        </div>
        <div className="brand-info">
          <span className="brand-name">AGROSMART</span>
          <span className="brand-tagline">Smart Agriculture</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`nav-item ${isActive ? 'active' : ''}`}
            >
              <Icon size={20} className="nav-icon" />
              <span className="nav-label">{item.label}</span>
              {item.id === 'ai' && <span className="nav-badge">AI</span>}
              {item.id === 'news' && <span className="nav-badge live-badge">LIVE</span>}
            </button>
          );
        })}
      </nav>

      {user && (
        <div className="sidebar-footer">
          <div className="user-preview">
            <div className="user-avatar">{user.name ? user.name[0].toUpperCase() : 'F'}</div>
            <div className="user-details">
              <span className="user-name">{user.name || 'Farmer'}</span>
              <span className="user-role">{user.state || 'India'}</span>
            </div>
          </div>
          <button onClick={logout} className="logout-btn" title="Logout">
            <LogOut size={18} />
          </button>
        </div>
      )}

      <style>{`
        .sidebar {
          width: var(--sidebar-width);
          height: 100vh;
          background: var(--bg-surface);
          border-right: 1px solid var(--border-color);
          position: fixed;
          left: 0;
          top: 0;
          display: flex;
          flex-direction: column;
          z-index: 100;
        }
        
        @media (max-width: 1023px) {
          .sidebar { display: none; }
        }
        
        .sidebar-brand {
          padding: 24px 20px;
          display: flex;
          align-items: center;
          gap: 12px;
          border-bottom: 1px solid var(--border-color);
        }
        
        .brand-logo {
          width: 42px;
          height: 42px;
          background: linear-gradient(135deg, var(--brand-primary), var(--brand-dark));
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 10px rgba(45, 106, 79, 0.3);
        }
        
        .brand-name {
          font-weight: 800;
          font-size: 1.15rem;
          letter-spacing: 0.5px;
          color: var(--brand-primary);
          display: block;
          line-height: 1.1;
        }
        
        .brand-tagline {
          font-size: 0.72rem;
          color: var(--text-secondary);
          font-weight: 500;
        }
        
        .sidebar-nav {
          padding: 16px 12px;
          flex: 1;
          overflow-y: auto;
          display: flex;
          flex-direction: column;
          gap: 4px;
        }
        
        .nav-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 11px 16px;
          border-radius: var(--radius-md);
          color: var(--text-secondary);
          font-weight: 500;
          font-size: 0.875rem;
          background: transparent;
          border: none;
          cursor: pointer;
          transition: var(--transition);
          width: 100%;
          text-align: left;
          position: relative;
        }
        
        .nav-item:hover {
          background: var(--bg-hover);
          color: var(--brand-primary);
        }
        
        .nav-item.active {
          background: var(--brand-primary);
          color: #FFFFFF;
          font-weight: 600;
          box-shadow: 0 4px 12px rgba(45, 106, 79, 0.25);
        }
        
        .nav-item.active .nav-icon { color: #FFFFFF; }
        
        .nav-badge {
          margin-left: auto;
          font-size: 0.65rem;
          padding: 2px 6px;
          border-radius: 6px;
          background: var(--brand-mint);
          color: var(--brand-dark);
          font-weight: 700;
        }
        
        .live-badge {
          background: rgba(229, 57, 53, 0.15);
          color: var(--accent-red);
        }

        .sidebar-footer {
          padding: 16px 20px;
          border-top: 1px solid var(--border-color);
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: var(--bg-primary);
        }

        .user-preview { display: flex; align-items: center; gap: 10px; }

        .user-avatar {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          background: var(--brand-primary);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 0.9rem;
        }

        .user-details { display: flex; flex-direction: column; }
        .user-name { font-size: 0.85rem; font-weight: 600; color: var(--text-primary); }
        .user-role { font-size: 0.72rem; color: var(--text-secondary); }

        .logout-btn {
          background: transparent;
          border: none;
          color: var(--text-muted);
          cursor: pointer;
          padding: 6px;
          border-radius: 6px;
          transition: var(--transition);
        }

        .logout-btn:hover {
          color: var(--accent-red);
          background: rgba(229, 57, 53, 0.1);
        }
      `}</style>
    </aside>
  );
};
