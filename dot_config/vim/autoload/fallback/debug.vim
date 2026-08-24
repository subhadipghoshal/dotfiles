function! s:require_vimspector() abort
  if exists(':VimspectorNewSession') == 2
    return 1
  endif
  call fallback#health#warn_once('Vimspector is unavailable. Run :PlugInstall, then restart Vim.')
  return 0
endfunction

function! s:project_config() abort
  return fallback#root#find() . '/.vimspector.json'
endfunction

function! fallback#debug#start() abort
  if !s:require_vimspector()
    return
  endif
  let l:config = s:project_config()
  if !filereadable(l:config)
    echoerr 'Debugger launch metadata is missing: create ' . l:config
    return
  endif
  execute 'lcd ' . fnameescape(fallback#root#find())
  if &filetype ==# 'java'
    if exists(':CocCommand') != 2
      echoerr 'Java debugging requires Coc with coc-java and coc-java-debug.'
      return
    endif
    CocCommand java.debug.vimspector.start
  else
    call vimspector#Launch()
  endif
endfunction

function! fallback#debug#continue() abort
  if !s:require_vimspector()
    return
  endif
  if exists('g:vimspector_session_windows')
    call vimspector#Continue()
  else
    call fallback#debug#start()
  endif
endfunction

function! fallback#debug#toggle_breakpoint() abort
  if s:require_vimspector()
    call vimspector#ToggleBreakpoint()
  endif
endfunction

function! fallback#debug#conditional_breakpoint() abort
  if s:require_vimspector()
    call vimspector#ToggleBreakpoint({'condition': input('Breakpoint condition: ')})
  endif
endfunction

function! fallback#debug#step(direction) abort
  if !s:require_vimspector()
    return
  endif
  let l:functions = {
        \ 'into': function('vimspector#StepInto'),
        \ 'over': function('vimspector#StepOver'),
        \ 'out': function('vimspector#StepOut'),
        \ }
  if has_key(l:functions, a:direction)
    call l:functions[a:direction]()
  endif
endfunction

function! fallback#debug#restart() abort
  if s:require_vimspector()
    call vimspector#Restart()
  endif
endfunction

function! fallback#debug#stop() abort
  if s:require_vimspector()
    call vimspector#Stop()
  endif
endfunction

function! fallback#debug#reset() abort
  if s:require_vimspector()
    call vimspector#Reset()
  endif
endfunction

function! fallback#debug#evaluate() abort
  if s:require_vimspector()
    call vimspector#Evaluate(input('Evaluate: '))
  endif
endfunction
