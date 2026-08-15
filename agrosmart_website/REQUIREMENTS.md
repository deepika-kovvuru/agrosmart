# AGROSMART Website — Requirements & System Specifications

This dedicated folder (`agrosmart_website/`) contains the complete standalone Web Application for **AGROSMART**, reproducing all features, screens, business logic, and UI elements of the AGROSMART Android Mobile Application (APK).

---

## 1. System Overview & Architecture

The AGROSMART Website operates on a single shared architecture connected directly to the existing cloud Flask backend and database:

```text
                           AGROSMART
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
      Android Mobile App                    AGROSMART Website
      (agrosmart.apk)                      (agrosmart_website/)
            │                                     │
            └──────────────────┬──────────────────┘
                               ▼
                        Flask Backend
            (https://agrosmart-app-service.onrender.com)
                               ▼
                      PostgreSQL Database
```

---

## 2. Technical Stack & Dependencies

- **Frontend Framework**: React 18 + Vite
- **UI & Design System**: Custom Vanilla CSS Tokens matching Mobile Theme (`#2D6A4F`, `#1B4332`, `#52B788`, `#E07B39`, `#E63946`)
- **Icons**: Lucide React (`lucide-react`)
- **Speech Recognition**: Web Speech API (`webkitSpeechRecognition` for microphone voice input)
- **Audio Output**: Web Speech Synthesis (`SpeechSynthesisUtterance`)
- **Backend API URL**: `https://agrosmart-app-service.onrender.com`
- **Database**: Shared Cloud Database (PostgreSQL on Render)

---

## 3. Web Feature Requirements & Screen Specifications

### 3.1 Authentication System
- **Login**: `POST /login` (Email or Mobile Number + Password).
- **Signup**: `POST /signup` (`name`, `email`, `phone`, `password`, `confirm_password`, `state`).
- **Session Persistence**: User token and session stored in `localStorage`.
- **Shared User Base**: Accounts created on the mobile app log in seamlessly on the website.

### 3.2 Home Dashboard
- **Welcome Banner**: Displays farmer name and registered state.
- **6 Quick Action Services**:
  1. 🌱 **Crop Advisory** (`#2D6A4F`)
  2. ⛅ **Weather Forecast** (`#4CC9F0`)
  3. 🐛 **Pest & Disease** (`#E63946`)
  4. 📈 **Market Prices** (`#F4A261`)
  5. 📰 **Farming Tips** (`#9B59B6`)
  6. 👤 **My Profile** (`#1ABC9C`)
- **Live Weather Summary Widget**: Temperature, humidity, rainfall, wind speed, spray advisory.
- **Live Mandi Price Highlights**: Real-time prices & trend indicators.
- **Live Agricultural News Ticker**: Latest RSS news articles.

### 3.3 State-Based Mandi Market Prices
- **Hierarchical Dropdown Filtering**: `State → Mandi Yard → Crop`.
- **Price Metrics**: Min Price, Max Price, Modal Price, Price Change (₹), Percentage Change (%).
- **Trend Badges**:
  - 📈 **Rising** (Green `▲`)
  - 📉 **Falling** (Red `▼`)
  - ➖ **Stable** (Blue)

### 3.4 Smart AI Image Scanner
- **File Upload & Live Camera Capture** connected to `POST /api/analyze-image`.
- **Human Face Protection Guard**:
  If a human face or person is detected, displays the exact warning:
  > *"This image appears to contain a person. Please upload a crop, leaf, fruit, pest, soil, or farm image for agricultural analysis."*
- **Crop/Soil Analysis**: For plant, leaf, pest, or soil samples, displays:
  - Category & Confidence Score (%)
  - Diagnosis Name
  - Severity Progress Level (Low / Moderate / High)
  - Detailed Observations & Symptoms
  - Actionable Chemical / Organic Treatment Advice

### 3.5 Weather & Forecast Module
- **Parameters**: Temperature (°C), Feels Like (°C), Humidity (%), Wind Speed (km/h), Rainfall Chance (%), UV Index.
- **5-Day Forecast Grid**: Weather icon, daily temp, rain probability.
- **Agro-Advisory Banner**: Spraying suitability advice.

### 3.6 Crop Advisory Module
- **Selection**: Crop (Paddy, Cotton, Chilli, Maize, Groundnut), Growth Stage, Soil Type.
- **Stage-Wise Advice Cards**:
  - Irrigation Schedule
  - Nutrient & Fertilizer Application
  - Pest & Disease Monitoring Alerts

### 3.7 Pest & Disease Management
- **Regional Pest Alerts**: Searchable list of active pest warnings by state/crop (`GET /pest_alerts`).
- **Control Information**: Symptoms, preventive protocols, and recommended treatments (`GET /treatments`).

### 3.8 Live RSS News & Farming Tips
- 🔴 **LIVE FEED** indicator with server cache refresh button (`GET /api/live-news`, `POST /api/live-news/refresh`).
- **Sources**: Krishi Jagran, PIB Agriculture Ministry, Down To Earth, Agri Farming, Google News.
- **Category Filters**: Market Update, Technology, Pest Alert, Policy, Climate.
- **Expert Farming Tips Tab**: Seed treatment, soil health, intercropping guides.

### 3.9 AgroSmart AI Assistant
- **Endpoint**: `POST /api/ask-ai`
- **Voice Speech Recognition**: Microphone voice input using Web Speech API.
- **Audio Output**: Voice readout for AI responses.
- **Floating AI FAB**: Floating action button accessible from all screens.

### 3.10 Profile & Settings
- Farmer details: Username, Phone, Registered State, Preferred Primary Crop (`PUT /profile/<user_id>`).
- **Multi-Language Selector**: English, Telugu (తెలుగు), Hindi (हिन्दी), Tamil (தமிழ்), Kannada (ಕನ್ನಡ), Marathi (मराठी).
- **Dark Mode**: Persistent dark theme toggle.

---

## 4. How to Run & Build

### Development Mode:
```bash
cd agrosmart_website
npm install
npm run dev
```
*Access at http://localhost:5173*

### Production Build:
```bash
npm run build
```
*Output folder: `agrosmart_website/dist/`*
