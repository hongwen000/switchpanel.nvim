local Config = {}

-- Get logger
local logger
local function get_logger()
    if not logger then
        logger = require("switchpanel").logger or require("switchpanel.logger")
    end
    return logger
end

---Validates configuration options
---@param config table The configuration to validate
---@return boolean is_valid Whether the configuration is valid
---@return string|nil error_message Error message if configuration is invalid
local function validate_config(config)
    local log = get_logger()
    
    if type(config) ~= "table" then
        return false, "Configuration must be a table"
    end
    
    -- Validate panel_list
    if config.panel_list and type(config.panel_list) ~= "table" then
        return false, "panel_list must be a table"
    end
    
    -- Validate width
    if config.width and type(config.width) ~= "number" then
        return false, "width must be a number"
    end
    
    -- Validate mappings
    if config.mappings then
        if type(config.mappings) ~= "table" then
            return false, "mappings must be a table"
        end
        
        for i, mapping in ipairs(config.mappings) do
            if type(mapping) ~= "table" or #mapping ~= 2 then
                log.warn("Invalid mapping at index %d: must be a table with 2 elements", i)
            end
        end
    end
    
    -- Validate builtin
    if config.builtin then
        if type(config.builtin) ~= "table" then
            return false, "builtin must be a table"
        end
        
        for i, panel in ipairs(config.builtin) do
            if type(panel) ~= "string" and type(panel) ~= "table" then
                log.warn("Invalid panel at index %d: must be a string or table", i)
            end
            
            if type(panel) == "table" then
                if not panel.open or not panel.close or not panel.filetype then
                    log.warn("Custom panel at index %d is missing required fields", i)
                end
            end
        end
    end
    
    return true, nil
end

---Gets the configuration with defaults merged with user options
---@param options table|nil User configuration options
---@return table The merged configuration
function Config.get_ops(options)
    local log = get_logger()
    local Utils = require("switchpanel.utils")
    
    -- Default configuration
    local defaults = {
        panel_list = {
            show = true,
            background = "Blue",
            selected = "LightBlue",
            color = "none",
        },

        width = 30,
        focus_on_open = true,
        tab_repeat = true,
        
        mappings = {
            {"1", "SwitchPanelSwitch 1" },
            {"2", "SwitchPanelSwitch 2" },
            {"3", "SwitchPanelSwitch 3" },
            -- {"4", "SwitchPanelSwitch 4" },
            -- {"5", "SwitchPanelSwitch 5" },
            {"J", "SwitchPanelNext" },
            {"K", "SwitchPanelPrevious" },
        },

        builtin = {
            "nvim-tree.lua",
            "sidebar.nvim",
            "undotree",
        }
    }
    
    -- Validate user options
    if options then
        local is_valid, err_msg = validate_config(options)
        if not is_valid then
            log.error("Invalid configuration: %s", err_msg)
            vim.notify("SwitchPanel: Invalid configuration: " .. err_msg, vim.log.levels.ERROR)
            return defaults
        end
    end
    
    -- Merge user options with defaults
    local merged_config = Utils.tableMerge(defaults, options or {})
    
    -- Validate merged configuration
    local is_valid, err_msg = validate_config(merged_config)
    if not is_valid then
        log.error("Invalid merged configuration: %s", err_msg)
        vim.notify("SwitchPanel: Configuration error: " .. err_msg, vim.log.levels.ERROR)
        return defaults
    end
    
    log.debug("Configuration loaded successfully")
    return merged_config
end

return Config
