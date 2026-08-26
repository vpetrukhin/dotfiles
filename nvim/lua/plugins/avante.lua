return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "ollama",
      providers = {
        ollama = {
          model = "deepseek-coder-v2:16,",
          is_env_set = require("avante.providers.ollama").check_endpoint_alive,
        },
      },
    },
  },
}
