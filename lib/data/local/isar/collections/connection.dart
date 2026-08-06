import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';

part 'connection.g.dart';

// P1 — schema stub only, not implemented in MVP. Included now so adding it
// later isn't a breaking migration.
@collection
class Connection {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  late String connectionType;
  double? confidenceScore;
  List<String> memoryUuids = []; // simple string list — no join table needed
  List<String> personUuids = [];
  late DateTime createdAt;
  @enumerated
  late SyncStatus syncStatus;
}
