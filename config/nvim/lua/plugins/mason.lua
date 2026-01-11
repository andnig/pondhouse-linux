return {
    {

        "mason-org/mason.nvim",
        opts = {
        ensure_installed = {
                "debugpy",
                "js-debug-adapter",
                "firefox-debug-adapter",
                "biome",
                -- "sqlfluff",
            },
        },
    },
}
