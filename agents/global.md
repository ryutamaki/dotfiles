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
    image  images (same CLI as gpt)

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

## A web screen has a request budget

Any web app built or changed here holds each screen to about **5 API calls on
first load, 10 at most**, and each call to **300ms**. A call that has a real
reason to take longer says why in a comment on its route.

Count the calls a screen makes whenever it gains a fetch, and design to the
budget from the start rather than trimming later:

- A list resolves the names it shows in one batch (`?ids=a,b,c`), one request
  for the whole page rather than one per row.
- A detail screen gets its side panels -- counts, badges, related records,
  display names -- in the same response as the record itself, so nothing waits
  on the record before it can start.
- Existence checks read only the key, not the whole row.

Measure against the production shape, not a laptop. A 0.25-vCPU container
gets 25ms of CPU per 100ms, so a dozen parallel requests that finish in 15ms
locally queue into 600ms there; `docker run --cpus=<production value>` on the
production image reproduces it.

## A web screen keeps the user's place

The user's **place** -- which screen, which record, the filters, search, sort,
page, open tab or panel, and anything typed but not yet saved -- survives
every way of leaving and coming back: the back button, a reload, a shared
link, and a sign-in that expired. Any web app built or changed here is held to
that.

- Whatever changes what the screen shows lives in the URL query, written with
  `replace` so typing does not stack history. A `useState` holding a filter,
  tab or page is a place that the back button will throw away.
- Every sign-in redirect carries the current path, query and hash as a
  `return_to`, and the callback sends the user there. Accept only a same-origin
  path (starts with one `/`, no backslash, not the auth routes themselves) so
  it cannot be turned into an open redirect.
- A link back to a list goes to the list as the user left it (browser back, or
  a URL carrying the query), never to its bare path.
- After a save, stay on the record or return to where the user came from --
  not to a home screen.
- Text a user is composing -- a note, a dialog form -- outlives an expired
  session: keep a draft (sessionStorage is enough) until the save succeeds.

When a screen gains a redirect, a `navigate()`, or a piece of view state, walk
it: set some filters, open a record, go back, reload, expire the session. The
user should land exactly where they were each time.
