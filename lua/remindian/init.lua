local M = {}

-- Import the configuration module
local config = require("remindian.config")

-- Setup function for plugin configuration
function M.setup(opts)
  -- Override defaults with user provided options
  config.setup(opts)

  -- adding an autocmd to trigger reminders on Save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md", -- Adjust the pattern as needed
    command = "lua require('remindian.reminder').trigger()",
  })
end

return M