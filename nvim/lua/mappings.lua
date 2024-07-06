require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- normal mode
map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<leader>sw", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>cx", function()
  require("nvchad.tabufline").closeAllBufs()
end, { desc = "Close All Buffers" })
map("n", "<leader><leader>q", "<cmd>q<cr>", { desc = "Close focused field" })

map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Find Todo" })
map("n", "\\", "<cmd>:vsplit <CR>", { desc = "Vertical Split" })
map("n", "<c-l>", "<cmd>:TmuxNavigateRight<cr>", { desc = "Tmux Right" })
map("n", "<c-h>", "<cmd>:TmuxNavigateLeft<cr>", { desc = "Tmux Left" })
map("n", "<c-k>", "<cmd>:TmuxNavigateUp<cr>", { desc = "Tmux Up" })
map("n", "<c-j>", "<cmd>:TmuxNavigateDown<cr>", { desc = "Tmux Down" })

-- Trouble

map("n", "<leader>qx", "<cmd>Trouble<CR>", { desc = "Open Trouble" })
map("n", "<leader>qw", "<cmd>Trouble workspace_diagnostics<CR>", { desc = "Open Workspace Trouble" })
map("n", "<leader>qd", "<cmd>Trouble document_diagnostics<CR>", { desc = "Open Document Trouble" })
map("n", "<leader>qq", "<cmd>Trouble quickfix<CR>", { desc = "Open Quickfix" })
map("n", "<leader>ql", "<cmd>Trouble loclist<CR>", { desc = "Open Location List" })

-- insert mode
map("i", "jk", "<ESC>")
