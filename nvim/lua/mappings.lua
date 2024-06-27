require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<leader>sw", "<cmd> w <cr>", { desc = "Save" })

-- insert mode
map("i", "jk", "<ESC>")
