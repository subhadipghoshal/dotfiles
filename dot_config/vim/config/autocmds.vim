augroup fallback_vim
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line('$') | execute 'normal! g`"' | endif
  autocmd BufReadPost,BufWritePost * call fallback#actions#lint()
  autocmd VimLeavePre * call fallback#actions#session_autosave()
  autocmd BufRead,BufNewFile docker-compose*.yml,docker-compose*.yaml,compose.yml,compose.yaml setfiletype yaml.docker-compose
  autocmd BufRead,BufNewFile */playbooks/*.yml,*/playbooks/*.yaml,*/roles/*/tasks/*.yml,*/roles/*/tasks/*.yaml setfiletype yaml.ansible
  autocmd BufRead,BufNewFile */.github/workflows/*.yml,*/.github/workflows/*.yaml,*/.gitea/workflows/*.yml,*/.gitea/workflows/*.yaml setfiletype yaml.github-actions
  autocmd FileType yaml.github-actions let b:ale_linters = ['actionlint']
  autocmd FileType yaml.ansible let b:ale_linters = ['ansible_lint']
  autocmd FileType netrw nnoremap <buffer> l <CR>
augroup END

let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
