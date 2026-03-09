import AppKit

let app = NSApplication.shared
// Keep a strong global reference — NSApplication.delegate is weak
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
