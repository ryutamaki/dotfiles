##-----------------------------------------------
#  Path settings
##-----------------------------------------------

# Don't set duplicated paths
typeset -U path

# Set path
path=(
      /usr/local/bin(N-/)
      /usr/bin(N-/)
      /bin(N-/)
      /usr/local/sbin(N-/)
      /usr/sbin(N-/)
      /sbin(N-/)
)


##-----------------------------------------------
#  Language settings
##-----------------------------------------------

export LANG=en_US.UTF-8
export LC_ALL=$LANG


##-----------------------------------------------
#  Other settings
#  TODO: you should divide these settings to an another file
##-----------------------------------------------

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell ses    sion *as a function*
## Add environment variable COCOS_CONSOLE_ROOT for cocos2d-x
export COCOS_CONSOLE_ROOT=$HOME/dev/Personal/cocos2d-x-3.0/tools/cocos2d-console/bin
export PATH=$COCOS_CONSOLE_ROOT:$PATH
