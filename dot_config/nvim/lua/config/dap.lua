-- lua/config/dap-python.lua
local dap = require("dap")

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch current file",
    program = "${file}",
    cwd = vim.fn.getcwd(),
    pythonPath = function()
      if vim.env.VIRTUAL_ENV then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
      end
      return "python"
    end,
  },
}
