import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/theme_helpers.dart';
import '../../state/daily_entry_controller.dart';

class SleepTabSection extends StatelessWidget {
  final DateFormat dateFormat;
  final DateTime selectedDate;
  final DateTime yesterday;
  final DailyEntryController controller;
  final TextEditingController sleepNotesController;
  final bool sleepDetailsExpanded;
  final ValueChanged<bool> onSleepDetailsExpandedChanged;
  final VoidCallback onSavePressed;

  const SleepTabSection({
    super.key,
    required this.dateFormat,
    required this.selectedDate,
    required this.yesterday,
    required this.controller,
    required this.sleepNotesController,
    required this.sleepDetailsExpanded,
    required this.onSleepDetailsExpandedChanged,
    required this.onSavePressed,
  });

  String _sleepQualityLabel(BuildContext context, int? quality) {
    final l10n = context.l10n;
    if (quality == null) return l10n.commonNotRecorded;
    switch (quality) {
      case 1:
        return l10n.dayTabMoodVeryBad;
      case 2:
        return l10n.dayTabMoodBad;
      case 3:
        return l10n.dayTabMoodOk;
      case 4:
        return l10n.dayTabMoodGood;
      case 5:
        return l10n.dayTabMoodVeryGood;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final c = controller;

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
                  const Icon(Icons.bedtime, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepTabNightOf(dateFormat.format(selectedDate)),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          l10n.sleepTabNightRange(yesterday.day, selectedDate.day),
                          style: TextStyle(
                            color: muted(context, 0.60),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.sleepTabHowDidYouSleep,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isOn = star <= (c.sleepQuality ?? 0);
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          isOn ? Icons.star : Icons.star_border,
                          color: isOn ? cs.primary : muted(context, 0.25),
                        ),
                        onPressed: () => c.setSleepQuality(star),
                      );
                    }),
                  ),
                  Text(
                    _sleepQualityLabel(context, c.sleepQuality),
                    style: TextStyle(color: muted(context, 0.60), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              initiallyExpanded: sleepDetailsExpanded,
              onExpansionChanged: onSleepDetailsExpandedChanged,
              leading: const Icon(Icons.more_horiz),
              title: Text(l10n.commonDetailsOptional),
              subtitle: Text(
                () {
                  final parts = <String>[];
                  final h = c.sleepDurationHours;
                  final m = c.sleepDurationMinutes;
                  if (h != null || m != null) {
                    final hh = h ?? 0;
                    final mm = m ?? 0;
                    if (!(hh == 0 && mm == 0)) {
                      final mm2 = mm.toString().padLeft(2, '0');
                      parts.add('${hh}h ${mm2}m');
                    }
                  }
                  if (c.sleepContinuity == 1) {
                    parts.add(l10n.sleepTabContinuityStraight);
                  }
                  if (c.sleepContinuity == 2) {
                    parts.add(l10n.sleepTabContinuityBroken);
                  }
                  return parts.isEmpty ? l10n.commonIncomplete : parts.join(' • ');
                }(),
                style: TextStyle(color: muted(context, 0.70), fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sleepTabHowLongDidYouSleep,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey(c.sleepDurationHours),
                              initialValue: c.sleepDurationHours,
                              decoration: InputDecoration(
                                labelText: l10n.sleepTabHours,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('—'),
                                ),
                                for (final h in List<int>.generate(15, (i) => i))
                                  DropdownMenuItem<int?>(
                                    value: h,
                                    child: Text('$h'),
                                  ),
                              ],
                              onChanged: (v) => c.setSleepDuration(
                                hours: v,
                                minutes: c.sleepDurationMinutes,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: ValueKey(c.sleepDurationMinutes),
                              initialValue: c.sleepDurationMinutes,
                              decoration: InputDecoration(
                                labelText: l10n.sleepTabMinutes,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('—'),
                                ),
                                for (final m in const [0, 10, 20, 30, 40, 50])
                                  DropdownMenuItem<int?>(
                                    value: m,
                                    child: Text(m.toString().padLeft(2, '0')),
                                  ),
                              ],
                              onChanged: (v) => c.setSleepDuration(
                                hours: c.sleepDurationHours,
                                minutes: v,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.sleepTabHowWasSleep,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.sleepTabContinuityStraight),
                            selected: c.sleepContinuity == 1,
                            onSelected: (v) => c.setSleepContinuity(v ? 1 : null),
                          ),
                          ChoiceChip(
                            label: Text(l10n.sleepTabContinuityBroken),
                            selected: c.sleepContinuity == 2,
                            onSelected: (v) => c.setSleepContinuity(v ? 2 : null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.sleepTabOptionalHint,
                        style: TextStyle(color: muted(context, 0.60), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.sleepTabGeneralNotesOptional,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: sleepNotesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: c.setSleepNotes,
            decoration: InputDecoration(
              hintText: l10n.sleepTabNotesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSavePressed,
              icon: const Icon(Icons.save),
              label: Text(l10n.commonSave),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}

