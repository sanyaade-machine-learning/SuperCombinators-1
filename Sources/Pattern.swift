//
//  Pattern.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

/**
 Parses a prefix of a string, returning the prefix's end index on success.
*/
public final class Pattern<Input: Collection>: ParserCombinator where Input.SubSequence: Collection {
    public typealias Value = ()
    
    /**
     Parses a prefix of a string, returning the prefix's end index on success.
    */
    public let parsePrefix: (Input.SubSequence) -> Parse<Value, Input>?

    public init(parsePrefix: @escaping (Input.SubSequence) ->  Parse<Value, Input>?) {
        self.parsePrefix = parsePrefix
    }
}

extension Parser {

    /**
     Creates a pattern that parses the prefix of a string using `self.parse` and ignores the value.
    */
    public var pattern: Pattern<Input> {
        return Pattern<Input> { input in
            return self.parsePrefix(input)?.map { _ in () }
        }
    }

    /**
     Create a parser that parses the prefix of a string using `pattern.parse` and returns `value` as the value.
    */
    public convenience init(_ pattern: Pattern<Input>, _ value: Value) {
        self.init { input in
            return pattern.parsePrefix(input)?.map { _ in value }
        }
    }

    /**
     Create a parser that parses the prefix of a string using `pattern.parse` and returns `value` as the value.
     
     Returns an array of values that can be parsed by `self` given that their strings are separated by substrings matched by `separator`.
     */
    public func separated(by separator: Pattern<Input>) -> Parser<[Value], Input> {
        return Parser<[Value], Input> { input in
            guard let first = self.parsePrefix(input) else { return nil }

            let combined = separator & self

            var values = [first.value]
            var rest = first.rest

            while let next = combined.parsePrefix(rest) {
                values.append(next.value)
                rest = next.rest
                guard !rest.isEmpty else { break }
            }

            return Parser<[Value], Input>.Result(
                value: values,
                rest: rest
            )
        }
    }
}

extension Pattern {

    /**
     Create a pattern that does not parse anything and never fails.
    */
    public static var pure: Pattern {
        return Pattern { text in Result(rest: text[...]) }
    }
    
    public static var single: Pattern {
        return Pattern { input in
            guard !input.isEmpty else { return nil }
            return Pattern.Result(rest: input.dropFirst())
        }
    }

    /**
     Create a pattern that fails on any string but "".
    */
    public static var empty: Pattern {
        return Pattern { text in text.isEmpty ? Result(rest: text[...]) : nil }
    }

    /**
     Create a pattern that parses using `self.parse`. If that fails, returns the whole text as suffix.
     - Note: is equivalent to `self || .pure`
    */
    public var optional: Pattern {
        return Pattern { text in self.parsePrefix(text) ?? Result(rest: text[...]) }
    }
}
