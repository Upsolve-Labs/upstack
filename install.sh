#!/bin/bash
set -e

UPSTACK_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# Detect OS
case "$(uname -s)" in
  Darwin*) OS="macos" ;;
  Linux*)  OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  *)       OS="unknown" ;;
esac

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

# Platform-specific install helpers
install_gh() {
  if [ "$OS" = "macos" ] && command -v brew &> /dev/null; then
    brew install gh
  elif [ "$OS" = "linux" ]; then
    if command -v apt &> /dev/null; then
      echo "Installing gh via apt..."
      (type -p wget >/dev/null || sudo apt-get install wget -y) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update && sudo apt install gh -y
    elif command -v dnf &> /dev/null; then
      echo "Installing gh via dnf..."
      sudo dnf install -y gh
    else
      echo "  Could not detect a supported package manager."
      echo "  Install manually: https://cli.github.com/"
      return 1
    fi
  elif [ "$OS" = "windows" ]; then
    if command -v winget &> /dev/null; then
      winget install --id GitHub.cli
    elif command -v scoop &> /dev/null; then
      scoop install gh
    else
      echo "  Install manually: https://cli.github.com/"
      return 1
    fi
  else
    echo "  Install manually: https://cli.github.com/"
    return 1
  fi
}

# agent-browser is from Vercel (https://github.com/vercel-labs/agent-browser)
install_agent_browser() {
  if [ "$OS" = "macos" ] && command -v brew &> /dev/null; then
    brew install agent-browser
  elif command -v npm &> /dev/null; then
    echo "Installing agent-browser via npm (from Vercel)..."
    npm install -g agent-browser
  else
    echo "  agent-browser requires Homebrew (macOS) or npm (any platform)."
    echo "  Install Node.js first: https://nodejs.org/"
    echo "  Then run: npm install -g agent-browser"
    return 1
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

  echo "  os: $OS"
  echo "  homebrew: $HAS_BREW"
  HAS_NPM=false
  command -v npm &> /dev/null && HAS_NPM=true
  echo "  npm: $HAS_NPM"
  HAS_APT=false
  command -v apt &> /dev/null && HAS_APT=true
  echo "  apt: $HAS_APT"
  echo ""
  echo "NEXT_STEPS:"
  echo "  - Walk the user through installing any missing tools (one AskUserQuestion per tool)."
  echo "    - gh: (strongly recommended) needed for /ship to push commits, create/update PRs, and generate release notes."
  echo "      - macOS: brew install gh"
  echo "      - Linux (apt): see https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  echo "      - Linux (dnf): sudo dnf install gh"
  echo "      - Windows: winget install --id GitHub.cli"
  echo "    - agent-browser: (strongly recommended) Vercel's browser automation CLI (https://github.com/vercel-labs/agent-browser). Needed for /plan, /validate, /review, /qa."
  echo "      - macOS: brew install agent-browser && agent-browser install"
  echo "      - Other: npm install -g agent-browser && agent-browser install (requires Node.js)"
  echo "    - linear-cli: (optional) needed to integrate with your team's Linear instead of relying just on TODO.md."
  echo "      - macOS: brew install schpet/tap/linear-cli"
  echo "      - Other: npm install -g linear-cli"
  echo "  - Add an 'upstack' section to the project's CLAUDE.md stating:"
  echo "    - Use agent-browser for all web browsing."
  echo "    - Available skills: /plan, /execute, /validate, /review, /ship, /qa, /advisor, /setup, /upgrade."
  echo "  - Tell the user to run /advisor to get started."
  exit 0
fi

# --- Interactive: prompt for each decision ---

# Install gh CLI if missing
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is needed for /ship to push commits, create/update PRs, and generate release notes."
  if prompt_yn "Install gh? (Y/n) " "Y"; then
    install_gh
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

# Install agent-browser if missing (Vercel's browser automation CLI)
if ! command -v agent-browser &> /dev/null; then
  echo ""
  echo "agent-browser (by Vercel) is needed for /plan, /validate, /review, /qa to navigate frontend, click around the browser, and screenshot functionality."
  if prompt_yn "Install agent-browser? (Y/n) " "Y"; then
    install_agent_browser && agent-browser install
  fi
else
  echo "agent-browser: installed."
fi

# Optional: Linear CLI
if prompt_yn "
Install Linear CLI to integrate with your team's Linear instead of relying just on TODO.md? (y/N) " "N"; then
  if [ "$OS" = "macos" ] && command -v brew &> /dev/null; then
    brew install schpet/tap/linear
    echo "  Linear CLI installed."
  elif command -v npm &> /dev/null; then
    npm install -g linear-cli
    echo "  Linear CLI installed."
  else
    echo "  Install manually: https://github.com/schpet/linear-cli"
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
