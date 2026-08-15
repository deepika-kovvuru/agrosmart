// app.js - Same to Same Connected Mobile Clone Logic

const API_BASE = 'https://agrosmart-app-service.onrender.com';

// Global State
let currentUser = null;
let currentCrop = 'Paddy';
let currentMandi = '';
let currentMarketState = '';
let currentMarketCategory = 'All';
let currentOnboardingSlide = 0;
let priceChartInstance = null;
let chartSelectedCrop = '';
let chartSelectedMandi = '';

// Navigation Routing Controller
function navigateTo(screenId) {
    console.log(`Navigating to: ${screenId}`);
    
    // Hide all screens
    document.querySelectorAll('.screen-view').forEach(screen => {
        screen.classList.remove('active');
    });
    
    // Show targeted screen
    const targetScreen = document.getElementById(`screen-${screenId}`);
    if (targetScreen) {
        targetScreen.classList.add('active');
        
        // Hide all sliding overlays when switching root screens
        document.querySelectorAll('.sliding-overlay').forEach(overlay => {
            overlay.classList.remove('active');
        });
    }

    // Adapt status bar color based on screen headers
    const statusBar = document.querySelector('.phone-status-bar');
    if (['splash', 'login', 'register', 'home', 'crop_advisory', 'pest', 'market', 'tips', 'profile'].includes(screenId)) {
        statusBar.classList.remove('dark'); // White text for color gradients
    } else {
        statusBar.classList.add('dark');
    }
}

// DOM Setup
document.addEventListener('DOMContentLoaded', () => {
    setupOnboarding();
    setupAuthNavigation();
    setupQuickActions();
    setupTabs();
    setupProfileOverlays();
    setupScheduleDialog();
    setupAPIForms();
    setupWebPreferences();
    loadStatesDropdown();

    // Start Clock in Status Bar
    setInterval(updateStatusBarClock, 1000);
    updateStatusBarClock();

    // Poll for real-time updates every 5 seconds
    setInterval(pollRealTimeUpdates, 5000);

    // Trigger Splash delay
    runSplashDelay();
});

// Mock clock in phone status bar
function updateStatusBarClock() {
    const now = new Date();
    const min = now.getMinutes().toString().padStart(2, '0');
    document.getElementById('status-time').innerText = `${now.getHours()}:${min}`;
}

// Background polling for real-time updates from database
function pollRealTimeUpdates() {
    if (!currentUser) return;
    
    const activeScreen = document.querySelector('.screen-view.active');
    if (activeScreen) {
        const screenId = activeScreen.id.replace('screen-', '');
        
        switch (screenId) {
            case 'home':
                loadHomeData();
                break;
            case 'crop_advisory':
                loadAdvisoryData();
                break;
            case 'pest':
                loadPestData();
                break;
            case 'market':
                loadMarketData();
                break;
            case 'tips':
                loadTipsData();
                break;
            case 'profile':
                loadProfileData();
                break;
        }
    }
}

// Toast Alerts
function showToast(message, type = 'success') {
    const toastContainer = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `<span>${type === 'success' ? '🟢' : '🔴'}</span> ${message}`;
    toastContainer.appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
}

// Splash Screen loading session
async function runSplashDelay() {
    // 2.2s artificial delay matching mobile animations
    await new Promise(resolve => setTimeout(resolve, 2200));

    try {
        const response = await fetch(`${API_BASE}/get_current_user`);
        if (response.status === 200) {
            const res = await response.json();
            if (res && res.id) {
                currentUser = res;
                currentUser.username = res.name; // map name to username
                showAppUI();
                return;
            }
        }
    } catch (_) {}
    
    // Fallback to onboarding if no active session
    navigateTo('onboarding');
}

// Fetch and load Indian states into dropdown
async function loadStatesDropdown() {
    try {
        const response = await fetch(`${API_BASE}/api/states`);
        const states = await response.json();
        const stateSelect = document.getElementById('state-select');
        if (stateSelect) {
            stateSelect.innerHTML = '<option value="">Select State</option>';
            states.forEach(s => {
                const opt = document.createElement('option');
                opt.value = s.state_name;
                opt.innerText = s.state_name;
                stateSelect.appendChild(opt);
            });
        }
    } catch (_) {}
}

// Onboarding Carousel logic
function setupOnboarding() {
    const slides = document.querySelectorAll('.onboarding-slide');
    const dots = document.querySelectorAll('.onboarding-dots .dot');
    const btn = document.getElementById('onboarding-btn');

    btn.addEventListener('click', () => {
        if (currentOnboardingSlide < 2) {
            slides[currentOnboardingSlide].classList.remove('active');
            dots[currentOnboardingSlide].classList.remove('active');
            
            currentOnboardingSlide++;
            
            slides[currentOnboardingSlide].classList.add('active');
            dots[currentOnboardingSlide].classList.add('active');
            
            if (currentOnboardingSlide === 2) {
                btn.innerText = 'Get Started';
            }
        } else {
            navigateTo('login');
        }
    });
}

// Login & Signup toggles
function setupAuthNavigation() {
    document.getElementById('btn-to-register').addEventListener('click', () => navigateTo('register'));
    document.getElementById('btn-to-login').addEventListener('click', () => navigateTo('login'));
}

// Map farmer's state to respective default Mandi city
function getMandiForState(state) {
    if (!state) return 'Kurnool';
    const s = state.toLowerCase();
    if (s.includes('telangana') || s.includes('hyderabad')) return 'Hyderabad';
    if (s.includes('maharashtra') || s.includes('mumbai') || s.includes('pune')) return 'Hyderabad';
    if (s.includes('vijayawada')) return 'Vijayawada';
    if (s.includes('guntur')) return 'Guntur';
    return 'Kurnool';
}

