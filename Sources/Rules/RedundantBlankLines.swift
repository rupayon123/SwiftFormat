//
//  RedundantBlankLines.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines that separate tightly connected syntax
    static let redundantBlankLines = FormatRule(
        help: "Remove redundant blank lines within declarations and between expression prefixes and their operands."
    ) { formatter in
        formatter.forEach(.attribute) { i, _ in
            guard let endOfAttribute = formatter.endOfAttribute(at: i),
                  let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: endOfAttribute),
                  formatter.tokens[linebreakIndex].isLinebreak,
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: linebreakIndex),
                  // Preserve blank lines before comments
                  !formatter.tokens[nextIndex].isComment,
                  let lastLinebreakIndex = formatter.index(of: .linebreak, before: nextIndex),
                  lastLinebreakIndex > linebreakIndex,
                  formatter.isDeclarationAttribute(at: i)
            else { return }

            formatter.removeTokens(in: linebreakIndex + 1 ... lastLinebreakIndex)
        }
        formatter.forEach(.linebreak) { i, _ in
            guard let previous = formatter.index(of: .nonSpace, before: i),
                  !formatter.tokens[previous].isLinebreak,
                  let next = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                  let lastLinebreak = formatter.index(of: .linebreak, before: next),
                  lastLinebreak > i,
                  formatter.blankLineSeparatesConnectedSyntax(previous, next)
            else { return }
            formatter.removeTokens(in: i + 1 ... lastLinebreak)
        }
    } examples: {
        """
        ```diff
          @MainActor
        -
          struct Foo {
              @State
        -
              var bar = 0
          }
        ```

        ```diff
          public
        -
          final class Foo {}

          let value = try
        -
              await load()
        ```

        Ordinary line wrapping is preserved. Blank lines between statements, arguments,
        collection elements, and at scope boundaries are left to other rules.
        """
    }
}

extension Formatter {
    /// Whether two tokens separated by whitespace belong to tightly connected syntax.
    /// Comments and conditional compilation boundaries deliberately prevent matching.
    func blankLineSeparatesConnectedSyntax(_ previous: Int, _ next: Int) -> Bool {
        let left = tokens[previous]
        let right = tokens[next]
        guard !left.isComment, !right.isComment,
              currentScope(at: previous)?.isMultilineStringDelimiter != true
        else { return false }

        // Declaration modifiers, including parenthesized modifiers such as private(set).
        // A standalone async may belong to a preceding bodyless function, not the following let.
        if left.isModifierKeyword || left == .endOfScope(")") || left.isAttribute,
           left.string != "async",
           right.isModifierKeyword || right.isDeclarationTypeKeyword || right.isAttribute,
           let keyword = index(after: previous, where: \.isDeclarationTypeKeyword),
           startOfModifiers(at: keyword, includingAttributes: true) <= previous,
           startOfScope(at: next) == startOfScope(at: keyword)
        {
            return true
        }

        // A declaration keyword and its name (not its body or argument list).
        if ["let", "var", "func", "class", "struct", "enum", "actor", "protocol", "typealias", "associatedtype", "extension"].contains(left.string),
           left.isKeyword, right.isIdentifier
        {
            return true
        }

        // Require a parsed operand rather than treating every occurrence of await as a prefix.
        var prefix = previous
        if left.isUnwrapOperator,
           let tryIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: previous),
           tokens[tryIndex] == .keyword("try")
        {
            prefix = tryIndex
        }
        if [Token.keyword("try"), .keyword("await")].contains(tokens[prefix]),
           let expression = parseExpressionRange(startingAt: prefix), expression.upperBound >= next
        {
            return true
        }

        // Only declaration parameters, not call arguments, tuples, or collection elements.
        if let scope = startOfScope(at: next), tokens[scope] == .startOfScope("("),
           let keyword = index(before: scope, where: \.isFunctionDeclarationKeyword),
           let function = parseFunctionDeclaration(keywordIndex: keyword),
           function.argumentsRange.lowerBound == scope,
           let parameter = commaSeparatedElementsInScope(startOfScope: scope).first(where: {
               $0.contains(previous) && $0.contains(next)
           }),
           let colon = index(of: .delimiter(":"), in: parameter)
        {
            if left.isIdentifier, next == colon,
               let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: next),
               parseType(at: typeStart) != nil
            {
                return true
            }
            if previous == colon, parseType(at: next) != nil {
                return true
            }
            if left.isIdentifier, right.isIdentifier,
               index(of: .nonSpaceOrCommentOrLinebreak, after: next) == colon
            {
                return true
            }
        }

        // Join signature components without changing spacing within parameter or type lists.
        if left == .operator("->", .infix) || right == .operator("->", .infix)
            || ["async", "throws", "rethrows"].contains(right.string),
           let keyword = index(before: next, where: \.isFunctionDeclarationKeyword),
           let function = parseFunctionDeclaration(keywordIndex: keyword)
        {
            if let effects = function.effectsRange,
               previous >= function.argumentsRange.upperBound, next <= effects.upperBound,
               ["async", "throws", "rethrows"].contains(right.string)
            {
                return true
            }
            if let arrow = function.returnOperatorIndex, let returnType = function.returnType {
                return (previous == (function.effectsRange?.upperBound ?? function.argumentsRange.upperBound) && next == arrow)
                    || (previous == arrow && next == returnType.range.lowerBound)
            }
        }
        return false
    }

    /// Whether the attribute at the given index applies to a declaration
    func isDeclarationAttribute(at attributeIndex: Int) -> Bool {
        guard let keywordIndex = index(after: attributeIndex, where: \.isDeclarationTypeKeyword) else {
            return false
        }
        return startOfModifiers(at: keywordIndex, includingAttributes: true) <= attributeIndex
    }
}
