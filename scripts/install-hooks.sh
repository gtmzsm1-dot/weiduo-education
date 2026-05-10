#!/usr/bin/env bash
# Install git hooks for this repo
set -euo pipefail

HOOKS_DIR=".git/hooks"
mkdir -p "$HOOKS_DIR"

# Pre-commit: check SYNC + node syntax
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# 1. SYNC check
if ! cmp -s index.html deploy/index.html; then
  echo "❌ index.html and deploy/index.html are out of sync"
  echo "   Run: cp index.html deploy/index.html"
  exit 1
fi

# 2. Node syntax check
NODE_BIN="/Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin/node"
if [[ ! -x "$NODE_BIN" ]]; then
  echo "⚠️ managed node not found at $NODE_BIN, skipping syntax check"
  exit 0
fi

TMPFILE=$(mktemp /tmp/precommit-check.XXXXXX.js)
trap "rm -f $TMPFILE" EXIT

python3 -c "
from pathlib import Path
text = Path('index.html').read_text(encoding='utf-8')
start = text.find('<script>')
end = text.rfind('</script>')
if start >= 0 and end > start:
    Path('$TMPFILE').write_text(text[start+8:end], encoding='utf-8')
"

if ! NODE_OPTIONS="" "$NODE_BIN" --check "$TMPFILE"; then
  echo "❌ JavaScript syntax error in index.html"
  exit 1
fi

echo "✅ pre-commit checks passed"
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Pre-commit hook installed at $HOOKS_DIR/pre-commit"
