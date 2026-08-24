-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Formatting on save is handled by LazyVim's LazyFormat autocmd (conform +
-- the eslint LSP formatter); do not add another BufWritePre format here.
--
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.keymap.set("n", "<leader>of", function()
      vim.lsp.buf.code_action({
        context = {
          only = {
            "source.organizeImports",
            "source.fixAll",
          },
        },
        apply = true,
      })
    end, {
      buffer = ev.buf,
      desc = "LSP: organize imports / fix",
    })
  end,
})
