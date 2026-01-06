-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})

-- Delete trailing whitespace on save, but not in Markdown where spacing = vibes
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = { "*" },
--   callback = function()
--     if vim.bo.filetype ~= "markdown" then
--       vim.cmd([[%s/\s\+$//e]])
--     end
--   end,
-- })

-- Auto-run GoImports on save if available
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    vim.cmd("silent! GoImports")
  end,
})

-- ESLint auto-fix on save for JS/TS/React projects
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    vim.cmd("silent! EslintFixAll")
  end,
})

local group = vim.api.nvim_create_augroup("PythonWorkflow", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = "*.py",
  callback = function()
    pcall(vim.cmd, "silent! RuffFix")
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*/tests/*.py",
  callback = function()
    vim.cmd("silent! !pytest -q %")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  callback = function()
    vim.opt_local.scrollbind = false
  end,
})
