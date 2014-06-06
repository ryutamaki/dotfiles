#!bin/sh
##-----------------------------------------------
#  Install NEOBundle
##-----------------------------------------------

if [ -e /usr/bin/curl ] || [ -e /bin/curl ]; then
    curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
else
    echo "You should install 'curl' due to install NEOBunbdle."
    exit
fi

##-----------------------------------------------


##-----------------------------------------------
#  Put dotfiles
##-----------------------------------------------

dir=$HOME/dotfiles
olddir=$HOME/dotfiles_old
files="vimrc gitconfig zshrc zshenv tmux.conf"

echo "Creating $olddir for backup of any existing dotfiles in $HOME"
mkdir -p $olddir
echo "...done"

echo "Chenge to the $dir directory"
cd $dir
echo "...done"

echo "Moving any existing dotfiles from $HOME to $olddir"
for file in $files; do
    if [ -e file ] ; then
       mv $HOME/.$file $olddir/
    fi
    if [ ! -L $HOME/.$file ] ; then
        ln -s $dir/.$file $HOME/.$file
    fi
done

touch $HOME/.zsh_history
touch $HOME/.zshenv.local
touch $HOME/.gitconfig.local

##-----------------------------------------------
