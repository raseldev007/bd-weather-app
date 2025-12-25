import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/weather_provider.dart';
import '../models/guidance_models.dart';
import '../smart_guidance_provider.dart';
import '../models/routine_models.dart';

enum SimMetric { study, commute, outdoor }

class RiskSimulator extends StatefulWidget {
  const RiskSimulator({super.key});

  @override
  State<RiskSimulator> createState() => _RiskSimulatorState();
}

class _RiskSimulatorState extends State<RiskSimulator> {
  int _idx = 0;
  SimMetric _metric = SimMetric.commute;

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final smart = context.watch<SmartGuidanceProvider>();

    if (!smart.isEnabled) {
      return _CardWrap(
        child: Row(
          children: [
             const Expanded(child: Text("Enable Smart Guidance to explore risks.")),
             FilledButton(
                onPressed: () => smart.toggleSmartGuidance(true),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: Colors.teal),
                child: const Text("Enable"),
             )
          ],
        ),
      );
    }

    final hourly = _getHourly(weather);
    if (hourly.isEmpty) {
      return const _CardWrap(child: Text("Hourly forecast not available yet."));
    }

    final horizon = hourly.take(12).toList(); // next 12 points (hourly or 3-hour points)
    _idx = _idx.clamp(0, horizon.length - 1);

    final point = _readPoint(horizon[_idx]);

    final sStudy = _scoreStudy(point);
    final sCommute = _scoreCommute(point);
    final sOutdoor = _scoreOutdoor(point);

    final nowLabel = _timeLabel(point.dt);

    // best alternative (choose the metric)
    final bestAlt = _bestWindow(horizon, _metric, smart);

    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Risk Simulator",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(nowLabel, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 10),

          _metricSelector(OutcomeProfileId.general),

          const SizedBox(height: 10),
          Text("Slide time → see risk & comfort instantly",
              style: Theme.of(context).textTheme.bodySmall),

          Slider(
            value: _idx.toDouble(),
            min: 0,
            max: (horizon.length - 1).toDouble(),
            divisions: horizon.length - 1,
            label: nowLabel,
            onChanged: (v) => setState(() => _idx = v.round()),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _scoreTile(context, "Study", sStudy),
              _scoreTile(context, "Commute", sCommute),
              _scoreTile(context, "Outdoor", sOutdoor),
            ],
          ),

          const SizedBox(height: 12),
          if (bestAlt != null) ...[
            Text("Best alternative",
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(bestAlt, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  // ---------- UI helpers ----------
  Widget _metricSelector(OutcomeProfileId profile) {
    final items = [SimMetric.commute, SimMetric.outdoor, SimMetric.study];
    
    String label(SimMetric m) {
      switch (m) {
        case SimMetric.study: return "Study";
        case SimMetric.commute: return "Commute";
        case SimMetric.outdoor: return "Outdoor";
        default: return "Other";
      }
    }

    return Wrap(
      spacing: 8,
      children: items.map((m) {
        final selected = m == _metric;
        return ChoiceChip(
          label: Text(label(m)),
          selected: selected,
          onSelected: (_) => setState(() => _metric = m),
        );
      }).toList(),
    );
  }

  Widget _scoreTile(BuildContext context, String title, int score) {
    final c = score >= 75 ? Colors.green : (score >= 55 ? Colors.orange : Colors.red);
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.35)),
        color: c.withOpacity(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text("$score/100",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c)),
        ],
      ),
    );
  }

  // ---------- Hourly extraction ----------
  List<dynamic> _getHourly(WeatherProvider w) {
    // your provider already has hourlyForecast getter; use it
    final h = w.hourlyForecast;
    if (h != null && h.isNotEmpty) return h;
    // fallback
    if (w.forecast != null && w.forecast!['hourly'] is List) return w.forecast!['hourly'];
    if (w.forecast != null && w.forecast!['list'] is List) return w.forecast!['list'];
    return const [];
  }

  _Point _readPoint(dynamic raw) {
    // handles OneCall-like map OR 5-day/3-hour raw map
    final m = (raw is Map) ? raw : <String, dynamic>{};

    // dt is unix seconds
    final dtSec = (m['dt'] as num?)?.toInt() ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(dtSec * 1000, isUtc: true).toLocal();

    // OneCall format: temp, feels_like, humidity, wind_speed, pop
    final temp = _asDouble(m['temp']) ?? _asDouble(m['main']?['temp']) ?? 0.0;
    final feels = _asDouble(m['feels_like']) ?? _asDouble(m['main']?['feels_like']) ?? temp;
    final hum = (m['humidity'] as num?)?.toInt()
        ?? (m['main']?['humidity'] as num?)?.toInt()
        ?? 0;
    final wind = _asDouble(m['wind_speed'])
        ?? _asDouble(m['wind']?['speed'])
        ?? 0.0;
    final pop = _asDouble(m['pop']) ?? 0.0;
    final vis = (m['visibility'] as num?)?.toInt();

    String cond = "Unknown";
    if (m['weather'] is List && (m['weather'] as List).isNotEmpty) {
      final w0 = (m['weather'][0] as Map);
      cond = (w0['main'] ?? "Unknown").toString();
    }

    return _Point(
      dt: dt,
      temp: temp,
      feelsLike: feels,
      humidity: hum,
      wind: wind,
      pop: pop,
      visibility: vis,
      condition: cond,
    );
  }

  double? _asDouble(dynamic x) => (x is num) ? x.toDouble() : null;

  // ---------- Scoring (simple, consistent) ----------
  int _clamp100(double v) => v.clamp(0, 100).round();

  int _tempComfort(double feels) {
    // Bangladesh-friendly neutral comfort: 20–28 ideal
    const min = 20.0, max = 28.0;
    final center = (min + max) / 2.0;
    final half = (max - min) / 2.0;
    final dist = (feels - center).abs();
    return _clamp100(100 - (dist / (half + 6.0)) * 100);
  }

  int _humidityComfort(int hum) {
    const idealMax = 75;
    if (hum <= idealMax) return 100;
    return _clamp100(100 - (hum - idealMax) * 2.2);
  }

  int _rainPenalty(double pop) {
    if (pop >= 0.60) return 55;
    if (pop >= 0.30) return 25;
    return 0;
  }

  int _windPenalty(double wind) {
    if (wind >= 9.0) return 35;
    if (wind >= 5.0) return 15;
    return 0;
  }

  int _scoreStudy(_Point p) {
    final t = _tempComfort(p.feelsLike);
    final h = _humidityComfort(p.humidity);
    final rain = _rainPenalty(p.pop);
    final wind = _windPenalty(p.wind);
    return _clamp100(0.55 * t + 0.35 * h - 0.6 * rain - 0.4 * wind);
  }

  int _scoreCommute(_Point p) {
    final rain = _rainPenalty(p.pop);
    final wind = _windPenalty(p.wind);
    final base = 100 - (1.1 * rain + 0.9 * wind);
    return _clamp100(base);
  }

  int _scoreOutdoor(_Point p) {
    final t = _tempComfort(p.feelsLike);
    final rain = _rainPenalty(p.pop);
    final wind = _windPenalty(p.wind);
    return _clamp100(0.7 * t - 0.8 * rain - 0.5 * wind + 20);
  }



  String? _bestWindow(List<dynamic> horizon, SimMetric metric, SmartGuidanceProvider smart) {
    if (horizon.length < 2) return null;

    int scoreAt(dynamic raw) {
      final p = _readPoint(raw);
      switch (metric) {
        case SimMetric.study: return _scoreStudy(p);
        case SimMetric.commute: return _scoreCommute(p);
        case SimMetric.outdoor: return _scoreOutdoor(p);
      }
    }

    int bestIdx = 0;
    double bestAvg = -1;

    for (int i = 0; i < horizon.length - 1; i++) {
      final a = scoreAt(horizon[i]);
      final b = scoreAt(horizon[i + 1]);
      final avg = (a + b) / 2.0;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestIdx = i;
      }
    }

    final p0 = _readPoint(horizon[bestIdx]);
    final p1 = _readPoint(horizon[bestIdx + 1]);

    final start = _timeLabel(p0.dt);
    final end = _timeLabel(p1.dt);
    return "Best ${metric.name.toUpperCase()} window: $start – $end (avg ${(bestAvg).round()}/100)";
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}

class _Point {
  final DateTime dt;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double wind;
  final double pop;
  final int? visibility;
  final String condition;

  _Point({
    required this.dt,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.pop,
    required this.visibility,
    required this.condition,
  });
}

class _CardWrap extends StatelessWidget {
  final Widget child;
  const _CardWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}
