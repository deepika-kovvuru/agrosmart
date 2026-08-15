import React, { useState, useRef, useEffect } from 'react';
import { Bot, Send, Mic, MicOff, Volume2, User, Sparkles } from 'lucide-react';
import { askAI } from '../services/aiService';
import { useLanguage } from '../context/LanguageContext';

export const AIAssistant = () => {
  const { t } = useLanguage();
  const [messages, setMessages] = useState([
    {
      id: '1',
      sender: 'ai',
      text: 'Hello! I am your AgroSmart AI Assistant. Ask me anything about crop health, fertilizer schedules, irrigation, or pest protection!',
      timestamp: 'Just now',
    },
  ]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const chatEndRef = useRef(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isTyping]);

  const handleSend = async (textToSend) => {
    const query = textToSend || input.trim();
    if (!query) return;

    const userMsg = {
      id: Date.now().toString(),
      sender: 'user',
      text: query,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!textToSend) setInput('');
    setIsTyping(true);

    const res = await askAI(query);
    setIsTyping(false);

    const aiMsg = {
      id: (Date.now() + 1).toString(),
      sender: 'ai',
      text: res.response || 'Sorry, I could not process your request.',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, aiMsg]);
  };

  // Web Speech API Voice Recognition
  const toggleListening = () => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert('Speech recognition is not supported in this browser. Try Google Chrome.');
      return;
    }

    if (isListening) {
      setIsListening(false);
      return;
    }

    try {
      const recognition = new SpeechRecognition();
      recognition.lang = 'en-IN';
      recognition.continuous = false;
      recognition.interimResults = false;

      recognition.onstart = () => setIsListening(true);
      recognition.onresult = (e) => {
        const transcript = e.results[0][0].transcript;
        setInput(transcript);
        setIsListening(false);
        handleSend(transcript);
      };
      recognition.onerror = () => setIsListening(false);
      recognition.onend = () => setIsListening(false);

      recognition.start();
    } catch (e) {
      setIsListening(false);
    }
  };

  const speakText = (text) => {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.95;
      window.speechSynthesis.speak(utterance);
    }
  };

  return (
    <div className="ai-chat-page">
      <div className="hero-banner">
        <h1 className="hero-title">🤖 AgroSmart AI Assistant</h1>
        <p className="hero-subtitle">
          Ask questions by typing or speaking in your preferred language for instant agronomic solutions.
        </p>
      </div>

      <div className="chat-card card">
        <div className="messages-container">
          {messages.map((msg) => (
            <div key={msg.id} className={`chat-bubble-wrap ${msg.sender === 'user' ? 'user-wrap' : 'ai-wrap'}`}>
              <div className="avatar">
                {msg.sender === 'user' ? <User size={18} /> : <Bot size={18} />}
              </div>
              <div className="bubble">
                <p>{msg.text}</p>
                <div className="bubble-footer">
                  <span className="time">{msg.timestamp}</span>
                  {msg.sender === 'ai' && (
                    <button onClick={() => speakText(msg.text)} className="speak-btn" title="Listen Audio">
                      <Volume2 size={14} />
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}

          {isTyping && (
            <div className="chat-bubble-wrap ai-wrap">
              <div className="avatar"><Bot size={18} /></div>
              <div className="bubble typing-bubble">
                <span className="spinner" style={{ width: 16, height: 16 }} />
                <span>AgroSmart AI is thinking...</span>
              </div>
            </div>
          )}
          <div ref={chatEndRef} />
        </div>

        {/* Quick Suggestion Chips */}
        <div className="preset-chips">
          <button onClick={() => handleSend('Best fertilizer schedule for Paddy crop?')} className="chip">
            🌱 Paddy Fertilizer
          </button>
          <button onClick={() => handleSend('How to control whiteflies on Chilli?')} className="chip">
            🐛 Chilli Whitefly
          </button>
          <button onClick={() => handleSend('Water management for Cotton in black soil')} className="chip">
            💧 Cotton Irrigation
          </button>
        </div>

        {/* Input Bar */}
        <div className="chat-input-bar">
          <button
            onClick={toggleListening}
            className={`mic-btn ${isListening ? 'listening' : ''}`}
            title={isListening ? 'Listening...' : 'Voice Input'}
          >
            {isListening ? <MicOff size={20} color="#E53935" /> : <Mic size={20} />}
          </button>

          <input
            type="text"
            className="form-input chat-input"
            placeholder={isListening ? 'Listening to your voice...' : t('askAnything')}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
          />

          <button onClick={() => handleSend()} className="btn btn-primary send-btn">
            <Send size={18} />
          </button>
        </div>
      </div>

      <style>{`
        .chat-card {
          height: calc(100vh - 240px);
          min-height: 500px;
          display: flex;
          flex-direction: column;
          padding: 0;
          overflow: hidden;
        }

        .messages-container {
          flex: 1;
          padding: 20px;
          overflow-y: auto;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .chat-bubble-wrap {
          display: flex;
          gap: 12px;
          max-width: 80%;
        }

        .user-wrap {
          margin-left: auto;
          flex-direction: row-reverse;
        }

        .ai-wrap {
          margin-right: auto;
        }

        .avatar {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .user-wrap .avatar {
          background: var(--brand-primary);
          color: white;
        }

        .ai-wrap .avatar {
          background: var(--brand-mint);
          color: var(--brand-dark);
        }

        .bubble {
          background: var(--bg-primary);
          padding: 12px 16px;
          border-radius: 16px;
          font-size: 0.9rem;
          color: var(--text-primary);
          line-height: 1.45;
        }

        .user-wrap .bubble {
          background: var(--brand-primary);
          color: white;
          border-bottom-right-radius: 4px;
        }

        .ai-wrap .bubble {
          border-bottom-left-radius: 4px;
          border: 1px solid var(--border-color);
        }

        .bubble-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-top: 6px;
          font-size: 0.7rem;
          opacity: 0.75;
        }

        .speak-btn {
          background: transparent;
          border: none;
          color: var(--brand-primary);
          cursor: pointer;
          padding: 2px;
        }

        .typing-bubble {
          display: flex;
          align-items: center;
          gap: 8px;
          font-style: italic;
          color: var(--text-secondary);
        }

        .preset-chips {
          display: flex;
          gap: 8px;
          padding: 10px 16px;
          background: var(--bg-primary);
          overflow-x: auto;
          border-top: 1px solid var(--border-color);
        }

        .chip {
          padding: 6px 12px;
          background: var(--bg-surface);
          border: 1px solid var(--border-color);
          border-radius: var(--radius-full);
          font-size: 0.78rem;
          font-weight: 500;
          color: var(--text-secondary);
          cursor: pointer;
          white-space: nowrap;
        }

        .chip:hover {
          border-color: var(--brand-primary);
          color: var(--brand-primary);
        }

        .chat-input-bar {
          display: flex;
          gap: 10px;
          padding: 14px 16px;
          border-top: 1px solid var(--border-color);
          background: var(--bg-surface);
        }

        .chat-input {
          flex: 1;
        }

        .mic-btn {
          width: 44px;
          height: 44px;
          border-radius: 50%;
          border: 1px solid var(--border-color);
          background: var(--bg-primary);
          color: var(--text-secondary);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        }

        .mic-btn.listening {
          background: rgba(229, 57, 53, 0.15);
          animation: pulse 1s infinite alternate;
        }

        @keyframes pulse {
          to { transform: scale(1.08); }
        }

        .send-btn {
          padding: 0 18px;
        }
      `}</style>
    </div>
  );
};
