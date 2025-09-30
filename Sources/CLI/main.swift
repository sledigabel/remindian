import Foundation
import RemindianCore

func printUsage() {
    let exe = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "remindian"
    print(
        """
        Usage: \(exe) [options] <markdown-file>
        Parses checklist lines of form: - [] Task text  %% optional comment %%
        
        Options:
          --list <list-name>    Specify which list reminders belong to (default: "remindian")
          --output <file>       Output to a different file (implies file rewriting)
          --rewrite             Rewrite the original file with updates
        """
    )
}

// Parse arguments
let args = Array(CommandLine.arguments.dropFirst())
var listName = "remindian"  // Default list name
var filePath: String? = nil
var outputPath: String? = nil
var shouldRewrite = false   // Flag to control rewriting the original file

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
    } else if arg == "--output" {
        guard i + 1 < args.count else {
            fputs("Error: --output requires a value\n", stderr)
            printUsage()
            exit(1)
        }
        outputPath = args[i + 1]
        i += 2
    } else if arg == "--rewrite" {
        shouldRewrite = true
        i += 1
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

// Run the async processing in Task
Task {
    do {
        let localListName = listName // Local copy to avoid async issues
        
        // Check if we should rewrite (based on presence of outputPath or shouldRewrite flag)
        if let outputPathValue = outputPath {
            // Rewrite to a different file
            let outputURL = URL(fileURLWithPath: outputPathValue)
            
            let resultURL = try await ChecklistParser.rewriteFile(at: url, outputURL: outputURL)
            print("File has been rewritten: \(resultURL.path)")
            
            // Display the reminders in the rewritten file
            let rewrittenData = try String(contentsOf: resultURL)
            let items = ChecklistParser.parseLines(rewrittenData, list: localListName)
            if !items.isEmpty {
                print("\nReminders in the rewritten file:")
                for item in items { print(item.description) }
            }
        } else if shouldRewrite {
            // Rewrite the original file
            let resultURL = try await ChecklistParser.rewriteFile(at: url)
            print("Original file has been rewritten: \(resultURL.path)")
            
            // Display the reminders in the rewritten file
            let rewrittenData = try String(contentsOf: resultURL)
            let items = ChecklistParser.parseLines(rewrittenData, list: localListName)
            if !items.isEmpty {
                print("\nReminders in the rewritten file:")
                for item in items { print(item.description) }
            }
        } else {
            // Original behavior - just parse and display
            let data = try String(contentsOf: url)
            let items = ChecklistParser.parseLines(data, list: localListName)
            if items.isEmpty {
                print("No reminders found in file: \(url.path)")
            } else {
                for item in items { print(item.description) }
                
                // Inform the user that no changes were made to the file
                print("\nNote: File was only parsed, not modified. Use --rewrite to update the file or --output to write to a new file.")
            }
        }
        exit(0)
    } catch {
        fputs("Failed to process file: \(error)\n", stderr)
        exit(3)
    }
}

// Keep the process running until our Task completes
RunLoop.main.run()
