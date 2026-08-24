scriptencoding utf-8

function! s:xdg_dir(variable, fallback) abort
  let l:value = eval('$' . a:variable)
  return empty(l:value) ? expand(a:fallback) : expand(l:value)
endfunction

let g:fallback_data_dir = s:xdg_dir('XDG_DATA_HOME', '~/.local/share') . '/vim'
let g:fallback_state_dir = s:xdg_dir('XDG_STATE_HOME', '~/.local/state') . '/vim'
let g:fallback_plug_home = g:fallback_data_dir . '/plugged'
let g:fallback_session_dir = g:fallback_state_dir . '/sessions'
let g:vimspector_base_dir = g:fallback_data_dir . '/vimspector'
let g:polyglot_disabled = ['autoindent', 'ftdetect', 'sensible']

for s:directory in [
      \ g:fallback_data_dir,
      \ g:fallback_data_dir . '/undo',
      \ g:vimspector_base_dir,
      \ g:fallback_state_dir,
      \ g:fallback_state_dir . '/backup',
      \ g:fallback_state_dir . '/sessions',
      \ g:fallback_state_dir . '/swap',
      \ g:fallback_state_dir . '/view',
      \ ]
  if !isdirectory(s:directory) && mkdir(s:directory, 'p', 0700) == 0
    echoerr 'Unable to create Vim state directory: ' . s:directory
  endif
endfor
unlet s:directory

let &undodir = g:fallback_data_dir . '/undo//'
let &backupdir = g:fallback_state_dir . '/backup//'
let &directory = g:fallback_state_dir . '/swap//'
let &viewdir = g:fallback_state_dir . '/view'
let &viminfofile = g:fallback_state_dir . '/viminfo'

set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set undofile
set backup
set writebackup
set swapfile
set viminfo='100,<50,s10,h
set hidden
set autoread
set confirm
set mouse=a
set clipboard=unnamed
set number
set relativenumber
set numberwidth=4
set signcolumn=yes
set laststatus=2
set showtabline=2
set cmdheight=1
set noshowmode
set ruler
set wildmenu
set wildmode=longest:full,full
set pumheight=10
set completeopt=menuone,noselect
set shortmess+=c
set updatetime=250
set timeoutlen=300
set splitbelow
set splitright
set scrolloff=8
set sidescrolloff=8
set nowrap
set linebreak
set breakindent
set ignorecase
set smartcase
set incsearch
set nohlsearch
set showmatch
set backspace=indent,eol,start
set whichwrap+=<,>,[,],h,l
set autoindent
set smartindent
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set formatoptions-=o
set iskeyword+=-
set spelllang=en_us,de_de,es_es
set termguicolors
set background=dark

if isdirectory(expand('~/.local/share/nvim/mason/bin'))
  let s:mason_bin = expand('~/.local/share/nvim/mason/bin')
  if index(split($PATH, ':'), s:mason_bin) < 0
    let $PATH .= ':' . s:mason_bin
  endif
  unlet s:mason_bin
endif

filetype plugin indent on
syntax enable
