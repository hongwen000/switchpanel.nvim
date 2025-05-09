local SwitchPanel = {}

-- Version information
SwitchPanel.version = "1.0.0"

-- Default debug configuration
SwitchPanel.debug_config = {
    level = "WARN",      -- DEBUG, INFO, WARN, ERROR, OFF
    use_console = true,  -- Log to Neovim's notification system
    use_file = false,    -- Log to file
    file_path = nil,     -- Path to log file (default: stdpath("cache")/switchpanel.log)
}

---Check if required dependencies are available
---@return boolean success Whether all dependencies are available
---@return string|nil error_message Error message if dependencies are missing
local function check_dependencies()
    -- List of required Neovim API features
    local required_features = {
        "nvim_create_user_command",
        "nvim_create_autocmd",
        "nvim_buf_set_option",
        "nvim_win_set_option"
    }
    
    for _, feature in ipairs(required_features) do
        if not vim.api[feature] then
            return false, "SwitchPanel requires Neovim 0.7+ with " .. feature .. " API support"
        end
    end
    
    return true, nil
end

---Setup function for SwitchPanel plugin
---@param options table|nil Configuration options
---@return table SwitchPanel module for chaining
function SwitchPanel.setup(options)
    options = options or {}
    
    -- Initialize logger first
    local logger = require("switchpanel.logger")
    
    -- Setup logger with user config or defaults
    local log_config = {}
    if options.debug then
        log_config = vim.tbl_extend("force", SwitchPanel.debug_config, options.debug)
        
        -- Convert string level to numeric level
        if type(log_config.level) == "string" then
            log_config.level = logger.levels[log_config.level] or logger.levels.WARN
        end
    else
        log_config = SwitchPanel.debug_config
        log_config.level = logger.levels.WARN
    end
    
    logger.setup(log_config)
    SwitchPanel.logger = logger
    
    -- Log startup information
    logger.info("SwitchPanel v%s initializing", SwitchPanel.version)
    
    -- Check dependencies
    local deps_ok, deps_err = check_dependencies()
    if not deps_ok then
        logger.error(deps_err)
        vim.notify(deps_err, vim.log.levels.ERROR)
        return SwitchPanel
    end
    
    -- Get configuration with defaults
    local ok, config_or_err = pcall(function()
        return require("switchpanel.ops").get_ops(options)
    end)
    
    if not ok then
        logger.error("Failed to load configuration: %s", config_or_err)
        vim.notify("SwitchPanel: Failed to load configuration: " .. config_or_err, vim.log.levels.ERROR)
        return SwitchPanel
    end
    
    SwitchPanel.ops = config_or_err
    local config = SwitchPanel.ops
    
    -- Process builtin panels
    local default_builtin = require("switchpanel.builtin")
    for i, builtin in pairs(config.builtin) do
        if type(builtin) == "string" then
            if default_builtin[builtin] then
                config.builtin[i] = default_builtin[builtin]
                logger.debug("Loaded builtin panel: %s", builtin)
            else
                logger.warn("Unknown builtin panel: %s", builtin)
                config.builtin[i] = nil
            end
        else
            -- Validate custom panel configuration
            if type(builtin) == "table" and builtin.open and builtin.close and builtin.filetype then
                logger.debug("Loaded custom panel with filetype: %s", builtin.filetype)
            else
                logger.warn("Invalid panel configuration at index %d", i)
            end
        end
    end
    
    -- Load commands and autocmds
    local success, err = pcall(function()
        require("switchpanel.command")
        require("switchpanel.autocmd")
    end)
    
    if not success then
        logger.error("Failed to initialize commands or autocmds: %s", err)
        vim.notify("SwitchPanel: Initialization error: " .. err, vim.log.levels.ERROR)
    else
        logger.info("SwitchPanel initialized successfully")
    end
    
    -- Return the module for chaining
    return SwitchPanel
end

return SwitchPanel
