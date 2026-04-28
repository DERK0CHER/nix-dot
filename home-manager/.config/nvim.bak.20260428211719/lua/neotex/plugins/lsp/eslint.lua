-- ESLint LSP (diagnostics, quick fixes, rule docs)
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  opts = function(_, opts)
    opts.servers = opts.servers or {}

    local util = require("lspconfig.util")
    local root_with_eslint = util.root_pattern(
      ".eslintrc",
      ".eslintrc.cjs",
      ".eslintrc.js",
      ".eslintrc.json",
      "eslint.config.js",
      "eslint.config.cjs",
      "eslint.config.mjs",
      "package.json",
      ".git"
    )

    opts.servers.eslint = {
      root_dir = root_with_eslint,
      settings = {
        -- Don’t let ESLint do full formatting; we’ll use Conform below
        format = false,
        codeAction = {
          disableRuleComment = { enable = true },
          showDocumentation = { enable = true },
        },
        -- If you use pnpm/yarn, set this accordingly (optional):
        -- packageManager = "pnpm",
      },
    }

    return opts
  end,
}
