-- Markdown ecosystem: quiet diagnostics, real in-buffer rendering, prose
-- linting that stays out of the way, and authoring help.
--
-- Division of labour:
--   render-markdown.nvim  owns ALL in-buffer rendering (obsidian.nvim's own UI
--                         layer is disabled; two extmark providers on one
--                         buffer fight each other).
--   marksman              links, refs, document symbols.
--   harper-ls             prose grammar, pinned to prose filetypes only.
--   markdownlint-cli2     structural lint, against a repo-wide baseline.
--   prettier              formatting, via LazyVim's single BufWritePre pipeline.

-- markdownlint-cli2 never resolves a config file above the process CWD, and
-- nvim-lint pipes the buffer over stdin, which carries no file location. So a
-- machine-wide baseline only works if we pass --config ourselves. A project
-- that ships its own config still wins: prefer the nearest one, fall back to
-- the repo baseline.
local MD_CONFIG_NAMES = {
  ".markdownlint-cli2.jsonc",
  ".markdownlint-cli2.yaml",
  ".markdownlint-cli2.cjs",
  ".markdownlint-cli2.mjs",
  ".markdownlint.jsonc",
  ".markdownlint.json",
  ".markdownlint.yaml",
  ".markdownlint.yml",
}

local function markdownlint_config(path)
  local start = (path and path ~= "") and vim.fs.dirname(path) or vim.fn.getcwd()
  local found = vim.fs.find(MD_CONFIG_NAMES, { path = start, upward = true, type = "file" })[1]
  return found or (vim.fn.stdpath("config") .. "/markdownlint.jsonc")
end

-- Run a one-shot export and report where the artifact landed. Build steps do
-- not need a persistent terminal; presenterm below does, and uses Snacks.
local function export(args, out)
  local src = vim.api.nvim_buf_get_name(0)
  if src == "" then
    return vim.notify("Buffer has no file on disk", vim.log.levels.WARN)
  end
  local target = out and (vim.fn.fnamemodify(src, ":r") .. out) or nil
  vim.notify("Exporting " .. vim.fn.fnamemodify(src, ":t") .. " ...", vim.log.levels.INFO)
  vim.system(vim.list_extend(vim.deepcopy(args), { src }), { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        vim.notify("Wrote " .. (target or "output"), vim.log.levels.INFO)
      else
        vim.notify((res.stderr ~= "" and res.stderr or res.stdout or "export failed"), vim.log.levels.ERROR)
      end
    end)
  end)
end

-- ~/vaults/publish is the content contract for an Astro portfolio and blog:
-- typed YAML frontmatter, no obsidian bookkeeping. Keep every field the
-- templates define, bump `updated`, derive `slug` from the filename, and never
-- inject obsidian's id/aliases/tags into a file the site parses. Notes outside
-- that vault get obsidian's stock behaviour.
local PUBLISH_VAULT = vim.fs.normalize(vim.fn.expand("~/vaults/publish"))

local function publish_frontmatter(note)
  local path = vim.fs.normalize(tostring(note.path or ""))
  if not vim.startswith(path, PUBLISH_VAULT) then
    return require("obsidian.builtin").frontmatter(note)
  end
  local out = vim.deepcopy(note.metadata or {})
  out.slug = vim.fn.fnamemodify(path, ":t:r")
  out.updated = os.date("%Y-%m-%d")
  out.created = out.created or out.updated
  return out
end

