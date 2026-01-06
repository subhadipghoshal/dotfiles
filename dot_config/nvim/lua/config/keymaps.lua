-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- General keymaps
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Telescope keymaps

map("n", "<leader>fw", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })

-- LSP keymaps
map("n", "<leader>al", require("lspimport").import, { desc = "Resolve an import" })

-- Rename symbols
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

-- DAP Python keymaps
map("n", "<leader>dtm", function()
  require("dap-python").test_method()
end, { desc = "Debug test method" })

map("n", "<leader>dtc", function()
  require("dap-python").test_class()
end, { desc = "Debug test class" })
