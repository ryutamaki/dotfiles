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


##-----------------------------------------------
#  Machine local files (never committed)
##-----------------------------------------------

touch "$HOME/.zshenv.local" "$HOME/.vimrc.local"

if [ ! -e "$HOME/.gitconfig.local" ]; then
    cat > "$HOME/.gitconfig.local" <<'TEMPLATE'
# Personal identity -- the default for every repository.
[user]
    name = CHANGE_ME
    email = CHANGE_ME
TEMPLATE
    warn "fill in ~/.gitconfig.local (personal name and email)"
fi

if [ ! -e "$HOME/.gitconfig.work" ]; then
    cat > "$HOME/.gitconfig.work" <<'TEMPLATE'
# Work identity -- applied under the includeIf directories in ~/.gitconfig.
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
       files are rewritten by the tools themselves, so this script does not
       edit them; README.md has the three snippets. The command to paste,
       with this machine's path already filled in:

           /usr/bin/python3 $DOTFILES/bin/statusline.py

    6. Put your SSH keys in ~/.ssh and add the public key to GitHub
    7. Fill in ~/.gitconfig.local and ~/.gitconfig.work if setup created them
    8. Open Ghostty once, then allow it under
       System Settings > Privacy & Security > Accessibility
       so that cmd+\` can summon the quick terminal from any app
    9. Restart your shell (or open a new Ghostty window)

MANUAL
