"""
Phase 1 Backend Rule Logic
Python implementation of decision-making intelligence
Returns decisions, not raw weather data
"""

from dataclasses import dataclass
from typing import List, Dict, Any
from datetime import datetime


@dataclass
class WeatherInput:
    """Shared data model for all rule engines"""
    temperature: float
    humidity: float
    rain_probability: float
    wind_speed: float
    heat_index: float
    lightning_risk: float
    forecast_stability: float


@dataclass
class HourlyForecast:
    """Hourly forecast data point"""
    time: str
    temperature: float
    humidity: float
    rain_probability: float
    heat_index: float


# ============================================================================
# FORECAST CONFIDENCE ENGINE
# ============================================================================

def get_forecast_confidence(forecast_stability: float) -> str:
    """
    Determines forecast confidence based on stability metric
    
    Args:
        forecast_stability: 0.0-1.0 (lower = more stable)
    
    Returns:
        "HIGH" | "MEDIUM" | "LOW"
    """
    if forecast_stability < 0.3:
        return "HIGH"
    elif forecast_stability < 0.6:
        return "MEDIUM"
    else:
        return "LOW"


# ============================================================================
# WORKER MODE — WORK SAFETY DETECTOR
# ============================================================================

def work_safety_status(data: WeatherInput) -> str:
    """
    Determines work safety status based on heat and lightning
    
    Returns:
        "UNSAFE" | "CAUTION" | "SAFE"
    """
    if data.heat_index >= 41 or data.lightning_risk > 0.6:
        return "UNSAFE"
    elif data.heat_index >= 35:
        return "CAUTION"
    else:
        return "SAFE"


def unsafe_work_hours(hourly_forecast: List[HourlyForecast]) -> List[str]:
    """
    Identifies unsafe work hours based on heat index
    
    Returns:
        List of time strings (e.g., ["12:00", "13:00", "14:00"])
    """
    unsafe_hours = []
    for hour in hourly_forecast:
        if hour.heat_index >= 41:
            unsafe_hours.append(hour.time)
    return unsafe_hours


def get_worker_decision(data: WeatherInput, hourly: List[HourlyForecast]) -> Dict[str, Any]:
    """
    Complete worker mode decision package
    
    Returns:
        {
            "status": "SAFE" | "CAUTION" | "UNSAFE",
            "unsafe_hours": ["12:00", "13:00"],
            "advice": "Clear action text",
            "confidence": "HIGH" | "MEDIUM" | "LOW",
            "notify_when_safe": bool
        }
    """
    status = work_safety_status(data)
    unsafe_hrs = unsafe_work_hours(hourly)
    confidence = get_forecast_confidence(data.forecast_stability)
    
    advice_map = {
        "UNSAFE": "Stop work immediately. Rest in shade. Hydrate frequently.",
        "CAUTION": "Take extra breaks every 30 minutes. Drink water regularly.",
        "SAFE": "Conditions are safe for outdoor work. Stay hydrated."
    }
    
    return {
        "status": status,
        "unsafe_hours": unsafe_hrs,
        "advice": advice_map[status],
        "confidence": confidence,
        "notify_when_safe": status == "UNSAFE",
        "triggers": {
            "heat_index": data.heat_index,
            "lightning_risk": data.lightning_risk
        }
    }


# ============================================================================
# FARMER MODE — CROP RISK & SPRAYING SUITABILITY
# ============================================================================

def spraying_suitability(data: WeatherInput) -> str:
    """
    Determines if conditions are suitable for spraying
    
    Returns:
        "SUITABLE" | "NOT SUITABLE"
    """
    if data.rain_probability < 0.3 and data.wind_speed < 10:
        return "SUITABLE"
    return "NOT SUITABLE"


def crop_risk(data: WeatherInput) -> str:
    """
    Assesses crop risk based on rain probability
    
    Returns:
        "HIGH" | "MEDIUM" | "LOW"
    """
    if data.rain_probability > 0.6:
        return "HIGH"
    elif data.rain_probability > 0.3:
        return "MEDIUM"
    return "LOW"


def get_farmer_decision(data: WeatherInput) -> Dict[str, Any]:
    """
    Complete farmer mode decision package
    
    Returns:
        {
            "risk_level": "HIGH" | "MEDIUM" | "LOW",
            "spraying_suitable": "SUITABLE" | "NOT SUITABLE",
            "safe_window": "6 AM - 10 AM" | "No safe window today",
            "advice": "Clear action text",
            "confidence": "HIGH" | "MEDIUM" | "LOW"
        }
    """
    risk = crop_risk(data)
    spraying = spraying_suitability(data)
    confidence = get_forecast_confidence(data.forecast_stability)
    
    # Determine safe window
    if spraying == "SUITABLE" and risk == "LOW":
        safe_window = "6 AM - 10 AM"
        advice = "Apply fertilizer or pesticide now. Window closes at 10 AM."
    elif risk == "MEDIUM":
        safe_window = "Early morning only (before 8 AM)"
        advice = "Work quickly. Rain risk increases after 8 AM."
    else:
        safe_window = "No safe window today"
        advice = "Avoid spraying. High rain risk will wash away chemicals."
    
    return {
        "risk_level": risk,
        "spraying_suitable": spraying,
        "safe_window": safe_window,
        "advice": advice,
        "confidence": confidence,
        "triggers": {
            "rain_probability": data.rain_probability,
            "wind_speed": data.wind_speed
        }
    }


# ============================================================================
# GENERAL MODE — KEY TIP & 6-HOUR RISK
# ============================================================================

