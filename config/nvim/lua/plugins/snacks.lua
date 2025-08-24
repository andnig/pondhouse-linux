-- lazy.nvim
return {
    "folke/snacks.nvim",
    opts = {
        explorer = {
            retplace_ntrw = true,
        },
        picker = {
            sources = {
                explorer = {
                    hidden = true,
                    ignored = true,
                },
            },
        },
    },
}
