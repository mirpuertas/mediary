import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../ui/theme_helpers.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const _ranges = <int>[7, 30, 90];

  int _rangeDays = 7;
  late Future<_SummaryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<_SummaryData> _load() async {
    final today = _dateOnly(DateTime.now());

    final start = today.subtract(Duration(days: _rangeDays - 1));
    final end = today;

    final db = DatabaseHelper.instance;

    final days = List<DateTime>.generate(
      _rangeDays,
      (i) => start.add(Duration(days: i)),
      growable: false,
    );

    final sleepQualities = await db.getSleepQualitiesBetween(start, end);
    final moods = await db.getDayMoodsBetween(start, end);
    final intakeCounts = await db.getIntakeCountsBetween(start, end);

    final sleepValues = days
        .map((d) => sleepQualities[_dateOnly(d)])
        .toList(growable: false);

    final avgSleep = () {
      final present = sleepValues.whereType<int>().toList(growable: false);
      if (present.isEmpty) return null;
      final sum = present.fold<int>(0, (a, b) => a + b);
      return sum / present.length;
    }();

    final sleepTrend = _sleepTrendText(days, sleepValues);

    final moodBuckets = _buildMoodBuckets(days, moods);
    final mostFrequentMood = _mostFrequentMood(moodBuckets);

    final daysWithMeds = days
        .where((d) => (intakeCounts[_dateOnly(d)] ?? 0) > 0)
        .length;

    final patterns = _buildPatterns(
      rangeDays: _rangeDays,
      days: days,
      sleepQualities: sleepValues,
      moodsByDay: moods,
      intakeCountsByDay: intakeCounts,
    );

    return _SummaryData(
      rangeDays: _rangeDays,
      start: start,
      end: end,
      days: days,
      sleepQualitiesByDay: sleepValues,
      avgSleep: avgSleep,
      sleepTrendText: sleepTrend,
      moodBuckets: moodBuckets,
      mostFrequentMood: mostFrequentMood,
      daysWithMedication: daysWithMeds,
      patterns: patterns,
    );
  }

  String? _sleepTrendText(List<DateTime> days, List<int?> sleepValues) {
    final pairs = <({DateTime day, int quality})>[];
    for (var i = 0; i < days.length; i++) {
      final q = sleepValues[i];
      if (q == null) continue;
      pairs.add((day: days[i], quality: q));
    }

    if (pairs.length < 5) return null;

    final third = (pairs.length / 3).floor().clamp(1, pairs.length);
    final first = pairs.take(third).map((p) => p.quality).toList();
    final last = pairs
        .skip(pairs.length - third)
        .map((p) => p.quality)
        .toList();

    double avg(List<int> xs) =>
        xs.isEmpty ? 0 : xs.fold<int>(0, (a, b) => a + b) / xs.length;

    final delta = avg(last) - avg(first);

    const threshold = 0.6;
    if (delta >= threshold) {
      return 'La calidad de sueño fue más alta hacia el final del período';
    }
    if (delta <= -threshold) {
      return 'La calidad de sueño fue más alta hacia el inicio del período';
    }
    return null;
  }

  List<_MoodBucket> _buildMoodBuckets(
    List<DateTime> days,
    Map<DateTime, int> moodsByDay,
  ) {
    final counts = List<int>.filled(5, 0);

    for (final day in days) {
      final mood = moodsByDay[_dateOnly(day)];
      if (mood == null) continue;
      final idx = mood - 1;
      if (idx >= 0 && idx < counts.length) counts[idx]++;
    }

    return List.generate(5, (i) {
      final mood = i + 1;
      return _MoodBucket(mood: mood, count: counts[i]);
    }, growable: false);
  }

  int? _mostFrequentMood(List<_MoodBucket> buckets) {
    final nonEmpty = buckets.where((b) => b.count > 0).toList(growable: false);
    if (nonEmpty.isEmpty) return null;

    nonEmpty.sort((a, b) => b.count.compareTo(a.count));
    return nonEmpty.first.mood;
  }

  List<String> _buildPatterns({
    required int rangeDays,
    required List<DateTime> days,
    required List<int?> sleepQualities,
    required Map<DateTime, int> moodsByDay,
    required Map<DateTime, int> intakeCountsByDay,
  }) {
    final patterns = <String>[];

    // Patrón 1: sueño alto suele coincidir con ánimo más alto.
    final pairs = <({int sleep, int mood})>[];
    for (var i = 0; i < days.length; i++) {
      final s = sleepQualities[i];
      final m = moodsByDay[_dateOnly(days[i])];
      if (s == null || m == null) continue;
      pairs.add((sleep: s, mood: m));
    }

    final minPairs = (rangeDays <= 7) ? 5 : 6;
    if (pairs.length >= minPairs) {
      pairs.sort((a, b) => a.sleep.compareTo(b.sleep));
      final half = (pairs.length / 2).floor().clamp(1, pairs.length);

      final low = pairs.take(half).map((p) => p.mood).toList();
      final high = pairs.skip(pairs.length - half).map((p) => p.mood).toList();

      double avg(List<int> xs) =>
          xs.isEmpty ? 0 : xs.fold<int>(0, (a, b) => a + b) / xs.length;

      final deltaMood = avg(high) - avg(low);
      if (deltaMood >= 0.75) {
        patterns.add(
          '🛏️ Días con sueño de mayor calidad suelen coincidir con ánimo más alto',
        );
      }
    }

    // Patrón 2: medicación más frecuente entre semana.
    if (days.length >= 14) {
      int weekdayDays = 0;
      int weekendDays = 0;
      int weekdayMeds = 0;
      int weekendMeds = 0;

      for (final day in days) {
        final isWeekend =
            day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
        final hasMeds = (intakeCountsByDay[_dateOnly(day)] ?? 0) > 0;

        if (isWeekend) {
          weekendDays++;
          if (hasMeds) weekendMeds++;
        } else {
          weekdayDays++;
          if (hasMeds) weekdayMeds++;
        }
      }

      if (weekdayDays > 0 && weekendDays > 0) {
        final weekdayRate = weekdayMeds / weekdayDays;
        final weekendRate = weekendMeds / weekendDays;
        if ((weekdayRate - weekendRate) >= 0.25) {
          patterns.add(
            '💊 Los días con medicación registrada fueron más frecuentes entre semana',
          );
        }
      }
    }

    return patterns;
  }

  IconData _moodIcon(int mood) => moodIcon(mood);
  Color _moodColor(BuildContext context, int mood) => moodColor(context, mood);

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: muted(context, 0.55));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<_SummaryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar el resumen.'));
          }

          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Row(
                children: [
                  PopupMenuButton<int>(
                    tooltip: 'Rango',
                    onSelected: (days) {
                      setState(() {
                        _rangeDays = days;
                        _future = _load();
                      });
                    },
                    itemBuilder: (_) => _ranges
                        .map(
                          (d) => PopupMenuItem<int>(
                            value: d,
                            child: Text('Últimos $d días'),
                          ),
                        )
                        .toList(growable: false),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Últimos ${data.rangeDays} días',
                          style: subtitleStyle,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: subtitleStyle?.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SleepCard(
                avgSleep: data.avgSleep,
                qualitiesByDay: data.sleepQualitiesByDay,
                trendText: data.sleepTrendText,
              ),
              const SizedBox(height: 12),
              _MoodCard(
                buckets: data.moodBuckets,
                mostFrequentMood: data.mostFrequentMood,
                moodIcon: _moodIcon,
                moodColor: (m) => _moodColor(context, m),
              ),
              const SizedBox(height: 12),
              _MedicationCard(
                rangeDays: data.rangeDays,
                daysWithMedication: data.daysWithMedication,
              ),
              if (data.patterns.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PatternsCard(patterns: data.patterns),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ver detalle día por día →'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryData {
  final int rangeDays;
  final DateTime start;
  final DateTime end;
  final List<DateTime> days;

  final List<int?> sleepQualitiesByDay;
  final double? avgSleep;
  final String? sleepTrendText;

  final List<_MoodBucket> moodBuckets;
  final int? mostFrequentMood;

  final int daysWithMedication;
  final List<String> patterns;

  const _SummaryData({
    required this.rangeDays,
    required this.start,
    required this.end,
    required this.days,
    required this.sleepQualitiesByDay,
    required this.avgSleep,
    required this.sleepTrendText,
    required this.moodBuckets,
    required this.mostFrequentMood,
    required this.daysWithMedication,
    required this.patterns,
  });
}

class _SleepCard extends StatelessWidget {
  final double? avgSleep;
  final List<int?> qualitiesByDay;
  final String? trendText;

  const _SleepCard({
    required this.avgSleep,
    required this.qualitiesByDay,
    required this.trendText,
  });

  @override
  Widget build(BuildContext context) {
    final hasSleepData = avgSleep != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🛏️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Sueño', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (hasSleepData) ...[
              const Text(
                'Promedio',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _Stars(value: avgSleep),
              const SizedBox(height: 4),
              Text(
                'Promedio de calidad de sueño',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted(context, 0.55)),
              ),
            ] else ...[
              Text(
                'Sin registros de sueño en este período',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted(context, 0.70)),
              ),
            ],
            const SizedBox(height: 12),
            _MiniBarChart(values: qualitiesByDay),
            if ((trendText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                trendText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted(context, 0.70)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double? value;

  const _Stars({required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value;
    final filled = v == null ? 0 : v.floor().clamp(0, 5);

    final on = Theme.of(context).colorScheme.primary;
    final off = muted(context, 0.20);

    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < filled ? Icons.star : Icons.star_border,
          size: 20,
          color: i < filled ? on : off,
        );
      }),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<int?> values;

  const _MiniBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.75);
    final emptyColor = muted(context, 0.12);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final q = values[i];
                  final t = q == null ? 0.12 : (q.clamp(1, 5) / 5.0);
                  final h = (c.maxHeight * t).clamp(4.0, c.maxHeight);

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: q == null ? emptyColor : barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _MoodBucket {
  final int mood;
  final int count;

  const _MoodBucket({required this.mood, required this.count});
}

class _MoodCard extends StatelessWidget {
  final List<_MoodBucket> buckets;
  final int? mostFrequentMood;
  final IconData Function(int mood) moodIcon;
  final Color Function(int mood) moodColor;

  const _MoodCard({
    required this.buckets,
    required this.mostFrequentMood,
    required this.moodIcon,
    required this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = buckets.any((b) => b.count > 0);
    final captionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: muted(context, 0.70));

    final most = mostFrequentMood == null
        ? null
        : buckets.firstWhere(
            (b) => b.mood == mostFrequentMood,
            orElse: () => const _MoodBucket(mood: 0, count: 0),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('😊', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Ánimo', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: buckets
                  .map(
                    (b) => Expanded(
                      child: Center(
                        child: Icon(
                          moodIcon(b.mood),
                          size: 22,
                          color: moodColor(
                            b.mood,
                          ).withValues(alpha: b.count == 0 ? 0.30 : 0.90),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: buckets
                  .map(
                    (b) => Expanded(
                      child: Center(
                        child: Text(
                          '${b.count}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: muted(
                                  context,
                                  b.count == 0 ? 0.25 : 0.55,
                                ),
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            if (!hasAny)
              Text(
                'Sin registros de ánimo en este período',
                style: captionStyle,
              )
            else
              Row(
                children: [
                  Text('El ánimo más frecuente fue ', style: captionStyle),
                  if (most != null && most.mood != 0)
                    Icon(
                      moodIcon(most.mood),
                      size: 18,
                      color: moodColor(most.mood).withValues(alpha: 0.90),
                    )
                  else
                    Text('—', style: captionStyle),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final int rangeDays;
  final int daysWithMedication;

  const _MedicationCard({
    required this.rangeDays,
    required this.daysWithMedication,
  });

  @override
  Widget build(BuildContext context) {
    final daysWithout = (rangeDays - daysWithMedication).clamp(0, rangeDays);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('💊', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Medicación',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✔️  '),
                Expanded(
                  child: Text(
                    'Días con medicación registrada: $daysWithMedication de $rangeDays',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('—  '),
                Expanded(child: Text('Días sin registro: $daysWithout')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternsCard extends StatelessWidget {
  final List<String> patterns;

  const _PatternsCard({required this.patterns});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🔎', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Patrones', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...patterns.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
