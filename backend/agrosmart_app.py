# -*- coding: utf-8 -*-
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import os

app = Flask(__name__, static_folder='static', static_url_path='/')
CORS(app)

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.errorhandler(404)
def page_not_found(e):
    if request.path.startswith('/api/') or request.path in [
        '/signup', '/login', '/get_current_user', '/logout', '/profile', 
        '/farm_details', '/crop_advisories', '/pest_alerts', '/treatments', 
        '/market_prices', '/mandis', '/farm_schedule', '/farming_tips', '/news_articles'
    ]:
        return jsonify({'error': 'Not found'}), 404
    relative_path = request.path.lstrip('/')
    if relative_path and app.static_folder and os.path.exists(os.path.join(app.static_folder, relative_path)):
        return app.send_static_file(relative_path)
    return app.send_static_file('index.html')

database_url = os.environ.get('DATABASE_URL', '')

if database_url:
    # Render gives postgres:// but SQLAlchemy needs postgresql://
    if database_url.startswith('postgres://'):
        database_url = database_url.replace('postgres://', 'postgresql://', 1)
    db_uri = database_url
    print("Connected to PostgreSQL (cloud database).")
else:
    db_uri = 'sqlite:///agrosmart.db'
    print("Using local SQLite database.")

app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'agrosmart_secret_dev')

db = SQLAlchemy(app)



# ─────────────────────────────────────────
# MODELS
# ─────────────────────────────────────────

class User(db.Model):
    __tablename__ = 'users'
    id         = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name       = db.Column(db.String(255), nullable=False)
    email      = db.Column(db.String(255), unique=True, nullable=False)
    phone      = db.Column(db.String(50), nullable=False)
    password   = db.Column(db.String(255), nullable=False)
    state      = db.Column(db.String(100), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ActiveSession(db.Model):
    __tablename__ = 'active_sessions'
    id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    email    = db.Column(db.String(255), nullable=False)
    login_at = db.Column(db.DateTime, default=datetime.utcnow)

class FarmDetail(db.Model):
    __tablename__ = 'farm_details'
    id            = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id       = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    land_area     = db.Column(db.Numeric(10, 2), nullable=True)
    primary_crops = db.Column(db.String(255), nullable=True)
    soil_type     = db.Column(db.String(100), nullable=True)
    irrigation    = db.Column(db.String(100), nullable=True)
    region        = db.Column(db.String(255), nullable=True)
    updated_at    = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class State(db.Model):
    __tablename__ = 'states'
    id         = db.Column(db.Integer, primary_key=True, autoincrement=True)
    state_name = db.Column(db.String(100), unique=True, nullable=False)

class Mandi(db.Model):
    __tablename__ = 'mandis'
    id         = db.Column(db.Integer, primary_key=True, autoincrement=True)
    mandi_name = db.Column(db.String(255), nullable=False)
    state_id   = db.Column(db.Integer, db.ForeignKey('states.id'), nullable=False)
    district   = db.Column(db.String(100), nullable=True)
    location   = db.Column(db.String(255), nullable=True)
    
    state_rel  = db.relationship('State', backref='mandis')

class Crop(db.Model):
    __tablename__ = 'crops'
    id        = db.Column(db.Integer, primary_key=True, autoincrement=True)
    crop_name = db.Column(db.String(100), unique=True, nullable=False)
    category  = db.Column(db.String(50), nullable=True)

class MarketPrice(db.Model):
    __tablename__ = 'market_prices'
    id             = db.Column(db.Integer, primary_key=True, autoincrement=True)
    mandi_id       = db.Column(db.Integer, db.ForeignKey('mandis.id'), nullable=False)
    crop_id        = db.Column(db.Integer, db.ForeignKey('crops.id'), nullable=False)
    minimum_price  = db.Column(db.Float, nullable=True)
    maximum_price  = db.Column(db.Float, nullable=True)
    modal_price    = db.Column(db.Float, nullable=True)
    previous_price = db.Column(db.Float, nullable=False)
    current_price  = db.Column(db.Float, nullable=False)
    price_date     = db.Column(db.Date, nullable=False, default=datetime.utcnow().date)
    updated_at     = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    unit           = db.Column(db.String(20), default='₹/quintal')

    mandi_rel = db.relationship('Mandi', backref='prices')
    crop_rel = db.relationship('Crop', backref='prices')

    @property
    def mandi(self):
        return self.mandi_rel.mandi_name if self.mandi_rel else ""

    @property
    def commodity(self):
        return self.crop_rel.crop_name if self.crop_rel else ""

    @property
    def category(self):
        return self.crop_rel.category if self.crop_rel else ""

    @property
    def price(self):
        return self.current_price

    @property
    def prev_price(self):
        return self.previous_price

class CropAdvisory(db.Model):
    __tablename__ = 'crop_advisories'
    id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id     = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    crop        = db.Column(db.String(100), nullable=False)
    emoji       = db.Column(db.String(10),  nullable=True)
    title       = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)
    priority    = db.Column(db.String(20), default='Info')
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

class PestAlert(db.Model):
    __tablename__ = 'pest_alerts'
    id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    region      = db.Column(db.String(100), nullable=False)
    crop        = db.Column(db.String(100), nullable=False)
    pest_name   = db.Column(db.String(255), nullable=False)
    severity    = db.Column(db.String(20),  default='Medium')
    description = db.Column(db.Text, nullable=True)
    treatment   = db.Column(db.Text, nullable=True)
    reported_at = db.Column(db.DateTime, default=datetime.utcnow)

class Treatment(db.Model):
    __tablename__ = 'treatments'
    id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name        = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)
    type        = db.Column(db.String(50), nullable=False)   # Chemical / Fungicide / Bio-Pesticide
    crop        = db.Column(db.String(100), nullable=True)   # null = applicable to all
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

class FarmSchedule(db.Model):
    __tablename__ = 'farm_schedule'
    id           = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id      = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    activity     = db.Column(db.String(255), nullable=False)
    scheduled_at = db.Column(db.DateTime, nullable=False)
    status       = db.Column(db.String(20), default='pending')
    created_at   = db.Column(db.DateTime, default=datetime.utcnow)

