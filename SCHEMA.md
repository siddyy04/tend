# Tend — Database Schema (Isar primary, Supabase backup mirror)

**Supersedes:** `02-database-schema.md`. Aligned to `ARCHITECTURE.md` (ADR-0001).
**How to use this with Cursor:** paste this whole file into the repo as `SCHEMA.md`. Tell Cursor: *"Isar is the source of truth. Generate Dart collections exactly matching SCHEMA.md — do not invent additional fields. The Supabase schema is a backup mirror only, never queried directly by the app for normal reads/writes."*

**Single source of truth for collections:** This file owns all Isar collection field definitions. `ARCHITECTURE.md` must reference this document — it must not restate field lists (avoids schema drift).

---

## Primary schema: Isar collections

```dart
// lib/core/constants/enums.dart
enum CircleTier { innerCircle, family, friends, professional, mentors, acquaintances }
enum MemoryCategory { family, career, health, education, travel, finance, goals, hobbies, preferences, promises, milestones }
enum SourceType { voice, text, photo, share }
enum SensitivityLevel { low, medium, high }
enum DatePrecision { explicit, relative, none }
enum FollowUpStatus { open, done, dismissed }
enum SyncStatus { pending, synced, conflict }
```

```dart
// lib/data/local/isar/collections/person.dart
@collection
class Person {
  Id id = Isar.autoIncrement;          // local-only fast key — never leaves the device
  @Index(unique: true)
  late String uuid;                    // stable cross-device identity — client-generated v4, THIS is the real foreign key
  @Index()
  late String name;
  @enumerated
  late CircleTier circleTier;
  String? relationshipType;             // free text for MVP, e.g. "college friend"
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt;                  // tombstone — null means not deleted
}
```

```dart
// lib/data/local/isar/collections/memory.dart
@collection
class Memory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String personUuid;               // FK by uuid, NOT an IsarLink — see "Why uuid FKs, not IsarLinks" below
  @enumerated
  @Index()
  late MemoryCategory category;
  late String eventText;
  String? quoteEvidence;                // grounding quote from source (hallucination guard)
  @enumerated
  late DatePrecision datePrecision;
  String? dateValueRaw;                 // verbatim phrase if relative, e.g. "next month"
  @Index()
  DateTime? dateValue;                  // resolved date if explicit or derivable
  late int importanceScore;             // 1-5
  double? extractionConfidence;         // null if manually entered
  double? personMatchConfidence;
  @enumerated
  late SensitivityLevel sensitivityFlag;
  @enumerated
  late SourceType sourceType;
  String? sourceRef;                    // LOCAL file path (audio/photo) — never a cloud URL
  late bool needsUserConfirmation;
  List<double>? embedding;              // Gecko-110m-en: 768-d float32 when present
  @Index()
  String? embeddingModelVersion;        // e.g. "gecko-110m-en-seq256-v1"; null = needs backfill
  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt;
}
```

```dart
// lib/data/local/isar/collections/follow_up.dart
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

  // --- Denormalized snapshot fields, populated from the parent Memory at creation time ---
  // Why: Isar is a NoSQL object store with no SQL-style joins. Scoring candidates for
  // Today's Opportunities against `follow_ups` alone (instead of joining `memories` on every
  // scan) keeps the daily Suggestion Engine job to a single collection query.
  // Trade-off: if importanceScore or category is edited on the Memory after the FollowUp
  // is created, these snapshots go stale unless explicitly re-synced. Acceptable for MVP
  // volumes and edit frequency — flagged here so it's a deliberate choice, not a bug later.
  late String personUuid;
  @enumerated
  late MemoryCategory categorySnapshot;
  late int importanceScoreSnapshot;

  late DateTime createdAt;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
  DateTime? deletedAt; // tombstone — null means not deleted
}
```

```dart
// lib/data/local/isar/collections/suggestion_log_entry.dart
@collection
class SuggestionLogEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  @Index()
  late String followUpUuid;
  late DateTime surfacedAt;
  String? reasonShown;                  // the "why this surfaced" explanation
  String? actionTaken;                  // 'acted' | 'dismissed' | 'not_now' | null
  String? userFeedback;
  late DateTime updatedAt;
  @enumerated
  late SyncStatus syncStatus;
}
```

```dart
// lib/data/local/isar/collections/connection.dart
// P1 — schema stub only, not implemented in MVP. Included now so adding it later
// isn't a breaking migration.
@collection
class Connection {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String uuid;
  late String connectionType;
  double? confidenceScore;
  List<String> memoryUuids = [];        // simple string list — no join table needed in Isar
  List<String> personUuids = [];
  late DateTime createdAt;
  @enumerated
  late SyncStatus syncStatus;
}
```

### Why uuid FKs, not IsarLinks
Isar has a native relation feature (`IsarLink`/`IsarLinks`), but it's keyed to Isar's own local `Id` — which, per the ADR, is not sync-safe (two devices can generate colliding integers independently). Every relation in this schema is therefore a plain `String` field holding the related record's `uuid`, resolved with an explicit query rather than Isar's built-in link traversal. This costs a little convenience (no automatic link loading) in exchange for the relation actually surviving a sync round-trip.

