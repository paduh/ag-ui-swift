# Linting & Concurrency

Guidance for handling lint rules related to Swift Concurrency.

## SwiftLint: `async_without_await`
- **Intent**: A declaration should not be `async` if it never awaits.
- **Never “fix”** by inserting fake suspension (e.g. `await Task.yield()`, `await Task { ... }.value`). Those mask the real issue and add meaningless suspension points.
- **Legit use of `Task.yield()`**: OK in tests or scheduling control when you truly need a yield; not as a lint workaround.

### Diagnose why the declaration is `async`
1) **Protocol requirement** — the protocol method/property is `async`.
2) **Override requirement** — base class API is `async`.
3) **`@concurrent` requirement** — stays `async` even without `await`.
4) **Accidental/legacy `async`** — no caller needs async semantics.

### Preferred fixes (order)
1) **Remove `async`** (and adjust call sites) when no async semantics are needed.
2) If `async` is required (protocol/override/@concurrent):
   - Re-evaluate the upstream API if you own it (can it be non-async?).
   - If you cannot change it, keep `async` and **narrowly suppress the rule** where appropriate (common for mocks/stubs/overrides).

### Suppression examples (keep scope tight)
```swift
// swiftlint:disable:next async_without_await
func fetch() async { perform() }

// For a block:
// swiftlint:disable async_without_await
func makeMock() async { perform() }
// swiftlint:enable async_without_await
```

### Quick checklist
- [ ] Confirm if `async` is truly required (protocol/override/@concurrent).
- [ ] If not required, remove `async` and update callers.
- [ ] If required, prefer localized suppression over dummy awaits.
- [ ] Avoid adding new suspension points without intent.

