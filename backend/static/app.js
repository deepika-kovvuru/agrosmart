// AgroSmart Web Application Logic & View Controller

const App = {
  currentView: 'home',
  authMode: 'login', // 'login' or 'signup'
  marketChart: null,

  async init() {
    console.log('[AgroSmart] Initializing Web App...');
    
    // Theme setup
    if (AppTranslations.isDark) {
      document.body.classList.add('dark-theme');
      document.getElementById('theme-toggle').innerHTML = '<i class="fa-solid fa-sun"></i>';
    }

    // Languages setup
    this.populateLanguageDropdown();

    // Event listeners
    this.bindEvents();

    // Load active session user if available
    await window.api.getCurrentUser();
    this.updateUserUI();

    // Load home view initially
    this.switchView('home');
  },

  populateLanguageDropdown() {
    const select = document.getElementById('language-select');
    select.innerHTML = '';
    AppTranslations.languages.forEach((lang, idx) => {
      const opt = document.createElement('option');
      opt.value = idx;
      opt.textContent = lang;
      if (idx === AppTranslations.currentLangIndex) opt.selected = true;
      select.appendChild(opt);
    });

    select.addEventListener('change', (e) => {
      const idx = parseInt(e.target.value, 10);
      AppTranslations.setLanguage(idx);
      this.translateUI();
    });
  },

  translateUI() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      el.textContent = AppTranslations.t(key);
    });
  },

  bindEvents() {
    // Navigation items
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        const view = item.getAttribute('data-view');
        this.switchView(view);
        // Mobile drawer close
        document.getElementById('sidebar').classList.remove('open');
      });
    });

    // Mobile sidebar toggle
    document.getElementById('mobile-toggle').addEventListener('click', () => {
      document.getElementById('sidebar').classList.toggle('open');
    });

    // Theme toggle
    document.getElementById('theme-toggle').addEventListener('click', () => {
      const isDark = document.body.classList.toggle('dark-theme');
      AppTranslations.toggleDarkMode(isDark);
      document.getElementById('theme-toggle').innerHTML = isDark ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
    });

    // Auth Action Btn
    document.getElementById('auth-action-btn').addEventListener('click', () => {
      if (window.api.currentUser) {
        window.api.logout().then(() => {
          this.updateUserUI();
          this.switchView('home');
        });
      } else {
        this.openModal('auth-modal');
      }
    });

    // Market Filters
    document.getElementById('market-search').addEventListener('input', () => this.filterMarketPrices());
    document.getElementById('market-state-filter').addEventListener('change', () => this.filterMarketPrices());
    document.getElementById('market-category-filter').addEventListener('change', () => this.filterMarketPrices());

    // Advisory Search
    document.getElementById('advisory-search').addEventListener('input', (e) => this.filterAdvisories(e.target.value));
  },

  updateUserUI() {
    const u = window.api.currentUser;
    const authBtnText = document.getElementById('auth-btn-text');
    const authBtn = document.getElementById('auth-action-btn');
    const avatar = document.getElementById('sidebar-avatar');
    const username = document.getElementById('sidebar-username');
    const userloc = document.getElementById('sidebar-userloc');

    if (u) {
      authBtnText.textContent = 'Sign Out';
      authBtn.style.background = '#ef4444';
      avatar.textContent = u.name.charAt(0).toUpperCase();
      username.textContent = u.name;
      userloc.innerHTML = `<i class="fa-solid fa-location-dot"></i> ${u.state || 'Andhra Pradesh'}`;
    } else {
      authBtnText.textContent = 'Sign In';
      authBtn.style.background = 'var(--primary)';
      avatar.textContent = 'G';
      username.textContent = 'Guest Farmer';
      userloc.innerHTML = `<i class="fa-solid fa-location-dot"></i> Kurnool, AP`;
    }
  },

  switchView(viewName) {
    this.currentView = viewName;
    document.querySelectorAll('.view-section').forEach(sec => sec.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(nav => nav.classList.remove('active'));

    const targetView = document.getElementById(`view-${viewName}`);
    const targetNav = document.querySelector(`.nav-item[data-view="${viewName}"]`);
    if (targetView) targetView.classList.add('active');
    if (targetNav) targetNav.classList.add('active');

    // Update Header Title
    const titleMap = {
      home: 'AgroSmart Dashboard',
      advisory: 'Personalized Crop Advisories',
      pest: 'Pest & Disease Management',
      market: 'APMC Live Mandi Prices',
      weather: 'Weather Forecast & Alerts',
      news: 'Farming Tips & Agriculture News',
      chat: 'AgroBot AI Smart Assistant',
      schedule: 'Farm Activity Schedule',
      profile: 'User Profile & Farm Details'
    };
    document.getElementById('page-title').textContent = titleMap[viewName] || 'AgroSmart';

    // Load view specific data
    switch(viewName) {
      case 'home': this.loadHomeData(); break;
      case 'advisory': this.loadAdvisoryData(); break;
      case 'pest': this.loadPestData(); break;
      case 'market': this.loadMarketData(); break;
      case 'weather': this.loadWeatherData(); break;
      case 'news': this.loadNewsData(); break;
      case 'schedule': this.loadScheduleData(); break;
      case 'profile': this.loadProfileData(); break;
    }
  },

  // --- HOME DATA ---
  async loadHomeData() {
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    const advisories = await window.api.getCropAdvisories(userId);
    const schedule = await window.api.getFarmSchedule(userId);

    // Render Home Advisories
    const advList = document.getElementById('home-advisories-list');
    advList.innerHTML = advisories.slice(0, 3).map(a => `
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: var(--bg-main); border-radius: var(--radius-md);">
        <div style="display: flex; align-items: center; gap: 12px;">
          <span style="font-size: 24px;">${a.emoji || '🌾'}</span>
          <div>
            <div style="font-weight: 700; font-size: 14px;">${a.crop}: ${a.title}</div>
            <div style="font-size: 12px; color: var(--text-muted); text-overflow: ellipsis; white-space: nowrap; overflow: hidden; max-width: 280px;">${a.description}</div>
          </div>
        </div>
        <span class="badge ${a.priority === 'High' ? 'badge-high' : 'badge-medium'}">${a.priority}</span>
      </div>
    `).join('');

    // Render Home Tasks
    const taskList = document.getElementById('home-tasks-list');
    taskList.innerHTML = schedule.slice(0, 3).map(s => `
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: var(--bg-main); border-radius: var(--radius-md);">
        <div style="display: flex; align-items: center; gap: 12px;">
          <i class="fa-regular ${s.status === 'completed' ? 'fa-circle-check' : 'fa-clock'}" style="color: ${s.status === 'completed' ? 'var(--primary)' : 'var(--accent)'}; font-size: 18px;"></i>
          <div>
            <div style="font-weight: 700; font-size: 14px; ${s.status === 'completed' ? 'text-decoration: line-through; opacity: 0.7;' : ''}">${s.activity}</div>
            <div style="font-size: 11px; color: var(--text-muted);">${s.scheduled_at}</div>
          </div>
        </div>
        <span class="badge ${s.status === 'completed' ? 'badge-success' : 'badge-info'}">${s.status}</span>
      </div>
    `).join('');
  },

  // --- CROP ADVISORIES ---
  advisoriesCache: [],
  async loadAdvisoryData() {
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    this.advisoriesCache = await window.api.getCropAdvisories(userId);
    this.renderAdvisories(this.advisoriesCache);
  },

  renderAdvisories(list) {
    const container = document.getElementById('advisory-cards-container');
    container.innerHTML = list.map(a => `
      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 32px;">${a.emoji || '🌾'}</span>
            <div>
              <div style="font-weight: 800; font-size: 16px;">${a.crop}</div>
              <div style="font-size: 12px; color: var(--text-muted);">${a.title}</div>
            </div>
          </div>
          <span class="badge ${a.priority === 'High' ? 'badge-high' : 'badge-medium'}">${a.priority}</span>
        </div>
        <p style="font-size: 13px; color: var(--text-main); line-height: 1.6; margin-bottom: 14px;">${a.description}</p>
        <button class="btn-secondary" style="width: 100%; font-size: 12px;" onclick="alert('Detailed guidelines for ${a.crop}: Keep soil moisture maintained and check leaf undersides twice weekly.')">View Guidelines</button>
      </div>
    `).join('');
  },

  filterAdvisories(query) {
    const q = query.toLowerCase();
    const filtered = this.advisoriesCache.filter(a => a.crop.toLowerCase().includes(q) || a.title.toLowerCase().includes(q) || a.description.toLowerCase().includes(q));
    this.renderAdvisories(filtered);
  },

  // --- PEST MANAGEMENT & SCANNER ---
  async loadPestData() {
    const alerts = await window.api.getPestAlerts();
    const treatments = await window.api.getTreatments();

    const alertsList = document.getElementById('pest-alerts-list');
    alertsList.innerHTML = alerts.map(p => `
      <div style="padding: 12px 16px; background: var(--bg-main); border-radius: var(--radius-md); border-left: 4px solid var(--danger);">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
          <div style="font-weight: 800; font-size: 14px;">${p.crop} - ${p.pest_name}</div>
          <span class="badge badge-high">${p.severity}</span>
        </div>
        <div style="font-size: 12px; color: var(--text-muted); margin-bottom: 6px;">Region: ${p.region}</div>
        <div style="font-size: 13px;">${p.description}</div>
        <div style="font-size: 12px; font-weight: 700; color: var(--primary); margin-top: 6px;">Recommended Action: ${p.treatment}</div>
      </div>
    `).join('');

    const treatList = document.getElementById('treatments-list');
    treatList.innerHTML = treatments.map(t => `
      <div style="padding: 12px 16px; background: var(--bg-main); border-radius: var(--radius-md); border-left: 4px solid var(--info);">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
          <div style="font-weight: 800; font-size: 14px;">${t.name}</div>
          <span class="badge badge-info">${t.type}</span>
        </div>
        <div style="font-size: 12px; color: var(--text-muted); margin-bottom: 4px;">Target: ${t.crop || 'All Crops'}</div>
        <div style="font-size: 13px;">${t.description}</div>
      </div>
    `).join('');
  },

  async handlePestImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append('image', file);

    const res = await window.api.analyzePestImage(formData);
    if (res) {
      document.getElementById('pest-res-title').textContent = res.pest_name || 'Crop Leaf Analysis';
      document.getElementById('pest-res-confidence').textContent = `Confidence Score: ${res.confidence || '94%'}`;
      document.getElementById('pest-res-symptoms').textContent = res.symptoms || 'Symptoms identified on crop leaf.';
      document.getElementById('pest-res-organic').textContent = res.organic_treatment || 'Apply organic neem oil solution.';
      document.getElementById('pest-res-chemical').textContent = res.chemical_treatment || 'Apply recommended chemical fungicide.';
      this.openModal('pest-result-modal');
    }
  },

  // --- MARKET PRICES ---
  marketPricesCache: [],
  async loadMarketData() {
    this.marketPricesCache = await window.api.getMarketPrices();
    this.populateMarketFilters();
    this.filterMarketPrices();
    this.renderMarketChart();
  },

  populateMarketFilters() {
    const stateSelect = document.getElementById('market-state-filter');
    const catSelect = document.getElementById('market-category-filter');

    const states = [...new Set(this.marketPricesCache.map(p => p.state).filter(Boolean))];
    const cats = [...new Set(this.marketPricesCache.map(p => p.category).filter(Boolean))];

    stateSelect.innerHTML = '<option value="ALL">All States</option>' + states.map(s => `<option value="${s}">${s}</option>`).join('');
    catSelect.innerHTML = '<option value="ALL">All Categories</option>' + cats.map(c => `<option value="${c}">${c}</option>`).join('');
  },

  filterMarketPrices() {
    const q = document.getElementById('market-search').value.toLowerCase();
    const st = document.getElementById('market-state-filter').value;
    const cat = document.getElementById('market-category-filter').value;

    const filtered = this.marketPricesCache.filter(p => {
      const matchesQ = (p.commodity || '').toLowerCase().includes(q) || (p.mandi || '').toLowerCase().includes(q);
      const matchesSt = st === 'ALL' || p.state === st;
      const matchesCat = cat === 'ALL' || p.category === cat;
      return matchesQ && matchesSt && matchesCat;
    });

    const grid = document.getElementById('market-prices-grid');
    grid.innerHTML = filtered.map(p => `
      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
          <div>
            <div style="font-weight: 800; font-size: 16px;">${p.commodity}</div>
            <div style="font-size: 12px; color: var(--text-muted);">${p.mandi}, ${p.state || 'India'}</div>
          </div>
          <span class="badge ${p.trend && p.trend.includes('-') ? 'badge-high' : 'badge-success'}">${p.trend || '+1.5%'}</span>
        </div>
        <div style="margin-top: 14px; display: flex; align-items: baseline; gap: 8px;">
          <div style="font-size: 26px; font-weight: 900; color: var(--primary);">₹${p.modal_price || p.current_price}</div>
          <div style="font-size: 12px; color: var(--text-muted);">${p.unit || '₹/quintal'}</div>
        </div>
        <div style="font-size: 12px; color: var(--text-muted); margin-top: 6px;">Prev Price: ₹${p.previous_price || p.prev_price || p.modal_price - 50}</div>
      </div>
    `).join('');
  },

  renderMarketChart() {
    const ctx = document.getElementById('marketChart').getContext('2d');
    if (this.marketChart) this.marketChart.destroy();

    this.marketChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [{
          label: 'Paddy (Dhan) Price (₹/Quintal)',
          data: [2250, 2280, 2300, 2310, 2330, 2340, 2350],
          borderColor: '#2d6a4f',
          backgroundColor: 'rgba(45, 106, 79, 0.1)',
          fill: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: true } }
      }
    });
  },

  // --- WEATHER VIEW ---
  loadWeatherData() {
    const days = [
      { day: 'Thursday', temp: '34° / 20°', condition: 'Partly Cloudy', icon: 'fa-cloud-sun' },
      { day: 'Friday', temp: '29° / 18°', condition: 'Heavy Rain Warning', icon: 'fa-cloud-showers-heavy' },
      { day: 'Saturday', temp: '31° / 19°', condition: 'Moderate Rain', icon: 'fa-cloud-rain' },
      { day: 'Sunday', temp: '33° / 21°', condition: 'Clear Sky', icon: 'fa-sun' },
      { day: 'Monday', temp: '35° / 22°', condition: 'Heat Advisory', icon: 'fa-temperature-high' },
      { day: 'Tuesday', temp: '34° / 21°', condition: 'Mostly Sunny', icon: 'fa-cloud-sun' },
      { day: 'Wednesday', temp: '32° / 20°', condition: 'Scattered Showers', icon: 'fa-cloud-sun-rain' }
    ];

    const container = document.getElementById('weather-7day-container');
    container.innerHTML = days.map(d => `
      <div style="padding: 16px; background: var(--bg-main); border-radius: var(--radius-md); text-align: center;">
        <div style="font-weight: 700; font-size: 14px; margin-bottom: 8px;">${d.day}</div>
        <i class="fa-solid ${d.icon}" style="font-size: 28px; color: var(--primary); margin-bottom: 8px;"></i>
        <div style="font-weight: 800; font-size: 15px;">${d.temp}</div>
        <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">${d.condition}</div>
      </div>
    `).join('');
  },

  // --- NEWS & TIPS ---
  async loadNewsData() {
    const news = await window.api.getLiveNews();
    const tips = await window.api.getFarmingTips();

    const newsList = document.getElementById('news-articles-list');
    newsList.innerHTML = news.map(n => `
      <div style="padding: 12px 14px; background: var(--bg-main); border-radius: var(--radius-md);">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
          <span class="badge badge-info">${n.category}</span>
          <span style="font-size: 11px; color: var(--text-muted);">${n.published_at}</span>
        </div>
        <div style="font-weight: 800; font-size: 14px; margin: 4px 0;">${n.title}</div>
        <div style="font-size: 13px; color: var(--text-muted);">${n.summary}</div>
        <div style="font-size: 11px; color: var(--primary); margin-top: 6px; font-weight: 700;">Source: ${n.source || 'Agri News'}</div>
      </div>
    `).join('');

    const tipsList = document.getElementById('farming-tips-list');
    tipsList.innerHTML = tips.map(t => `
      <div style="padding: 12px 14px; background: var(--bg-main); border-radius: var(--radius-md);">
        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
          <span style="font-size: 20px;">${t.icon || '💡'}</span>
          <div style="font-weight: 800; font-size: 14px;">${t.title}</div>
        </div>
        <div style="font-size: 13px; color: var(--text-muted);">${t.description}</div>
      </div>
    `).join('');
  },

  async refreshNews() {
    await window.api.getLiveNews();
    this.loadNewsData();
  },

  // --- AGROBOT AI CHAT ---
  async sendChatMessage() {
    const input = document.getElementById('chat-input');
    const prompt = input.value.trim();
    if (!prompt) return;

    const messages = document.getElementById('chat-messages');
    messages.innerHTML += `<div class="message-bubble user">${prompt}</div>`;
    input.value = '';
    messages.scrollTop = messages.scrollHeight;

    const typingId = 'typing-' + Date.now();
    messages.innerHTML += `<div class="message-bubble bot" id="${typingId}"><i>AgroBot is analyzing your request...</i></div>`;
    messages.scrollTop = messages.scrollHeight;

    const res = await window.api.askAi(prompt);
    document.getElementById(typingId).remove();

    messages.innerHTML += `<div class="message-bubble bot">${(res.answer || res.message || 'Thank you for asking AgroBot.').replace(/\n/g, '<br>')}</div>`;
    messages.scrollTop = messages.scrollHeight;
  },

  // --- FARM SCHEDULE ---
  async loadScheduleData() {
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    const schedule = await window.api.getFarmSchedule(userId);
    const container = document.getElementById('full-schedule-list');

    container.innerHTML = schedule.map(s => `
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; background: var(--bg-main); border-radius: var(--radius-md);">
        <div style="display: flex; align-items: center; gap: 14px;">
          <input type="checkbox" ${s.status === 'completed' ? 'checked' : ''} onchange="App.toggleTaskStatus(${s.id}, this.checked)" style="width: 18px; height: 18px; cursor: pointer;">
          <div>
            <div style="font-weight: 800; font-size: 15px; ${s.status === 'completed' ? 'text-decoration: line-through; opacity: 0.6;' : ''}">${s.activity}</div>
            <div style="font-size: 12px; color: var(--text-muted);"><i class="fa-regular fa-clock"></i> ${s.scheduled_at}</div>
          </div>
        </div>
        <button class="btn-secondary" style="color: var(--danger); border-color: var(--danger-light); padding: 4px 10px; font-size: 12px;" onclick="App.deleteTask(${s.id})"><i class="fa-solid fa-trash"></i></button>
      </div>
    `).join('');
  },

  async toggleTaskStatus(id, isChecked) {
    await window.api.updateFarmScheduleStatus(id, isChecked ? 'completed' : 'pending');
    this.loadScheduleData();
  },

  async deleteTask(id) {
    await window.api.deleteFarmSchedule(id);
    this.loadScheduleData();
  },

  async saveNewTask(event) {
    event.preventDefault();
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    const desc = document.getElementById('task-desc').value;
    const time = document.getElementById('task-time').value;

    await window.api.addFarmSchedule({ user_id: userId, activity: desc, scheduled_at: time });
    this.closeModal('add-task-modal');
    this.loadScheduleData();
  },

  // --- PROFILE & FARM DETAILS ---
  async loadProfileData() {
    const u = window.api.currentUser || { name: 'Farmer Deepika', phone: '9876543210', state: 'Andhra Pradesh', id: 1 };
    document.getElementById('prof-name').value = u.name || '';
    document.getElementById('prof-phone').value = u.phone || '';
    document.getElementById('prof-state').value = u.state || '';

    const farm = await window.api.getFarmDetails(u.id || 1);
    document.getElementById('farm-area').value = farm.land_area || 5.5;
    document.getElementById('farm-crops').value = farm.primary_crops || 'Paddy, Cotton, Tomato';
    document.getElementById('farm-soil').value = farm.soil_type || 'Black Soil';
    document.getElementById('farm-irrigation').value = farm.irrigation || 'Drip Irrigation';
  },

  async saveProfile(event) {
    event.preventDefault();
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    const name = document.getElementById('prof-name').value;
    const phone = document.getElementById('prof-phone').value;
    const state = document.getElementById('prof-state').value;

    await window.api.updateProfile(userId, { name, phone, state });
    this.updateUserUI();
    alert('Profile updated successfully!');
  },

  async saveFarmDetails(event) {
    event.preventDefault();
    const userId = window.api.currentUser ? window.api.currentUser.id : 1;
    const land_area = document.getElementById('farm-area').value;
    const primary_crops = document.getElementById('farm-crops').value;
    const soil_type = document.getElementById('farm-soil').value;
    const irrigation = document.getElementById('farm-irrigation').value;

    await window.api.updateFarmDetails(userId, { land_area, primary_crops, soil_type, irrigation });
    alert('Farm details saved successfully!');
  },

  // --- AUTH MODAL FLOW ---
  toggleAuthMode() {
    this.authMode = this.authMode === 'login' ? 'signup' : 'login';
    const isSignup = this.authMode === 'signup';

    document.getElementById('auth-modal-title').textContent = isSignup ? 'Create AgroSmart Account' : 'Sign In to AgroSmart';
    document.getElementById('name-group').style.display = isSignup ? 'block' : 'none';
    document.getElementById('phone-group').style.display = isSignup ? 'block' : 'none';
    document.getElementById('confirm-password-group').style.display = isSignup ? 'block' : 'none';
    document.getElementById('auth-submit-btn').textContent = isSignup ? 'Create Account' : 'Sign In';
    document.getElementById('auth-toggle-text').textContent = isSignup ? 'Already have an account?' : "Don't have an account?";
  },

  async handleAuthSubmit(event) {
    event.preventDefault();
    const email = document.getElementById('auth-email').value;
    const password = document.getElementById('auth-password').value;

    if (this.authMode === 'login') {
      const res = await window.api.login(email, password);
      if (res.success) {
        this.closeModal('auth-modal');
        this.updateUserUI();
        this.switchView('home');
      } else {
        alert(res.error || 'Login failed');
      }
    } else {
      const name = document.getElementById('auth-name').value;
      const phone = document.getElementById('auth-phone').value;
      const confirmPassword = document.getElementById('auth-confirm-password').value;

      const res = await window.api.signup({ name, email, phone, password, confirmPassword });
      if (res.success) {
        alert('Registration successful! Please sign in.');
        this.toggleAuthMode();
      } else {
        alert(res.error || 'Registration failed');
      }
    }
  },

  // --- MODAL HELPERS ---
  openModal(id) {
    document.getElementById(id).classList.add('active');
  },

  closeModal(id) {
    document.getElementById(id).classList.remove('active');
  }
};

document.addEventListener('DOMContentLoaded', () => App.init());
