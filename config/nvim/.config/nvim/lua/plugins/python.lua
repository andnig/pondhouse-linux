-- return {
--     -- change nvim-lspconfig options
--     "neovim/nvim-lspconfig",
--     opts = {
--         servers = {
--             -- https://github.com/microsoft/pyright/discussions/5852#discussioncomment-6874502
--             pyright = {
--                 capabilities = {
--                     textDocument = {
--                         publishDiagnostics = {
--                             tagSupport = {
--                                 valueSet = { 2 },
--                             },
--                         },
--                     },
--                 },
--             },
--             ruff_lsp = {},
--         },
--     },
return {
    {
        "nvim-lspconfig",
        opts = {
            servers = {
                pyright = {
                    capabilities = (function()
                        local capabilities = vim.lsp.protocol.make_client_capabilities()
                        capabilities.textDocument.publishDiagnostics.tagSupport.valueSet = { 2 }
                        return capabilities
                    end)(),
                    settings = {
                        python = {
                            analysis = {
                                useLibraryCodeForTypes = true,
                                diagnosticSeverityOverrides = {
                                    reportUnusedVariable = "warning", -- or anything
                                },
                                typeCheckingMode = "basic",
                            },
                        },
                    },
                },
                ruff_lsp = {
                    on_attach = function(client, _)
                        client.server_capabilities.hoverProvider = false
                    end,
                },
            },
        },
    },
}
