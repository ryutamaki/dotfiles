##-----------------------------------------------
#  Path settings -- the ONLY place PATH is defined
#
#  Sourced from both .zshenv and .zprofile on purpose:
#    - .zshenv  covers non-login shells (scripts, editors, AI agents)
#    - .zprofile re-asserts the order for login shells, because macOS
#      /etc/zprofile runs path_helper, which moves the system paths back
#      to the front of PATH.
#
#  Do not prepend to PATH anywhere else. If a tool's installer appends a
#  line to .zshrc or .zprofile, move it here.
##-----------------------------------------------

# Keep both names deduplicated. `typeset -U path` alone is not enough:
# without PATH listed too, `export PATH="x:$PATH"` reintroduces duplicates.
typeset -U path PATH

path=(
      $HOME/.local/bin(N-/)
      ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/mysql-client/bin(N-/)
      ${HOMEBREW_PREFIX:-/opt/homebrew}/bin(N-/)
      ${HOMEBREW_PREFIX:-/opt/homebrew}/sbin(N-/)
      $HOME/local/bin(N-/)
      /usr/local/bin(N-/)
      /usr/bin(N-/)
      /bin(N-/)
      /usr/local/sbin(N-/)
      /usr/sbin(N-/)
      /sbin(N-/)
)
