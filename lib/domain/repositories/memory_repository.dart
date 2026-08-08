import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';

/// Memory persistence contract — Isar is touched only through this layer.
abstract class MemoryRepository {
  /// Active (non-tombstoned) memories for [personUuid] as a flat unsorted list.
  Stream<List<Memory>> watchAllForPerson(String personUuid);

  /// All active (non-tombstoned) memories across the Circle — unsorted.
  ///
  /// Used by Search; ranking stays outside the repository (ADR-003).
  Future<List<Memory>> getActiveMemories();

  /// Active memories for one person — unsorted. Soft-delete filtered.
  Future<List<Memory>> getActiveMemoriesForPerson(String personUuid);

  /// Returns null if missing or soft-deleted.
  Future<Memory?> getByUuid(String uuid);

  Future<void> create(Memory memory);

  Future<void> update(Memory memory);

  /// Soft-delete only: sets [Memory.deletedAt], [Memory.updatedAt], and
  /// [Memory.syncStatus] — never hard-deletes the Isar row.
  Future<void> softDelete(String uuid);

  /// Active memories whose embedding is missing or not [currentVersion].
  Future<List<Memory>> getMemoriesNeedingEmbedding(
    String currentVersion, {
    int? limit,
  });

  /// Persist embedding fields only (load-merge-put).
  Future<void> updateEmbedding({
    required String uuid,
    required List<double> embedding,
    required String embeddingModelVersion,
  });
}

/// Isar-backed [MemoryRepository].
class IsarMemoryRepository implements MemoryRepository {
  IsarMemoryRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<Memory>> watchAllForPerson(String personUuid) {
    return _isar.memorys
        .filter()
        .personUuidEqualTo(personUuid)
        .and()
        .deletedAtIsNull()
        .watch(fireImmediately: true);
  }

  @override
  Future<List<Memory>> getActiveMemories() {
    return _isar.memorys.filter().deletedAtIsNull().findAll();
  }

  @override
  Future<List<Memory>> getActiveMemoriesForPerson(String personUuid) {
    return _isar.memorys
        .filter()
        .personUuidEqualTo(personUuid)
        .and()
        .deletedAtIsNull()
        .findAll();
  }

  @override
  Future<Memory?> getByUuid(String uuid) {
    return _isar.memorys
        .filter()
        .uuidEqualTo(uuid)
        .and()
        .deletedAtIsNull()
        .findFirst();
  }

  @override
  Future<void> create(Memory memory) async {
    await _isar.writeTxn(() async {
      await _isar.memorys.put(memory);
    });
  }

  @override
  Future<void> update(Memory memory) async {
    await _isar.writeTxn(() async {
      await _isar.memorys.put(memory);
    });
  }

  @override
  Future<void> softDelete(String uuid) async {
    await _isar.writeTxn(() async {
      final memory = await _isar.memorys.getByUuid(uuid);
      if (memory == null) {
        throw StateError('Cannot soft-delete unknown memory uuid: $uuid');
      }
      final now = DateTime.now();
      memory.deletedAt = now;
      memory.updatedAt = now;
      memory.syncStatus = SyncStatus.pending;
      await _isar.memorys.put(memory);
    });
  }

  @override
  Future<List<Memory>> getMemoriesNeedingEmbedding(
    String currentVersion, {
    int? limit,
  }) async {
    final all = await _isar.memorys.filter().deletedAtIsNull().findAll();
    final needing = <Memory>[];
    for (final m in all) {
      final version = m.embeddingModelVersion;
      final embedding = m.embedding;
      final stale = version == null ||
          version != currentVersion ||
          embedding == null ||
          embedding.isEmpty;
      if (stale) {
        needing.add(m);
        if (limit != null && needing.length >= limit) break;
      }
    }
    return needing;
  }

  @override
  Future<void> updateEmbedding({
    required String uuid,
    required List<double> embedding,
    required String embeddingModelVersion,
  }) async {
    await _isar.writeTxn(() async {
      final memory = await _isar.memorys
          .filter()
          .uuidEqualTo(uuid)
          .and()
          .deletedAtIsNull()
          .findFirst();
      if (memory == null) return;
      memory.embedding = embedding;
      memory.embeddingModelVersion = embeddingModelVersion;
      memory.updatedAt = DateTime.now();
      memory.syncStatus = SyncStatus.pending;
      await _isar.memorys.put(memory);
    });
  }
}
