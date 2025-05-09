local PanelList = {}

-- Define module constants
PanelList.FILETYPE = "SwitchPanelList"

-- Local references
local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

-- Get logger
local logger
local function get_logger()
    if not logger then
        logger = require("switchpanel").logger or require("switchpanel.logger")
    end
    return logger
end

---Renders the panel list with icons from configured builtin panels
---@return boolean success Whether the render was successful
function PanelList.render()
    local log = get_logger()
    local config = require("switchpanel").ops
    
    if not PanelList.bufnr then
        log.error("Cannot render panel list: buffer not created")
        return false
    end
    
    -- Check if buffer is valid
    local is_valid = pcall(api.nvim_buf_is_valid, PanelList.bufnr)
    if not is_valid then
        log.error("Cannot render panel list: buffer is invalid")
        return false
    end
    
    local lines = {}
    
    -- Validate builtin panels
    if not config or not config.builtin then
        log.error("Cannot render panel list: configuration is invalid")
        return false
    end
    
    -- Generate lines for each panel
    for i, panel in pairs(config.builtin) do
        table.insert(lines, " ")
        local icon = " "
        if type(panel) == "table" and panel.icon then
            icon = icon .. panel.icon
        else
            icon = icon .. "?"
            log.warn("Panel at index %d has no icon", i)
        end
        table.insert(lines, icon)
    end
    
    -- Add padding
    for _ = 1, 100 do
        table.insert(lines, " ")
    end
    
    -- Set buffer lines
    local ok, err = pcall(function()
        api.nvim_buf_set_lines(PanelList.bufnr, 0, -1, true, lines)
    end)
    
    if not ok then
        log.error("Failed to set buffer lines: %s", err)
        return false
    end
    
    log.debug("Panel list rendered successfully with %d panels", #config.builtin)
    return true
end

---Sets up autocmd for buffer enter events and mouse click handling
---@return nil
function PanelList.setup_autocmd()
    local log = get_logger()
    
    -- Buffer enter event handling
    api.nvim_create_autocmd("BufEnter", {
        pattern = "<buffer=" .. PanelList.bufnr .. ">",
        callback = function()
            local win = fn.winnr()
            if PanelList.nofocus then
                if win == fn.winnr("1h") then
                    cmd("wincmd 10l")
                else
                    cmd("wincmd p")
                end
            end
        end,
    })
    
    -- ModeChanged event handling for buffer options
    api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = function()
            if api.nvim_get_current_buf() == PanelList.bufnr then
                api.nvim_buf_set_option(PanelList.bufnr, "modifiable", true)
                api.nvim_buf_set_option(PanelList.bufnr, "modifiable", false)
            end
        end,
    })
    
    -- Proper mouse click handling with keymaps
    local function handle_mouse_click()
        local pos = vim.fn.getmousepos()
        
        -- Check if the click is in our panel list window
        if pos.winid == PanelList.winnr then
            local row = pos.line
            
            -- Calculate panel index from row (every other row has an icon)
            if row % 2 == 0 then -- Even rows have icons
                local panel_index = row / 2
                log.debug("Mouse click detected on panel %d", panel_index)
                
                -- Switch to the clicked panel
                local Panel = require("switchpanel.panel")
                local success = Panel.switch(panel_index)
                
                if not success then
                    log.warn("Failed to switch to panel %d via mouse click", panel_index)
                end
            end
        end
    end
    
    -- Set up left mouse click mapping for the panel list buffer
    vim.keymap.set('n', '<LeftMouse>', handle_mouse_click, {
        buffer = PanelList.bufnr,
        noremap = true,
        silent = true,
        desc = "SwitchPanel: Switch to clicked panel"
    })
    
    -- Double-click for faster switching
    vim.keymap.set('n', '<2-LeftMouse>', handle_mouse_click, {
        buffer = PanelList.bufnr,
        noremap = true,
        silent = true,
        desc = "SwitchPanel: Switch to clicked panel (double-click)"
    })
    
    log.debug("Mouse handling set up for panel list buffer")
end

---Creates and configures the panel list buffer
---@return boolean success Whether the buffer was created successfully
function PanelList.create_buffer()
    local log = get_logger()
    
    -- Create buffer
    local ok, result = pcall(function()
        return api.nvim_create_buf(false, false)
    end)
    
    if not ok or not result then
        log.error("Failed to create panel list buffer: %s", result or "unknown error")
        vim.notify("Failed to create panel list buffer", vim.log.levels.ERROR)
        return false
    end
    
    PanelList.bufnr = result
    
    -- Set buffer name
    local name_ok, name_err = pcall(function()
        api.nvim_buf_set_name(PanelList.bufnr, PanelList.FILETYPE)
    end)
    
    if not name_ok then
        log.warn("Failed to set buffer name: %s", name_err)
    end
    
    -- Render panel list
    local render_ok = PanelList.render()
    if not render_ok then
        log.warn("Failed to render panel list during buffer creation")
    end

    -- Set buffer options
    local buffer_options = {
        { name = "swapfile", val = false },
        { name = "buftype", val = "nofile" },
        { name = "modifiable", val = false },
        { name = "filetype", val = PanelList.FILETYPE },
        { name = "bufhidden", val = "hide" },
    }
    
    for _, opt in ipairs(buffer_options) do
        local opt_ok, opt_err = pcall(function()
            vim.bo[PanelList.bufnr][opt.name] = opt.val
        end)
        
        if not opt_ok then
            log.warn("Failed to set buffer option '%s': %s", opt.name, opt_err)
        end
    end
    
    log.debug("Panel list buffer created successfully")
    return true
