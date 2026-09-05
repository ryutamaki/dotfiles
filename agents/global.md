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
delegate bulk <name> "<task>"          # hand over, wait, read, close: one call
delegate --async bulk <name> "<task>"  # returns at once: fan-out, not budget
delegate --collect <name>              # settle, read and close one of those
```

The default blocks, so give the tool call that runs it a 600000ms timeout. If
it is killed anyway the delegate is still working -- `--collect <name>` picks it
back up.

`delegate --help` has the rest -- `--status`, `--answer`, `--close`,
`--close-all`.

**Decide at the moment the request arrives, before the first file is opened.**
That is the only point where nothing is sunk yet: ten files in, handing over
means discarding work already done, so a count taken mid-task never fires.

    the ask is an inventory, a survey, 洗い出し, 調査, どうなっているか   ->  bulk
    the answer is out on the web rather than in this repo                 ->  web
    a loop of more than a few iterations                                  ->  a Grok chair, not this one
    an answer you are not confident in                                    ->  hard
    before settling a design decision, once                               ->  gpt, told to disagree
    an image is part of what is being delivered                           ->  image

The shape of the ask rather than a judgement about it, because reading a file
here always feels faster than opening a pane and waiting for one, so a rule
needing a judgement loses every time. Otherwise work here: implementing,
editing, refactoring, a few files, and talking to the human.

Grok is the plentiful plan and the other two are not, and waiting is what
actually spends it -- fired and forgotten, a delegate adds work rather than
moving it. When this session is already Grok, `bulk` / `web` / `deep` / `peer`
are this session -- do not open another Grok for them. Only when `HERDR_ENV=1`.

Every delegate is a pane, so the sidebar shows its state. Reading one ends it:
the default form and `--collect` both close the pane when the delegate stopped
on its own. `--async` is the only form that leaves one standing, so collect or
close whatever is fired that way before the session ends.

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
