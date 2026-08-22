# Global agent instructions

Edited as `agents/global.md` in the dotfiles repo, whose `CLAUDE.md` argues the
symlinks and the filename. Read at the start of every session in every project,
so it holds only what is true everywhere.

## Hand work to the model that fits it

Whichever model is in the chair, it manages rather than does everything itself.
`delegate` opens a herdr pane, starts the right CLI on the right model, and
submits the task. Choose a **role**, never a model string:

    bulk   default -- inventories, first passes, a lot of files
    web    research that means reading many web pages
    deep   when a first pass was not enough
    peer   a parallel subtask this session could have done itself
    hard   scarce -- genuinely hard design and argument
    gpt    scarce -- a different vendor, not a generic second pass
    image  images (same destination as gpt)

```sh
delegate bulk <name> "<task>"    # returns as soon as it picks the task up
delegate --collect <name>        # wait for it to settle, print the tail
```

`delegate --help` has the rest -- `--status`, `--answer`, `--close`,
`--close-all`.

Do this without being asked when one of these is true:

    a survey that will read more than ~10 files   ->  bulk
    research spanning more than ~3 web pages      ->  web
    an answer you are not confident in            ->  hard
    before settling a design decision, once       ->  gpt, told to disagree
    an image is part of what is being delivered   ->  image

Counts and occasions rather than a judgement, because reading a file here always
feels faster than opening a pane and waiting for one, so a softer rule loses
every time. Otherwise work here: implementing, editing, refactoring, a survey of
a few files, and talking to the human.

Grok is the plentiful plan and the other two are not. When this session is
already Grok, `bulk` / `web` / `deep` / `peer` are this session -- do not open
another Grok for them. Only when `HERDR_ENV=1`.

Every delegate is a pane, so the sidebar shows its state. Close what you opened;
the rule below about leaving a human's pane alone applies to these too.

## Long-running processes go in a herdr pane

When a task needs a dev server, a file watcher, or anything else that stays up
and keeps printing, start it in its own herdr pane instead of backgrounding it.
A backgrounded process is visible only to the agent. A pane is visible to both
of us, its log can be read as it goes, and the sidebar shows whether it is
still alive.

Only when `HERDR_ENV=1`. Outside a herdr pane there is nothing to talk to, and
an ordinary background process is the right answer.

```sh
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr pane run <id> "<command>"
herdr pane wait-output <id> --match "<ready line>" --timeout 30000
herdr pane read <id> --source visible --lines 40
```

Take `<id>` from `.result.pane.pane_id` of the split rather than predicting it.
`--no-focus` leaves the human wherever they already were, and `--cwd "$PWD"`
is required because a new pane does not inherit the caller's directory.

Read with `--source visible`. `recent` and `recent-unwrapped` read the pane's
scrollback and return an empty string until output has actually scrolled off
the viewport, so a server that has only printed its startup lines reads as
having printed nothing at all.

Do not close a pane the human might still be reading. A dev server started for
a task is theirs once the task is over; say where it is and leave it running.

The installed `herdr` skill documents the rest of that CLI, but it gates itself
on the user naming herdr explicitly, so it will not fire on its own for this.
Use the commands above directly.
