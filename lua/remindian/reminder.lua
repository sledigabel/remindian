local M = {}
local config = require("remindian.config")

-- Get the module directory path
local function get_module_dir()
  -- Get the path to this very file
  local source = debug.getinfo(1, "S").source
  local path = string.sub(source, 2) -- Remove the '@' prefix
  -- Return the directory containing this file
  return vim.fn.fnamemodify(path, ":h:h:h") -- Go up three levels: file -> remindian -> lua -> root
end

-- Build the binary path
local module_dir = get_module_dir()
local binary_path = module_dir .. "/bin/remindian"

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
  local cmd = binary_path .. " --rewrite --list=" .. reminder_list .. " " .. vim.fn.shellescape(file_path)

  -- Log command if logging is enabled
  if config.options.enable_logging then
    vim.notify("Executing: " .. cmd, vim.log.levels.DEBUG)
  end

  -- Execute command without showing output
  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data and #data > 1 then
        vim.notify("Remindian error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 and config.options.enable_logging then
        vim.notify("Remindian exited with code: " .. exit_code, vim.log.levels.DEBUG)
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
