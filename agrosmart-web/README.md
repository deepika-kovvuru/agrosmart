# AGROSMART Web Project (`agrosmart-web`)

Complete production-ready web application for **AGROSMART**, built with React + Vite frontend and Flask backend, sharing the single PostgreSQL/SQLite database architecture with the mobile application.

---

## 🏗️ Project Structure

```text
agrosmart-web/
├── frontend/                (React + Vite + Recharts + Lucide Icons)
│   ├── src/
│   │   ├── assets/          (Brand images & icons)
│   │   ├── components/      (Navbar, Sidebar, Header, PriceHistoryModal, FloatingAIFab)
│   │   ├── context/         (AuthContext, ThemeContext, LanguageContext)
│   │   ├── hooks/           (useFetch, useOfflineStatus)
│   │   ├── layouts/         (MainLayout, AuthLayout)
│   │   ├── pages/           (Login, Signup, HomeDashboard, MarketPrices, SmartScanner, WeatherForecast, CropAdvisory, PestManagement, FarmDetails, FarmSchedule, FarmingTipsAndNews, AIAssistant, ProfileSettings)
│   │   ├── services/        (api.js, authService.js, marketService.js, cropService.js, pestService.js, farmService.js, scannerService.js, newsService.js, aiService.js, weatherService.js)
│   │   └── styles/          (1:1 Mobile Theme Palette, Dark Mode)
│   ├── .env                 (VITE_API_BASE_URL=http://localhost:5000)
│   ├── .env.example
│   └── package.json
├── backend/
│   ├── app.py               (Flask entrypoint wrapper)
│   ├── agrosmart_app.py     (Core Flask application with SQLAlchemy & APIs)
│   ├── requirements.txt
│   └── Procfile
└── README.md
```

---

## ⚡ How to Run Locally

### 1. Run Backend Server (Flask)
```bash
cd agrosmart-web/backend
pip install -r requirements.txt
python app.py
```
*Backend runs on `http://localhost:5000`*

### 2. Run Frontend Web App (Vite React)
```bash
cd agrosmart-web/frontend
npm install
npm run dev
```
*Frontend runs on `http://localhost:5173`*

---

## 🌟 Key Features & Endpoints Covered

- **Authentication**: `POST /signup`, `POST /login`, `GET /get_current_user`, `POST /logout`.
- **Market Prices & 30-Day History Chart**: `GET /api/states`, `GET /api/mandis`, `GET /api/market-prices`, `GET /api/price-history` (interactive 30-day Recharts line graph).
- **Smart Image Analysis**: `POST /api/analyze-image` with multipart `image` file. Includes human face guard:
  > *"This image appears to contain a person. Please upload a crop, leaf, fruit, pest, soil, or farm image for agricultural analysis."*
- **Farm Details**: `GET /farm_details/<user_id>`, `PUT /farm_details/<user_id>`.
- **Farm Schedule**: Task scheduler (`GET`, `POST`, `PUT`, `DELETE /farm_schedule`).
- **Crop Advisory**: `GET`, `POST`, `DELETE /crop_advisories`.
- **Pest Alerts & Treatments**: `GET /pest_alerts`, `GET /treatments`.
- **Live RSS Agricultural News**: `GET /api/live-news`, `POST /api/live-news/refresh`.
- **AgroSmart AI Assistant**: `POST /api/ask-ai` with Web Speech API voice microphone input.
- **Profile & Settings**: `PUT /profile/<user_id>`, 6-language switcher, dark mode toggle.
