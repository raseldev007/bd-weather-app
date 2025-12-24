from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import urllib.request
import json
import random
import datetime
from typing import List, Optional

app = FastAPI()

# Allow CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURATION (MASTER BLUEPRINT) ---

TRUSTED_SOURCES = ["BMD", "The Daily Star", "Prothom Alo", "The Daily Naya Diganta", "FFWC"]

# Thresholds for Weather Signal Engine (PART 1.A)
HEAVY_RAIN_THRESHOLD = 10.0  # mm/h
CYCLONE_WIND_THRESHOLD = 50.0  # km/h
HEAT_STRESS_THRESHOLD = 40.0 # Heat Index
LIGHTNING_THRESHOLD = 30.0 # Percentage probability

DIVISION_COORDS = {
    'Dhaka': {'lat': 23.8103, 'lng': 90.4125},
    'Chattogram': {'lat': 22.3569, 'lng': 91.7832},
    'Rajshahi': {'lat': 24.3636, 'lng': 88.6241},
    'Khulna': {'lat': 22.8456, 'lng': 89.5403},
    'Barishal': {'lat': 22.7010, 'lng': 90.3535},
    'Sylhet': {'lat': 24.8949, 'lng': 91.8687},
    'Rangpur': {'lat': 25.7439, 'lng': 89.2752},
    'Mymensingh': {'lat': 24.7471, 'lng': 90.4203},
}

def map_weather_code(code: int) -> str:
    if code == 0: return "Clear"
    if code in [1, 2, 3]: return "Cloudy"
    if code in [45, 48]: return "Foggy"
    if code in [51, 53, 55, 61, 63, 65, 80, 81, 82]: return "Rainy"
    if code in [71, 73, 75, 85, 86]: return "Snowy"
    if code in [95, 96, 99]: return "Stormy"
    return "Variable"

# --- ENGINE A: WEATHER SIGNAL ENGINE ---

def get_signals(weather, lat, lng):
    signals = []
    
    # Rainfall Check
    rainfall = weather.get('precipitation', 0)
    if rainfall >= HEAVY_RAIN_THRESHOLD:
        signals.append({"type": "heavy_rain", "severity": "high", "val": rainfall})
    
    # Flood Risk (Mocked context: continuous rain + low-lying)
    if rainfall > 5.0 and "Sylhet" in weather.get('district', ''):
         signals.append({"type": "flood_risk", "severity": "emergency", "val": rainfall})

    # Cyclone Check
    wind = weather.get('windspeed', 0)
    if wind >= CYCLONE_WIND_THRESHOLD:
         signals.append({"type": "cyclone", "severity": "emergency", "val": wind})

    # Heat Stress Check
    temp = weather.get('temperature', 20)
    humid = weather.get('humidity', 50)
    # Simple Heat Index proxy: Temp + (Humidity/10)
    heat_index = temp + (humid / 10)
    if heat_index >= HEAT_STRESS_THRESHOLD:
         signals.append({"type": "heat_stress", "severity": "high", "val": heat_index})

    # Lightning Probability (Mocked)
    if "Storm" in weather.get('condition', ''):
         signals.append({"type": "lightning", "severity": "high", "val": 80})

    return signals

# --- FETCHING ---

def fetch_real_weather(lat: float, lng: float, district: str = "Dhaka"):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true&hourly=temperature_2m,relative_humidity_2m,precipitation,weathercode&daily=temperature_2m_max,temperature_2m_min&timezone=auto"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            current = data['current_weather']
            hourly = data['hourly']
            
            current_time = current['time']
            time_idx = hourly['time'].index(current_time) if current_time in hourly['time'] else 0
            humidity = hourly['relative_humidity_2m'][time_idx] if time_idx < len(hourly['relative_humidity_2m']) else 50
            precipitation = hourly['precipitation'][time_idx] if time_idx < len(hourly['precipitation']) else 0
            
            return {
                "district": district,
                "temperature": current['temperature'],
                "condition": map_weather_code(current['weathercode']),
                "humidity": humidity,
                "precipitation": precipitation,
                "windspeed": current['windspeed'],
                "hourly": data['hourly'],
                "daily": data['daily']
            }
    except Exception as e:
        print(f"Error fetching weather: {e}")
        return None

