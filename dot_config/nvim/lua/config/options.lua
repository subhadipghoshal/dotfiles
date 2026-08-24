-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.guicursor = "n-v-i-c:block-nCursor,i:blink-Cursor,r-cr:hor20,o:hor50"

vim.cmd([[
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Wq wq
  cnoreabbrev WQ wq
  cnoreabbrev Qa qa
  cnoreabbrev QA qa
  cnoreabbrev Wqa wqa
  cnoreabbrev WQa wqa
  cnoreabbrev WQA wqa
]])
