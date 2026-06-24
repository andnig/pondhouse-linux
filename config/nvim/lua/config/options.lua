-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
package.path = package.path
    .. ";"
    .. vim.fn.expand("$HOME")
    .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"

vim.opt.clipboard = "unnamedplus"
vim.g.snacks_scroll = false
vim.g.ai_cmp = false

-- Use OSC 52 when the native clipboard tool can't reach the compositor.
-- Triggers on SSH sessions AND on Wayland shells that lost WAYLAND_DISPLAY
-- (e.g. tmux server started under SSH, then attached physically — new shells
-- inherit no WAYLAND_DISPLAY since tmux's update-environment doesn't refresh it).
local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil
local wayland_broken = vim.env.XDG_SESSION_TYPE == "wayland"
    and (vim.env.WAYLAND_DISPLAY == nil or vim.env.WAYLAND_DISPLAY == "")

if in_ssh or wayland_broken then
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = osc52.copy("+"),
            ["*"] = osc52.copy("*"),
        },
        paste = {
            ["+"] = osc52.paste("+"),
            ["*"] = osc52.paste("*"),
        },
    }
    vim.opt.clipboard = "unnamedplus"
end

vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.scrolloff = 8
vim.opt.colorcolumn = "80"
vim.opt.conceallevel = 1

vim.filetype.add({
    extension = {
        conf = "conf",
    },
    filename = {
        ["tsconfig.json"] = "jsonc",
        [".yamlfmt"] = "yaml",
    },
})
