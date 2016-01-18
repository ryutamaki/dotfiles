# Refer to URLs below
# https://github.com/junegunn/fzf/wiki/Examples
# https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
# https://github.com/gotbletu/shownotes/blob/master/fzf.txt

# fvim
function fvim fzf-editor-open-widget() {
    local file=$(__fsel)
    if [ -n "$file" ]; then
        print -z "${LBUFFER}${EDITOR:-vim} ${file}"
    fi
}

# fd - cd to selected directory
function fd() {
    local dir=$(find ${1:-*} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
    print -z "cd ${dir}"
}

# fda - including hidden directories
function fda() {
    local dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m) &&
    print -z "cd ${dir}"
}

# fgbr - checkout git branch
function fgbr() {
    local branches branch
    branches=$(git branch) &&
    branch=$(echo "$branches" | fzf +m) &&
    print -z "git checkout $(echo "$branch" | awk '{print $1}' | sed 's/.* //')"
}

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
