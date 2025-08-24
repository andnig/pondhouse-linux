return {
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline",
        format = {
          cmdline = { pattern = "^:", icon = ":", lang = "vim" },
        },
      },
      -- presets = {
      --   command_palette = false,
      --   bottom_search = false,
      -- },
    },
  },
}
