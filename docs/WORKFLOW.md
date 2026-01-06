# Development Workflow Quick Reference

This guide provides a quick reference for the AGUISwift development workflow.

## Initial Setup

### Install Git Hooks

```bash
# From the project root
./scripts/install-git-hooks.sh
```

This installs hooks that prevent direct commits to `main`.

### Install GitHub CLI (Optional but Recommended)

```bash
brew install gh
gh auth login
```

## Daily Workflow

### Starting a New Feature

```bash
# 1. Update main
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/amazing-new-feature

# 3. Work on your feature
# Edit files...

# 4. Run tests frequently
swift test

# 5. Commit changes
git add .
git commit -m "feat: add amazing new feature

- Implement core functionality
- Add comprehensive tests
- Update documentation"

# 6. Push to remote
git push -u origin feature/amazing-new-feature

# 7. Create Pull Request
gh pr create --fill
```

### Working on a Bug Fix

```bash
# 1. Create fix branch
git checkout main
git pull origin main
git checkout -b fix/broken-thing

# 2. Fix the bug
# Edit files...

# 3. Add tests for the fix
# Write regression tests

# 4. Commit
git commit -m "fix: resolve broken thing

- Fix the root cause
- Add regression tests
- Update error handling"

# 5. Push and create PR
git push -u origin fix/broken-thing
gh pr create --fill
```

## Common Tasks

### Update Your Branch with Latest Main

```bash
# While on your feature branch
git fetch origin
git rebase origin/main

# If conflicts occur, resolve them:
# 1. Edit conflicting files
# 2. git add <resolved-files>
# 3. git rebase --continue
```

### Run All Quality Checks

```bash
# Build
swift build

# Test
swift test

# Format
swift package plugin --allow-writing-to-package-directory swiftformat

# Lint
swiftlint lint
```

### Create a Pull Request

**Using GitHub CLI** (easiest):

```bash
# Interactive creation
gh pr create

# With predefined title and body
gh pr create --title "feat: add authentication" --body "Implements user auth"

# Auto-fill from commits
gh pr create --fill
```

**Using Git Web UI**:

1. Push your branch
2. Go to GitHub repository
3. Click "Compare & pull request"
4. Fill in the template
5. Click "Create pull request"

### Review Someone's PR

```bash
# Checkout PR locally
gh pr checkout <PR-number>

# Or manually
git fetch origin pull/<PR-number>/head:pr-<PR-number>
git checkout pr-<PR-number>

# Review changes
git diff main...HEAD

# Run tests
swift test

# Leave review comments
gh pr review <PR-number> --comment --body "Looks good!"
gh pr review <PR-number> --approve
gh pr review <PR-number> --request-changes --body "Please fix XYZ"
```

### Update PR After Review

```bash
# On your feature branch
git checkout feature/amazing-new-feature

# Make requested changes
# Edit files...

# Commit changes
git add .
git commit -m "Address review feedback"

# Push updates
git push

# PR updates automatically!
```

### Merge a PR

**Using GitHub CLI**:

```bash
# Squash and merge (recommended)
gh pr merge <PR-number> --squash

# Regular merge
gh pr merge <PR-number> --merge

# Rebase and merge
gh pr merge <PR-number> --rebase
```

**Using GitHub Web UI**:

1. Navigate to the PR
2. Wait for all checks to pass
3. Get approval from reviewers
4. Click "Squash and merge"
5. Confirm merge

### Clean Up After Merge

```bash
# Update main
git checkout main
git pull origin main

# Delete merged feature branch
git branch -d feature/amazing-new-feature

# Delete remote branch (if not auto-deleted)
git push origin --delete feature/amazing-new-feature
```

## Branch Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<description>` | `feature/add-caching` |
| Bug Fix | `fix/<description>` | `fix/memory-leak` |
| Refactor | `refactor/<description>` | `refactor/simplify-parser` |
| Documentation | `docs/<description>` | `docs/api-examples` |
| Hotfix | `fix/<critical-issue>` | `fix/security-patch` |

## Commit Message Format

```
<type>: <short summary>

<optional detailed description>

<optional footer>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `docs` - Documentation changes
- `test` - Test additions/updates
- `chore` - Build/tooling changes
- `perf` - Performance improvements

### Examples

```bash
# Simple feature
git commit -m "feat: add bearer token authentication"

