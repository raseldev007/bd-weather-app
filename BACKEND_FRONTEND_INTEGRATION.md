# Phase 1 Backend-Frontend Integration Guide

**Status:** Ready for Integration  
**Date:** 2025-12-24

---

## 🔗 INTEGRATION OVERVIEW

### Current State
- ✅ Python backend rules implemented (`phase1_rules.py`)
- ✅ Flutter UI component tree verified
- ⚠️ **Need to connect:** API endpoints to rule logic

### Integration Points

```
Python Backend          Flutter Frontend
===============         ================
phase1_rules.py    →    WeatherInsightService
     ↓                       ↓
  FastAPI              HTTP Request
     ↓                       ↓
  JSON Response        Parse & Render
```

---

## 📡 API ENDPOINT UPDATES NEEDED

### Add to `backend/main.py`

```python
from phase1_rules import (
    WeatherInput,
    HourlyForecast,
    get_smart_guidance,
    get_forecast_confidence
)

@app.get("/api/v1/smart-guidance")
def get_smart_guidance_endpoint(
    district: str = "Dhaka",
    mode: str = "general"
):
    """
    Phase 1 Smart Guidance API
    Returns decisions, not raw weather
    """
    # Fetch weather data
    coords = DIVISION_COORDS.get(district, DIVISION_COORDS['Dhaka'])
    weather = fetch_real_weather(coords['lat'], coords['lng'], district)
    
    if not weather:
        return {"error": "Weather data unavailable"}
    
    # Calculate heat index
    temp = weather['temperature']
    humidity = weather['humidity']
    heat_index = temp + (humidity / 10)  # Simple proxy
    
    # Build WeatherInput
    current_weather = WeatherInput(
        temperature=temp,
        humidity=humidity,
        rain_probability=weather.get('precipitation', 0) / 100,  # Convert to 0-1
        wind_speed=weather['windspeed'],
        heat_index=heat_index,
        lightning_risk=0.8 if "Storm" in weather['condition'] else 0.1,
        forecast_stability=0.25  # Mock for now, calculate from hourly variance
    )
    
    # Build hourly forecast
    hourly_data = []
    for i in range(min(24, len(weather['hourly']['time']))):
        h_temp = weather['hourly']['temperature_2m'][i]
        h_humidity = weather['hourly']['relative_humidity_2m'][i]
        h_heat_index = h_temp + (h_humidity / 10)
        
        hourly_data.append(HourlyForecast(
            time=weather['hourly']['time'][i][-5:],  # "12:00"
            temperature=h_temp,
            humidity=h_humidity,
            rain_probability=weather['hourly']['precipitation'][i] / 100,
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
            "heat_index": heat_index
        }
    }
```

---

## 📱 FLUTTER SERVICE UPDATE

### Update `lib/services/weather_service.dart`

```dart
class WeatherService extends ChangeNotifier {
  // Add new method
  Future<Map<String, dynamic>> getSmartGuidance(
    String location,
    UserMode mode
  ) async {
    final modeStr = mode.toString().split('.').last; // "worker", "farmer", etc.
    
    final url = Uri.parse(
      'http://localhost:8000/api/v1/smart-guidance?district=$location&mode=$modeStr'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load smart guidance');
      }
    } catch (e) {
      print('Error fetching smart guidance: $e');
      return {};
    }
  }
}
```

---

## 🔄 USAGE IN FLUTTER

### Update `weather_screen.dart`

```dart
class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _smartGuidance;
  
  @override
  void initState() {
    super.initState();
    _loadSmartGuidance();
  }
  
  Future<void> _loadSmartGuidance() async {
    final weatherService = Provider.of<WeatherService>(context, listen: false);
    final profile = Provider.of<ProfileService>(context, listen: false);
    
    final guidance = await weatherService.getSmartGuidance(
      profile.location.split(',')[0],  // "Dhaka"
      profile.mode
    );
    
    setState(() {
      _smartGuidance = guidance;
    });
  }
  
  Widget _buildWorkSafetyBanner(...) {
    // Use backend decision instead of local calculation
    if (_smartGuidance != null && _smartGuidance!['decision'] != null) {
      final decision = _smartGuidance!['decision'];
      
      return Container(
        child: Column(
          children: [
            // Status from backend
            Text(
              decision['status'],  // "SAFE" | "CAUTION" | "UNSAFE"
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(decision['status'])
              )
            ),
            
            // Advice from backend
            Text(decision['advice']),
            
            // Confidence from backend
            Chip(
              label: Text(decision['confidence'])
            ),
            
            // Unsafe hours from backend
            if (decision['unsafe_hours'] != null)
              Text("Unsafe: ${decision['unsafe_hours'].join(', ')}")
          ]
        )
      );
    }
    
    // Fallback to local calculation if backend unavailable
    return _buildLocalWorkSafety(...);
  }
}
```

