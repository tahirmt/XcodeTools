//
//  LowercaseCommand.swift
//  Xcode Tools
//
//  Created by Mahmood Tahir on 2022-05-21.
//

import Foundation
import XcodeKit

class LowercaseCommand: NSObject, XCSourceEditorCommand {
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

                invocation.buffer.lines[lineNumber] = line.replacingCharacters(in: range, with: selectedText.lowercased())
            }
        }
    }

    func sort(_ inputLines: NSMutableArray, in range: CountableClosedRange<Int>, by comparator: (String, String) -> Bool) {
        guard range.upperBound < inputLines.count, range.lowerBound >= 0 else {
            return
        }

        let lines = inputLines.compactMap { $0 as? String }
        let sorted = Array(lines[range]).sorted(by: comparator)

        for lineIndex in range {
            inputLines[lineIndex] = sorted[lineIndex - range.lowerBound]
        }
    }
}
