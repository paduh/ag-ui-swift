#!/bin/bash
set -e

echo "🧹 Cleaning old test docs..."
rm -rf docs-test
mkdir -p docs-test

echo "📚 Generating documentation for all targets..."
for target in AGUICore AGUIClient AGUITools AGUIAgentSDK; do
  echo "  📖 Generating docs for $target..."
  swift package --allow-writing-to-directory ./docs-test/$target \
    generate-documentation --target $target \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path /ag-ui-swift/$target \
    --output-path ./docs-test/$target
  
  # Verify index.html was created
  if [ ! -f "./docs-test/$target/index.html" ]; then
    echo "  ⚠️  Warning: index.html not found for $target"
  else
    echo "  ✅ Successfully generated docs for $target"
  fi
done

echo ""
echo "🔧 Fixing filenames (colons -> hyphens)..."
find ./docs-test -depth -name "*:*" | while read -r file; do
  dir=$(dirname "$file")
  base=$(basename "$file")
  newbase=$(echo "$base" | tr ':' '-')
  mv "$file" "$dir/$newbase"
done

echo "🔧 Updating JSON references..."
find ./docs-test -name "*.json" -type f -exec sed -i '' 's/:/\\-/g' {} +

echo ""
echo "📄 Creating landing page..."
cat > ./docs-test/index.html << 'LANDING_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AG-UI Swift SDK Documentation</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 2rem;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    header { text-align: center; color: white; margin-bottom: 3rem; }
    header h1 { font-size: 3rem; margin-bottom: 0.5rem; text-shadow: 2px 2px 4px rgba(0,0,0,0.2); }
    header p { font-size: 1.2rem; opacity: 0.9; }
    .targets { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 2rem; margin-top: 2rem; }
    .target-card {
      background: white;
      border-radius: 12px;
      padding: 2rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
      transition: transform 0.3s ease;
      text-decoration: none;
      color: inherit;
      display: block;
    }
    .target-card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.3); }
    .target-card h2 { color: #667eea; margin-bottom: 1rem; font-size: 1.8rem; }
    .target-card p { color: #666; margin-bottom: 1.5rem; }
    .target-card .link { color: #667eea; font-weight: 600; }
    footer { text-align: center; color: white; margin-top: 4rem; opacity: 0.9; }
    footer a { color: white; text-decoration: underline; }
    @media (max-width: 768px) {
      header h1 { font-size: 2rem; }
      .targets { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>AG-UI Swift SDK</h1>
      <p>Comprehensive API Documentation</p>
    </header>
    <div class="targets">
      <a href="./AGUICore/" class="target-card">
        <h2>AGUICore</h2>
        <p>Core event types, decoding infrastructure, and protocol implementations.</p>
        <span class="link">View Documentation →</span>
      </a>
      <a href="./AGUIClient/" class="target-card">
        <h2>AGUIClient</h2>
        <p>Client-side functionality for connecting to AG-UI protocol servers.</p>
        <span class="link">View Documentation →</span>
      </a>
      <a href="./AGUITools/" class="target-card">
        <h2>AGUITools</h2>
        <p>Utility tools and helpers for working with AG-UI events.</p>
        <span class="link">View Documentation →</span>
      </a>
      <a href="./AGUIAgentSDK/" class="target-card">
        <h2>AGUIAgentSDK</h2>
        <p>High-level APIs for building agent applications.</p>
        <span class="link">View Documentation →</span>
      </a>
    </div>
    <footer>
      <p><a href="https://github.com/paduh/ag-ui-swift">GitHub Repository</a></p>
    </footer>
  </div>
</body>
</html>
LANDING_EOF

echo "📝 Creating .nojekyll file..."
touch ./docs-test/.nojekyll

echo ""
echo "📁 Generated documentation structure:"
ls -la ./docs-test/ | grep "^d" | awk '{print "  📂 " $NF}'

echo ""
echo "✅ Documentation generated successfully!"
echo ""
echo "🌐 Testing Options:"
echo ""
echo "Option 1: Simple HTTP Server (basic testing)"
echo "  Run: python3 -m http.server 8000 --directory docs-test"
echo "  Open: http://localhost:8000"
echo "  Note: Links will work, but assets may not load correctly due to base path"
echo ""
echo "Option 2: Test structure verification"
echo "  Run: ./verify-docs-structure.sh"
echo "  This will check if all required files exist"
echo ""
echo "Option 3: Manual inspection"
echo "  Check that each target has an index.html:"
for target in AGUICore AGUIClient AGUITools AGUIAgentSDK; do
  if [ -f "./docs-test/$target/index.html" ]; then
    echo "    ✅ $target/index.html exists"
  else
    echo "    ❌ $target/index.html MISSING"
  fi
done
