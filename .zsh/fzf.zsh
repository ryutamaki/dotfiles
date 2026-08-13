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
