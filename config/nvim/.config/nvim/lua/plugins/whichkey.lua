return {
    "folke/which-key.nvim",
    opts = {
        plugins = { spelling = true },
        spec = {
            { "<leader>a", group = "ai" },
            { "<leader>i", group = "image" },
            { "<leader>m", group = "markdown" },
            { "<leader>n", group = "notes" },
            { "<localleader>c", group = "code" },
            { "<localleader>d", group = "dbt/sql" },
        },
    },
}
