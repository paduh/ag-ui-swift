#!/bin/bash

echo "🔍 Verifying documentation structure..."
echo ""

ERRORS=0

# Check landing page
if [ -f "./docs-test/index.html" ]; then
  echo "✅ Landing page exists: docs-test/index.html"
else
  echo "❌ Landing page missing: docs-test/index.html"
  ERRORS=$((ERRORS + 1))
fi

# Check .nojekyll
if [ -f "./docs-test/.nojekyll" ]; then
  echo "✅ .nojekyll file exists"
else
  echo "❌ .nojekyll file missing"
  ERRORS=$((ERRORS + 1))
fi

# Check each target
for target in AGUICore AGUIClient AGUITools AGUIAgentSDK; do
  echo ""
  echo "Checking $target..."
  
  if [ ! -d "./docs-test/$target" ]; then
    echo "  ❌ Directory missing: docs-test/$target"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  
  if [ -f "./docs-test/$target/index.html" ]; then
    echo "  ✅ index.html exists"
  else
    echo "  ❌ index.html missing"
    ERRORS=$((ERRORS + 1))
  fi
  
  # Check for common DocC files
  if [ -d "./docs-test/$target/css" ]; then
    echo "  ✅ css/ directory exists"
  else
    echo "  ⚠️  css/ directory missing (may be normal)"
  fi
  
  if [ -d "./docs-test/$target/js" ]; then
    echo "  ✅ js/ directory exists"
  else
    echo "  ⚠️  js/ directory missing (may be normal)"
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "✅ All critical checks passed!"
  exit 0
else
  echo "❌ Found $ERRORS error(s)"
  exit 1
fi
