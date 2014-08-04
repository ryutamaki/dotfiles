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

export LANG=ja_JP.UTF-8
export LC_ALL=$LANG
