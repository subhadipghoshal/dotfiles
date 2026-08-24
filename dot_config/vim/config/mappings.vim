nnoremap <Space> <Nop>
xnoremap <Space> <Nop>
nnoremap ; :
inoremap jk <Esc>
inoremap kj <Esc>
nnoremap <silent> <Esc> :nohlsearch<CR>
nnoremap <silent> <C-s> :write<CR>
nnoremap <silent> <C-q> :quit<CR>
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <silent> <C-d> <C-d>zz
nnoremap <silent> <C-u> <C-u>zz
nnoremap <silent> n nzzzv
nnoremap <silent> N Nzzzv
xnoremap <silent> p "_dP
nnoremap x "_x
nnoremap <leader>y "+y
xnoremap <leader>y "+y
nnoremap <leader>Y "+Y

nnoremap <silent> <C-h> :TmuxNavigateLeft<CR>
nnoremap <silent> <C-j> :TmuxNavigateDown<CR>
nnoremap <silent> <C-k> :TmuxNavigateUp<CR>
nnoremap <silent> <C-l> :TmuxNavigateRight<CR>
nnoremap <silent> <C-\> :TmuxNavigatePrevious<CR>
nnoremap <silent> <C-Up> :resize +2<CR>
nnoremap <silent> <C-Down> :resize -2<CR>
nnoremap <silent> <C-Left> :vertical resize -2<CR>
nnoremap <silent> <C-Right> :vertical resize +2<CR>
nnoremap <silent> <leader>- :split<CR>
nnoremap <silent> <leader>\| :vsplit<CR>
nnoremap <silent> <leader>wd :close<CR>

nnoremap <silent> <S-h> :bprevious<CR>
nnoremap <silent> <S-l> :bnext<CR>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> <leader>bb :buffer #<CR>
nnoremap <silent> <leader>bd :call fallback#buffer#delete(0)<CR>
nnoremap <silent> <leader>bD :call fallback#buffer#delete(1)<CR>
nnoremap <silent> <leader>bo :call fallback#buffer#only()<CR>

