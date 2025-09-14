import Foundation
import RemindianCore

func printUsage() {
    let exe = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "remindian"
    print("Usage: \(exe) <markdown-file>\nParses checklist lines of form: - [] Task text  %% optional comment %%")
}

let args = Array(CommandLine.arguments.dropFirst())

guard let first = args.first else {
    printUsage()
    exit(1)
}

let url = URL(fileURLWithPath: first)

guard FileManager.default.fileExists(atPath: url.path) else {
    fputs("File not found: \(url.path)\n", stderr)
    exit(2)
}

do {
    let data = try String(contentsOf: url)
    let items = ChecklistParser.parseLines(data)
    if items.isEmpty {
        print("No reminders found in file: \(url.path)")
    } else {
        for item in items { print(item.description) }
    }
} catch {
    fputs("Failed to read file: \(error)\n", stderr)
    exit(3)
}
