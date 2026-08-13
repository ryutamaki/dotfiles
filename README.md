dotfiles
========

Terminal is Ghostty. Editing is mostly done through AI CLIs (`claude`,
`codex`, `cursor-agent`) rather than a GUI editor. Everything here follows
from those two facts.

## Setup

```sh
git clone https://github.com/ryutamaki/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./bin/setup.sh
```

That installs Homebrew and everything in `Brewfile`, links the config files,
installs Node / Ruby / Terraform through mise, and installs the AI CLIs that
Homebrew does not carry. It is safe to re-run: correct symlinks are left
alone, and anything real that is in the way is moved to
`~/dotfiles_old/<timestamp>/`.

Package versions are not upgraded by `setup.sh`. Upgrading is deliberate:

```sh
brew bundle upgrade --file=Brewfile
```

## After setup

These cannot be automated:

- [ ] `gh auth login`
- [ ] `claude` — and sign in
- [ ] `codex` — and sign in
- [ ] `cursor-agent login`
- [ ] SSH keys into `~/.ssh`, public key added to GitHub
- [ ] Fill in `~/.gitconfig.local` (personal) and `~/.gitconfig.work` (work) if
      `setup.sh` created them from the template
- [ ] Open Ghostty once, then allow it under **System Settings › Privacy &
      Security › Accessibility** so <kbd>cmd</kbd>+<kbd>`</kbd> can summon the
      quick terminal from any app
- [ ] Restart the shell

## What lives where

| Path | |
|---|---|
| `config/ghostty/config` | **The only place colors are defined.** Change the theme here and everything else follows |
| `config/mise/config.toml` | Global Node / Ruby / Terraform versions |
| `config/git/ignore` | Global gitignore. Symlinked to `~/.config/git/ignore`, which git reads by default |
| `.zsh/path.zsh` | **The only place PATH is defined.** Sourced from both `.zshenv` and `.zprofile` |
| `.zsh/plugins.zsh` | zsh plugins, all installed by `brew bundle` |
| `Brewfile` | Everything installed on a fresh machine |
| `CLAUDE.md` | The rules an AI should not break when editing this repo |

Machine-local files are never committed: `~/.zshenv.local`,
`~/.vimrc.local`, `~/.gitconfig.local`, `~/.gitconfig.work`.

## Deliberately not here

- **tmux / screen** — Ghostty owns splits and tabs
- **A vim plugin manager** — vim is for commit messages and quick edits
- **A zsh plugin manager** — `brew bundle` already is one
- **Flutter** — its SDK is a git clone at `~/Development/flutter`, which is how
  Flutter expects to be managed
- **`~/.claude`** — not tracked yet
