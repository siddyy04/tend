> **Backlog Rules**
>
> - Items in this document are intentionally out of scope for the current sprint.
> - New ideas should be added here instead of expanding the current sprint.
> - Priorities should be reviewed at the start of each sprint.
> - Completing the current sprint always takes precedence over backlog items.

# Product Backlog

## High Priority

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

---

### Activity log
Maintain a timeline of actions such as:
- Memory added
- Memory edited
- Memory deleted
- Person updated