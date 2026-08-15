import React from 'react';
import { Home, TrendingUp, Scan, Bot, User } from 'lucide-react';
import { useLanguage } from '../context/LanguageContext';

export const BottomNav = ({ activeTab, setActiveTab }) => {
  const { t } = useLanguage();

  const items = [
    { id: 'home', label: t('home'), icon: Home },
    { id: 'prices', label: t('marketPrices'), icon: TrendingUp },
    { id: 'scanner', label: t('smartScanner'), icon: Scan },
    { id: 'ai', label: t('aiAssistant'), icon: Bot },
    { id: 'profile', label: t('profile'), icon: User },
  ];

  return (
    <nav className="mobile-bottom-nav">
      {items.map((item) => {
        const Icon = item.icon;
        const isActive = activeTab === item.id;
        return (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={`bottom-nav-item ${isActive ? 'active' : ''}`}
          >
            <Icon size={20} />
            <span className="bottom-nav-label">{item.label}</span>
          </button>
        );
      })}

      <style>{`
        .mobile-bottom-nav {
          display: flex;
          position: fixed;
          bottom: 0;
          left: 0;
          right: 0;
          height: 64px;
          background: var(--bg-surface);
          border-top: 1px solid var(--border-color);
          z-index: 1000;
          box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.05);
        }

        @media (min-width: 1024px) {
          .mobile-bottom-nav {
            display: none;
          }
        }

        .bottom-nav-item {
          flex: 1;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 4px;
          background: transparent;
          border: none;
          color: var(--text-secondary);
          cursor: pointer;
          transition: var(--transition);
        }

        .bottom-nav-item.active {
          color: var(--brand-primary);
          font-weight: 700;
        }

        .bottom-nav-label {
          font-size: 0.7rem;
        }
      `}</style>
    </nav>
  );
};
