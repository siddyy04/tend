# Architecture Decision Records (ADR)

This document captures important architectural decisions made during the development of Tend.

The goal is to explain **why** a decision was made, not how the code works.

## Format

### ADR-XXX — Title

**Status**
Accepted | Superseded | Deprecated

**Date**
YYYY-MM-DD

**Context**
What problem were we trying to solve?

**Decision**
What did we decide?

**Rationale**
Why was this approach chosen?

**Consequences**
Pros, cons, and future implications.

---

# ADR-001 — Local-first architecture

**Status**
Accepted

**Date**
2026-08-07

**Context**
Tend must work reliably even without an internet connection and should avoid unnecessary cloud dependencies.

**Decision**
Isar is the primary source of truth for all application data.
Supabase is used only for authentication in the early sprints. Cloud synchronization will be added later without changing the local architecture.

**Rationale**
- Instant UI updates
- Full offline support
- Lower operating costs
- Better user privacy
- Simpler AI integration using local data

**Consequences**
- All repositories read/write Isar.
- Sync becomes an implementation detail rather than a core dependency.
- Extra work is required later for conflict resolution.

---

# ADR-002 — UUID-based relationships

**Status**
Accepted

**Date**
2026-08-07

**Context**
Entities reference each other throughout the application.

**Decision**
Relationships use UUID strings instead of IsarLinks or local database IDs.

**Rationale**
UUIDs remain stable across devices and future synchronization.

**Consequences**
- Navigation uses UUIDs only.
- Repositories expose UUIDs only.
- Local Isar IDs never leave the data layer.

---

# ADR-003 — Repository boundaries

**Status**
Accepted

**Date**
2026-08-07

**Context**
Repositories are the only boundary between business logic and Isar.

**Decision**
Repositories return flat entity lists.
Sorting, grouping, filtering, and presentation belong in Riverpod providers.

**Rationale**
Keeps repositories reusable and UI-independent.

**Consequences**
- Repository code stays simple.
- UI can have multiple derived views from the same data.

---

# ADR-004 — Form controller lifecycle

**Status**
Accepted

**Date**
2026-08-07

**Context**
Sprint 1A exposed a bug where create-mode forms reused stale controller state.

**Decision**
All temporary form controllers use `autoDispose`.
Create vs edit mode is determined only from immutable navigation/provider arguments.

**Rationale**
Prevents stale state leaking between screens.

**Consequences**
- Fresh controller every navigation.
- No hidden mutable mode state.
- Reusable pattern for all future forms.

---

# ADR-005 — Soft delete

**Status**
Accepted

**Date**
2026-08-07

**Context**
Deleted data may need synchronization, recovery, or audit history.

**Decision**
Person and Memory records are soft-deleted using `deletedAt`.

Repositories hide deleted records from callers.

**Rationale**
Supports future synchronization and recovery.

**Consequences**
- No hard deletes during normal app operation.
- Future restore functionality becomes possible.
- Sync engine can process deletions correctly.

---

# ADR-006 — Shared form screens

**Status**
Accepted

**Date**
2026-08-07

**Context**
Separate Add and Edit screens duplicate UI and validation logic.

**Decision**
Each entity has one shared form screen.

Examples:
- PersonFormScreen
- MemoryFormScreen

Mode is determined from route arguments.

**Rationale**
Reduces maintenance and keeps behavior consistent.

**Consequences**
- One validation path.
- One save flow.
- Less duplicated code.

---

# ADR-007 — Business defaults

**Status**
Accepted

**Date**
2026-08-07

**Context**
Default values such as Circle Tier and Memory Importance should not be scattered through the application.

**Decision**
Business defaults live in dedicated constants files.

Examples:
- person_defaults.dart
- memory_defaults.dart

**Rationale**
Single source of truth.

**Consequences**
Changing a default requires editing only one location.

---

# ADR-008 — Business rules

**Status**
Accepted

**Date**
2026-08-07

**Context**
Rules such as Memory sensitivity should not live inside widgets or repositories.

**Decision**
Business rules live in `domain/rules`.

Example:
- memory_sensitivity_rules.dart

**Rationale**
Reusable, testable, independent of UI and persistence.

**Consequences**
Future AI pipelines and manual forms use the same rules.

---

# ADR-009 — Manual-first before AI

**Status**
Accepted

**Date**
2026-08-07

**Context**
AI should not be introduced before manual workflows are stable.

**Decision**
Every feature is implemented manually before AI assistance is added.

**Rationale**
AI augments existing workflows rather than defining them.

**Consequences**
- Easier debugging
- Better testing
- Clear separation between CRUD and intelligence