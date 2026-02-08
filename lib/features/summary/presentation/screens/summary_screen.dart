import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/theme_helpers.dart';
import '../../../../ui/app_theme_tokens.dart';
import '../../data/summary_repository.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const _ranges = <int>[7, 30, 90];

  int _rangeDays = 7;
  late Future<_SummaryData> _future;
  bool _didInitFuture = false;
  final SummaryRepository _repo = SummaryRepository();
  late final _LifecycleObserver _lifecycleObserver;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LifecycleObserver(_reload);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFuture) return;
    _didInitFuture = true;
    _future = _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _focusNode.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<_SummaryData> _load() async {
    final l10n = context.l10n;
    final today = _dateOnly(DateTime.now());

    final start = today.subtract(Duration(days: _rangeDays - 1));
    final end = today;

    final days = List<DateTime>.generate(
      _rangeDays,
      (i) => start.add(Duration(days: i)),
      growable: false,
    );

    final data = await _repo.loadBetween(start, end);
    final sleepQualities = data.sleepQualities;
    final moods = data.moods;
    final intakeCounts = data.intakeCounts;
    final habits = data.habits;
    final blocksWalkedByDay = data.blocksWalkedByDay;

    final sleepValues = days
        .map((d) => sleepQualities[_dateOnly(d)])
        .toList(growable: false);

    final moodValues = days
        .map((d) => moods[_dateOnly(d)])
        .toList(growable: false);

    final habitsValues = days
        .map((d) => habits[_dateOnly(d)])
        .toList(growable: false);

    final blocksWalkedValues = days
        .map((d) => blocksWalkedByDay[_dateOnly(d)])
        .toList(growable: false);

    final avgSleep = () {
      final present = sleepValues.whereType<int>().toList(growable: false);
      if (present.isEmpty) return null;
      final sum = present.fold<int>(0, (a, b) => a + b);
      return sum / present.length;
    }();

    final sleepTrend = _sleepTrendText(
      l10n: l10n,
      days: days,
      sleepValues: sleepValues,
    );

    final moodBuckets = _buildMoodBuckets(days, moods);
    final mostFrequentMood = _mostFrequentMood(moodBuckets);

    final daysWithMeds = days
        .where((d) => (intakeCounts[_dateOnly(d)] ?? 0) > 0)
        .length;

    final habitsStats = _buildHabitsStats(habitsValues, blocksWalkedValues);

    final patterns = _buildPatternsNonCorrelative(
      l10n: l10n,
      rangeDays: _rangeDays,
      sleepValues: sleepValues,
      moodValues: moodValues,
      habitsValues: habitsValues,
      includeSensitive: false,
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
      habitsStats: habitsStats,
      patterns: patterns,
    );
  }

  String? _sleepTrendText({
    required AppLocalizations l10n,
    required List<DateTime> days,
    required List<int?> sleepValues,
  }) {
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
      return l10n.summarySleepTrendHigherAtEnd;
    }
    if (delta <= -threshold) {
      return l10n.summarySleepTrendHigherAtStart;
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

  _HabitsStats _buildHabitsStats(
    List<({int? waterCount, int? blocksWalked})?>
    habitsValues,
    List<int?> blocksWalkedValues,
  ) {
    int waterDays = 0;
    int waterSum = 0;

    for (final h in habitsValues) {
      if (h == null) continue;
      final water = h.waterCount;

      if (water != null) {
        waterDays++;
        waterSum += water.clamp(0, 10);
      }
    }

    final blocks = blocksWalkedValues
        .whereType<int>()
        .map((v) => v.clamp(0, 1000))
        .toList();

    double? avg(int sum, int n) => n <= 0 ? null : (sum / n);
    double? avgBlocks(List<int> xs) =>
        xs.isEmpty ? null : xs.fold<int>(0, (a, b) => a + b) / xs.length;

    return _HabitsStats(
      daysWithWater: waterDays,
      avgWater: avg(waterSum, waterDays),
      daysWithBlocksWalked: blocks.length,
      avgBlocksWalked: avgBlocks(blocks),
    );
  }

  List<_PatternSection> _buildPatternsNonCorrelative({
    required AppLocalizations l10n,
    required int rangeDays,
    required List<int?> sleepValues,
    required List<int?> moodValues,
    required List<({int? waterCount, int? blocksWalked})?>
    habitsValues,
    required bool includeSensitive,
  }) {
    List<bool> series(bool Function(int i) predicate) {
      return List<bool>.generate(rangeDays, predicate, growable: false);
    }

    int currentStreak(List<bool> xs) {
      var n = 0;
      for (var i = xs.length - 1; i >= 0; i--) {
        if (!xs[i]) break;
        n++;
      }
      return n;
    }

    int bestStreak(List<bool> xs) {
      var best = 0;
      var run = 0;
      for (final v in xs) {
        if (v) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
      }
      return best;
    }

    _Streak streakFor(String label, List<bool> xs) =>
        _Streak(label: label, current: currentStreak(xs), best: bestStreak(xs));

    _Goal goalFor(String label, List<bool> xs) => _Goal(
      label: label,
      achieved: xs.where((v) => v).length,
      total: rangeDays,
    );


    final waterGoal = series((i) {
      final w = habitsValues[i]?.waterCount;
      return w != null && w >= 6;
    });
    final sleepGoal = series((i) {
      final s = sleepValues[i];
      return s != null && s >= 4;
    });
    final moodGoal = series((i) {
      final m = moodValues[i];
      return m != null && m >= 4;
    });

    final streaks = <_Streak>[
      streakFor(l10n.summaryPatternWaterGoal, waterGoal),
      streakFor(l10n.summaryPatternSleepGoal, sleepGoal),
    ];

    final goals = <_Goal>[
      goalFor(l10n.summaryPatternWaterGoal, waterGoal),
      goalFor(l10n.summaryPatternSleepGoal, sleepGoal),
      goalFor(l10n.summaryPatternMoodGoal, moodGoal),
    ];

    final insights = (rangeDays <= 7)
        ? const <_InsightItem>[]
        : _buildInsightItems(
            l10n: l10n,
            rangeDays: rangeDays,
            sleepValues: sleepValues,
            moodValues: moodValues,
            habitsValues: habitsValues,
            includeSensitive: includeSensitive,
          );

    return [
      _PatternSection.streaks(streaks),
      _PatternSection.goals(goals),
      if (rangeDays > 7) _PatternSection.insights(insights),
    ];
  }

  List<_InsightItem> _buildInsightItems({
    required AppLocalizations l10n,
    required int rangeDays,
    required List<int?> sleepValues,
    required List<int?> moodValues,
    required List<({int? waterCount, int? blocksWalked})?>
    habitsValues,
    required bool includeSensitive,
  }) {
    List<double?> asDouble(List<int?> xs) =>
        xs.map((v) => v?.toDouble()).toList(growable: false);

    final sleep = asDouble(sleepValues); // 1..5
    final mood = asDouble(moodValues); // 1..5
    final water = habitsValues
        .map((h) => h?.waterCount?.toDouble())
        .toList(growable: false); // 0..10 (si fue registrado)

    _InsightItem insight({
      required String title,
      required String xLabel,
      required String yLabel,
      required double yMax,
      required List<double?> x,
      required List<double?> y,
    }) {
      return _buildTopBottomInsight(
        l10n: l10n,
        rangeDays: rangeDays,
        title: title,
        xLabel: xLabel,
        yLabel: yLabel,
        yMax: yMax,
        x: x,
        y: y,
      );
    }

    return <_InsightItem>[
      insight(
        title: l10n.summaryInsightTitleSleepMood,
        xLabel: l10n.summaryMetricSleep,
        yLabel: l10n.summaryMetricMood,
        yMax: 5,
        x: sleep,
        y: mood,
      ),
      insight(
        title: l10n.summaryInsightTitleWaterMood,
        xLabel: l10n.summaryMetricWater,
        yLabel: l10n.summaryMetricMood,
        yMax: 5,
        x: water,
        y: mood,
      ),
    ];
  }

  _InsightItem _buildTopBottomInsight({
    required AppLocalizations l10n,
    required int rangeDays,
    required String title,
    required String xLabel,
    required String yLabel,
    required double yMax,
    required List<double?> x,
    required List<double?> y,
  }) {
    final pairs = <({double x, double y})>[];
    final n = (x.length < y.length) ? x.length : y.length;
    for (var i = 0; i < n; i++) {
      final xv = x[i];
      final yv = y[i];
      if (xv == null || yv == null) continue;
      pairs.add((x: xv, y: yv));
    }

    // Base mínima para que tenga sentido mostrar algo.
    final minPairs = rangeDays <= 7 ? 4 : 8;
    if (pairs.length < minPairs) {
      return _InsightItem(
        title: title,
        strength: _InsightStrength.preliminary,
        baseText: l10n.summaryInsightBaseMinPairs(pairs.length, minPairs),
        message: l10n.summaryInsightMessageMinPairs,
      );
    }

    final sorted = [...pairs]..sort((a, b) => a.x.compareTo(b.x));

    int groupSize() {
      if (rangeDays <= 7) return 2;
      final pct = (sorted.length * 0.30).floor();
      return pct.clamp(3, (sorted.length / 2).floor());
    }

    final g = groupSize();
    if (g <= 0) {
      return _InsightItem(
        title: title,
        strength: _InsightStrength.preliminary,
        baseText: l10n.summaryInsightBaseNoGroup(pairs.length),
        message: l10n.summaryInsightMessageNoGroup,
      );
    }

    final low = sorted.take(g).map((p) => p.y).toList(growable: false);
    final high = sorted
        .skip(sorted.length - g)
        .map((p) => p.y)
        .toList(growable: false);

    double avg(List<double> xs) =>
        xs.isEmpty ? 0 : xs.fold<double>(0, (a, b) => a + b) / xs.length;

    final lowAvg = avg(low);
    final highAvg = avg(high);
    final delta = highAvg - lowAvg;

    final normalized = yMax <= 0 ? 0.0 : (delta.abs() / yMax);

    _InsightStrength strength() {
      if (g < 3 || pairs.length < 10) return _InsightStrength.preliminary;
      if (normalized >= 0.18) return _InsightStrength.strong;
      if (normalized >= 0.10) return _InsightStrength.moderate;
      return _InsightStrength.weak;
    }

    String dirWord() =>
        delta >= 0 ? l10n.summaryInsightDirHigher : l10n.summaryInsightDirLower;

    String groupHint() {
      if (rangeDays <= 7) return l10n.summaryInsightGroupHintShort(xLabel);
      return l10n.summaryInsightGroupHintLong(xLabel);
    }

    return _InsightItem(
      title: title,
      strength: strength(),
      baseText: l10n.summaryInsightBaseTopBottom(pairs.length, groupHint(), g),
      message: l10n.summaryInsightMessageTopBottom(
        xLabel,
        yLabel,
        dirWord(),
        delta.toStringAsFixed(1),
      ),
    );
  }

  IconData _moodIcon(int mood) => moodIcon(mood);
  Color _moodColor(BuildContext context, int mood) => moodColor(context, mood);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: muted(context, 0.55));

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) _reload();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.summaryTitle),
          backgroundColor: context.surfaces.accentSurface,
          actions: [
            IconButton(
              tooltip: l10n.commonRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
          ],
        ),
        body: FutureBuilder<_SummaryData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text(l10n.summaryLoadError));
            }

            final data = snapshot.data!;

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        PopupMenuButton<int>(
                          tooltip: l10n.commonRange,
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
                                  child: Text(l10n.summaryLastNDays(d)),
                                ),
                              )
                              .toList(growable: false),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.summaryLastNDays(data.rangeDays),
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
                  ),
                  TabBar(
                    tabs: [
                      Tab(text: l10n.summaryTabStats),
                      Tab(text: l10n.summaryTabPatterns),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          children: [
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
                            const SizedBox(height: 12),
                            _HabitsCard(
                              rangeDays: data.rangeDays,
                              stats: data.habitsStats,
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(l10n.summaryViewDayByDay),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          children: [
                            ...data.patterns.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PatternsSectionCard(section: s),
                              ),
                            ),
                            if (data.rangeDays <= 7)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    l10n.summaryPatternsRangeHint,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: muted(context, 0.70)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
  final _HabitsStats habitsStats;
  final List<_PatternSection> patterns;

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
    required this.habitsStats,
    required this.patterns,
  });
}

