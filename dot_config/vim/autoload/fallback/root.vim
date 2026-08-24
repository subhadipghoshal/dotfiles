let s:markers = [
      \ '.git', '.hg', '.svn',
      \ 'go.work', 'go.mod', 'package.json', 'pyproject.toml',
      \ 'Cargo.toml', 'pom.xml', 'build.gradle', 'settings.gradle',
      \ 'terraform.tf', '.terraform', 'Makefile', '.project-root',
      \ ]

function! fallback#root#find(...) abort
  if exists('b:fallback_root') && isdirectory(b:fallback_root)
    return fnamemodify(b:fallback_root, ':p:h')
  endif

  let l:start = a:0 ? a:1 : expand('%:p')
  if empty(l:start)
    let l:start = getcwd()
  endif
  let l:directory = isdirectory(l:start) ? fnamemodify(l:start, ':p') : fnamemodify(l:start, ':p:h')

  while !empty(l:directory)
    for l:marker in s:markers
      if isdirectory(l:directory . '/' . l:marker) || filereadable(l:directory . '/' . l:marker)
        return substitute(l:directory, '/$', '', '')
      endif
    endfor
    let l:parent = fnamemodify(l:directory, ':h')
    if l:parent ==# l:directory
      break
    endif
    let l:directory = l:parent
  endwhile

  return getcwd()
endfunction
