# remindian

![remindian](./img/remindian.png)

Automated reminder manager sourced from Obsidian check lists in neovim.

## Overview

Remindian is a command-line tool that scans markdown files Obsidian in neovim. style checklists and creates reminders in macOS Reminders app for incomplete tasks. It is designed to be used within a neovim environment, leveraging its capabilities to manage notes and tasks efficiently.

## Features

* Parse markdown files for Obsidian checklists
* Identify tasks (e.g., `- [ ] Task`)
* Create or update reminders in macOS Reminders app
* Automatically runs when saving markdown files in Neovim
* Can be manually triggered with the `:RemindianRun` command

## Development

Build the project:

```
make build
```

This will create the binary in the `bin/remindian` location within the plugin directory, which the Neovim plugin will automatically detect and use.

Run the CLI on a markdown file:

```
make run ARGS="path/to/file.md"
```

Run tests:

```
make test
```

Clean build artifacts:

```
make clean
```

## Neovim Plugin Configuration

Configure the plugin in your Neovim config:

```lua
require('remindian').setup({
  enable_logging = false, -- Enable debug logging
  log_level = 'info',     -- Log level (debug, info, warn, error)
  filetype = 'markdown',  -- Default filetype to use for reminders
  reminder_list = 'remindian', -- Default reminder list to use with --list flag
})
```

## Next Steps

* Support completed tasks parsing (- \[x])
* Extract metadata (dates, tags) beyond Obsidian comments
* Map checklist items to reminders
* Schedule and sync with Reminders API
* Provide dedicated examples repository with diverse fixtures
