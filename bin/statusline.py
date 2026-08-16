#!/usr/bin/env python3
"""Status line for the AI CLIs -- three lines: usage / terminal / git.

Claude Code and cursor-agent both take a `statusLine` command, spawn it every
few seconds, feed it a JSON snapshot on stdin and draw whatever it prints to
stdout. The two payloads are near enough that one script serves both:

    ~/.claude/settings.json      "statusLine": {"type": "command", ...}
    ~/.cursor/cli-config.json    "statusLine": {"type": "command", ...}

Only Claude Code reports `rate_limits`, and only cursor-agent reports
`model.param_summary`; each segment is skipped when its key is absent, so
neither tool needs its own copy of this file.

codex has no equivalent hook -- it renders a status line from a fixed set of
built-in items, chosen in `[tui] status_line` of ~/.codex/config.toml. That
list is kept pointing at the same facts this script prints.

Inside a herdr pane this also draws one block in herdr's sidebar, holding how
much of all three plans has been spent, and when each comes back:

    claude █▋░░░  33% →14:30
    codex  ██▊░░  56% →8/19
    cursor █▊░░░  35% →8/21

It goes on a workspace labelled `usage`, whose rows are named in
`[ui.sidebar.spaces]` of config/herdr/config.toml. Create that space and the
block appears; there isn't one and nothing is pushed. CLAUDE.md argues why it
sits there rather than on the agent rows.

Only claude's number arrives here on its own, in the payload; the other two are
gone looking for, which is why any pane drawing a status line writes the whole
block rather than just its own line:

    claude   `rate_limits` on stdin, kept in a cache for the panes that lack it
    codex    the last `token_count` of the newest ~/.codex/sessions rollout
    cursor   asked for over the network, with the token cursor-agent stored

So nothing writes the block unless a claude or cursor-agent pane is drawing
one, and "always visible" is really "visible while one of those two is on
screen". Ten minutes of codex alone, or of a closed laptop, and the TTL empties
it. That is the shape of the gap, and it is the price of adding no daemon.

Colors are the 16 ANSI ones, so the terminal theme in config/ghostty/config
is still the only place a palette is defined. Nothing here picks an RGB value.

Runs on the system python3 (3.9) so that it works before mise does.
"""

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime


PR_CACHE_DIR = os.path.join(tempfile.gettempdir(), "statusline-cache")
PR_CACHE_TTL = 300

# `gh pr view` is the one slow call here. Keep it under cursor-agent's spawn
# timeout even on a cache miss.
PR_TIMEOUT = 2.0
GIT_TIMEOUT = 0.4
HERDR_TIMEOUT = 0.3

HERDR_SOURCE = "statusline:quota"
# A percentage is a snapshot, so the push expires. Ten minutes outlives a lull
# between draws and still clears the block before its numbers are worth
# mistrusting. The reset stamp is absolute and does not go stale with it.
QUOTA_TTL_MS = 600000
# One stamp for every pane, because they are all writing the same block, and
# ten seconds because that is the finest the numbers behind it ever move.
QUOTA_STAMP = os.path.join(PR_CACHE_DIR, "quota-push")
QUOTA_INTERVAL = 10
USAGE_WORKSPACE = "usage"

# Five cells at eight steps each, which is finer than the whole percent beside
# it. `░` rather than a space in the first slot is what gives the sidebar's bar
# a track -- it fills with what is spent, like the status line's, but has no
# label beside it to say where a full one would end.
BLOCK = "░▏▎▍▌▋▊▉█"
BAR_WIDTH = 5
QUOTA_RULE = "─"

# claude's numbers are only in hand while a claude pane draws; half an hour is
# long enough to cover a stretch of cursor-agent-only work and short enough
# that a genuinely abandoned number leaves rather than misleads.
CLAUDE_CACHE = os.path.join(PR_CACHE_DIR, "quota-claude.json")
CLAUDE_CACHE_TTL = 1800

