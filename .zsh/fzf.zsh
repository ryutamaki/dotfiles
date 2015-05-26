# Refer to URLs below
# https://github.com/junegunn/fzf/wiki/Examples
# https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
# https://github.com/gotbletu/shownotes/blob/master/fzf.txt

# fzf-editor-open-widget
function fzf-editor-open-widget() {
    local file=$(__fsel)
    if [ -n "$file" ]; then
        LBUFFER="${LBUFFER}${EDITOR:-vim} ${file}"
        zle redisplay
    fi
}
zle -N fzf-editor-open-widget
bindkey '^o' fzf-editor-open-widget

# fzf-cd-widget - cd to selected directory
function fzf-cd-widget() {
    local dir=$(find ${1:-.} -type d 2> /dev/null | fzf-tmux +m)
    if [ -n "$dir" ]; then
        cd "$dir"
        zle reset-prompt
    fi
}
zle -N fzf-cd-widget
bindkey '^j' fzf-cd-widget
bindkey -r '^T' # remove default setting

# fzf-file-widget
# if you add key binds when installing fzf, this function below is redefined
fzf-file-widget() {
    LBUFFER="${LBUFFER}$(__fsel)"
    zle redisplay
}
zle     -N   fzf-file-widget
bindkey '^z' fzf-file-widget
