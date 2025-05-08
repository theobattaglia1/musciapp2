import os
enum Log {
    private static let sub = "com.example.artistmusic"
    static let ui = Logger(subsystem: sub, category: "UI")
    static let store = Logger(subsystem: sub, category: "Store")
    static let audio = Logger(subsystem: sub, category: "Audio")
}