class _LifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;
  const _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class _HabitsStats {
  final int daysWithWater;
  final double? avgWater;
  final int daysWithBlocksWalked;
  final double? avgBlocksWalked;

  const _HabitsStats({
    required this.daysWithWater,
    required this.avgWater,
    required this.daysWithBlocksWalked,
    required this.avgBlocksWalked,
  });
}

enum _PatternSectionType { streaks, goals, insights }

class _PatternSection {
  final _PatternSectionType type;
  final List<_Streak> streaks;
  final List<_Goal> goals;
  final List<_InsightItem> insights;

  const _PatternSection._({
    required this.type,
    this.streaks = const [],
    this.goals = const [],
    this.insights = const [],
  });

  const _PatternSection.streaks(List<_Streak> items)
    : this._(type: _PatternSectionType.streaks, streaks: items);

  const _PatternSection.goals(List<_Goal> items)
    : this._(type: _PatternSectionType.goals, goals: items);

  const _PatternSection.insights(List<_InsightItem> items)
    : this._(type: _PatternSectionType.insights, insights: items);
}

class _Streak {
  final String label;
  final int current;
  final int best;
  const _Streak({
    required this.label,
    required this.current,
    required this.best,
  });
}

class _Goal {
  final String label;
  final int achieved;
  final int total;
  const _Goal({
    required this.label,
    required this.achieved,
    required this.total,
  });
}

