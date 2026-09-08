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
`rate_limits` sits in every `token_count` event under `~/.codex/sessions`,
and a live pane is not required: a window whose `resets_at` has passed
rolls to 0% rather than hiding the row, and a newest rollout that has not
written one yet is skipped. cursor has neither, so it is asked over the network:
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

## Two entry points, five models

Either Opus 5 or Grok 4.6 Extra High is started by hand. `claude` is Opus
-- `claude/settings.base.json` pins `opus[1m]` and `effortLevel: xhigh`.
`cursor-agent` is Grok -- `~/.cursor/cli-config.json` pins it, and that file is
machine-local for the same reason the status line is. It pins
`Cursor Grok 4.6 Extra High`, which is what README's checklist asks for.

Keeping it there took a fix, because **cursor-agent writes whatever `--model` it
was launched with back into that file on startup**. So every delegate quietly
became the default for the next session a human starts by hand: with the default
set to Extra High, one `bulk` delegate put it back to High. Only startup writes
it -- closing the pane does not -- so `bin/delegate.sh` snapshots the model keys
around `herdr agent start` and puts them back. That is a restore rather than a
configuration, which is the one shape of write this repo allows into a file a
tool owns; the hole it leaves is a session a human starts by hand inside that
window. Nothing is chosen at launch, and that session manages rather than does
everything itself. Grok is the chair when the claude plan is empty, or
when the work wants Grok in it (a review, a long loop). `bin/delegate.sh`
is how either of them reaches a model that is not already in the chair --
Fable 5 through claude, GPT-5.6 Sol through codex, Image 2 through
codex, and Grok itself when the chair is Opus.

**A caller picks a role, never a model string.** That is the whole point rather
than a convenience: choosing correctly at launch means knowing the shape of the
work before doing any of it, which is exactly what is not known then. The names
are `bulk`, `web`, `deep`, `peer`, `hard`, `gpt`, `image`.

**Destinations and roles are two tables, not one, and keeping them apart is the
point.** Seven roles land on four destinations, so writing the model string once
per role is precisely how the second copy that drifts gets made -- and a drifted
one fails quietly, because cursor-agent accepts an unknown `--model` and carries
on with something else. So `dest()` holds the four strings and nothing else does,
`route()` maps a role to a destination and a sentence, and `resolve()` joins them
for the three callers that need both.

Roles name **what the caller is buying**, which is why four of them share the two
Grok destinations rather than collapsing into one name. `dlg:web:pricing` and
`dlg:peer:tests` say different things in a sidebar holding four panes, and
`dlg:bulk:` four times does not. Grok is the plentiful plan and the other two are
not, which is why those four are where the default sits; `hard`, `gpt` and
`image` are the scarce slots, each something Grok cannot be -- Fable when deep
came back short, a different vendor, images. When the chair is already Grok,
those four roles are this session: do not open another Grok for them.

Fast is absent from every Grok destination, and the price of that is measured
rather than assumed. `cursor.com/docs/models/grok-4-6` prices standard Grok 4.6
at $2 / $0.50 / $6 per Mtok (input / cached / output) and Fast at exactly double,
$4 / $1 / $12; the paid plans meter a token pool rather than requests, so Fast
drains it twice as fast. The same page also says **"Fast is the default speed
tier on Pro and higher plans"**, which is the part worth knowing before touching
that table: naming `high` is not picking the plain option, it is stepping down
from the plan's own default speed in exchange for halving the rate.

That is the trade taken, and it is deliberate: the pool is what runs out first,
and what the ladder wants when it escalates is more thinking rather than the same
thinking sooner -- `high` for breadth, `xhigh` when breadth was not enough, a
real difference at one rate where `high-fast` and `xhigh` would have been two
names for one call. It is also the one line here that trades away speed, which
was named as a reason to prefer Grok in the first place, so restoring `-fast` is
a decision to make on purpose rather than a correction.

All four destinations were confirmed by asking each delegate what it was:
`Cursor Grok 4.6 High`, `Cursor Grok 4.6 Extra High`, `Fable 5 with xhigh
effort`, `gpt-5.6-sol xhigh`. A `web` delegate was confirmed the same way to
actually hold `WebSearch` and `WebFetch`, which is the whole basis of that role.
Confirm a change to either table this way -- the CLI's own header line, not the
model's answer, which gets its own name wrong.

