if exists(':colorscheme') == 2
  try
    colorscheme catppuccin_mocha
  catch /^Vim\%((\a\+)\)\=:E185/
    " Keep core editing available; config/plugins.vim emits the one install warning.
  endtry
endif

if exists(':TmuxNavigateLeft') != 2
  silent! nunmap <C-h>
  silent! nunmap <C-j>
  silent! nunmap <C-k>
  silent! nunmap <C-l>
  nnoremap <silent> <C-h> <C-w>h
  nnoremap <silent> <C-j> <C-w>j
  nnoremap <silent> <C-k> <C-w>k
  nnoremap <silent> <C-l> <C-w>l
endif

if exists(':ALEFix') == 2
  call ale#fix#registry#Add(
        \ 'fallback_markdown_toc',
        \ 'fallback#actions#markdown_toc_fixer',
        \ ['markdown'],
        \ 'Update a Markdown table of contents with markdown-toc.'
        \ )
  call ale#fix#registry#Add(
        \ 'fallback_taplo',
        \ 'fallback#actions#taplo_fixer',
        \ ['toml'],
        \ 'Format TOML with taplo.'
        \ )
endif

" Vimspector's Vim BufNew handler expands <afile>, which is unset for :new and
" :terminal buffers on Vim 9.2. Keep its sign refresh while avoiding E495.
if exists(':VimspectorNewSession') == 2
  augroup Vimspector
    autocmd! BufNew
    autocmd BufNew * call vimspector#OnBufferCreated(bufname(str2nr(expand('<abuf>'))))
  augroup END
endif
