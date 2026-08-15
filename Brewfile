# Install with: brew bundle --file=Brewfile
#
# Anything listed here is what a fresh machine gets. If a tool is not here,
# it is not part of the environment -- add it deliberately, not by habit.

## Terminal (the single source of colors -- see config/ghostty/config)
cask "ghostty"

# The multiplexer the agents run inside. Its own installer
# (herdr.dev/install.sh) only ever fetches current, the same trap claude and
# cursor-agent are in below -- Homebrew carries it, so it is pinnable and it
# belongs here instead. Configured in config/herdr/config.toml.
brew "herdr"

## AI CLIs
# claude and cursor-agent ship their own installers and are handled by
# bin/setup.sh -- Homebrew has no formula for them.
cask "codex"

## Version manager (Node / Ruby / Terraform)
brew "mise"

## Git
brew "gh"
brew "tig"
brew "git-delta"

## Search / files
brew "fzf"
brew "ripgrep"
brew "fd"
brew "tree"

## zsh
# starship is the prompt. It replaced a hand-written PROMPT plus vcs_info, and
# unlike the AI CLIs above it is pinnable, so it belongs here rather than in an
# installer. Configured in config/starship.toml.
brew "starship"
brew "z"
brew "zsh-completions"
brew "zsh-syntax-highlighting"
brew "zsh-autosuggestions"

## AWS / infra
brew "saml2aws"
brew "aws-sam-cli"
brew "sshuttle"

## Misc
brew "jq"
brew "mysql-client"
brew "ffmpeg"
brew "rclone"
brew "libomp"