class FarmingTip(db.Model):
    __tablename__ = 'farming_tips'
    id          = db.Column(db.Integer, primary_key=True, autoincrement=True)
    icon        = db.Column(db.String(10),  nullable=False)
    title       = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)
    tag         = db.Column(db.String(50),  nullable=True)
    category    = db.Column(db.String(50),  nullable=True)
    created_at  = db.Column(db.DateTime, default=datetime.utcnow)

class NewsArticle(db.Model):
    __tablename__ = 'news_articles'
    id             = db.Column(db.Integer, primary_key=True, autoincrement=True)
    category       = db.Column(db.String(50),  nullable=False)
    title          = db.Column(db.String(500), nullable=False)
    summary        = db.Column(db.Text, nullable=False)
    source         = db.Column(db.String(255), nullable=True)
    image_emoji    = db.Column(db.String(10),  nullable=True)
    category_color = db.Column(db.String(20),  nullable=True)
    is_featured    = db.Column(db.Boolean, default=False)
    published_at   = db.Column(db.DateTime, default=datetime.utcnow)


# ─────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────

@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        required = ['name', 'email', 'phone', 'password', 'confirm_password']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        if data['password'] != data['confirm_password']:
            return jsonify({'error': 'Passwords do not match'}), 400
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already registered'}), 409
        new_user = User(
            name=data['name'], email=data['email'], phone=data['phone'],
            password=generate_password_hash(data['password']),
            state=data.get('state', None)
        )
        db.session.add(new_user)
        db.session.commit()
        return jsonify({'message': 'User registered successfully'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Server error: {str(e)}'}), 500


@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        if not data or 'email' not in data or 'password' not in data:
            return jsonify({'error': 'Email and password required'}), 400
        # Try to find user by email OR phone number
        user = User.query.filter((User.email == data['email']) | (User.phone == data['email'])).first()
        if not user or not check_password_hash(user.password, data['password']):
            return jsonify({'error': 'Invalid credentials'}), 401
        session = ActiveSession(email=user.email)
        db.session.add(session)
        db.session.commit()
        return jsonify({'message': 'Login successful', 'user': {
            'id': user.id, 'name': user.name, 'email': user.email,
            'phone': user.phone, 'state': user.state
        }}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Server error: {str(e)}'}), 500

@app.route('/get_current_user', methods=['GET'])
def get_current_user():
    try:
        last = ActiveSession.query.order_by(ActiveSession.id.desc()).first()
        if not last:
            return jsonify({'error': 'No active user found'}), 404
        user = User.query.filter_by(email=last.email).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify({'id': user.id, 'name': user.name, 'email': user.email,
                        'phone': user.phone, 'state': user.state}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/logout', methods=['POST'])
def logout():
    try:
        data = request.get_json()
        email = data.get('email') if data else None
        if not email:
            return jsonify({'error': 'Email required'}), 400
        ActiveSession.query.filter_by(email=email).delete()
        db.session.commit()
        return jsonify({'message': 'Logged out successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# PROFILE & FARM DETAILS
# ─────────────────────────────────────────

@app.route('/profile/<int:user_id>', methods=['PUT'])
def update_profile(user_id):
    try:
        data = request.get_json()
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        user.name  = data.get('name',  user.name)
        user.phone = data.get('phone', user.phone)
        user.state = data.get('state', user.state)
        db.session.commit()
        return jsonify({'message': 'Profile updated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/farm_details/<int:user_id>', methods=['GET'])
def get_farm_details(user_id):
    try:
        farm = FarmDetail.query.filter_by(user_id=user_id).first()
        if not farm:
            return jsonify({'error': 'Farm details not found'}), 404
        return jsonify({
            'id': farm.id, 'user_id': farm.user_id,
            'land_area': float(farm.land_area) if farm.land_area else None,
            'primary_crops': farm.primary_crops, 'soil_type': farm.soil_type,
            'irrigation': farm.irrigation, 'region': farm.region
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/farm_details/<int:user_id>', methods=['PUT'])
def update_farm_details(user_id):
    try:
        data = request.get_json()
        farm = FarmDetail.query.filter_by(user_id=user_id).first()
        if not farm:
            farm = FarmDetail(user_id=user_id)
            db.session.add(farm)
        farm.land_area     = data.get('land_area',     farm.land_area)
        farm.primary_crops = data.get('primary_crops', farm.primary_crops)
        farm.soil_type     = data.get('soil_type',     farm.soil_type)
        farm.irrigation    = data.get('irrigation',    farm.irrigation)
        farm.region        = data.get('region',        farm.region)
        db.session.commit()
        return jsonify({'message': 'Farm details updated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# CROP ADVISORY
# ─────────────────────────────────────────

@app.route('/crop_advisories/<int:user_id>', methods=['GET'])
def get_crop_advisories(user_id):
    try:
        crop = request.args.get('crop')
        query = CropAdvisory.query.filter_by(user_id=user_id)
        if crop:
            query = query.filter_by(crop=crop)
        advisories = query.order_by(CropAdvisory.created_at.desc()).all()
        return jsonify([{
            'id': a.id, 'crop': a.crop, 'emoji': a.emoji,
            'title': a.title, 'description': a.description,
            'priority': a.priority,
            'created_at': a.created_at.strftime('%d %b %Y, %I:%M %p')
        } for a in advisories]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/crop_advisories', methods=['POST'])
def add_crop_advisory():
    try:
        data = request.get_json()
        required = ['user_id', 'crop', 'title', 'description']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        advisory = CropAdvisory(
            user_id=data['user_id'], crop=data['crop'],
            emoji=data.get('emoji', '🌿'), title=data['title'],
            description=data['description'], priority=data.get('priority', 'Info')
        )
        db.session.add(advisory)
        db.session.commit()
        return jsonify({'message': 'Advisory saved', 'id': advisory.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/crop_advisories/<int:advisory_id>', methods=['DELETE'])
def delete_crop_advisory(advisory_id):
    try:
        advisory = CropAdvisory.query.get(advisory_id)
        if not advisory:
            return jsonify({'error': 'Advisory not found'}), 404
        db.session.delete(advisory)
        db.session.commit()
        return jsonify({'message': 'Advisory deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# PEST & DISEASE
# ─────────────────────────────────────────

@app.route('/pest_alerts', methods=['GET'])
def get_pest_alerts():
    try:
        region = request.args.get('region')
        crop   = request.args.get('crop')
        query  = PestAlert.query
        if region:
            query = query.filter_by(region=region)
        if crop:
            query = query.filter_by(crop=crop)
        alerts = query.order_by(PestAlert.reported_at.desc()).all()
        return jsonify([{
            'id': a.id, 'region': a.region, 'crop': a.crop,
            'pest_name': a.pest_name, 'severity': a.severity,
            'description': a.description, 'treatment': a.treatment,
            'reported_at': a.reported_at.strftime('%d %b %Y')
        } for a in alerts]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/pest_alerts', methods=['POST'])
def add_pest_alert():
    try:
        data = request.get_json()
        required = ['region', 'crop', 'pest_name']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        alert = PestAlert(
            region=data['region'], crop=data['crop'],
            pest_name=data['pest_name'], severity=data.get('severity', 'Medium'),
            description=data.get('description', ''), treatment=data.get('treatment', '')
        )
        db.session.add(alert)
        db.session.commit()
        return jsonify({'message': 'Alert added', 'id': alert.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/treatments', methods=['GET'])
def get_treatments():
    try:
        crop  = request.args.get('crop')
        ttype = request.args.get('type')
        query = Treatment.query
        if crop:
            query = query.filter((Treatment.crop == crop) | (Treatment.crop == None))
        if ttype:
            query = query.filter_by(type=ttype)
        items = query.order_by(Treatment.created_at.desc()).all()
        return jsonify([{
            'id': t.id, 'name': t.name, 'description': t.description,
            'type': t.type, 'crop': t.crop
        } for t in items]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/treatments', methods=['POST'])
def add_treatment():
    try:
        data = request.get_json()
        required = ['name', 'description', 'type']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        t = Treatment(
            name=data['name'], description=data['description'],
            type=data['type'], crop=data.get('crop', None)
        )
        db.session.add(t)
        db.session.commit()
        return jsonify({'message': 'Treatment added', 'id': t.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# MARKET PRICES
# ─────────────────────────────────────────

@app.route('/market_prices', methods=['GET'])
def get_market_prices():
    try:
        mandi_name = request.args.get('mandi')
        category = request.args.get('category')
        query = MarketPrice.query
        if mandi_name:
            query = query.join(Mandi).filter(Mandi.mandi_name == mandi_name)
        if category and category != 'All':
            query = query.join(Crop).filter(Crop.category == category)
        prices = query.all()

        # If no prices exist for this mandi in the database, seed them automatically
        if mandi_name and not prices:
            mandi_obj = Mandi.query.filter_by(mandi_name=mandi_name).first()
            state_id = mandi_obj.state_id if mandi_obj else 1
            if not mandi_obj:
                mandi_obj = Mandi(mandi_name=mandi_name, state_id=1, district=mandi_name, location=mandi_name)
                db.session.add(mandi_obj)
                db.session.commit()
            
            import random
            default_commodities = [
                {'commodity': 'Paddy (Fine)', 'category': 'Cereals', 'price': 2200, 'prev': 2160, 'unit': 'qtl'},
                {'commodity': 'Maize', 'category': 'Cereals', 'price': 1850, 'prev': 1865, 'unit': 'qtl'},
                {'commodity': 'Groundnut', 'category': 'Oilseed', 'price': 5700, 'prev': 5620, 'unit': 'qtl'},
                {'commodity': 'Soybean', 'category': 'Oilseed', 'price': 4150, 'prev': 4125, 'unit': 'qtl'},
                {'commodity': 'Cotton', 'category': 'Fruits', 'price': 6200, 'prev': 6200, 'unit': 'qtl'},
                {'commodity': 'Sugarcane', 'category': 'Vegetables', 'price': 350, 'prev': 340, 'unit': 'ton'},
                {'commodity': 'Wheat', 'category': 'Cereals', 'price': 2400, 'prev': 2380, 'unit': 'qtl'},
            ]
            for c in default_commodities:
                crop_obj = Crop.query.filter_by(crop_name=c['commodity']).first()
                if not crop_obj:
                    crop_obj = Crop(crop_name=c['commodity'], category=c['category'])
                    db.session.add(crop_obj)
                    db.session.commit()
                
                db.session.add(MarketPrice(
                    mandi_id=mandi_obj.id,
                    crop_id=crop_obj.id,
                    minimum_price=float(c['price']) * 0.95,
                    maximum_price=float(c['price']) * 1.05,
                    modal_price=c['price'],
                    previous_price=c['prev'],
                    current_price=c['price'],
                    price_date=datetime.utcnow().date(),
                    updated_at=datetime.utcnow() - timedelta(hours=random.randint(1, 12))
                ))
            db.session.commit()
            
            # Re-fetch
            query = MarketPrice.query
            if mandi_name:
                query = query.join(Mandi).filter(Mandi.mandi_name == mandi_name)
            if category and category != 'All':
                query = query.join(Crop).filter(Crop.category == category)
            prices = query.all()

        result = []
        for p in prices:
            change = float(p.price) - float(p.prev_price)
            result.append({
                'id': p.id, 'mandi': p.mandi, 'commodity': p.commodity,
                'category': p.category, 'price': float(p.price),
                'prev_price': float(p.prev_price), 'change': round(change, 2),
                'is_up': change >= 0, 'unit': p.unit,
                'updated_at': p.updated_at.strftime('%d %b %Y %I:%M %p') if p.updated_at else None
            })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/market_prices', methods=['POST'])
def add_market_price():
    """Add a new commodity price entry"""
    try:
        data = request.get_json()
        required = ['mandi', 'commodity', 'category', 'price', 'prev_price']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
            
        mandi_obj = Mandi.query.filter_by(mandi_name=data['mandi']).first()
        if not mandi_obj:
            mandi_obj = Mandi(mandi_name=data['mandi'], state_id=1, district=data['mandi'], location=data['mandi'])
            db.session.add(mandi_obj)
            db.session.commit()
            
        crop_obj = Crop.query.filter_by(crop_name=data['commodity']).first()
        if not crop_obj:
            crop_obj = Crop(crop_name=data['commodity'], category=data['category'])
            db.session.add(crop_obj)
            db.session.commit()

        price = MarketPrice(
            mandi_id=mandi_obj.id,
            crop_id=crop_obj.id,
            minimum_price=float(data['price']) * 0.95,
            maximum_price=float(data['price']) * 1.05,
            modal_price=float(data['price']),
            previous_price=float(data['prev_price']),
            current_price=float(data['price']),
            unit=data.get('unit', '₹/quintal')
        )
        db.session.add(price)
        db.session.commit()
        return jsonify({'message': 'Price added', 'id': price.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/market_prices/<int:price_id>', methods=['PUT'])
def update_market_price(price_id):
    """Update existing commodity price (admin use)"""
    try:
        data  = request.get_json()
        price = MarketPrice.query.get(price_id)
        if not price:
            return jsonify({'error': 'Price not found'}), 404
        price.previous_price = float(price.current_price)
        price.current_price  = data.get('price', price.current_price)
        price.modal_price    = data.get('price', price.modal_price)
        price.updated_at = datetime.utcnow()
        db.session.commit()
        return jsonify({'message': 'Price updated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/mandis', methods=['GET'])
def get_mandis():
    try:
        mandis = Mandi.query.all()
        return jsonify([m.mandi_name for m in mandis]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# NEW STATE-BASED MARKET PRICES APIs
# ─────────────────────────────────────────

@app.route('/api/states', methods=['GET'])
def get_api_states():
    try:
        states = State.query.order_by(State.state_name.asc()).all()
        return jsonify([{
            'id': s.id,
            'state_name': s.state_name
        } for s in states]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mandis', methods=['GET'])
def get_api_mandis():
    try:
        state_name = request.args.get('state')
        query = Mandi.query
        if state_name:
            query = query.join(State).filter(State.state_name == state_name)
        mandis = query.order_by(Mandi.mandi_name.asc()).all()
        return jsonify([{
            'id': m.id,
            'mandi_name': m.mandi_name,
            'state_id': m.state_id,
            'state': m.state_rel.state_name if m.state_rel else "",
            'district': m.district,
            'location': m.location
        } for m in mandis]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/market-prices', methods=['GET'])
def get_api_market_prices():
    try:
        state_name = request.args.get('state')
        mandi_name = request.args.get('mandi')
        crop_name = request.args.get('crop')
        
        # Trigger live price fluctuation updates (if last update was > 3 minutes ago)
        try:
            last_price = MarketPrice.query.order_by(MarketPrice.updated_at.desc()).first()
            if last_price and (datetime.utcnow() - last_price.updated_at).total_seconds() > 180:
                from sqlalchemy import text
                db.session.execute(text("""
                    UPDATE market_prices 
                    SET 
                        previous_price = current_price,
                        current_price = ROUND((current_price * (1.0 + (random() * 0.035 - 0.015)))::numeric, 2),
                        updated_at = NOW()
                    WHERE price_date = CURRENT_DATE
                """))
                db.session.execute(text("""
                    UPDATE market_prices
                    SET
                        minimum_price = ROUND((current_price * 0.95)::numeric, 2),
                        maximum_price = ROUND((current_price * 1.05)::numeric, 2),
                        modal_price = current_price
                    WHERE price_date = CURRENT_DATE
                """))
                db.session.commit()
        except Exception as ex:
            db.session.rollback()
            print("Fluctuation update failed:", ex)


        query = MarketPrice.query.join(Mandi).join(Crop)
        
        if state_name:
            query = query.join(State, Mandi.state_id == State.id).filter(State.state_name == state_name)
        if mandi_name:
            query = query.filter(Mandi.mandi_name == mandi_name)
        if crop_name:
            query = query.filter(Crop.crop_name == crop_name)
            
        prices = query.order_by(MarketPrice.updated_at.desc()).all()
        
        mandi_map = {}
        for p in prices:
            m_id = p.mandi_id
            if m_id not in mandi_map:
                mandi_map[m_id] = {
                    'mandi_name': p.mandi_rel.mandi_name,
                    'district': p.mandi_rel.district,
                    'prices': []
                }
            
            # Prevent double entries for chart/history in base listing
            if any(pr['crop'] == p.crop_rel.crop_name for pr in mandi_map[m_id]['prices']):
                continue
                
            change = float(p.current_price) - float(p.previous_price)
            pct_change = round((change / float(p.previous_price)) * 100, 2) if float(p.previous_price) > 0 else 0.0
            
            trend = "STABLE"
            if change > 0:
                trend = "RISING"
            elif change < 0:
                trend = "FALLING"
                
            mandi_map[m_id]['prices'].append({
                'crop': p.crop_rel.crop_name,
                'minimum_price': float(p.minimum_price) if p.minimum_price else float(p.current_price),
                'maximum_price': float(p.maximum_price) if p.maximum_price else float(p.current_price),
                'modal_price': float(p.modal_price) if p.modal_price else float(p.current_price),
                'previous_price': float(p.previous_price),
                'current_price': float(p.current_price),
                'price_change': round(change, 2),
                'percentage_change': pct_change,
                'trend': trend,
                'unit': p.unit,
                'updated_at': p.updated_at.strftime('%Y-%m-%d')
            })
            
        return jsonify({
            'state': state_name or "All States",
            'mandis': list(mandi_map.values())
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/price-history', methods=['GET'])
def get_price_history():
    try:
        mandi_name = request.args.get('mandi')
        crop_name = request.args.get('crop')
        days = int(request.args.get('days', 30))
        
        if not mandi_name or not crop_name:
            return jsonify({'error': 'Missing mandi or crop name'}), 400
            
        query = MarketPrice.query.join(Mandi).join(Crop)\
            .filter(Mandi.mandi_name == mandi_name)\
            .filter(Crop.crop_name == crop_name)\
            .order_by(MarketPrice.price_date.asc())
            
        prices = query.all()
        if len(prices) > days:
            prices = prices[-days:]
            
        return jsonify([{
            'date': p.price_date.strftime('%Y-%m-%d'),
            'price': float(p.current_price),
            'prev_price': float(p.previous_price),
            'modal_price': float(p.modal_price) if p.modal_price else float(p.current_price)
        } for p in prices]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# FARM SCHEDULE
# ─────────────────────────────────────────

@app.route('/farm_schedule/<int:user_id>', methods=['GET'])
def get_farm_schedule(user_id):
    try:
        schedules = FarmSchedule.query.filter_by(user_id=user_id)\
            .order_by(FarmSchedule.scheduled_at.asc()).all()
        return jsonify([{
            'id': s.id, 'activity': s.activity,
            'scheduled_at': s.scheduled_at.strftime('%d %b %Y, %I:%M %p'),
            'status': s.status
        } for s in schedules]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/farm_schedule', methods=['POST'])
def add_farm_schedule():
    try:
        data = request.get_json()
        required = ['user_id', 'activity', 'scheduled_at']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        schedule = FarmSchedule(
            user_id=data['user_id'], activity=data['activity'],
            scheduled_at=datetime.strptime(data['scheduled_at'], '%Y-%m-%d %H:%M'),
            status='pending'
        )
        db.session.add(schedule)
        db.session.commit()
        return jsonify({'message': 'Activity added', 'id': schedule.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/farm_schedule/<int:schedule_id>', methods=['PUT'])
def update_schedule_status(schedule_id):
    try:
        data     = request.get_json()
        schedule = FarmSchedule.query.get(schedule_id)
        if not schedule:
            return jsonify({'error': 'Schedule not found'}), 404
        schedule.status = data.get('status', schedule.status)
        db.session.commit()
        return jsonify({'message': 'Status updated'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/farm_schedule/<int:schedule_id>', methods=['DELETE'])
def delete_farm_schedule(schedule_id):
    try:
        schedule = FarmSchedule.query.get(schedule_id)
        if not schedule:
            return jsonify({'error': 'Schedule not found'}), 404
        db.session.delete(schedule)
        db.session.commit()
        return jsonify({'message': 'Activity deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


# ─────────────────────────────────────────
# FARMING TIPS & NEWS
# ─────────────────────────────────────────

@app.route('/farming_tips', methods=['GET'])
def get_farming_tips():
    try:
        category = request.args.get('category')
        query    = FarmingTip.query
        if category:
            query = query.filter_by(category=category)
        tips = query.order_by(FarmingTip.created_at.desc()).all()
        return jsonify([{
            'id': t.id, 'icon': t.icon, 'title': t.title,
            'description': t.description, 'tag': t.tag, 'category': t.category
        } for t in tips]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/farming_tips', methods=['POST'])
def add_farming_tip():
    try:
        data = request.get_json()
        required = ['icon', 'title', 'description']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        tip = FarmingTip(
            icon=data['icon'], title=data['title'],
            description=data['description'], tag=data.get('tag', ''),
            category=data.get('category', 'General')
        )
        db.session.add(tip)
        db.session.commit()
        return jsonify({'message': 'Tip added', 'id': tip.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/news_articles', methods=['GET'])
def get_news_articles():
    try:
        category = request.args.get('category')
        featured = request.args.get('featured')
        limit    = int(request.args.get('limit', 20))
        query    = NewsArticle.query
        if category and category != 'All':
            query = query.filter_by(category=category)
        if featured == 'true':
            query = query.filter_by(is_featured=True)
        articles = query.order_by(NewsArticle.published_at.desc()).limit(limit).all()
        return jsonify([{
            'id': a.id, 'category': a.category, 'title': a.title,
            'summary': a.summary, 'source': a.source,
            'image_emoji': a.image_emoji, 'category_color': a.category_color,
            'is_featured': a.is_featured,
            'published_at': a.published_at.strftime('%d %b %Y')
        } for a in articles]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/news_articles', methods=['POST'])
def add_news_article():
    try:
        data = request.get_json()
        required = ['category', 'title', 'summary']
        if not data or not all(k in data for k in required):
            return jsonify({'error': 'Missing required fields'}), 400
        article = NewsArticle(
            category=data['category'], title=data['title'],
            summary=data['summary'], source=data.get('source', 'Agrosmart'),
            image_emoji=data.get('image_emoji', '📰'),
            category_color=data.get('category_color', '#2D6A4F'),
            is_featured=data.get('is_featured', False)
        )
        db.session.add(article)
        db.session.commit()
        return jsonify({'message': 'Article added', 'id': article.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

def _seed_static_data():
    """Seed treatments, tips, news if tables are empty"""

    # Treatments
    if Treatment.query.count() == 0:
        treatments = [
            Treatment(name='Chlorpyrifos 20 EC', type='Chemical',
                description='Spray 2ml/L water for FAW control. Apply during evening hours.'),
            Treatment(name='Tricyclazole 75 WP', type='Fungicide',
                description='Use 0.6g/L water for blast control. 2 sprays 15 days apart.'),
            Treatment(name='Neem Oil Spray', type='Bio-Pesticide',
                description='Eco-friendly: 5ml/L water, spray weekly for BPH and aphids.'),
            Treatment(name='Imidacloprid 17.8 SL', type='Chemical',
                description='Apply 0.3ml/L water for sucking pests like whitefly and BPH.'),
            Treatment(name='Copper Oxychloride', type='Fungicide',
                description='3g/L water for bacterial and fungal diseases. Spray at first sign.'),
            Treatment(name='Trichoderma viride', type='Bio-Pesticide',
                description='Soil application 2.5kg/acre for root rot and damping off prevention.'),
        ]
        for t in treatments:
            db.session.add(t)

    # Farming tips
    if FarmingTip.query.count() == 0:
        tips = [
            FarmingTip(icon='🌱', title='Seed Treatment', tag='Pre-Sowing', category='Sowing',
                description='Treat seeds with fungicide + insecticide before sowing to prevent soil-borne diseases.'),
            FarmingTip(icon='🌿', title='Intercropping Benefits', tag='Soil Health', category='Soil',
                description='Growing legumes alongside cereals improves soil nitrogen naturally, reducing fertilizer cost by 25%.'),
            FarmingTip(icon='💊', title='Nutrient Management', tag='Fertilization', category='Fertilizer',
                description='Split fertilizer application (basal + top-dress) improves uptake efficiency.'),
            FarmingTip(icon='🔍', title='Scouting Protocol', tag='Pest Control', category='Pest',
                description='Walk fields in W-pattern twice a week. Early detection saves 70% on pesticide costs.'),
            FarmingTip(icon='💧', title='Deficit Irrigation', tag='Water Saving', category='Irrigation',
                description='Apply irrigation at critical growth stages only. Saves 30% water vs continuous flooding.'),
            FarmingTip(icon='🌾', title='Crop Rotation', tag='Soil Health', category='Soil',
                description='Rotate crops every season to break pest cycles and improve soil structure naturally.'),
        ]
        for t in tips:
            db.session.add(t)

    # News articles
    if NewsArticle.query.count() == 0:
        articles = [
            NewsArticle(category='Market Update', is_featured=True, image_emoji='🌾',
                category_color='#E07B39', source='Agrosmart Market Daily',
                title='Wheat Prices Surge 12% Amid Global Supply Concerns',
                summary='International wheat futures climbed sharply this week as drought conditions persist in key growing regions.'),
            NewsArticle(category='Technology', image_emoji='💧',
                category_color='#2196F3', source='FarmTech Review',
                title='AI-Powered Irrigation Systems Cut Water Usage by 40%',
                summary='Smart drip systems with soil-moisture sensors help farmers reduce water consumption while maintaining yield.'),
            NewsArticle(category='Pest Alert', image_emoji='🐛',
                category_color='#E53935', source='Crop Protection News',
                title='Fall Armyworm Detected in Northern Districts',
                summary='Agricultural authorities issued an advisory after fall armyworm infestations were confirmed in multiple zones.'),
            NewsArticle(category='Policy', image_emoji='🏛️',
                category_color='#7B1FA2', source='Agrosmart Policy Hub',
                title='Govt Announces ₹50,000 Cr Subsidy Package for Farmers',
                summary='New relief package supports small farmers with fertilizer subsidies and low-interest crop loans.'),
            NewsArticle(category='Climate', image_emoji='🌧️',
                category_color='#00897B', source='Weather & Agro',
                title='IMD Forecasts Above-Normal Monsoon This Season',
                summary='India Meteorological Department predicts 106% of long-period average rainfall this Kharif season.'),
        ]
        for a in articles:
            db.session.add(a)

    # Pest alerts
    if PestAlert.query.count() == 0:
        alerts = [
            PestAlert(region='Kurnool', crop='Paddy', pest_name='Brown Planthopper',
                severity='High', description='Yellowing and drying of plants in patches.',
                treatment='Apply Imidacloprid 17.8% SL at 0.3ml/L water.'),
            PestAlert(region='Kurnool', crop='Maize', pest_name='Fall Armyworm',
                severity='High', description='Leaf damage with circular holes.',
                treatment='Spray Chlorpyrifos 20% EC at 2ml/L water.'),
            PestAlert(region='Kurnool', crop='Cotton', pest_name='Whitefly',
                severity='Medium', description='Yellowing of leaves, sticky honeydew.',
                treatment='Apply Acetamiprid 20% SP at 0.2g/L water.'),
        ]
        for a in alerts:
            db.session.add(a)

    # Seed States, Crops, Mandis, and Market Prices if State table is empty
    if State.query.count() == 0:
        # 1. Add States
        states_list = [
            'Andhra Pradesh', 'Telangana', 'Karnataka', 'Tamil Nadu', 
            'Maharashtra', 'Kerala', 'Odisha', 'West Bengal', 'Gujarat', 
            'Rajasthan', 'Punjab', 'Haryana', 'Uttar Pradesh', 'Madhya Pradesh', 
            'Bihar', 'Chhattisgarh', 'Jharkhand', 'Assam'
        ]
        states_db = {}
        for s_name in states_list:
            state = State(state_name=s_name)
            db.session.add(state)
            states_db[s_name] = state
        db.session.commit() # commit so they get IDs

        # 2. Add Crops
        crops_list = [
            {'name': 'Rice', 'cat': 'Cereals'},
            {'name': 'Paddy (Fine)', 'cat': 'Cereals'},
            {'name': 'Cotton', 'cat': 'Oilseed'},
            {'name': 'Red Chilli', 'cat': 'Vegetables'},
            {'name': 'Maize', 'cat': 'Cereals'},
            {'name': 'Groundnut', 'cat': 'Oilseed'},
            {'name': 'Tomato', 'cat': 'Vegetables'},
            {'name': 'Onion', 'cat': 'Vegetables'},
            {'name': 'Turmeric', 'cat': 'Vegetables'},
            {'name': 'Soybean', 'cat': 'Oilseed'},
            {'name': 'Wheat', 'cat': 'Cereals'},
            {'name': 'Sugarcane', 'cat': 'Vegetables'}
        ]
        crops_db = {}
        for c in crops_list:
            crop = Crop(crop_name=c['name'], category=c['cat'])
            db.session.add(crop)
            crops_db[c['name']] = crop
        db.session.commit()

        # 3. Add Mandis
        mandis_list = [
            # Andhra Pradesh
            {'name': 'Guntur Market Yard', 'state': 'Andhra Pradesh', 'dist': 'Guntur', 'loc': 'Guntur'},
            {'name': 'Vijayawada Market', 'state': 'Andhra Pradesh', 'dist': 'Krishna', 'loc': 'Vijayawada'},
            {'name': 'Kurnool Market', 'state': 'Andhra Pradesh', 'dist': 'Kurnool', 'loc': 'Kurnool'},
            {'name': 'Nellore Market', 'state': 'Andhra Pradesh', 'dist': 'Nellore', 'loc': 'Nellore'},
            {'name': 'Anantapur Market', 'state': 'Andhra Pradesh', 'dist': 'Anantapur', 'loc': 'Anantapur'},
            {'name': 'Kadapa Market', 'state': 'Andhra Pradesh', 'dist': 'Kadapa', 'loc': 'Kadapa'},
            # Telangana
            {'name': 'Hyderabad Mandi', 'state': 'Telangana', 'dist': 'Hyderabad', 'loc': 'Bowenpally'},
            {'name': 'Warangal Market', 'state': 'Telangana', 'dist': 'Warangal', 'loc': 'Warangal'},
            # Karnataka
            {'name': 'Bengaluru Mandi', 'state': 'Karnataka', 'dist': 'Bengaluru', 'loc': 'Yeshwanthpur'},
            {'name': 'Hubli Market', 'state': 'Karnataka', 'dist': 'Dharwad', 'loc': 'Hubli'},
            # Tamil Nadu
            {'name': 'Chennai Koyambedu', 'state': 'Tamil Nadu', 'dist': 'Chennai', 'loc': 'Koyambedu'},
            {'name': 'Coimbatore Market', 'state': 'Tamil Nadu', 'dist': 'Coimbatore', 'loc': 'MTP Road'},
            # Maharashtra
            {'name': 'Pune Mandi', 'state': 'Maharashtra', 'dist': 'Pune', 'loc': 'Gultekdi'},
            {'name': 'Mumbai Mandi', 'state': 'Maharashtra', 'dist': 'Mumbai', 'loc': 'Vashi'},
            # Kerala
            {'name': 'Kochi Market', 'state': 'Kerala', 'dist': 'Ernakulam', 'loc': 'Nettoor'},
            {'name': 'Kozhikode Mandi', 'state': 'Kerala', 'dist': 'Kozhikode', 'loc': 'Kozhikode'},
            # Odisha
            {'name': 'Bhubaneswar Mandi', 'state': 'Odisha', 'dist': 'Khurda', 'loc': 'Bhubaneswar'},
            {'name': 'Cuttack Market', 'state': 'Odisha', 'dist': 'Cuttack', 'loc': 'Cuttack'},
            # West Bengal
            {'name': 'Kolkata Mandi', 'state': 'West Bengal', 'dist': 'Kolkata', 'loc': 'Barabazar'},
            {'name': 'Siliguri Market', 'state': 'West Bengal', 'dist': 'Darjeeling', 'loc': 'Siliguri'},
            # Gujarat
            {'name': 'Ahmedabad Mandi', 'state': 'Gujarat', 'dist': 'Ahmedabad', 'loc': 'Jamalpur'},
            {'name': 'Surat Market', 'state': 'Gujarat', 'dist': 'Surat', 'loc': 'Surat'},
            # Rajasthan
            {'name': 'Jaipur Mandi', 'state': 'Rajasthan', 'dist': 'Jaipur', 'loc': 'Muhana Terminal'},
            {'name': 'Jodhpur Market', 'state': 'Rajasthan', 'dist': 'Jodhpur', 'loc': 'Bhagat Ki Kothi'},
            # Punjab
            {'name': 'Ludhiana Mandi', 'state': 'Punjab', 'dist': 'Ludhiana', 'loc': 'Gill Road'},
            {'name': 'Amritsar Market', 'state': 'Punjab', 'dist': 'Amritsar', 'loc': 'Amritsar'},
            # Haryana
            {'name': 'Karnal Mandi', 'state': 'Haryana', 'dist': 'Karnal', 'loc': 'Karnal'},
            {'name': 'Ambala Market', 'state': 'Haryana', 'dist': 'Ambala', 'loc': 'Ambala Cantt'},
            # Uttar Pradesh
            {'name': 'Lucknow Mandi', 'state': 'Uttar Pradesh', 'dist': 'Uttar Pradesh', 'loc': 'Aliganj'},
            {'name': 'Kanpur Market', 'state': 'Uttar Pradesh', 'dist': 'Kanpur', 'loc': 'Kanpur'},
            # Madhya Pradesh
            {'name': 'Indore Mandi', 'state': 'Madhya Pradesh', 'dist': 'Indore', 'loc': 'Choithram'},
            {'name': 'Bhopal Market', 'state': 'Madhya Pradesh', 'dist': 'Bhopal', 'loc': 'Karond'},
            # Bihar
            {'name': 'Patna Mandi', 'state': 'Bihar', 'dist': 'Patna', 'loc': 'Bazar Samiti'},
            {'name': 'Muzaffarpur Market', 'state': 'Bihar', 'dist': 'Muzaffarpur', 'loc': 'Muzaffarpur'},
            # Chhattisgarh
            {'name': 'Raipur Mandi', 'state': 'Chhattisgarh', 'dist': 'Raipur', 'loc': 'Dumartara'},
            # Jharkhand
            {'name': 'Ranchi Mandi', 'state': 'Jharkhand', 'dist': 'Ranchi', 'loc': 'Pandra'},
            # Assam
            {'name': 'Guwahati Mandi', 'state': 'Assam', 'dist': 'Kamrup', 'loc': 'Guwahati'}
        ]
        mandis_db = []
        for m in mandis_list:
            state_obj = states_db.get(m['state'])
            if state_obj:
                mandi = Mandi(
                    mandi_name=m['name'],
                    state_id=state_obj.id,
                    district=m['dist'],
                    location=m['loc']
                )
                db.session.add(mandi)
                mandis_db.append({'obj': mandi, 'state_name': m['state']})
        db.session.commit()

        # 4. Add Market Prices with 30-day history
        import random
        from datetime import datetime, timedelta
        
        prices_to_insert = []
        for m_data in mandis_db:
            mandi = m_data['obj']
            
            # Select 4-7 random crops for this mandi
            selected_crops = list(crops_db.values())
            random.shuffle(selected_crops)
            selected_crops = selected_crops[:random.randint(4, 7)]
            
            for crop in selected_crops:
                # Base price for this crop
                base_price = 2000
                if 'chilli' in crop.crop_name.lower(): base_price = 18000
                elif 'ground' in crop.crop_name.lower(): base_price = 5500
                elif 'cotton' in crop.crop_name.lower(): base_price = 6000
                elif 'soy' in crop.crop_name.lower(): base_price = 4000
                elif 'sugar' in crop.crop_name.lower(): base_price = 350
                elif 'tomato' in crop.crop_name.lower(): base_price = 1500
                elif 'onion' in crop.crop_name.lower(): base_price = 2000
                
                current_val = base_price
                for day_offset in range(30, -1, -1):
                    price_date = (datetime.utcnow() - timedelta(days=day_offset)).date()
                    change_pct = random.uniform(-0.03, 0.04) # -3% to +4% change
                    prev_val = current_val
                    current_val = round(prev_val * (1 + change_pct), 2)
                    
                    min_val = round(current_val * 0.95, 2)
                    max_val = round(current_val * 1.05, 2)
                    
                    prices_to_insert.append({
                        'mandi_id': mandi.id,
                        'crop_id': crop.id,
                        'minimum_price': min_val,
                        'maximum_price': max_val,
                        'modal_price': current_val,
                        'previous_price': prev_val,
                        'current_price': current_val,
                        'price_date': price_date,
                        'updated_at': datetime.combine(price_date, datetime.min.time()) + timedelta(hours=random.randint(8, 17)),
                        'unit': '₹/quintal' if 'sugar' not in crop.crop_name.lower() else '₹/ton'
                    })
        
        if prices_to_insert:
            db.session.bulk_insert_mappings(MarketPrice, prices_to_insert)
            db.session.commit()


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'service': 'AGROSMART API'}), 200


@app.route('/api/ask-ai', methods=['POST'])
def ask_ai():
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({'error': 'Message required'}), 400
            
        msg = data['message'].lower().strip()
        
        response_text = ""
        if "chilli" in msg or "pepper" in msg:
            if "pest" in msg or "insect" in msg or "disease" in msg or "control" in msg:
                response_text = "For red chilli, common pests are thrips, mites, and pod borers. I recommend spraying Neem Oil 10,000 PPM @ 2ml/L, or Fipronil 5% SC @ 2ml/L for thrips control. Ensure yellow and blue sticky traps are installed in your field."
            elif "fertilizer" in msg or "npk" in msg or "nutri" in msg:
                response_text = "Chilli crop requires 120:60:60 kg/ha of N:P:K. Apply the full dose of P and half dose of N and K at planting. Top dress the remaining N and K in two equal splits at 30 and 60 days after transplanting."
            elif "irrigation" in msg or "water" in msg:
                response_text = "Chilli is sensitive to waterlogging. Maintain moisture using drip irrigation (irrigate for 1-2 hours daily or every alternate day depending on soil dryness). Suspend irrigation during harvest intervals."
            else:
                response_text = "Red chilli grows best in well-drained loamy soil with a pH of 6.0-7.0. Popular high-yielding varieties include Teja, Guntur Sannam, and Byadagi. Keep the soil moist but avoid logging."
        elif "paddy" in msg or "rice" in msg:
            if "pest" in msg or "insect" in msg or "disease" in msg or "control" in msg:
                response_text = "In paddy fields, watch out for Brown Planthopper (BPH) and Stem Borer. Spray Imidacloprid 17.8% SL @ 0.3ml/L water for BPH, or apply Cartap Hydrochloride 4G granules @ 10kg/acre to control stem borers."
            elif "fertilizer" in msg or "npk" in msg or "nutri" in msg:
                response_text = "Recommended NPK for Paddy is 120:40:40 kg/ha. Apply nitrogen in three equal splits: at transplanting, active tillering (30 days), and panicle initiation (60 days) to boost grain yield."
            elif "irrigation" in msg or "water" in msg:
                response_text = "Paddy needs continuous shallow submergence (2-5 cm of standing water) during vegetative and flowering stages. Drain the water fully 10-15 days before harvesting to allow drying."
            else:
                response_text = "Paddy thrives in clayey loam soils that retain moisture. High-yielding varieties include Swarna, Samba Mahsuri, and IR64. Maintain shallow standing water during early growth."
        elif "cotton" in msg:
            if "pest" in msg or "insect" in msg or "disease" in msg or "control" in msg:
                response_text = "For cotton crops, major threats are Whiteflies and Pink Bollworm. Spray Acetamiprid 20% SP @ 0.2g/L or use pheromone traps (5 per acre) for Pink Bollworms. Avoid excessive nitrogen which attracts whiteflies."
            elif "fertilizer" in msg or "npk" in msg or "nutri" in msg:
                response_text = "Apply 100:50:50 kg/ha N:P:K for cotton. Apply half nitrogen and full phosphorus/potash at sowing, and top-dress the remaining nitrogen in splits during squaring and flowering stages."
            elif "irrigation" in msg or "water" in msg:
                response_text = "Cotton is deep-rooted and drought-tolerant but needs irrigation during flowering and boll development. Drip irrigation is highly recommended to prevent boll shedding."
            else:
                response_text = "Cotton grows best in black cotton soil (regur) which has high water-retaining capacity. Keep the field free of weeds during the first 60 days of growth."
        elif "maize" in msg or "corn" in msg:
            if "pest" in msg or "insect" in msg or "disease" in msg or "control" in msg:
                response_text = "Fall Armyworm is the most critical pest for Maize. Spray Chlorpyrifos 20% EC @ 2ml/L water or apply Emamectin Benzoate 5% SG @ 0.4g/L directly into the leaf whorls at early infestation."
            else:
                response_text = "Maize requires well-drained fertile loam soils. Keep soil moist during tasseling and silking stages, as water stress then can reduce yield by up to 50%."
        elif "tomato" in msg:
            if "pest" in msg or "insect" in msg or "disease" in msg or "control" in msg:
                response_text = "For tomato plants, watch for Leaf Miners and Early Blight. Spray Chlorothalonil 75% WP @ 2g/L for blight, and use yellow sticky cards to capture leaf miners."
            else:
                response_text = "Tomatoes need warm weather and structured staking. Water at the base of the plant rather than on leaves to prevent fungal infections."
        elif "weather" in msg or "rain" in msg:
            response_text = "Please visit the Weather Forecast section from the home dashboard. I recommend checking daily rain probability to schedule your sprays and fertilizer applications."
        elif "hello" in msg or "hi" in msg or "hey" in msg:
            response_text = "Hello! I am your Agrosmart AI Assistant. How can I help you with your crop health, fertilizer scheduling, irrigation, or pest protection today?"
        else:
            response_text = "To help you best, could you please specify the crop you are cultivating (e.g. Paddy, Cotton, Chilli, Maize, Groundnut) and the issue (irrigation, fertilizer, or pest control)?"

        return jsonify({
            'query': data['message'],
            'response': response_text,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500




# ─────────────────────────────────────────
# DATABASE INITIALIZATION (Runs in Gunicorn & Dev)
# ─────────────────────────────────────────
with app.app_context():
    db.create_all()
    _seed_static_data()


if __name__ == '__main__':
    # use_reloader=False prevents the double-process issue that breaks localtunnel
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)