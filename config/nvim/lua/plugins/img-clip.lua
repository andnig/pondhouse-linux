return {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown", "vimwiki", "md", "norg", "png" },
    event = "BufEnter",
    opts = {
        -- add options here
        -- or leave it empty to use the default settings
    },
    keys = {
        -- suggested keymap
        { "<leader>ip", "<cmd>PasteImage<cr>", desc = "Paste clipboard image" },
    },
}
