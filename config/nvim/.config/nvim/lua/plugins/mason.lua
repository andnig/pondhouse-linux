return {
    {

        "williamboman/mason.nvim",
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
