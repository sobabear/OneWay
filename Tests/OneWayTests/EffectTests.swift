//
//  OneWay
//  The MIT License (MIT)
//
//  Copyright (c) 2022-2023 SeungYeop Yeom ( https://github.com/DevYeom ).
//

import Clocks
import OneWay
import XCTest

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
final class EffectTests: XCTestCase {
    enum Action: Sendable {
        case first
        case second
        case third
        case fourth
        case fifth
    }

    func test_just() async {
        let values = Effects.Just(Action.first).values

        var result: [Action] = []
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(result, [.first])
    }

    func test_async() async {
        let clock = TestClock()

        let values = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.first
        }.values

        var result: [Action] = []
        await clock.advance(by: .seconds(100))
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(result, [.first])
    }

    func test_sequence() async {
        let stream = AsyncStream { continuation in
            for number in 1 ... 5 {
                continuation.yield(number)
            }
            continuation.finish()
        }

        let values = Effects.Sequence { send in
            for await number in stream {
                let action: Action
                switch number {
                case 1: action = .first
                case 2: action = .second
                case 3: action = .third
                case 4: action = .fourth
                case 5: action = .fifth
                default:
                    action = .first
                    XCTFail()
                }
                send(action)
            }
        }.values

        var result: [Action] = []
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(
            result,
            [
                .first,
                .second,
                .third,
                .fourth,
                .fifth,
            ]
        )
    }

    func test_concat() async {
        let clock = TestClock()

        let first = Effects.Just(Action.first).any
        let second = Effects.Single {
            try! await clock.sleep(for: .seconds(300))
            return Action.second
        }.any
        let third = Effects.Single {
            try! await clock.sleep(for: .seconds(200))
            return Action.third
        }.any
        let fourth = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.fourth
        }.any
        let fifth = Effects.Just(Action.fifth).any

        let values = Effects.Concat([
            first,
            second,
            third,
            fourth,
            fifth,
        ]).values

        var result: [Action] = []
        await clock.advance(by: .seconds(100 + 200 + 300))
        for await value in values {
            result.append(value)
        }


        XCTAssertEqual(
            result,
            [
                .first,
                .second,
                .third,
                .fourth,
                .fifth,
            ]
        )
    }

    func test_concatIncludingMerge() async {
        let clock = TestClock()

        let first = Effects.Single {
            try! await clock.sleep(for: .seconds(500))
            return Action.first
        }.any
        let second = Effects.Single {
            try! await clock.sleep(for: .seconds(200))
            return Action.second
        }.any
        let third = Effects.Single {
            try! await clock.sleep(for: .seconds(300))
            return Action.third
        }.any
        let fourth = Effects.Single {
            try! await clock.sleep(for: .seconds(400))
            return Action.fourth
        }.any
        let fifth = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.fifth
        }.any

        let values = Effects.Concat([
            first,
            Effects.Merge([fourth, third, second]).any,
            fifth,
        ]).values

        var result: [Action] = []
        await clock.advance(by: .seconds(500 + 400 + 100))
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(
            result,
            [
                .first,
                .second,
                .third,
                .fourth,
                .fifth,
            ]
        )
    }

    func test_merge() async {
        let clock = TestClock()

        let first = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.first
        }.any
        let second = Effects.Single {
            try! await clock.sleep(for: .seconds(200))
            return Action.second
        }.any
        let third = Effects.Single {
            try! await clock.sleep(for: .seconds(300))
            return Action.third
        }.any
        let fourth = Effects.Single {
            try! await clock.sleep(for: .seconds(400))
            return Action.fourth
        }.any
        let fifth = Effects.Single {
            try! await clock.sleep(for: .seconds(500))
            return Action.fifth
        }.any

        let values = Effects.Merge([
            first,
            second,
            third,
            fourth,
            fifth,
        ]).values

        var result: [Action] = []
        await clock.advance(by: .seconds(500))
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(
            result,
            [
                .first,
                .second,
                .third,
                .fourth,
                .fifth,
            ]
        )
    }

    func test_mergeIncludingConcat() async {
        let clock = TestClock()

        let first = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.first
        }.any
        let second = Effects.Single {
            try! await clock.sleep(for: .seconds(300))
            return Action.second
        }.any
        let third = Effects.Single {
            try! await clock.sleep(for: .seconds(200))
            return Action.third
        }.any
        let fourth = Effects.Single {
            try! await clock.sleep(for: .seconds(100))
            return Action.fourth
        }.any
        let fifth = Effects.Single {
            try! await clock.sleep(for: .seconds(600 + 100))
            return Action.fifth
        }.any

        let values = Effects.Merge([
            first,
            Effects.Concat([second, third, fourth]).any,
            fifth,
        ]).values

        var result: [Action] = []
        await clock.advance(by: .seconds(700))
        for await value in values {
            result.append(value)
        }

        XCTAssertEqual(
            result,
            [
                .first,
                .second,
                .third,
                .fourth,
                .fifth,
            ]
        )
    }
}
