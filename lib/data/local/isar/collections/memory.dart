import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';

part 'memory.g.dart';

@collection
class Memory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String personUuid; // FK by uuid, NOT an IsarLink
  @enumerated
  @Index()
  late MemoryCategory category;
  late String eventText;
  String? quoteEvidence; // grounding quote from source (hallucination guard)
  @enumerated
  late DatePrecision datePrecision;
  String? dateValueRaw; // verbatim phrase if relative, e.g. "next month"
  @Index()
  DateTime? dateValue; // resolved date if explicit or derivable
  late int importanceScore; // 1-5
  double? extractionConfidence; // null if manually entered
  double? personMatchConfidence;
  @enumerated
  late SensitivityLevel sensitivityFlag;
  @enumerated
  late SourceType sourceType;
  String? sourceRef; // LOCAL file path (audio/photo) — never a cloud URL
  late bool needsUserConfirmation;
  List<double>? embedding; // local semantic search vector (Gecko: 768-d)
  /// e.g. `gecko-110m-en-seq256-v1`; null = never embedded / needs backfill.
  @Index()
  String? embeddingModelVersion;
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt;
}
