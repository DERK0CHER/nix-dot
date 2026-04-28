-- Tailwind CSS LSP (tailwindcss-language-server)
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- Tailwind v3/v4 friendly root_dir:
      -- supports projects without a tailwind.config.* by checking package.json
      local util = require("lspconfig.util")
      local function has_tailwind_in_pkg_json(root)
        local pkg = util.path.join(root, "package.json")
        if not vim.uv.fs_stat(pkg) then return false end
        local ok, data = pcall(vim.fn.readfile, pkg)
        if not ok then return false end
        local str = table.concat(data, "\n")
        return str:match('"tailwindcss"%s*:') ~= nil
      end

      opts.servers.tailwindcss = {
        root_dir = function(fname)
          local root = util.root_pattern(
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.ts",
            "package.json",
            ".git"
          )(fname)
          -- If no explicit config, require tailwind in package.json (helps TW v4)
          if root and has_tailwind_in_pkg_json(root) then
            return root
          end
          -- Fallback to configs if present
          return util.root_pattern(
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.ts"
          )(fname)
        end,
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                -- add framework-specific regex here if you need it
              },
            },
          },
        },
      }

      return opts
    end,
  },
}
