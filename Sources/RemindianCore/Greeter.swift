public struct Greeter {
    public static func hello(name: String? = nil) -> String {
        if let name, !name.isEmpty {
            return "Hello, \(name)!"
        }
        return "Hello, world!"
    }
}