---

## 🧪 TESTING STEPS

### 1. Start Python Backend
```bash
cd backend
python -m uvicorn main:app --reload
```

### 2. Test API Endpoint
```bash
curl "http://localhost:8000/api/v1/smart-guidance?district=Dhaka&mode=worker"
```

**Expected Response:**
```json
{
  "location": {"district": "Dhaka"},
  "mode": "worker",
  "decision": {
    "status": "CAUTION",
    "unsafe_hours": ["12:00", "13:00", "14:00"],
    "advice": "Take extra breaks every 30 minutes. Drink water regularly.",
    "confidence": "HIGH",
    "notify_when_safe": false,
    "triggers": {
      "heat_index": 38.5,
      "lightning_risk": 0.1
    },
    "why_this_advice": {
      "triggers": {...},
      "explanation": "Advice generated based on safety thresholds",
      "details": ["Heat index is 38.5°C (unsafe threshold: 35°C)"]
    }
  }
}
```

### 3. Run Flutter App
```bash
cd weather_app
flutter run
```

### 4. Verify Integration
- [ ] Switch to Worker mode
- [ ] Check if status shows backend decision
- [ ] Verify advice text matches backend
- [ ] Confirm confidence level displays
- [ ] Test mode switching (Farmer, Student, General)

---

## 🚨 FALLBACK STRATEGY

### If Backend Unavailable

```dart
Future<Map<String, dynamic>> getSmartGuidance(...) async {
  try {
    // Try backend first
    final response = await http.get(url).timeout(Duration(seconds: 5));
    return json.decode(response.body);
  } catch (e) {
    // Fallback to local calculation
    print('Backend unavailable, using local intelligence');
    return _getLocalSmartGuidance(mode, weather);
  }
}

Map<String, dynamic> _getLocalSmartGuidance(UserMode mode, Map weather) {
  // Use existing WeatherInsightService as fallback
  if (mode == UserMode.worker) {
    return WeatherInsightService.getWorkSafetyStatus(...);
  }
  // ... other modes
}
```

---

## 📊 MONITORING

### Add Logging

```python
# In backend/main.py
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.get("/api/v1/smart-guidance")
def get_smart_guidance_endpoint(...):
    logger.info(f"Smart Guidance request: district={district}, mode={mode}")
    
    decision = get_smart_guidance(mode, current_weather, hourly_data)
    
    logger.info(f"Decision: {decision['status']} (confidence: {decision['confidence']})")
    
    return {...}
```

```dart
// In Flutter
print('Smart Guidance loaded: ${guidance['decision']['status']}');
```

---

## ✅ INTEGRATION CHECKLIST

- [ ] Add `/api/v1/smart-guidance` endpoint to `main.py`
- [ ] Import `phase1_rules.py` functions
- [ ] Update `WeatherService` with new method
- [ ] Modify `weather_screen.dart` to use backend decisions
- [ ] Test all 4 modes (Worker, Farmer, Student, General)
- [ ] Verify fallback works when backend offline
- [ ] Add error handling and logging
- [ ] Test mode switching triggers new API call
- [ ] Verify confidence levels display correctly
- [ ] Confirm "Why This Advice" shows backend triggers

---

## 🎯 SUCCESS CRITERIA

Integration is successful when:

1. ✅ Flutter app calls Python backend for decisions
2. ✅ Backend returns status, advice, and confidence
3. ✅ UI displays backend decisions (not local calculations)
4. ✅ Mode switching triggers new backend call
5. ✅ Fallback to local works if backend down
6. ✅ No UI lag when switching modes
7. ✅ Notifications trigger on backend state changes

---

**Next Step:** Implement the API endpoint in `main.py` and test the integration!
