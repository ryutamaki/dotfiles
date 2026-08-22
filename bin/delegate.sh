#!/usr/bin/env bash
#
# Hand a task to the model that fits it, in a herdr pane beside the caller.
#
# usage:
#   delegate <role> <name> <task...>    split a pane, start the agent, submit it
#   delegate --list                     the routing table
#   delegate --status                   live delegates, and what each plan has left
#   delegate --collect <name> [ms]      wait for it to settle, then print the tail
#   delegate --collect-all              the same for every delegate in this tab
#   delegate --answer <name> <keys>     answer a `blocked` delegate's prompt
#   delegate --close <name>
#   delegate --close-all
# :usage
#
# Either Opus 5 or Grok 4.6 Extra High is started by hand -- `claude` or
# `cursor-agent`. Each pins its model so nothing is chosen at launch, and
# that session manages rather than does everything itself. This is how it
# hands work to a model that is not already in the chair. A human never
# picks a model either; they pick a role.
#
# `route` below is the only place a model string is written. agents/global.md
# points here rather than repeating the table, for the same reason colors live
# only in the ghostty config: two copies drift. It matters more than usual here
# because a wrong model string does not fail loudly -- cursor-agent accepts an
# unknown --model and carries on with something else.
#
# Everything runs through `herdr agent`, never a bare background process, so a
# delegate appears in the sidebar with its own state and is relaunched with its
# resume flag when the herdr server restarts. That is the rule in
# agents/global.md applied to agents rather than to dev servers.

set -euo pipefail

QUOTA_DIR="${TMPDIR:-/tmp}/statusline-cache"

# bin/statusline.py writes these three, so the budget is already on disk and
# needs no request of its own. A stale percentage is worse than no percentage,
# because it reads as current -- so past its age a plan is reported as unknown.
#
# The ages are per plan and match the TTLs statusline.py sets, rather than one
# number for all three: it holds codex to 60s because that number moves inside a
# turn, and a shared half-hour here would show a codex figure statusline itself
# refuses to draw.
max_age_of() {
    case "$1" in
        codex) echo 60 ;;
        *)     echo 1800 ;;
    esac
}

# Warn above this. The number is a warning and never a reroute -- see budget().
QUOTA_WARN=85

# Every pane this script opens is labelled with this prefix, and that label is
# the whole registry. There is no state file: `herdr pane list` is the ledger,
# a leaked delegate is visible in the sidebar rather than recorded somewhere
# only this script can read, and nothing to reconcile survives a herdr restart.
TAG="dlg"

die() { printf 'delegate: %s\n' "$1" >&2; exit 1; }

##-----------------------------------------------
#  The routing table
##-----------------------------------------------

# Destinations first, roles second, because several roles share a destination
# and writing the model string once per role is how the second copy that drifts
# gets made. These four are the only launch model strings on this machine; the
# other three CLIs pin their own defaults in their own config, which is a
# different thing from this script naming one.
#
# Fast is absent from both Grok rungs, and that is a paid trade rather than a
# free one. cursor.com/docs/models/grok-4-6 prices standard at $2 / $0.50 / $6
# per Mtok (input / cached / output) and Fast at exactly double, $4 / $1 / $12 --
# and the same page says "Fast is the default speed tier on Pro and higher
# plans". So naming `high` is stepping down from the plan's own default speed to
# halve the rate at which the pool drains. Worth it here because the pool is what
# runs out first and the ladder wants more thinking rather than the same thinking
# sooner: `high` for breadth, `xhigh` when breadth was not enough, a real
# difference at one rate where `high-fast` and `xhigh` are two names for one
# call. Restoring `-fast` is a decision about speed against capacity, not a typo
# to fix.
dest() {
    case "$1" in
        grok)      echo 'cursor|--model cursor-grok-4.6-high' ;;
        grok-deep) echo 'cursor|--model cursor-grok-4.6-xhigh' ;;
        fable)     echo 'claude|--model fable' ;;
        codex)     echo 'codex|' ;;
    esac
}

# Roles name what the caller is buying, not where it lands -- so four of them
# share the two Grok destinations, and that is the point rather than a
# redundancy: `dlg:web:pricing` and `dlg:peer:tests` say different things in the
# sidebar when four panes are open, which `dlg:bulk:` four times would not.
route() {
    case "$1" in
        bulk)      echo 'grok|Default. Inventories, first passes, reading a lot of files' ;;
        web)       echo 'grok|Research that means reading many web pages' ;;
        peer)      echo 'grok|A parallel subtask this session could have done itself' ;;
        deep)      echo 'grok-deep|When a first pass was not enough' ;;
        hard)      echo 'fable|Scarce. Genuinely hard design and argument' ;;
        gpt)       echo 'codex|Scarce. A different vendor -- not a generic second pass' ;;
        image)     echo 'codex|Images, through Image 2. Same destination as gpt' ;;
        *)         return 1 ;;
    esac
}

