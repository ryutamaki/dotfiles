dotfiles
========

Terminal is Ghostty. Editing is mostly done through AI CLIs (`claude`,
`codex`, `cursor-agent`) rather than a GUI editor, and those run inside
`herdr`, which keeps their panes alive and shows what every one of them is
doing. Everything here follows from those facts.

## Setup

```sh
git clone https://github.com/ryutamaki/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./bin/setup.sh
```

That installs Homebrew and everything in `Brewfile`, links the config files,
installs Node / Ruby / Terraform through mise, installs the AI CLIs that
Homebrew does not carry, and wires the agents and herdr to each other — the
skills the agents use, and the hooks herdr reads their state from. It is safe
to re-run: correct symlinks are left alone, and anything real that is in the
way is moved to `~/dotfiles_old/<timestamp>/`.

Package versions are not upgraded by `setup.sh`. Upgrading is deliberate:

```sh
brew bundle upgrade --file=Brewfile
```

If that upgrades `herdr`, restart its server before trusting the `herdr` CLI
again — the old server keeps running and a newer client refuses to talk to it,
so every command fails with `protocol_mismatch`. `herdr status` shows
`restart_needed: yes`. Run this from a plain Ghostty tab, not from inside
herdr, because stopping exits every pane process:

```sh
HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock" herdr server stop
herdr
```

Panes come back with their agents resumed, thanks to the integrations.
Scrollback does not.

## After setup

These cannot be automated:

- [ ] `gh auth login`
- [ ] `claude` — and sign in
- [ ] `codex` — and sign in
- [ ] `cursor-agent login`
- [ ] SSH keys into `~/.ssh`, public key added to GitHub
- [ ] Fill in `~/.gitconfig.local` (personal) and `~/.gitconfig.work` (work) if
      `setup.sh` created them from the template, and uncomment one `includeIf`
      in `~/.gitconfig.local` per work directory — nothing else points at
      `~/.gitconfig.work`
- [ ] Open Ghostty once, then allow it under **System Settings › Privacy &
      Security › Accessibility** so <kbd>cmd</kbd>+<kbd>`</kbd> can summon the
      quick terminal from any app
- [ ] Open Raycast once and give it <kbd>cmd</kbd>+<kbd>space</kbd> as its
      hotkey. Spotlight owns that shortcut on a fresh machine, and Raycast
      offers to take it off Spotlight when you press it — accept. Nothing here
      can do this step: Raycast's preferences are its own file, rewritten by
      the app and carrying account state, so the repo tracks only the
      `Brewfile` line. Declining is not a middle ground: the system shortcut
      wins, so Raycast's hotkey never fires at all
- [ ] Point the AI CLIs at `bin/statusline.py`. Their config files are not
      tracked (see below), so this is per machine. `setup.sh` prints the
      command with this machine's path already filled in:

      ```jsonc
      // ~/.claude/settings.json and ~/.cursor/cli-config.json.
      // Spell the path out: neither tool expands ~ in an argument.
      "statusLine": {
        "type": "command",
        "command": "/usr/bin/python3 /Users/YOU/dotfiles/bin/statusline.py",
        "padding": 1
      }
      ```

      ```toml
      # ~/.codex/config.toml -- codex has no command hook, so it gets the
      # nearest built-in items instead. `/statusline` edits the same list.
      # No five-hour-limit: that window does not exist on this plan, and the
      # item is simply omitted when its data is unavailable.
      [tui]
      status_line = [
          "model-with-reasoning", "context-used", "weekly-limit",
          "current-dir", "git-branch", "pull-request-number",
      ]
      status_line_use_colors = false
      ```

- [ ] Paste `agents/global.md` into cursor-agent's **User Rules**, in the Cursor
      app under Settings › Rules. `setup.sh` links that file to
      `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, but cursor-agent has no
      equivalent on disk — its global layer arrives in the server response, so
      it is account-side and cannot be symlinked. Re-paste it when that file
      changes

- [ ] Start `codex` once and press <kbd>t</kbd> at its hook review prompt.
      codex holds every newly installed hook until a human trusts it, so
      herdr's agent-state integration reports nothing until then. `claude` and
      `cursor-agent` need no equivalent step

- [ ] Create the space the plan budgets are drawn in, and drag it to the top of
      the sidebar:

      ```sh
      herdr workspace create --label usage --cwd "$HOME" --no-focus
      ```

      `bin/statusline.py` pushes how much of claude's, codex's and cursor's
      plans has been spent to a space with exactly that label, and pushes
      nothing when there is none. herdr owns the sidebar's order, so the
      position is a drag rather than a setting

