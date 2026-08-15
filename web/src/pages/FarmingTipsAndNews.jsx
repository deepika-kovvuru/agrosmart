import React, { useState, useEffect } from 'react';
import { Newspaper, RefreshCw, ExternalLink, Bookmark, Sparkles } from 'lucide-react';
import { getLiveNews, refreshLiveNews, getFarmingTips } from '../services/newsService';
import { useLanguage } from '../context/LanguageContext';

export const FarmingTipsAndNews = () => {
  const { t } = useLanguage();
  const [activeTab, setActiveTab] = useState('news');
  const [news, setNews] = useState([]);
  const [tips, setTips] = useState([]);
  const [category, setCategory] = useState('All');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const categories = ['All', 'Market Update', 'Technology', 'Pest Alert', 'Policy', 'Climate'];

  useEffect(() => {
    loadData();
  }, [category]);

  const loadData = async () => {
    setLoading(true);
    try {
      const [newsData, tipsData] = await Promise.all([
        getLiveNews(category),
        getFarmingTips(),
      ]);
      setNews(newsData);
      setTips(tipsData);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await refreshLiveNews();
    await loadData();
    setRefreshing(false);
  };

  return (
    <div className="news-page">
      <div className="hero-banner">
        <h1 className="hero-title">📰 Agricultural News & Farming Tips</h1>
        <p className="hero-subtitle">
          Real-time RSS updates from Krishi Jagran, PIB, Down To Earth, and expert agronomic advice.
        </p>
      </div>

      {/* Tabs Header */}
      <div className="tabs-header mb-4">
        <button
          onClick={() => setActiveTab('news')}
          className={`tab-btn ${activeTab === 'news' ? 'active' : ''}`}
        >
          🔴 Live RSS News ({news.length})
        </button>
        <button
          onClick={() => setActiveTab('tips')}
          className={`tab-btn ${activeTab === 'tips' ? 'active' : ''}`}
        >
          🌱 Expert Farming Tips ({tips.length})
        </button>
      </div>

      {activeTab === 'news' ? (
        <>
          {/* Live Indicator Banner */}
          <div className="card live-indicator-banner mb-4">
            <div className="live-badge-wrap">
              <span className="live-dot" />
              <span><b>🔴 LIVE FEED</b> — Real-time RSS aggregated from Krishi Jagran, PIB, Down To Earth</span>
            </div>
            <button onClick={handleRefresh} disabled={refreshing} className="btn btn-secondary btn-sm">
              <RefreshCw size={14} className={refreshing ? 'spinner' : ''} />
              {refreshing ? 'Refreshing...' : 'Force Refresh'}
            </button>
          </div>

          {/* Category Filter Chips */}
          <div className="category-chips mb-4">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setCategory(cat)}
                className={`chip ${category === cat ? 'active' : ''}`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* News List */}
          {loading ? (
            <div className="card empty-state">
              <span className="spinner" style={{ margin: '0 auto 12px auto' }} />
              <p>Fetching live news feeds...</p>
            </div>
          ) : (
            <div className="grid-2">
              {news.map((item) => (
                <div key={item.id} className="news-web-card card">
                  <div className="news-card-top mb-2">
                    <span className="news-emoji-box">{item.image_emoji || '📰'}</span>
                    <div>
                      <span className="news-category-badge" style={{ color: item.category_color, background: `${item.category_color}18` }}>
                        {item.category}
                      </span>
                      <span className="news-source-tag"> • {item.source}</span>
                    </div>
                  </div>

                  <h3 className="news-web-title">{item.title}</h3>
                  <p className="news-web-summary">{item.summary}</p>

                  <div className="news-web-footer mt-3">
                    <span className="news-date">🕒 {item.published_at}</span>
                    {item.link && (
                      <a href={item.link} target="_blank" rel="noreferrer" className="read-more-link">
                        Read Full Article <ExternalLink size={14} />
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      ) : (
        /* Expert Farming Tips Tab */
        <div className="grid-2">
          {tips.map((tip, i) => (
            <div key={i} className="tip-card card">
              <div className="tip-header">
                <span className="tip-icon">{tip.icon || '🌱'}</span>
                <div>
                  <span className="badge badge-success">{tip.tag || 'General'}</span>
                  <h3 className="tip-title">{tip.title}</h3>
                </div>
              </div>
              <p className="tip-desc">{tip.description}</p>
            </div>
          ))}
        </div>
      )}

      <style>{`
        .tabs-header { display: flex; gap: 12px; border-bottom: 2px solid var(--border-color); }
        .tab-btn {
          padding: 12px 20px;
          background: transparent;
          border: none;
          font-family: inherit;
          font-size: 0.95rem;
          font-weight: 600;
          color: var(--text-secondary);
          cursor: pointer;
          border-bottom: 3px solid transparent;
          margin-bottom: -2px;
        }

        .tab-btn.active {
          color: var(--brand-primary);
          border-bottom-color: var(--brand-primary);
        }

        .live-indicator-banner {
          display: flex;
          justify-content: space-between;
          align-items: center;
          background: rgba(82, 183, 136, 0.12);
          border-color: var(--brand-light);
        }

        .live-badge-wrap { display: flex; align-items: center; gap: 8px; font-size: 0.85rem; color: var(--brand-dark); }
        .live-dot { width: 10px; height: 10px; border-radius: 50%; background: var(--accent-red); animation: pulse 1s infinite alternate; }

        .category-chips { display: flex; gap: 8px; flex-wrap: wrap; }
        .chip.active { background: var(--brand-primary); color: white; border-color: var(--brand-primary); }

        .news-web-card { display: flex; flex-direction: column; }
        .news-card-top { display: flex; align-items: center; gap: 10px; }
        .news-emoji-box { font-size: 1.8rem; }
        .news-category-badge { font-size: 0.72rem; font-weight: 700; padding: 2px 8px; border-radius: 6px; }
        .news-source-tag { font-size: 0.75rem; color: var(--text-muted); }

        .news-web-title { font-size: 1.05rem; font-weight: 700; line-height: 1.35; margin-bottom: 8px; color: var(--text-primary); }
        .news-web-summary { font-size: 0.85rem; color: var(--text-secondary); line-height: 1.45; }

        .news-web-footer { display: flex; justify-content: space-between; align-items: center; font-size: 0.75rem; color: var(--text-muted); }
        .read-more-link { color: var(--brand-primary); font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 4px; }
        .read-more-link:hover { text-decoration: underline; }

        .tip-header { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
        .tip-icon { font-size: 2rem; }
        .tip-title { font-size: 1.1rem; font-weight: 700; }
        .tip-desc { font-size: 0.875rem; color: var(--text-secondary); line-height: 1.5; }
      `}</style>
    </div>
  );
};
