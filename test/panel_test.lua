-- Basic test for SwitchPanel functionality
local Panel = require("switchpanel.panel")
local PanelList = require("switchpanel.panel_list")

describe("SwitchPanel", function()
    before_each(function()
        -- Setup the plugin with test configuration
        require("switchpanel").setup({
            builtin = {
                "nvim-tree.lua",
                "undotree"
            }
        })
    end)
    
    it("should initialize with correct defaults", function()
        local config = require("switchpanel").ops
        assert.is_table(config)
        assert.is_table(config.builtin)
        assert.is_table(config.panel_list)
        assert.equals(30, config.width)
        assert.equals(true, config.focus_on_open)
    end)
    
    it("should have proper panel list functions", function()
        assert.is_function(PanelList.open)
        assert.is_function(PanelList.close)
        assert.is_function(PanelList.is_open)
        assert.is_function(PanelList.get_active_panel)
    end)
    
    it("should have proper panel functions", function()
        assert.is_function(Panel.switch)
        assert.is_function(Panel.tabnext)
        assert.is_function(Panel.tabprevious)
        assert.is_function(Panel.toggle)
    end)
end)