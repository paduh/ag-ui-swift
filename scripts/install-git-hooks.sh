#!/bin/bash
# Install git hooks for AGUISwift project
# This sets up the pre-commit hook to prevent direct commits to main

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Installing git hooks for AGUISwift..."

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not a git repository"
    echo "Please run this script from the AGUISwift project root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo "Installing pre-commit hook..."
cp "$SCRIPT_DIR/git-hooks/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed successfully!"
echo ""
echo "The following hooks are now active:"
echo "  • pre-commit: Prevents direct commits to main branch"
echo ""
echo "To bypass the hook in emergencies (not recommended):"
echo "  git commit --no-verify -m \"emergency fix\""
echo ""
echo "See CONTRIBUTING.md for the proper workflow."
