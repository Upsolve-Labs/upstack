#!/bin/bash
set -e

BSTACK_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Installing upstack..."
echo ""

# 1. Link skills
mkdir -p "$SKILLS_DIR"

for skill_dir in "$BSTACK_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  target="$SKILLS_DIR/$skill_name"
  if [ -L "$target" ]; then
    rm "$target"
  fi
  ln -sf "$skill_dir" "$target"
  echo "  linked $skill_name"
done

echo ""
echo "upstack v$(cat "$BSTACK_DIR/VERSION") installed. $(ls -d "$BSTACK_DIR"/skills/*/ | wc -l | tr -d ' ') skills linked."
echo ""

# 2. Install gh CLI if missing
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is required for /ship, /review, and /advisor."
  if command -v brew &> /dev/null; then
    read -p "Install gh via Homebrew? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      brew install gh
    fi
  else
    echo "  Install manually: https://cli.github.com/"
  fi
fi

# 3. Ensure gh is authenticated
if command -v gh &> /dev/null; then
  if ! gh auth status &> /dev/null; then
    echo ""
    echo "gh is installed but not authenticated. Signing in now — this is required for /ship and /review to work."
    echo ""
    gh auth login
  else
    echo "gh: authenticated."
  fi
fi

# 4. Install agent-browser if missing
if ! command -v agent-browser &> /dev/null; then
  echo ""
  echo "agent-browser is required for /plan, /execute, /validate, and /qa (screenshots, UI navigation)."
  if command -v brew &> /dev/null; then
    read -p "Install agent-browser via Homebrew? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      brew install agent-browser
      agent-browser install
    fi
  else
    echo "  Install manually: https://agent-browser.dev/"
  fi
else
  echo "agent-browser: installed."
fi

# 5. Optional: Linear CLI
echo ""
read -p "Install Linear CLI for ticket tracking alongside TODO.md? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v brew &> /dev/null; then
    brew install schpet/tap/linear-cli
    echo "  Linear CLI installed."
  else
    echo "  Homebrew not found. Install manually: https://github.com/schpet/linear-cli"
  fi
fi

# 6. Optional: Add to current project for teammates
echo ""
read -p "Add upstack to the current project so teammates get it? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  PROJECT_SKILLS="$(pwd)/.claude/skills"
  mkdir -p "$PROJECT_SKILLS"
  cp -r "$BSTACK_DIR"/skills/* "$PROJECT_SKILLS/"
  echo "  Copied skills to $PROJECT_SKILLS"
  echo "  Commit .claude/skills/ so teammates get upstack automatically."
fi

echo ""
echo "Setup complete. Run /advisor to get started."
