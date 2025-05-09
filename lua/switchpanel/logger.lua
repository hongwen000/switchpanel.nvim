local Logger = {}

-- Log levels
Logger.levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5
}

-- Default configuration
Logger.config = {
    level = Logger.levels.WARN,  -- Default log level
    use_console = true,         -- Log to Neovim's notification system
    use_file = false,           -- Log to file
    file_path = nil,            -- Path to log file (default: stdpath("cache")/switchpanel.log)
    prefix = "[SwitchPanel] ",  -- Prefix for log messages
}

-- Initialize the logger
function Logger.setup(opts)
    opts = opts or {}
    
    -- Merge user options with defaults
    for k, v in pairs(opts) do
        Logger.config[k] = v
    end
    
    -- Set default log file path if logging to file is enabled
    if Logger.config.use_file and not Logger.config.file_path then
        Logger.config.file_path = vim.fn.stdpath("cache") .. "/switchpanel.log"
    end
    
    -- Create log file if it doesn't exist
    if Logger.config.use_file then
        local file = io.open(Logger.config.file_path, "a")
        if file then
            file:write("\n--- SwitchPanel.nvim log started " .. os.date("%Y-%m-%d %H:%M:%S") .. " ---\n")
            file:close()
        else
            vim.notify(
                "Failed to create log file at " .. Logger.config.file_path,
                vim.log.levels.ERROR
            )
            Logger.config.use_file = false
        end
    end
    
    return Logger
end

-- Internal logging function
local function log(level_name, level, msg, ...)
    if level < Logger.config.level then
        return
    end
    
    -- Format message with any additional arguments
    local formatted_msg = msg
    local args = {...}
    if #args > 0 then
        formatted_msg = string.format(msg, unpack(args))
    end
    
    -- Add prefix
    formatted_msg = Logger.config.prefix .. level_name .. ": " .. formatted_msg
    
    -- Log to console
    if Logger.config.use_console then
        local vim_level
        if level == Logger.levels.DEBUG or level == Logger.levels.INFO then
            vim_level = vim.log.levels.INFO
        elseif level == Logger.levels.WARN then
            vim_level = vim.log.levels.WARN
        else
            vim_level = vim.log.levels.ERROR
        end
        
        vim.notify(formatted_msg, vim_level)
    end
    
    -- Log to file
    if Logger.config.use_file then
        local file = io.open(Logger.config.file_path, "a")
        if file then
            file:write(os.date("%Y-%m-%d %H:%M:%S ") .. formatted_msg .. "\n")
            file:close()
        end
    end
end

-- Public logging methods
function Logger.debug(msg, ...)
    log("DEBUG", Logger.levels.DEBUG, msg, ...)
end

function Logger.info(msg, ...)
    log("INFO", Logger.levels.INFO, msg, ...)
end

function Logger.warn(msg, ...)
    log("WARN", Logger.levels.WARN, msg, ...)
end

function Logger.error(msg, ...)
    log("ERROR", Logger.levels.ERROR, msg, ...)
end

-- Helper function to dump a table for debugging
function Logger.dump(value, description, depth)
    if Logger.config.level > Logger.levels.DEBUG then
        return
    end
    
    description = description or "Value"
    depth = depth or 3
    
    local function dump_table(t, indent, max_depth, current_depth)
        if current_depth > max_depth then
            return indent .. "..."
        end
        
        local result = ""
        for k, v in pairs(t) do
            local key_str = tostring(k)
            if type(v) == "table" then
                result = result .. indent .. key_str .. " = {\n"
                result = result .. dump_table(v, indent .. "  ", max_depth, current_depth + 1)
                result = result .. indent .. "}\n"
            else
                result = result .. indent .. key_str .. " = " .. tostring(v) .. "\n"
            end
        end
        return result
    end
    
    local result
    if type(value) == "table" then
        result = description .. " = {\n" .. dump_table(value, "  ", depth, 1) .. "}"
    else
        result = description .. " = " .. tostring(value)
    end
    
    log("DEBUG", Logger.levels.DEBUG, result)
end

return Logger