-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("n", "<leader>fy", function()
  local path = vim.fn.expand("%:.")
  local cmd = "echo '" .. path .. "' | pbcopy"
  vim.fn.system(cmd)
  vim.notify("Путь скопирован: " .. path, vim.log.levels.INFO)
end, { desc = "Копировать путь к файлу в буфер" })
