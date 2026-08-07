> **Backlog Rules**
>
> - Items in this document are intentionally out of scope for the current sprint.
> - New ideas should be added here instead of expanding the current sprint.
> - Priorities should be reviewed at the start of each sprint.
> - Completing the current sprint always takes precedence over backlog items.

# Product Backlog

## High Priority

### Person → memory cascade delete
**Problem**
`FEATURES.md` requires deleting a person to cascade to their memories, follow-ups, and suggestion history. Sprint 1B intentionally deferred this.

**Proposed solution**
- When a Person is soft-deleted, also soft-delete related Memories (and later FollowUps / suggestion history).
- Keep tombstones; never hard-delete in early sprints.
- Likely fits Sprint 6 data-controls work unless re-prioritized earlier.
- Resolve `FollowUp.deletedAt` SCHEMA vs ARCHITECTURE mismatch before cascading to FollowUps.

---

### PersonRepository.getByUuid hides soft-deleted records
**Problem**
`MemoryRepository.getByUuid` excludes soft-deleted rows at the Isar query layer. `PersonRepository.getByUuid` still returns tombstoned people via the unique-index helper.

**Proposed solution**
- Align Person with Memory: filter `uuidEqualTo` + `deletedAtIsNull` in the repository query.
- Keeps “repositories hide deleted records completely” consistent.

---

### Duplicate person names
**Problem**
Multiple people can legitimately share the same name, making the Circle list confusing.

**Proposed solution**
- Detect duplicate names during create/edit.
- Show a non-blocking informational message.
- Suggest adding a Relationship Type or nickname.
- Never prevent saving.

---

### Undo delete
**Problem**
Accidental deletes currently require a future restore feature.

**Proposed solution**
- After deleting a Person or Memory, show:
  - "Deleted"
  - Undo button
- Keep soft delete as the underlying implementation.

---

## Medium Priority

### Temporary Logout on My Circle
**Problem**
Developer Logout lives on the My Circle AppBar from Sprint 0.

**Proposed solution**
- Move sign-out into Settings (Sprint 5/6) and remove the temporary AppBar action.

---

### Auth surface: phone OTP
**Problem**
`FEATURES.md` mentions email/phone OTP; the app currently supports email/password only.

**Proposed solution**
- Add phone OTP (or document email/password as the intentional MVP auth path).

---

### Person Profile extras (FEATURES P0 notes)
**Problem**
FEATURES Person Profile lists upcoming/recent, category filter, and search entry point. Sprint 1B shipped timeline + manual memories only.

**Proposed solution**
- Add category filter / search entry / upcoming-recent sections when those P0 surfaces are built (Search sprint / polish), without expanding AI scope early.

---

### FollowUp.deletedAt schema alignment
**Problem**
`ARCHITECTURE.md` collection sketch includes `deletedAt` on FollowUp; `SCHEMA.md` FollowUp does not.

**Proposed solution**
- Pick one contract before Sprint 3 (Suggestion Engine) or cascade-delete work touches FollowUps.
- Prefer updating SCHEMA + Isar collection together if tombstones are required.

---

### Archive person
Allow users to archive a person without deleting them or their memories.
Archived people should disappear from My Circle but remain searchable and restorable.

---

### Rich display names
Support richer display names such as:
- Uncle John
- John (Work)
- John Smith
- Dr. Patel

without changing the underlying identity model.

---

### Timeline grouping
Group memories by year and month once a person has many memories.

Example:
2026
- July
- June

2025
- December
- October

---

### Pin memories
Allow users to pin important memories so they always appear above the chronological timeline.

---

### Favorite people
Allow users to pin important people to the top of My Circle regardless of Circle Tier.

---

### Recent activity
Display the latest interaction or memory date for each person in My Circle.

Example:
Sarah
Last memory: 2 days ago

---

### Global search improvements
Future search should support:
- People
- Memories
- Suggestions

instead of a single combined list.

---

## Low Priority

### App theme stub
**Problem**
`lib/core/theme/app_theme.dart` is still Sprint 0 scaffolding.

**Proposed solution**
- Define real theme tokens when visual polish is prioritized (often Sprint 6).

---

### Merge duplicate people
Allow users to merge two Person records while preserving all memories.

---

### Person avatars
Support optional profile photos or avatars.

---

### Timeline filters
Allow filtering memories by category (Health, Family, Work, Finance, etc.).

---

### Person statistics
Display simple profile statistics such as:
- Total memories
- Last updated
- Completed follow-ups

------

# Technical Debt

## Person delete cascade
**Priority:** High

**Problem**
Deleting a Person currently soft-deletes only the Person record.

**Future work**
Implement a transactional soft-delete cascade:
- Person → Memories
- Person → FollowUps (when FollowUps are implemented)

This was intentionally deferred from Sprint 1B.

---

## Repository consistency
**Priority:** High

**Problem**
`PersonRepository.getByUuid()` may still return soft-deleted people.

**Future work**
Ensure all repositories hide soft-deleted entities consistently at the repository boundary.

---

## Logout location
**Priority:** Medium

**Problem**
Logout is temporarily located on the My Circle screen for development convenience.

**Future work**
Move Logout into the future Settings screen.

---

## App theme
**Priority:** Medium

**Problem**
`app_theme.dart` is still a scaffold.

**Future work**
Complete the application theme once the visual design is finalized.

---

## FollowUp schema review
**Priority:** Medium

**Problem**
The architecture notes and schema differ regarding `FollowUp.deletedAt`.

**Future work**
Resolve the schema before implementing FollowUps or delete cascades.

---

## Person Profile enhancements
**Priority:** Medium

Deferred from Sprint 1B:

- Memory category filters
- Search within a person's memories
- Upcoming / Recent memories section

### Activity log
Maintain a timeline of actions such as:
- Memory added
- Memory edited
- Memory deleted
- Person updated
