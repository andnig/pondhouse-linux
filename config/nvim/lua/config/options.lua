-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
package.path = package.path
    .. ";"
    .. vim.fn.expand("$HOME")
    .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"

vim.g.snacks_scroll = false
vim.g.ai_cmp = false

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
