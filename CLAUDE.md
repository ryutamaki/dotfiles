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

That line names two themes — `light:GitHub Light High Contrast,dark:GitHub
Dark High Contrast` — and Ghostty picks between them from the macOS
appearance, live. A tool that only ever writes ANSI color numbers needs no
light/dark notion at all, which is most of the list above. The two that do
have one ask the terminal for its background rather than being told: vim
queries with `t_RB` and sets `background` from the answer, git-delta queries
with OSC 10/11 and picks its diff colors. Both stop asking the moment the
answer is hardcoded — `set background=dark` in the vimrc or `light`/`dark` in
`[delta]` — so leave those unset.

Both halves are picked for legibility, not looks, and a replacement is checked
the same way — the config file records the measurements and the floor. The
constraint that rules most light themes out is that they carry their dark
sibling's bright ANSI row, which is unreadable on a light background. Fix that
by choosing a better theme, never with `minimum-contrast` or `faint-opacity`:
those clamp toward black or white and take the green out of a diff.

Claude Code is the exception, and it is not fixable here. `"theme": "auto"` is
accepted but in a terminal it resolves through `$COLORFGBG`, which Ghostty does
not set, so it lands on plain `dark` and loses the ANSI-only palette. There is
no `auto-ansi`. `dark-ansi` stays pinned; in light mode its text still comes
from the terminal, and `/config` flips it by hand.

**PATH lives only in `.zsh/path.zsh`.** It is sourced twice on purpose:
`.zshenv` covers scripts and AI agents, and `.zprofile` sources it again
because macOS `/etc/zprofile` runs `path_helper` and pushes the system
directories back to the front. When an installer appends `export PATH=...` to
`.zprofile` or `.zshrc`, move that entry into `.zsh/path.zsh`. `typeset -U
path PATH` needs both names — with `path` alone the deduplication does not
survive string assignment.

## One status line, three CLIs

`bin/statusline.py` prints the same three lines -- usage, terminal, git -- for
both `claude` and `cursor-agent`. Both spawn a `statusLine` command and hand it
a JSON snapshot on stdin, and the two payloads differ only in what they carry:
`rate_limits` is Claude Code's, `model.param_summary` is cursor-agent's. Each
segment is skipped when its key is missing, which is why one file serves both.
Do not fork it per tool.

`codex` has no command hook. Its status line is a fixed set of built-in items
picked in `[tui] status_line` of `~/.codex/config.toml` (`/statusline` edits
the same list). Keep that list pointing at the facts the script prints; an item
codex does not recognise is dropped with a notice rather than failing.

The script writes only the 16 ANSI colors, and codex runs with
`status_line_use_colors = false` so its line stays the terminal foreground.
Both are the colour invariant above, not a style choice.

The three config files it is wired into -- `~/.claude/settings.json`,
`~/.cursor/cli-config.json`, `~/.codex/config.toml` -- are neither tracked nor
symlinked. Each tool rewrites its own file, and each holds credentials or
per-directory trust levels that do not belong in a public repo. `setup.sh`
leaves them alone; wiring them up is a manual step in README.md.

## Two agent skills are written here, the rest are installed

`~/.agents/skills` is where the installed skills live, and it is not a git
repository. Nearly all of them come from a single upstream repository, so
`setup.sh` restores them with one `skills add` and nothing more is needed here
than `claude/skill-lock.json` as the record of what was installed and when.
That installer only fetches current, which puts skills in the same category as
`claude` and `cursor-agent`: reproducible, not pinnable.

`claude/skills/cleanup` and `claude/skills/audit-memory` are the exceptions.
Both are authored, both are absent from that lockfile, and until they were
tracked they existed on exactly one disk. They are symlinked into
`~/.claude/skills` like everything else here.

Anything written rather than installed belongs in this repository for the same
reason. The test is whether `skills add` could produce it again.

## LANG is set, LC_ALL is not

`.zshenv` exports `LANG` and stops there. `LC_ALL` outranks every other locale
variable, including a one-off `LANG=... command` prefix, so exporting it turns
those prefixes into no-ops. That is not hypothetical: the
`LANG=en_US.UTF-8 vcs_info` in `.zsh/zshrc` sat there doing nothing for as long
as `LC_ALL` was set beside `LANG`.

Adding `export LC_ALL=$LANG` back looks harmless and silently breaks it again.
When one command needs a different locale, prefix that command.

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