`agents/global.md` states its triggers as the shape of the request -- an
inventory, a survey, 洗い出し, 調査, an answer that is out on the web, a loop of
more than a few iterations -- and that is the second attempt. `peer` still
carries no trigger on purpose: "a subtask worth not waiting for" is a judgement
call, and one of those sitting in the list would undo the list. The pull is
toward doing the work in the session that was asked, because reading a file here
always feels faster than opening a pane and waiting for one, so a trigger needing
a judgement call loses to that pull every time and the router goes unused.

**The first attempt stated them as counts -- ten files, three web pages -- and
the measurement is why they are gone.** Every transcript on disk, 181 sessions:
seven ever spawned a delegate, and 38 of the 69 spawns were in this repository,
which is to say while building the thing. The file trigger was crossed by 92
sessions and fired in 3; the web trigger, 17 and 2. Meanwhile claude sat at 85%
of its week with Grok at 4.4% of its month.

What a count cannot do is be true at a moment when acting on it is still
rational. "A survey that will read more than ~10 files" is a forecast at file
zero and a fact at file ten, and at file ten handing over means discarding the
work already done. So the trigger is never both true and actionable, and the old
argument was half right: countable triggers do survive their own inconvenience,
they just have no moment to be checked in. The shape of the ask has exactly one,
and it is the only one available -- the request arriving, before the first file is
open. That is a deliberately weaker predicate, bought for being evaluable while
nothing is sunk yet.

**`--wait` is the other half of the same measurement, and that half was missing
rather than wrong.** `delegate <role>` returns as soon as the delegate picks the
task up, which makes it a throughput device: the chair carries on working, the
wall clock is unchanged, and the scarce plan is not spared at all. The three
sessions that delegated most that week -- 13, 5 and 3 times -- are three of the
five largest claude spenders in it. Fired and forgotten, a delegate adds work
rather than moving it, so a router obeyed perfectly would still have emptied the
plan it was written to protect.

There are two reasons to delegate, they want opposite behaviour, and the verb now
says which one is being bought. `delegate --async bulk` for parallelism.
`delegate bulk` when the point is which subscription pays -- spawn, settle, read,
close, with the chair stopped for the duration. Collapsing the three-verb ceremony
matters more than it sounds: what the plain form actually loses to is not the
count in the trigger but the built-in subagent call, which is one tool call and
was reached for 148 times over the same sessions against delegate's 69.

Two details in that verb are not free choices. `herdr agent wait` without
`--timeout` waits indefinitely, so the one verb that blocks its caller needs a
ceiling or a wedged delegate takes the chair down with it -- `WAIT_MS` is fifteen
minutes, above every bulk survey measured here and below "the human has gone
home". And it closes the pane only on `idle` or `done`: a `blocked` delegate is
waiting on a keypress and an expired wait may be one still working, so closing
either would throw the work away along with the question. Those two keep their
pane and the message names the verb to use.

The routing rewrite above did work, and that is why what follows is about
ceremony rather than about triggers: Claude sessions using delegate went from 7
of 132 before 2026-08-24 to 32 of 77 after, 5% to 42%. What remained was not a
reluctance to decide.

**Which of the two forms is the default was then measured again, and inverted.**
`--wait` was the flag and fire-and-forget was the default, on the argument in the
paragraph above -- which is right about the verb having to say which reason is
being bought, and was wrong about which way round to say it. Across all 403
transcripts, 852 `delegate` calls produced 158 delegates: 5.4 tool calls each,
against roughly one for the built-in subagent that same paragraph already named
as the real competitor. 288 of those 852 are `--status`. Fired and forgotten, a
delegate turns its caller into a poller, which is the budget finding restated in
wall-clock terms rather than in tokens.

So the blocking form is what a bare `delegate <role> <name> <task>` does now and
`--async` is the flag. `--wait` stays as a one-line alias rather than an error:
the string is in old transcripts and in a human's fingers, and it now asks for
what happens anyway.

