return {

    "ThePrimeagen/refactoring.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-treesitter/nvim-treesitter" },
        { "lewis6991/async.nvim" },
    },
    config = function()
        require("refactoring").setup({})
    end,
    keys = {
        {
            "<leader>cR",
            ":lua require('refactoring').select_refactor()<CR>",
            mode = "v",
            desc = "Refactor",
        },
    },
}
