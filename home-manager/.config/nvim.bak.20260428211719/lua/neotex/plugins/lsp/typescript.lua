-- TypeScript/TSX LSP via vtsls
return {
  -- Optional helper plugin with extra TS commands (e.g. :VtsRename, :VtsExec)
  { "yioneko/nvim-vtsls" },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- Prefer vtsls over tsserver/ts_ls
      opts.servers.vtsls = {
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
        end,
        single_file_support = false,
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
            },
          },
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            preferences = { importModuleSpecifier = "non-relative" },
          },
          javascript = {
            inlayHints = { parameterNames = { enabled = "all" } },
          },
        },
      }

      -- Disable old servers if they were configured elsewhere
      opts.setup = opts.setup or {}
      opts.setup.tsserver = function() return true end
      opts.setup.ts_ls = function() return true end

      return opts
    end,
  },
}
