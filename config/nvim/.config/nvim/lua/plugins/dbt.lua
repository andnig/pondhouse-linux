return {
    {
        "PedramNavid/dbtpal",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
        ft = {
            "sql",
            "dbt",
            "md",
            "yaml",
        },
        config = function()
            local dbt = require("dbtpal")
            dbt.setup({
                -- Path to the dbt executable
                path_to_dbt = "dbt",

                -- Path to the dbt project, if blank, will auto-detect
                -- using currently open buffer for all sql,yml, and md files
                path_to_dbt_project = "",

                -- Path to dbt profiles directory
                path_to_dbt_profiles_dir = vim.fn.expand("~/.dbt"),

                -- Search for ref/source files in macros and models folders
                extended_path_search = true,

                -- Prevent modifying sql files in target/(compiled|run) folders
                protect_compiled_files = true,
            })

            -- Setup key mappings
            vim.keymap.set("n", "<localleader>dr", dbt.run, { desc = "dbt run file" })
            vim.keymap.set("n", "<localleader>dp", dbt.run_all, { desc = "dbt run project" })
            vim.keymap.set("n", "<localleader>dt", dbt.test, { desc = "dbt test file" })
            vim.keymap.set(
                { "n" },
                "<localleader>df",
                "<cmd>!sqlfluff fix % -f <CR> --templater dbt",
                { desc = "Fix SQL" }
            )
            vim.keymap.set(
                "n",
                "<localleader>dm",
                require("dbtpal.telescope").dbt_picker,
                { desc = "dbt picker" }
            )

            -- Enable Telescope Extension
            require("telescope").load_extension("dbtpal")
        end,
    },
}
