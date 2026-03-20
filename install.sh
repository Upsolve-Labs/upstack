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
  read -p "$prompt" -n 1 -r
  echo
  if [ "$default" = "Y" ]; then
    [[ ! $REPLY =~ ^[Nn]$ ]]
  else
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

# --- Always safe: link skills ---
echo "Installing upstack..."
echo ""

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

# --- Non-interactive: report status, don't act ---
if [ "$INTERACTIVE" = false ]; then
  HAS_BREW=false
  command -v brew &> /dev/null && HAS_BREW=true

  echo "INSTALL_STATUS:"

  # gh
  if command -v gh &> /dev/null; then
    echo "  gh: installed"
    if gh auth status &> /dev/null; then
      echo "  gh-auth: authenticated"
    else
      echo "  gh-auth: not-authenticated"
    fi
  else
    echo "  gh: missing"
  fi

  # agent-browser
  if command -v agent-browser &> /dev/null; then
    echo "  agent-browser: installed"
  else
    echo "  agent-browser: missing"
  fi

  # linear-cli
  if command -v linear &> /dev/null; then
    echo "  linear-cli: installed"
  else
    echo "  linear-cli: missing"
  fi

  echo "  homebrew: $HAS_BREW"
  echo ""
  echo "NEXT_STEPS:"
  echo "  - Walk the user through installing any missing tools (one AskUserQuestion per tool)."
  echo "    - gh: (strongly recommended) needed for /ship to push commits, create/update PRs, and generate release notes."
  echo "    - agent-browser: (strongly recommended) needed for /plan, /validate, /review, /qa to navigate frontend, click around the browser, and screenshot functionality."
  echo "    - linear-cli: (optional) needed to integrate with your team's Linear instead of relying just on TODO.md."
  echo "  - Add an 'upstack' section to the project's CLAUDE.md stating:"
  echo "    - Use agent-browser for all web browsing."
  echo "    - Available skills: /plan, /execute, /validate, /review, /ship, /qa, /advisor, /setup, /upgrade."
  exit 0
fi

# --- Interactive: prompt for each decision ---

# Install gh CLI if missing
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is needed for /ship to push commits, create/update PRs, and generate release notes."
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

# Ensure gh is authenticated
if command -v gh &> /dev/null; then
  if ! gh auth status &> /dev/null; then
    echo ""
    echo "gh is installed but not authenticated."
    echo ""
    gh auth login
  else
    echo "gh: authenticated."
  fi
fi

# Install agent-browser if missing
if ! command -v agent-browser &> /dev/null; then
  echo ""
  echo "agent-browser is needed for /plan, /validate, /review, /qa to navigate frontend, click around the browser, and screenshot functionality."
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

# Optional: Linear CLI
if prompt_yn "
Install Linear CLI to integrate with your team's Linear instead of relying just on TODO.md? (y/N) " "N"; then
  if command -v brew &> /dev/null; then
    brew install schpet/tap/linear-cli
    echo "  Linear CLI installed."
  else
    echo "  Homebrew not found. Install manually: https://github.com/schpet/linear-cli"
  fi
fi

# Optional: Add to current project for teammates
if prompt_yn "
Add upstack to the current project so teammates get it? (y/N) " "N"; then
  PROJECT_SKILLS="$(pwd)/.claude/skills"
  mkdir -p "$PROJECT_SKILLS"
  cp -r "$UPSTACK_DIR"/skills/* "$PROJECT_SKILLS/"
  echo "  Copied skills to $PROJECT_SKILLS"
  echo "  Commit .claude/skills/ so teammates get upstack automatically."
fi

echo ""
echo "Setup complete. Run /advisor to get started."
