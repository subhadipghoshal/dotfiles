-- yazi.nvim: floating file manager, replacing the snacks.nvim explorer as the
-- primary <leader>e destination. snacks explorer stays reachable on <leader>fe
-- / <leader>fE (untouched, still wired by the snacks_explorer extra) for the
-- sidebar-tree style when that's what's wanted instead.
--
-- <leader>- (yazi.nvim's own suggested default) is not used here - LazyVim
-- core already owns it for "Split Window Below"
-- (LazyVim/lua/lazyvim/config/keymaps.lua:199) - remapping it would be a
-- surprise every time that split muscle memory fires.
return {
  {
    -- release <leader>e before yazi.nvim claims it below. Registering the
    -- same lhs in two specs without freeing it first makes the winner
    -- depend on lazy.nvim's load order rather than on what's written here.
    "folke/snacks.nvim",
    optional = true,
    keys = {
      { "<leader>e", false },
    },
  },
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- open_for_directories replaces netrw with yazi for `nvim <dir>` /
    -- `:e <dir>`. Safe to enable here specifically because neo-tree isn't
    -- installed - its hijack_netrw_behavior would otherwise race yazi for
    -- the same directory-open event. netrw disabled per yazi.nvim's own
    -- README note (github.com/mikavilpas/yazi.nvim, issue #802).
    init = function()
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      open_for_directories = true,
      keymaps = {
        show_help = "<f1>",
      },
    },
    keys = {
      { "<leader>e", "<cmd>Yazi<cr>", desc = "Open yazi (current file)" },
      { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open yazi (nvim's cwd)" },
      { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
    },
  },
}