def todays_key_tip(data: WeatherInput) -> str:
    """
    Generates the single most important tip for today
    
    Returns:
        Clear, actionable advice string
    """
    if data.rain_probability > 0.6:
        return "Avoid travel in the evening due to rain"
    if data.heat_index > 38:
        return "Limit outdoor activity at midday"
    return "Weather conditions are generally comfortable"


def next_6_hour_risk(hourly_forecast: List[HourlyForecast]) -> str:
    """
    Assesses risk level for next 6 hours
    
    Returns:
        "RISKY" | "SAFE"
    """
    for hour in hourly_forecast[:6]:
        if hour.rain_probability > 0.6:
            return "RISKY"
    return "SAFE"


def get_general_decision(data: WeatherInput, hourly: List[HourlyForecast]) -> Dict[str, Any]:
    """
    Complete general mode decision package
    
    Returns:
        {
            "key_tip": "Today's most important advice",
            "next_6h_risk": "RISKY" | "SAFE",
            "advice": "Clear action text",
            "confidence": "HIGH" | "MEDIUM" | "LOW"
        }
    """
    tip = todays_key_tip(data)
    risk_6h = next_6_hour_risk(hourly)
    confidence = get_forecast_confidence(data.forecast_stability)
    
    if risk_6h == "RISKY":
        advice = "Plan indoor activities. Carry umbrella if going out."
    else:
        advice = "Good conditions for outdoor plans. Stay hydrated."
    
    return {
        "key_tip": tip,
        "next_6h_risk": risk_6h,
        "advice": advice,
        "confidence": confidence,
        "triggers": {
            "rain_probability": data.rain_probability,
            "heat_index": data.heat_index
        }
    }


# ============================================================================
# WHY-THIS-ADVICE GENERATOR
# ============================================================================

def why_this_advice(triggers: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generates explanation for advice
    
    Args:
        triggers: Dictionary of condition values that triggered the advice
    
    Returns:
        {
            "triggers": {...},
            "explanation": "Human-readable explanation"
        }
    """
    explanations = []
    
    if "heat_index" in triggers and triggers["heat_index"] >= 35:
        explanations.append(f"Heat index is {triggers['heat_index']}°C (unsafe threshold: 35°C)")
    
    if "rain_probability" in triggers and triggers["rain_probability"] > 0.3:
        explanations.append(f"Rain probability is {triggers['rain_probability']*100:.0f}%")
    
    if "wind_speed" in triggers and triggers["wind_speed"] > 10:
        explanations.append(f"Wind speed is {triggers['wind_speed']} km/h (spraying limit: 10 km/h)")
    
    if "lightning_risk" in triggers and triggers["lightning_risk"] > 0.6:
        explanations.append(f"Lightning risk is {triggers['lightning_risk']*100:.0f}%")
    
    return {
        "triggers": triggers,
        "explanation": "Advice generated based on safety thresholds",
        "details": explanations
    }


# ============================================================================
# MASTER DECISION ENGINE
# ============================================================================

def get_smart_guidance(
    mode: str,
    current_weather: WeatherInput,
    hourly_forecast: List[HourlyForecast]
) -> Dict[str, Any]:
    """
    Master function that routes to appropriate mode logic
    
    Args:
        mode: "worker" | "farmer" | "student" | "general"
        current_weather: Current weather conditions
        hourly_forecast: Next 24 hours forecast
    
    Returns:
        Complete decision package for the specified mode
    """
    if mode == "worker":
        decision = get_worker_decision(current_weather, hourly_forecast)
    elif mode == "farmer":
        decision = get_farmer_decision(current_weather)
    elif mode == "student":
        # Student mode uses general logic + specific additions
        decision = get_general_decision(current_weather, hourly_forecast)
        decision["study_comfort"] = "GOOD" if current_weather.heat_index < 35 else "POOR"
    else:  # general
        decision = get_general_decision(current_weather, hourly_forecast)
    
    # Add why-this-advice to all decisions
    decision["why_this_advice"] = why_this_advice(decision.get("triggers", {}))
    
    return decision


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if __name__ == "__main__":
    # Example: Worker mode on a hot day
    current = WeatherInput(
        temperature=38.0,
        humidity=75.0,
        rain_probability=0.2,
        wind_speed=5.0,
        heat_index=42.5,  # Dangerous!
        lightning_risk=0.1,
        forecast_stability=0.25  # HIGH confidence
    )
    
    hourly = [
        HourlyForecast("12:00", 38, 75, 0.2, 42.5),
        HourlyForecast("13:00", 39, 76, 0.2, 43.8),
        HourlyForecast("14:00", 39, 74, 0.3, 43.2),
        HourlyForecast("15:00", 37, 72, 0.3, 40.6),
        HourlyForecast("16:00", 35, 70, 0.4, 38.5),
        HourlyForecast("17:00", 33, 68, 0.4, 36.4),
    ]
    
    result = get_smart_guidance("worker", current, hourly)
    
    print("=== WORKER MODE DECISION ===")
    print(f"Status: {result['status']}")
    print(f"Advice: {result['advice']}")
    print(f"Unsafe Hours: {result['unsafe_hours']}")
    print(f"Confidence: {result['confidence']}")
    print(f"Notify When Safe: {result['notify_when_safe']}")
    print(f"\nWhy This Advice:")
    print(f"  {result['why_this_advice']['explanation']}")
    for detail in result['why_this_advice']['details']:
        print(f"  - {detail}")
