import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';

part 'suggestion_log_entry.g.dart';

@collection
class SuggestionLogEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String followUpUuid;
  late DateTime surfacedAt;
  String? reasonShown; // the "why this surfaced" explanation
  String? actionTaken; // 'acted' | 'dismissed' | 'not_now' | null
  String? userFeedback;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
}
