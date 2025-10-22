return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    ---@class CatppuccinOptions
    opts = {
        float = {
            transparent = true, -- enable transparent floating windows
        },
        transparent_background = true,
        flavour = "mocha",
        integrations = { fzf = true, blink_cmp = true },
        default_integrations = true,
    },
}