ROLES="bulk web deep peer hard gpt image"

# role -> kind|argv|why, which is the shape every caller wants. Splitting it
# here rather than in each of the three keeps them from drifting apart.
resolve() {
    local spec d why
    spec="$(route "$1")" || return 1
    d="${spec%%|*}"; why="${spec#*|}"
    printf '%s|%s' "$(dest "$d")" "$why"
}

# Which subscription a kind spends. The three plans are metered separately, so
# this is what makes the budget warning mean anything.
plan_of() {
    case "$1" in
        claude) echo claude ;;
        codex)  echo codex ;;
        cursor) echo cursor ;;
    esac
}

# A delegate has nobody at its keyboard, so a permission prompt is a hang.
# Each CLI's "don't ask" lives here and nowhere else -- a session started
# by hand keeps its own settings. cursor --force still honours the deny
# list; codex -a never still runs inside workspace-write. The leftover
# cases (hook trust, a project codex has never seen) still surface as
# blocked, and --answer is still the keypress for those.
kind_flags() {
    case "$1" in
        cursor) echo '--trust --force --approve-mcps' ;;
        codex)  echo '-a never -s workspace-write' ;;
        *)      echo '' ;;
    esac
}

##-----------------------------------------------
#  Budget
##-----------------------------------------------

# Percent spent on one plan, or empty when the cache is missing or stale.
budget() {
    local plan="$1" path="$QUOTA_DIR/quota-$plan.json"
    [ -r "$path" ] || return 0
    python3 - "$path" "$(max_age_of "$plan")" <<'PY' 2>/dev/null || true
import json, sys, time
path, max_age = sys.argv[1], float(sys.argv[2])
try:
    with open(path) as fh:
        blob = json.load(fh)
except Exception:
    sys.exit(0)
if time.time() - blob.get("at", 0) > max_age:
    sys.exit(0)
used = (blob.get("usage") or {}).get("used")
if used is None:
    sys.exit(0)
print("{:.0f}".format(used))
PY
}

# Name the emptiest plan with a fresh number, so a warning can point somewhere
# rather than just complaining.
emptiest_plan() {
    local best="" best_pct="" plan pct
    for plan in claude codex cursor; do
        pct="$(budget "$plan")"
        [ -n "$pct" ] || continue
        if [ -z "$best_pct" ] || [ "$pct" -lt "$best_pct" ]; then
            best="$plan"; best_pct="$pct"
        fi
    done
    # printf, then return 0 unconditionally. Ending on the `&&` would return 1
    # when no plan has a fresh number, and every caller assigns from a command
    # substitution -- which under set -e exits the script rather than yielding
    # the empty string the caller is written to handle.
    [ -n "$best" ] && printf '%s %s' "$best" "$best_pct"
    return 0
}

# A warning and never a reroute. Sending the task somewhere the caller did not
# choose would put it on a model nobody reasoned about, which is a worse
# failure than running out of quota.
warn_budget() {
    local plan="$1" pct other
    pct="$(budget "$plan")"
    [ -n "$pct" ] || return 0
    [ "$pct" -ge "$QUOTA_WARN" ] || return 0

    printf 'delegate: %s is %s%% spent.' "$plan" "$pct" >&2
    other="$(emptiest_plan)"
    if [ -n "$other" ] && [ "${other%% *}" != "$plan" ]; then
        printf ' %s is at %s%% -- %s route there.' \
            "${other%% *}" "${other##* }" "$(roles_on_plan "${other%% *}")" >&2
    fi
    printf ' Sending anyway.\n' >&2
}

roles_on_plan() {
    local want="$1" role spec out=""
    for role in $ROLES; do
        spec="$(resolve "$role")"
        [ "$(plan_of "${spec%%|*}")" = "$want" ] || continue
        out="$out $role"
    done
    printf '%s' "${out# }"
}

##-----------------------------------------------
#  Verbs
##-----------------------------------------------

require_herdr() {
    [ "${HERDR_ENV:-}" = "1" ] || die 'not inside a herdr pane; there is nothing to split'
    command -v herdr >/dev/null || die 'herdr is not on PATH'
}

# codex takes no --model here: ~/.codex/config.toml owns that value, and
# printing a copy of it would put a model string in a second place. Name the
# owner instead.
model_column() {
    if [ -n "$2" ]; then printf '%s' "${2#--model }"; else printf '(%s config)' "$1"; fi
}

