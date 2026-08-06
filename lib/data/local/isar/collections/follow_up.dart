import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';

part 'follow_up.g.dart';

@collection
class FollowUp {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String memoryUuid;
  String? note;
  @Index()
  DateTime? expectedDate;
  @enumerated
  @Index()
  late FollowUpStatus status;
  DateTime? resolvedAt;

  // Denormalized snapshot fields, populated from the parent Memory at creation.
  late String personUuid;
  @enumerated
  late MemoryCategory categorySnapshot;
  late int importanceScoreSnapshot;

  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
}
