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

**Colors live only in `config/ghostty/config`, for everything that draws inside
a pane.** Those all read the theme's 16 ANSI colors from there: Claude Code
through `"theme": "dark-ansi"` or `"light-ansi"`, vim by having no colorscheme and
no `t_Co`, git-delta through `syntax-theme = none`, starship by naming ANSI
colors and nothing else, and fzf and tig by setting no color options. Restyle
all of them by editing the `theme` line. When something new needs colors, point
it at the terminal palette the same way.

starship is the one on that list that has to be held to it by hand, because it
is the only one shipping a palette of its own. 14 of its 109 modules default to
a color this file cannot reach — `terraform` is `bold 105`, `package` is
`208 bold`, `gleam` is a hex — so `config/starship.toml` states a style for
every module it enables and enables modules by name. Its own header carries the
rule; the thing to know from here is that `starship preset` writes hex and must
never be run against that file.

herdr's own chrome — sidebar, tab bar, borders, overlays — is the one exception,
and it is a decision rather than an oversight. It carries Catppuccin;
`config/herdr/config.toml` argues it in full, and the short version is that
sixteen ANSI slots offer no color meant to be a background and no yellow that is
both readable on white and recognisable as yellow, and herdr's sidebar needs
both. Pane *contents* still come from Ghostty, so nothing in the list above
changes.

That line names two themes — `light:GitHub Light High Contrast,dark:GitHub
Dark High Contrast` — and Ghostty picks between them from the macOS
appearance, live. A tool that only ever writes ANSI color numbers needs no
light/dark notion at all, which is most of the list above. The two that do
have one ask the terminal for its background rather than being told: vim
queries with `t_RB` and sets `background` from the answer, git-delta queries
with OSC 10/11 and picks its diff colors. Both stop asking the moment the
answer is hardcoded — `set background=dark` in the vimrc or `light`/`dark` in
`[delta]` — so leave those unset.

herdr is where that switching stops being free, which is the price of the
exception above. `[theme] auto_switch` sounds like following the terminal and is
not: it makes herdr swap between two of its *own* themes on an appearance change.
Under `name = "terminal"` there was nothing to swap and it was left off. Under a
named theme it is mandatory, because `panel_bg` follows the terminal background
while `surface0` and `surface1` come from the theme — pin one half and a light
fill lands on a dark panel, which measured 2.0:1 for the text inside it. So it is
on, with `light_name = "catppuccin-latte"` and `dark_name = "catppuccin"`, and
Ghostty does report the appearance for herdr to follow. There is no
`[theme.custom]` block; overriding a token there would hardcode a color outside
both sources.

Both halves are picked for legibility, not looks, and a replacement is checked
the same way — the config file records the measurements and the floor. The
constraint that rules most light themes out is that they carry their dark
sibling's bright ANSI row, which is unreadable on a light background. Fix that
by choosing a better theme, never with `minimum-contrast` or `faint-opacity`:
those clamp toward black or white and take the green out of a diff.

There is one contrast problem a better theme cannot fix, and it is worth knowing
before reaching for the theme line. Every floor recorded in that file measures a
slot **against the background**, because until herdr nothing here painted a slot
**as** a background. A tool that fills a panel with ANSI 8 and draws text on it
needs slot 8 to work as a background too, and no theme Ghostty ships clears both
at once. So the fix never lives in the theme line. herdr's was to stop drawing
from this palette at all, which is the exception above.

Claude Code is where it stays unfixed, and it is not fixable here. There is no
`auto-ansi` — `"theme": "auto"` resolves through `$COLORFGBG`, which Ghostty does
not set — so the theme is whichever half was set last and `/config` flips it by
hand. That flip is not cosmetic: Claude Code draws the user's own message as a
filled block, so the wrong half puts sub-3:1 text inside it while everything
outside the block still reads fine, which is what makes it look survivable. The
light half has a right answer and the dark half has none. Both sets of numbers,
and the dark themes that would close the gap, are recorded in
`config/ghostty/config`. Replacing the dark half is its own piece of work with
its own verification, `split-divider-color` included, never a side effect of
something else.

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

The same script also draws how much of all three plans has been spent as one
block in herdr's sidebar, which is a second job rather than a second file for
the same reason the first one is shared: the data is already in its hands. A
status line is only legible in the pane drawing it, so comparing three budgets
meant visiting three panes.