enum _InsightStrength { notEnoughData, weak, preliminary, moderate, strong }

class _InsightItem {
  final String title;
  final _InsightStrength strength;
  final String baseText;
  final String message;

  const _InsightItem({
    required this.title,
    required this.strength,
    required this.baseText,
    required this.message,
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
    final l10n = context.l10n;
    final hasSleepData = avgSleep != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🛏️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l10n.commonSleep,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasSleepData) ...[
              Text(
                l10n.commonAverage,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _Stars(value: avgSleep),
              const SizedBox(height: 4),
              Text(
                l10n.summarySleepAverageQuality,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted(context, 0.55)),
              ),
            ] else ...[
              Text(
                l10n.summarySleepNoRecords,
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
    final l10n = context.l10n;
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
            Row(
              children: [
                const Text('😊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l10n.commonMood,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
              Text(l10n.summaryMoodNoRecords, style: captionStyle)
            else
              Row(
                children: [
                  Text(
                    '${l10n.summaryMoodMostFrequentPrefix} ',
                    style: captionStyle,
                  ),
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
    final l10n = context.l10n;
    final daysWithout = (rangeDays - daysWithMedication).clamp(0, rangeDays);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l10n.commonMedication,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                    l10n.summaryMedicationDaysWith(
                      daysWithMedication,
                      rangeDays,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('—  '),
                Expanded(
                  child: Text(l10n.summaryDaysWithoutRecord(daysWithout)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternsSectionCard extends StatelessWidget {
  final _PatternSection section;

  const _PatternsSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String title() {
      switch (section.type) {
        case _PatternSectionType.streaks:
          return l10n.summaryPatternsStreaks;
        case _PatternSectionType.goals:
          return l10n.summaryPatternsGoals;
        case _PatternSectionType.insights:
          return l10n.summaryPatternsInsights;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  section.type == _PatternSectionType.streaks
                      ? '🔥'
                      : (section.type == _PatternSectionType.goals
                            ? '🎯'
                            : '🧠'),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (section.type == _PatternSectionType.streaks)
              ...section.streaks.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.label)),
                      Text(l10n.summaryStreakCurrent(s.current)),
                      const SizedBox(width: 10),
                      Text(l10n.summaryStreakBest(s.best)),
                    ],
                  ),
                ),
              ),
            if (section.type == _PatternSectionType.goals)
              ...section.goals.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(g.label)),
                      Text(l10n.summaryGoalDaysProgress(g.achieved, g.total)),
                    ],
                  ),
                ),
              ),
            if (section.type == _PatternSectionType.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l10n.summaryInsightsDisclaimer,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted(context, 0.70)),
                ),
              ),
            if (section.type == _PatternSectionType.insights)
              ...section.insights.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InsightTile(item: i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final _InsightItem item;
  const _InsightTile({required this.item});

  String _strengthLabel(BuildContext context, _InsightStrength s) {
    final l10n = context.l10n;
    switch (s) {
      case _InsightStrength.notEnoughData:
        return l10n.summaryInsightStrengthNotEnoughData;
      case _InsightStrength.weak:
        return l10n.summaryInsightStrengthWeak;
      case _InsightStrength.preliminary:
        return l10n.summaryInsightStrengthPreliminary;
      case _InsightStrength.moderate:
        return l10n.summaryInsightStrengthModerate;
      case _InsightStrength.strong:
        return l10n.summaryInsightStrengthStrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedText = Theme.of(context).textTheme.bodySmall?.color;

    Color pillBg() {
      switch (item.strength) {
        case _InsightStrength.strong:
          return cs.primaryContainer;
        case _InsightStrength.moderate:
          return cs.secondaryContainer;
        case _InsightStrength.preliminary:
          return cs.surfaceContainerHighest;
        case _InsightStrength.weak:
          return cs.surfaceContainerHighest;
        case _InsightStrength.notEnoughData:
          return cs.surfaceContainerHighest;
      }
    }

    Color pillFg() {
      switch (item.strength) {
        case _InsightStrength.strong:
          return cs.onPrimaryContainer;
        case _InsightStrength.moderate:
          return cs.onSecondaryContainer;
        default:
          return cs.onSurface;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pillBg(),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: muted(context, 0.12)),
              ),
              child: Text(
                _strengthLabel(context, item.strength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: pillFg(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(item.message),
        const SizedBox(height: 4),
        Text(
          item.baseText,
          style: TextStyle(
            fontSize: 12,
            color: mutedText ?? muted(context, 0.70),
          ),
        ),
      ],
    );
  }
}

class _HabitsCard extends StatelessWidget {
  final int rangeDays;
  final _HabitsStats stats;

  const _HabitsCard({required this.rangeDays, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final captionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: muted(context, 0.70));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  l10n.commonHabits,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.summaryDaysWithRecordLabel(rangeDays),
              style: captionStyle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.summaryWaterDays(stats.daysWithWater)),
                ),
                Text(l10n.summaryAvgShortWithValue(_fmtAvg(stats.avgWater))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.summaryBlocksWalkedDays(stats.daysWithBlocksWalked),
                  ),
                ),
                Text(
                  l10n.summaryAvgShortWithValue(
                    _fmtAvg(stats.avgBlocksWalked, digits: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtAvg(double? v, {int digits = 1}) =>
      v == null ? '—' : v.toStringAsFixed(digits);
}
