import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct SaveTraceMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        print("XXXX: Expanding SaveTraceMacro macro")
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return """
            Traces.addMessage(\(argument), fct: #function, path: #file, line: #line)
        """

        /*
        return """
          {
            var result: String = Traces.addMessage(\(argument), fct: #function, path: #file, line: #line)
            return result
          }()
        """
        */
    }
}

public struct FatalErrorMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        print("XXXX: Expanding FatalErrorMacro macro")
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return """
            {
                let _message = Traces.addMessage(\(argument), fct: #function, path: #file, line: #line)
                print("XXXX: \\(_message)")
                if isAppResilient == false { fatalError(_message) }
            }()
        """
    }
}

@main
struct iOSToolsMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        SaveTraceMacro.self,
        FatalErrorMacro.self
    ]
}
