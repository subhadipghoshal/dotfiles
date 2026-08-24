function! s:require_command(command, feature) abort
  if exists(':' . a:command) == 2
    return 1
  endif
  call fallback#health#warn_once(a:feature . ' is unavailable. Run :PlugInstall, then restart Vim.')
  return 0
endfunction

function! s:workdir(use_root) abort
  return a:use_root ? fallback#root#find() : getcwd()
endfunction

function! s:lcd(directory) abort
  execute 'lcd ' . fnameescape(a:directory)
endfunction

function! fallback#actions#files(use_root) abort
  if !s:require_command('Files', 'File search')
    return
  endif
  call s:lcd(s:workdir(a:use_root))
  Files
endfunction

function! fallback#actions#grep(use_root) abort
  if !s:require_command('Rg', 'Live grep')
    return
  endif
  let l:query = input('Grep: ', expand('<cword>'))
  if empty(l:query)
    return
  endif
  call s:lcd(s:workdir(a:use_root))
  execute 'Rg ' . escape(l:query, ' |')
endfunction

function! fallback#actions#explorer(use_root) abort
  if !s:require_command('NERDTreeToggle', 'File explorer')
    execute 'Lexplore ' . fnameescape(s:workdir(a:use_root))
    return
  endif
  execute 'NERDTreeToggle ' . fnameescape(s:workdir(a:use_root))
endfunction

function! s:coc_ready() abort
  if exists('*coc#rpc#ready') && coc#rpc#ready()
    return 1
  endif
  call fallback#health#warn_once('Coc is unavailable. Run :PlugInstall and :CocUpdateSync, then restart Vim.')
  return 0
endfunction

function! fallback#actions#coc(action) abort
  if s:coc_ready()
    call CocActionAsync(a:action)
  endif
endfunction

function! fallback#actions#hover() abort
  if s:coc_ready()
    call CocActionAsync('doHover')
  else
    execute 'normal! K'
  endif
endfunction

function! fallback#actions#rename() abort
  if s:coc_ready()
    call CocActionAsync('rename')
  endif
endfunction

function! fallback#actions#code_action() abort
  if s:coc_ready()
    call feedkeys("\<Plug>(coc-codeaction-cursor)", 'm')
  endif
endfunction

function! fallback#actions#import_action() abort
  if s:coc_ready()
    call CocActionAsync('doQuickfix')
  endif
endfunction

function! fallback#actions#organize_fix() abort
  if !s:coc_ready()
    return
  endif
  call CocAction('organizeImport')
  call CocActionAsync('fixAll')
endfunction

function! fallback#actions#lint() abort
  if exists(':ALELint') == 2 && &buftype ==# '' && filereadable(expand('%:p'))
    silent ALELint
  endif
endfunction

function! fallback#actions#format() abort
  if s:require_command('ALEFix', 'Formatting')
    ALEFix
  endif
endfunction

function! fallback#actions#markdown_toc_fixer(buffer) abort
  return {
        \ 'command': ale#Escape('markdown-toc') . ' -i %t',
        \ 'read_temporary_file': 1,
        \ }
endfunction

