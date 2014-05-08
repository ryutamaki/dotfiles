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
autoload -U compinit
compinit
# Don't play sounds when no list comes up
setopt no_beep
