# Changelog

All notable user-visible changes to Tend will be documented here.

This project follows a simple chronological changelog.

---

# v0.2.0 — Person & Memory Foundation

## Added

### Authentication
- Email/password authentication
- Persistent login session
- Splash screen authentication check

### My Circle
- Offline Person CRUD
- Shared PersonFormScreen
- Soft delete
- Circle grouping
- Empty state
- Validation

### Person Profile
- Dedicated profile screen
- Read-only person header
- Edit person action

### Memories
- Offline Memory CRUD
- Shared MemoryFormScreen
- Reverse chronological timeline
- Memory categories
- Importance levels
- Manual date support
- Soft delete
- Memory sensitivity rules

### Architecture
- Isar local database
- Repository pattern
- Riverpod state management
- Offline-first design
- UUID-based relationships

---

## Changed

- Tapping a person now opens Person Profile instead of the Person edit form.
- Memory timelines now live inside Person Profile.

---

## Fixed

- Fixed create/edit controller reuse bug caused by long-lived Riverpod providers.
- Form controllers now use autoDispose.
- Create/edit mode now depends solely on immutable route arguments.

---

# v0.1.0 — Project Foundation

## Added

- Flutter project setup
- Supabase authentication
- Isar initialization
- Routing
- Project architecture
- Development workflow
- Documentation