// Show main interface dashboard
async function showAppUI() {
    // Set profile names globally
    document.getElementById('user-greeting-name').innerText = currentUser.username || currentUser.name || 'Farmer';
    document.getElementById('user-greeting-loc').innerText = currentUser.state || 'Kurnool';
    document.getElementById('advisory-loc-badge').innerText = currentUser.state || 'Kurnool';
    
    document.getElementById('profile-card-name').innerText = currentUser.username || currentUser.name || 'Farmer';
    document.getElementById('profile-card-email').innerText = currentUser.email || '';

    // Dynamic location matching state for Mandi Dropdowns
    currentMarketState = currentUser.state || 'Andhra Pradesh';
    const stateSelect = document.getElementById('state-select');
    if (stateSelect) {
        stateSelect.value = currentMarketState;
    }
    
    const mandiSelect = document.getElementById('mandi-select');
    if (mandiSelect) {
        try {
            const response = await fetch(`${API_BASE}/api/mandis?state=${encodeURIComponent(currentMarketState)}`);
            const mandis = await response.json();
            if (mandis.length > 0) {
                mandiSelect.innerHTML = '';
                mandis.forEach(m => {
                    const opt = document.createElement('option');
                    opt.value = m.mandi_name;
                    opt.innerText = m.mandi_name;
                    mandiSelect.appendChild(opt);
                });
                currentMandi = mandis[0].mandi_name;
                mandiSelect.value = currentMandi;
            } else {
                mandiSelect.innerHTML = '<option value="">No mandis found</option>';
                currentMandi = '';
            }
        } catch (_) {}
    }

    // Load active dashboard data panels
    loadHomeData();
    loadAdvisoryData();
    loadPestData();
    loadMarketData();
    loadTipsData();
    loadProfileData();

    navigateTo('home');
}

// Home Action grid routing
function setupQuickActions() {
    const items = document.querySelectorAll('.quick-item');
    items.forEach(item => {
        item.addEventListener('click', () => {
            const route = item.getAttribute('data-route');
            navigateTo(route);
        });
    });

    // Avatar icon opens profile
    document.getElementById('avatar-btn').addEventListener('click', () => navigateTo('profile'));

    // Back buttons inside sub-screens route back to Home
    document.querySelectorAll('.back-btn').forEach(btn => {
        btn.addEventListener('click', () => navigateTo('home'));
    });
}

// Mobile Tab views
function setupTabs() {
    const tabHeaders = document.querySelectorAll('.mobile-tabs');
    tabHeaders.forEach(header => {
        const tabs = header.querySelectorAll('.tab-item');
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                tabs.forEach(t => t.classList.remove('active'));
                tab.classList.add('active');

                // Toggle views in the same section scope
                const screenView = header.closest('.screen-view');
                const targetTab = tab.getAttribute('data-tab');
                
                screenView.querySelectorAll('.tabview').forEach(view => {
                    view.classList.remove('active');
                });
                screenView.querySelector(`#tabview-${targetTab}`).classList.add('active');
            });
        });
    });
}

// Profile settings sliding overlays
function setupProfileOverlays() {
    const personalBtn = document.getElementById('settings-personal-btn');
    const farmBtn = document.getElementById('settings-farm-btn');
    
    personalBtn.addEventListener('click', () => {
        document.getElementById('panel-personal-info').classList.add('active');
    });

    farmBtn.addEventListener('click', () => {
        document.getElementById('panel-farm-details').classList.add('active');
    });

    // Close buttons slide back out
    document.querySelectorAll('.overlay-close-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const target = btn.getAttribute('data-overlay');
            document.getElementById(`panel-${target}`).classList.remove('active');
        });
    });

    // Logout setting trigger
    document.getElementById('settings-logout-btn').addEventListener('click', async () => {
        try {
            await fetch(`${API_BASE}/logout`, { method: 'POST' });
        } catch (_) {}
        currentUser = null;
        showToast('Logged out successfully');
        navigateTo('login');
    });
}

// Add task dialog launcher
function setupScheduleDialog() {
    const overlay = document.getElementById('schedule-dialog-overlay');
    
    document.getElementById('btn-add-activity').addEventListener('click', () => {
        // Set default picker value to tomorrow morning
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(6, 0, 0, 0);
        
        const tzoffset = tomorrow.getTimezoneOffset() * 60000;
        const localISOTime = (new Date(tomorrow - tzoffset)).toISOString().slice(0, 16);
        document.getElementById('schedule-dialog-date').value = localISOTime;

        overlay.classList.remove('hidden');
    });

    document.getElementById('schedule-dialog-cancel').addEventListener('click', () => {
        overlay.classList.add('hidden');
    });
}

