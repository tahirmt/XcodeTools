//
//  CamelCaseCommand.swift
//  Xcode Tools
//
//  Created by Mahmood Tahir on 2022-05-21.
//

import Foundation
import XcodeKit

class CamelCaseCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        defer { completionHandler(nil) }

        let selections = invocation.buffer.selections.compactMap { $0 as? XCSourceTextRange }

        selections.forEach { selection in
            let lineNumber = selection.start.line
            let columnNumber = selection.start.column

            let endLineNumber = selection.end.line
            let endColumnNumber = selection.end.column

            // only do it if there is a selected text
            if let line = invocation.buffer.lines.object(at: lineNumber) as? NSString,
                lineNumber == endLineNumber && endColumnNumber > columnNumber {

                let range = NSRange(location: columnNumber, length: endColumnNumber-columnNumber)
                let selectedText = line.substring(with: range)

                invocation.buffer.lines[lineNumber] = line.replacingCharacters(in: range, with: selectedText.lowerCamelCased)
            }
        }
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    var upperCamelCased: String {
        upperCamelCased(ignoringCapitalLetters: false)
    }

    func upperCamelCased(ignoringCapitalLetters: Bool = false) -> String {
        lowercased()
            .split(separator: " ")
            .map {
                if ignoringCapitalLetters {
                    return String($0).capitalizingFirstLetter()
                }

                return $0.lowercased().capitalizingFirstLetter()
            }
            .joined()
    }

    var lowerCamelCased: String {
        lowerCamelCased(ignoringCapitalLetters: false)
    }

    func lowerCamelCased(ignoringCapitalLetters: Bool = false) -> String {
        let upperCased = self.upperCamelCased(ignoringCapitalLetters: ignoringCapitalLetters)
        if ignoringCapitalLetters {
            return String(upperCamelCased.prefix(1)) + upperCased.dropFirst()
        }

        return upperCamelCased.prefix(1).lowercased() + upperCased.dropFirst()
    }
}
