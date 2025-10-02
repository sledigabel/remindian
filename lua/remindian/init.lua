local M = {}

-- Import the configuration module
local config = require('remindian.config')

-- Setup function for plugin configuration
function M.setup(opts)
    -- Override defaults with user provided options
    config.setup(opts)
    
    -- Register commands
    vim.api.nvim_create_user_command('RemindianHello', function()
        vim.notify('Hello from Remindian plugin!', vim.log.levels.INFO)
    end, {})
end

return M