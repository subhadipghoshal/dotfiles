return {
  {
    "nobbmaestro/nvim-andromeda",
    dependencies = { "tjdevries/colorbuddy.nvim" },
    setup = function()
      return {
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
