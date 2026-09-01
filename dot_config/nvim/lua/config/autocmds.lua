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

-- Prose buffers. LazyVim already sets `wrap` and `spell` for these filetypes;
-- add what it leaves out. `comments` + formatoptions "ro" continues list and
-- checkbox markers on <CR> and o, which is the dependency-free stand-in for a
-- bullets plugin. Checkbox toggling itself comes from the editor.dial extra
-- (<C-a> / <C-x>).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("md_prose", { clear = true }),
  pattern = { "markdown", "markdown.mdx", "text" },
  callback = function(ev)
    local o = vim.opt_local
    -- harper_ls owns spelling for these filetypes and, unlike Vim's speller,
    -- it skips code spans, fenced blocks and link URLs. Running both means two
    -- squiggles under every backticked technical term, so keep only harper.
    o.spell = false
    o.breakindent = true -- wrapped lines keep their list indentation
    o.showbreak = "↳ "
    o.textwidth = 0 -- never hard-wrap; prettier owns line width
    o.conceallevel = 2 -- required by render-markdown.nvim
    o.concealcursor = "" -- reveal raw text on the cursor line
    o.comments = "b:- [ ],b:- [x],b:-,b:*,b:+,b:>,n:1."
    o.formatoptions:append("ro")
    o.formatoptions:remove("t") -- don't auto-wrap while typing
    -- Move by visual line, so j/k behave on wrapped prose.
    local map = function(lhs, rhs)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, expr = true, desc = "Move by visual line" })
    end
    map("j", function()
      return vim.v.count == 0 and "gj" or "j"
    end)
    map("k", function()
      return vim.v.count == 0 and "gk" or "k"
    end)
  end,
})
