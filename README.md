# remindian

![remindian](./img/remindian.png)

Automated reminder manager sourced from Obsidian check lists in neovim.

## Overview

Remindian is a command-line tool that scans markdown files Obsidian in neovim. style checklists and creates reminders in macOS Reminders app for incomplete tasks. It is designed to be used within a neovim environment, leveraging its capabilities to manage notes and tasks efficiently.

## Features

* Parse markdown files for Obsidian checklists
* Identify tasks (e.g., `- [ ] Task`)
* Create or update reminders in macOS Reminders app

## Development

Build the project:

```
make build
```

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

## Next Steps

* Support completed tasks parsing (- \[x])
* Extract metadata (dates, tags) beyond Obsidian comments
* Map checklist items to reminders
* Schedule and sync with Reminders API
* Provide dedicated examples repository with diverse fixtures
