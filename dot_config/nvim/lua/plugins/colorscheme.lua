return {
  {
    "nobbmaestro/nvim-andromeda",
    lazy = true,
    dependencies = { "tjdevries/colorbuddy.nvim" },
    config = function()
      local andromeda = require("andromeda")
      local custom_opts = {
        preset = "andromeda",
        colors = {
          background = "#0f111a",
          mono_1 = "#2f323c", -- secondary background and/or highlighting
          mono_2 = "#3a3e4b", -- used for highlighting
          mono_3 = "#464959", -- used for highlighting
          mono_4 = "#606064",
          mono_5 = "#a0a1a7", -- comments
          mono_6 = "#d5ced9", -- normal text
        },
      }
      -- colors/andromeda.lua (sourced by every `:colorscheme andromeda`, including
      -- the one lazy.nvim's own colorscheme-triggered load runs) calls
      -- `require("andromeda").setup()` with no args, which would otherwise reset
      -- these colors to preset defaults. Wrap setup so that call still gets them.
      local orig_setup = andromeda.setup
      andromeda.setup = function(opts)
        orig_setup(vim.tbl_deep_extend("force", custom_opts, opts or {}))
      end
      andromeda.setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
      -- Add theme-specific options here if needed, e.g., for TokyoNight:
      -- style = "moon",
    },
  },
}
