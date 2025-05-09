-- SwitchPanel command definitions

-- Local references
local api = vim.api
local Panel = require("switchpanel.panel")
local PanelList = require("switchpanel.panel_list")

-- Create user commands
api.nvim_create_user_command("SwitchPanelSwitch", function(arg)
    Panel.switch(tonumber(arg.args) or 1)
end, { nargs = "?" })

api.nvim_create_user_command("SwitchPanelNext", function(_)
    Panel.tabnext()
end, {})

api.nvim_create_user_command("SwitchPanelPrevious", function(_)
    Panel.tabprevious()
end, {})

api.nvim_create_user_command("SwitchPanelToggle", function(_)
    Panel.toggle()
end, {})

api.nvim_create_user_command("SwitchPanelListOpen", function(_)
    PanelList.open()
end, {})

api.nvim_create_user_command("SwitchPanelListClose", function(_)
    PanelList.close()
end, {})

api.nvim_create_user_command("SwitchPanel", function(_)
    PanelList.open()
end, {})