**The leak is that same arithmetic from the other end.** 20 of the 158 were never
closed by the session that opened them, and the distance is why -- a median of 19
tool calls, a mean of 29 and a maximum of 217 separate a spawn from its
`--close`. A close that far from its spawn depends on the chair still remembering
across a stretch that routinely spans a compaction, which is the same shape as a
routing trigger with no moment it can be checked in, and it fails the same way.
So reading a delegate ends it: `report_and_release` is shared by the default form
and by `--collect`, and both close the pane on `idle` or `done`. `--async` is the
only form that leaves one standing, which is the case where that is deliberate.

`unknown` sits in the same arm as `blocked` there rather than with `idle`, and
herdr's own skill is the reason: it means herdr cannot classify the pane and
"does not prove completion".

What none of that reaches is a delegate whose tab has moved on. Every closing
verb is scoped to the caller's tab, deliberately, and the price of that scope is
a leak nothing can close and nothing can see -- two were sitting `idle` in other
workspaces when this was written. So `--status` names them without touching them,
and closing those is a human in the sidebar.

The caller's own harness is the other ceiling, and it is lower than any ceiling
in the script. Claude Code's Bash tool stops a command at 120s by default and
refuses to be given more than 600s, while `WAIT_MS` is fifteen minutes -- and a
killed script runs none of its cleanup, so an overrun orphans the pane and hands
the chair nothing but "command timed out". Measured, that has not bitten yet: all
24 `--wait` calls on disk returned, 20 of them with an explicit 600000ms tool
timeout. Making the form the default is what puts it in reach, so the recovery is
a printf placed *before* the wait rather than after it -- output written before a
kill still reaches the caller -- and it names `--collect <name>`.