The block hangs off a workspace labelled `usage` rather than off the agents,
and that placement is the decision worth keeping. herdr has no global status
bar; `[ui.sidebar.agents]` and `[ui.sidebar.spaces]` are the only two surfaces
that render custom text, and a budget is an account-wide fact, so putting it on
the agent rows printed the same percentage once per pane — six identical lines
with six claude panes open. A space of its own says it once. The rows are named
globally in `[ui.sidebar.spaces]` and stay empty on every other space, so
deleting the `usage` space is the whole uninstall.

Only claude's number arrives on its own, in the payload. So whichever pane is
drawing writes the entire block, not just its own line, and claude's numbers
are cached on the way past for the cursor-agent panes that never see them. That
is the one real cost of not adding a daemon, and it is why the push carries a
`ttl_ms`: leave the machine for ten minutes and the block empties rather than
showing percentages from an hour ago.

Both bars fill with what is **spent**, and that is worth keeping true. The
sidebar's carries a `░` track and the status line's does not, because a sidebar
row has no label beside it to say where a full bar would end — but the
direction is the same in both, so the same window never reads two different
numbers in two places. A bar that drained instead was tried and reverted for
exactly that reason.

The three sources are not equally cheap, and cursor's is the one to think twice
about before extending. claude's arrives on stdin. codex's is a file read —
`rate_limits` sits in every `token_count` event of the newest rollout under
`~/.codex/sessions`. cursor has neither, so it is asked over the network:
`GetCurrentPeriodUsage` on `aiserver.v1` at `api2.cursor.sh`, with the
`cursor-access-token` keychain item as a bearer. That reply carries both
`totalPercentUsed` and `billingCycleEnd`, which is why only one of the three
calls behind the TUI's `/usage` is made here.

Undocumented protobuf reached with a borrowed token will break without notice,
so it is boxed in rather than trusted: a five-minute disk cache, a two-second
timeout, only the two numbers written to that cache — never the spend figures
the reply also carries — and one failed request never discarding the number
before it, so a blip costs nothing and a real outage costs the row rather than
the truth.

The three config files it is wired into -- `~/.claude/settings.json`,
`~/.cursor/cli-config.json`, `~/.codex/config.toml` -- are neither tracked nor
symlinked. Each tool rewrites its own file, and each holds credentials or
per-directory trust levels that do not belong in a public repo. Wiring the
status line into them is a manual step in README.md. `setup.sh` writes nothing
into two of them; the exception for claude is the section below, and it stays
clear of the status line.

## claude's settings are merged, not linked

`claude/settings.base.json` holds the settings that are *decisions* -- things
that should survive a new machine. `setup.sh` merges it into
`~/.claude/settings.json` with `jq`'s recursive `*`, base on the right, so the
repo wins for the keys it names and every other key is left exactly as claude
left it. The merge is a no-op when nothing differs, which is what keeps
`setup.sh` re-runnable.

The test for whether a key belongs in that file is whether a fresh machine
would be wrong without it. `theme`, `model`, `effortLevel`, `tui`,
`autoCompactEnabled`, `autoCompactWindow`, `skillOverrides` and
`permissions.defaultMode` pass it. Machine state does not -- the
`skip*Prompt` keys record that a dialog was accepted, `statusLine` and `hooks`
carry absolute paths and are owned by README.md and by `herdr integration
install` respectively.

**It is a merge and not a symlink for two independent reasons, either of which
alone would settle it.** claude rewrites this file itself -- `/config`,
`/model`, `/effort`, `/autocompact`, "always allow" on a permission prompt and
every plugin install write `userSettings` -- so a link would mean a tool
committing to a public repository unattended. And the file's own contents
cannot be published: `autoMode.environment` carries the employer name, a client
name, project directory names, and an explicit list of where the `.env` and
`terraform.tfvars` / `terraform.tfstate` files sit, which is a map of where the
credentials are. `permissions.additionalDirectories`
and `permissions.allow` carry work paths and an AWS app id. That is the
Identity rule at the end of this file, and it is why the base file is a
whitelist: it names what goes in, so nothing arrives by being forgotten.

