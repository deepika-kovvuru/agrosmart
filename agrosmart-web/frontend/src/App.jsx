import React, { useState } from 'react';
import { Bot } from 'lucide-react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { LanguageProvider } from './context/LanguageContext';

import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { BottomNav } from './components/BottomNav';

import { Login, Signup } from './pages/Login';
import { HomeDashboard } from './pages/HomeDashboard';
import { MarketPrices } from './pages/MarketPrices';
import { SmartScanner } from './pages/SmartScanner';
import { WeatherForecast } from './pages/WeatherForecast';
import { CropAdvisory } from './pages/CropAdvisory';
import { PestManagement } from './pages/PestManagement';
import { FarmDetails } from './pages/FarmDetails';
import { FarmSchedule } from './pages/FarmSchedule';
import { FarmingTipsAndNews } from './pages/FarmingTipsAndNews';
import { AIAssistant } from './pages/AIAssistant';
import { ProfileSettings } from './pages/ProfileSettings';

const MainAppContent = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState('home');
  const [authMode, setAuthMode] = useState('login');

  if (!user) {
    return authMode === 'login' ? (
      <Login onSwitchToSignup={() => setAuthMode('signup')} />
    ) : (
      <Signup onSwitchToLogin={() => setAuthMode('login')} />
    );
  }

  const getPageTitle = () => {
    switch (activeTab) {
      case 'home': return 'Home Dashboard';
      case 'prices': return 'Market Prices & Mandis';
      case 'advisory': return 'Crop Advisory';
      case 'scanner': return 'Smart Image Scanner';
      case 'pest': return 'Pest & Disease Management';
      case 'farm-details': return 'Farm Details';
      case 'farm-schedule': return 'Farm Schedule';
      case 'weather': return 'Weather & Forecast';
      case 'news': return 'Farming Tips & Live News';
      case 'ai': return 'AgroSmart AI Assistant';
      case 'profile': return 'Profile & Settings';
      default: return 'AgroSmart';
    }
  };

  const renderActiveScreen = () => {
    switch (activeTab) {
      case 'home': return <HomeDashboard setActiveTab={setActiveTab} />;
      case 'prices': return <MarketPrices />;
      case 'advisory': return <CropAdvisory />;
      case 'scanner': return <SmartScanner />;
      case 'pest': return <PestManagement />;
      case 'farm-details': return <FarmDetails />;
      case 'farm-schedule': return <FarmSchedule />;
      case 'weather': return <WeatherForecast />;
      case 'news': return <FarmingTipsAndNews />;
      case 'ai': return <AIAssistant />;
      case 'profile': return <ProfileSettings />;
      default: return <HomeDashboard setActiveTab={setActiveTab} />;
    }
  };

  return (
    <div className="app-container">
      {/* Desktop Sidebar Navigation */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main App Content Area */}
      <div className="main-content">
        <Header title={getPageTitle()} activeTab={activeTab} setActiveTab={setActiveTab} />
        <main className="page-container">
          {renderActiveScreen()}
        </main>
      </div>

      {/* Floating AI Assistant FAB */}
      {activeTab !== 'ai' && (
        <button
          onClick={() => setActiveTab('ai')}
          className="floating-ai-fab"
          title="AgroSmart Voice AI Assistant"
        >
          <Bot size={28} />
        </button>
      )}

      {/* Mobile Bottom Navigation */}
      <BottomNav activeTab={activeTab} setActiveTab={setActiveTab} />
    </div>
  );
};

export default function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <LanguageProvider>
          <MainAppContent />
        </LanguageProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}