### Embedding dimension
`Memory.embedding` is produced by the active `EmbeddingProvider` — Phase 3.3 production provider is **Gecko-110m-en** (**768** dimensions). Persist `embeddingModelVersion` (e.g. `gecko-110m-en-seq256-v1`) with every vector. **Never compare embeddings across different versions or dimensions.** Stale / null version → exclude from Tier 2 semantic search until backfill re-embeds. Dimension is not stored per row.

Search is **tiered hybrid** (Phase 3.3): Tier 1 = keyword (unchanged from Phase 3.1); Tier 2 = semantic-only matches above a tunable cosine threshold. See `SPRINT3_3.md` / ADR-013.

---

## Common local queries (Isar query syntax, for reference implementations)

**Today's Opportunities candidates** (single collection scan, thanks to the denormalized snapshot fields above):
```dart
final candidates = await isar.followUps
    .filter()
    .statusEqualTo(FollowUpStatus.open)
    .and()
    .group((q) => q
        .expectedDateIsNull()
        .or()
        .expectedDateLessThan(DateTime.now().add(const Duration(days: 3))))
    .sortByImportanceScoreSnapshotDesc()
    .findAll();
// Final ranking/diversity/cap-at-5 logic still applied in application code (unchanged from Deliverable 6).
```

**Person timeline:**
```dart
final timeline = await isar.memorys
    .filter()
    .personUuidEqualTo(personUuid)
    .and()
    .deletedAtIsNull()
    .sortByDateValueDesc()
    .findAll();
```

**Semantic search** (brute-force cosine scan — see `ARCHITECTURE.md` Section 8 for why this is intentional, not a shortcut):
```dart
final queryEmbedding = await embeddingProvider.embed(queryText);
final all = await isar.memorys.filter().deletedAtIsNull().findAll();
final ranked = all
    .where((m) => m.embedding != null)
    .map((m) => (memory: m, score: cosineSimilarity(queryEmbedding, m.embedding!)))
    .toList()
  ..sort((a, b) => b.score.compareTo(a.score));
final topResults = ranked.take(10);
```

---

## Backup mirror schema: Supabase (Postgres)

This exists **only** for opt-in backup/sync — never queried directly by the app for normal reads or writes. Field names mirror the Isar collections exactly, keyed by `uuid`, not by Postgres-native identity.

```sql
create extension if not exists pgcrypto;

create type circle_tier as enum
  ('inner_circle','family','friends','professional','mentors','acquaintances');
create type memory_category as enum
  ('family','career','health','education','travel','finance','goals','hobbies',
   'preferences','promises','milestones');
create type source_type as enum ('voice','text','photo','share');
create type sensitivity_level as enum ('low','medium','high');
create type date_precision as enum ('explicit','relative','none');
create type followup_status as enum ('open','done','dismissed');

create table people (
  uuid uuid primary key,                -- matches Isar's uuid, NOT a fresh server-generated id
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  circle_tier circle_tier not null,
  relationship_type text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index idx_people_user on people(user_id);

create table memories (
  uuid uuid primary key,
  person_uuid uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  category memory_category not null,
  event_text text not null,
  quote_evidence text,
  date_precision date_precision not null,
  date_value_raw text,
  date_value date,
  importance_score smallint not null check (importance_score between 1 and 5),
  extraction_confidence numeric(3,2),
  person_match_confidence numeric(3,2),
  sensitivity_flag sensitivity_level not null,
  source_type source_type not null,
  -- NOTE: no source_ref column — local file paths (audio/photo) are device-local and
  -- deliberately never uploaded to the backup mirror. See "Remaining gaps" below.
  needs_user_confirmation boolean not null,
  embedding vector(768),                -- placeholder dimension — MUST match the active
                                         -- EmbeddingProvider's actual output size before use
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index idx_memories_user on memories(user_id);
create index idx_memories_person on memories(person_uuid);

create table follow_ups (
  uuid uuid primary key,
  memory_uuid uuid not null,
  person_uuid uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  note text,
  expected_date date,
  status followup_status not null,
  resolved_at timestamptz,
  category_snapshot memory_category not null,
  importance_score_snapshot smallint not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index idx_followups_status on follow_ups(status, expected_date);

create table suggestion_log (
  uuid uuid primary key,
  follow_up_uuid uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  surfaced_at timestamptz not null,
  reason_shown text,
  action_taken text,
  user_feedback text,
  updated_at timestamptz not null
);

-- Row Level Security — mandatory on every table, backup mirror or not
alter table people enable row level security;
alter table memories enable row level security;
alter table follow_ups enable row level security;
alter table suggestion_log enable row level security;

create policy "own people" on people for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own memories" on memories for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own follow_ups" on follow_ups for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own suggestion_log" on suggestion_log for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

**Why `pgvector` still appears here even though it's not used for querying:** the backup mirror stores the embedding purely so a full restore-from-backup doesn't require every memory to be re-embedded from scratch on a new device. It is never queried with `pgvector`'s similarity operators — all search remains local, per `ARCHITECTURE.md` Section 8.
