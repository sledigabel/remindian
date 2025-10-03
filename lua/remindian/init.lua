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

  -- adding an autocmd to trigger reminders on Save
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md", -- Adjust the pattern as needed
    callback = function()
      vim.schedule(trigger)
    end,
  })

  -- makes sure the file is re-read after being written
  -- otherwise neovim will try to write a file that has changed.
  vim.b.autoread = true
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
    command = "if mode() != 'c' | checktime | endif",
    pattern = { "*" },
  })

  -- Create command to manually trigger remindian
  vim.api.nvim_create_user_command("RemindianRun", function()
    require("remindian.reminder").run()
  end, {})
end

return M