cmd_list() {
    local role spec kind extra why pct plan
    printf '%-7s %-14s %-38s %s\n' ROLE 'CLI (plan)' MODEL 'FOR'
    for role in $ROLES; do
        spec="$(resolve "$role")"
        kind="${spec%%|*}"; spec="${spec#*|}"
        extra="${spec%%|*}"; why="${spec#*|}"
        plan="$(plan_of "$kind")"
        pct="$(budget "$plan")"
        printf '%-7s %-14s %-38s %s\n' \
            "$role" \
            "$kind${pct:+ ${pct}%}" \
            "$(model_column "$kind" "$extra")" \
            "$why"
    done
    printf '\nbasic work stays here. When this session is already Grok, so do bulk/web/deep/peer.\n'
}

cmd_status() {
    local plan pct
    for plan in claude codex cursor; do
        pct="$(budget "$plan")"
        if [ -n "$pct" ]; then
            printf '%-7s %s%% spent\n' "$plan" "$pct"
        else
            printf '%-7s no fresh number\n' "$plan"
        fi
    done
    printf '\n'
    require_herdr
    local live
    live="$(delegate_panes)"
    if [ -z "$live" ]; then
        printf 'no live delegates in this tab\n'
    else
        printf '%s\n' "$live" | column -t -s "$(printf '\t')"
    fi
}

# `herdr agent start` requires the pane to be at its interactive shell prompt
# already, and a pane one millisecond old is not -- it answers agent_pane_busy.
# Retrying the call is better than waiting for a prompt string: the prompt comes
# from config/starship.toml, and matching on it here would put a copy of that
# character in a second place, where a prompt change would break spawning with
# no visible connection to the cause.
start_agent() {
    local name="$1" kind="$2" pane="$3" extra="$4" out attempt=0

    while :; do
        # Word splitting on $extra and $(kind_flags) is wanted: they are argv,
        # and no flag here contains a space.
        # shellcheck disable=SC2046
        if out="$(herdr agent start "$name" --kind "$kind" --pane "$pane" \
            --timeout 120000 -- $extra $(kind_flags "$kind") 2>&1)"; then
            return 0
        fi
        case "$out" in
            *agent_pane_busy*) ;;
            *) printf '%s\n' "$out" >&2; return 1 ;;
        esac
        attempt=$((attempt + 1))
        [ "$attempt" -lt 40 ] || { printf '%s\n' "$out" >&2; return 1; }
        sleep 0.25
    done
}

# One attempt: split, name, start, submit. Prints the pane id on success.
#
# On failure it takes its own pane back down and returns 1, because there is
# never anything in it worth keeping: `agent_prompt_stalled` means herdr saw no
# state change, which means the turn never began. Measured -- a stalled cursor
# pane holds the task text sitting unsent in its composer, and `send-keys enter`
# does not submit it either; the TUI is wedged, not busy. So there is no work to
# close over, and a fresh pane is what fixes it.
try_spawn() {
    local role="$1" name="$2" kind="$3" extra="$4" task="$5"
    local pane out

    pane="$(herdr pane split --current --direction right --cwd "$PWD" --no-focus \
        | jq -r '.result.pane.pane_id')"
    [ -n "$pane" ] && [ "$pane" != null ] || die 'could not split a pane'
    herdr pane rename "$pane" "$TAG:$role:$name" >/dev/null

    if ! start_agent "$name" "$kind" "$pane" "$extra"; then
        herdr pane close "$pane" >/dev/null 2>&1 || true
        return 1
    fi

    # --until working, not the default settled states: the caller delegates in
    # order not to block, so this returns the moment the delegate picks the task
    # up rather than when it finishes. It is still not the same as omitting
    # --wait. `herdr agent wait` matches the state it already sees, so a
    # --collect issued straight after a fire-and-forget prompt reports the state
    # from before the prompt landed and returns an empty answer as though the
    # work were done. --wait carries herdr's own observed-state-change guard,
    # which is what closes that race without this script keeping a sequence
    # number of its own.
    # By pane like every other agent call here, so no verb in this script
    # addresses an agent machine-wide.
    if out="$(herdr agent prompt "$pane" "$task" \
        --wait --until working --timeout 20000 2>&1)"; then
        printf '%s' "$pane"
        return 0
    fi

    printf '%s\n' "$out" >&2
    herdr pane close "$pane" >/dev/null 2>&1 || true
    return 1
}