// Form submissions and REST bindings
function setupAPIForms() {
    // Login form
    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;

        try {
            const response = await fetch(`${API_BASE}/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const res = await response.json();
            if (response.status === 200 && res.user) {
                currentUser = res.user;
                currentUser.username = res.user.name;
                showToast('Signed in successfully!');
                showAppUI();
            } else {
                showToast(res.error || res.message || 'Invalid credentials', 'error');
            }
        } catch (_) {
            showToast('Unable to connect to server', 'error');
        }
    });

    // Register Form
    document.getElementById('register-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const username = document.getElementById('register-username').value;
        const email = document.getElementById('register-email').value;
        const phone = document.getElementById('register-phone').value;
        const state = document.getElementById('register-state').value;
        const password = document.getElementById('register-password').value;

        try {
            const response = await fetch(`${API_BASE}/signup`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: username, email, phone, state, password, confirm_password: password })
            });
            const res = await response.json();
            if (response.status === 201) {
                showToast('Registration successful! Please sign in.');
                document.getElementById('login-email').value = email;
                navigateTo('login');
            } else {
                showToast(res.error || res.message || 'Registration failed', 'error');
            }
        } catch (_) {
            showToast('Unable to connect to server', 'error');
        }
    });

    // Add schedule item
    document.getElementById('schedule-dialog-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const activity = document.getElementById('schedule-dialog-activity').value;
        const rawDate = document.getElementById('schedule-dialog-date').value;
        const scheduled_at = rawDate.replace('T', ' '); // backend expects YYYY-MM-DD HH:MM

        try {
            const response = await fetch(`${API_BASE}/farm_schedule`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: currentUser.id,
                    activity,
                    scheduled_at
                })
            });
            const res = await response.json();
            if (response.status === 201) {
                showToast('Farm activity scheduled!');
                document.getElementById('schedule-dialog-overlay').classList.add('hidden');
                document.getElementById('schedule-dialog-form').reset();
                loadAdvisoryData();
            } else {
                showToast(res.error || res.message || 'Server update failed', 'error');
            }
        } catch (_) {
            showToast('Server update failed', 'error');
        }
    });

    // Save Personal Settings Form
    document.getElementById('btn-save-personal').addEventListener('click', async () => {
        const username = document.getElementById('profile-username').value;
        const email = document.getElementById('profile-email').value;
        const phone = document.getElementById('profile-phone').value;
        const state = document.getElementById('profile-state').value;

        try {
            const response = await fetch(`${API_BASE}/profile/${currentUser.id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: username, email, phone, state })
            });
            const res = await response.json();
            if (response.status === 200) {
                currentUser.name = username;
                currentUser.username = username;
                currentUser.email = email;
                currentUser.phone = phone;
                currentUser.state = state;
                showToast('Personal information updated!');
                showAppUI();
            } else {
                showToast(res.error || res.message || 'Update failed', 'error');
            }
        } catch (_) {
            showToast('Update failed', 'error');
        }
    });

    // Save Farm Settings Form
    document.getElementById('btn-save-farm').addEventListener('click', async () => {
        const land_area = parseFloat(document.getElementById('profile-land-area').value);
        const primary_crops = document.getElementById('profile-crops').value;
        const soil_type = document.getElementById('profile-soil').value;
        const irrigation = document.getElementById('profile-irrigation').value;

        try {
            const response = await fetch(`${API_BASE}/farm_details/${currentUser.id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ land_area, primary_crops, soil_type, irrigation })
            });
            const res = await response.json();
            if (response.status === 200) {
                showToast('Farm specifications saved!');
                showAppUI();
            } else {
                showToast(res.error || res.message || 'Update failed', 'error');
            }
        } catch (_) {
            showToast('Update failed', 'error');
        }
    });

    // Crop select chips on advisory page
    document.querySelectorAll('.crop-chip').forEach(chip => {
        chip.addEventListener('click', () => {
            document.querySelectorAll('.crop-chip').forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
            currentCrop = chip.getAttribute('data-crop');
            loadAdvisoryData();
        });
    });

    // Ask AI advisory fab trigger
    document.getElementById('floating-ask-ai').addEventListener('click', async () => {
        showToast('Consulting AI advisors...');
        try {
            const response = await fetch(`${API_BASE}/crop_advisories`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: currentUser.id,
                    crop: currentCrop,
                    title: `${currentCrop} AI Disease Warning`,
                    description: `Humid conditions may facilitate pathogen spread. Spray Pseudomonas fluorescens @ 10g/L to safeguard your crops.`,
                    emoji: '🔬',
                    priority: 'Medium'
                })
            });
            const res = await response.json();
            if (response.status === 201) {
                showToast('AI Advisory recommendation received!');
                loadAdvisoryData();
            }
        } catch (_) {}
    });

    // State Select dropdown on Market page
    const stateSelect = document.getElementById('state-select');
    if (stateSelect) {
        stateSelect.addEventListener('change', async (e) => {
            currentMarketState = e.target.value;
            currentMandi = ''; // reset mandi
            
            const mandiSelect = document.getElementById('mandi-select');
            if (mandiSelect) {
                mandiSelect.innerHTML = '<option value="">Select Mandi</option>';
            }
            
            if (currentMarketState) {
                try {
                    const response = await fetch(`${API_BASE}/api/mandis?state=${encodeURIComponent(currentMarketState)}`);
                    const mandis = await response.json();
                    if (mandis.length > 0) {
                        mandiSelect.innerHTML = '';
                        mandis.forEach(m => {
                            const opt = document.createElement('option');
                            opt.value = m.mandi_name;
                            opt.innerText = m.mandi_name;
                            mandiSelect.appendChild(opt);
                        });
                        currentMandi = mandis[0].mandi_name;
                        mandiSelect.value = currentMandi;
                    } else {
                        mandiSelect.innerHTML = '<option value="">No mandis found</option>';
                    }
                } catch (_) {}
            }
            
            loadMarketData();
        });
    }

    // Mandi Select dropdown on Market page
    const mandiSelect = document.getElementById('mandi-select');
    if (mandiSelect) {
        mandiSelect.addEventListener('change', (e) => {
            currentMandi = e.target.value;
            loadMarketData();
        });
    }

    // Chart Modal Close button trigger
    const chartCloseBtn = document.getElementById('chart-dialog-close');
    if (chartCloseBtn) {
        chartCloseBtn.addEventListener('click', () => {
            document.getElementById('chart-dialog-overlay').classList.add('hidden');
        });
    }

    // Chart Time period buttons click bindings
    document.querySelectorAll('.chart-period-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.chart-period-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const days = parseInt(btn.getAttribute('data-days'));
            showPriceHistoryChart(chartSelectedMandi, chartSelectedCrop, days);
        });
    });

    // Search bar on Market page
    document.getElementById('market-search').addEventListener('input', (e) => {
        loadMarketData(e.target.value);
    });

    // Category chips on Market page
    document.querySelectorAll('.category-chip').forEach(chip => {
        chip.addEventListener('click', () => {
            document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
            currentMarketCategory = chip.getAttribute('data-cat');
            loadMarketData();
        });
    });
}

// Panel Loaders
async function loadHomeData() {
    if (!currentUser) return;

    // Load home pest alerts
    try {
        const response = await fetch(`${API_BASE}/pest_alerts`);
        const res = await response.json();
        const wrapper = document.getElementById('home-pest-alerts');
        wrapper.innerHTML = '';

        const list = res.slice(0, 2); // limit to 2 for home viewport space
        if (list.length > 0) {
            list.forEach(a => {
                const priorityClass = (a.severity === 'High') ? 'high' : 'medium';
                const emoji = a.pest_name.toLowerCase().includes('hopper') ? '🦗' : '🐛';
                wrapper.innerHTML += `
                    <div class="advisory-card ${priorityClass}">
                        <span class="advisory-card-emoji">${emoji}</span>
                        <div class="advisory-card-body">
                            <h4>${a.pest_name} Alert</h4>
                            <p>${a.description}</p>
                        </div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = `
                <div class="advisory-card">
                    <span class="advisory-card-emoji">🛡️</span>
                    <div class="advisory-card-body">
                        <h4>All Clear</h4>
                        <p>No active outbreaks reported in your area.</p>
                    </div>
                </div>
            `;
        }
    } catch (_) {}

    // Load mandi price snapshots
    try {
        const response = await fetch(`${API_BASE}/market_prices?mandi=${currentUser.state || 'Kurnool'}`);
        const res = await response.json();
        const wrapper = document.getElementById('home-market-prices');
        wrapper.innerHTML = '';

        const list = res.slice(0, 2);
        if (list.length > 0) {
            list.forEach(p => {
                const isUp = p.is_up === true;
                const changeClass = isUp ? 'up' : 'down';
                const changeArrow = isUp ? '▲' : '▼';
                const emoji = p.commodity.toLowerCase().includes('maize') ? '🌽' : '🌾';
                wrapper.innerHTML += `
                    <div class="schedule-card">
                        <span style="font-size: 20px;">${emoji}</span>
                        <div class="schedule-details">
                            <h4>${p.commodity}</h4>
                            <p>${p.category}</p>
                        </div>
                        <div style="text-align: right;">
                            <div style="font-weight:700;">₹${Math.floor(p.price)}</div>
                            <span class="c-change-row ${changeClass}" style="font-size:10px;">${changeArrow} ₹${Math.floor(p.change)}</span>
                        </div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = `
                <div class="schedule-card">
                    <span style="font-size: 20px;">🌾</span>
                    <div class="schedule-details">
                        <h4>Paddy (Fine)</h4>
                        <p>Cereals · Kurnool</p>
                    </div>
                    <div style="text-align: right;">
                        <div style="font-weight:700;">₹2,180</div>
                        <span class="c-change-row up" style="font-size:10px;">▲ ₹40</span>
                    </div>
                </div>
            `;
        }
    } catch (_) {}
}

async function loadAdvisoryData() {
    if (!currentUser) return;

    // Load Crop Advisories
    try {
        const response = await fetch(`${API_BASE}/crop_advisories/${currentUser.id}?crop=${currentCrop}`);
        const list = await response.json();
        const wrapper = document.getElementById('advisory-list');
        wrapper.innerHTML = '';

        if (list.length > 0) {
            list.forEach(a => {
                const sev = a.priority === 'High' ? 'high' : (a.priority === 'Medium' ? 'medium' : '');
                wrapper.innerHTML += `
                    <div class="advisory-card ${sev} mb-12">
                        <span class="advisory-card-emoji">${a.emoji || '🌾'}</span>
                        <div class="advisory-card-body">
                            <h4>${a.title}</h4>
                            <p>${a.description}</p>
                            <div class="advisory-card-time">${a.created_at || 'Just now'}</div>
                        </div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = `
                <div class="advisory-card mb-12">
                    <span class="advisory-card-emoji">💧</span>
                    <div class="advisory-card-body">
                        <h4>${currentCrop} Irrigation</h4>
                        <p>Optimal moisture is at 62%. Water the crop within 2 days for consistent yields.</p>
                    </div>
                </div>
                <div class="advisory-card medium mb-12">
                    <span class="advisory-card-emoji">🌿</span>
                    <div class="advisory-card-body">
                        <h4>${currentCrop} Fertilization</h4>
                        <p>Apply 2nd dose of NPK (20:20:0) -- 40kg per acre this week.</p>
                    </div>
                </div>
            `;
        }
    } catch (_) {}

    // Load Farm schedules
    try {
        const response = await fetch(`${API_BASE}/farm_schedule/${currentUser.id}`);
        const list = await response.json();
        const wrapper = document.getElementById('schedule-list');
        wrapper.innerHTML = '';

        if (list.length > 0) {
            list.forEach(item => {
                const isCompleted = item.status === 'completed';
                const completedClass = isCompleted ? 'completed' : '';
                wrapper.innerHTML += `
                    <div class="schedule-card ${completedClass} mb-12">
                        <div class="schedule-checkbox" onclick="toggleTaskStatus(${item.id}, '${item.status}')">
                            <span class="schedule-checkbox-check">✔</span>
                        </div>
                        <div class="schedule-details">
                            <h4>${item.activity}</h4>
                            <p>${item.scheduled_at}</p>
                        </div>
                        <button class="schedule-delete" onclick="deleteScheduleTask(${item.id})">🗑️</button>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = `
                <div class="schedule-card mb-12">
                    <div class="schedule-checkbox"></div>
                    <div class="schedule-details">
                        <h4>Irrigate Field</h4>
                        <p>Tomorrow, 6:00 AM</p>
                    </div>
                </div>
            `;
        }
    } catch (_) {}
}

async function toggleTaskStatus(id, currentStatus) {
    const newStatus = currentStatus === 'completed' ? 'pending' : 'completed';
    try {
        const response = await fetch(`${API_BASE}/farm_schedule/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus })
        });
        if (response.status === 200) {
            loadAdvisoryData();
        }
    } catch (_) {}
}

async function deleteScheduleTask(id) {
    if (!confirm('Delete this task?')) return;
    try {
        const response = await fetch(`${API_BASE}/farm_schedule/${id}`, { method: 'DELETE' });
        if (response.status === 200) {
            showToast('Task deleted');
            loadAdvisoryData();
        }
    } catch (_) {}
}

async function loadPestData() {
    try {
        const response = await fetch(`${API_BASE}/pest_alerts`);
        const res = await response.json();
        const wrapper = document.getElementById('pest-alerts-list');
        wrapper.innerHTML = '';

        if (res.length > 0) {
            res.forEach(a => {
                const priorityClass = (a.severity === 'High') ? 'high' : 'medium';
                const emoji = a.pest_name.toLowerCase().includes('hopper') ? '🦗' : '🐛';
                wrapper.innerHTML += `
                    <div class="advisory-card ${priorityClass}">
                        <span class="advisory-card-emoji">${emoji}</span>
                        <div class="advisory-card-body">
                            <h4>${a.pest_name} (${a.crop})</h4>
                            <p>${a.description}</p>
                            <div class="advisory-card-time">${a.region} · Reported ${a.reported_at}</div>
                        </div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = '<p class="loading-placeholder">No active pest alerts reported.</p>';
        }
    } catch (_) {}

    try {
        const response = await fetch(`${API_BASE}/treatments`);
        const res = await response.json();
        const wrapper = document.getElementById('treatments-list');
        wrapper.innerHTML = '';

        if (res.length > 0) {
            res.forEach(t => {
                let badgeColor = '#2a9d8f';
                if (t.type.toLowerCase().includes('chem')) badgeColor = '#e63946';
                if (t.type.toLowerCase().includes('fungi')) badgeColor = '#9B59B6';
                wrapper.innerHTML += `
                    <div class="treatment-card">
                        <h4>${t.name}</h4>
                        <p>${t.description}</p>
                        <span class="treatment-badge" style="background:${badgeColor}">${t.type}</span>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = '<p class="loading-placeholder">No treatments listed.</p>';
        }
    } catch (_) {}
}

async function loadMarketData(searchQuery = '') {
    const wrapper = document.getElementById('market-prices-list');
    if (!wrapper) return;
    
    wrapper.innerHTML = '<p class="loading-placeholder">Loading market prices...</p>';
    
    if (!currentMarketState) {
        wrapper.innerHTML = '<p class="loading-placeholder">Please select a state first.</p>';
        return;
    }
    
    try {
        let url = `${API_BASE}/api/market-prices?state=${encodeURIComponent(currentMarketState)}`;
        if (currentMandi) {
            url += `&mandi=${encodeURIComponent(currentMandi)}`;
        }
        
        const response = await fetch(url);
        if (response.status !== 200) {
            wrapper.innerHTML = '<p class="loading-placeholder" style="color: var(--error);">Unable to retrieve market prices. Please try again.</p>';
            return;
        }
        
        const resData = await response.json();
        
        if (!resData.mandis || resData.mandis.length === 0) {
            wrapper.innerHTML = '<p class="loading-placeholder" style="color: var(--error);">Market information is currently unavailable for this state.</p>';
            
            const risingEl = document.getElementById('market-stat-rising');
            const fallingEl = document.getElementById('market-stat-falling');
            const stableEl = document.getElementById('market-stat-stable');
            if (risingEl) risingEl.innerText = `▲ 0 Rising`;
            if (fallingEl) fallingEl.innerText = `▼ 0 Falling`;
            if (stableEl) stableEl.innerText = `= 0 Stable`;
            return;
        }
        
        const selectedMandiData = resData.mandis.find(m => m.mandi_name === currentMandi);
        
        if (!selectedMandiData || !selectedMandiData.prices || selectedMandiData.prices.length === 0) {
            wrapper.innerHTML = '<p class="loading-placeholder" style="color: var(--error);">Price information is currently unavailable for this mandi.</p>';
            
            const risingEl = document.getElementById('market-stat-rising');
            const fallingEl = document.getElementById('market-stat-falling');
            const stableEl = document.getElementById('market-stat-stable');
            if (risingEl) risingEl.innerText = `▲ 0 Rising`;
            if (fallingEl) fallingEl.innerText = `▼ 0 Falling`;
            if (stableEl) stableEl.innerText = `= 0 Stable`;
            return;
        }
        
        let prices = selectedMandiData.prices;
        
        if (searchQuery.trim() !== '') {
            prices = prices.filter(p => p.crop.toLowerCase().includes(searchQuery.toLowerCase()));
        }
        
        if (currentMarketCategory !== 'All') {
            prices = prices.filter(p => {
                const c = p.crop.toLowerCase();
                if (currentMarketCategory === 'Cereals') {
                    return c.includes('paddy') || c.includes('rice') || c.includes('maize') || c.includes('wheat');
                } else if (currentMarketCategory === 'Pulses') {
                    return c.includes('pulse') || c.includes('gram') || c.includes('dal');
                } else if (currentMarketCategory === 'Oilseed') {
                    return c.includes('ground') || c.includes('cotton') || c.includes('soy');
                } else if (currentMarketCategory === 'Vegetables') {
                    return c.includes('chilli') || c.includes('tomato') || c.includes('onion') || c.includes('turmeric') || c.includes('sugar');
                }
                return true;
            });
        }
        
        let risingCount = 0;
        let fallingCount = 0;
        let stableCount = 0;
        prices.forEach(p => {
            if (p.trend === 'RISING') risingCount++;
            else if (p.trend === 'FALLING') fallingCount++;
            else stableCount++;
        });
        
        const risingEl = document.getElementById('market-stat-rising');
        const fallingEl = document.getElementById('market-stat-falling');
        const stableEl = document.getElementById('market-stat-stable');
        if (risingEl) risingEl.innerText = `▲ ${risingCount} Rising`;
        if (fallingEl) fallingEl.innerText = `▼ ${fallingCount} Falling`;
        if (stableEl) stableEl.innerText = `= ${stableCount} Stable`;
        
        wrapper.innerHTML = '';
        
        const lastUpdatedEl = document.getElementById('market-last-updated');
        if (lastUpdatedEl && prices.length > 0) {
            lastUpdatedEl.innerText = `Last updated: ${prices[0].updated_at}`;
        }
        
        prices.forEach(p => {
            let changeClass = 'stable';
            let changeArrow = '=';
            if (p.trend === 'RISING') {
                changeClass = 'up';
                changeArrow = '▲';
            } else if (p.trend === 'FALLING') {
                changeClass = 'down';
                changeArrow = '▼';
            }
            
            const cropLower = p.crop.toLowerCase();
            let emoji = '🌾';
            if (cropLower.includes('maize') || cropLower.includes('corn')) emoji = '🌽';
            else if (cropLower.includes('ground')) emoji = '🥜';
            else if (cropLower.includes('chilli')) emoji = '🌶️';
            else if (cropLower.includes('tomato')) emoji = '🍅';
            else if (cropLower.includes('onion')) emoji = '🧅';
            else if (cropLower.includes('turmeric')) emoji = '🫚';
            else if (cropLower.includes('cotton')) emoji = '☁️';
            else if (cropLower.includes('wheat')) emoji = '🌾';
            else if (cropLower.includes('sugar')) emoji = '🎋';
            
            const card = document.createElement('div');
            card.className = 'commodity-price-card';
            card.style.cursor = 'pointer';
            card.innerHTML = `
                <span class="c-emoji">${emoji}</span>
                <div class="c-details" style="flex: 1;">
                    <h4 style="margin: 0; font-size: 14px;">${p.crop}</h4>
                    <p style="margin: 2px 0 0; font-size: 11px; color: var(--text-light);">Range: ₹${Math.floor(p.minimum_price)} - ₹${Math.floor(p.maximum_price)}</p>
                </div>
                <div class="c-pricing" style="text-align: right;">
                    <div class="c-price-val" style="font-weight: bold; font-size: 14px;">₹${Math.floor(p.modal_price)}/${p.unit.includes('ton') ? 'ton' : 'qtl'}</div>
                    <span class="c-change-row ${changeClass}" style="font-size: 11px; display: inline-flex; align-items: center; gap: 2px; margin-top: 2px;">
                        ${changeArrow} ₹${Math.floor(Math.abs(p.price_change))} (${p.percentage_change >= 0 ? '+' : ''}${p.percentage_change}%)
                    </span>
                </div>
            `;
            
            card.addEventListener('click', () => {
                chartSelectedCrop = p.crop;
                chartSelectedMandi = currentMandi;
                
                document.getElementById('chart-crop-title').innerText = `${p.crop} Price Trend`;
                document.getElementById('chart-mandi-subtitle').innerText = `Mandi: ${currentMandi} · District: ${selectedMandiData.district || ''}`;
                document.getElementById('chart-dialog-overlay').classList.remove('hidden');
                
                document.querySelectorAll('.chart-period-btn').forEach(b => b.classList.remove('active'));
                const defaultPeriodBtn = document.querySelector('.chart-period-btn[data-days="30"]');
                if (defaultPeriodBtn) defaultPeriodBtn.classList.add('active');
                
                showPriceHistoryChart(currentMandi, p.crop, 30);
            });
            
            wrapper.appendChild(card);
        });
        
    } catch (_) {
        wrapper.innerHTML = '<p class="loading-placeholder" style="color: var(--error);">Unable to retrieve market prices. Please try again.</p>';
    }
}

async function loadTipsData() {
    try {
        const response = await fetch(`${API_BASE}/farming_tips`);
        const res = await response.json();
        const wrapper = document.getElementById('tips-deck');
        wrapper.innerHTML = '';

        if (res.length > 0) {
            res.forEach(t => {
                wrapper.innerHTML += `
                    <div class="tip-card">
                        <div class="tip-icon">${t.icon || '🌱'}</div>
                        <div class="tip-body">
                            <h4>${t.title}</h4>
                            <p>${t.description}</p>
                            <span class="tip-tag">${t.tag}</span>
                        </div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = '<p class="loading-placeholder">No tips available.</p>';
        }
    } catch (_) {}

    try {
        const response = await fetch(`${API_BASE}/news_articles`);
        const res = await response.json();
        const wrapper = document.getElementById('news-list');
        const featuredWrapper = document.getElementById('featured-news-container');
        wrapper.innerHTML = '';
        featuredWrapper.innerHTML = '';

        if (res.length > 0) {
            const featuredList = res.filter(n => n.is_featured);
            const nonFeaturedList = res.filter(n => !n.is_featured);
            
            const featured = featuredList.length > 0 ? featuredList[0] : res[0];
            const regularList = featuredList.length > 0 ? nonFeaturedList : res.slice(1);

            featuredWrapper.innerHTML = `
                <div class="news-card-featured">
                    <span class="news-card-featured-emoji">${featured.image_emoji || '📰'}</span>
                    <span class="news-feat-category">${featured.category}</span>
                    <h4>${featured.title}</h4>
                    <div class="news-feat-footer">
                        <span>📰 ${featured.source}</span>
                        <span>${featured.published_at || 'Today'}</span>
                    </div>
                </div>
            `;

            regularList.forEach(n => {
                wrapper.innerHTML += `
                    <div class="news-card">
                        <div class="news-card-header">
                            <span class="news-category">${n.category}</span>
                            <span class="news-time">${n.published_at || 'Today'}</span>
                        </div>
                        <h4>${n.title}</h4>
                        <p>${n.summary}</p>
                        <div class="news-source">📰 Source: ${n.source}</div>
                    </div>
                `;
            });
        } else {
            wrapper.innerHTML = '<p class="loading-placeholder">No news updates listed.</p>';
        }
    } catch (_) {}
}

async function loadProfileData() {
    if (!currentUser) return;
    
    document.getElementById('profile-username').value = currentUser.username || currentUser.name || '';
    document.getElementById('profile-email').value = currentUser.email || '';
    document.getElementById('profile-phone').value = currentUser.phone || '';
    document.getElementById('profile-state').value = currentUser.state || '';

    try {
        const response = await fetch(`${API_BASE}/farm_details/${currentUser.id}`);
        const res = await response.json();
        if (response.status === 200 && res) {
            document.getElementById('profile-land-area').value = res.land_area || '';
            document.getElementById('profile-crops').value = res.primary_crops || '';
            document.getElementById('profile-soil').value = res.soil_type || 'Black Soil';
            document.getElementById('profile-irrigation').value = res.irrigation || 'Borewell';
        }
    } catch (_) {}
}

// 22 Indian Languages + English Web translation logic
const webTranslations = {
    "welcome": [
      'Welcome back,', 'স্বাগতম,', 'স্বাগতম,', 'वरायबाय,', 'स्वागत ऐ,', 'સ્વાગત,', 'स्वागत है,', 'ಸ್ವಾಗತ,', 'خوش آمدید', 'स्वागत आसा,',
      'स्वागत अछि,', 'സ്വാഗതം,', 'তরাম্না ওকচরি,', 'स्वागत आहे,', 'स्वागत छ,', 'ସ୍ଵାଗତ,', 'ਜੀ ਆਇਆਂ ਨੂੰ,', 'स्वागतम्,', 'सगुन दराम,', 'भली कार आया,',
      'வரவேற்கிறோம்,', 'స్వాగతం,', 'خوش آمدید،'
    ],
    "advisory": [
      'Advisory', 'পৰামৰ্শ', 'পরামর্শ', 'सलाह', 'सलाह', 'સલાહ', 'सलाह', 'ಸಲಹೆ', 'صلاح', 'सल्लो',
      'सलाह', 'ഉপদেশ', 'পাউতাক', 'सल्ला', 'सल्लाह', 'ପରାମର୍ଶ', 'ସଲାਹ', 'परामर्श', 'सलाहा', 'सलाह',
      'ஆலோசனை', 'సలహా', 'مشورہ'
    ],
    "pest_alert": [
      'Pest Alert', 'কীট-পতংগ সৰ্তকতা', 'পোকামাকড় সতর্কতা', 'এনাइ संकेत', 'कीड़ा चेतावनी', 'જીવાત ચેતવણી', 'कीट चेतावनी', 'ಕೀಟ ಎಚ್ಚरीके', 'پیسٹ الرٹ', 'किडो शिस्त',
      'कीट चेतावनी', 'കീട മുന്നറിയിപ്പ്', 'পোকামাকড় চেকশিন', 'कीड चेतावणी', 'कीरा चेतावनी', 'ପୋକ ଚେତାବନୀ', 'ਕੀਟ ਚੇਤਾਵਨੀ', 'कीट सचेत', 'कीट एर्ट', 'कीट चेतावनी',
      'பூச்சி எச்சரிக்கை', 'కీటక హెచ్చరిక', 'کیڑوں کی وارننگ'
    ],
    "market": [
      'Market', 'বজাৰ', 'বাজার', 'হাট', 'बाजार', 'બજાર', 'बाजार', 'ಮಾರುಕಟ್ಟೆ', 'बाजार', 'बाजार',
      'बाजार', 'മാർക്കറ്റ്', 'কৈথেল', 'बाजार', 'बजार', 'ବଜାର', 'ਮਾਰਕੀਟ', 'आपण', 'हाट', 'बाजार',
      'சந்தை', 'మార్కెట్', 'مارکیٹ'
    ],
    "tips_news": [
      'Tips & News', 'পৰামৰ্শ আৰু বাতৰি', 'পরামর্শ ও খবর', 'सलाহ आरो खौरां', 'सलाह ते खबरें', 'નવીન માહિતી', 'टिप्स और समाचार', 'සුದ್ದಿ ಮತ್ತು ಸಲಹೆಗಳು', 'टिप्स व खबर', 'टिप्स आणि खबर',
      'सलाह आ समाचार', 'ടിപ്പുകളും വാർത്തകളും', 'পাউতাক অমসুং পাউ', 'सल्ला व बातम्या', 'सुझाव र समाचार', 'ଟିପ୍ସ ଏବଂ ସମାଚାର', 'ਸੁਝਾਅ ਅਤੇ ਖ਼ਬਰਾਂ', 'वार्ताः', 'सल्लाह आरो खवर', 'टिप्स ऐं खबरूं',
      'செய்திகள் & குறிப்புகள்', 'చిట్కాలు & వార్తలు', 'ٹپس اور خبریں'
    ],
    "profile": [
      'Profile', 'প্ৰফাইল', 'প্রোফাইল', 'प्रोफाइल', 'प्रोफाइल', 'પ્રોફાઇઇલ', 'प्रोफाइल', 'ಪ್ರೊಫೈಲ್', 'پروفائل', 'प्रोफाइल',
      'प्रोफाइल', 'പ്രൊഫൈൽ', 'প্রোফাইল', 'प्रोफाइल', 'प्रोफाइल', 'ପ୍ରୋଫାଇଲ୍', 'ਪ੍ਰਫਾਈਲ', 'व्यक्तिचित्रम्', 'प्रोफाइल', 'प्रोफाइल',
      'விவரக்குறிப்பு', 'ప్రొఫైల్', 'پروفائل'
    ],
    "dark_mode": [
      'Dark Mode', 'ডাৰ্ক ম’ড', 'ডার্ক মোড', 'डार्क मोड', 'डार्क मोड', 'ડાર્ક મોડ', 'डार्क मोड', 'ಡಾರ್ಕ್ ಮೋಡ್', 'ڈارک موڈ', 'डार्क मोड',
      'डार्क मोड', 'ഡാർക്ക് മോഡ്', 'অমোম্বা মোড', 'डार्क मोड', 'डार्क मोड', 'ଡାର୍କ ମୋଡ୍', 'ਡਾਰਕ ਮੋਡ', 'तमिस्रा', 'डार्क मोड', 'डार्क मोड',
      'இருண்ட பயன்முறை', 'డార్క్ మోడ్', 'ڈارک موڈ'
    ],
    "language": [
      'Language', 'ภาษา', 'भाषा', 'राव', 'बोली', 'ભાષા', 'भाषा', 'ಭಾಷೆ', 'زبان', 'भास',
      'भाषा', 'भाषा', 'লোন', 'भाषा', 'भाषा', 'ଭାଷା', 'ਭਾਸ਼ਾ', 'भाषा', 'भासा', 'बोली',
      'மொழி', 'భాష', 'زبان'
    ],
    "logout": [
      'Log Out', 'লগ আউট', 'লগ আউট', 'लॉग आउट', 'लॉग आउट', 'લૉગ આઉટ', 'लॉग आउट', 'ಲಾಗ್ ಔಟ್', 'لاگ آوٹ', 'लॉग आउट',
      'लॉग आउट', 'ലോഗ് ഔട്ട്', 'লগ আউট', 'लॉग आउट', 'लॉग आउट', 'ଲଗ୍ ଆଉଟ୍', 'ਲੌਗ ਆਉਟ', 'निर्गमनम्', 'लॉग आउट', 'लॉग आउट',
      'வெளியேறு', 'లాగ్ అవుట్', 'لاگ آؤٹ'
    ],
    "personal_info": [
      'Personal Information', 'ব্যক্তিগত তথ্য', 'ব্যক্তিগত তথ্য', 'गावनि खौरां', 'जाती मालूमात', 'વ્યક્તિગત માહિતી', 'व्यक्तिगत जानकारी', 'ವೈಯক্তিক ಮಾಹಿತಿ', 'जाती माहिती', 'खाजगी माहिती',
      'व्यक्तिगत जानकारी', 'വ്യക്തിഗത വിവരങ്ങൾ', 'অপুনবা পাউ', 'वैयक्तिक माहिती', 'व्यक्तिगत विवरण', 'ବ୍ୟକ୍ତିଗତ ସୂଚନା', 'ਨਿੱਜੀ ਜਾਣਕਾਰੀ', 'वैयक्तिक वृत्तम्', 'निजो खवर', 'जाती माहिती',
      'தனிப்பட்ட தகவல்', 'వ్యవసాయ సమాచారం', 'ذاتی معلومات'
    ],
    "farm_details": [
      'Farm Details', 'খেতিৰ সবিশেষ', 'খামারের বিবরণ', 'आबाद खौरां', 'खेती दे बारे', 'ખેતી વિગતો', 'कृषि विवरण', 'ಕೃಷಿ ವಿವರಗಳು', 'शेत माहिती', 'शेत माहिती',
      'कृषि विवरण', 'കൃഷി വിവരങ്ങൾ', 'লৌমী সবিশেষ', 'शेतीची माहिती', 'कृषि विवरण', 'କୃଷି ବିବରଣୀ', 'ਖੇਤੀਬਾੜੀ ਵੇਰਵੇ', 'कृषिक्षेत्रम्', 'खेत खवर', 'खेतीअ बाबत',
      'பண்ணை விவரங்கள்', 'వ్యవసాయ వివరాలు', 'فارم کی تفصیلات'
    ]
};

let webLangIdx = 0;

function translateWeb(key) {
    if (!webTranslations[key]) return key;
    const list = webTranslations[key];
    if (webLangIdx >= list.length) return list[0];
    return list[webLangIdx];
}

function updateWebUILocalizations() {
    // 1. Home quick grid labels
    const quickItems = document.querySelectorAll('.quick-item');
    if (quickItems.length >= 4) {
        quickItems[0].querySelector('span').innerText = translateWeb('advisory');
        quickItems[1].querySelector('span').innerText = translateWeb('pest_alert');
        quickItems[2].querySelector('span').innerText = translateWeb('market');
        quickItems[3].querySelector('span').innerText = translateWeb('tips_news');
    }
    // 2. Welcome sub-greeting label
    const subGreeting = document.querySelector('.sub-greeting');
    if (subGreeting) {
        subGreeting.innerText = translateWeb('welcome');
    }
    // 3. Settings items labels
    const langTitle = document.getElementById('settings-lang-title');
    if (langTitle) langTitle.innerText = translateWeb('language');
    const darkTitle = document.getElementById('settings-dark-title');
    if (darkTitle) darkTitle.innerText = translateWeb('dark_mode');
    const logoutTitle = document.getElementById('settings-logout-title');
    if (logoutTitle) logoutTitle.innerText = translateWeb('logout');
}

function setupWebPreferences() {
    // Dark mode toggle handler
    const darkToggle = document.getElementById('web-dark-toggle');
    if (darkToggle) {
        darkToggle.addEventListener('change', (e) => {
            const viewport = document.querySelector('.phone-viewport');
            const statusBar = document.querySelector('.phone-status-bar');
            if (e.target.checked) {
                viewport.classList.add('dark-theme');
            } else {
                viewport.classList.remove('dark-theme');
            }
        });
    }

    // Language selection handler
    const langSelect = document.getElementById('web-lang-select');
    if (langSelect) {
        langSelect.addEventListener('change', (e) => {
            webLangIdx = parseInt(e.target.value);
            updateWebUILocalizations();
            showToast(`Language updated successfully!`);
        });
    }
}

// Render Chart.js line graph for historical crop prices
async function showPriceHistoryChart(mandi, crop, days) {
    try {
        const response = await fetch(`${API_BASE}/api/price-history?mandi=${encodeURIComponent(mandi)}&crop=${encodeURIComponent(crop)}&days=${days}`);
        const data = await response.json();
        
        const labels = data.map(d => {
            const date = new Date(d.date);
            return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
        });
        const prices = data.map(d => d.price);
        
        const ctx = document.getElementById('crop-history-chart').getContext('2d');
        
        if (priceChartInstance) {
            priceChartInstance.destroy();
        }
        
        priceChartInstance = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Price (₹/quintal)',
                    data: prices,
                    borderColor: '#1b4332',
                    backgroundColor: 'rgba(82, 183, 136, 0.15)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.3,
                    pointRadius: days > 7 ? 0 : 3,
                    pointBackgroundColor: '#1b4332'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    x: {
                        grid: {
                            display: false
                        },
                        ticks: {
                            font: {
                                size: 9
                            },
                            maxTicksLimit: 6
                        }
                    },
                    y: {
                        grid: {
                            color: '#dde5db'
                        },
                        ticks: {
                            font: {
                                size: 9
                            }
                        }
                    }
                }
            }
        });
    } catch (_) {}
}

