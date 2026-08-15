import React, { useState, useEffect } from 'react';
import { TrendingUp, Filter, Search, RefreshCw, ArrowUpRight, ArrowDownRight, Minus } from 'lucide-react';
import { getStates, getMandis, getMarketPrices } from '../services/marketService';
import { useLanguage } from '../context/LanguageContext';

export const MarketPrices = () => {
  const { t } = useLanguage();
  const [states, setStates] = useState([]);
  const [mandis, setMandis] = useState([]);
  const [selectedState, setSelectedState] = useState('Andhra Pradesh');
  const [selectedMandi, setSelectedMandi] = useState('');
  const [selectedCrop, setSelectedCrop] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [prices, setPrices] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchStatesList = async () => {
      const data = await getStates();
      setStates(data);
    };
    fetchStatesList();
  }, []);

  useEffect(() => {
    const fetchMandisList = async () => {
      if (selectedState) {
        const data = await getMandis(selectedState);
        setMandis(data);
      }
    };
    fetchMandisList();
  }, [selectedState]);

  useEffect(() => {
    fetchPrices();
  }, [selectedState, selectedMandi, selectedCrop]);

  const fetchPrices = async () => {
    setLoading(true);
    try {
      const data = await getMarketPrices(selectedState, selectedMandi, selectedCrop);
      setPrices(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const filteredPrices = prices.filter(p => 
    p.crop.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.mandi.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="market-prices-page">
      <div className="hero-banner">
        <h1 className="hero-title">📈 Real-Time Mandi Market Prices</h1>
        <p className="hero-subtitle">
          Live commodity prices across 37 Mandis and 18 Indian States with price change indicators.
        </p>
      </div>

      {/* Filter Controls */}
      <div className="card mb-4">
        <div className="filter-grid">
          <div className="form-group">
            <label className="form-label">{t('selectState')}</label>
            <select
              className="form-select"
              value={selectedState}
              onChange={(e) => {
                setSelectedState(e.target.value);
                setSelectedMandi('');
              }}
            >
              <option value="">All States</option>
              {states.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">{t('selectMandi')}</label>
            <select
              className="form-select"
              value={selectedMandi}
              onChange={(e) => setSelectedMandi(e.target.value)}
            >
              <option value="">All Mandis ({mandis.length})</option>
              {mandis.map((m) => (
                <option key={m.id || m.mandi_name} value={m.mandi_name || m}>
                  {m.mandi_name || m}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">{t('search')}</label>
            <div className="search-input-wrap">
              <Search size={18} className="search-icon" />
              <input
                type="text"
                className="form-input search-input"
                placeholder="Search Crop (e.g. Chilli, Paddy)"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Prices Grid */}
      {loading ? (
        <div className="card empty-state">
          <span className="spinner" style={{ margin: '0 auto 12px auto' }} />
          <p>Loading real-time market prices...</p>
        </div>
      ) : filteredPrices.length === 0 ? (
        <div className="card empty-state">
          <div className="empty-icon">🌾</div>
          <h3>No prices found for selected filters</h3>
          <p>Try clearing your search query or selecting a different Mandi yard.</p>
        </div>
      ) : (
        <div className="grid-3">
          {filteredPrices.map((p) => {
            const isRising = p.trend === 'Rising' || p.price_change > 0;
            const isFalling = p.trend === 'Falling' || p.price_change < 0;

            return (
              <div key={p.id || p.crop} className="price-card card">
                <div className="price-card-header">
                  <div>
                    <h3 className="crop-title">{p.crop}</h3>
                    <span className="mandi-subtitle">🏛️ {p.mandi}, {p.state}</span>
                  </div>
                  <span className={`badge ${isRising ? 'badge-success' : isFalling ? 'badge-danger' : 'badge-info'}`}>
                    {isRising ? <ArrowUpRight size={14} /> : isFalling ? <ArrowDownRight size={14} /> : <Minus size={14} />}
                    {p.trend || (isRising ? 'Rising' : isFalling ? 'Falling' : 'Stable')}
                  </span>
                </div>

                <div className="modal-price-box">
                  <span className="price-label">{t('modalPrice')}</span>
                  <div className="price-main-num">
                    ₹{p.modal_price.toLocaleString('en-IN')}
                    <span className="unit-label">/ Qtl</span>
                  </div>
                </div>

                <div className="price-breakdown">
                  <div className="breakdown-item">
                    <span className="bk-label">{t('minPrice')}</span>
                    <span className="bk-val">₹{p.min_price}</span>
                  </div>
                  <div className="breakdown-item">
                    <span className="bk-label">{t('maxPrice')}</span>
                    <span className="bk-val">₹{p.max_price}</span>
                  </div>
                  <div className="breakdown-item">
                    <span className="bk-label">Change</span>
                    <span className={`bk-val ${isRising ? 'text-green' : isFalling ? 'text-red' : ''}`}>
                      {p.price_change > 0 ? '+' : ''}{p.price_change} ({p.percentage_change}%)
                    </span>
                  </div>
                </div>

                <div className="price-card-footer">
                  <span>🕒 Updated: {p.updated_at || 'Today'}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      <style>{`
        .filter-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 16px;
        }

        @media (min-width: 768px) {
          .filter-grid {
            grid-template-columns: 1fr 1fr 1fr;
          }
        }

        .search-input-wrap {
          position: relative;
        }

        .search-icon {
          position: absolute;
          left: 14px;
          top: 50%;
          transform: translateY(-50%);
          color: var(--text-muted);
        }

        .search-input {
          padding-left: 42px;
        }

        .price-card {
          display: flex;
          flex-direction: column;
        }

        .price-card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 14px;
        }

        .crop-title {
          font-size: 1.1rem;
          font-weight: 700;
          color: var(--text-primary);
        }

        .mandi-subtitle {
          font-size: 0.78rem;
          color: var(--text-secondary);
          display: block;
          margin-top: 2px;
        }

        .modal-price-box {
          background: linear-gradient(135deg, var(--brand-mint) 0%, var(--bg-surface) 100%);
          padding: 14px;
          border-radius: var(--radius-sm);
          text-align: center;
          margin-bottom: 14px;
        }

        .price-label {
          font-size: 0.75rem;
          font-weight: 600;
          color: var(--brand-dark);
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .price-main-num {
          font-size: 1.6rem;
          font-weight: 800;
          color: var(--brand-primary);
          line-height: 1.1;
        }

        .unit-label {
          font-size: 0.8rem;
          font-weight: 500;
          color: var(--text-secondary);
        }

        .price-breakdown {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr;
          gap: 8px;
          padding: 10px 0;
          border-top: 1px dashed var(--border-color);
          border-bottom: 1px dashed var(--border-color);
          margin-bottom: 12px;
        }

        .breakdown-item {
          display: flex;
          flex-direction: column;
          align-items: center;
        }

        .bk-label {
          font-size: 0.7rem;
          color: var(--text-secondary);
        }

        .bk-val {
          font-size: 0.85rem;
          font-weight: 700;
        }

        .text-green { color: var(--brand-primary); }
        .text-red { color: var(--accent-red); }

        .price-card-footer {
          margin-top: auto;
          font-size: 0.72rem;
          color: var(--text-muted);
          text-align: right;
        }
      `}</style>
    </div>
  );
};
