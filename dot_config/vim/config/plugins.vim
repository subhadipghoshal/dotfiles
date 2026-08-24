let s:plug_loader = g:fallback_config_root . '/autoload/plug.vim'
if filereadable(s:plug_loader)
  execute 'source ' . fnameescape(s:plug_loader)
endif

if !exists('*plug#begin')
  call fallback#health#warn_once(
        \ 'vim-plug is missing. Restore ~/.config/vim/autoload/plug.vim, then run :PlugInstall.'
        \ )
  unlet s:plug_loader
  finish
endif
unlet s:plug_loader

call plug#begin(g:fallback_plug_home)

Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'itchyny/lightline.vim'
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'christoomey/vim-tmux-navigator'
Plug 'fladson/vim-kitty'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'jiangmiao/auto-pairs'
Plug 'machakann/vim-highlightedyank'
Plug 'svermeulen/vim-yoink'
Plug 'tpope/vim-obsession'

Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'dense-analysis/ale'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'vim-test/vim-test'
Plug 'puremourning/vimspector', {
      \ 'do': { info -> fallback#plugins#install_vimspector(info) }
      \ }
Plug 'sheerun/vim-polyglot'

call plug#end()

if !get(g:, 'fallback_installing', 0)
      \ && !empty(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  call fallback#health#warn_once(
        \ 'One or more Vim plugins are missing. Run :PlugInstall, then restart Vim.'
        \ )
endif
