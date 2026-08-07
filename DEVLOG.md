# Tend Development Log

## Sprint 0
- Project created
- Supabase authentication completed
- Isar initialized
- Router implemented
- Authentication UX improved

## Sprint 1A
- Person CRUD against Isar completed
- My Circle grouped by circle tier (empty state, add/edit/soft-delete)
- Shared PersonFormScreen with autoDispose form controller
- Create vs edit keyed only by `personUuid` (fixed create-reuse bug)

## Sprint 1B
- MemoryRepository + validators + sensitivity rules completed
- Person Profile with permanent header + memory timeline
- Manual MemoryFormScreen (create/edit/soft-delete)
- Circle tap → Person Profile; person edit secondary from profile
- Person→memory cascade deferred (see BACKLOG.md)
- Housekeeping: CURSOR_HANDOFF updated for post-1B / Sprint 2 next
