import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/theme_helpers.dart';
import '../../state/daily_entry_controller.dart';

class DayTabSection extends StatelessWidget {
  final DateFormat dateFormat;
  final DateTime selectedDate;
  final DailyEntryController controller;
  final GlobalKey moodSectionKey;
  final GlobalKey habitsSectionKey;
  final TextEditingController dayNotesController;
  final TextEditingController blocksWalkedController;
  final bool dayDetailsExpanded;
  final ValueChanged<bool> onDayDetailsExpandedChanged;
  final VoidCallback onSavePressed;

  const DayTabSection({
    super.key,
    required this.dateFormat,
    required this.selectedDate,
    required this.controller,
    required this.moodSectionKey,
    required this.habitsSectionKey,
    required this.dayNotesController,
    required this.blocksWalkedController,
    required this.dayDetailsExpanded,
    required this.onDayDetailsExpandedChanged,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l10n = context.l10n;
    final labelMuted = muted(context, 0.60);

    final moodItems = <({int v, IconData icon, String label})>[
      (
        v: 1,
        icon: Icons.sentiment_very_dissatisfied,
        label: l10n.dayTabMoodVeryBad,
      ),
      (v: 2, icon: Icons.sentiment_dissatisfied, label: l10n.dayTabMoodBad),
      (v: 3, icon: Icons.sentiment_neutral, label: l10n.dayTabMoodOk),
      (v: 4, icon: Icons.sentiment_satisfied, label: l10n.dayTabMoodGood),
      (
        v: 5,
        icon: Icons.sentiment_very_satisfied,
        label: l10n.dayTabMoodVeryGood,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.today, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dayTabHeader(dateFormat.format(selectedDate)),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          l10n.dayTabOptionalHint,
                          style: TextStyle(color: muted(context, 0.60)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mood
          Container(key: moodSectionKey),
          Text(
            l10n.dayTabMoodTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dayTabMoodQuestion,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final it in moodItems)
                        _MoodButton(
                          icon: it.icon,
                          mood: it.v,
                          selected: c.dayMood == it.v,
                          onTap: () =>
                              c.setDayMood((c.dayMood == it.v) ? null : it.v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.dayMood == null
                        ? l10n.commonNotRecorded
                        : moodItems.firstWhere((e) => e.v == c.dayMood).label,
                    style: TextStyle(color: labelMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              initiallyExpanded: dayDetailsExpanded,
              onExpansionChanged: onDayDetailsExpandedChanged,
              leading: const Icon(Icons.more_horiz),
              title: Text(l10n.commonDetailsOptional),
              subtitle: Text(
                dayNotesController.text.trim().isNotEmpty
                    ? l10n.commonNoteSaved
                    : l10n.commonIncomplete,
                style: TextStyle(color: muted(context, 0.70), fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dayTabDayNotesTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dayNotesController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: c.setDayNotes,
                        decoration: InputDecoration(
                          hintText: l10n.dayTabDayNotesHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Container(key: habitsSectionKey),
          Text(
            l10n.dayTabHabitsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.dayTabWaterTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.water_drop, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.dayTabWaterCount(c.waterCount),
                      style: TextStyle(color: labelMuted, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonDecrease,
                    onPressed: () => c.setWaterCount(c.waterCount - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${c.waterCount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonIncrease,
                    onPressed: () => c.setWaterCount(c.waterCount + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.dayTabBlocksWalkedTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (blocksWalkedController.text.trim().isNotEmpty)
                        IconButton(
                          tooltip: l10n.commonClear,
                          onPressed: () {
                            blocksWalkedController.clear();
                            c.setBlocksWalkedText('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: blocksWalkedController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: l10n.dayTabBlocksWalkedHint,
                      helperText: l10n.dayTabBlocksWalkedHelper,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: c.setBlocksWalkedText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSavePressed,
              icon: const Icon(Icons.save),
              label: Text(l10n.commonSave),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final IconData icon;
  final int mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.icon,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = moodBg(context, mood, selected: selected);
    final border = moodBorder(context, mood, selected: selected);
    final iconColor = moodIconColor(context, mood, selected: selected);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: selected ? 2.2 : 1.4),
        ),
        child: Icon(icon, size: 32, color: iconColor),
      ),
    );
  }
}
