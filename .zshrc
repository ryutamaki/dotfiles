## Use emacs keybind
bindkey -e


##-----------------------------------------------
#  aliases
##------------------------------------------------

alias g='git'

## move to a directory without 'cd'
#setopt auto_cd
alias -g ..='..'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g ......='../../../../../..'
alias -g .......='../../../../../../..'
alias -g ........='../../../../../../../..'


##-----------------------------------------------
#  ls settings
##-----------------------------------------------

## ls with colors
case $(uname) in
    *BSD|Darwin)
    alias ls="ls -G"
    ;;
    *)
    alias ls="ls --color=auto"
    ;;
esac

alias la="ls -A"
alias ll="ls -AlhFv"


##-----------------------------------------------
#  History settings
##-----------------------------------------------

## Set history file
HISTFILE=~/.zsh_history
## Number of history stored
HISTSIZE=10000000
## Number of history saved
SAVEHIST=$HISTSIZE
## Store the time not only commands
setopt extended_history
## Share history between processes
setopt share_history
## Add history immediately
setopt inc_append_history


##-----------------------------------------------
#  Complement settings
##-----------------------------------------------

## Initialize
autoload -Uz compinit
compinit
## Don't play sounds when no list comes up
setopt no_beep
## Don't care the letter whichever capital or small
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## Complemt with clors
zstyle ':completion:*' list-colors ""


##-----------------------------------------------
#  tmux auto start
##-----------------------------------------------

is_screen_running() {
  [ ! -z "$WINDOW" ]
}
is_tmux_running() {
  [ ! -z "$TMUX" ]
}
is_screen_or_tmux_running() {
  is_screen_running || is_tmux_running
}
shell_has_started_interactively() {
  [ ! -z "$PS1" ]
}
resolve_alias() {
  cmd="$1"
  while 
    whence "$cmd" >/dev/null 2>/dev/null && [ "$(whence "$cmd")" != "$cmd" ]
  do
    cmd=$(whence "$cmd")
  done
  echo "$cmd"
}
if ! is_screen_or_tmux_running && shell_has_started_interactively; then
  for cmd in tmux tscreen screen; do
    if whence $cmd >/dev/null 2>/dev/null; then
      $(resolve_alias "$cmd")
      break
    fi
  done
fi


##-----------------------------------------------
#  Pronpt settings
#  Refer to clear-code/zsh.d
##-----------------------------------------------

## PROMPT$BFb$GJQ?tE83+!&%3%^%s%ICV49!&;;=Q1i;;$r<B9T$9$k!#(B
setopt prompt_subst
## PROMPT$BFb$G!V(B%$B!WJ8;z$+$i;O$^$kCV495!G=$rM-8z$K$9$k!#(B
setopt prompt_percent
## $B%3%T%Z$7$d$9$$$h$&$K%3%^%s%I<B9T8e$O1&%W%m%s%W%H$r>C$9!#(B
setopt transient_rprompt

## Decide prompt looks
prompt_left_self="[%{%B%}%n%{%b%}%{%F{cyan}%}@%{%f%}%{%B%}%m%{%b%}]"
prompt_left_status="[%{%B%F{white}%(?.%K{green}.%K{red})%}%?%{%k%f%b%}]"
prompt_left_current_dir="[%{%B%}%d%{%f%k%b%}]"
prompt_left_up="${prompt_left_self} ${prompt_left_status} ${prompt_left_current_dir}"
prompt_left_down="-%(1j,(%j),)%{%B%}%#%{%b%} "

## Set prompt
## RPROMPT sets with git status below
PROMPT="${prompt_left_up}"$'\n'"${prompt_left_down}"

## Show git branch and status if the directory, where you are, have it.
autoload -Uz vcs_info
zstyle ':vcs_info:*' formats \
    '[%{%F{white}%F{green}%}%s%{%f%k%} %{%F{white}%F{blue}%}%b%{%f%k%}]'
zstyle ':vcs_info:*' actionformats \
    '(%{%F{white}%K{green}%}%s%{%f%k%})-[%{%F{white}%K{blue}%}%b%{%f%k%}|%{%F{white}%K{red}%}%a%{%f%k%}]'
precmd() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}


##------------------------------------------------
#  Do ls and git status when you press enter
##------------------------------------------------

function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    echo
    ls
    # $B"-$*$9$9$a(B
    # ls_abbrev
    if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        echo
        echo -e "\e[0;33m--- git status ---\e[0m"
        git status -sb
    fi
    zle reset-prompt
    return 0
}
zle -N do_enter
bindkey '^m' do_enter


##------------------------------------------------
#  include .zshenv.local
##------------------------------------------------

if [ -e ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
