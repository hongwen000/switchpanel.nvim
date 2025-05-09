# SwitchPanel.nvim Debugging Guide

## Overview

SwitchPanel.nvim now includes comprehensive error handling and debugging capabilities to help troubleshoot issues and improve plugin stability. This guide explains how to use these features.

## Debug Configuration

You can enable debug mode by adding a `debug` section to your configuration:

```lua
require("switchpanel").setup({
    -- Your regular configuration here
    
    -- Debug configuration
    debug = {
        level = "INFO",       -- DEBUG, INFO, WARN, ERROR, OFF
        use_console = true,   -- Log to Neovim's notification system
        use_file = true,      -- Log to file
        file_path = nil,      -- Custom log file path (default: stdpath("cache")/switchpanel.log)
    }
})
```

## Log Levels

The following log levels are available (from most to least verbose):

- `DEBUG`: Detailed information, useful for development and troubleshooting
- `INFO`: General information about normal operation
- `WARN`: Warning messages that don't prevent operation but indicate potential issues
- `ERROR`: Error messages that may prevent proper operation
- `OFF`: Disable logging completely

## Log File

When `use_file` is enabled, logs are written to a file. By default, this file is located at:

```
:echo stdpath("cache") . "/switchpanel.log"
```

You can specify a custom path using the `file_path` option.

## Troubleshooting Common Issues

### Panel Not Opening

If a panel fails to open, check:

1. Is the panel plugin installed? (e.g., nvim-tree.lua, aerial.nvim)
2. Are the panel commands correct in your configuration?
3. Enable DEBUG level logging to see detailed error messages

### Panel List Not Displaying

If the panel list doesn't appear:

1. Check if `panel_list.show` is set to `true` in your configuration
2. Look for error messages in the log file
3. Verify that your terminal supports the colors specified in the configuration

### Key Mappings Not Working

If key mappings don't work:

1. Check if the mappings are correctly defined in your configuration
2. Verify that there are no conflicts with other plugins
3. Enable DEBUG level logging to see if the mappings are being registered

## Reporting Issues

When reporting issues, please include:

1. Your SwitchPanel configuration
2. Log file contents with DEBUG level enabled
3. Neovim version (`nvim --version`)
4. Steps to reproduce the issue

## Advanced Debugging

For advanced debugging, you can use the logger API directly in your configuration:

```lua
local switchpanel = require("switchpanel")
switchpanel.setup({
    -- Your configuration
})

-- Access logger after setup
local logger = switchpanel.logger
logger.debug("Custom debug message")
```

This can be useful for debugging custom panel configurations or integration with other plugins.