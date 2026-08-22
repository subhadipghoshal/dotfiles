-- Extends the `lang.java` extra (see lazyvim.json) with the multiple JDKs
-- SDKMAN manages on this machine, so jdtls can target a project-specific
-- Java version instead of whatever's on $PATH.
--
-- SDKMAN's shell default is 25.0.3-tem (Temurin 25, LTS) — kept as the
-- jdtls default runtime too, for consistency. Add more entries here as
-- more JDKs get installed via `sdk install java <version>`.
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local home = vim.env.HOME
      opts.settings = opts.settings or {}
      opts.settings.java = opts.settings.java or {}
      opts.settings.java.configuration = opts.settings.java.configuration or {}
      opts.settings.java.configuration.runtimes = {
        {
          name = "JavaSE-25",
          path = home .. "/.sdkman/candidates/java/25.0.3-tem",
          default = true,
        },
        {
          name = "JavaSE-26",
          path = home .. "/.sdkman/candidates/java/26.0.1-tem",
        },
      }
      return opts
    end,
  },
}
