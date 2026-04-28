return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- ✅ Autoformat on save
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },

    -- ✅ Use Prettier for web-related files
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },
    },

    -- ✅ Optional: customize Prettier arguments
    formatters = {
      prettier = {
        prepend_args = {
          "--single-quote",
          "--no-semi",
          "--trailing-comma=es5",
        },
      },
    },
  },
}