function! fallback#actions#taplo_fixer(buffer) abort
  return {'command': ale#Escape('taplo') . ' format -'}
endfunction

function! fallback#actions#toggle_format(scope) abort
  if a:scope ==# 'buffer'
    let b:ale_fix_on_save = !get(b:, 'ale_fix_on_save', get(g:, 'ale_fix_on_save', 0))
    echom 'Buffer format-on-save: ' . (b:ale_fix_on_save ? 'on' : 'off')
  else
    let g:ale_fix_on_save = !get(g:, 'ale_fix_on_save', 0)
    echom 'Global format-on-save: ' . (g:ale_fix_on_save ? 'on' : 'off')
  endif
endfunction

function! fallback#actions#toggle_diagnostics() abort
  let g:ale_set_signs = !get(g:, 'ale_set_signs', 1)
  if exists(':ALEEnable') == 2
    execute g:ale_set_signs ? 'ALEEnable' : 'ALEDisable'
  endif
  echom 'ALE diagnostics: ' . (g:ale_set_signs ? 'on' : 'off')
endfunction

function! fallback#actions#diagnostic(direction, severity) abort
  let l:command = a:direction ==# 'next' ? 'ALENextWrap' : 'ALEPreviousWrap'
  if !s:require_command(l:command, 'Diagnostics')
    return
  endif
  if a:severity ==# 'all'
    execute l:command
  else
    execute l:command . ' -' . a:severity
  endif
endfunction

function! fallback#actions#diagnostic_detail() abort
  if s:require_command('ALEDetail', 'Diagnostics')
    ALEDetail
  endif
endfunction

function! fallback#actions#git_hunk(action) abort
  let l:commands = {
        \ 'next': 'GitGutterNextHunk', 'previous': 'GitGutterPrevHunk',
        \ 'stage': 'GitGutterStageHunk', 'undo': 'GitGutterUndoHunk',
        \ 'preview': 'GitGutterPreviewHunk',
        \ }
  let l:command = get(l:commands, a:action, '')
  if !empty(l:command) && s:require_command(l:command, 'Git hunks')
    execute l:command
  endif
endfunction

function! fallback#actions#git_status() abort
  if s:require_command('Git', 'Git integration')
    call s:lcd(fallback#root#find())
    Git
  endif
endfunction

function! fallback#actions#git_blame() abort
  if s:require_command('Git', 'Git integration')
    Git blame
  endif
endfunction

function! fallback#actions#git_diff() abort
  if s:require_command('Gdiffsplit', 'Git integration')
    Gdiffsplit
  endif
endfunction

function! fallback#actions#yank_history() abort
  if s:require_command('Yanks', 'Yank history')
    Yanks
  endif
endfunction

function! fallback#actions#yank_cycle(direction) abort
  if exists(':Yanks') == 2
    call yoink#rotate(a:direction)
  else
    call fallback#health#warn_once('Yank cycling is unavailable. Run :PlugInstall, then restart Vim.')
  endif
endfunction

function! s:session_path() abort
  return g:fallback_session_dir . '/' . sha256(fallback#root#find()) . '.vim'
endfunction

function! fallback#actions#session_save() abort
  let l:path = s:session_path()
  execute 'mksession! ' . fnameescape(l:path)
  let g:fallback_active_session = l:path
  echom 'Session saved: ' . l:path
endfunction

function! fallback#actions#session_load() abort
  let l:path = s:session_path()
  if !filereadable(l:path)
    echoerr 'No session exists for project root: ' . fallback#root#find()
    return
  endif
  execute 'source ' . fnameescape(l:path)
  let g:fallback_active_session = l:path
endfunction

function! fallback#actions#session_delete() abort
  let l:path = s:session_path()
  if filereadable(l:path) && delete(l:path) != 0
    echoerr 'Unable to delete session: ' . l:path
    return
  endif
  unlet! g:fallback_active_session
  echom 'Session deleted: ' . l:path
endfunction

function! fallback#actions#session_select() abort
  let l:sessions = glob(g:fallback_session_dir . '/*.vim', 0, 1)
  if empty(l:sessions)
    echoerr 'No fallback Vim sessions exist.'
    return
  endif
  let l:choices = ['Select session:'] + map(copy(l:sessions), 'printf("%d. %s", v:key + 1, v:val)')
  let l:selected = inputlist(l:choices)
  if l:selected > 0 && l:selected <= len(l:sessions)
    execute 'source ' . fnameescape(l:sessions[l:selected - 1])
    let g:fallback_active_session = l:sessions[l:selected - 1]
  endif
endfunction

function! fallback#actions#session_autosave() abort
  if exists('g:fallback_active_session') && len(getbufinfo({'buflisted': 1})) > 0
    execute 'silent! mksession! ' . fnameescape(g:fallback_active_session)
  endif
endfunction

function! fallback#actions#test(kind) abort
  if a:kind ==# 'output'
    if !exists('g:fallback_test_buffer') || !bufexists(g:fallback_test_buffer)
      echoerr 'No fallback Vim test output exists.'
      return
    endif
    execute 'sbuffer ' . g:fallback_test_buffer
    return
  endif
  if a:kind ==# 'stop'
    if !exists('g:fallback_test_buffer') || !bufexists(g:fallback_test_buffer)
      echoerr 'No fallback Vim test job is running.'
      return
    endif
    let l:job = term_getjob(g:fallback_test_buffer)
    if job_status(l:job) ==# 'run'
      call job_stop(l:job)
    endif
    return
  endif

  let l:commands = {
        \ 'file': 'TestFile', 'all': 'TestSuite', 'nearest': 'TestNearest',
        \ 'last': 'TestLast',
        \ }
  let l:command = get(l:commands, a:kind, '')
  if empty(l:command) || !s:require_command(l:command, 'Test runner')
    return
  endif
  call s:lcd(fallback#root#find())
  execute l:command
  for l:buffer in reverse(getbufinfo({'bufloaded': 1}))
    if getbufvar(l:buffer.bufnr, '&buftype') ==# 'terminal'
      let g:fallback_test_buffer = l:buffer.bufnr
      break
    endif
  endfor
endfunction
