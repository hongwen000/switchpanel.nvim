-- SwitchPanel autocommands

-- Local references
local api = vim.api

---Sets up autocommands for SwitchPanel
---@return nil
local function setup_autocommands()
    local config = require("switchpanel").ops
    
    api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
            for _, panel in pairs(config.builtin) do
                local filetype = panel.filetype
                
                if vim.bo.filetype == filetype then
                    for _, keymap in pairs(config.mappings) do
                        local cmd = keymap[2]
                        
                        if type(cmd) == "string" then
                            cmd = "<cmd>" .. cmd .. "<cr>"
                        end
                        
                        vim.keymap.set(
                            "n", 
                            keymap[1], 
                            cmd, 
                            { silent = true, buffer = api.nvim_get_current_buf() }
                        )
                    end
                end
            end
        end,
    })
end

-- Initialize autocommands
setup_autocommands()
