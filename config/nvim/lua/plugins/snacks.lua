-- lazy.nvim
return {
    "folke/snacks.nvim",
    opts = {
        explorer = {
            retplace_ntrw = true,
        },
        picker = {
            sources = {
                gh_issue = {
                    -- your gh_issue picker configuration comes here
                    -- or leave it empty to use the default settings
                },
                gh_pr = {
                    -- your gh_pr picker configuration comes here
                    -- or leave it empty to use the default settings
                },
                explorer = {
                    hidden = true,
                    ignored = true,
                },
            },
        },
    },
}
