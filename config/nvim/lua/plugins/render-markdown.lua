return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
        checkbox = {
            bullet = false,
            enabled = true,
            left_pad = 3,
            unchecked = {
                icon = "󰄱 ",
                highlight = "RenderMarkdownUnchecked",
            },
            checked = {
                icon = "󰱒 ",
                highlight = "RenderMarkdownChecked",
            },
            custom = {
                todo = { raw = "[-]", rendered = "󰜺 ", highlight = "RenderMarkdownTodo" },
            },
        },
    },
}