# Bug fix with details
git commit -m "fix: resolve UTF-8 boundary handling

The SSE parser was incorrectly handling multi-byte UTF-8
characters that span chunk boundaries. Now accumulates
bytes until valid sequence forms.

Fixes #123"

# Breaking change
git commit -m "feat!: redesign state management API

BREAKING CHANGE: StateManager is now an actor instead of
a class. Update all usages to use await.

Migration guide in docs/migration.md"
```

## Emergency Procedures

### Need to Commit Directly to Main? (Emergency Only)

```bash
# Bypass pre-commit hook (NOT RECOMMENDED)
git commit --no-verify -m "EMERGENCY: critical security fix"

# Better: Create hotfix branch and fast-track PR
git checkout -b fix/critical-security-issue
# Make minimal changes
git commit -m "fix: patch security vulnerability"
git push -u origin fix/critical-security-issue
gh pr create --title "HOTFIX: security vulnerability"
# Request immediate review
```

### Accidentally Committed to Main?

```bash
# If not pushed yet
git reset HEAD~1  # Undo last commit, keep changes
git checkout -b feature/my-feature  # Create proper branch
git commit -m "feat: my feature"
git push -u origin feature/my-feature

# If already pushed (requires force push - be careful!)
git checkout main
git reset --hard origin/main  # Reset to remote state
git checkout -b feature/my-feature
# Cherry-pick commits or redo work
```

## Tips & Tricks

### Keep Commits Focused

```bash
# Stage specific files
git add file1.swift file2.swift
git commit -m "feat: implement feature X"

# Stage parts of a file (interactive)
git add -p file.swift
```

### Review Before Committing

```bash
# See what changed
git diff

# See what's staged
git diff --cached

# Review commit before pushing
git show HEAD
```

### Work on Multiple Features

```bash
# Save current work
git stash push -m "WIP: feature A"

# Switch to different branch
git checkout -b feature/feature-b
# Work on feature B...

# Return to feature A
git checkout feature/feature-a
git stash pop
```

### Find Specific Commits

```bash
# Search commit messages
git log --grep="authentication"

# See changes in a file
git log -p -- path/to/file.swift

# See commits by author
git log --author="Your Name"

# Beautiful graph
git log --graph --oneline --all
```

## Getting Help

### GitHub CLI

```bash
gh pr --help
gh pr create --help
gh pr review --help
```

### Documentation

- Full guide: `CONTRIBUTING.md`
- Project standards: `CLAUDE.md`
- Architecture: `ARCHITECTURE.md`

### Common Issues

**Q: Git hook is preventing my commit?**
A: You're trying to commit to `main`. Create a feature branch first.

**Q: How do I test my changes before creating a PR?**
A: Run `swift test && swiftlint lint` before pushing.

**Q: My PR has conflicts?**
A: Rebase on main: `git fetch origin && git rebase origin/main`

**Q: How do I undo my last commit?**
A: `git reset HEAD~1` (keeps changes) or `git reset --hard HEAD~1` (discards changes)

**Q: Can I push directly to main in an emergency?**
A: Technically yes with `--no-verify`, but create a hotfix branch instead.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        main (protected)                       │
└──────────────┬──────────────────────────────────┬────────────┘
               │                                   │
               │ git checkout -b feature/X         │
               │                                   │
         ┌─────▼─────┐                      ┌─────▼─────┐
         │ feature/X │                      │  fix/Y    │
         └─────┬─────┘                      └─────┬─────┘
               │                                   │
               │ Commits                           │ Commits
               │ Tests                             │ Tests
               │                                   │
               │ git push                          │ git push
               │                                   │
               │ gh pr create                      │ gh pr create
               │                                   │
         ┌─────▼──────────┐              ┌────────▼─────────┐
         │ Pull Request X │              │ Pull Request Y   │
         │ ✓ CI Pass      │              │ ✓ CI Pass        │
         │ ✓ Review       │              │ ✓ Review         │
         └─────┬──────────┘              └────────┬─────────┘
               │                                   │
               │ Squash & Merge                    │ Squash & Merge
               │                                   │
               └───────────────┬───────────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │ main updated │
                        └──────────────┘
```

---

Happy coding! 🚀