CODEX_SESSIONS = os.path.expanduser("~/.codex/sessions")
# codex writes its rate limits into every `token_count` event, so the answer is
# always near the end of the newest rollout. Read back far enough to clear one
# turn's worth of tool output without reading the whole file.
CODEX_TAIL_BYTES = 512 * 1024
CODEX_CACHE = os.path.join(PR_CACHE_DIR, "quota-codex.json")
# No grace beyond the TTL: an empty read here means the window has rolled over,
# which is a fact rather than a failure, and holding the old number would be
# holding a wrong one.
CODEX_CACHE_TTL = 60

# cursor's plan usage is in neither its payload nor a file, so it is asked for.
# One `GetCurrentPeriodUsage` carries both halves -- `totalPercentUsed` and the
# billing cycle end -- so `GetUsageLimitPolicyStatus`, which `/usage` also
# calls, is not needed here. This is the same shape as the `gh pr view` call
# below it: a network round trip behind a disk cache, with a timeout short
# enough that a dead network costs the sidebar a refresh and nothing else.
CURSOR_ENDPOINT = "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
CURSOR_KEYCHAIN_ITEM = "cursor-access-token"
CURSOR_CACHE = os.path.join(PR_CACHE_DIR, "quota-cursor.json")
CURSOR_CACHE_TTL = 300
# Unlike codex's, an empty read here is a failed request rather than an answer,
# so the last good number is held across one. Half an hour of held number is
# the point at which it stops being worth more than a blank row.
CURSOR_MAX_AGE = 1800
CURSOR_TIMEOUT = 2.0
# A read that does not prompt measures 0.02s. This is only ever hit when macOS
# has put a dialog up, and the two timeouts together have to stay under the 5s
# cursor allows the whole script.
CURSOR_KEYCHAIN_TIMEOUT = 1.0


RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
BRAILLE = " ⣀⣄⣤⣦⣶⣷⣿"
SEPARATOR = " │ "


def ansi(value):
    if os.environ.get("NO_COLOR"):
        return ""
    return value


def as_float(value, default=0.0):
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def pct(value):
    return max(0.0, min(100.0, as_float(value)))


def usage_color(value):
    value = pct(value)
    if value < 50:
        return GREEN
    if value < 80:
        return YELLOW
    return RED


def bar(value, width, ramp):
    # ramp[0] is an empty cell and ramp[-1] a full one, so a ramp whose first
    # glyph is a space leaves no track behind the bar and one whose first is
    # `░` draws one. Only the sidebar needs the track; see BLOCK.
    level = pct(value) / 100.0
    cells = []
    for index in range(width):
        start = index / width
        end = (index + 1) / width
        if level >= end:
            cells.append(ramp[-1])
        elif level <= start:
            cells.append(ramp[0])
        else:
            fraction = (level - start) / (end - start)
            cells.append(ramp[min(int(fraction * (len(ramp) - 1)), len(ramp) - 1)])
    return "".join(cells)


def reset_time(value):
    try:
        if value is None:
            return ""
        timestamp = float(value)
    except (TypeError, ValueError):
        return ""

    if timestamp <= 0:
        return ""

    return datetime.fromtimestamp(timestamp).strftime("%H:%M")


def usage_segment(label, value, reset_at=None):
    if value is None:
        return "{}{}{} --%".format(ansi(DIM), label, ansi(RESET))

    value = pct(value)
    segment = "{}{}{} {}{}{} {:.0f}%".format(
        ansi(DIM), label, ansi(RESET),
        ansi(usage_color(value)), bar(value, 4, BRAILLE), ansi(RESET),
        value,
    )
    reset = reset_time(reset_at)
    if reset:
        segment += "{}→{}{}".format(ansi(DIM), reset, ansi(RESET))
    return segment


def join(parts):
    return "{}{}{}".format(ansi(DIM), SEPARATOR, ansi(RESET)).join(parts)


