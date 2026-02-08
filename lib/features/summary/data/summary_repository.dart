import '../../../services/database_helper.dart';
import '../../daily_entry/data/day_repository.dart';
import '../../daily_entry/data/habits_repository.dart';
import '../../medication/data/intake_repository.dart';

class SummaryRepository {
  final DayRepository dayRepo;
  final HabitsRepository habitsRepo;
  final IntakeRepository intakeRepo;

  SummaryRepository({DatabaseHelper? db})
    : dayRepo = DayRepository(db: db),
      habitsRepo = HabitsRepository(db: db),
      intakeRepo = IntakeRepository(db: db);

  Future<
    ({
      Map<DateTime, int> sleepQualities,
      Map<DateTime, int> moods,
      Map<DateTime, int> intakeCounts,
      Map<DateTime, ({int? waterCount, int? blocksWalked})>
      habits,
      Map<DateTime, int> blocksWalkedByDay,
    })
  >
  loadBetween(DateTime start, DateTime end) async {
    final sleepQualities = await dayRepo.getSleepQualitiesBetween(start, end);
    final moods = await dayRepo.getDayMoodsBetween(start, end);
    final intakeCounts = await intakeRepo.getIntakeCountsBetween(start, end);
    final habits = await habitsRepo.getHabitsBetween(start, end);
    final blocksWalkedByDay = <DateTime, int>{};
    for (final e in habits.entries) {
      final blocks = e.value.blocksWalked;
      if (blocks == null) continue;
      if (blocks <= 0) continue;
      blocksWalkedByDay[e.key] = blocks;
    }

    return (
      sleepQualities: sleepQualities,
      moods: moods,
      intakeCounts: intakeCounts,
      habits: habits,
      blocksWalkedByDay: blocksWalkedByDay,
    );
  }
}
