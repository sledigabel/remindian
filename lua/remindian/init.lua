local M = {}

-- Import the configuration module
local config = require("remindian.config")

-- Setup function for plugin configuration
function M.setup(opts)
  -- Override defaults with user provided options
  config.setup(opts)

  local function trigger()
    require("remindian.reminder").trigger()
  end

  vim.b.autoread = true
  -- adding an autocmd to trigger reminders on Save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md", -- Adjust the pattern as needed
    -- command = "lua require('remindian.reminder').trigger()",
    callback = function()
      vim.schedule(trigger)
    end,
  })

  -- Create command to manually trigger remindian
  vim.api.nvim_create_user_command("RemindianRun", function()
    require("remindian.reminder").run_manually()
  end, {})
end

return M