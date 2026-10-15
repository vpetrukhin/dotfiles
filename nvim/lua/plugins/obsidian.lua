local function get_workspaces()
  local vaults_file = vim.fn.expand("~/Library/Application Support/obsidian/obsidian.json")
  local file = io.open(vaults_file, "r")
  if not file then
    return {}
  end

  local contents = file:read("*a")
  file:close()

  local ok, config = pcall(vim.json.decode, contents)
  if not ok or type(config.vaults) ~= "table" then
    return {}
  end

  local workspaces = {}
  for _, vault in pairs(config.vaults) do
    if type(vault.path) == "string" and vim.fn.isdirectory(vault.path) == 1 then
      table.insert(workspaces, {
        name = vim.fn.fnamemodify(vault.path, ":t"),
        path = vault.path,
      })
    end
  end

  return workspaces
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      return {
        legacy_commands = false,
        workspaces = get_workspaces(),
      }
    end,
  },
}
