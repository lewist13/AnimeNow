//  CoreData+Predicate.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 11/16/22.
//  

import Foundation

public protocol PredicateProtocol<Root>: NSPredicate {
    associatedtype Root: ManagedObjectConvertible
}

public final class CompoundPredicate<Root: ManagedObjectConvertible>: NSCompoundPredicate, PredicateProtocol {}
public final class ComparisonPredicate<Root: ManagedObjectConvertible>: NSComparisonPredicate, PredicateProtocol {}

// MARK: compound operators

public func && <TP1: PredicateProtocol, TP2: PredicateProtocol>(
    p1: TP1,
    p2: TP2
) -> CompoundPredicate<TP1.Root> where TP1.Root == TP2.Root {
    CompoundPredicate(type: .and, subpredicates: [p1, p2])
}

public func || <TP1: PredicateProtocol, TP2: PredicateProtocol>(
    p1: TP1,
    p2: TP2
) -> CompoundPredicate<TP1.Root> where TP1.Root == TP2.Root {
    CompoundPredicate(type: .or, subpredicates: [p1, p2])
}

public prefix func ! <TP: PredicateProtocol>(p: TP) -> CompoundPredicate<TP.Root> {
    CompoundPredicate(type: .not, subpredicates: [p])
}

// MARK: - comparison operators
public func == <E: Equatable & ConvertableValue, R, K: KeyPath<R, E>>(kp: K, value: E) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .equalTo, value)
}

public func != <E: Equatable & ConvertableValue, R, K: KeyPath<R, E>>(kp: K, value: E) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .notEqualTo, value)
}

public func > <C: Comparable & ConvertableValue, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .greaterThan, value)
}

public func < <C: Comparable & ConvertableValue, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .lessThan, value)
}

public func <= <C: Comparable & ConvertableValue, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .lessThanOrEqualTo, value)
}

public func >= <C: Comparable & ConvertableValue, R, K: KeyPath<R, C>>(kp: K, value: C) -> ComparisonPredicate<R> {
    ComparisonPredicate(kp, .greaterThanOrEqualTo, value)
}

public func === <S: Sequence, R, K: KeyPath<R, S.Element>>(kp: K, values: S) -> ComparisonPredicate<R> where S.Element: Equatable & ConvertableValue, S: ConvertableValue {
    ComparisonPredicate(kp, .in, values)
}

// MARK: - internal
internal extension ComparisonPredicate {
    convenience init<Value: ConvertableValue>(
        _ keyPath: KeyPath<Root, Value>,
        _ op: NSComparisonPredicate.Operator,
        _ value: (any ConvertableValue)?
    ) {
        let attribute = Root.attribute(keyPath)
        let ex1 = NSExpression(forKeyPath: attribute.name)
        let ex2 = NSExpression(forConstantValue: value?.encode())
        self.init(leftExpression: ex1, rightExpression: ex2, modifier: .direct, type: op)
    }
}
