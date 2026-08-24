let g:coc_config_home = g:fallback_config_root
let g:coc_data_home = g:fallback_data_dir . '/coc'
let g:coc_disable_startup_warning = 1
let g:coc_global_extensions = [
      \ 'coc-java@1.56.0',
      \ 'coc-java-debug@1.0.0',
      \ 'coc-snippets@3.4.9',
      \ ]

let g:ale_disable_lsp = 1
let g:ale_linters_explicit = 1
let g:ale_lint_on_enter = 0
let g:ale_lint_on_save = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_fix_on_save = 0
let g:ale_set_signs = 1
let g:ale_set_highlights = 0
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_error = 'E'
let g:ale_sign_warning = 'W'
let g:ale_linters = {
      \ 'ansible': ['ansible_lint'],
      \ 'dockerfile': ['hadolint'],
      \ 'go': ['golangci_lint'],
      \ 'javascript': ['eslint'],
      \ 'javascriptreact': ['eslint'],
      \ 'markdown': ['markdownlint'],
      \ 'python': ['ruff'],
      \ 'sh': ['shellcheck'],
      \ 'terraform': ['terraform', 'tflint'],
      \ 'typescript': ['eslint'],
      \ 'typescriptreact': ['eslint'],
      \ }
let g:ale_fixers = {
      \ '*': ['remove_trailing_lines', 'trim_whitespace'],
      \ 'css': ['prettier'],
      \ 'go': ['goimports', 'gofumpt'],
      \ 'html': ['prettier'],
      \ 'javascript': ['prettier'],
      \ 'javascriptreact': ['prettier'],
      \ 'json': ['prettier'],
      \ 'jsonc': ['prettier'],
      \ 'lua': ['stylua'],
      \ 'markdown': ['prettier', 'markdownlint_cli2', 'fallback_markdown_toc'],
      \ 'python': ['ruff', 'ruff_format'],
      \ 'sh': ['shfmt'],
      \ 'terraform': ['terraform'],
      \ 'toml': ['fallback_taplo'],
      \ 'typescript': ['prettier'],
      \ 'typescriptreact': ['prettier'],
      \ 'vue': ['prettier'],
      \ 'yaml': ['prettier'],
      \ }

let g:UltiSnipsExpandTrigger = '<C-l>'
let g:UltiSnipsJumpForwardTrigger = '<C-j>'
let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
let g:test#strategy = 'vimterminal'
let g:test#preserve_screen = 1
let g:vimspector_enable_mappings = ''
" Vim 9.2's bundled Java syntax can emit E28 while including Markdown syntax.
let g:java_ignore_markdown = 1

let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeWinSize = 32
let g:lightline = {
      \ 'colorscheme': 'catppuccin_mocha',
      \ 'active': {
      \   'left': [['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified']],
      \ },
      \ 'component_function': {'gitbranch': 'FugitiveHead'},
      \ }
let g:highlightedyank_highlight_duration = 200
let g:yoinkIncludeDeleteOperations = 1

command! VimHealth call fallback#health#open()
command! VimFormat call fallback#actions#format()
