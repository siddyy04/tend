import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';

part 'person.g.dart';

@collection
class Person {
  Id id = Isar.autoIncrement; // local-only fast key — never leaves the device
  @Index(unique: true)
  late String uuid; // stable cross-device identity — client-generated v4
  @Index()
  late String name;
  @enumerated
  late CircleTier circleTier;
  String? relationshipType; // free text for MVP, e.g. "college friend"
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt; // tombstone — null means not deleted
}
