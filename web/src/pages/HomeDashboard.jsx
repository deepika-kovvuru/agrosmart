import React, { useEffect, useState } from 'react';
import { 
  Sprout, 
  CloudSun, 
  Bug, 
  TrendingUp, 
  Newspaper, 
  User, 
  ArrowRight, 
  AlertTriangle,
  Scan,
  Bot
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useLanguage } from '../context/LanguageContext';
import { getWeatherForecast } from '../services/weatherService';
import { getMarketPrices } from '../services/marketService';
import { getLiveNews } from '../services/newsService';

export const HomeDashboard = ({ setActiveTab }) => {
  const { user } = useAuth();
  const { t } = useLanguage();
  const [weather, setWeather] = useState(null);
  const [prices, setPrices] = useState([]);
  const [news, setNews] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadDashboard = async () => {
      setLoading(true);
      try {
        const [weatherData, priceData, newsData] = await Promise.all([
          getWeatherForecast(user?.state || 'Andhra Pradesh'),
          getMarketPrices(user?.state || 'Andhra Pradesh'),
          getLiveNews('All', 3),
        ]);
        setWeather(weatherData);
        setPrices(priceData.slice(0, 4));
        setNews(newsData.slice(0, 3));
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };

    loadDashboard();
  }, [user]);

  // Exact 6 Quick Actions matching mobile application
  const quickActions = [
    { id: 'advisory', label: 'Crop Advisory', icon: Sprout, color: '#2D6A4F', bg: 'rgba(45, 106, 79, 0.15)' },
    { id: 'weather', label: 'Weather Forecast', icon: CloudSun, color: '#0288D1', bg: 'rgba(76, 201, 240, 0.15)' },
    { id: 'pest', label: 'Pest & Disease', icon: Bug, color: '#E63946', bg: 'rgba(230, 57, 70, 0.15)' },
    { id: 'prices', label: 'Market Prices', icon: TrendingUp, color: '#E07B39', bg: 'rgba(244, 162, 97, 0.15)' },
    { id: 'news', label: 'Farming Tips', icon: Newspaper, color: '#9B59B6', bg: 'rgba(155, 89, 182, 0.15)' },
    { id: 'profile', label: 'My Profile', icon: User, color: '#1ABC9C', bg: 'rgba(26, 188, 156, 0.15)' },
  ];

  return (
    <div className="dashboard-container">
      {/* Hero Welcome Banner */}
      <div className="hero-banner">
        <div className="hero-content">
          <div className="badge badge-success mb-2" style={{ background: 'rgba(255,255,255,0.2)', color: '#fff' }}>
            🌾 Smart Farming Portal
          </div>
          <h1 className="hero-title">{t('welcome')}, {user?.username || 'Farmer'}! 👋</h1>
          <p className="hero-subtitle">
            Here is your daily agricultural breakdown for {user?.state || 'Andhra Pradesh'}. Crop health, market prices, and live weather.
          </p>
        </div>
      </div>

      {/* Scanner Banner CTA */}
      <div className="scanner-cta-card card mb-4" onClick={() => setActiveTab('scanner')}>
        <div className="scanner-cta-icon">📷</div>
        <div className="scanner-cta-info">
          <h3>Smart AI Crop & Soil Scanner</h3>
          <p>Scan your crop leaf, pest, or soil sample for instant AI diagnosis and care recommendations.</p>
        </div>
        <button className="btn btn-primary">
          <Scan size={18} /> Open Scanner
        </button>
      </div>

      {/* Mobile-Matching 6 Quick Actions Grid */}
      <h3 className="section-title mb-3">Quick Services</h3>
      <div className="quick-actions-grid grid-4 mb-4">
        {quickActions.map((action) => {
          const Icon = action.icon;
          return (
            <div
              key={action.id}
              className="action-card card"
              onClick={() => setActiveTab(action.id)}
            >
              <div className="action-icon" style={{ background: action.bg }}>
                <Icon size={26} color={action.color} />
              </div>
              <div className="action-info">
                <h3>{action.label}</h3>
                <p>Access {action.label.toLowerCase()} details</p>
              </div>
              <ArrowRight size={18} className="action-arrow" />
            </div>
          );
        })}
      </div>

      {/* Dashboard Columns */}
      <div className="dashboard-columns">
        {/* Left Column: Weather & Mandi Prices */}
        <div className="dash-col-left">
          {weather && (
            <div className="weather-card card mb-4">
              <div className="weather-header">
                <div>
                  <span className="weather-location">{weather.location}</span>
                  <h2 className="weather-temp">{weather.temperature}°C</h2>
                  <span className="weather-condition">{weather.condition}</span>
                </div>
                <div className="weather-main-icon">⛅</div>
              </div>

              <div className="weather-stats">
                <div className="stat-item">
                  <span className="stat-label">{t('humidity')}</span>
                  <span className="stat-value">{weather.humidity}%</span>
                </div>
                <div className="stat-item">
                  <span className="stat-label">{t('rainfall')}</span>
                  <span className="stat-value">{weather.rainfall_chance}</span>
                </div>
                <div className="stat-item">
                  <span className="stat-label">{t('windSpeed')}</span>
                  <span className="stat-value">{weather.wind_speed}</span>
                </div>
              </div>

              <div className="weather-advisory-box">
                <AlertTriangle size={18} color="#E07B39" />
                <p>{weather.advisory}</p>
              </div>
            </div>
          )}

          {/* Mandi Market Price List */}
          <div className="card mb-4">
            <div className="card-header">
              <h3>📈 Market Prices Highlights</h3>
              <button onClick={() => setActiveTab('prices')} className="view-all-btn">
                View All <ArrowRight size={14} />
              </button>
            </div>

            <div className="price-list">
              {prices.map((p) => (
                <div key={p.id || p.crop} className="price-row">
                  <div className="price-crop-info">
                    <span className="crop-name">{p.crop}</span>
                    <span className="mandi-name">{p.mandi}</span>
                  </div>
                  <div className="price-values">
                    <span className="price-num">₹{p.modal_price} / Qtl</span>
                    <span className={`trend-tag ${p.trend === 'Rising' || p.price_change > 0 ? 'rising' : 'falling'}`}>
                      {p.trend === 'Rising' || p.price_change > 0 ? '▲' : '▼'} {p.percentage_change}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Column: Live News & AI Assistant Banner */}
        <div className="dash-col-right">
          <div className="card mb-4">
            <div className="card-header">
              <div className="flex-align gap-2">
                <h3>🔴 Live Agricultural News</h3>
                <span className="badge badge-danger">LIVE</span>
              </div>
              <button onClick={() => setActiveTab('news')} className="view-all-btn">
                All News <ArrowRight size={14} />
              </button>
            </div>

            <div className="news-list">
              {news.map((item) => (
                <div key={item.id} className="news-item">
                  <span className="news-emoji">{item.image_emoji || '📰'}</span>
                  <div className="news-content">
                    <span className="news-cat" style={{ color: item.category_color }}>
                      {item.category} • {item.source}
                    </span>
                    <h4 className="news-title">{item.title}</h4>
                    <span className="news-time">{item.published_at}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="ai-cta-card card">
            <div className="ai-cta-icon">🤖</div>
            <div className="ai-cta-info">
              <h4>AgroSmart Voice AI Assistant</h4>
              <p>Have questions about your crop? Ask our AI assistant by voice or text.</p>
              <button onClick={() => setActiveTab('ai')} className="btn btn-primary mt-2">
                <Bot size={18} /> Talk to AI Assistant
              </button>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .section-title {
          font-size: 1.1rem;
          font-weight: 700;
          color: var(--text-primary);
        }

        .scanner-cta-card {
          display: flex;
          align-items: center;
          gap: 20px;
          background: linear-gradient(135deg, var(--brand-mint) 0%, var(--bg-surface) 100%);
          border-color: var(--brand-light);
          cursor: pointer;
        }

        .scanner-cta-icon {
          font-size: 2.8rem;
        }

        .scanner-cta-info h3 {
          font-size: 1.15rem;
          font-weight: 800;
          color: var(--brand-primary);
        }

        .scanner-cta-info p {
          font-size: 0.85rem;
          color: var(--text-secondary);
        }

        .quick-actions-grid {
          margin-bottom: 24px;
        }

        .action-card {
          display: flex;
          align-items: center;
          gap: 14px;
          cursor: pointer;
          transition: var(--transition);
        }

        .action-card:hover {
          transform: translateY(-3px);
          border-color: var(--brand-primary);
        }

        .action-icon {
          width: 48px;
          height: 48px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .action-info h3 {
          font-size: 0.925rem;
          font-weight: 700;
          color: var(--text-primary);
        }

        .action-info p {
          font-size: 0.75rem;
          color: var(--text-secondary);
        }

        .action-arrow {
          margin-left: auto;
          color: var(--text-muted);
        }

        .dashboard-columns {
          display: grid;
          grid-template-columns: 1fr;
          gap: 24px;
        }

        @media (min-width: 1024px) {
          .dashboard-columns {
            grid-template-columns: 1fr 1fr;
          }
        }

        .weather-card {
          background: linear-gradient(135deg, var(--bg-surface) 0%, var(--bg-secondary) 100%);
        }

        .weather-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 20px;
        }

        .weather-location {
          font-size: 0.85rem;
          color: var(--text-secondary);
          font-weight: 600;
        }

        .weather-temp {
          font-size: 2.5rem;
          font-weight: 800;
          color: var(--brand-primary);
          line-height: 1;
          margin: 4px 0;
        }

        .weather-condition {
          font-size: 0.9rem;
          font-weight: 600;
          color: var(--text-primary);
        }

        .weather-main-icon {
          font-size: 3.5rem;
        }

        .weather-stats {
          display: flex;
          justify-content: space-between;
          padding: 14px 0;
          border-top: 1px solid var(--border-color);
          border-bottom: 1px solid var(--border-color);
          margin-bottom: 14px;
        }

        .stat-item {
          display: flex;
          flex-direction: column;
        }

        .stat-label {
          font-size: 0.75rem;
          color: var(--text-secondary);
        }

        .stat-value {
          font-size: 0.95rem;
          font-weight: 700;
          color: var(--text-primary);
        }

        .weather-advisory-box {
          display: flex;
          gap: 10px;
          background: rgba(224, 123, 57, 0.1);
          padding: 10px 14px;
          border-radius: var(--radius-sm);
          font-size: 0.825rem;
          color: var(--text-primary);
        }

        .card-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 16px;
        }

        .card-header h3 {
          font-size: 1.05rem;
          font-weight: 700;
        }

        .view-all-btn {
          background: transparent;
          border: none;
          color: var(--brand-primary);
          font-weight: 600;
          font-size: 0.825rem;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 4px;
        }

        .price-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .price-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 10px 12px;
          border-radius: var(--radius-sm);
          background: var(--bg-primary);
        }

        .price-crop-info {
          display: flex;
          flex-direction: column;
        }

        .crop-name {
          font-weight: 700;
          font-size: 0.9rem;
        }

        .mandi-name {
          font-size: 0.75rem;
          color: var(--text-secondary);
        }

        .price-values {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
        }

        .price-num {
          font-weight: 800;
          font-size: 0.95rem;
          color: var(--brand-primary);
        }

        .trend-tag {
          font-size: 0.72rem;
          font-weight: 700;
        }

        .trend-tag.rising { color: var(--brand-primary); }
        .trend-tag.falling { color: var(--accent-red); }

        .news-list {
          display: flex;
          flex-direction: column;
          gap: 14px;
        }

        .news-item {
          display: flex;
          gap: 12px;
          padding-bottom: 12px;
          border-bottom: 1px solid var(--border-color);
        }

        .news-item:last-child {
          border-bottom: none;
          padding-bottom: 0;
        }

        .news-emoji {
          font-size: 1.5rem;
        }

        .news-content {
          display: flex;
          flex-direction: column;
        }

        .news-cat {
          font-size: 0.72rem;
          font-weight: 700;
          text-transform: uppercase;
        }

        .news-title {
          font-size: 0.875rem;
          font-weight: 600;
          line-height: 1.3;
          margin: 2px 0;
        }

        .news-time {
          font-size: 0.72rem;
          color: var(--text-muted);
        }

        .ai-cta-card {
          display: flex;
          gap: 16px;
          align-items: center;
          background: linear-gradient(135deg, var(--brand-mint) 0%, var(--bg-surface) 100%);
        }

        .ai-cta-icon {
          font-size: 2.5rem;
        }

        .ai-cta-info h4 {
          font-weight: 700;
          font-size: 0.95rem;
        }

        .ai-cta-info p {
          font-size: 0.8rem;
          color: var(--text-secondary);
        }

        .flex-align {
          display: flex;
          align-items: center;
        }

        .gap-2 { gap: 8px; }
        .mb-2 { margin-bottom: 8px; }
        .mb-3 { margin-bottom: 12px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
      `}</style>
    </div>
  );
};
