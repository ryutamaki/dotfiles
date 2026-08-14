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


def braille_bar(value, width=4):
    value = pct(value)
    level = value / 100.0
    cells = []
    for index in range(width):
        start = index / width
        end = (index + 1) / width
        if level >= end:
            cells.append(BRAILLE[-1])
        elif level <= start:
            cells.append(BRAILLE[0])
        else:
            fraction = (level - start) / (end - start)
            cells.append(BRAILLE[min(int(fraction * (len(BRAILLE) - 1)), len(BRAILLE) - 1)])
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
        ansi(usage_color(value)), braille_bar(value), ansi(RESET),
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


if __name__ == "__main__":
    main()
