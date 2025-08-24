return {
    {
        "mfussenegger/nvim-lint",
        opts = {
            linters_by_ft = {
                sql = { "sqlfluff" },
                dbt = { "sqlfluff" },
            },
            linters = {
                markdownlint = {
                    args = { "--disable", "MD033", "--disable", "MD034", "--" },
                },
                sqlfluff = {
                    args = {
                        "lint",
                        "--format=json",
                        "--dialect=bigquery",
                        "--templater=dbt",
                    },
                },
            },
        },
    },
}
