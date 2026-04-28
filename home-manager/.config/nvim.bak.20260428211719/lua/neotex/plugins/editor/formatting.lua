-----------------------------------------------------------
-- Conform.nvim Integration (fixed autoformat toggles)
-----------------------------------------------------------

return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" }, -- just for loading; doesn't auto-format by itself
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      -- Filetype -> formatter(s)
      formatters_by_ft = {
        -- Lua (remove if you don't want it)
        lua = { "stylua" },

        -- Web (Prettier)
        javascript = {"eslint_d", "prettier" },
        typescript = { "eslint_d","prettier" },
        javascriptreact = { "eslint_d","prettier" },
        typescriptreact = { "eslint_d","prettier" },
        vue = { "eslint_d","prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },

        -- Python (remove if not needed)
        python = { "isort", "black" },

        -- C/C++ (remove if not needed)
        c = { "clang_format" },
        cpp = { "clang_format" },

        -- Shell (remove if not needed)
        sh = { "shfmt" },

        -- LaTeX (remove if not needed)
        tex = { "latexindent" },

        -- Generic
        ["*"] = { "trim_whitespace", "trim_newlines" },
        ["_"] = { "trim_whitespace" },
      },

      -- Formatter options
      formatters = {
        black = { args = { "--quiet", "--line-length", "88", "-" } },
        isort = { args = { "--profile", "black", "-" } },
        stylua = { args = { "--indent-type", "Spaces", "--indent-width", "2", "--quote-style", "AutoPreferDouble", "-" } },
        latexindent = { args = { "-m", "-l" } },
        shfmt = { args = { "-i", "2", "-ci", "-bn" } },
      },

      -- AUTOFORMAT ON SAVE (now respects vim.g/b.autoformat)
      -- Return opts to enable; return false/nil to skip.
      format_on_save = function(bufnr)
        -- ❗ Respect the new LazyVim flags
        if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
          return false
        end

        -- Only autoformat selected filetypes (your list)
        local allow = {
          "javascript", "typescript", "javascriptreact", "typescriptreact",
          "json", "html", "css", "scss", "markdown", "yaml",
          -- add/remove here; e.g. "lua", "python", etc.
        }
        local ft = vim.bo[bufnr].filetype
        if vim.tbl_contains(allow, ft) then
          return { timeout_ms = 500, lsp_fallback = true }
        end
        return false
      end,

      -- Other settings
      format_after_save = false,
      log_level = vim.log.levels.ERROR,
      notify_on_error = true,
      respect_gitignore = true,
    })

    -- which-key (unchanged)
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key then
      which_key.register({
        m = {
          p = {
            function() require("conform").format({ async = true, lsp_fallback = true }) end,
            "Format code",
          },
        },
      }, { prefix = "<leader>" })
    end

    ----------------------------------------------------------------
    -- :FormatToggle  (switch to NEW flags; remove legacy ones)
    ----------------------------------------------------------------
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      local notify = function(msg, level)
        local ok, n = pcall(require, "neotex.util.notifications")
        if ok then
          n.lsp(msg, n.categories.USER_ACTION)
        else
          vim.notify(msg, level or vim.log.levels.INFO)
        end
      end

      if args.args == "buffer" then
        -- Buffer-local toggle
        if vim.b.autoformat == false then
          vim.b.autoformat = true
          notify("Format on save enabled (buffer)")
        else
          vim.b.autoformat = false
          notify("Format on save disabled (buffer)", vim.log.levels.WARN)
        end
      else
        -- Global toggle
        if vim.g.autoformat == false then
          vim.g.autoformat = true
          notify("Format on save enabled (global)")
        else
          vim.g.autoformat = false
          notify("Format on save disabled (global)", vim.log.levels.WARN)
        end
      end
    end, {
      nargs = "?",
      complete = function() return { "buffer" } end,
      desc = "Toggle format on save",
    })

    ----------------------------------------------------------------
    -- One-time compatibility shim: translate legacy flags if set
    ----------------------------------------------------------------
    if vim.g.disable_autoformat ~= nil then
      vim.g.autoformat = not vim.g.disable_autoformat
      vim.g.disable_autoformat = nil
    end
    vim.api.nvim_create_autocmd("BufReadPre", {
      callback = function(args)
        if vim.b.disable_autoformat ~= nil then
          vim.b.autoformat = not vim.b.disable_autoformat
          vim.b.disable_autoformat = nil
        end
      end,
    })
  end,
}
