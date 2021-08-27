
call plug#begin('~/.config/nvim/plugged')
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-fugitive'
Plug 'preservim/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_powerline_fonts = 1
let g:coc_global_extensions = [
  \ 'coc-tsserver'
  \ ]
call plug#end()

set tabstop=2
set softtabstop=0 noexpandtab
set shiftwidth=2
set relativenumber
set rnu
set expandtab
set nobackup
set noswapfile
set nowrap

colorscheme gruvbox

map <silent> <C-n> :NERDTreeFocus<CR>