# --- ENGINE C: INSIGHT GENERATION ENGINE ---

def generate_insights(signals, user_mode, district):
    insights = []
    
    if not signals:
        # Default calm insight
        insights.append({
            "type": "weather",
            "severity": "normal",
            "summary": "Weather is stable for now.",
            "bn_summary": "আবহাওয়া বর্তমানে স্থিতিশীল।",
            "why_this_alert": {"trigger": "Seasonal Norm", "time_window": "Next 6h", "bn_trigger": "স্বাভাবিক অবস্থা"},
            "confidence": "High",
            "actions": ["Stay hydrated", "Carry light umbrella if walking"],
            "bn_actions": ["পর্যাপ্ত পানি পান করুন", "বাইরে যাওয়ার সময় ছোট ছাতা রাখুন"],
            "who_is_affected": "General residents",
            "bn_who_is_affected": "সাধারণ বাসিন্দা"
        })
    
    for sig in signals:
        insight = {
            "type": "weather",
            "severity": sig['severity'],
            "confidence": "High" if sig['severity'] != 'emergency' else "Extreme",
            "who_is_affected": f"Residents of {district}",
            "bn_who_is_affected": f"{district} অঞ্চলের বাসিন্দারা"
        }
        
        if sig['type'] == "heavy_rain":
            insight.update({
                "summary": f"Heavy rainfall ({sig['val']}mm) expected.",
                "bn_summary": f"ভারী বৃষ্টিপাত ({sig['val']}মিমি) হতে পারে।",
                "why_this_alert": {"trigger": "Precipitation Spike", "time_window": "Next 3h", "bn_trigger": "বৃষ্টির পরিমাণ বৃদ্ধি"},
                "actions": ["Avoid waterlogged areas", "Plan travel carefully"]
            })
        elif sig['type'] == "flood_risk":
             insight.update({
                "summary": "Immediate Flood Risk - High Alert",
                "bn_summary": "তাৎক্ষণিক বন্যার ঝুঁকি - উচ্চ সতর্কতা",
                "why_this_alert": {"trigger": "Continuous Heavy Rainfall", "time_window": "Next 12h", "bn_trigger": "টানা ভারী বৃষ্টি"},
                "actions": ["Move valuables to high ground", "Keep emergency kits ready"]
            })
        elif sig['type'] == "heat_stress":
             insight.update({
                "summary": f"Excessive Heat Index: {sig['val']}",
                "bn_summary": f"অত্যাধিক তাপ অনুভূত হচ্ছে: {sig['val']}",
                "why_this_alert": {"trigger": "High Temp + Humidity", "time_window": "Daylight hours", "bn_trigger": "উচ্চ তাপমাত্রা ও আর্দ্রতা"},
                "actions": ["Drink oral saline", "Avoid sun exposure 11am-4pm"]
            })

        # --- ENGINE D: PERSONALIZATION LAYER ---
        if user_mode == "student":
             insight['actions'].append("Protect your school books from moisture.")
        elif user_mode == "farmer":
             if sig['type'] == "heavy_rain":
                 insight['actions'].append("Check field drainage immediately.")
             elif sig['type'] == "heat_stress":
                 insight['actions'].append("Irrigate crops early morning.")

        # Localization of actions
        insight['bn_actions'] = [f"অ্যাকশন: {a}" for a in insight['actions']] # Mock translation for speed
        insights.append(insight)

    # --- ENGINE F: RANKING ENGINE ---
    def rank_score(x):
        base = 100 if x['severity'] == 'emergency' else (50 if x['severity'] == 'high' else 0)
        return base
    
    insights.sort(key=rank_score, reverse=True)
    return insights[:3] # LIMIT visible_insights TO 3

# --- API ENDPOINTS ---

@app.get("/")
def read_root():
    return {"message": "Bangladesh Weather Intelligence API", "version": "v1.2 (Blueprint Aligned)"}

