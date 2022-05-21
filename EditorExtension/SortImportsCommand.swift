//
//  SortImportsCommand.swift
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

class SortImportsCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        defer { completionHandler(nil) }

        let selections = invocation.buffer.selections.compactMap { $0 as? XCSourceTextRange }

        for selection in selections {
            // must have more than one line to sort
            guard selection.start.line < selection.end.line else {
                continue
            }

            sort(invocation.buffer.lines, in: selection.start.line...selection.end.line, by: <)
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