def run_git(cwd, *args):
    if not cwd:
        return ""

    try:
        result = subprocess.run(
            ["git", "-C", cwd, *args],
            capture_output=True,
            text=True,
            timeout=GIT_TIMEOUT,
            check=False,
        )
    except Exception:
        return ""

    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def count_lines(value):
    if not value:
        return 0
    return len([line for line in value.splitlines() if line.strip()])


def shorten_path(path):
    if not path:
        return ""
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def agent_line(data):
    model = data.get("model") or {}
    name = model.get("display_name") or "agent"
    parts = ["{}{}{}{}".format(ansi(BOLD), ansi(MAGENTA), name, ansi(RESET))]

    # cursor-agent only: the reasoning effort and flags behind the model name.
    summary = model.get("param_summary")
    if summary:
        parts.append("{}{}{}".format(ansi(DIM), summary, ansi(RESET)))

    parts.append(usage_segment("ctx", (data.get("context_window") or {}).get("used_percentage")))

    # Claude Code only: how much of the plan's usage windows is spent.
    rate_limits = data.get("rate_limits") or {}
    five_hour = rate_limits.get("five_hour") or {}
    if five_hour.get("used_percentage") is not None:
        parts.append(usage_segment("5h", five_hour["used_percentage"], five_hour.get("resets_at")))

    seven_day = rate_limits.get("seven_day") or {}
    if seven_day.get("used_percentage") is not None:
        parts.append(usage_segment("7d", seven_day["used_percentage"]))

    return join(parts)


def terminal_line(cwd):
    try:
        import pwd as _pwd
        user = _pwd.getpwuid(os.getuid()).pw_name
    except Exception:
        user = os.environ.get("USER", "")

    try:
        import socket as _socket
        host = _socket.gethostname().split(".")[0]
    except Exception:
        host = ""

    identity = "{}{}{}{}@{}{}{}{}".format(
        ansi(BOLD), user, ansi(RESET),
        ansi(DIM), ansi(RESET),
        ansi(BOLD), host, ansi(RESET),
    )

    path = shorten_path(cwd)
    if not path:
        return identity
    return join([identity, "{}cwd{} {}{}{}".format(
        ansi(DIM), ansi(RESET), ansi(CYAN), path, ansi(RESET))])


def pr_cache_path(cwd, branch):
    digest = hashlib.sha1("{}::{}".format(cwd, branch).encode()).hexdigest()[:16]
    return os.path.join(PR_CACHE_DIR, "pr-{}.json".format(digest))


