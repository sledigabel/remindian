local M = {}

-- Default configuration
M.defaults = {
    -- Example configuration options
    enable_logging = false,
    log_level = 'info',
    filetype = 'markdown',
    reminder_list = 'remindian',
}

-- Current configuration (starts with defaults)
M.options = {}

-- Setup function to merge user config with defaults
function M.setup(opts)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, opts or {})
end

-- Initialize with defaults
M.setup({})

return M