## Duplicate person names

### Problem
Users can create multiple people with the same name, making the list confusing.

### Current behavior
Allowed (UUID distinguishes them internally).

### Proposed solution
- Detect duplicate names during creation/edit.
- Show a non-blocking informational message:
  "A person with this name already exists."
- Suggest adding a Relationship Type or nickname to distinguish them.
- Continue allowing the save.

### Out of scope
Do not enforce name uniqueness.
Do not make Relationship Type mandatory.