return {
  -- Prose linters mark position (sign + underline) but never shout in virtual
  -- text; a squiggle per prose line is what made markdown feel adversarial.
  -- Read the full message with <leader>cd.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local quiet = { markdownlint = true, ["harper-ls"] = true, Harper = true }
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          format = function(d)
            if quiet[d.source] then
              return nil
            end
            return d.message
          end,
        },
      })
    end,
  },

  -- Grammar and spelling for prose. Upstream nvim-lspconfig ships ~30
  -- filetypes for harper_ls including lua/go/python/java/sh; accepting that
  -- would grammar-check every code comment on the machine. Prose only.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        harper_ls = {
          filetypes = { "markdown", "markdown.mdx", "gitcommit", "text" },
          settings = {
            ["harper-ls"] = {
              userDictPath = vim.fn.stdpath("config") .. "/spell/harper-dict.txt",
              dialect = "American",
              markdown = { IgnoreLinkTitle = true },
              -- Hint severity + the virtual_text filter above means harper
              -- underlines a span and offers a code action, nothing louder.
              diagnosticSeverity = "hint",
              isolateEnglish = false,
              -- Rule names are harper's own codes. To find the name for
              -- anything noisy, put the cursor on it and read the `code`
              -- field: :lua =vim.diagnostic.get(0)[1].code
              -- Rules not named here keep their upstream default (mostly on),
              -- which is why repeated-word detection still fires.
              linters = {
                SpellCheck = true, -- false positives go in spell/harper-dict.txt
                MissingTo = true, -- real grammar: "want <to> do"
                AnA = true, -- a/an agreement, high precision
                -- Off: capitalisation, vocabulary and length opinions that are
                -- simply wrong about technical prose. Each of these was
                -- observed firing on AGENTS.md or the publish vault.
                OrthographicConsistency = false, -- "yaml" -> "YAML"
                SplitWords = false, -- mangles technical compounds
                UseTitleCase = false, -- sentence-case headings are deliberate
                DisjointPrefixes = false, -- "re-run" -> "rerun"
                ExpandConfiguration = false, -- "config" is correct usage
                ExpandTimeShorthands = false, -- "min" -> "minute"
                ExpandControl = false, -- "ctrl" -> "control"
                SentenceCapitalization = false, -- list items and cells are not sentences
                LongSentences = false, -- technical prose earns its long sentences
                PhrasalVerbAsCompoundNoun = false, -- "set up" vs "setup" churn
                MassNouns = false, -- wrong about "diagnostics", "docs"
              },
            },
          },
        },
      },
    },
  },

  -- Point both markdownlint entry points at the resolved config.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
        ["markdownlint-cli2"] = {
          args = {
            "--config",
            function()
              return markdownlint_config(vim.api.nvim_buf_get_name(0))
            end,
            "-",
          },
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          prepend_args = function(_, ctx)
            return { "--config", markdownlint_config(ctx.filename) }
          end,
        },
      },
    },
  },

  -- LazyVim's extra strips render-markdown down to almost nothing
  -- (heading.icons = {}, checkbox.enabled = false). Restore the parts that
  -- make a buffer readable at a glance.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "block",
        left_pad = 0,
        right_pad = 2,
      },
      checkbox = {
        enabled = true,
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          important = { raw = "[!]", rendered = "󰀦 ", highlight = "DiagnosticWarn" },
          cancelled = { raw = "[~]", rendered = "󰜺 ", highlight = "Comment" },
        },
      },
      pipe_table = { style = "full", alignment_indicator = "━" },
      -- YAML frontmatter is the publish vault's content contract; keep it
      -- plainly readable rather than concealed.
      yaml = { enabled = false },
      -- latex rendering needs latex2text, which is not installed.
      latex = { enabled = false },
      sign = { enabled = false },
      -- anti_conceal and render_modes stay at their defaults: raw text comes
      -- back on the cursor line and in insert mode, so editing stays honest.
    },
  },

  -- prettier aligns tables, but only on save. Table mode aligns as you type
  -- the closing pipe, which is the actual authoring win for docs like
  -- AGENTS.md. The overlap is intentional and harmless.
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown", "markdown.mdx" },
    cmd = { "TableModeToggle", "TableModeEnable", "TableModeRealign" },
    keys = {
      { "<leader>mt", "<cmd>TableModeToggle<cr>", ft = "markdown", desc = "Table Mode" },
      { "<leader>mT", "<cmd>TableModeRealign<cr>", ft = "markdown", desc = "Realign Table" },
    },
    init = function()
      vim.g.table_mode_corner = "|" -- GFM-compatible corners
    end,
  },

  -- obsidian.nvim as a template and frontmatter engine for ~/vaults/publish,
  -- NOT as a renderer. Migrated off the archived epwalsh repo (v3.9.0,
  -- 2024-07-11) to the maintained fork.
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Scoped to the vaults. The old spec used ft = "markdown", which spun the
    -- client up in every README on the machine for no benefit.
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/vaults/*/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/vaults/*/**.md",
    },
    cmd = "Obsidian",
    keys = {
      { "<leader>m", "", desc = "+markdown", mode = { "n", "v" } },
      { "<leader>mn", "<cmd>Obsidian new_from_template<cr>", desc = "New From Template" },
      { "<leader>mo", "<cmd>Obsidian quick_switch<cr>", desc = "Open Note" },
      { "<leader>ms", "<cmd>Obsidian search<cr>", desc = "Search Vault" },
      { "<leader>mb", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>mi", "<cmd>Obsidian paste_img<cr>", desc = "Paste Image" },
      { "<leader>mw", "<cmd>Obsidian workspace<cr>", desc = "Switch Vault" },
      { "<leader>mD", "<cmd>Obsidian today<cr>", desc = "Daily Note" },
      { "<leader>mx", "<cmd>Obsidian extract_note<cr>", mode = "v", desc = "Extract To New Note" },
    },
    opts = {
      legacy_commands = false,
      -- strict pins each vault root to its own path. Without it obsidian walks
      -- up to ~/vaults, which is itself a git repo (logseq's git plugin), and
      -- collapses all three vaults into one.
      workspaces = {
        { name = "personal", path = "~/vaults/personal", strict = true },
        { name = "publish", path = "~/vaults/publish", strict = true },
        { name = "work", path = "~/vaults/work", strict = true },
      },
      -- render-markdown.nvim owns rendering. Leaving this on puts two extmark
      -- providers on the same buffer, which is what the old config did.
      ui = { enable = false },
      picker = { name = "snacks.picker" },
      completion = { min_chars = 2 },
      link = { style = "wiki" },
      attachments = { folder = "assets/img" },
      daily_notes = {
        folder = "Journal",
        -- Moment-style, not strftime. Matches the existing Journal/2025_12_01.md.
        date_format = "YYYY_MM_DD",
        workdays_only = false,
      },
      -- The active workspace is picked once at startup (from cwd, else the
      -- first entry) and only changes via <leader>mw. So keep templates global
      -- rather than a per-workspace override: publish has templates/, the
      -- other vaults simply have none.
      templates = { folder = "templates", date_format = "YYYY-MM-DD", time_format = "HH:mm" },
      frontmatter = {
        func = publish_frontmatter,
        -- Template field order, so a saved note still reads like the template.
        sort = {
          "title",
          "slug",
          "description",
          "type",
          "status",
          "topics",
          "published",
          "newsletter",
          "featured",
          "created",
          "updated",
          "source_notes",
        },
      },
    },
  },

  -- Export and slides. pandoc renders PDF through typst (no TeX install);
  -- presenterm runs slides in the terminal; marp is for decks that leave the
  -- machine and needs no global install.
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>mep",
        function()
          export({ "pandoc", "--pdf-engine=typst", "-o", vim.fn.expand("%:r") .. ".pdf" }, ".pdf")
        end,
        ft = "markdown",
        desc = "Export PDF",
      },
      {
        "<leader>meh",
        function()
          export({ "pandoc", "--standalone", "--embed-resources", "-o", vim.fn.expand("%:r") .. ".html" }, ".html")
        end,
        ft = "markdown",
        desc = "Export HTML",
      },
      {
        "<leader>mem",
        function()
          export({ "bunx", "@marp-team/marp-cli", "--pdf", "--allow-local-files" }, ".pdf")
        end,
        ft = "markdown",
        desc = "Export Marp Deck",
      },
      {
        "<leader>mes",
        function()
          Snacks.terminal.toggle({ "presenterm", vim.api.nvim_buf_get_name(0) }, { title = "Slides" })
        end,
        ft = "markdown",
        desc = "Present Slides",
      },
    },
    -- Inline images. Ghostty speaks the Kitty graphics protocol; tmux needs
    -- allow-passthrough on, or nothing renders and nothing errors.
    opts = {
      image = {
        enabled = true,
        doc = { enabled = true, inline = true, float = true, max_width = 80, max_height = 40 },
      },
    },
  },
}
