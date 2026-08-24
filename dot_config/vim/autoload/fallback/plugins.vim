function! fallback#plugins#install_vimspector(info) abort
  let l:command = [
        \ './install_gadget.py',
        \ '--basedir', g:vimspector_base_dir,
        \ '--enable-go',
        \ '--force-enable-node',
        \ '--force-enable-java',
        \ '--update-gadget-config',
        \ ]
  let l:output = system(l:command)
  if v:shell_error != 0
    throw 'Vimspector gadget installation failed: ' . substitute(l:output, '\n', ' ', 'g')
  endif

  let l:debugpy = exepath('debugpy')
  let l:shebang = empty(l:debugpy) ? '' : get(readfile(l:debugpy, '', 1), 0, '')
  let l:python = substitute(l:shebang, '^#!', '', '')
  if empty(l:python) || !executable(l:python)
    throw 'Vimspector Python adapter requires a debugpy executable with a valid Python shebang.'
  endif

  let l:platform = has('macunix') ? 'macos' : (has('win32') ? 'windows' : 'linux')
  let l:config_dir = g:vimspector_base_dir . '/gadgets/' . l:platform . '/.gadgets.d'
  if !isdirectory(l:config_dir) && mkdir(l:config_dir, 'p', 0700) == 0
    throw 'Unable to create Vimspector gadget config directory: ' . l:config_dir
  endif
  let l:adapter = {
        \ 'adapters': {
        \   'debugpy': {
        \     'command': [l:python, '-m', 'debugpy.adapter'],
        \     'name': 'debugpy',
        \     'configuration': {'python': l:python},
        \     'custom_handler': 'vimspector.custom.python.Debugpy',
        \   },
        \ },
        \ }
  if writefile([json_encode(l:adapter)], l:config_dir . '/debugpy-external.json') != 0
    throw 'Unable to write the Vimspector debugpy adapter configuration.'
  endif
  return l:output
endfunction
