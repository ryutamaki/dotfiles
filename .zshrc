# -*- mode: sh; indent-tabs-mode: nil -*-

# Use vim keybind
bindkey -v


##-----------------------------------------------
#  Directory settings
##-----------------------------------------------

setopt auto_cd


##-----------------------------------------------
#  History settings
##-----------------------------------------------

# Set history file
HISTFILE=~/.zsh_history
# Number of history stored
HISTSIZE=10000000
# Number of history saved
SAVEHIST=$HISTSIZE
# Store the time not only commands
setopt extended_history
# Share history between processes
setopt share_history
# Add history immediately
setopt inc_append_history


##-----------------------------------------------
#  Complement settings
##-----------------------------------------------

# Initialize
autoload -Uz compinit
compinit
# Don't play sounds when no list comes up
setopt no_beep


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

# Decide prompt looks
prompt_left_self="(%{%B%}%n%{%b%}%{%F{cyan}%}@%{%f%}%{%B%}%m%{%b%})"
prompt_left_status="(%{%B%F{white}%(?.%K{green}.%K{red})%}%?%{%k%f%b%})"
prompt_left_current_dir="<%{%B%K{magenta}%F{white}%}%d%{%f%k%b%}>"
prompt_left_up="-${prompt_left_self}-${prompt_left_status}-${prompt_left_current_dir}-"
prompt_left_down="-[%h]%(1j,(%j),)%{%B%}%#%{%b%} "

# Set prompt
PROMPT="${prompt_left_up}"$'\n'"${prompt_left_down}"
RPROMPT="[%{%B%F{white}%K{magenta}%}%~%{%k%f%b%}]"

# Show git branch and status if the directory, where you are, have it.
autoload -Uz vcs_info
zstyle ':vcs_info:*' formats \
    '(%{%F{white}%K{green}%}%s%{%f%k%})-[%{%F{white}%K{blue}%}%b%{%f%k%}]'
zstyle ':vcs_info:*' actionformats \
    '(%{%F{white}%K{green}%}%s%{%f%k%})-[%{%F{white}%K{blue}%}%b%{%f%k%}|%{%F{white}%K{red}%}%a%{%f%k%}]'
precmd() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info >&/dev/null
    RPROMPT="${vcs_info_msg_0_}-${RPROMPT}"
}
