return {
    {

        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                "debugpy",
                "js-debug-adapter",
                "biome",
                -- "sqlfluff",
            },
        },
    },
}
