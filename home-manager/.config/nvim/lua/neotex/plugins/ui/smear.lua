
return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- Example options (all optional)
      smear_between_buffers = true, -- keeps the smear across buffer switches
      smear_between_windows = true,
      smear_cursor_line = true,     -- smears the whole line with cursor
    }
  },
}
