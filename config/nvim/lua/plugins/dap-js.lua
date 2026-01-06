-- DAP configuration for Next.js and TanStack Start debugging
return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require("dap")

        -- Helper function to detect package manager (pnpm vs npm)
        local function get_package_manager()
            local cwd = vim.fn.getcwd()
            if vim.fn.filereadable(cwd .. "/pnpm-lock.yaml") == 1 then
                return "pnpm"
            end
            return "npm"
        end

        -- pwa-node adapter for server-side debugging
        dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
                command = "node",
                args = {
                    vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
                    "${port}",
                },
            },
        }

        -- Firefox adapter for client-side debugging
        dap.adapters["firefox"] = {
            type = "executable",
            command = "node",
            args = {
                vim.fn.stdpath("data") .. "/mason/packages/firefox-debug-adapter/dist/adapter.bundle.js",
            },
        }

        -- Debug configurations for JS/TS filetypes
        local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

        for _, language in ipairs(js_based_languages) do
            dap.configurations[language] = dap.configurations[language] or {}

            -- Next.js: debug server
            table.insert(dap.configurations[language], {
                name = "Next.js: debug server",
                type = "pwa-node",
                request = "launch",
                cwd = "${workspaceFolder}",
                runtimeExecutable = function()
                    return get_package_manager()
                end,
                runtimeArgs = { "run", "dev" },
                skipFiles = { "<node_internals>/**" },
                console = "integratedTerminal",
            })

            -- Next.js: debug client-side
            table.insert(dap.configurations[language], {
                name = "Next.js: debug client-side",
                type = "firefox",
                request = "launch",
                reAttach = true,
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                firefoxExecutable = "/usr/bin/firefox",
            })

            -- TanStack Start: debug server
            table.insert(dap.configurations[language], {
                name = "TanStack Start: debug server",
                type = "pwa-node",
                request = "launch",
                cwd = "${workspaceFolder}",
                runtimeExecutable = function()
                    return get_package_manager()
                end,
                runtimeArgs = { "run", "dev" },
                skipFiles = { "<node_internals>/**" },
                console = "integratedTerminal",
            })

            -- TanStack Start: debug client-side
            table.insert(dap.configurations[language], {
                name = "TanStack Start: debug client-side",
                type = "firefox",
                request = "launch",
                reAttach = true,
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
                firefoxExecutable = "/usr/bin/firefox",
            })
        end
    end,
}
