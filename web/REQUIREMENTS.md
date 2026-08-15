# AGROSMART Web Application — System Architecture & Text Requirements

This dedicated folder (`web/`) contains the standalone Web Application for **AGROSMART**, reproducing 100% of the mobile application's UI, features, logic, and texts.

---

## 1. Single Shared Backend Architecture

Both the **Mobile Application (`frontend/`)** and **Web Application (`web/`)** connect to the **SAME existing Flask backend**:

```text
                  ┌───────────────────────────────┐
                  │   Render Cloud PostgreSQL     │
                  └───────────────┬───────────────┘
                                  │
                       Existing Flask Backend
             (https://agrosmart-app-service.onrender.com)
                                  │
             ┌────────────────────┴────────────────────┐
             │                                         │
      ┌──────▼──────┐                           ┌──────▼──────┐
      │ Mobile App  │                           │ Web App     │
      │ (Flutter)   │                           │ (React/Vite)│
      │ `frontend/` │                           │ `web/`      │
      └─────────────┘                           └─────────────┘
```

> ⚠️ **NO duplicate backend or database is created.** Both clients share the single source of truth.

---

## 2. Shared API Service Connections

All web services call the existing Flask endpoints:

| Feature | Backend Endpoint | Request Type | Purpose |
|---|---|---|---|
| **Login** | `/login` | `POST` | Authenticate with Email/Phone + Password |
| **Signup** | `/signup` | `POST` | Register new farmer account |
| **Current User** | `/get_current_user` | `GET` | Get session profile details |
| **Update Profile** | `/profile/<id>` | `PUT` | Update state, phone, preferred crop |
| **States List** | `/api/states` | `GET` | Indian states dropdown |
| **Mandis List** | `/api/mandis` | `GET` | Mandi yards by state |
| **Market Prices** | `/api/market-prices` | `GET` | Min, Max, Modal prices & trends |
| **Image Analysis** | `/api/analyze-image` | `POST` | Smart Scanner image classification & face warning |
| **AI Assistant** | `/api/ask-ai` | `POST` | Agronomic query responses |
| **Live News** | `/api/live-news` | `GET` | Live RSS agricultural news feeds |
| **News Refresh** | `/api/live-news/refresh` | `POST` | Force refresh news cache |
| **Farming Tips** | `/farming_tips` | `GET` | Expert agronomic tips |
| **Pest Alerts** | `/pest_alerts` | `GET` | Active regional pest warnings |
| **Treatments** | `/treatments` | `GET` | Pest & disease treatment catalog |

---

## 3. Required Web Texts & Multi-Language Dictionary

All UI text, headings, badges, labels, error messages, and translations are defined in `src/utils/translations.js`:

### Key UI Strings Defined:
- **Header & Navigation**: `Home`, `Market Prices`, `Crop Advisory`, `Smart Scanner`, `Pest Management`, `Weather`, `Tips & News`, `AI Assistant`, `Profile & Settings`, `Log In`, `Sign Up`, `Log Out`.
- **Market Price Strings**: `Select State`, `Select Mandi Yard`, `Select Crop`, `Current Price`, `Min Price`, `Max Price`, `Modal Price`, `Rising`, `Falling`, `Stable`, `Last Updated`.
- **Smart Scanner Warning Text**:
  > *"This image appears to contain a person. Please upload a crop, leaf, fruit, pest, soil, or farm image for agricultural analysis."*
- **Weather Strings**: `Humidity`, `Rainfall`, `Wind Speed`, `Temperature`, `UV Index`, `Air Quality`, `5-Day Forecast`, `Spraying Advisory`.
- **Supported Languages**:
  1. 🇬🇧 English (`en`)
  2. 🇮🇳 Telugu (`te` - తెలుగు)
  3. 🇮🇳 Hindi (`hi` - हिन्दी)
  4. 🇮🇳 Tamil (`ta` - தமிழ்)
  5. 🇮🇳 Kannada (`kn` - ಕನ್ನಡ)
  6. 🇮🇳 Marathi (`mr` - मराठी)

---

## 4. How to Run

```bash
cd web
npm install
npm run dev
```

Open **http://localhost:5173** in Google Chrome or Edge.
