# Working in this repo

Every tracked file here is symlinked into `$HOME`. An edit changes the live
shell, terminal and git config immediately — there is no build step and no
apply step. Verify a shell change by starting a fresh shell with a real
terminal attached:

```sh
script -q /dev/null zsh -l -i -c 'exit'
```

`zsh -i -c` has no tty and reports failures that never happen in Ghostty.

## Two single sources

These two invariants are the point of the current layout. Keep each one true.

**Colors live only in `config/ghostty/config`.** Everything that draws in the
terminal reads the theme's 16 ANSI colors from there: Claude Code through
`"theme": "dark-ansi"`, vim by having no colorscheme and no `t_Co`, git-delta
through `syntax-theme = none`, and fzf and tig by setting no color options.
Restyle the whole environment by editing the `theme` line. When something new
needs colors, point it at the terminal palette the same way.

**PATH lives only in `.zsh/path.zsh`.** It is sourced twice on purpose:
`.zshenv` covers scripts and AI agents, and `.zprofile` sources it again
because macOS `/etc/zprofile` runs `path_helper` and pushes the system
directories back to the front. When an installer appends `export PATH=...` to
`.zprofile` or `.zshrc`, move that entry into `.zsh/path.zsh`. `typeset -U
path PATH` needs both names — with `path` alone the deduplication does not
survive string assignment.

## Absent on purpose

Adding any of these undoes a decision rather than filling a gap:

- **tmux and screen** — Ghostty owns splits and tabs.
- **A vim plugin manager** — vim is for commit messages and quick edits.
- **A zsh plugin manager** — `brew bundle` fills that role; plugins are
  Homebrew packages sourced by `.zsh/plugins.zsh`.
- **Flutter under mise** — its SDK is a git clone at `~/Development/flutter`,
  which is how Flutter expects to be managed.
- **A pinned version for `claude` and `cursor-agent`** — their installers only
  fetch current. Everything pinnable goes in `Brewfile` or
  `config/mise/config.toml`.

## Terraform stays at 1.5.7

Raising it rewrites terraform state in a way that cannot be undone, and nine
`.tf` files depend on it. Treat a bump as its own piece of work with its own
verification, never as a side effect of touching `config/mise/config.toml`.

## setup.sh stays re-runnable

`bin/setup.sh` runs on a working machine as often as on a fresh one, so every
step tolerates already being done: correct symlinks are left alone, real files
in the way move to `~/dotfiles_old/<timestamp>/`, and `brew bundle install`
passes `--no-upgrade` so upgrading stays a deliberate separate command. Keep
new steps to that standard.

## Identity

This repository is public, so it carries neither an address nor the name of
any directory an address applies to. `.gitconfig` includes
`~/.gitconfig.local` and stops there. That untracked file holds the personal
identity as the default and its own `includeIf` lines pointing work
directories at `~/.gitconfig.work`.

Personal-as-default is the safe direction: a missed work directory means a
personal address on a work repo rather than a work address in a public one.
Keep new identity rules in `~/.gitconfig.local` — adding an `includeIf` here
would publish the directory name.

`~/.zshenv.local`, `~/.vimrc.local`, `~/.gitconfig.local` and
`~/.gitconfig.work` are machine-local and stay untracked.
