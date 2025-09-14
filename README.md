# remindian

Automated reminder manager sourced from Obsidian check lists (initial scaffold).

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
- Support completed tasks parsing (- [x])
- Extract metadata (dates, tags) beyond Obsidian comments
- Map checklist items to reminders
- Schedule and sync with Reminders API
- Provide dedicated examples repository with diverse fixtures
