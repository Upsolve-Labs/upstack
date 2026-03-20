#!/bin/bash
set -e

UPSTACK_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# Detect non-interactive shell (e.g. Claude Code, piped input)
if [ -t 0 ]; then
  INTERACTIVE=true
else
  INTERACTIVE=false
fi

prompt_yn() {
  local prompt="$1" default="$2"
  if [ "$INTERACTIVE" = false ]; then
    # Non-interactive: use default
    if [ "$default" = "Y" ]; then return 0; else return 1; fi
  fi
  read -p "$prompt" -n 1 -r
  echo
  if [ "$default" = "Y" ]; then
    [[ ! $REPLY =~ ^[Nn]$ ]]
  else
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

echo "Installing upstack..."
if [ "$INTERACTIVE" = false ]; then
  echo "(non-interactive mode — accepting defaults, skipping optional extras)"
fi
echo ""

# 1. Link skills
mkdir -p "$SKILLS_DIR"

for skill_dir in "$UPSTACK_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  target="$SKILLS_DIR/$skill_name"
  if [ -L "$target" ]; then
    rm "$target"
  fi
  ln -sf "$skill_dir" "$target"
  echo "  linked $skill_name"
done

echo ""
echo "upstack v$(cat "$UPSTACK_DIR/VERSION") installed. $(ls -d "$UPSTACK_DIR"/skills/*/ | wc -l | tr -d ' ') skills linked."
echo ""

# 2. Install gh CLI if missing
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is required for /ship, /review, and /advisor."
  if command -v brew &> /dev/null; then
    if prompt_yn "Install gh via Homebrew? (Y/n) " "Y"; then
      brew install gh
    fi
  else
    echo "  Install manually: https://cli.github.com/"
  fi
else
  echo "gh: installed."
fi

# 3. Ensure gh is authenticated
if command -v gh &> /dev/null; then
  if ! gh auth status &> /dev/null; then
    if [ "$INTERACTIVE" = true ]; then
      echo ""
      echo "gh is installed but not authenticated."
      echo ""
      gh auth login
    else
      echo ""
      echo "NEEDS_ACTION: gh-auth — run 'gh auth login' in your terminal to sign in."
    fi
  else
    echo "gh: authenticated."
  fi
fi

# 4. Install agent-browser if missing
if ! command -v agent-browser &> /dev/null; then
  echo ""
  echo "agent-browser is required for /plan, /execute, /validate, and /qa (screenshots, UI navigation)."
  if command -v brew &> /dev/null; then
    if prompt_yn "Install agent-browser via Homebrew? (Y/n) " "Y"; then
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
if prompt_yn "
Install Linear CLI for ticket tracking alongside TODO.md? (y/N) " "N"; then
  if command -v brew &> /dev/null; then
    brew install schpet/tap/linear-cli
    echo "  Linear CLI installed."
  else
    echo "  Homebrew not found. Install manually: https://github.com/schpet/linear-cli"
  fi
else
  SKIPPED="${SKIPPED}linear-cli,"
fi

# 6. Optional: Add to current project for teammates
if prompt_yn "
Add upstack to the current project so teammates get it? (y/N) " "N"; then
  PROJECT_SKILLS="$(pwd)/.claude/skills"
  mkdir -p "$PROJECT_SKILLS"
  cp -r "$UPSTACK_DIR"/skills/* "$PROJECT_SKILLS/"
  echo "  Copied skills to $PROJECT_SKILLS"
  echo "  Commit .claude/skills/ so teammates get upstack automatically."
else
  SKIPPED="${SKIPPED}project-skills,"
fi

echo ""
if [ -n "$SKIPPED" ]; then
  echo "SKIPPED_OPTIONAL: ${SKIPPED%,}"
fi
echo "Setup complete. Run /advisor to get started."