def fetch_pr(cwd):
    try:
        result = subprocess.run(
            ["gh", "pr", "view", "--json", "number,state,isDraft"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=PR_TIMEOUT,
            check=False,
        )
    except Exception:
        return None

    # A non-zero exit is the normal answer for "this branch has no PR". Cache
    # that too, otherwise every refresh pays for `gh` again.
    if result.returncode != 0:
        return {"number": None}

    try:
        data = json.loads(result.stdout)
    except Exception:
        return None

    return {
        "number": data.get("number"),
        "state": data.get("state"),
        "is_draft": data.get("isDraft", False),
    }


def get_pr_info(cwd, branch):
    if not cwd or not branch:
        return None

    path = pr_cache_path(cwd, branch)

    try:
        with open(path) as fh:
            cached = json.load(fh)
        if time.time() - cached.get("ts", 0) < PR_CACHE_TTL:
            return cached.get("pr")
    except Exception:
        pass

    pr = fetch_pr(cwd)

    try:
        os.makedirs(PR_CACHE_DIR, exist_ok=True)
        with open(path, "w") as fh:
            json.dump({"ts": time.time(), "pr": pr}, fh)
    except Exception:
        pass

    return pr


def pr_segment(pr):
    if not pr or pr.get("number") is None:
        return ""

    if pr.get("is_draft"):
        color = DIM
    elif pr.get("state") == "MERGED":
        color = MAGENTA
    elif pr.get("state") == "CLOSED":
        color = RED
    else:
        color = GREEN

    return "{}pr{} {}#{}{}".format(
        ansi(DIM), ansi(RESET), ansi(color), pr["number"], ansi(RESET))


def parse_left_right(value):
    # `rev-list --left-right --count A...B` prints left then right. The caller
    # decides which is ahead and which is behind by the order it passes A and B.
    if not value:
        return 0, 0
    try:
        left, right = value.split()
        return int(left), int(right)
    except (ValueError, AttributeError):
        return 0, 0


def git_line(cwd):
    branch = run_git(cwd, "branch", "--show-current")
    if not branch:
        commit = run_git(cwd, "rev-parse", "--short", "HEAD")
        branch = "detached:{}".format(commit) if commit else ""
    if not branch:
        return ""

    staged = count_lines(run_git(cwd, "diff", "--cached", "--numstat"))
    modified = count_lines(run_git(cwd, "diff", "--numstat"))
    untracked = count_lines(run_git(cwd, "ls-files", "--others", "--exclude-standard"))
    behind, ahead = parse_left_right(
        run_git(cwd, "rev-list", "--left-right", "--count", "@{upstream}...HEAD")
    )

    parts = ["{}git{} {}{}{}".format(
        ansi(DIM), ansi(RESET), ansi(BOLD), branch, ansi(RESET))]

    status = []
    if staged:
        status.append("{}+{}{}".format(ansi(GREEN), staged, ansi(RESET)))
    if modified:
        status.append("{}~{}{}".format(ansi(YELLOW), modified, ansi(RESET)))
    if untracked:
        status.append("{}?{}{}".format(ansi(RED), untracked, ansi(RESET)))
    if status:
        parts.append(" ".join(status))
    elif not (ahead or behind):
        parts.append("{}clean{}".format(ansi(GREEN), ansi(RESET)))

    sync = []
    if ahead:
        sync.append("↑{}".format(ahead))
    if behind:
        sync.append("↓{}".format(behind))
    if sync:
        parts.append(" ".join(sync))

    pr = pr_segment(get_pr_info(cwd, branch))
    if pr:
        parts.append(pr)

    return join(parts)


def herdr_call(method, params):
    # The socket rather than the `herdr <group> <verb>` CLI everything else
    # here is told to use, because this runs on every draw and spawning a
    # binary two or three times a second to write a display token is not worth
    # what it costs. The framing is the one herdr's own hooks use.
    path = os.environ.get("HERDR_SOCKET_PATH")
    if not path:
        return None

    request = {
        "id": "{}:{}".format(HERDR_SOURCE, time.time_ns()),
        "method": method,
        "params": params,
    }

    try:
        import socket as _socket
        client = _socket.socket(_socket.AF_UNIX, _socket.SOCK_STREAM)
        client.settimeout(HERDR_TIMEOUT)
        client.connect(path)
        client.sendall((json.dumps(request) + "\n").encode())
        chunks = []
        while True:
            chunk = client.recv(65536)
            if not chunk or b"\n" in chunk:
                chunks.append(chunk)
                break
            chunks.append(chunk)
        client.close()
    except Exception:
        return None

    try:
        return json.loads(b"".join(chunks).split(b"\n")[0].decode())
    except Exception:
        return None


def reset_stamp(timestamp):
    # Inside the day the time of day is what is wanted; past it, the date. The
    # form that shows also says which window is being reported, so the label
    # the row has no room for is not really missing: a clock is the five-hour
    # window, a date is the weekly or monthly one.
    seconds = as_float(timestamp) - time.time()
    if seconds <= 0:
        return ""
    when = datetime.fromtimestamp(as_float(timestamp))
    if seconds < 86400:
        return when.strftime("%H:%M")
    return "{}/{}".format(when.month, when.day)


def quota_row(name, usage):
    if not usage or usage.get("used") is None:
        return None

    # Past its reset the percentage is not stale, it is wrong: the window has
    # rolled over and nothing has run since to say so. No row beats a number
    # that will never be corrected.
    resets_at = usage.get("resets_at")
    if resets_at is not None and as_float(resets_at) <= time.time():
        return None

    used = pct(usage["used"])
    row = "{:<6} {} {:>3.0f}%".format(name, bar(used, BAR_WIDTH, BLOCK), used)
    stamp = reset_stamp(resets_at)
    if stamp:
        row += " →{}".format(stamp)
    return row


def claude_usage(rate_limits):
    windows = []
    for key in ("five_hour", "seven_day"):
        window = rate_limits.get(key) or {}
        if window.get("used_percentage") is not None:
            windows.append({
                "used": window["used_percentage"],
                "resets_at": window.get("resets_at"),
            })
    if not windows:
        return None

    # One row, so report whichever window is nearest its limit -- that is the
    # one about to stop the session. The status line still carries both, for
    # the pane that has room for them.
    return max(windows, key=lambda window: pct(window["used"]))


def newest_codex_rollout():
    # rollout-<timestamp>-<uuid>.jsonl under sessions/<year>/<month>/<day>, all
    # zero-padded, so the newest is the lexicographic maximum of the names.
    # Descending by the largest directory at each level would be cheaper and is
    # wrong: codex leaves a day directory behind when its sessions are cleared,
    # and one empty newest day would report no codex at all.
    import glob as _glob

    rollouts = _glob.glob(os.path.join(CODEX_SESSIONS, "*", "*", "*", "rollout-*.jsonl"))
    if not rollouts:
        return ""
    return max(rollouts, key=os.path.basename)


def read_codex_usage():
    path = newest_codex_rollout()
    if not path:
        return None

    try:
        with open(path, "rb") as fh:
            fh.seek(0, os.SEEK_END)
            fh.seek(max(0, fh.tell() - CODEX_TAIL_BYTES))
            tail = fh.read()
    except OSError:
        return None

    # The first line of the tail is usually cut in half. It fails to parse and
    # is skipped like any other line without the key.
    for line in reversed(tail.split(b"\n")):
        if b'"rate_limits"' not in line:
            continue
        try:
            payload = json.loads(line.decode("utf-8")).get("payload") or {}
        except Exception:
            continue
        limits = payload.get("rate_limits") or {}
        # Both windows, and the nearer one to its limit wins, the same way
        # claude's do. This plan only fills `primary`, but taking it blindly
        # would hide a weekly limit behind a five-hour one elsewhere.
        windows = [
            {"used": window["used_percent"], "resets_at": window.get("resets_at")}
            for window in (limits.get("primary"), limits.get("secondary"))
            if window and window.get("used_percent") is not None
        ]
        if not windows:
            continue
        return max(windows, key=lambda window: pct(window["used"]))
    return None


def cursor_bearer():
    # The item cursor-agent's own login created. macOS asks once, for
    # /usr/bin/security rather than for the caller, and is silent after that.
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", CURSOR_KEYCHAIN_ITEM, "-w"],
            capture_output=True,
            text=True,
            timeout=CURSOR_KEYCHAIN_TIMEOUT,
            check=False,
        )
    except Exception:
        return ""

    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def fetch_cursor_usage():
    bearer = cursor_bearer()
    if not bearer:
        return None

    import urllib.request

    request = urllib.request.Request(
        CURSOR_ENDPOINT,
        data=b"{}",
        headers={
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
            "Authorization": "Bearer {}".format(bearer),
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=CURSOR_TIMEOUT) as response:
            body = json.loads(response.read().decode("utf-8"))
    except Exception:
        return None

    used = (body.get("planUsage") or {}).get("totalPercentUsed")
    if used is None:
        return None

    # Milliseconds, and a string. Everything else here is epoch seconds.
    ends_at = as_float(body.get("billingCycleEnd")) / 1000.0
    return {"used": used, "resets_at": ends_at or None}


def read_usage(path, max_age):
    # `at` is when the numbers were obtained, `tried` when one was last
    # attempted. They part company when a fetch fails, which is the whole
    # reason there are two of them.
    try:
        with open(path) as fh:
            entry = json.load(fh)
    except Exception:
        return None, 0.0, 0.0

    at = as_float(entry.get("at"))
    tried = as_float(entry.get("tried"))
    if time.time() - at >= max_age:
        return None, 0.0, tried
    return entry.get("usage"), at, tried


def write_usage(path, usage, at):
    # Only the two numbers are written. cursor's reply also carries what the
    # plan has been spent down to in cents, which has no business in a cache.
    try:
        os.makedirs(PR_CACHE_DIR, exist_ok=True)
        with open(path, "w") as fh:
            json.dump({"at": at, "tried": time.time(), "usage": usage}, fh)
    except OSError:
        pass


def fetched_usage(path, ttl, max_age, fetch):
    usage, at, tried = read_usage(path, max_age)
    if time.time() - tried < ttl:
        return usage

    fresh = fetch()

    # A fetch that comes back empty does not throw away one that did not, so a
    # single network blip costs nothing. `tried` moves either way, so a broken
    # network is retried on the interval rather than on every draw, and `at`
    # stays put, which is what finally clears a number nothing can refresh.
    if fresh is None and usage is not None:
        write_usage(path, usage, at)
        return usage

    write_usage(path, fresh, time.time())
    return fresh


def take_turn(path, interval):
    # True at most once per interval across every pane, and the caller that
    # gets it has already claimed the next one.
    try:
        if time.time() - os.stat(path).st_mtime < interval:
            return False
    except OSError:
        pass

    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, "w").close()
    except OSError:
        pass
    return True


