local Panel = {}

-- Module state
Panel.active = nil
Panel.tabnr = 1
Panel.resume = nil

-- Local references
local PanelList = require("switchpanel.panel_list")
local api = vim.api
local cmd = vim.cmd

-- Get logger
local logger
local function get_logger()
    if not logger then
        logger = require("switchpanel").logger or require("switchpanel.logger")
    end
    return logger
end

---Validates a panel configuration
---@param panel table|nil The panel configuration to validate
---@return boolean is_valid Whether the panel is valid
---@return string|nil error_message Error message if panel is invalid
local function validate_panel(panel)
    if not panel then
        return false, "Panel is nil"
    end
    
    if type(panel) ~= "table" then
        return false, "Panel must be a table"
    end
    
    if not panel.open then
        return false, "Panel missing 'open' command"
    end
    
    if not panel.close then
        return false, "Panel missing 'close' command"
    end
    
    if not panel.filetype then
        return false, "Panel missing 'filetype'"
    end
    
    return true, nil
end

---Switches to a specific panel by number
---@param number number The panel number to switch to
---@return boolean success Whether the switch was successful
function Panel.switch(number)
    local log = get_logger()
    local config = require("switchpanel").ops
    
    -- Validate input
    if type(number) ~= "number" then
        log.error("Panel.switch: Expected number, got %s", type(number))
        vim.notify("SwitchPanel: Invalid panel number", vim.log.levels.ERROR)
        return false
    end
    
    -- Check if panel exists
    local panel = config.builtin[number]
    if not panel then
        log.error("Panel number %d not found", number)
        vim.notify("Panel number " .. number .. " not found", vim.log.levels.ERROR)
        return false
    end
    
    -- Validate panel configuration
    local is_valid, err_msg = validate_panel(panel)
    if not is_valid then
        log.error("Invalid panel configuration at index %d: %s", number, err_msg)
        vim.notify("SwitchPanel: Invalid panel configuration", vim.log.levels.ERROR)
        return false
    end
    
    -- Close active panel if exists
    if Panel.active then
        local close_success = Panel.close(Panel.active)
        if not close_success then
            log.warn("Failed to close active panel before switching")
        end
    end
    
    -- Open new panel
    local open_success = Panel.open(panel)
    if open_success then
        Panel.tabnr = number
        log.debug("Switched to panel %d", number)
        
        if Panel.active then
            vim.defer_fn(function()
                local PanelList = require("switchpanel.panel_list")
                if PanelList.winnr and api.nvim_win_is_valid(PanelList.winnr) then
                    log.debug("Apply mouse event handler after NvimTree is opened")
                    PanelList.setup_autocmd()
                end
            end, 50)
        end
        
        return true
    else
        log.error("Failed to open panel %d", number)
        return false
    end
end

---Switches to the next panel
---@return boolean success Whether the switch was successful
function Panel.tabnext()
    local log = get_logger()
    local config = require("switchpanel").ops
    
    -- Check if there's an active panel
    if not Panel.active then
        log.debug("No active panel to switch from")
        return false
    end
    
    -- Close current panel
    local close_success = Panel.close(Panel.active)
    if not close_success then
        log.warn("Failed to close active panel before switching to next")
    end
    
    -- Try to find a valid next panel
    local max_attempts = #config.builtin
    local attempts = 0
    local next_tabnr = Panel.tabnr
    local open_success = false
    
    while attempts < max_attempts do
        -- Calculate next panel index
        if next_tabnr == #config.builtin then
            if not config.tab_repeat then
                log.debug("Already at last panel and tab_repeat is disabled")
                return false
            end
            next_tabnr = 1
            log.debug("Wrapping around to first panel")
        else
            next_tabnr = next_tabnr + 1
        end
        
        attempts = attempts + 1
        
        -- Check if next panel exists and is valid
        local next_panel = config.builtin[next_tabnr]
        if not next_panel then
            log.warn("Next panel at index %d not found, trying next", next_tabnr)
            goto continue
        end
        
        local is_valid, err_msg = validate_panel(next_panel)
        if not is_valid then
            log.warn("Invalid next panel configuration: %s, trying next", err_msg)
            goto continue
        end
        
        -- Try to open the panel
        open_success = Panel.open(next_panel)
        if open_success then
            Panel.tabnr = next_tabnr
            log.debug("Switched to next panel %d", next_tabnr)
            return true
        else
            log.warn("Failed to open panel %d, trying next", next_tabnr)
        end
        
        ::continue::
    end
    
    log.error("Failed to open next panel after %d attempts", attempts)
    vim.notify("SwitchPanel: No available panels found", vim.log.levels.WARN)
    return false
end

