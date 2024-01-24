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
