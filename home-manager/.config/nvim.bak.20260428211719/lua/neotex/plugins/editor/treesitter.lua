-- ~/.config/nvim/lua/plugins/
return {
  -- Treesitter: Optimized parser configuration
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "query",
        "markdown", "markdown_inline",
        "bash", "json", "yaml", "toml", "html", "css", "javascript", "regex",
        "python",
      },
      auto_install = false,
      
      ignore_install = { 
        "latex", "tex", "bibtex", "plaintex", "context",
        "ledger", "supercollider", "ocamllex", "gdscript",
        "teal", "erlang", "devicetree",
      },
      
      highlight = {
        enable = true,
        disable = function(lang, buf)
          -- Disable for large files (>500KB)
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          return ok and stats and stats.size > 500000
        end,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-n>",
          node_incremental = "<C-n>",
          node_decremental = "<C-p>",
          scope_incremental = false,
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
      
      -- Use classic syntax for .tex files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "latex" },
        callback = function()
          vim.opt_local.syntax = "tex"
          -- Completely disable treesitter for tex files
          vim.cmd("TSBufDisable highlight")
        end,
      })
    end,
  },

  -- Render markdown: Pretty in-buffer rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      file_types = { "markdown" },
      log_level = "error",
      debounce = 100,
      render_modes = { "n", "i" },
      max_file_size = 10.0,
      heading = { enabled = true, sign = false, position = "overlay" },
      bullet = { enabled = true, icons = { "•", "◦", "▪", "▫" } },
      checkbox = {
        enabled = true,
        position = "inline",
        unchecked = { icon = " " },
        checked = { icon = " " },
      },
      code = { enabled = true, sign = false, border = "thin", width = "full" },
      quote = { enabled = true, icon = "▌" },
      dash = { enabled = true, icon = "─", width = "full" },
      latex = {
        enabled = false,
        converter = { "utftex", "latex2text" },
        highlight = "RenderMarkdownMath",
        top_pad = 0,
        bottom_pad = 0,
      },
      win_options = {
        conceallevel = { default = vim.o.conceallevel, rendered = 3 },
        concealcursor = { default = vim.o.concealcursor, rendered = "" },
      },
    },
    keys = {
      { "<leader>um", function() require("render-markdown.state").toggle() end, desc = "Toggle Markdown Rendering" },
    },
  },

  -- mdmath: Inline math preview with Kitty Graphics Protocol
  {
    "Thiago4532/mdmath.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      filetypes = { "markdown" },
      -- hide_on_insert = tru,

      anticonceal = true,
      inline = true,
      dynamic = true,
      internal_scale = 1.0,
      block_scale = 1.0,
      update_interval = 350,
      center_equations = true,
   },
    config = function(_, opts)
      require("mdmath").setup(opts)
      
      vim.opt.updatetime = 300
      
      local refresh_timer = nil
      local function debounced_refresh()
        if refresh_timer then
          vim.fn.timer_stop(refresh_timer)
        end
        refresh_timer = vim.fn.timer_start(300, function()
          vim.cmd("silent! MdMath clear")
          vim.cmd("silent! MdMath enable")
          refresh_timer = nil
        end)
      end
      
      vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        pattern = "*.md",
        callback = debounced_refresh,
      })
      
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          vim.defer_fn(function()
            vim.cmd("silent! MdMath enable")
          end, 100)
        end,
      })
    end,
    keys = {
      { "<leader>mm", "<cmd>MdMath enable<cr>", desc = "Math: Enable Preview" },
      { "<leader>mM", "<cmd>MdMath disable<cr>", desc = "Math: Disable Preview" },
      { "<leader>mr", "<cmd>MdMath clear<cr>", desc = "Math: Refresh Preview" },
    },
  },

  -- Markdown preview: Browser preview with KaTeX
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle", "MarkdownPreviewStop" },
    init = function()
      vim.g.mkdp_browser = "brave"
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_page_title = "「${name}」"
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "Markdown: Preview" },
      { "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown: Toggle Preview" },
      { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", desc = "Markdown: Stop Preview" },
    },
  },

  -- Context-aware commenting
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable_autocmd = false,
    },
  },

  -- Auto-close tags
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      autotag = {
        enable = true,
        enable_close_on_slash = false,
      },
    },
  },
}