---Switches to the previous panel
---@return boolean success Whether the switch was successful
function Panel.tabprevious()
    local log = get_logger()
    local config = require("switchpanel").ops
    
    -- Check if there's an active panel
    if not Panel.active then
        log.debug("No active panel to switch from")
        return false
    end
    
    -- Close current panel
    local close_success = Panel.close(Panel.active)
    if not close_success then
        log.warn("Failed to close active panel before switching to previous")
    end
    
    -- Try to find a valid previous panel
    local max_attempts = #config.builtin
    local attempts = 0
    local prev_tabnr = Panel.tabnr
    local open_success = false
    
    while attempts < max_attempts do
        -- Calculate previous panel index
        if prev_tabnr == 1 then
            if not config.tab_repeat then
                log.debug("Already at first panel and tab_repeat is disabled")
                return false
            end
            prev_tabnr = #config.builtin
            log.debug("Wrapping around to last panel")
        else
            prev_tabnr = prev_tabnr - 1
        end
        
        attempts = attempts + 1
        
        -- Check if previous panel exists and is valid
        local prev_panel = config.builtin[prev_tabnr]
        if not prev_panel then
            log.warn("Previous panel at index %d not found, trying next", prev_tabnr)
            goto continue
        end
        
        local is_valid, err_msg = validate_panel(prev_panel)
        if not is_valid then
            log.warn("Invalid previous panel configuration: %s, trying next", err_msg)
            goto continue
        end
        
        -- Try to open the panel
        open_success = Panel.open(prev_panel)
        if open_success then
            Panel.tabnr = prev_tabnr
            log.debug("Switched to previous panel %d", prev_tabnr)
            return true
        else
            log.warn("Failed to open panel %d, trying next", prev_tabnr)
        end
        
        ::continue::
    end
    
    log.error("Failed to open previous panel after %d attempts", attempts)
    vim.notify("SwitchPanel: No available panels found", vim.log.levels.WARN)
    return false
end

---Toggles the current panel
---@return boolean success Whether the toggle was successful
function Panel.toggle()
    local log = get_logger()
    local config = require("switchpanel").ops
    
    if not Panel.active then
        -- Open the panel
        local panel = config.builtin[Panel.tabnr]
        if not panel then
            log.error("Panel at index %d not found for toggle", Panel.tabnr)
            vim.notify("SwitchPanel: Panel not found", vim.log.levels.ERROR)
            return false
        end
        
        local is_valid, err_msg = validate_panel(panel)
        if not is_valid then
            log.error("Invalid panel configuration for toggle: %s", err_msg)
            vim.notify("SwitchPanel: Invalid panel configuration", vim.log.levels.ERROR)
            return false
        end
        
        local success = Panel.open(panel)
        log.debug("Toggled panel %d to open state: %s", Panel.tabnr, success)
        return success
    else
        -- Close the panel
        local success = Panel.close(Panel.active)
        log.debug("Toggled panel to closed state: %s", success)
        return success
    end
end

---Closes a panel
---@param panel table The panel to close
---@return boolean success Whether the panel was closed successfully
function Panel.close(panel)
    local log = get_logger()
    
    -- Validate panel
    local is_valid, err_msg = validate_panel(panel)
    if not is_valid then
        log.error("Cannot close invalid panel: %s", err_msg)
        vim.notify("SwitchPanel: Invalid panel configuration", vim.log.levels.WARN)
        return false
    end
    
    -- Close panel list
    local list_closed = pcall(PanelList.close)  -- Safely close panel list
    if not list_closed then
        log.warn("Failed to close panel list")
    end
    
    Panel.active = nil
    Panel.resume = panel
    
    -- Execute close command
    local success, err = pcall(function()
        cmd(panel.close)
    end)
    
    if not success then
        log.error("Failed to close panel: %s", err)
        vim.notify("Failed to close panel: " .. err, vim.log.levels.ERROR)
        return false
    end
    
    log.debug("Panel closed successfully: %s", panel.filetype)
    return true
end

---Opens a panel
---@param panel table The panel to open
---@return boolean success Whether the panel was opened successfully
function Panel.open(panel)
    local log = get_logger()
    
    -- Validate panel
    local is_valid, err_msg = validate_panel(panel)
    if not is_valid then
        log.error("Cannot open invalid panel: %s", err_msg)
        vim.notify("SwitchPanel: Invalid panel configuration", vim.log.levels.ERROR)
        return false
    end
    
    -- Check if the panel command exists before executing
    local command_exists = true
    local command_name = panel.open:match("^(%S+)")
    
    if command_name then
        -- Try to check if the command exists
        local cmd_exists, _ = pcall(function()
            return vim.api.nvim_get_commands({})[""][""][command_name] ~= nil
        end)
        
        if not cmd_exists then
            -- Try alternative method to check command existence
            cmd_exists = pcall(function() 
                vim.cmd("silent! command " .. command_name)
                return vim.fn.exists(":" .. command_name) == 2
            end)
        end
        
        command_exists = cmd_exists
    end
    
    if not command_exists then
        log.warn("Panel command '%s' not found - plugin may not be installed or loaded", command_name or panel.open)
        vim.notify("SwitchPanel: Panel '" .. (panel.filetype or "") .. "' not available - plugin may not be installed or loaded", vim.log.levels.WARN)
        return false
    end
    
    Panel.active = panel
    Panel.resume = nil
    
    -- Execute open command
    local success, err = pcall(function()
        cmd(panel.open)
    end)
    
    if not success then
        log.error("Failed to open panel: %s", err)
        vim.notify("Failed to open panel: " .. err, vim.log.levels.ERROR)
        Panel.active = nil
        return false
    end
    
    -- Open panel list and set cursor
    local list_ok, list_err = pcall(function()
        PanelList.open()
        PanelList.set_cursor()
    end)
    
    if not list_ok then
        log.warn("Failed to setup panel list: %s", list_err)
    end
    
    -- Always setup mouse event handler after panel is opened
    -- Use defer_fn to ensure the window is fully loaded before setting up autocmd
    vim.defer_fn(function()
        if PanelList.winnr and api.nvim_win_is_valid(PanelList.winnr) then
            log.debug("Setting up mouse event handler for panel: %s", panel.filetype)
            pcall(PanelList.setup_autocmd)
        end
    end, 100) -- 100ms delay to ensure window is ready
    
    log.debug("Panel opened successfully: %s", panel.filetype)
    return true
end

return Panel
