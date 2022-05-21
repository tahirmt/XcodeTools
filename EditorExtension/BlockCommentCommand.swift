//
//  BlockCommentCommand.swift
//  EditorExtension
//
//  MIT License
//
//  Copyright (c) 2022 Mahmood Tahir
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Mahmood Tahir on 2022-05-21.

import Foundation
import XcodeKit
import OSLog

class BlockCommentCommand: NSObject, XCSourceEditorCommand {
    private struct Operation {
        enum Kind {
            case insert
            case remove
            case replace
        }

        let kind: Kind
        let line: Int
        let value: String
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        defer { completionHandler(nil) }

        let selections = invocation.buffer.selections.compactMap { $0 as? XCSourceTextRange }

        let lines = invocation.buffer.lines
        var operations = [Operation]()

        selections.forEach { selection in
            // check if the previous line is a block comment start

            let startLine = lines[safe: selection.start.line] as? String
            let endLine = lines[safe: selection.end.line] as? String

            let previousLine = lines[safe: selection.start.line-1] as? String
            let nextLine = lines[safe: selection.end.line+1] as? String

            if let previousLine = previousLine, let nextLine = nextLine, previousLine.isBeginningOfBlockComment, nextLine.isEndOfBlockComment {
                os_log("remove previous and next lines", type: .debug)
                operations.append(Operation(kind: .remove, line: selection.start.line-1, value: previousLine))
                operations.append(Operation(kind: .remove, line: selection.end.line+1, value: nextLine))
            }
            else if let startLine = startLine, let endLine = endLine, startLine.isBeginningOfBlockComment, endLine.isEndOfBlockComment {
                os_log("remove begin and end", type: .debug)
                operations.append(Operation(kind: .remove, line: selection.start.line, value: startLine))
                operations.append(Operation(kind: .remove, line: selection.end.line, value: endLine))
            }
            else if let previousLine = previousLine, let endLine = endLine, previousLine.isBeginningOfBlockComment, endLine.isEndOfBlockComment {
                os_log("remove previous end end", type: .debug)
                operations.append(Operation(kind: .remove, line: selection.start.line-1, value: previousLine))
                operations.append(Operation(kind: .remove, line: selection.end.line, value: endLine))
            }
            else if let startLine = startLine, let nextLine = nextLine, startLine.isBeginningOfBlockComment, nextLine.isEndOfBlockComment {
                os_log("remove begin and next", type: .debug)
                operations.append(Operation(kind: .remove, line: selection.start.line, value: startLine))
                operations.append(Operation(kind: .remove, line: selection.end.line+1, value: nextLine))
            }
            else if var startLine = startLine, var endLine = endLine, startLine.startsInBlockComment && endLine.endsInBlockComment {
                os_log("Remove start and end", type: .debug)
                if let range = startLine.range(of: "/*") {
                    startLine.replaceSubrange(range, with: "")
                    operations.append(Operation(kind: .replace, line: selection.start.line, value: startLine))
                }

                if let range = endLine.range(of: "*/") {
                    endLine.replaceSubrange(range, with: "")
                    operations.append(Operation(kind: .replace, line: selection.end.line, value: endLine))
                }
            }
            else {
                os_log("insert block comment", type: .debug)
                // comment block
                operations.append(Operation(kind: .insert, line: selection.start.line, value: "/*"))
                operations.append(Operation(kind: .insert, line: selection.end.line+1, value: "*/"))
            }
        }

        // perform operations
        var outputLines = lines.compactMap { $0 as? String }
        var indexOffset = 0

        operations.forEach { operation in
            switch operation.kind {
            case .insert:
                outputLines.insert(operation.value, at: operation.line + indexOffset)
                indexOffset += 1
            case .replace:
                outputLines[operation.line] = operation.value
            case .remove:
                let indexToRemove = operation.line + indexOffset
                if outputLines.indices ~= indexToRemove {
                    outputLines.remove(at: indexToRemove)
                }
                indexOffset -= 1
            }
        }

        // apply the change
        lines.removeAllObjects()
        lines.addObjects(from: outputLines)
    }
}

extension String {
    var isBeginningOfBlockComment: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines) == "/*"
    }

    var isEndOfBlockComment: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines) == "*/"
    }

    var startsInBlockComment: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("/*")
    }

    var endsInBlockComment: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("*/")
    }
}

extension NSMutableArray {
    subscript(safe index: Int) -> Element? {
        index < count ? self[index] : nil
    }
}