@app.get("/api/v1/insights/home")
def get_home_insights(district: str = "Dhaka", mode: str = "general"):
    coords = DIVISION_COORDS.get(district, DIVISION_COORDS['Dhaka'])
    weather = fetch_real_weather(coords['lat'], coords['lng'], district)
    
    if not weather:
        return {"error": "Weather data unavailable"}
    
    signals = get_signals(weather, coords['lat'], coords['lng'])
    insights = generate_insights(signals, mode, district)
    
    # Override for safety (PART 3.B)
    is_emergency = any(i['severity'] == "emergency" for i in insights)
    
    return {
        "location": {"district": district, "division": district},
        "current_weather": weather,
        "primary_insight": insights[0] if insights else None,
        "all_insights": insights,
        "is_emergency": is_emergency,
        "next_6_hours_risk": "high" if is_emergency or any(s['severity'] == 'high' for s in signals) else "low"
    }

@app.get("/api/v1/alerts")
def get_alerts(district: str = "Dhaka", mode: str = "general"):
    coords = DIVISION_COORDS.get(district, DIVISION_COORDS['Dhaka'])
    weather = fetch_real_weather(coords['lat'], coords['lng'], district)
    if not weather: return {"alerts": []}
    
    signals = get_signals(weather, coords['lat'], coords['lng'])
    insights = generate_insights(signals, mode, district)
    
    alerts = []
    for ins in insights:
        if ins['severity'] in ['high', 'emergency']:
            alerts.append({
                "type": ins['type'].capitalize(),
                "severity": ins['severity'],
                "confidence": ins['confidence'],
                "title": ins['summary'],
                "bn_title": ins['bn_summary'],
                "details": f"{ins['who_is_affected']}: {ins['why_this_alert']['trigger']}",
                "bn_details": f"{ins['bn_who_is_affected']}: {ins['why_this_alert']['bn_trigger']}",
                "actions": ins['actions'],
                "bn_actions": ins['bn_actions'],
                "source": "BMD Intelligence",
                "valid_until": (datetime.datetime.now() + datetime.timedelta(hours=6)).isoformat()
            })
    return {"alerts": alerts}

@app.get("/api/v1/news-insights")
def get_news_insights(district: str = "Dhaka"):
    # NEWS DATABASE (Simulating relational schema)
    raw_news = [
        {"headline": "Trusted Flood Briefing", "source": "BMD", "category": "flood", "district": "Sylhet", "url": "https://www.bmd.gov.bd"},
        {"headline": "Untrusted Rumor", "source": "Facebook Group", "category": "general", "district": "Dhaka", "url": "#"},
        {"headline": "Heavy Rain Warning", "source": "Prothom Alo", "category": "monsoon", "district": "Chittagong", "url": "https://www.prothomalo.com"}
    ]
    
    # --- ENGINE B: NEWS CLASSIFICATION ---
    trusted_news = [n for n in raw_news if n['source'] in TRUSTED_SOURCES]
    
    items = []
    for news in trusted_news:
        items.append({
            "news": {
                "headline": news['headline'],
                "bn_headline": "সংবাদ: " + news['headline'], 
                "source": news['source'],
                "published_at": datetime.datetime.now().isoformat(),
                "url": news['url'],
                "district": news['district'],
                "category": news['category'],
                "type": "news"
            },
            "insight": {
                "why_it_matters": f"Affects the safety protocols in {news['district']}.",
                "bn_why_it_matters": "এটি আপনার এলাকার নিরাপত্তার জন্য গুরুত্বপূর্ণ।",
                "who_is_affected": "Residents and travelers.",
                "bn_who_is_affected": "বনিসন্দা এবং ভ্রমণকারীরা।",
                "what_to_do": ["Stay alert", "Follow the source link"],
                "bn_what_to_do": ["সতর্ক থাকুন", "লিঙ্কটি দেখুন"],
                "confidence": "High"
            },
            "severity": "high" if news['category'] == "flood" else "normal"
        })
    return {"items": items}

