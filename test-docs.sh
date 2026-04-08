#!/bin/bash
set -e

echo "🧹 Cleaning old docs..."
rm -rf docs-test
mkdir -p docs-test

echo "📚 Generating documentation for all targets..."
for target in AGUICore AGUIClient AGUITools AGUIAgentSDK; do
  echo "  Generating docs for $target..."
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
echo "🔧 Fixing filenames (colons -> hyphens) and updating references..."
python3 - << 'PYTHON_EOF'
import os
import glob
from pathlib import Path

def build_rename_map(root_dir):
    rename_map = {}
    root_path = Path(root_dir)
    for path in root_path.rglob("*"):
        if ":" in path.name:
            new_name = path.name.replace(":", "-")
            new_path = path.with_name(new_name)
            old_rel = path.relative_to(root_path).as_posix()
            new_rel = new_path.relative_to(root_path).as_posix()
            rename_map[old_rel] = new_rel
    return rename_map

def apply_renames(root_dir, rename_map):
    root_path = Path(root_dir)
    for old_rel in sorted(rename_map.keys(), key=lambda p: p.count("/"), reverse=True):
        old_path = root_path / old_rel
        new_path = root_path / rename_map[old_rel]
        if old_path.exists():
            os.rename(old_path, new_path)

def build_replacements(rename_map):
    replacements = []
    for old_rel, new_rel in rename_map.items():
        replacements.append((old_rel, new_rel))
        replacements.append(("/" + old_rel, "/" + new_rel))
    return replacements

def replace_all(content, replacements):
    for old_value, new_value in replacements:
        content = content.replace(old_value, new_value)
    return content

rename_map = build_rename_map("./docs-test")
print(f"Found {len(rename_map)} paths to rename")
apply_renames("./docs-test", rename_map)

if rename_map:
    replacements = build_replacements(rename_map)
    files_to_update = glob.glob("./docs-test/**/*.json", recursive=True)
    files_to_update.extend(glob.glob("./docs-test/**/*.html", recursive=True))
    for path in files_to_update:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        updated = replace_all(content, replacements)
        if updated != content:
            with open(path, "w", encoding="utf-8") as f:
                f.write(updated)
PYTHON_EOF

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
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 2rem;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    header {
      text-align: center;
      color: white;
      margin-bottom: 3rem;
    }
    header h1 {
      font-size: 3rem;
      margin-bottom: 0.5rem;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
    }
    header p {
      font-size: 1.2rem;
      opacity: 0.9;
    }
    .targets {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 2rem;
      margin-top: 2rem;
    }
    .target-card {
      background: white;
      border-radius: 12px;
      padding: 2rem;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      text-decoration: none;
      color: inherit;
      display: block;
    }
    .target-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 15px 40px rgba(0,0,0,0.3);
    }
    .target-card h2 {
      color: #667eea;
      margin-bottom: 1rem;
      font-size: 1.8rem;
    }
    .target-card p {
      color: #666;
      margin-bottom: 1.5rem;
    }
    .target-card .link {
      color: #667eea;
      font-weight: 600;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
    }
    .target-card .link:hover {
      text-decoration: underline;
    }
    .target-card .link::after {
      content: '→';
      transition: transform 0.3s ease;
    }
    .target-card:hover .link::after {
      transform: translateX(5px);
    }
    footer {
      text-align: center;
      color: white;
      margin-top: 4rem;
      opacity: 0.9;
    }
    footer a {
      color: white;
      text-decoration: underline;
    }
    @media (max-width: 768px) {
      header h1 {
        font-size: 2rem;
      }
      .targets {
        grid-template-columns: 1fr;
      }
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
        <p>Core event types, decoding infrastructure, and protocol implementations. The foundation of the AG-UI Swift SDK.</p>
        <span class="link">View Documentation</span>
      </a>

      <a href="./AGUIClient/" class="target-card">
        <h2>AGUIClient</h2>
        <p>Client-side functionality for connecting to AG-UI protocol servers and managing agent interactions.</p>
        <span class="link">View Documentation</span>
      </a>

      <a href="./AGUITools/" class="target-card">
        <h2>AGUITools</h2>
        <p>Utility tools and helpers for working with AG-UI events and protocol features.</p>
        <span class="link">View Documentation</span>
      </a>

      <a href="./AGUIAgentSDK/" class="target-card">
        <h2>AGUIAgentSDK</h2>
        <p>High-level APIs for building agent applications with AG-UI protocol support.</p>
        <span class="link">View Documentation</span>
      </a>
    </div>

    <footer>
      <p>
        <a href="https://github.com/paduh/ag-ui-swift">GitHub Repository</a> |
        <a href="https://github.com/paduh/ag-ui-swift/issues">Report Issues</a>
      </p>
    </footer>
  </div>
</body>
</html>
LANDING_EOF

echo "📝 Creating .nojekyll file..."
touch ./docs-test/.nojekyll

echo ""
echo "📁 Generated documentation structure:"
ls -la ./docs-test/ | grep "^d" | awk '{print "  " $NF}'

echo ""
echo "✅ Documentation generated successfully!"
echo ""
echo "🌐 To test locally, run one of these commands:"
echo "   Python 3:  python3 -m http.server 8000 --directory docs-test"
echo "   Python 2:  python -m SimpleHTTPServer 8000 (from docs-test directory)"
echo "   Node.js:   npx serve docs-test"
echo "   PHP:       php -S localhost:8000 -t docs-test"
echo ""
echo "   Then open: http://localhost:8000"
echo "   (Note: Use /ag-ui-swift/AGUICore/ etc. in the URL to match GitHub Pages structure)"
