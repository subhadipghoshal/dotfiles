return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        -- ruff_format is a drop-in black replacement and ruff_organize_imports
        -- replaces isort; both ship in the same tool, so black/isort are unneeded.
        -- JS/TS/YAML/JSON/Markdown formatting comes from the formatting.prettier
        -- and lang.markdown extras.
        python = { "ruff_organize_imports", "ruff_format" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      -- Lint on open and save only; running on every InsertLeave is noise
      opts.events = { "BufWritePost", "BufReadPost" }
      opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
        -- nvim-lint resolves dotted filetypes part-by-part, so "ansible"
        -- matches yaml.ansible buffers without touching plain yaml
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        ansible = { "ansible_lint" },
        -- Global linters apply to all filetypes, then conditions filter them;
        -- used here because workflow yaml has no dedicated filetype
        ["*"] = { "actionlint" },
      })
      opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
        actionlint = {
          ---Only lint GitHub Actions workflow files
          ---@param ctx {filename: string}
          condition = function(ctx)
            -- plain-text find: no pattern escaping wanted here
            return ctx.filename:find(".github/workflows/", 1, true) ~= nil
              or ctx.filename:find(".gitea/workflows/", 1, true) ~= nil
          end,
        },
      })
    end,
  },
}
