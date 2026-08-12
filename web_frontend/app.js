// app.js - Same to Same Connected Mobile Clone Logic

const API_BASE = 'http://localhost:5000';

// Global State
let currentUser = null;
let currentCrop = 'Paddy';
let currentMandi = 'Kurnool';
let currentMarketCategory = 'All';
let currentOnboardingSlide = 0;

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

    // Start Clock in Status Bar
    setInterval(updateStatusBarClock, 1000);
    updateStatusBarClock();

    // Trigger Splash delay
    runSplashDelay();
});

// Mock clock in phone status bar
function updateStatusBarClock() {
    const now = new Date();
    const min = now.getMinutes().toString().padLeft(2, '0');
    document.getElementById('status-time').innerText = `${now.getHours()}:${min}`;
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
            if (res.success && res.user) {
                currentUser = res.user;
                showAppUI();
                return;
            }
        }
    } catch (_) {}
    
    // Fallback to onboarding if no active session
    navigateTo('onboarding');
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

// Show main interface dashboard
function showAppUI() {
    // Set profile names globally
    document.getElementById('user-greeting-name').innerText = currentUser.username;
    document.getElementById('user-greeting-loc').innerText = currentUser.state || 'Kurnool';
    document.getElementById('advisory-loc-badge').innerText = currentUser.state || 'Kurnool';
    
    document.getElementById('profile-card-name').innerText = currentUser.username;
    document.getElementById('profile-card-email').innerText = currentUser.email;

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
            if (res.success) {
                currentUser = res.user;
                showToast('Signed in successfully!');
                showAppUI();
            } else {
                showToast(res.message || 'Invalid credentials', 'error');
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
                body: JSON.stringify({ username, email, phone, state, password })
            });
            const res = await response.json();
            if (res.success) {
                currentUser = res.user;
                showToast('Registration successful! Welcome.');
                showAppUI();
            } else {
                showToast(res.message || 'Registration failed', 'error');
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
            if (res.success) {
                showToast('Farm activity scheduled!');
                document.getElementById('schedule-dialog-overlay').classList.add('hidden');
                document.getElementById('schedule-dialog-form').reset();
                loadAdvisoryData();
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
            const response = await fetch(`${API_BASE}/update_profile`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ user_id: currentUser.id, username, email, phone, state })
            });
            const res = await response.json();
            if (res.success) {
                currentUser = res.user;
                showToast('Personal information updated!');
                showAppUI();
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
            const response = await fetch(`${API_BASE}/update_farm`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ user_id: currentUser.id, land_area, primary_crops, soil_type, irrigation })
            });
            const res = await response.json();
            if (res.success) {
                showToast('Farm specifications saved!');
                showAppUI();
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
            if (res.success) {
                showToast('AI Advisory recommendation received!');
                loadAdvisoryData();
            }
        } catch (_) {}
    });

    // Mandi Select dropdown on Market page
    document.getElementById('mandi-select').addEventListener('change', (e) => {
        currentMandi = e.target.value;
        loadMarketData();
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
        const res = await response.json();
        if (res.success) {
            loadAdvisoryData();
        }
    } catch (_) {}
}

async function deleteScheduleTask(id) {
    if (!confirm('Delete this task?')) return;
    try {
        const response = await fetch(`${API_BASE}/farm_schedule/${id}`, { method: 'DELETE' });
        const res = await response.json();
        if (res.success) {
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
    // Sync Mandi options
    try {
        const mandisRes = await fetch(`${API_BASE}/mandis`);
        const mandis = await mandisRes.json();
        const select = document.getElementById('mandi-select');
        
        if (mandis.length > 0 && select.options.length <= 4) {
            select.innerHTML = '';
            mandis.forEach(m => {
                const opt = document.createElement('option');
                opt.value = m;
                opt.innerText = `${m} Mandi`;
                select.appendChild(opt);
            });
            if (mandis.includes(currentMandi)) {
                select.value = currentMandi;
            } else {
                currentMandi = select.value;
            }
        }
    } catch (_) {}

    try {
        let url = `${API_BASE}/market_prices?mandi=${currentMandi}`;
        if (currentMarketCategory !== 'All') {
            url += `&category=${currentMarketCategory}`;
        }
        const response = await fetch(url);
        let prices = await response.json();
        
        const wrapper = document.getElementById('market-prices-list');
        wrapper.innerHTML = '';

        if (prices.length > 0) {
            // Apply search locally
            if (searchQuery.trim() !== '') {
                prices = prices.filter(p => p.commodity.toLowerCase().includes(searchQuery.toLowerCase()));
            }

            prices.forEach(p => {
                const isUp = p.is_up === true;
                const changeClass = isUp ? 'up' : 'down';
                const changeArrow = isUp ? '▲' : '▼';
                const emoji = p.commodity.toLowerCase().includes('maize') ? '🌽' : (p.commodity.toLowerCase().includes('ground') ? '🥜' : '🌾');

                wrapper.innerHTML += `
                    <div class="commodity-price-card">
                        <span class="c-emoji">${emoji}</span>
                        <div class="c-details">
                            <h4>${p.commodity}</h4>
                            <p>${p.category}</p>
                        </div>
                        <div class="c-pricing">
                            <div class="c-price-val">₹${Math.floor(p.price)}/${p.unit}</div>
                            <span class="c-change-row ${changeClass}">${changeArrow} ₹${Math.floor(p.change)}</span>
                        </div>
                    </div>
                `;
            });
        } else {
            // Fallback mock prices
            const mockPrices = [
                { emoji: '🌾', name: 'Paddy (Fine)', cat: 'Cereals', price: '2,180', change: '+40', up: true },
                { emoji: '🌽', name: 'Maize', cat: 'Cereals', price: '1,820', change: '-15', up: false },
                { emoji: '🥜', name: 'Groundnut', cat: 'Oilseed', price: '5,640', change: '+80', up: true }
            ];
            mockPrices.forEach(p => {
                if (currentMarketCategory === 'All' || p.cat.toLowerCase() === currentMarketCategory.toLowerCase()) {
                    if (searchQuery.trim() === '' || p.name.toLowerCase().includes(searchQuery.toLowerCase())) {
                        const changeClass = p.up ? 'up' : 'down';
                        const changeArrow = p.up ? '▲' : '▼';
                        wrapper.innerHTML += `
                            <div class="commodity-price-card">
                                <span class="c-emoji">${p.emoji}</span>
                                <div class="c-details">
                                    <h4>${p.name}</h4>
                                    <p>${p.cat}</p>
                                </div>
                                <div class="c-pricing">
                                    <div class="c-price-val">₹${p.price}/qtl</div>
                                    <span class="c-change-row ${changeClass}">${changeArrow} ₹${p.change.replace('+', '').replace('-', '')}</span>
                                </div>
                            </div>
                        `;
                    }
                }
            });
        }
    } catch (_) {}
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
    
    document.getElementById('profile-username').value = currentUser.username;
    document.getElementById('profile-email').value = currentUser.email;
    document.getElementById('profile-phone').value = currentUser.phone;
    document.getElementById('profile-state').value = currentUser.state || '';

    try {
        const response = await fetch(`${API_BASE}/get_farm_details/${currentUser.id}`);
        const res = await response.json();
        if (res.success && res.data) {
            document.getElementById('profile-land-area').value = res.data.land_area || '';
            document.getElementById('profile-crops').value = res.data.primary_crops || '';
            document.getElementById('profile-soil').value = res.data.soil_type || 'Black Soil';
            document.getElementById('profile-irrigation').value = res.data.irrigation || 'Borewell';
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

