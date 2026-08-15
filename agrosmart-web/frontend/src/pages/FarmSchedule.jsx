import React, { useState, useEffect } from 'react';
import { Calendar, Plus, CheckCircle2, Clock, Trash2, Check, AlertCircle } from 'lucide-react';
import { getFarmSchedule, addFarmSchedule, updateFarmSchedule, deleteFarmSchedule } from '../services/farmService';
import { useAuth } from '../context/AuthContext';

export const FarmSchedule = () => {
  const { user } = useAuth();
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newActivity, setNewActivity] = useState({
    activity: '',
    crop: 'Paddy',
    date: new Date().toISOString().split('T')[0],
    time: '09:00 AM',
  });

  useEffect(() => {
    fetchSchedule();
  }, [user]);

  const fetchSchedule = async () => {
    setLoading(true);
    const data = await getFarmSchedule(user?.id || 1);
    setSchedules(data);
    setLoading(false);
  };

  const handleAdd = async (e) => {
    e.preventDefault();
    if (!newActivity.activity) return;

    try {
      await addFarmSchedule({
        user_id: user?.id || 1,
        ...newActivity,
        status: 'Pending',
      });
      setShowAddModal(false);
      setNewActivity({ activity: '', crop: 'Paddy', date: new Date().toISOString().split('T')[0], time: '09:00 AM' });
      fetchSchedule();
    } catch (err) {
      alert(err.message || 'Failed to add activity.');
    }
  };

  const handleToggleStatus = async (item) => {
    const newStatus = item.status === 'Completed' ? 'Pending' : 'Completed';
    try {
      await updateFarmSchedule(item.id, { status: newStatus });
      fetchSchedule();
    } catch (_) {}
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this farming activity?')) {
      try {
        await deleteFarmSchedule(id);
        fetchSchedule();
      } catch (_) {}
    }
  };

  return (
    <div className="farm-schedule-page">
      <div className="hero-banner">
        <div className="flex-between">
          <div>
            <h1 className="hero-title">📅 Farm Schedule & Task Tracker</h1>
            <p className="hero-subtitle">
              Plan and schedule irrigation, fertilizer application, spraying, and harvesting tasks.
            </p>
          </div>
          <button onClick={() => setShowAddModal(true)} className="btn btn-primary" style={{ background: '#FFFFFF', color: '#1B4332' }}>
            <Plus size={18} /> Add New Activity
          </button>
        </div>
      </div>

      {loading ? (
        <div className="card empty-state">
          <span className="spinner" style={{ margin: '0 auto 12px auto' }} />
          <p>Loading farm schedule tasks...</p>
        </div>
      ) : schedules.length === 0 ? (
        <div className="card empty-state">
          <div className="empty-icon">📅</div>
          <h3>No farm activities scheduled</h3>
          <p>Click <b>Add New Activity</b> to create your first farming task.</p>
        </div>
      ) : (
        <div className="grid-2">
          {schedules.map((item) => {
            const isDone = item.status === 'Completed';
            return (
              <div key={item.id} className={`schedule-card card ${isDone ? 'done-card' : ''}`}>
                <div className="sched-header">
                  <div className="flex-align gap-2">
                    <button onClick={() => handleToggleStatus(item)} className={`check-toggle-btn ${isDone ? 'checked' : ''}`}>
                      {isDone ? <Check size={14} color="#FFF" /> : <div className="dot" />}
                    </button>
                    <div>
                      <h3 className={`sched-title ${isDone ? 'strike' : ''}`}>{item.activity}</h3>
                      <span className="crop-tag">Crop: <b>{item.crop}</b></span>
                    </div>
                  </div>

                  <span className={`badge ${isDone ? 'badge-success' : 'badge-warning'}`}>
                    {item.status || 'Pending'}
                  </span>
                </div>

                <div className="sched-time-bar mt-3">
                  <span>📅 {item.date}</span>
                  <span>⏰ {item.time}</span>
                  <button onClick={() => handleDelete(item.id)} className="delete-btn" title="Delete Task">
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add Task Modal */}
      {showAddModal && (
        <div className="modal-backdrop">
          <div className="modal-content card" style={{ maxWidth: '480px' }}>
            <h3 className="mb-3">➕ Schedule Farming Task</h3>

            <form onSubmit={handleAdd}>
              <div className="form-group">
                <label className="form-label">Activity Description</label>
                <input
                  type="text"
                  className="form-input"
                  placeholder="e.g. Urea Top Dressing & Drip Watering"
                  value={newActivity.activity}
                  onChange={(e) => setNewActivity({ ...newActivity, activity: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Target Crop</label>
                <select
                  className="form-select"
                  value={newActivity.crop}
                  onChange={(e) => setNewActivity({ ...newActivity, crop: e.target.value })}
                >
                  <option value="Paddy">Paddy (Rice)</option>
                  <option value="Cotton">Cotton</option>
                  <option value="Red Chilli">Red Chilli</option>
                  <option value="Maize">Maize</option>
                  <option value="Groundnut">Groundnut</option>
                </select>
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label className="form-label">Date</label>
                  <input
                    type="date"
                    className="form-input"
                    value={newActivity.date}
                    onChange={(e) => setNewActivity({ ...newActivity, date: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Time</label>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="e.g. 09:00 AM"
                    value={newActivity.time}
                    onChange={(e) => setNewActivity({ ...newActivity, time: e.target.value })}
                  />
                </div>
              </div>

              <div className="flex-align gap-2 mt-3" style={{ justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => setShowAddModal(false)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Task
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style>{`
        .schedule-card { display: flex; flex-direction: column; }
        .done-card { opacity: 0.75; background: var(--bg-primary); }
        .sched-header { display: flex; justify-content: space-between; align-items: flex-start; }
        .sched-title { font-size: 1.05rem; font-weight: 700; color: var(--text-primary); }
        .sched-title.strike { text-decoration: line-through; }
        .crop-tag { font-size: 0.78rem; color: var(--text-secondary); }

        .check-toggle-btn {
          width: 24px; height: 24px; border-radius: 50%;
          border: 2px solid var(--brand-primary);
          background: transparent; cursor: pointer;
          display: flex; align-items: center; justify-content: center;
          flex-shrink: 0; margin-top: 2px;
        }

        .check-toggle-btn.checked { background: var(--brand-primary); }
        .check-toggle-btn .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--brand-primary); opacity: 0; }

        .sched-time-bar {
          display: flex; justify-content: space-between; align-items: center;
          padding-top: 10px; border-top: 1px dashed var(--border-color);
          font-size: 0.8rem; color: var(--text-secondary);
        }

        .delete-btn { background: transparent; border: none; color: var(--text-muted); cursor: pointer; }
        .delete-btn:hover { color: var(--accent-red); }
      `}</style>
    </div>
  );
};