@app.get("/api/v1/forecast")
def get_forecast(district: str = "Dhaka"):
    coords = DIVISION_COORDS.get(district, DIVISION_COORDS['Dhaka'])
    weather = fetch_real_weather(coords['lat'], coords['lng'], district)
    
    if not weather: return {"error": "Data unavailable"}

    # --- ENGINE E: TREND & COMPARISON ---
    # Mocking yesterday's max for comparison
    yesterday_max = weather['daily']['temperature_2m_max'][0] - random.uniform(-2, 2)
    today_max = weather['daily']['temperature_2m_max'][0]
    diff = today_max - yesterday_max
    
    comparison_text = f"Today is {abs(diff):.1f}°C {'warmer' if diff > 0 else 'cooler'} than yesterday."
    bn_comparison_text = f"আজ গতকালের চেয়ে {abs(diff):.1f}°সে. {'উষ্ণ' if diff > 0 else 'শীতল'}।"

    hourly_data = []
    for i in range(0, 12):
        hourly_data.append({
            "time": weather['hourly']['time'][i][-5:],
            "temp": f"{weather['hourly']['temperature_2m'][i]}°C",
            "cond": map_weather_code(weather['hourly']['weathercode'][i]),
        })

    return {
        "hourly": hourly_data,
        "comparison": {
            "comparisonText": comparison_text,
            "bn_comparisonText": bn_comparison_text,
            "trend": "up" if diff > 1 else ("down" if diff < -1 else "stable")
        },
        "weekly_brief": {
            "text": "Stability expected throughout the week.",
            "bn_text": "পুরো সপ্তাহে স্থায়িত্ব আশা করা হচ্ছে।"
        }
    }

@app.get("/api/v1/smart-guidance")
def get_smart_guidance_endpoint(district: str = "Dhaka", mode: str = "general"):
    """
    Phase 1 Smart Guidance API
    Returns decisions, not raw weather
    """
    from phase1_rules import WeatherInput, HourlyForecast, get_smart_guidance, get_forecast_confidence
    
    coords = DIVISION_COORDS.get(district, DIVISION_COORDS['Dhaka'])
    weather = fetch_real_weather(coords['lat'], coords['lng'], district)
    
    if not weather:
        return {"error": "Weather data unavailable"}
    
    # Calculate heat index
    temp = weather['temperature']
    humidity = weather['humidity']
    heat_index = temp + (humidity / 10)
    
    # Calculate forecast stability (variance in next 6 hours)
    hourly_temps = weather['hourly']['temperature_2m'][:6]
    temp_variance = max(hourly_temps) - min(hourly_temps) if len(hourly_temps) > 0 else 0
    forecast_stability = min(temp_variance / 10, 1.0)  # Normalize to 0-1
    
    # Build WeatherInput
    current_weather = WeatherInput(
        temperature=temp,
        humidity=humidity,
        rain_probability=min(weather.get('precipitation', 0) / 10, 1.0),
        wind_speed=weather['windspeed'],
        heat_index=heat_index,
        lightning_risk=0.8 if "Storm" in weather['condition'] else 0.1,
        forecast_stability=forecast_stability
    )
    
    # Build hourly forecast
    hourly_data = []
    for i in range(min(24, len(weather['hourly']['time']))):
        h_temp = weather['hourly']['temperature_2m'][i]
        h_humidity = weather['hourly']['relative_humidity_2m'][i]
        h_heat_index = h_temp + (h_humidity / 10)
        h_precip = weather['hourly']['precipitation'][i]
        
        hourly_data.append(HourlyForecast(
            time=weather['hourly']['time'][i][-5:],
            temperature=h_temp,
            humidity=h_humidity,
            rain_probability=min(h_precip / 10, 1.0),
            heat_index=h_heat_index
        ))
    
    # Get smart guidance decision
    decision = get_smart_guidance(mode, current_weather, hourly_data)
    
    return {
        "location": {"district": district},
        "mode": mode,
        "decision": decision,
        "current_weather": {
            "temperature": temp,
            "condition": weather['condition'],
            "heat_index": heat_index,
            "humidity": humidity
        }
    }
