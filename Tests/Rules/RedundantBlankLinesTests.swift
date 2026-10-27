//
//  RedundantBlankLinesTests.swift
//  SwiftFormatTests
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantBlankLinesTests: XCTestCase {
    func testRemovesBlankLineAfterTypeAttribute() {
        let input = """
        @MainActor

        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesMultipleBlankLinesAfterAttribute() {
        let input = """
        @MainActor


        struct Foo {}
        """
        let output = """
        @MainActor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenSequentialAttributes() {
        let input = """
        @objc

        @MainActor

        class Foo: NSObject {}
        """
        let output = """
        @objc
        @MainActor
        class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterAttributeWithArguments() {
        let input = """
        @available(iOS 15, *)

        func foo() {}
        """
        let output = """
        @available(iOS 15, *)
        func foo() {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineBeforeModifiers() {
        let input = """
        @objc

        public final class Foo: NSObject {}
        """
        let output = """
        @objc
        public final class Foo: NSObject {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterPropertyAttributeInTypeBody() {
        let input = """
        struct Foo: View {
            @State

            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        let output = """
        struct Foo: View {
            @State
            private var count = 0

            var body: some View {
                Text("\\(count)")
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterLocalPropertyAttribute() {
        let input = """
        #Preview {
            @Previewable

            @State var count = 0
            Text("\\(count)")
        }
        """
        let output = """
        #Preview {
            @Previewable
            @State var count = 0
            Text("\\(count)")
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLineAfterAttributeWithTrailingComment() {
        let input = """
        @MainActor // Isolated to the main actor

        struct Foo {}
        """
        let output = """
        @MainActor // Isolated to the main actor
        struct Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineBeforeComment() {
        let input = """
        @MainActor

        // TODO: Remove main actor isolation
        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesAttributesWithoutBlankLines() {
        let input = """
        @MainActor
        struct Foo {
            @State private var count = 0
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLineAfterNonDeclarationAttribute() {
        let input = """
        func foo(
            @ViewBuilder

            content: () -> some View
        ) -> some View {
            content()
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenModifiers() {
        let input = """
        public

        final

        class Foo {}
        """
        let output = """
        public
        final
        class Foo {}
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.modifiersOnSameLine])
    }

    func testRemovesBlankLinesBetweenParenthesizedModifier() {
        let input = """
        private(set)

        var value = 0
        """
        let output = """
        private(set)
        var value = 0
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.modifiersOnSameLine])
    }

    func testRemovesBlankLinesBetweenDeclarationNames() {
        let input = """
        struct

        Foo {
            let

                value = 0
        }
        """
        let output = """
        struct
        Foo {
            let
                value = 0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenFunctionSignature() {
        let input = """
        func

        foo()

        async

        throws

        ->

        Int {
            0
        }
        """
        let output = """
        func
        foo()
        async
        throws
        ->
        Int {
            0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenTypedThrows() {
        let input = """
        func foo()

            async

            throws(Failure)

            ->

            Int
        {
            0
        }
        """
        let output = """
        func foo()
            async
            throws(Failure)
            ->
            Int
        {
            0
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testRemovesBlankLinesBetweenParameterSyntax() {
        let input = """
        func foo(
            value

                :

            Int,

            other: String
        ) {
            print(value, other)
        }
        """
        let output = """
        func foo(
            value
                :
            Int,

            other: String
        ) {
            print(value, other)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.leadingDelimiters])
    }

    func testRemovesBlankLinesBetweenParameterLabels() {
        let input = """
        func foo(
            external

            internalName: Int
        ) {
            print(internalName)
        }
        """
        let output = """
        func foo(
            external
            internalName: Int
        ) {
            print(internalName)
        }
        """
        testFormatting(for: input, output, rule: .redundantBlankLines, exclude: [.wrapArguments])
    }

    func testRemovesBlankLinesBetweenExpressionPrefixes() {
        let input = """
        let value = try

            await

            load()
        let other = try?

            load()
        """
        let output = """
        let value = try
            await
            load()
        let other = try?
            load()
        """
        testFormatting(for: input, output, rule: .redundantBlankLines)
    }

    func testPreservesGroupedExpressions() {
        let input = """
        let values = [
            first,

            second,
        ]
        foo(
            first,

            second
        )
        let result = first

            + second
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesScopePadding() {
        let input = """
        func foo() {

            first()

            second()

        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testPreservesComments() {
        let input = """
        func foo()

            /// Explanation
            async -> Int
        {
            0
        }

        let value = try

            // Explanation
            load()
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesConditionalCompilation() {
        let input = """
        @MainActor

        #if DEBUG
            struct Foo {}
        #endif
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesAttributeArguments() {
        let input = """
        @available(
            iOS 15,

            macOS 12, *
        )
        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesMultilineString() {
        let input = """
        let text = \"\"\"
        try

        await

        value
        \"\"\"
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesDisabledRule() {
        let input = """
        // swiftformat:disable redundantBlankLines
        @MainActor

        struct Foo {}
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLinesInsideParameterDefaults() {
        let input = """
        func foo(
            value: Int = condition ? first :

                second
        ) {
            print(value)
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }

    func testPreservesBlankLinesBeforeBodyAndBetweenBranches() {
        let input = """
        func foo() -> Int

        {
            if condition {
                return 1
            }

            else {
                return 2
            }
        }
        """
        testFormatting(for: input, rule: .redundantBlankLines, exclude: [.braces, .elseOnSameLine])
    }

    func testPreservesBlankLineAfterBodylessAsyncFunction() {
        let input = """
        @GenerateBody
        func foo() async

        let value: Int
        """
        testFormatting(for: input, rule: .redundantBlankLines)
    }
}
