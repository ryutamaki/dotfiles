""-----------------------------------------------
"  NEOBundle
""-----------------------------------------------
if has('vim_starting')
  set nocompatible
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

""-----------------------------------------------
"  NEOBundle > plugins
""-----------------------------------------------

NeoBundle 'Shougo/unite.vim'
NeoBundleLazy 'Shougo/neomru.vim', {
\   'depends': 'Shougo/unite.vim',
\   'autoload': {
\       'unite_sources': 'file_mru'
\   }
\}
let g:unite_source_history_yank_enable = 1
nnoremap [unite] <Nop>
nmap <leader>u [unite]
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
nnoremap <silent> [unite]u :<C-u>Unite buffer file_mru<CR>
nnoremap <silent> [unite]y :<C-u>Unite history/yank<CR>


NeoBundleLazy 'hewes/unite-gtags', {
\   'depends': 'Shougo/unite.vim',
\   'autoload': {
\       'unite_sources': ['gtags/context', 'gtags/ref', 'gtags/def', 'gtags/grep', 'gtags/gtags/completion']
\   }
\}
nnoremap <silent> [unite]gcon :<C-u>Unite gtags/context<CR>
nnoremap <silent> [unite]gr :<C-u>Unite gtags/ref<CR>
nnoremap <silent> [unite]gd :<C-u>Unite gtags/def<CR>
nnoremap <silent> [unite]gg :<C-u>Unite gtags/grep<CR>
nnoremap <silent> [unite]gcom :<C-u>Unite gtags/completion<CR>


NeoBundle 'scrooloose/syntastic'
let g:syntastic_enable_signs = 1
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_auto_loc_list = 1
let g:syntastic_html_tidy_ignore_errors = [" proprietary attribute \"ng-"]


NeoBundle 'itchyny/lightline.vim'
let g:lightline = {
\   'active': {
\       'left': [ [ 'mode', 'paste' ], [ 'cd', 'dir', 'filename', 'modified' ] ],
\   },
\   'component': {
\       'dir': '%.50(%{expand("%:h:s?\\S$?\\0/?")}%)',
\       'cd': '%.50(%{fnamemodify(getcwd(), ":~")}%)',
\   },
\}


NeoBundle 'tyru/caw.vim.git'
nmap <leader>/ <Plug>(caw:i:toggle)
vmap <leader>/ <Plug>(caw:i:toggle)


NeoBundleLazy 'junegunn/vim-easy-align', {
\   'autoload': {
\       'mappings': '<Plug>(EasyAlign)',
\       'commands': 'EasyAlign'
\   }
\}
vmap <Enter> <Plug>(EasyAlign)
nmap <Leader>a <Plug>(EasyAlign)


NeoBundleLazy 'thinca/vim-quickrun', {
\   'autoload': {
\       'commands': 'QuickRun'
\   }
\}


NeoBundleLazy 'mustache/vim-mustache-handlebars', {
\   'autoload': {
\       'filename_patterns': '.*\.hbs'
\   }
\}
let g:mustache_abbreviations = 1


call neobundle#end()

filetype plugin indent on

"" If there are uninstalled bundles found on startup,
"" this will conveniently prompt you to install them.
NeoBundleCheck