The `.gitconfig` / `.gitconfig.local` split cannot be copied here, which is
worth knowing before reaching for it a second time. Measured against claude
2.1.233: there are exactly five settings sources -- `policySettings`,
`userSettings` (`~/.claude/settings.json`), `projectSettings`
(`<root>/.claude/settings.json`), `localSettings`
(`<root>/.claude/settings.local.json`), `flagSettings` (`--settings`) -- and
`localSettings` resolves against the cwd or git root, never against `$HOME`. So
`~/.claude/settings.local.json` is not a user-level overlay; it is the
*project*-local file for the home directory, inert unless claude is started
with `$HOME` as the cwd. There is no `include` directive either, so the
harmless half cannot pull in the machine-local half from inside. The merge is
the inverse of a link, and it is the only shape left.

What it costs is that changes do not flow back. Flipping the theme with
`/config` edits the live file, and the next `setup.sh` run puts
`claude/settings.base.json` back. That is the theme half of the invariant at
the top of this file meeting the one setting a human is expected to flip by
hand, so it is a real collision rather than a hypothetical -- but `setup.sh` is
run rarely and the light half is the one with a right answer, so the base pins
`light-ansi` and the flip stays manual.

`autoCompactWindow` needs its arithmetic recorded, because the number looks
arbitrary and is not. The setting is a window size, not a percentage, and
claude fires auto-compact at **that value minus 33,000** -- `Bye()` holds back
`min(maxOutputTokens, 20000)` for output and `SQo()` subtracts a further
`13000`. So `633000` puts the trigger at 600,000 tokens. That is 60% only
because `model` is `opus[1m]`: the effective window is
`min(modelMax, autoCompactWindow)`, so on a 200k model the setting would do
nothing at all. The two keys are coupled, and changing one without the other
silently changes what the number means. Left at `auto` the trigger is 967,000,
or 96.7%.

Two displays disagree about the percentage, which is not a bug in either.
`bin/statusline.py` reads `context_window.used_percentage`, computed against
the raw model window, so it shows 60% at the moment of compaction. `/context`
computes against `min(modelMax, autoCompactWindow)` instead, so it shows nearly
100% at the same moment and grows an `Autocompact buffer` block worth the
33,000. Read the status line when the question is "how full is the model".

## Two agent skills are written here, the rest are installed

`~/.agents/skills` is where the installed skills live, and it is not a git
repository. All but two come from upstream — the bulk from `mattpocock/skills`,
plus `herdr` from `herdrdev/herdr` — so `setup.sh` restores them with one
`skills add` per source and nothing more is needed here than
`claude/skill-lock.json` as the record of what was installed and when. That
installer only fetches current, which puts skills in the same category as
`claude` and `cursor-agent`: reproducible, not pinnable.

Guard a new source on a skill only that source provides, never on
`~/.agents/skills` itself — the first source to install creates that directory
and would make every later step skip.

One `skills add --agent '*'` reaches all three CLIs here, but by two different
routes, and the difference matters when a skill appears to be missing. Claude
Code gets a symlink at `~/.claude/skills/<name>`; codex and cursor-agent read
`~/.agents/skills` directly and get no per-tool copy. An empty `~/.codex/skills`
is therefore normal and not a failed install.

`claude/skills/cleanup` and `claude/skills/audit-memory` are the exceptions.
Both are authored, both are absent from that lockfile, and until they were
tracked they existed on exactly one disk. They are symlinked into
`~/.claude/skills` like everything else here.

Anything written rather than installed belongs in this repository for the same
reason. The test is whether `skills add` could produce it again.

## One global instruction file, two names

`agents/global.md` is what every agent reads at the start of every session, in
every project. `setup.sh` links it to `~/.claude/CLAUDE.md`, which claude loads
as its user memory, and to `~/.codex/AGENTS.md`, which codex loads as its global
AGENTS.md. Nothing in the file is specific to a CLI — only the name each one
looks for is — so it is one file with two links rather than two copies to keep
in sync.

The name is `global.md` and not `AGENTS.md` on purpose. `AGENTS.md` is the
project-level instruction file for both codex and cursor-agent, so a file by
that name anywhere in this repo would be read a second time, as a project
instruction, whenever an agent works on the dotfiles themselves.

cursor-agent has no third link because it has no such file. Its global layer is
account-side User Rules, delivered in the server response rather than read from
disk, so it is a manual step in README.md next to the status line — the same
category as the config files this repo deliberately does not track.

Keep the file short. It costs context in every session in every project, so
anything true of only one repository belongs in that repository's `CLAUDE.md`,
not here.

## herdr is wired in both directions

