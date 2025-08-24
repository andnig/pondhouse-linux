-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("x", "<leader>pp", [["_dP]], { desc = "Paste but do not override yank register" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set("n", "<leader>ps", [["+p]], { desc = "[p]aste from system clipboard" })
vim.keymap.set("n", "<leader>Ps", [["+P]], { desc = "[P]aste from system clipboard" })
vim.keymap.set("n", "<leader>pd", [["=strftime("%F")<CR>P]], { desc = "Insert current date" })

vim.keymap.set({ "n", "v" }, "<leader>dd", [["_d]], { desc = "Delete into void" })
vim.keymap.set({ "n", "v" }, "<leader>dd", [["_d]], { desc = "Delete into void" })

vim.keymap.set(
    { "n" },
    "<localleader>dc",
    "<cmd>!dbt compile -s % <CR>",
    { desc = "dbt compile file" }
)

vim.keymap.set(
    "n",
    "<leader>fx",
    "<cmd>!chmod +x %<CR>",
    { silent = true, desc = "Chmod +x this file" }
)

-- vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
-- vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous location" })

vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line down" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move line up" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move line down" })

vim.api.nvim_set_keymap(
    "n",
    "<leader>bn",
    "<cmd>lua require('methods').create_buffer_with_name()<CR>",
    { noremap = true, silent = true, desc = "Create buffer with name" }
)

vim.api.nvim_set_keymap(
    "n",
    "<leader>nr",
    "<cmd>lua require('methods').create_new_note('russmedia')<CR>",
    { noremap = true, silent = true, desc = "Create new Russmedia note" }
)

vim.api.nvim_set_keymap(
    "n",
    "<leader>ng",
    "<cmd>lua require('methods').create_new_note('general')<CR>",
    { noremap = true, silent = true, desc = "Create new General note" }
)

vim.api.nvim_set_keymap(
    "n",
    "<leader>ni",
    "<cmd>lua require('methods').create_new_note('ideas')<CR>",
    { noremap = true, silent = true, desc = "Create new idea" }
)

vim.api.nvim_set_keymap(
    "n",
    "<leader>cb",
    "<cmd>:lua vim.cmd('silent !biome check --unsafe --write --formatter-enabled=true --organize-imports-enabled=true --skip-errors ' .. vim.fn.shellescape('%'))<CR>",
    { noremap = true, silent = true, desc = "Format with biome" }
)

vim.keymap.set(
    "v",
    "<leader>ae",
    "<cmd>lua require('chatgpt').edit_with_instructions()<CR>",
    { desc = "Edit with ChatGPT with instructions" }
)
vim.keymap.set(
    { "n", "v" },
    "<leader>ac",
    "<cmd>lua require('chatgpt').openChat()<CR>",
    { desc = "Open ChatGPT" }
)

-- vim.keymap.set("n", "<c-k>", ":wincmd k<CR>", { desc = "Navigate pane up" })
-- vim.keymap.set("n", "<c-j>", ":wincmd j<CR>", { desc = "Navigate pane down" })
-- vim.keymap.set("n", "<c-h>", ":wincmd h<CR>", { desc = "Navigate pane left" })
-- vim.keymap.set("n", "<c-l>", ":wincmd l<CR>", { desc = "Navigate pane right" })
