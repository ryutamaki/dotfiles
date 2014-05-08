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
files="vimrc gitconfig zshrc"

echo "Creating $olddir for backup of any existing dotfiles in $HOME"
mkdir -p $olddir
echo "...done"

echo "Chenge to the $dir directory"
cd $dir
echo "...done"

for file in $files; do
    echo "Moving any existing dotfiles from $HOME to $olddir"
    mv $HOME/.$file $olddir/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/.$file $HOME/.$file
done

touch $HOME/.zsh_history

##-----------------------------------------------