- [ ] Restart the shell

## Agents in herdr

Run `herdr` in a project, start `claude` / `codex` / `cursor-agent` in a pane,
and split for more. Panes keep running when the window closes; `herdr` reattaches
to them. The sidebar shows every agent across every project and whether it is
working, blocked or done. Mouse works everywhere; <kbd>ctrl</kbd>+<kbd>t</kbd>
then <kbd>?</kbd> lists the keys.

The prefix is <kbd>ctrl</kbd>+<kbd>t</kbd> rather than herdr's own
<kbd>ctrl</kbd>+<kbd>b</kbd>, because <kbd>ctrl</kbd>+<kbd>b</kbd> is emacs'
backward-char and gets pressed far more often than any pane command.
<kbd>|</kbd> and <kbd>-</kbd> split, as they did under tmux. That takes
<kbd>ctrl</kbd>+<kbd>t</kbd> away from fzf inside a pane, so its file widget
moved to <kbd>ctrl</kbd>+<kbd>o</kbd>.

Those agents can also drive herdr back. `setup.sh` installs the `herdr` skill
into all three, so an agent that is asked to can split a pane, run a build
beside itself without taking focus, read what came out, and wait for another
agent to finish — through the same `herdr` CLI, which answers in JSON. The
skill will not spawn panes on its own.

There is one exception, and it is the reason `agents/global.md` exists: a dev
server or watcher goes in its own pane without being asked, so its log is
visible to a human rather than held in the agent's background.

```sh
herdr agent list      # what every agent is doing, as JSON
herdr status          # client and server
```

## What lives where

| Path | |
|---|---|
| `config/ghostty/config` | **The only place colors are defined.** Change the theme here and everything else follows |
| `config/herdr/config.toml` | The multiplexer the agents run in. Carries Catppuccin — the one deliberate exception to the line above, argued in the file |
| `agents/global.md` | What every agent reads in every project. Symlinked to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` |
| `config/starship.toml` | The shell prompt. A whitelist: any module it does not name is off, and every one it names states an ANSI color |
| `config/mise/config.toml` | Global Node / Ruby / Terraform versions |
| `config/git/ignore` | Global gitignore. Symlinked to `~/.config/git/ignore`, which git reads by default |
| `.zsh/path.zsh` | **The only place PATH is defined.** Sourced from both `.zshenv` and `.zprofile` |
| `.zsh/plugins.zsh` | zsh plugins, all installed by `brew bundle` |
| `claude/skills/` | The agent skills written here rather than installed. Symlinked into `~/.claude/skills` |
| `claude/skill-lock.json` | Record of the installed skills `setup.sh` restores from upstream |
| `bin/statusline.py` | The status line `claude` and `cursor-agent` both draw. `codex` gets the nearest built-in items |
| `Brewfile` | Everything installed on a fresh machine |
| `CLAUDE.md` | The rules an AI should not break when editing this repo |

Machine-local files are never committed: `~/.zshenv.local`,
`~/.vimrc.local`, `~/.gitconfig.local`, `~/.gitconfig.work`.

## Deliberately not here

- **tmux / screen** — `herdr` is the multiplexer, and it knows which agent is
  working, blocked or done. Ghostty still owns the window
- **A vim plugin manager** — vim is for commit messages and quick edits
- **A zsh plugin manager** — `brew bundle` already is one
- **Flutter** — its SDK is a git clone at `~/Development/flutter`, which is how
  Flutter expects to be managed
- **The AI CLIs' config files** — `~/.claude/settings.json`,
  `~/.cursor/cli-config.json` and `~/.codex/config.toml` each get rewritten by
  their own tool and each holds credentials or per-directory trust levels.
  Only `bin/statusline.py` is tracked; wiring it in is a manual step above.
  `claude/settings.base.json` is the one exception, and it is a merge rather
  than a link: it carries the handful of settings that are decisions rather
  than machine state, and `setup.sh` merges them into `~/.claude/settings.json`
  without touching any other key
- **The herdr agent-state hooks** — `~/.claude/settings.json`,
  `~/.codex/hooks.json` and `~/.cursor/hooks.json`. herdr writes and owns those
  scripts; `setup.sh` calls `herdr integration install` rather than tracking a
  copy that would go stale on the next herdr release
