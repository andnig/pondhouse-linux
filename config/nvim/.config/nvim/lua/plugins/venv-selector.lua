return {
    --     {
    --         "linux-cultist/venv-selector.nvim",
    --         dependencies = {
    --             "neovim/nvim-lspconfig",
    --             "nvim-telescope/telescope.nvim",
    --             "mfussenegger/nvim-dap-python",
    --         },
    --         opts = function(_, opts)
    --             if require("lazyvim.util").has("nvim-dap-python") then
    --                 opts.dap_enabled = true
    --             end
    --             return vim.tbl_deep_extend("force", opts, {
    --                 name = {
    --                     ".venv",
    --                     ".env",
    --                 },
    --                 anaconda_base_path = os.getenv("CONDA_BASE_PREFIX"),
    --                 anaconda_envs_path = os.getenv("CONDA_BASE_PREFIX") .. "/envs",
    --             })
    --         end,
    --         keys = {
    --             { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" },
    --             { "<leader>cc", "<cmd>:VenvSelectCached<cr>", desc = "Select Cached VirtualEnv" },
    --             { "<leader>cm", "<cmd>:VenvSelectCached<cr>", desc = "Select My VirtualEnv" },
    --         },
    --     },
    {
        "linux-cultist/venv-selector.nvim",
        opts = {
            settings = {
                search = {
                    anaconda_envs = {
                        command = "fdfind bin/python$ $CONDA_BASE_PREFIX/envs --full-path --color never -E /proc",
                        type = "anaconda",
                    },
                    anaconda_base = {
                        command = "fdfind /python$ $CONDA_BASE_PREFIX/bin --full-path --color never -E /proc",
                        type = "anaconda",
                    },
                },
                options = {
                    notify_user_on_venv_activation = true,
                },
            },
        },
    },
}