cmd_spawn() {
    # ${2:-} rather than $2: set -u would turn `delegate bulk` into an unbound
    # variable trace instead of the message two lines down.
    local role="$1" name="${2:-}"
    shift $(( $# > 2 ? 2 : $# ))
    local task="$*"

    local spec kind extra
    spec="$(resolve "$role")" || die "unknown role '$role'; try --list"
    kind="${spec%%|*}"; spec="${spec#*|}"; extra="${spec%%|*}"

    [ -n "$name" ] || die 'a delegate needs a name; it is how you collect and close it'
    [ -n "$task" ] || die 'a delegate needs a task'

    require_herdr

    # Names are the handle for every other verb, so a collision would make
    # --collect ambiguous. Machine-wide on purpose, unlike the pane lookups:
    # `herdr agent <name>` resolves machine-wide, so a name another tab owns is
    # a name this one cannot safely use.
    if herdr agent list | jq -e --arg n "$name" \
        '[.result.agents[]? | select(.name == $n)] | length > 0' >/dev/null 2>&1; then
        die "an agent named '$name' is already live"
    fi

    warn_budget "$(plan_of "$kind")"

    # Two attempts, because the wedged-TUI stall above is transient and a second
    # pane clears it -- measured. Two and not more: if the CLI is genuinely busy
    # rather than wedged (codex downloading the release it decided to install on
    # launch, which also reports interactive-ready), retrying cannot help, and a
    # loop would spend the caller's turn opening panes.
    local pane attempt
    for attempt in 1 2; do
        if pane="$(try_spawn "$role" "$name" "$kind" "$extra" "$task")"; then
            printf '%s\t%s\t%s\n' "$name" "$pane" "$role"
            return 0
        fi
        [ "$attempt" = 1 ] && printf 'delegate: %s did not pick the task up; retrying once.\n' \
            "$name" >&2
    done

    printf 'delegate: %s could not be started. Nothing was left open.\n' "$name" >&2
    return 1
}

cmd_collect() {
    local name="${1:-}" timeout="${2:-}"
    [ -n "$name" ] || die 'which delegate?'
    require_herdr

    # Addressed by pane rather than by name. `herdr agent <name>` resolves
    # machine-wide, so a name this tab does not own would be read out of another
    # session's workspace -- the same reach the closing verbs were scoped out of.
    local pane
    pane="$(pane_of "$name")"
    [ -n "$pane" ] || die "no delegate named '$name' in this tab"

    # No --until: idle, done and blocked all mean "stopped, go look". Waiting
    # only for done would hang forever on a permission prompt. Spelled out both
    # ways rather than ${timeout:+...}, which word-splits into one argument.
    if [ -n "$timeout" ]; then
        herdr agent wait "$pane" --timeout "$timeout" >/dev/null
    else
        herdr agent wait "$pane" >/dev/null
    fi

    local state
    state="$(herdr agent get "$pane" | jq -r '.result.agent.agent_status')"
    [ -n "$state" ] && [ "$state" != null ] || state='unknown'
    printf '=== %s: %s ===\n' "$name" "$state"

    # --source visible rather than recent: the scrollback sources return an
    # empty string until output has actually scrolled off, which is the trap
    # agents/global.md records for panes and is no different here.
    herdr agent read "$pane" --source visible --lines 120
}

# A leftover blocked delegate is waiting on a keypress -- hook trust, a
# project never seen -- and without this the PM would hand-write
# `herdr agent send-keys` every time. It is a keypress and nothing more.
# Fan-in for the fan-out. A loop that opened three delegates should not have to
# name all three back, and this is the half of goal "flexible pane creation and
# deletion" that --close-all did not cover: --close-all could tidy a round up,
# nothing could read one.
#
# Sequential waits, which is not sequential waiting: the delegates have all been
# running since they were spawned, so the total is the slowest of them rather
# than the sum. One that cannot be collected is reported and the rest continue --
# a round is more useful nine-tenths read than abandoned at the first failure.
cmd_collect_all() {
    require_herdr
    local rows label name
    rows="$(delegate_panes)"
    if [ -z "$rows" ]; then
        printf 'no delegate panes in this tab\n'
        return
    fi
    while IFS="$(printf '\t')" read -r label _; do
        [ -n "$label" ] || continue
        name="${label##*:}"
        cmd_collect "$name" || printf 'delegate: could not collect %s\n' "$name" >&2
        printf '\n'
    done <<ROWS
$rows
ROWS
}

cmd_answer() {
    local name="${1:-}"; shift || true
    [ -n "$name" ] || die 'which delegate?'
    [ $# -gt 0 ] || die 'no keys; e.g. `delegate --answer <name> y` or `... esc`'
    require_herdr

    # By pane, for the reason cmd_collect gives -- sending keys to another
    # session's delegate is the worse half of that failure.
    local pane
    pane="$(pane_of "$name")"
    [ -n "$pane" ] || die "no delegate named '$name' in this tab"
    herdr agent send-keys "$pane" "$@" >/dev/null

    # Same race as the prompt in cmd_spawn, from the other side: without this,
    # a --collect issued next sees the still-blocked state and returns the
    # prompt it was just answered. Best effort -- some keys (esc, n) settle the
    # delegate rather than starting it working, and that is not a failure.
    herdr agent wait "$pane" --until working --timeout 8000 >/dev/null 2>&1 || true
    printf 'sent %s to %s\n' "$*" "$name"
}

# The tab the caller is sitting in. Every verb that closes something is scoped
# to it, and that is not a nicety: `herdr pane list` is machine-wide, so an
# unscoped --close-all reaches the delegates of every other agent on the machine.
# It did, on this script's first real run -- one session tidying up took down a
# delegate another session in a different workspace was waiting on, and nothing
# about that is visible to either of them. A delegate is always split from the
# caller's own pane, so it is always in the caller's own tab.
current_tab() {
    local tab
    tab="$(herdr pane current | jq -r '.result.pane.tab_id')"
    # jq prints the literal `null` for a missing field, and every caller feeds
    # this into `select(.tab_id == $tab)`, which then matches nothing -- turning
    # a lookup failure into a confident "no delegate panes in this tab". Die
    # instead, the same way the split does at cmd_spawn.
    [ -n "$tab" ] && [ "$tab" != null ] || die 'could not tell which tab this is'
    printf '%s' "$tab"
}

# The delegate panes in the caller's tab, as `pane_id label` lines. Every verb
# that enumerates panes goes through here: the tab scope is the thing the note
# above says must not be forgotten, and three copies of the filter is how it
# gets forgotten in the fourth place.
delegate_panes() {
    herdr pane list | jq -r --arg t "$TAG:" --arg tab "$(current_tab)" \
        '.result.panes[] | select(.tab_id == $tab
         and ((.label // "") | startswith($t)))
         | "\(.label)\t\(.pane_id)\t\(.agent_status)"'
}

# The pane of one named delegate in this tab, or empty. This is also what keeps
# `--collect` and `--answer` from reaching another session: `herdr agent <name>`
# resolves machine-wide, so a name this tab does not own would otherwise be read
# from, or have keys sent to it, in somebody else's workspace.
pane_of() {
    delegate_panes | awk -F'\t' -v s=":$1" \
        'substr($1, length($1) - length(s) + 1) == s { print $2; exit }'
}

cmd_close() {
    local name="${1:-}"
    [ -n "$name" ] || die 'which delegate?'
    require_herdr
    local pane
    pane="$(pane_of "$name")"
    [ -n "$pane" ] || die "no delegate named '$name' in this tab"
    herdr pane close "$pane" >/dev/null
    printf 'closed %s (%s)\n' "$name" "$pane"
}

cmd_close_all() {
    require_herdr
    local panes pane
    panes="$(delegate_panes | cut -f2)"
    if [ -z "$panes" ]; then
        printf 'no delegate panes in this tab\n'
        return
    fi
    # Labelled by this script, in this tab. A human's pane never carries the
    # prefix, and another agent's delegates are in another tab, so neither is
    # reachable from here.
    #
    # A close that fails is reported rather than skipped: `close && printf` said
    # nothing, carried on, and exited 0, so a pane that would not go down looked
    # like a pane that was never there.
    for pane in $panes; do
        if herdr pane close "$pane" >/dev/null 2>&1; then
            printf 'closed %s\n' "$pane"
        else
            printf 'delegate: could not close %s\n' "$pane" >&2
        fi
    done
}

# Printed by --help, read out of this file's own header so the two cannot
# disagree. Delimited rather than addressed by line number: a range breaks
# silently the next time a line is added above it, and --help is exactly the
# place a silent break goes unnoticed.
usage() {
    sed -n '/^# usage:$/,/^# :usage$/p' "$0" | sed '1d;$d;s/^# \{0,1\}//'
}

##-----------------------------------------------

case "${1:-}" in
    --list)      cmd_list ;;
    --status)    cmd_status ;;
    --collect)   shift; cmd_collect "$@" ;;
    --collect-all) cmd_collect_all ;;
    --answer)    shift; cmd_answer "$@" ;;
    --close)     shift; cmd_close "$@" ;;
    --close-all) cmd_close_all ;;
    -h|--help|'') usage ;;
    -*)          die "unknown option '$1'; try --help" ;;
    *)           cmd_spawn "$@" ;;
esac
