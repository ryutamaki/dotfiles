# Refer to URLs below
# https://github.com/junegunn/fzf/wiki/Examples
# https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh

##-----------------------------------------------
#  What fzf lists
#
#  fd is in the Brewfile; without these it went unused and fzf walked the tree
#  itself, descending into .git and node_modules. fd reads .gitignore, so the
#  listing matches what the repository actually tracks.
#
#  --hidden brings back dotfiles, which fd omits by default -- this repo is
#  nothing but dotfiles -- and .git is then excluded by name.
#
#  No FZF_DEFAULT_OPTS with colors in it: fzf drawing in the terminal's own
#  palette is the point (see config/ghostty/config).
##-----------------------------------------------

if command -v fd > /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

##-----------------------------------------------
#  Where fzf-file-widget is reachable from
#
#  `fzf --zsh` binds it to ^T, and ^T is herdr's prefix -- see
#  config/herdr/config.toml for why the prefix moved there -- so inside a herdr
#  pane the widget had no key at all.
#
#  ^O is the slot that was free. Its default, accept-line-and-down-history, is
#  the one control key in the emacs keymap nothing here reaches for, unlike the
#  ^A/^B/^E/^F/^K/^W/^Y that made ^B unusable as a prefix in the first place.
#
#  ^T keeps its binding rather than being unbound. Outside a herdr pane -- a
#  plain Ghostty tab, or over ssh -- nothing is eating it, and taking it away
#  would buy nothing.
#
#  FZF_CTRL_T_COMMAND above keeps its name whichever key is bound: fzf reads it
#  by widget, not by binding. The guard is because the widget only exists once
#  `fzf --zsh` has run in .zshrc; binding a missing widget is a startup error
#  rather than a quiet no-op.
##-----------------------------------------------

if zle -l fzf-file-widget; then
    bindkey '^O' fzf-file-widget
fi

# z - z with fzf
unalias z 2> /dev/null
z() {
    if [[ -z "$*" ]]; then
        cd "$(_z -l 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
    else
        _last_z_args="$@"
        _z "$@"
    fi
}

zz() {
    cd "$(_z -l 2>&1 | sed 's/^[0-9,.]* *//' | fzf -q $_last_z_args)"
}
