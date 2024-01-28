// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "iOSToolsMacrosMacros", type: "StringifyMacro")

// usage: fatalError(#saveTrace("division by zero"))
@freestanding(expression)
public macro saveTrace<T>(_ value: T) -> String = #externalMacro(module: "iOSToolsMacrosMacros", type: "SaveTraceMacro")

// usage: #fatalError("division by zero")
// if the Resilient property in Info.plist equals true, an error message is printed and saved, and a fatalError() let the app exit (in case a debugger is attached, a "detach" command in the CLI must be entered to create the crash log on the device). If it is set to false, an error message is printed and saved but the code flow continues to try not to crash.
@freestanding(expression)
public macro fatalError<T>(_ value: T) -> Void = #externalMacro(module: "iOSToolsMacrosMacros", type: "FatalErrorMacro")
