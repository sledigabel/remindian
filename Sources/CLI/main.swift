import Foundation
import RemindianCore

func printUsage() {
    let exe = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "remindian"
    print(
        "Usage: \(exe) [--list <list-name>] <markdown-file>\nParses checklist lines of form: - [] Task text  %% optional comment %%\n\nOptions:\n  --list <list-name>    Specify which list reminders belong to (default: \"remindian\")"
    )
}

let args = Array(CommandLine.arguments.dropFirst())
var listName = "remindian"  // Default list name
var filePath: String? = nil

// Parse arguments
var i = 0
while i < args.count {
    let arg = args[i]
    if arg == "--list" {
        guard i + 1 < args.count else {
            fputs("Error: --list requires a value\n", stderr)
            printUsage()
            exit(1)
        }
        listName = args[i + 1]
        i += 2
    } else {
        // First non-option argument is the file path
        filePath = arg
        i += 1
    }
}

// Ensure we have a file path
guard let filePath = filePath else {
    printUsage()
    exit(1)
}
let url = URL(fileURLWithPath: filePath)

guard FileManager.default.fileExists(atPath: url.path) else {
    fputs("File not found: \(url.path)\n", stderr)
    exit(2)
}

do {
    let data = try String(contentsOf: url)
    let items = ChecklistParser.parseLines(data, list: listName)
    if items.isEmpty {
        print("No reminders found in file: \(url.path)")
    } else {
        for item in items { print(item.description) }
    }
} catch {
    fputs("Failed to read file: \(error)\n", stderr)
    exit(3)
}
