import React, { useState, useRef } from 'react';
import { Scan, Upload, Camera, AlertCircle, CheckCircle2, RefreshCw, Info, ShieldAlert } from 'lucide-react';
import { analyzeImage } from '../services/scannerService';
import { useLanguage } from '../context/LanguageContext';

export const SmartScanner = () => {
  const { t } = useLanguage();
  const [selectedFile, setSelectedFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const fileInputRef = useRef(null);

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setImagePreview(URL.createObjectURL(file));
      setResult(null);
    }
  };

  const handleScan = async () => {
    if (!selectedFile) return;
    setLoading(true);
    try {
      const data = await analyzeImage(selectedFile);
      setResult(data);
    } catch (e) {
      console.error(e);
      setResult({
        category: 'Error',
        is_agricultural: false,
        message: 'Could not complete image analysis. Please try again.',
      });
    } finally {
      setLoading(false);
    }
  };

  const resetScanner = () => {
    setSelectedFile(null);
    setImagePreview(null);
    setResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  return (
    <div className="scanner-page">
      <div className="hero-banner">
        <h1 className="hero-title">🔍 Smart AI Crop & Soil Scanner</h1>
        <p className="hero-subtitle">
          Upload a photo of your leaf, crop, pest, or soil for instant context-aware agricultural diagnosis.
        </p>
      </div>

      <div className="scanner-grid">
        {/* Upload Column */}
        <div className="card upload-card">
          <h3>1. Choose Image</h3>
          <p className="subtitle">Select a clear photo of your crop, leaf, pest, or soil sample.</p>

          <input
            type="file"
            ref={fileInputRef}
            accept="image/*"
            onChange={handleFileSelect}
            style={{ display: 'none' }}
          />

          <div
            className={`dropzone ${imagePreview ? 'has-preview' : ''}`}
            onClick={() => fileInputRef.current?.click()}
          >
            {imagePreview ? (
              <div className="preview-container">
                <img src={imagePreview} alt="Selected sample" className="preview-img" />
                <div className="preview-overlay">
                  <span>Click to change image</span>
                </div>
              </div>
            ) : (
              <div className="dropzone-content">
                <div className="dropzone-icon">
                  <Upload size={32} color="#2D6A4F" />
                </div>
                <h4>{t('uploadPhoto')}</h4>
                <p>Supports PNG, JPG, WEBP up to 10MB</p>
              </div>
            )}
          </div>

          <div className="scan-actions">
            <button
              onClick={() => fileInputRef.current?.click()}
              className="btn btn-secondary flex-1"
            >
              <Upload size={18} /> Select File
            </button>
            <button
              onClick={handleScan}
              disabled={!selectedFile || loading}
              className="btn btn-primary flex-1"
            >
              {loading ? (
                <>
                  <span className="spinner" /> Analyzing...
                </>
              ) : (
                <>
                  <Scan size={18} /> {t('scanImage')}
                </>
              )}
            </button>
          </div>
        </div>

        {/* Results Column */}
        <div className="card result-card">
          <h3>2. AI Diagnosis Report</h3>

          {loading ? (
            <div className="empty-state">
              <span className="spinner" style={{ width: 36, height: 36, margin: '0 auto 16px auto' }} />
              <h4>Analyzing Image Context...</h4>
              <p>Detecting subject type (Crop / Leaf / Soil / Face / Animal)...</p>
            </div>
          ) : !result ? (
            <div className="empty-state">
              <div className="empty-icon">🌱</div>
              <h4>Awaiting Image Scan</h4>
              <p>Upload a crop or soil sample on the left and click <b>Scan Image</b> to see recommendations.</p>
            </div>
          ) : result.category === 'Human Face' || result.is_agricultural === false ? (
            /* Human Face / Non-Agricultural Image Warning */
            <div className="result-box face-warning-box">
              <div className="warning-icon-wrap">
                <ShieldAlert size={40} color="#E53935" />
              </div>
              <h4 className="warning-title">Non-Agricultural Image Detected</h4>
              <p className="warning-message">
                {result.message || t('humanDetectedWarning')}
              </p>
              <div className="warning-tips">
                <h5>💡 For best results, please upload:</h5>
                <ul>
                  <li>🌿 Close-up of diseased leaf or stem</li>
                  <li>🐛 Insect or pest on crop</li>
                  <li>🤎 Soil sample or farm field photo</li>
                  <li>🍅 Harvested crop or fruit</li>
                </ul>
              </div>
            </div>
          ) : (
            /* Agricultural Analysis Result */
            <div className="result-box agri-success-box">
              <div className="result-header">
                <div>
                  <span className="badge badge-success mb-1">
                    Category: {result.category || 'Crop / Plant'}
                  </span>
                  <h3 className="diagnosis-name">{result.diagnosis || 'Leaf Spot Infection'}</h3>
                </div>
                <div className="confidence-pill">
                  <span>Confidence</span>
                  <strong>{Math.round((result.confidence || 0.92) * 100)}%</strong>
                </div>
              </div>

              <div className="severity-bar-wrap mb-3">
                <span className="sev-label">Severity Level: <b>{result.severity || 'Moderate'}</b></span>
                <div className="sev-progress">
                  <div className={`sev-fill ${result.severity === 'High' ? 'high' : 'medium'}`} />
                </div>
              </div>

              <div className="detail-section mb-3">
                <h4><Info size={16} /> Observations & Diagnosis</h4>
                <p>{result.description || 'Chlorosis spotted with dark concentric rings on mature leaves.'}</p>
              </div>

              <div className="detail-section mb-3">
                <h4><CheckCircle2 size={16} color="#2D6A4F" /> Recommended Treatment</h4>
                <p>{result.recommendation || 'Apply Chlorpyrifos 20 EC @ 2ml/L water during evening. Ensure adequate soil moisture.'}</p>
              </div>

              <button onClick={resetScanner} className="btn btn-outline w-full mt-2">
                <RefreshCw size={16} /> Scan Another Sample
              </button>
            </div>
          )}
        </div>
      </div>

      <style>{`
        .scanner-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 24px;
        }

        @media (min-width: 1024px) {
          .scanner-grid {
            grid-template-columns: 1fr 1fr;
          }
        }

        .dropzone {
          border: 2px dashed var(--border-color);
          border-radius: var(--radius-md);
          padding: 30px 20px;
          text-align: center;
          cursor: pointer;
          transition: var(--transition);
          margin: 16px 0;
          background: var(--bg-primary);
          min-height: 240px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .dropzone:hover {
          border-color: var(--brand-primary);
          background: var(--brand-mint);
        }

        .dropzone-icon {
          width: 56px;
          height: 56px;
          border-radius: 50%;
          background: rgba(45, 106, 79, 0.1);
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 12px auto;
        }

        .has-preview {
          padding: 0;
          border: 1px solid var(--border-color);
          overflow: hidden;
        }

        .preview-container {
          position: relative;
          width: 100%;
          height: 260px;
        }

        .preview-img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .preview-overlay {
          position: absolute;
          inset: 0;
          background: rgba(0, 0, 0, 0.4);
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          opacity: 0;
          transition: var(--transition);
          font-weight: 600;
        }

        .preview-container:hover .preview-overlay {
          opacity: 1;
        }

        .scan-actions {
          display: flex;
          gap: 12px;
        }

        .flex-1 { flex: 1; }
        .w-full { width: 100%; }

        .face-warning-box {
          background: rgba(229, 57, 53, 0.08);
          border: 1px solid var(--accent-red);
          border-radius: var(--radius-md);
          padding: 24px;
          text-align: center;
        }

        .warning-icon-wrap {
          margin-bottom: 12px;
        }

        .warning-title {
          font-size: 1.1rem;
          font-weight: 700;
          color: var(--accent-red);
          margin-bottom: 8px;
        }

        .warning-message {
          font-size: 0.9rem;
          color: var(--text-primary);
          line-height: 1.5;
          margin-bottom: 16px;
        }

        .warning-tips {
          text-align: left;
          background: var(--bg-surface);
          padding: 14px;
          border-radius: var(--radius-sm);

        }

        .warning-tips h5 {
          font-size: 0.85rem;
          margin-bottom: 8px;
        }

        .warning-tips ul {
          list-style: none;
          font-size: 0.825rem;
        }

        .warning-tips li {
          margin-bottom: 4px;
        }

        .agri-success-box {
          display: flex;
          flex-direction: column;
        }

        .result-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 16px;
        }

        .diagnosis-name {
          font-size: 1.25rem;
          font-weight: 800;
          color: var(--brand-primary);
        }

        .confidence-pill {
          background: var(--brand-mint);
          padding: 6px 12px;
          border-radius: var(--radius-sm);
          text-align: center;
          font-size: 0.75rem;
          color: var(--brand-dark);
        }

        .confidence-pill strong {
          display: block;
          font-size: 1rem;
        }

        .sev-label {
          font-size: 0.8rem;
          color: var(--text-secondary);
        }

        .sev-progress {
          height: 8px;
          background: var(--border-color);
          border-radius: var(--radius-full);
          overflow: hidden;
          margin-top: 4px;
        }

        .sev-fill {
          height: 100%;
          border-radius: var(--radius-full);
        }

        .sev-fill.medium { width: 50%; background: var(--accent-orange); }
        .sev-fill.high { width: 85%; background: var(--accent-red); }

        .detail-section {
          background: var(--bg-primary);
          padding: 12px 14px;
          border-radius: var(--radius-sm);
        }

        .detail-section h4 {
          font-size: 0.85rem;
          display: flex;
          align-items: center;
          gap: 6px;
          color: var(--brand-primary);
          margin-bottom: 4px;
        }

        .detail-section p {
          font-size: 0.85rem;
          color: var(--text-primary);
          line-height: 1.4;
        }
      `}</style>
    </div>
  );
};