herdr is the one multiplexer this setup keeps — the list below used to exclude
the whole category, and now excludes only tmux and screen. It earns the slot by
offering three things Ghostty does not: panes that survive a closed window, one
sidebar showing the state of every agent across every project, and a socket API
an agent can drive from inside its own pane. A multiplexer sits between the agent
and Ghostty, which is exactly where a second palette appears, and this one has
one — `[theme] name` is Catppuccin, not `terminal`. That is the exception carved
out at the top of this file, and `config/herdr/config.toml` carries the argument
for it.

It went the other way first. `terminal` gets herdr the right sixteen colors but
not the relationships between them, and herdr needs two relationships ANSI does
not fix. A fill needs a slot to work as a background, and slot 8 cannot: it has to
read *on* the background, so the selected entry measured 2.43:1 on the light half
and 2.18:1 on the dark one, with its second row at 1.02:1. And the sidebar's state
dots are drawn in the color slots, where a high-contrast light theme has to darken
its yellow to survive white — `GitHub Light High Contrast`'s palette 3 is
`#3f2200`, perfectly legible at 15:1 and not recognisable as yellow. A dot is a
glanceable signal, so hue is the requirement there, and no passthrough theme can
be talked out of the palette it passes through.

Catppuccin fixes both, and one thing survives the switch: herdr draws the second
row of an agent entry with SGR 2, which halves its distance to whatever is behind
it. That is arithmetic, not palette — the agent name measured 1.9:1 under
`terminal` and 1.5:1 under Catppuccin, the named theme being the worse of the two.
`[ui.sidebar.agents]` turns the `dim` off for that one row; the spaces panel draws
its second row in a real color and is left alone. With that in place every row and
dot in the sidebar clears 3:1 in both appearances, the weakest being the agent name
on a filled entry at 3.11:1.

When editing that file, note that `herdr config check` validates the TOML and, of
the values, only the keybindings. It reports `ok` for a color that is not a color
and falls back silently on a theme name it does not know, but it names an unknown
key and disables that binding. So a keybinding edit is confirmed by `check`, and a
theme edit only by looking at the sidebar after `herdr server reload-config`.

The prefix is `ctrl+t`, not herdr's `ctrl+b`, and it is the keybinding decision
that reaches outside herdr. `ctrl+b` is emacs'
backward-char, which is pressed in every pane far more often than any multiplexer
verb. `ctrl+t` was this repo's tmux prefix from 2014 until `.tmux.conf` was
deleted, so it is old muscle memory rather than a new one. It is not free either:
`.zshrc` runs `source <(fzf --zsh)`, which binds `^T` to `fzf-file-widget`, and
inside a herdr pane the prefix now wins — so before rebinding anything in
`.zsh/`, check it against the prefix. `split_vertical` moves to `prefix+|` for the
same reason; `prefix+minus` already matches what tmux bound `-` to. Resize does
not port at all, because herdr has `prefix+r`, a mode, and no repeat binding.

Moving between agents is the other binding, and it exists because herdr ships it
unbound: `focus_pane_h/j/k/l` stops at the edge of a tab, while the agents sit one
per workspace, so the only route to the next one was `prefix+w` and a pane key.
`next_agent`/`previous_agent` are `ctrl+alt+n`/`p`, the second and third direct
captures in this setup rather than prefixed bindings. That is the no-repeat gap
again: prefix mode exits after one action, so a prefixed pair walks one entry per
press, while a direct chord can be held and tapped. So the rule above widens —
check a new `.zsh/` binding against `ctrl+alt+n`/`p` as well as against the prefix.
They walk the sidebar's agent panel in whatever order `agent_panel_sort` gives it,
so that setting stays a free choice. herdr's indexed `focus_agent` is deliberately
still unbound — it would aim at a row number, which only holds still under
`"spaces"`, and two keys were the smaller change.

