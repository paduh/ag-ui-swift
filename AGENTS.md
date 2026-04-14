# AGENTS

<!-- Skills section removed -->

<skills_system priority="1">

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>swift-concurrency</name>
<description>'Expert guidance on Swift Concurrency best practices, patterns, and implementation. Use when developers mention: (1) Swift Concurrency, async/await, actors, or tasks, (2) "use Swift Concurrency" or "modern concurrency patterns", (3) migrating to Swift 6, (4) data races or thread safety issues, (5) refactoring closures to async/await, (6) @MainActor, Sendable, or actor isolation, (7) concurrent code architecture or performance optimization, (8) concurrency-related linter warnings (SwiftLint or similar; e.g. async_without_await, Sendable/actor isolation/MainActor lint).'</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>

### Concurrency Rules

Swift 6 targets enable NonisolatedNonsendingByDefault and InferIsolatedConformances.

- **No default `@MainActor` isolation** at module level. Apply `@MainActor` explicitly where needed (views, view models, UI-bound types).
- **Use `@concurrent`** to mark a nonisolated async function that must run on the cooperative pool, not the caller's actor.
- **Do not use `assumeIsolated`**. Use explicit isolation annotations (`@MainActor`) or restructure the code.
- **Do not use `DispatchQueue.main.async` or `DispatchQueue.global().async`** in new code. Use `async/await` and `@MainActor` functions.
- **Do not create custom actors.** Use `@MainActor`, `LeagueLocked`, or `NSLock` instead.
- **Non-Sendable first.** Default to plain, nonisolated, non-`Sendable` types. `Sendable` and isolation are constraints — only add them when a type must cross an isolation boundary. Reach for `@MainActor`, `Sendable`, or `LeagueLocked` only when the compiler requires it.
- **No `unsafe`/`unchecked` APIs.** Do not use `nonisolated(unsafe)`, `@unchecked Sendable`, `unsafeBitCast`, `unsafeDowncast`, `UnsafePointer` & friends, or `withUnsafe*`. For shared mutable state use `LeagueLocked` or `NSLock`. If genuinely needed (FFI, profiler-confirmed hot path), document why and open a decision record.
- **No new `unsafe`/`unchecked` APIs in app code.** Do not introduce `nonisolated(unsafe)`, new ad hoc `@unchecked Sendable` conformances, `unsafeBitCast`, `unsafeDowncast`, `UnsafePointer` & friends, or `withUnsafe*`. `LeagueLocked` is an allowed, vetted wrapper for shared mutable state even though it uses `@unchecked Sendable` internally; otherwise use `NSLock`. If genuinely needed (FFI, profiler-confirmed hot path), document why and open a decision record.
- **No `unsafe`/`unchecked` APIs.** Do not use `nonisolated(unsafe)`, `@unchecked Sendable`, `unsafeBitCast`, `unsafeDowncast`, `UnsafePointer` & friends, or `withUnsafe*`. For shared mutable state use `NSLock`, but keep lock-protected critical sections synchronous/non-suspending — never hold a lock across an `await` or any other suspension point. Prefer `NSLock {}`-style APIs where available to make that constraint obvious. If genuinely needed (FFI, profiler-confirmed hot path), document why and open a decision record.
- **No `unsafe`/`unchecked` APIs.** Do not use `nonisolated(unsafe)`, `@unchecked Sendable`, `unsafeBitCast`, `unsafeDowncast`, `UnsafePointer` & friends, or `withUnsafe*`. For shared mutable state use `NSLock`. If genuinely needed (FFI, profiler-confirmed hot path), document why and open a decision record.

### Unstructured `Task {}`

Avoid `Task {}`. Prefer `async` functions, `async let`, and task groups.

If you must use `Task {}`, store the handle and cancel it when the owner is deallocated.

**Exception:** A one-shot `Task {}` that calls a single async function from a synchronous context (e.g. a button action) does not need to be stored:
