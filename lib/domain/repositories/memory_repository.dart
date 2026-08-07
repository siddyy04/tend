import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';

/// Memory persistence contract — Isar is touched only through this layer.
abstract class MemoryRepository {
  /// Active (non-tombstoned) memories for [personUuid] as a flat unsorted list.
  Stream<List<Memory>> watchAllForPerson(String personUuid);

  /// Returns null if missing or soft-deleted.
  Future<Memory?> getByUuid(String uuid);

  Future<void> create(Memory memory);

  Future<void> update(Memory memory);

  /// Soft-delete only: sets [Memory.deletedAt], [Memory.updatedAt], and
  /// [Memory.syncStatus] — never hard-deletes the Isar row.
  Future<void> softDelete(String uuid);
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
}