nnoremap <silent> <leader><Tab><Tab> :tabnew<CR>
nnoremap <silent> <leader><Tab>d :tabclose<CR>
nnoremap <silent> <leader><Tab>] :tabnext<CR>
nnoremap <silent> <leader><Tab>[ :tabprevious<CR>
nnoremap <silent> <leader><Tab>f :tabfirst<CR>
nnoremap <silent> <leader><Tab>l :tablast<CR>
nnoremap <silent> <leader><Tab>o :tabonly<CR>

nnoremap <silent> <leader><Space> :call fallback#actions#files(1)<CR>
nnoremap <silent> <leader>ff :call fallback#actions#files(1)<CR>
nnoremap <silent> <leader>fF :call fallback#actions#files(0)<CR>
nnoremap <silent> <leader>/ :call fallback#actions#grep(1)<CR>
nnoremap <silent> <leader>sg :call fallback#actions#grep(1)<CR>
nnoremap <silent> <leader>sG :call fallback#actions#grep(0)<CR>
nnoremap <silent> <leader>fw :call fallback#actions#grep(1)<CR>
nnoremap <silent> <leader>e :call fallback#actions#explorer(1)<CR>
nnoremap <silent> <leader>E :call fallback#actions#explorer(0)<CR>

nnoremap <silent> gd :call fallback#actions#coc('jumpDefinition')<CR>
nnoremap <silent> gD :call fallback#actions#coc('jumpDeclaration')<CR>
nnoremap <silent> gr :call fallback#actions#coc('jumpReferences')<CR>
nnoremap <silent> gI :call fallback#actions#coc('jumpImplementation')<CR>
nnoremap <silent> gy :call fallback#actions#coc('jumpTypeDefinition')<CR>
nnoremap <silent> K :call fallback#actions#hover()<CR>
nnoremap <silent> <leader>ca :call fallback#actions#code_action()<CR>
nnoremap <silent> <leader>cr :call fallback#actions#rename()<CR>
nnoremap <silent> <leader>rn :call fallback#actions#rename()<CR>
nnoremap <silent> <leader>ci :call fallback#actions#import_action()<CR>
nnoremap <silent> <leader>of :call fallback#actions#organize_fix()<CR>
nnoremap <silent> <leader>cf :VimFormat<CR>
nnoremap <silent> [d :call fallback#actions#diagnostic('previous', 'all')<CR>
nnoremap <silent> ]d :call fallback#actions#diagnostic('next', 'all')<CR>
nnoremap <silent> [e :call fallback#actions#diagnostic('previous', 'error')<CR>
nnoremap <silent> ]e :call fallback#actions#diagnostic('next', 'error')<CR>
nnoremap <silent> [w :call fallback#actions#diagnostic('previous', 'warning')<CR>
nnoremap <silent> ]w :call fallback#actions#diagnostic('next', 'warning')<CR>
nnoremap <silent> <leader>cd :call fallback#actions#diagnostic_detail()<CR>

nnoremap <silent> [h :call fallback#actions#git_hunk('previous')<CR>
nnoremap <silent> ]h :call fallback#actions#git_hunk('next')<CR>
nnoremap <silent> <leader>ghs :call fallback#actions#git_hunk('stage')<CR>
nnoremap <silent> <leader>ghr :call fallback#actions#git_hunk('undo')<CR>
nnoremap <silent> <leader>ghp :call fallback#actions#git_hunk('preview')<CR>
nnoremap <silent> <leader>gb :call fallback#actions#git_blame()<CR>
nnoremap <silent> <leader>gs :call fallback#actions#git_status()<CR>
nnoremap <silent> <leader>gd :call fallback#actions#git_diff()<CR>
nnoremap <silent> <leader>p :call fallback#actions#yank_history()<CR>
nnoremap <silent> [y :call fallback#actions#yank_cycle(-1)<CR>
nnoremap <silent> ]y :call fallback#actions#yank_cycle(1)<CR>

nnoremap <silent> <leader>ft :call fallback#terminal#open(1)<CR>
nnoremap <silent> <leader>fT :call fallback#terminal#open(0)<CR>
nnoremap <silent> <C-_> :call fallback#terminal#open(1)<CR>
tnoremap <silent> <Esc><Esc> <C-W>N
tnoremap <silent> <C-h> <C-W>h
tnoremap <silent> <C-j> <C-W>j
tnoremap <silent> <C-k> <C-W>k
tnoremap <silent> <C-l> <C-W>l

nnoremap <silent> <leader>qs :call fallback#actions#session_save()<CR>
nnoremap <silent> <leader>ql :call fallback#actions#session_load()<CR>
nnoremap <silent> <leader>qd :call fallback#actions#session_delete()<CR>
nnoremap <silent> <leader>qS :call fallback#actions#session_select()<CR>

nnoremap <silent> <leader>tt :call fallback#actions#test('file')<CR>
nnoremap <silent> <leader>tT :call fallback#actions#test('all')<CR>
nnoremap <silent> <leader>tr :call fallback#actions#test('nearest')<CR>
nnoremap <silent> <leader>tl :call fallback#actions#test('last')<CR>
nnoremap <silent> <leader>to :call fallback#actions#test('output')<CR>
nnoremap <silent> <leader>tS :call fallback#actions#test('stop')<CR>
nnoremap <silent> <leader>td :call fallback#debug#start()<CR>

nnoremap <silent> <F5> :call fallback#debug#continue()<CR>
nnoremap <silent> <F9> :call fallback#debug#toggle_breakpoint()<CR>
nnoremap <silent> <F10> :call fallback#debug#step('over')<CR>
nnoremap <silent> <F11> :call fallback#debug#step('into')<CR>
nnoremap <silent> <S-F11> :call fallback#debug#step('out')<CR>
nnoremap <silent> <leader>db :call fallback#debug#toggle_breakpoint()<CR>
nnoremap <silent> <leader>dB :call fallback#debug#conditional_breakpoint()<CR>
nnoremap <silent> <leader>dc :call fallback#debug#continue()<CR>
nnoremap <silent> <leader>di :call fallback#debug#step('into')<CR>
nnoremap <silent> <leader>do :call fallback#debug#step('over')<CR>
nnoremap <silent> <leader>dO :call fallback#debug#step('out')<CR>
nnoremap <silent> <leader>dr :call fallback#debug#restart()<CR>
nnoremap <silent> <leader>dt :call fallback#debug#stop()<CR>
nnoremap <silent> <leader>du :call fallback#debug#reset()<CR>
nnoremap <silent> <leader>de :call fallback#debug#evaluate()<CR>

nnoremap <silent> <leader>uf :call fallback#actions#toggle_format('buffer')<CR>
nnoremap <silent> <leader>uF :call fallback#actions#toggle_format('global')<CR>
nnoremap <silent> <leader>us :setlocal spell!<CR>
nnoremap <silent> <leader>uw :setlocal wrap!<CR>
nnoremap <silent> <leader>uL :setlocal relativenumber!<CR>
nnoremap <silent> <leader>ud :call fallback#actions#toggle_diagnostics()<CR>
nnoremap <silent> <leader>ul :setlocal list!<CR>
nnoremap <silent> <leader>vh :VimHealth<CR>

inoremap <silent><expr> <Tab> exists('*coc#pum#visible') && coc#pum#visible()
      \ ? coc#pum#next(1)
      \ : pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> exists('*coc#pum#visible') && coc#pum#visible()
      \ ? coc#pum#prev(1)
      \ : pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <CR> exists('*coc#pum#visible') && coc#pum#visible()
      \ ? coc#pum#confirm()
      \ : "\<C-g>u\<CR>"