def usage_workspace():
    response = herdr_call("workspace.list", {}) or {}
    for workspace in ((response.get("result") or {}).get("workspaces")) or []:
        if workspace.get("label") == USAGE_WORKSPACE:
            return workspace.get("workspace_id")
    return None


def push_quota(data):
    if os.environ.get("HERDR_ENV") != "1":
        return

    usage = claude_usage(data.get("rate_limits") or {})
    if usage:
        write_usage(CLAUDE_CACHE, usage, time.time())

    if not take_turn(QUOTA_STAMP, QUOTA_INTERVAL):
        return

    workspace_id = usage_workspace()
    if not workspace_id:
        return

    rows = {
        "claude": quota_row("claude", read_usage(CLAUDE_CACHE, CLAUDE_CACHE_TTL)[0]),
        "codex": quota_row("codex", fetched_usage(
            CODEX_CACHE, CODEX_CACHE_TTL, CODEX_CACHE_TTL, read_codex_usage)),
        "cursor": quota_row("cursor", fetched_usage(
            CURSOR_CACHE, CURSOR_CACHE_TTL, CURSOR_MAX_AGE, fetch_cursor_usage)),
    }

    # Measured against what was actually drawn rather than fixed, because a
    # reset shown as a date is a character shorter than one shown as a clock.
    # Pushed with the rows so that it leaves when they do.
    widths = [len(row) for row in rows.values() if row]
    rows["rule"] = QUOTA_RULE * max(widths) if widths else None

    # A row with nothing behind it is sent as null, which clears the token
    # rather than leaving the last known number sitting there indefinitely.
    herdr_call("workspace.report_metadata", {
        "workspace_id": workspace_id,
        "source": HERDR_SOURCE,
        "seq": time.time_ns(),
        "ttl_ms": QUOTA_TTL_MS,
        "tokens": rows,
    })


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("status unavailable")
        return

    workspace = data.get("workspace") or {}
    cwd = workspace.get("current_dir") or data.get("cwd") or workspace.get("project_dir")

    lines = [agent_line(data)]
    for line in (terminal_line(cwd), git_line(cwd)):
        if line:
            lines.append(line)

    print("\n".join(lines))

    # Flushed before the sidebar work rather than at exit, because that work
    # can outlast the host's patience -- cursor kills this at 5s and a cold
    # cursor fetch can spend 5 of those -- and a buffered line dies with it.
    sys.stdout.flush()

    # After the print, and never allowed to reach it: the sidebar is a bonus,
    # the status line is the job.
    try:
        push_quota(data)
    except Exception:
        pass


if __name__ == "__main__":
    main()
