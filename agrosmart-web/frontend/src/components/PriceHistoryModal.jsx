import React, { useState, useEffect } from 'react';
import { X, TrendingUp, Calendar } from 'lucide-react';
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import { getPriceHistory } from '../services/marketService';

export const PriceHistoryModal = ({ mandi, crop, onClose }) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [days, setDays] = useState(30);

  useEffect(() => {
    const fetchHistory = async () => {
      setLoading(true);
      const history = await getPriceHistory(mandi, crop, days);
      setData(history);
      setLoading(false);
    };
    fetchHistory();
  }, [mandi, crop, days]);

  return (
    <div className="modal-backdrop">
      <div className="modal-content card">
        <div className="modal-header">
          <div>
            <div className="flex-align gap-2">
              <TrendingUp size={22} color="#2D6A4F" />
              <h3>30-Day Price History Chart</h3>
            </div>
            <p className="subtitle">📊 {crop} at {mandi}</p>
          </div>
          <button onClick={onClose} className="close-btn"><X size={20} /></button>
        </div>

        <div className="range-selector mb-3">
          <span className="lbl"><Calendar size={14} /> Time Range:</span>
          <button onClick={() => setDays(7)} className={`chip ${days === 7 ? 'active' : ''}`}>7 Days</button>
          <button onClick={() => setDays(15)} className={`chip ${days === 15 ? 'active' : ''}`}>15 Days</button>
          <button onClick={() => setDays(30)} className={`chip ${days === 30 ? 'active' : ''}`}>30 Days</button>
        </div>

        {loading ? (
          <div className="empty-state">
            <span className="spinner" style={{ margin: '0 auto 12px auto' }} />
            <p>Loading price history from API...</p>
          </div>
        ) : (
          <div className="chart-container" style={{ width: '100%', height: 320 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data} margin={{ top: 10, right: 20, left: 10, bottom: 20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-color)" />
                <XAxis dataKey="date" stroke="var(--text-secondary)" fontSize={11} />
                <YAxis stroke="var(--text-secondary)" fontSize={11} domain={['auto', 'auto']} tickFormatter={(v) => `₹${v}`} />
                <Tooltip
                  contentStyle={{ background: 'var(--bg-surface)', borderColor: 'var(--border-color)', borderRadius: '10px' }}
                  formatter={(val) => [`₹${val.toLocaleString('en-IN')}`, 'Modal Price']}
                />
                <Line type="monotone" dataKey="modal_price" stroke="#2D6A4F" strokeWidth={3} dot={{ r: 4, fill: '#2D6A4F' }} activeDot={{ r: 7 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}

        <div className="modal-footer">
          <p>Source: AGROSMART Mandi Price Analytics Engine</p>
          <button onClick={onClose} className="btn btn-secondary">Close Chart</button>
        </div>
      </div>

      <style>{`
        .modal-backdrop {
          position: fixed;
          inset: 0;
          background: rgba(0, 0, 0, 0.6);
          backdrop-filter: blur(4px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 10000;
          padding: 20px;
        }

        .modal-content {
          width: 100%;
          max-width: 720px;
          padding: 24px;
        }

        .modal-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 16px;
        }

        .modal-header h3 { font-weight: 800; font-size: 1.25rem; }
        .subtitle { font-size: 0.85rem; color: var(--text-secondary); margin-top: 2px; }

        .close-btn {
          background: transparent;
          border: none;
          color: var(--text-muted);
          cursor: pointer;
          padding: 4px;
          border-radius: 6px;
        }

        .close-btn:hover { color: var(--accent-red); }

        .range-selector { display: flex; align-items: center; gap: 8px; }
        .range-selector .lbl { font-size: 0.8rem; color: var(--text-secondary); display: flex; align-items: center; gap: 4px; }
        .chip.active { background: var(--brand-primary); color: white; border-color: var(--brand-primary); }

        .modal-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-top: 20px;
          padding-top: 14px;
          border-top: 1px solid var(--border-color);
          font-size: 0.75rem;
          color: var(--text-muted);
        }
      `}</style>
    </div>
  );
};
