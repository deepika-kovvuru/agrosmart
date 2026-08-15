import React, { createContext, useContext, useState } from 'react';
import { translations, languages } from '../utils/translations';

const LanguageContext = createContext();

export const LanguageProvider = ({ children }) => {
  const [langCode, setLangCode] = useState(() => {
    return localStorage.getItem('agrosmart_lang') || 'en';
  });

  const changeLanguage = (code) => {
    setLangCode(code);
    localStorage.setItem('agrosmart_lang', code);
  };

  const t = (key) => {
    const dict = translations[langCode] || translations.en;
    return dict[key] || translations.en[key] || key;
  };

  return (
    <LanguageContext.Provider value={{ langCode, languages, changeLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => useContext(LanguageContext);
