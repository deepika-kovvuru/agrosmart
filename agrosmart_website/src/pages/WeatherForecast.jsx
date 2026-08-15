import React, { useState, useEffect } from 'react';
import { CloudSun, Droplets, Wind, Thermometer, MapPin, AlertTriangle } from 'lucide-react';
import { getWeatherForecast } from '../services/weatherService';
import { useAuth } from '../context/AuthContext';

export const WeatherForecast = () => {
  const { user } = useAuth();
  const [location, setLocation] = useState(user?.state || 'Andhra Pradesh');
  const [data, setData] = useState(null);

  useEffect(() => {
    const fetchWeather = async () => {
      const res = await getWeatherForecast(location);
      setData(res);
    };
    fetchWeather();
  }, [location]);

  return (
    <div className="weather-page">
      <div className="hero-banner">
        <h1 className="hero-title">⛅ Live Weather & Agro-Advisory</h1>
        <p className="hero-subtitle">
          Real-time weather parameters, rainfall forecast, and agricultural spray advisories.
        </p>
      </div>

      <div className="card mb-4">
        <div className="flex-between">
          <div className="location-picker-wrap">
            <MapPin size={20} className="text-brand" />
            <select
              className="form-select"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
            >
              <option value="Andhra Pradesh">Andhra Pradesh</option>
              <option value="Telangana">Telangana</option>
              <option value="Karnataka">Karnataka</option>
              <option value="Tamil Nadu">Tamil Nadu</option>
              <option value="Maharashtra">Maharashtra</option>
            </select>
          </div>
        </div>
      </div>

      {data && (
        <>
          <div className="grid-2 mb-4">
            <div className="card main-weather-box">
              <div className="main-temp-wrap">
                <span className="big-temp">{data.temperature}°C</span>
                <span className="feels-like">Feels like {data.feels_like}°C</span>
                <h3 className="cond-title">{data.condition}</h3>
              </div>
              <div className="weather-icon-lg">⛅</div>
            </div>

            <div className="card metrics-grid">
              <div className="metric-box">
                <Droplets size={22} color="#2196F3" />
                <div>
                  <span className="m-label">Humidity</span>
                  <strong className="m-val">{data.humidity}%</strong>
                </div>
              </div>
              <div className="metric-box">
                <Wind size={22} color="#52B788" />
                <div>
                  <span className="m-label">Wind Speed</span>
                  <strong className="m-val">{data.wind_speed}</strong>
                </div>
              </div>
              <div className="metric-box">
                <CloudSun size={22} color="#E07B39" />
                <div>
                  <span className="m-label">Rain Probability</span>
                  <strong className="m-val">{data.rainfall_chance}</strong>
                </div>
              </div>
              <div className="metric-box">
                <Thermometer size={22} color="#E53935" />
                <div>
                  <span className="m-label">UV Index</span>
                  <strong className="m-val">{data.uv_index}</strong>
                </div>
              </div>
            </div>
          </div>

          <div className="card mb-4 advisory-card">
            <h3>🌾 Agricultural Spraying Advisory</h3>
            <p>{data.advisory}</p>
          </div>

          <div className="card">
            <h3 className="mb-3">📅 5-Day Weather Forecast</h3>
            <div className="forecast-grid grid-5">
              {data.forecast.map((f, i) => (
                <div key={i} className="forecast-item">
                  <span className="f-day">{f.day}</span>
                  <span className="f-icon">{f.icon}</span>
                  <span className="f-temp">{f.temp}</span>
                  <span className="f-rain">☔ {f.rain}</span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      <style>{`
        .flex-between { display: flex; justify-content: space-between; align-items: center; }
        .location-picker-wrap { display: flex; align-items: center; gap: 10px; width: 300px; }
        .text-brand { color: var(--brand-primary); }

        .main-weather-box {
          display: flex;
          justify-content: space-between;
          align-items: center;
          background: linear-gradient(135deg, var(--brand-mint) 0%, var(--bg-surface) 100%);
        }

        .big-temp { font-size: 3.5rem; font-weight: 800; color: var(--brand-primary); line-height: 1; display: block; }
        .feels-like { font-size: 0.85rem; color: var(--text-secondary); }
        .cond-title { font-size: 1.2rem; font-weight: 700; margin-top: 6px; }
        .weather-icon-lg { font-size: 5rem; }

        .metrics-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
        }

        .metric-box {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px;
          background: var(--bg-primary);
          border-radius: var(--radius-sm);
        }

        .m-label { font-size: 0.75rem; color: var(--text-secondary); display: block; }
        .m-val { font-size: 1rem; font-weight: 700; color: var(--text-primary); }

        .advisory-card {
          background: rgba(82, 183, 136, 0.1);
          border: 1px solid var(--brand-light);
        }

        .advisory-card h3 { font-size: 1rem; color: var(--brand-primary); margin-bottom: 6px; }
        .advisory-card p { font-size: 0.9rem; color: var(--text-primary); }

        .forecast-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; }
        @media (max-width: 640px) { .forecast-grid { grid-template-columns: repeat(2, 1fr); } }

        .forecast-item {
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 14px 8px;
          background: var(--bg-primary);
          border-radius: var(--radius-sm);
        }

        .f-day { font-weight: 700; font-size: 0.85rem; }
        .f-icon { font-size: 2rem; margin: 6px 0; }
        .f-temp { font-weight: 800; color: var(--brand-primary); font-size: 0.95rem; }
        .f-rain { font-size: 0.72rem; color: var(--text-secondary); margin-top: 2px; }
      `}</style>
    </div>
  );
};
