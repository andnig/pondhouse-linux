return {
    {
        "saghen/blink.cmp",
        dependencies = {
            "Kaiser-Yang/blink-cmp-avante",
            -- ... Other dependencies
        },
        opts = {
            sources = {
                -- Add 'avante' to the list
                default = { "avante" },
                providers = {
                    avante = {
                        module = "blink-cmp-avante",
                        name = "Avante",
                        opts = {
                            -- options for blink-cmp-avante
                        },
                    },
                },
            },
        },
    },
    -- {
    --     "giuxtaposition/blink-cmp-copilot",
    -- },
    --     {
    --         "saghen/blink.cmp",
    --         ---@module 'blink.cmp'
    --         ---@type blink.cmp.Config
    --         opts = {
    --             -- sources = {
    --             --     default = { "copilot" },
    --             --     providers = {
    --             --         copilot = {
    --             --             name = "copilot",
    --             --             module = "blink-cmp-copilot",
    --             --         },
    --             --     },
    --             --     completion = {
    --             --         enabled_providers = { "copilot", "lsp", "path" },
    --             --     },
    --             -- },
    --             keymap = {
    --                 preset = "super-tab",
    --                 ["<Tab>"] = {
    --                     LazyVim.cmp.map({
    --                         "ai_accept",
    --                         "accept",
    --                     }),
    --                     function(cmp)
    --                         if cmp.snippet_active() then
    --                             return cmp.accept()
    --                         else
    --                             return cmp.select_and_accept()
    --                         end
    --                     end,
    --                     "fallback",
    --                 },
    --             },
    --         },
    --     },
}
