require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Auto-copy to system clipboard on mouse selection
map("v", "<LeftRelease>", '"*ygv', { desc = "Auto-copy on select" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
