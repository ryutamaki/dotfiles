## Use emacs keybind
bindkey -e


##-----------------------------------------------
#  directory settings
##-----------------------------------------------

## move to a directory without 'cd'
#setopt auto_cd
## aliases
alias -g ..='..'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'


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
#  include .zshenv.local
##------------------------------------------------

if [ -e ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