Those two letters are measured, and swapping them for a nicer pair is where an
afternoon goes. `ctrl+alt+k` and `ctrl+alt+u` deliver no bytes at all on this
machine — in a plain Ghostty tab as much as in a pane, with nothing in Ghostty's
keybinds, Karabiner or the system hotkeys to blame — while `ctrl+alt+o` and
`ctrl+alt+y` arrive and are eaten by the tty's own `DISCARD` and `DSUSP`. `herdr
config check` says `ok` to every one of them, because the key name parses. So a
replacement chord is confirmed with `cat -v` in a pane, the same way a theme edit
is confirmed by looking at the sidebar.

One part of the invariant turns out to depend on herdr's version rather than its
config. 0.8.0 is the release where "pane applications that query OSC 4 palette
colors now inherit the host terminal palette" (#1752); before it, a pane app
asking the terminal what its palette is did not necessarily get Ghostty's answer.
Everything here that asks rather than hardcodes — vim through `t_RB`, git-delta
through OSC 10/11 — is downstream of that, which is one more reason the upgrade
note below is not optional maintenance.

The wiring is two independent halves, and a working install needs both:

- **Agent → herdr** is the `herdr` skill, installed from `herdrdev/herdr`. It
  teaches an agent to split panes, run commands without stealing focus, read
  another pane's output, and wait on another agent — all through `herdr <group>
  <verb>`, which returns JSON. It is installed rather than written, so by the
  rule above it does not belong in this repository. Do not copy it here to edit
  the wording; upstream is the source of truth and the lockfile is the record.
- **herdr → agent** are the integrations, one `herdr integration install` per
  CLI. Each is a `SessionStart` hook herdr writes and owns, so the sidebar can
  report `working` / `blocked` / `done` from the agent itself instead of
  guessing from the screen.

Both halves are conditional on `HERDR_ENV=1`, which herdr sets in every pane it
owns. The skill checks it before touching anything, and the hooks exit quietly
without it, so an agent started in a plain Ghostty tab is unaffected.

codex needs one thing the other two do not. It will not run a hook it has not
been shown, so a freshly installed integration sits at a review prompt on the
next launch and reports `0 active` until a human presses `t`. `herdr
integration status` says `current` either way — it reports the file, not the
trust. When codex's agent state looks stuck, check that prompt before
suspecting herdr.

Upgrading herdr is not finished when Homebrew is finished. The server keeps
running the old binary, and a client whose protocol is newer refuses to talk to
it — every `herdr <group> <verb>` returns `protocol_mismatch`, which takes the
whole agent-facing surface down while the panes themselves carry on looking
fine. `herdr status` names it: `compatible: no`, `restart_needed: yes`. The
restart has to come from outside herdr, because stopping the server exits every
pane process:

```sh
HERDR_SOCKET_PATH="$HOME/.config/herdr/herdr.sock" herdr server stop
herdr
```

What that costs is bounded, and the integrations above are what bound it.
Layout comes back, and any agent that reported a native session reference is
relaunched with its own resume flag — `claude --resume <id>`, `codex resume
<id>`, `cursor-agent --resume <id>` — so the conversations continue rather than
restart. That needs integration version 6 / 5 / 1 or newer respectively, which
is why `setup.sh` keeps them current. Scrollback does not come back:
`pane_history` is off by default because pane output holds secrets, and it
should stay off.

## Reading a pane an agent started

The read-source trap itself is in `agents/global.md`, where the prescription
belongs — it is true in every repo, not just this one. What lives here is the
measurement behind it: `python3 -m http.server` in an 84-row pane read empty at
six lines of output and correct for both scrollback sources after a hundred.
That is why `visible` is the starting point and `recent-unwrapped` is worth
reaching for only once the output has actually scrolled.

`herdr pane wait-output --match` is the reliable readiness signal and does not
share the problem, because it searches the snapshot immediately and matches
output that already exists.

Do not add a completion-notification hook to match codex's `turn-ended` notify.
The sidebar already carries that signal for every agent at once, which is
strictly more than a per-tool notification, and building both means two things
to keep in sync.

## LANG is set, LC_ALL is not

`.zshenv` exports `LANG` and stops there. `LC_ALL` outranks every other locale
variable, including a one-off `LANG=... command` prefix, so exporting it turns
those prefixes into no-ops. That was not hypothetical: the
`LANG=en_US.UTF-8 vcs_info` in `.zsh/zshrc` sat there doing nothing for as long
as `LC_ALL` was set beside `LANG`.

That prefix is gone with vcs_info — starship reads git through a library rather
than parsing localized output, so it needs no locale of its own. Nothing here
demonstrates the rule any more, which makes it easier to undo by accident, not
harder: adding `export LC_ALL=$LANG` back now breaks nothing visible today and
the next `LANG=... command` written months from now instead. When one command
needs a different locale, prefix that command.

## Absent on purpose

Adding any of these undoes a decision rather than filling a gap:

- **tmux and screen** — herdr is the multiplexer, and it is agent-aware in a
  way neither of them is. Ghostty still owns the window.
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
