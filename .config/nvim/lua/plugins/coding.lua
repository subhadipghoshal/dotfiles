return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff", "black", "isort" },
      javascript = { "eslint", "prettierd" },
      typescript = { "eslint", "prettierd" },
      html = { "prettierd" },
      css = { "prettierd" },
      json = { "prettierd" },
      markdown = { "markdownlint", "markdownlint-cli2", "prettierd", "marksman" },
    },
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    config = function()
      local dap_python = require("dap-python")
      -- Choose ONE interpreter. This is where most pain comes from.
      dap_python.setup(".venv/bin/python")
      -- pytest is the only correct answer
      dap_python.test_runner = "unittest"
      -- dap_python.test_runner = "pytest"
    end,
  },
}