**Launching fails often enough to be its own reason not to reach for it, and
that half is not this script's to fix.** Of roughly 216 spawns on disk, 69 hit
the first retry, 15 the second and 22 gave up after all three: one launch in ten
never starts. `protocol_mismatch` appears in 9 sessions, which takes the whole
agent-facing surface down rather than one spawn. The retry ladder is already
tuned for the load-related stall it can see, so the remaining lever is herdr's
version -- 0.8.0 is installed, 0.8.2 is out, and 0.8.0's own notes name "`agent
start` now waits for new pane shells and first-run agent prompts to become ready
instead of racing them or reporting premature readiness". That upgrade is the
restart dance further down and costs every pane's scrollback, so it is its own
piece of work rather than a side effect of touching this script.

**The window was the other refusal, and it was arguing about one axis while the
window has two.** Every delegate took the widest pane in the tab and always took
it sideways, so 295 columns halved to 147 and then to 73 and the second delegate
was refused -- `no room in this tab` fired 13 times across 7 sessions. Widest-
first was itself a fix for `--current` making the caller pay for every delegate
it opened, and it inherited the sideways assumption from the version it
replaced.

So the caller's pane is now split once, to the right, and every delegate after
that stacks downward inside that column, tallest first for the reason widest-
first existed -- it spreads the cost rather than quartering the newest arrival.
An 84-row column reaches eight delegates before it refuses. The caller keeping
the window's full height from the first split on is the point rather than a side
effect: one full-height pane beside a stack of short ones says at a glance which
pane a human is meant to be typing in.

Opening beats the layout wherever the two conflict, and the ladder is written as
candidates in priority order so that stays true. The delegate column is tried
first, downward and then sideways, because that is the arrangement worth
keeping; the caller is tried **last rather than not at all**, and it is the
half a review caught. Dropping the caller from the pool the moment a delegate
existed meant a full column refused while the caller sat there splittable on
both axes -- layout beating opening, which is the inversion this was written to
prevent. So the caller can lose its full height, but only where the alternative
is refusing to open at all. Only when no candidate fits does `check_room`
refuse, and its message names the caller as the pane tried last so the numbers
it prints are the ones that actually decided.

`MIN_ROWS` is 10, measured the way `MIN_COLS` was rather than guessed: a 10-row
pane starts cursor-agent and takes a prompt, and at 5 rows `herdr agent start`
fails outright instead of stalling -- a louder failure than the width one, which
at 26 columns came up and silently never accepted the prompt. 10 is the
known-good number, not an extrapolation toward the cliff between them.

Two of the launch refusals are downstream of the leak rather than independent of
it, which is why the messages for both now name the fix. `is already live` fired
12 times across 9 sessions, and a delegate nobody closed is the usual reason the
name is taken -- so when the name resolves to a pane in this tab the message
says to `--collect` it, and only otherwise says to pick another name.

Every delegate is a `herdr agent`, never a background process. That is the rule
in `agents/global.md` about dev servers, applied to agents: the sidebar carries
its state, and the integrations relaunch it with its resume flag when the herdr
server restarts. It also means a delegate has no keyboard, so a permission
prompt is a hang rather than a question. `kind_flags` is where each CLI's
"don't ask" lives -- cursor-agent gets `--trust --force --approve-mcps`,
codex gets `-a never -s workspace-write`, and claude already has
`permissions.defaultMode: auto`. The deny list and the workspace sandbox
still apply; what these flags do not cover (a hook-trust prompt, a project
codex has never seen) still surfaces as `blocked`, and `--answer` is still a
keypress and nothing more. A session started by hand is unchanged -- these
flags only go on what this script starts.

What that buys is measured, and so is what it costs. A `deep` delegate carrying
those flags rewrote this file, `agents/global.md` and `bin/delegate.sh` while
another session was mid-edit on all three -- including adding the `--force` that
let it. That is the shape to expect rather than a bug: a delegate with approvals
off reaches anything the deny list does not name, this repository included. The
flags stay, deliberately. What changes is that one session owns a file at a
time, because an untracked file has no diff to recover a lost update from.

The pane label is the whole registry. `dlg:<role>:<name>` is set by
`herdr pane rename` and read back from `.label`, so there is no state file to
reconcile, a leaked delegate is visible in the sidebar rather than recorded
somewhere only that script can read, and `--close-all` cannot reach a pane a
human opened because a human's pane never carries the prefix.

**The label alone is not enough, and finding that out cost another session's
work.** `herdr pane list` is machine-wide, so the first `--close-all` reached a
delegate a different Opus 5 session had spawned in a different workspace and took
it down mid-task -- invisible to both sides, since neither is watching the
other's panes. Every closing verb is now scoped to the caller's own tab, which
is sound rather than a patch: a delegate is split from the caller's pane and
therefore always in the caller's tab. Anything added to that script that
enumerates panes needs the same scope, and the label is not a substitute for it.

The filter that finds those panes is one function for the same reason the scope
is one rule, and it took a fourth copy to make the point: `--status` needs the
same set cut the other way -- delegates *not* in this tab -- and wrote its own
copy of the label filter to get it. Worse than a duplicate, the inverted
comparison failed open rather than closed: `current_tab` inlined in a command
substitution cannot stop its caller when it dies, so an empty tab id turned
`!= $tab` into "every pane on the machine". `tagged_panes` now holds the filter,
`delegate_panes` and `stray_panes` are the two cuts, and both bind the tab id in
a bare assignment where set -e can see it fail.

That rule was then broken by the next thing added, which is why it is worth
stating twice. `herdr pane layout` with no argument answers for the **focused**
tab, not the caller's -- so the widest-pane split landed in whichever workspace a
human had last clicked into, the delegate was invisible to every verb here, and
two of them were left running in another session's tab. `own_pane` and
`herdr pane layout --pane` fix it. `herdr pane current` is what makes any of this
possible: it resolves the caller's pane from the calling terminal rather than
from focus, which is the one herdr call here that cannot move under you.

Scoping the closing verbs was half a fix, which a review caught. `herdr agent
<name>` also resolves machine-wide, so `--collect` and `--answer` reached the
same way -- reading another session's delegate, or sending keys into it, which is
the worse half. Both now resolve the name to a pane in this tab first and address
the pane, and `pane_of` / `delegate_panes` exist so the filter is written once
rather than in each verb that needs it.

Budget is warned about and never acted on. The three plans are metered
separately and `bin/statusline.py` already writes all three to
`$TMPDIR/statusline-cache/quota-*.json`, so the numbers cost nothing to read --
but rerouting on them would put the task on a model nobody reasoned about, which
is a worse outcome than running out. So above 85% it names the emptiest plan and
the roles that route there, and sends anyway. Anything older than half an hour
is reported as unknown rather than shown, because a stale percentage reads as a
current one.

Two races are closed there, and both look like a bug in the delegate rather than
in the timing. **`herdr agent wait` matches the state it already sees**, so a
`--collect` issued straight after a fire-and-forget prompt reports the state from
before the prompt landed and returns an empty answer as though the work were
done. The fix is `herdr agent prompt --wait --until working`, which carries
herdr's own observed-state-change guard; `--until working` rather than the
default settled states, because the point of delegating is not to block.
`--answer` has the same race from the other side and waits the same way, best
effort, since `esc` settles a delegate rather than starting it.

A delegate needs room, and running out of it does not look like running out of
it. `split --current` halved the caller's own pane every time, so the third
delegate arrived at about a quarter width and could not be prompted at all:
`agent start` reports ready, the task lands in the composer, and no Enter
submits it -- indistinguishable from the load-related stall below, which is what
made it cost half an hour to find. cursor-agent is fine at 53 columns and dead
at 26. So the split takes the widest pane in the tab rather than the caller's,
and `check_room` refuses below `MIN_COLS` with the numbers in the message.

That refusal has to be raised outside `try_spawn`, which is the second half of
the same lesson. `die` inside a function whose output is captured by a command
substitution exits only the subshell, so the first version's hard refusal came
back as an ordinary failure, got retried three times, and finished by blaming a
busy machine for a window that was merely full -- reproducing the exact
misdiagnosis the check was added to prevent.

`herdr agent start` needs the pane to be at an interactive shell prompt already,
and a pane one millisecond old is not -- it answers `agent_pane_busy`. The retry
is on that call rather than on a `wait-output --match` of the prompt character,
because the character comes from `config/starship.toml`: matching it here would
put a copy in a second place, where changing the prompt breaks spawning with no
visible connection to the cause.

One failure shape is worth recognising, because it is not the script's. codex
upgrades itself on launch -- it did, mid-verification, 0.147.0 to 0.149.0 -- and
during that download `herdr agent start` reports it interactive-ready while it
is not at a prompt, so the prompt stalls. It also means a Brewfile cask can move
without `brew bundle`, which the `--no-upgrade` note under setup.sh does not
cover.

An earlier draft left a stalled pane standing, on the theory that the CLI might
have the text and be working. That was wrong, and measuring it is what showed
why: `agent_prompt_stalled` means herdr observed no state change, so the turn
never began, and a stalled cursor pane holds the task sitting **unsent** in its
composer -- `send-keys enter` will not submit it either, because the TUI is
wedged rather than busy. There is nothing to close over. So `try_spawn` takes its
own pane down and `cmd_spawn` tries once more, which clears it; a second failure
means the CLI is genuinely occupied rather than wedged, where retrying cannot
help, and nothing is left open.

Those retries carry a growing pause, and the pause is the load-bearing part.
herdr's `--wait` requires an observed state change within 5000ms and that number
is its own -- a longer `--timeout` does not extend it -- so on a busy machine the
submit is structurally late. Back-to-back retries all land in the same busy
window, which is how the first version managed to fail twice and report a wedged
CLI that was only occupied.

`bin/delegate.sh` is symlinked to `~/.local/bin/delegate` rather than putting
`bin/` on PATH in `.zsh/path.zsh`. That directory also holds `setup.sh`, and
having `setup.sh` one tab-completion away in every shell is a worse trade than
one extra symlink.

## Loop goals are discovered, not declared

`claude/skills/loop-goal` exists because the hard part of a loop here is not
running it, it is that the finish line cannot be written at the start and the
real requirement only appears a few iterations in.

**The obvious answer is wrong and was rejected deliberately.** A contract file
holding an executable `exit 0` check, refusing to start until the check is
runnable, is a gate on precisely the thing it was supposed to help with: if the
finish line could be written, there was no problem. So the skill requires a
direction, a first probe, and a budget, and lets the goal be the string
`不明`.

The budget is the one field with no exemption, and that is the load-bearing
asymmetry: the finish line is sometimes unwritable, the iteration and time
ceiling never is. Not knowing where a loop ends is allowed; not knowing that it
ends is not.

What replaces the up-front check is a signal computed from the ledger's own
history. Each iteration appends three lines, the third being the rewritten goal
or the literal `unchanged`. Three consecutive `unchanged` means converged, and
that is when the exit check becomes writable -- if it still is not, the
`unchanged` lines were dishonest and the loop continues. Five consecutive
rewrites means the opposite: not discovery but a wrong direction, and it goes to
a human. So "cannot write a termination check" stops being a defect and becomes
a measurement.

Which plan pays is a field of its own now, beside the budget and exempt for the
same reason. A loop re-reads its ledger and rebuilds its context every iteration,
so it empties the chair's plan faster than anything else here, and which chair it
is in is knowable before the first iteration even when the goal is `不明`. Above
a few dozen iterations the answer is to start the loop in a Grok chair, not to
route out of a claude one; `delegate --wait bulk` per iteration is the fallback
for a loop already running in the wrong one.

The ledger is the state, which is why the skill says to put its path in the
`/loop` prompt rather than relying on the protocol staying in context. Read back
each iteration, it survives compaction, `/loop` re-invocation, and a herdr server
restart. `config/git/ignore` ignores `.loop/` globally for the reason the
`settings.local.json` line above it gives -- a loop is started in any repository,
and a per-repository rule is one that gets forgotten in the next one.

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
claude fires auto-compact at **that value minus 33,000**: one function holds
back `min(maxOutputTokens, 20000)` for output and another subtracts a further
`13000`. So `633000` puts the trigger at 600,000 tokens.

Re-checked against 2.1.241, because the constants are the load-bearing part and
the version has moved twice since they were first read. The total is still
33,000 and the two constants are unchanged; only the minified names are, from
`Bye` / `SQo` to `Xve` / `cyi`. Today's bundle carries `var fNp=20000`,
`function cyi(e,t){let r=e-13000`, `var sNp=13000,aNp=3000`, and the
composition `function vlr(e,t){return cyi(Xve(e,t),z2a(e,t))}`; the default max
output is `G5b=32000`, so `min(32000, 20000) + 13000` is where 33,000 comes
from. Names change per build, so re-check by grepping those constants rather
than the identifiers.

One thing to not misread on the way: the nearby level function subtracts 20,000
of its own (`a=s-20000`) and that one is the **warn** threshold, not compact.
Reading it as the trigger gives an answer that is wrong by the 13,000. That is 60% only
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

## Three agent skills are written here, the rest are installed

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

`claude/skills/cleanup`, `claude/skills/audit-memory` and
`claude/skills/loop-goal` are the exceptions. All three are authored, all three
are absent from that lockfile, and until they were tracked they existed on
exactly one disk. The section above argues what `loop-goal` is for.

**An authored skill needs two links, not one, and one link is worse than it
looks.** `~/.claude/skills/<name>` reaches claude; codex and cursor-agent read
`~/.agents/skills` directly and get no per-tool copy, so a skill linked only
into the first reaches one CLI out of three. Found by delegating the question:
`loop-goal` was invisible to codex and cursor-agent entirely, and `cleanup` had
drifted into a separate hand-edited fork under `~/.agents/skills` -- 118 lines
with four substitutions, `AGENTS.md` for `CLAUDE.md` and `.Codex/worktrees` for
`.claude/worktrees` -- so the same skill name behaved differently depending on
which CLI ran it. The fork is the symptom worth remembering: a per-tool path in
an authored skill is a reason for someone to fork it, so the skill names both
spellings and one copy serves all three, the same trade `agents/global.md` makes
by being one file under two names.

Adding those links early in `setup.sh` is safe even though the upstream
installer creates `~/.agents/skills` further down, and for the reason stated
above: those steps guard on a skill only their own source provides, never on the
directory.

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
which is why that setting is not a free choice and `config/herdr/config.toml`
argues it: under `"priority"` the panel reorders as agents change state, so the
row being walked toward moves during the walk. herdr's indexed `focus_agent` is deliberately
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
note below is not optional maintenance. Both halves of that were checked rather than assumed: the
OSC 4 wording is real and did ship in 0.8.0, and the newest stable is 0.8.2, so
this machine is two patch releases behind and the restart dance below is owed.

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

Stacking delegates made the other half of that ordinary, so `delegate` reads both
and keeps the longer answer. `visible` is one screenful, and a delegate in a
ten-row pane has its answer cut to ten lines while looking as though it said
almost nothing. The scrollback has the whole turn there — checked rather than
assumed, since a TUI holding the alternate screen would have none:
`recent-unwrapped` on a 10-row cursor-agent pane came back with the prompt, the
answer and the banner above it. Neither source is right alone, and which one is
wrong now depends on a pane height that is no longer fixed, so `read_agent` takes
the longer of the two. That extends the rule above rather than reversing it —
`visible` is still the floor.

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
