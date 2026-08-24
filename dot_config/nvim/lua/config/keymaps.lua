-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- LSP keymaps
if vim.g.vscode then
  -- VSCode extension
  local map = vim.keymap.set
  map("n", "<leader>rn", function()
    vim.fn.VSCodeNotify("editor.action.rename")
  end, { desc = "Rename symbol" })
else
  -- ordinary Neovim
  local map = vim.keymap.set
  -- General keymaps
  map("n", ";", ":", { desc = "CMD enter command mode" })
  map("i", "jk", "<ESC>")
  -- Telescope keymaps
  map("n", "<leader>fw", function()
    require("lazyvim.util").pick("live_grep")
  end, { desc = "Live Grep" })
  -- Rename symbols
  map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
end
