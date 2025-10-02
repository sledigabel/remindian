local M = {}
local config = require("remindian.config")
local binary_path = "bin/remindian" -- Path to the binary

-- Function to check if the binary exists
local function binary_exists()
  local f = io.open(binary_path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Run the remindian binary with the current file
M.trigger = function()
  -- Get the absolute path of the current file
  local file_path = vim.fn.expand("%:p")
  
  -- Check if binary exists
  if not binary_exists() then
    vim.notify("Remindian binary not found at: " .. binary_path, vim.log.levels.ERROR)
    return
  end
  
  -- Get reminder list from config
  local reminder_list = config.options.reminder_list
  
  -- Build the command
  local cmd = binary_path .. " " .. vim.fn.shellescape(file_path) .. " --list=" .. reminder_list
  
  -- Execute command without showing output
  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data and #data > 1 then
        vim.notify("Remindian error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    -- We're not handling stdout as requested to not log output
  })
end

-- Function to run remindian on demand
M.run_manually = function()
  M.trigger()
  vim.notify("Remindian manually executed")
end

return M
