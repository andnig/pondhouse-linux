return {
    -- custom config which piggybacks on the copilot extras in lazy.lua.
    {
        "yetone/avante.nvim",
        enable = true,
        event = "LazyFile",
        lazy = true,
        build = "make",
        opts = {
            -- add any opts here
        },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "echasnovski/mini.icons",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below is optional, make sure to setup it properly if you have lazy=true
            "zbirenbaum/copilot.lua", -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        use_absolute_path = true,
                    },
                },
            },
            {
                "MeanderingProgrammer/render-markdown.nvim",
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    },
    -- {
    --     "zbirenbaum/copilot.lua",
    --     cmd = "Copilot",
    --     build = ":Copilot auth",
    --     event = "InsertEnter",
    --     opts = {
    --         suggestion = {
    --             enabled = false,
    --             auto_trigger = true,
    --             debounce = 75,
    --             keymap = {
    --                 accept = false,
    --             },
    --         },
    --         panel = { enabled = false },
    --         filetypes = {
    --             markdown = true,
    --             yaml = true,
    --         },
    --     },
    -- },

    -- https://github.com/jackMort/ChatGPT.nvim
    -- {
    --     "jackMort/ChatGPT.nvim",
    --     dependencies = {
    --         { "MunifTanjim/nui.nvim" },
    --         { "nvim-lua/plenary.nvim" },
    --         -- { "nvim-telescope/telescope.nvim" },
    --     },
    --     -- event = "VeryLazy",
    --     config = function()
    --         local home = vim.fn.expand("$HOME")
    --         require("chatgpt").setup({
    --             api_key_cmd = "cat " .. home .. "/.secrets/openai.secret",
    --             openai_params = {
    --                 model = "gpt-4o",
    --             },
    --             edit_with_instructions = {
    --                 keymaps = {
    --                     accept = "<leader>aa",
    --                     use_output_as_input = "<leader>ao",
    --                 },
    --             },
    --             chat = {
    --                 keymaps = {
    --                     yank_last = "<leader>ay",
    --                     yank_last_code = "<leader>ak",
    --                     toggle_sessions = "<leader>as",
    --                 },
    --             },
    --             openai_edit_params = {
    --                 model = "gpt-4o",
    --                 temperature = 0,
    --                 top_p = 1,
    --                 n = 1,
    --             },
    --         })
    --     end,
    -- },
}
