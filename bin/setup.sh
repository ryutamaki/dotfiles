#!/usr/bin/env bash
#
# Bring a machine up to what this repository describes.
#
#   bash ./bin/setup.sh
#
# Safe to re-run: existing correct symlinks are left alone, and anything real
# that is in the way is moved aside with a timestamp rather than deleted.
# What it cannot do -- logging into gh, claude and codex, wiring the status
# line into their config files, SSH keys, granting Ghostty its global hotkey
# -- is listed at the end and in README.md.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="$HOME/dotfiles_old/$(date +%Y%m%d%H%M%S)"

info() { printf '\033[36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$1"; }

# link <source relative to repo> <absolute destination>
link() {
    local src="$DOTFILES/$1" dest="$2"

    if [ ! -e "$src" ]; then
        warn "skip $1 (not in repo)"
        return
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
        mv "$dest" "$BACKUP/${dest#"$HOME"/}"
        info "backed up ${dest#"$HOME"/} -> ${BACKUP#"$HOME"/}"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    info "linked ${dest#"$HOME"/}"
}


##-----------------------------------------------
#  Homebrew
##-----------------------------------------------

if ! command -v brew > /dev/null; then
    info "installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --no-upgrade keeps this script safe to re-run: it installs what is missing
# and leaves working versions alone. Upgrading is a separate, deliberate act:
#   brew bundle upgrade --file=Brewfile
info "installing packages from Brewfile"
brew bundle install --no-upgrade --file="$DOTFILES/Brewfile"

# compinit refuses to load completions when any directory on fpath is
# group-writable, and Homebrew leaves share/ that way.
if [ -d "$(brew --prefix)/share" ]; then
    chmod g-w "$(brew --prefix)/share"
fi


##-----------------------------------------------
#  Symlinks
##-----------------------------------------------

link .vim      "$HOME/.vim"
link .vimrc    "$HOME/.vimrc"
link .zsh      "$HOME/.zsh"
link .zshrc    "$HOME/.zshrc"
link .zshenv   "$HOME/.zshenv"
link .zprofile "$HOME/.zprofile"
link .gitconfig "$HOME/.gitconfig"
link .tigrc    "$HOME/.tigrc"

# Files under ~/.config are linked one at a time so that other tools' files in
# those directories are left untouched.
link config/ghostty/config  "$HOME/.config/ghostty/config"
link config/git/ignore      "$HOME/.config/git/ignore"
link config/mise/config.toml "$HOME/.config/mise/config.toml"
link config/herdr/config.toml "$HOME/.config/herdr/config.toml"
link config/starship.toml    "$HOME/.config/starship.toml"

# The two agent skills that are written here rather than installed. Everything
# else under ~/.agents/skills comes from upstream and is reinstalled further
# down; these two appear in no lockfile and exist nowhere but this repository.
link claude/skills/cleanup      "$HOME/.claude/skills/cleanup"
link claude/skills/audit-memory "$HOME/.claude/skills/audit-memory"

# One instruction file, two names. claude reads ~/.claude/CLAUDE.md as its user
# memory and codex reads a global AGENTS.md under CODEX_HOME; the content is
# identical, so the repo keeps one copy. cursor-agent gets no line here -- its
# equivalent is account-side User Rules, not a file, which is a manual step in
# README.md.
link agents/global.md "$HOME/.claude/CLAUDE.md"
link agents/global.md "$HOME/.codex/AGENTS.md"


##-----------------------------------------------
#  Machine local files (never committed)
##-----------------------------------------------

touch "$HOME/.zshenv.local" "$HOME/.vimrc.local"

if [ ! -e "$HOME/.gitconfig.local" ]; then
    cat > "$HOME/.gitconfig.local" <<'TEMPLATE'
# Personal identity -- the default for every repository, and the only place the
# work directories are named. Uncomment one includeIf per work directory; they
# live here rather than in the tracked .gitconfig because that repo is public.
[user]
    name = CHANGE_ME
    email = CHANGE_ME

# [includeIf "gitdir:~/CHANGE_ME/"]
#     path = ~/.gitconfig.work
TEMPLATE
    warn "fill in ~/.gitconfig.local (personal name and email, and an includeIf per work directory)"
fi

if [ ! -e "$HOME/.gitconfig.work" ]; then
    cat > "$HOME/.gitconfig.work" <<'TEMPLATE'
# Work identity -- applied under the includeIf directories in ~/.gitconfig.local.
[user]
    name = CHANGE_ME
    email = CHANGE_ME
TEMPLATE
    warn "fill in ~/.gitconfig.work (work name and email)"
fi


##-----------------------------------------------
#  Tool versions
##-----------------------------------------------

info "installing Node, Ruby and Terraform via mise"
mise install

# `gem install` always fetches the current release, so calling it unguarded
# would upgrade CocoaPods on every re-run -- the opposite of the --no-upgrade
# rule the Brewfile step follows. Install it when missing, leave it otherwise.
if mise exec ruby -- gem list -i cocoapods > /dev/null 2>&1; then
    info "CocoaPods already installed"
else
    info "installing CocoaPods (needed for iOS and Flutter builds)"
    mise exec ruby -- gem install cocoapods
fi


##-----------------------------------------------
#  AI CLIs that Homebrew does not carry
#
#  These installers always fetch the current release; there is no way to pin a
#  version through them. codex comes from the Brewfile instead.
##-----------------------------------------------

if ! command -v claude > /dev/null; then
    info "installing claude"
    curl -fsSL https://claude.ai/install.sh | bash
fi

if ! command -v cursor-agent > /dev/null; then
    info "installing cursor-agent"
    curl -fsS https://cursor.com/install | bash
fi


##-----------------------------------------------
#  claude's settings, merged rather than linked
#
#  ~/.claude/settings.json cannot be a symlink into this repo: claude rewrites
#  it itself, and most of what ends up there is either machine state or work
#  identity that a public repository must not carry. So the repo tracks only the
#  decisions -- claude/settings.base.json -- and this merges them in, leaving
#  every key it does not name untouched. CLAUDE.md argues the split in full.
#
#  There is no user-level overlay to do this with instead. claude reads exactly
#  five settings sources, and the only per-user one is this file; the
#  settings.local.json name is project-scoped, resolved against the cwd or git
#  root, never against $HOME.
##-----------------------------------------------

claude_settings="$HOME/.claude/settings.json"
claude_base="$DOTFILES/claude/settings.base.json"

if ! command -v jq > /dev/null; then
    warn "skipped claude settings (jq is missing; it is in the Brewfile)"
elif [ ! -e "$claude_base" ]; then
    warn "skip claude/settings.base.json (not in repo)"
else
    if [ ! -e "$claude_settings" ]; then
        mkdir -p "$(dirname "$claude_settings")"
        printf '{}\n' > "$claude_settings"
        chmod 600 "$claude_settings"
    fi

    # `*` is jq's recursive merge, so permissions.defaultMode lands beside the
    # permissions.allow entries claude wrote rather than replacing the whole
    # object. The base is the right operand, which makes the repo win for the
    # keys it names and lose everywhere else.
    #
    # Merging into a variable first means a syntax error in the live file costs
    # nothing: without it, the redirect below would truncate the file before jq
    # ever failed.
    if claude_merged=$(jq -s '.[0] * .[1]' "$claude_settings" "$claude_base"); then
        if [ "$claude_merged" = "$(cat "$claude_settings")" ]; then
            info "claude settings already match the base"
        else
            # Truncated in place rather than moved over from a temp file: this
            # file is 0600 because it holds credentials and per-directory trust
            # levels, and a fresh temp file would arrive at the umask instead.
            printf '%s\n' "$claude_merged" > "$claude_settings"
            info "merged claude/settings.base.json into .claude/settings.json"
        fi
    else
        warn "skipped claude settings (invalid JSON in ${claude_settings#"$HOME"/})"
    fi
fi


##-----------------------------------------------
#  Agent skills
#
#  Two upstream sources, one `skills add` each. claude/skill-lock.json is the
#  tracked record of which skills were installed and at which commit, but
#  `skills add` only ever fetches current -- the same situation as claude and
#  cursor-agent above -- so the lockfile is a manifest to read, not a version
#  this can pin to.
#
#  Each step is guarded by a skill only that source provides, so the two are
#  independent: neither ordering nor a half-finished earlier run can make one
#  of them silently skip. Guarding on ~/.agents/skills itself cannot do that,
#  because the first source to install creates it for everyone.
#
#  The two skills in neither lockfile are authored in this repository and are
#  symlinked into place by the link lines further up instead.
##-----------------------------------------------

# Both go through `mise exec node`, like the CocoaPods step above: node comes
# from mise, and its shims reach PATH through `mise activate` in .zshrc, which
# this script never runs. A bare npx works on a machine that already has one and
# aborts the rest of this script on a fresh one.
#
# --all is `--skill '*' --agent '*' -y`: every skill in the repository, exposed
# to every agent on the machine.
if [ -d "$HOME/.agents/skills/setup-matt-pocock-skills" ]; then
    info "mattpocock skills already installed"
else
    info "installing agent skills from mattpocock/skills"
    mise exec node -- npx -y skills add mattpocock/skills --global --all
fi

# herdr ships the skill that teaches an agent to drive the multiplexer it is
# running inside. One skill out of that repository, every agent on the machine.
# Claude Code gets a symlink under ~/.claude/skills; codex and cursor-agent
# read ~/.agents/skills directly.
if [ -d "$HOME/.agents/skills/herdr" ]; then
    info "herdr skill already installed"
else
    info "installing the herdr skill from herdrdev/herdr"
    mise exec node -- npx -y skills add herdrdev/herdr --skill herdr --agent '*' --global -y
fi


##-----------------------------------------------
#  herdr integrations
#
#  The skill above is one direction -- the agent driving herdr. These are the
#  other -- herdr reading the agent, so the sidebar can say which one is
#  working, blocked or done instead of guessing from the screen.
#
#  Each is a SessionStart hook herdr writes and owns, registered in a file this
#  repository deliberately does not track: ~/.claude/settings.json,
#  ~/.codex/hooks.json, ~/.cursor/hooks.json.
#
#  Installing is skipped when `status` already says `current`, and that guard is
#  load-bearing rather than a speed-up. codex will not run a hook it has not
#  been shown: it holds a new one at a review prompt on the next launch, and
#  rewriting the script is what makes it new again. An unguarded re-install
#  would silently un-trust codex's hook every time this script ran. Giving that
#  confirmation is in the manual list below, because only a human can.
##-----------------------------------------------

if command -v herdr > /dev/null; then
    # Read once rather than per target. Piping into `grep -q` closes the pipe at
    # the matching line, herdr dies writing the rest, and pipefail turns that
    # into a miss -- so a current integration reinstalls itself, which is the one
    # thing this guard exists to prevent.
    herdr_integrations=$(herdr integration status)
    for target in claude codex cursor; do
        if grep -q "^$target: current" <<< "$herdr_integrations"; then
            info "herdr integration already current: $target"
        else
            info "installing herdr integration: $target"
            herdr integration install "$target" > /dev/null
        fi
    done
fi


##-----------------------------------------------
#  What is left for a human
##-----------------------------------------------

# Unquoted heredoc: $DOTFILES is filled in below so the status line command can
# be pasted as printed. Neither claude nor cursor-agent expands ~ in an
# argument, which is why the path has to be spelled out. The backtick in the
# Ghostty step is escaped for the same reason the quotes came off.
cat <<MANUAL

==> Done. These cannot be automated:

    1. gh auth login
    2. claude          -- and sign in
    3. codex           -- and sign in
    4. cursor-agent login
    5. Point claude, cursor-agent and codex at the status line. Their config
       files are rewritten by the tools themselves, so this script writes
       nothing into them beyond the claude settings it merged above;
       README.md has the three snippets. The command to paste, with this
       machine's path already filled in:

           /usr/bin/python3 $DOTFILES/bin/statusline.py

    6. Start codex once and trust its SessionStart hook. codex holds every
       newly installed hook at a review prompt, so herdr's agent-state
       integration stays inert until a human presses t there. claude and
       cursor-agent need no equivalent step.
    7. Put your SSH keys in ~/.ssh and add the public key to GitHub
    8. Fill in ~/.gitconfig.local and ~/.gitconfig.work if setup created them
    9. Open Ghostty once, then allow it under
       System Settings > Privacy & Security > Accessibility
       so that cmd+\` can summon the quick terminal from any app
   10. Restart your shell (or open a new Ghostty window)

MANUAL
