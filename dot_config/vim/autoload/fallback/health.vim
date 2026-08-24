let s:warnings = {}

function! fallback#health#warn_once(message) abort
  if has_key(s:warnings, a:message)
    return
  endif
  let s:warnings[a:message] = 1
  echohl WarningMsg
  echom '[fallback-vim] ' . a:message
  echohl None
endfunction

function! s:status(label, ok, detail) abort
  return printf('%s %-28s %s', a:ok ? 'OK     ' : 'MISSING', a:label, a:detail)
endfunction

function! s:executable_lines(title, names) abort
  let l:lines = ['', a:title]
  for l:name in a:names
    let l:path = exepath(l:name)
    call add(l:lines, s:status(l:name, !empty(l:path), empty(l:path) ? 'not on PATH' : l:path))
  endfor
  return l:lines
endfunction

function! s:gadget_lines() abort
  let l:platform = has('macunix') ? 'macos' : (has('win32') ? 'windows' : 'linux')
  let l:directory = g:vimspector_base_dir . '/gadgets/' . l:platform
  let l:configs = glob(l:directory . '/.gadgets.json', 0, 1)
        \ + glob(l:directory . '/.gadgets.d/*.json', 0, 1)
  let l:content = ''
  for l:path in l:configs
    let l:content .= join(readfile(l:path), "\n")
  endfor
  let l:lines = ['', 'Vimspector adapters']
  for [l:label, l:key] in [
        \ ['Python (debugpy)', 'debugpy'],
        \ ['Go (delve)', 'delve'],
        \ ['Node (js-debug)', 'js-debug'],
        \ ['Java (vscode-java)', 'vscode-java'],
        \ ]
    let l:ok = l:content =~# '"' . l:key . '"'
    call add(l:lines, s:status(l:label, l:ok, l:ok ? l:directory : 'run :PlugUpdate vimspector'))
  endfor
  return l:lines
endfunction

function! fallback#health#lines() abort
  let l:lines = [
        \ 'Fallback Vim health',
        \ '===================',
        \ s:status('Vim >= 9.2', v:version >= 902, execute('version')->split("\n")[0]),
        \ s:status('config root', isdirectory(g:fallback_config_root), g:fallback_config_root),
        \ s:status('plugin root', isdirectory(g:fallback_plug_home), g:fallback_plug_home),
        \ s:status('state root', isdirectory(g:fallback_state_dir), g:fallback_state_dir),
        \ s:status('vim-plug', exists('*plug#begin'), g:fallback_config_root . '/autoload/plug.vim'),
        \ s:status('Coc', exists(':CocInfo') == 2, 'LSP/completion/actions'),
        \ s:status('ALE', exists(':ALEInfo') == 2, 'lint/format/diagnostics'),
        \ s:status('Vimspector', exists(':VimspectorNewSession') == 2, 'debugger UI'),
        \ ]

  call extend(l:lines, s:executable_lines('Language servers', [
        \ 'ansible-language-server', 'bash-language-server',
        \ 'docker-compose-langserver', 'docker-langserver', 'gopls', 'helm_ls',
        \ 'lua-language-server', 'marksman', 'pyright-langserver',
        \ 'ruff', 'taplo', 'terraform-ls', 'vscode-eslint-language-server',
        \ 'vscode-json-language-server', 'vtsls', 'yaml-language-server',
        \ ]))
  call extend(l:lines, s:executable_lines('Formatters and linters', [
        \ 'actionlint', 'ansible-lint', 'gofumpt', 'goimports', 'golangci-lint',
        \ 'hadolint', 'markdown-toc', 'markdownlint-cli2', 'prettier', 'ruff',
        \ 'shellcheck', 'shfmt', 'stylua', 'taplo', 'terraform', 'tflint',
        \ ]))
  call extend(l:lines, s:executable_lines('Debugger prerequisites', [
        \ 'debugpy', 'java', 'node', 'python3',
        \ ]))
  call extend(l:lines, s:gadget_lines())

  let l:launch = fallback#root#find() . '/.vimspector.json'
  call add(l:lines, '')
  call add(l:lines, 'Current project')
  call add(l:lines, s:status('debug launch metadata', filereadable(l:launch), l:launch))
  return l:lines
endfunction

function! fallback#health#open() abort
  execute 'botright new ' . fnameescape('[Fallback Vim Health]')
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal filetype=fallbackhealth
  call setline(1, fallback#health#lines())
  setlocal nomodifiable
  normal! gg
endfunction
