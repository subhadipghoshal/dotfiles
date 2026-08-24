function! fallback#terminal#open(use_root) abort
  if !has('terminal')
    echoerr 'This Vim build has no terminal support.'
    return
  endif

  let l:directory = a:use_root ? fallback#root#find() : getcwd()
  execute 'botright new ' . fnameescape('[Fallback Terminal]')
  execute 'lcd ' . fnameescape(l:directory)
  terminal ++curwin
  startinsert
endfunction
