# SwitchPanel.nvim

Integrate a plugin to display NeoVim sidebars and switch between them like a VSCode sidebar. Now with improved error handling, mouse support, and debugging capabilities.

## Demo
![img](doc/demo.gif)

## Requirements

SwitchPanel.nvim can work with the following sidebar plugins:

- [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) - File explorer
- [sidebar.nvim](https://github.com/sidebar-nvim/sidebar.nvim) - Multi-component sidebar
- [undotree](https://github.com/mbbill/undotree) - Undo history visualizer
- [aerial.nvim](https://github.com/stevearc/aerial.nvim) - Code outline and symbol navigator

## Installation

### Using packer

```lua
use({
    "arakkkkk/switchpanel.nvim",
    config = function()
        require("switchpanel").setup({})
    end,
})
```

## Configuration

SwitchPanel.nvim can be configured with the following options:

```lua
require("switchpanel").setup({
    panel_list = {
        show = true,            -- Show the panel list
        background = "Blue",    -- Background color
        selected = "LightBlue", -- Selected item color
        color = "none",         -- Text color
    },

    width = 30,                -- Width of panels when opened

    focus_on_open = true,      -- Focus panel when opened

    tab_repeat = true,         -- Cycle through panels
    
    mappings = {              -- Key mappings in panel windows
        {"1", "SwitchPanelSwitch 1" },
        {"2", "SwitchPanelSwitch 2" },
        {"3", "SwitchPanelSwitch 3" },
        -- {"4", "SwitchPanelSwitch 4" },
        -- {"5", "SwitchPanelSwitch 5" },
        {"J", "SwitchPanelNext" },
        {"K", "SwitchPanelPrevious" },
    },

    builtin = {               -- Enabled builtin panels
        "nvim-tree.lua",
        "sidebar.nvim",
        "undotree",
        -- "aerial.nvim",
    },
    
    -- Debug configuration (optional)
    debug = {
        level = "WARN",        -- DEBUG, INFO, WARN, ERROR, OFF
        use_console = true,    -- Log to Neovim's notification system
        use_file = false,      -- Log to file
        file_path = nil,       -- Custom log file path (default: stdpath("cache")/switchpanel.log)
    }
})
```

## Commands

SwitchPanel.nvim provides the following commands:

- `:SwitchPanelSwitch [number]` - Switch to the panel with the specified number
- `:SwitchPanelNext` - Switch to the next panel in the list
- `:SwitchPanelPrevious` - Switch to the previous panel in the list
- `:SwitchPanelToggle` - Toggle the current panel (open if closed, close if open)
- `:SwitchPanelListOpen` - Open the panel list sidebar
- `:SwitchPanelListClose` - Close the panel list sidebar
- `:SwitchPanel` - Alias for SwitchPanelListOpen

## Usage

1. Configure the plugin with your desired panels
2. Use the commands to switch between panels
3. Use the key mappings defined in the configuration when a panel is active

## Custom Panels

You can add custom panels by providing a table with the following structure:

```lua
require("switchpanel").setup({
    builtin = {
        "nvim-tree.lua",
        {
            open = "YourPanelOpenCommand",
            close = "YourPanelCloseCommand",
            filetype = "your_panel_filetype",
            icon = "󰀘",  -- Icon to display in the panel list
            option = {},  -- Additional options
        }
    }
})
```

## Features

### Mouse Support

SwitchPanel.nvim now supports mouse interactions:

- **Click to Switch**: Click on panel icons in the sidebar to switch between panels
- **Intuitive Navigation**: Easily navigate between panels using either keyboard shortcuts or mouse clicks

### Improved Error Handling

SwitchPanel.nvim includes enhanced error handling for plugin management:

- **Missing Plugin Detection**: Gracefully handles missing or not-yet-loaded plugins
- **Lazy Loading Support**: Compatible with lazy-loaded plugins, avoiding errors when plugins aren't available
- **Smart Panel Switching**: When navigating with Next/Previous, automatically skips unavailable panels
- **Informative Messages**: Provides helpful notifications instead of error messages

### Debugging Capabilities

Comprehensive error handling and debugging tools to help troubleshoot issues:

- **Robust Error Handling**: All operations include proper error checking and recovery
- **Detailed Logging**: Configure log levels from DEBUG to ERROR to control verbosity
- **Log to File**: Optionally save logs to a file for persistent debugging
- **Dependency Validation**: Automatic checking of required Neovim API features
- **Configuration Validation**: Validates all user configuration options

For detailed debugging instructions, see [debug.md](doc/debug.md).

## License

MIT