end

---Creates and configures the panel list window
---@return nil
function PanelList.create_window()
    cmd("vsp")
    
    local window_options = {
        relativenumber = false,
        number = false,
        list = false,
        winfixwidth = true,
        winfixheight = true,
        foldenable = false,
        spell = false,
        signcolumn = "no",
        foldmethod = "manual",
        foldcolumn = "0",
        cursorcolumn = false,
        colorcolumn = "0",
    }
    
    for option, value in pairs(window_options) do
        api.nvim_win_set_option(0, option, value)
    end
end

---Sets up window highlights for the panel list
---@return nil
function PanelList.setup_highlights()
    local config = require("switchpanel").ops
    
    -- Set window highlight groups
    api.nvim_win_set_option(
        0,
        "winhighlight",
        "Normal:PanelListNormal,EndOfBuffer:PanelList,VertSplit:PanelListVert,SignColumn:PanelList,CursorLine:PanelListSelected"
    )
    
    -- Define highlight groups
    api.nvim_set_hl(0, "PanelList", {
        fg = "NONE",
        bg = config.panel_list.background,
    })
    
    api.nvim_set_hl(0, "PanelListVert", {
        fg = config.panel_list.background,
        bg = config.panel_list.background,
    })
    
    api.nvim_set_hl(0, "PanelListSelected", {
        fg = "NONE",
        bg = config.panel_list.selected,
    })
    
    api.nvim_set_hl(0, "PanelListNormal", {
        fg = config.panel_list.color or "none",
        bg = config.panel_list.background,
    })
end

---Opens the panel list
---@return boolean success Whether the panel list was opened successfully
function PanelList.open()
    local log = get_logger()
    
    -- Check if already open
    if PanelList.is_open() then
        log.debug("Panel list is already open")
        return true
    end
    
    -- Create buffer if needed
    if not PanelList.bufnr then
        log.debug("Creating new panel list buffer")
        if not PanelList.create_buffer() then
            log.error("Failed to create panel list buffer")
            return false
        end
    end
    
    -- Create window and set up panel list
    local ok, err = pcall(function()
        PanelList.create_window()
        cmd("buffer " .. PanelList.bufnr)
        cmd("wincmd H")
        
        PanelList.winnr = api.nvim_get_current_win()
        api.nvim_win_set_width(0, 2)

        PanelList.setup_highlights()

        cmd("wincmd p")
        PanelList.nofocus = true
        PanelList.setup_autocmd()
    end)
    
    if not ok then
        log.error("Failed to open panel list: %s", err)
        vim.notify("Failed to open panel list: " .. err, vim.log.levels.ERROR)
        return false
    end
    
    log.debug("Panel list opened successfully")
    return true
end

---Closes the panel list
---@return boolean success Whether the panel list was closed successfully
function PanelList.close()
    local log = get_logger()
    
    PanelList.nofocus = false
    local win = PanelList.get_window_by_filetype(PanelList.FILETYPE)
    
    if not win then
        log.debug("No panel list window to close")
        return true
    end
    
    -- Close window
    local ok, err = pcall(function()
        api.nvim_win_close(win, true)
    end)
    
    if not ok then
        log.error("Failed to close panel list window: %s", err)
        return false
    end
    
    log.debug("Panel list closed successfully")
    return true
end

---Sets the cursor position in the panel list
---@return nil
function PanelList.set_cursor()
    local config = require("switchpanel").ops
    local win = PanelList.get_window_by_filetype(PanelList.FILETYPE)
    local active = PanelList.get_active_panel()
    
    if not active then
        vim.notify("No active panel found", vim.log.levels.WARN)
        return
    end
    
    PanelList.nofocus = false
    api.nvim_win_set_cursor(win, { active.count * 2, 1 })
    api.nvim_win_set_width(active.win, config.width)
    
    if config.focus_on_open then
        cmd("wincmd 10h")
        cmd("wincmd l")
    else
        cmd("wincmd 10h")
        cmd("wincmd 2l")
    end
    
    PanelList.nofocus = true
end

---Gets the currently active panel
---@return table|nil The active panel information or nil if none is active
function PanelList.get_active_panel()
    local config = require("switchpanel").ops
    local count = 0
    
    for _, panel in pairs(config.builtin) do
        count = count + 1
        local win, bufnr = PanelList.get_window_by_filetype(panel.filetype)
        
        if win then
            return { count = count, builtin = panel, win = win, bufnr = bufnr }
        end
    end
    
    return nil
end

---Gets a window by its filetype
---@param filetype string The filetype to search for
---@return number|nil win The window handle or nil if not found
---@return number|nil bufnr The buffer number or nil if not found
function PanelList.get_window_by_filetype(filetype)
    for _, win in pairs(api.nvim_list_wins()) do
        local bufnr = api.nvim_win_get_buf(win)
        local win_filetype = vim.bo[bufnr].filetype
        
        if filetype == win_filetype then
            return win, bufnr
        end
    end
    
    return nil
end

---Checks if the panel list is currently open
---@return boolean True if the panel list is open, false otherwise
function PanelList.is_open()
    return PanelList.get_window_by_filetype(PanelList.FILETYPE) ~= nil
end

return PanelList
