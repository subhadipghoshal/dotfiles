function! s:replacement_buffer(target) abort
  for l:buffer in getbufinfo({'buflisted': 1})
    if l:buffer.bufnr != a:target
      return l:buffer.bufnr
    endif
  endfor
  return -1
endfunction

function! fallback#buffer#delete(force) abort
  let l:target = bufnr('%')
  if getbufvar(l:target, '&modified') && !a:force
    echoerr 'Buffer has unsaved changes; save it or use <leader>bD to discard it.'
    return
  endif

  let l:replacement = s:replacement_buffer(l:target)
  if l:replacement < 0
    let l:replacement = bufadd('[Fallback]')
    call bufload(l:replacement)
    call setbufvar(l:replacement, '&buftype', 'nofile')
    call setbufvar(l:replacement, '&bufhidden', 'wipe')
    call setbufvar(l:replacement, '&swapfile', 0)
  endif
  for l:window in win_findbuf(l:target)
    call win_execute(l:window, 'buffer ' . l:replacement)
  endfor

  execute (a:force ? 'bdelete!' : 'bdelete') . ' ' . l:target
endfunction

function! fallback#buffer#only() abort
  let l:current = bufnr('%')
  for l:buffer in getbufinfo({'buflisted': 1})
    if l:buffer.bufnr != l:current && !l:buffer.changed
      execute 'silent bdelete ' . l:buffer.bufnr
    endif
  endfor
endfunction
