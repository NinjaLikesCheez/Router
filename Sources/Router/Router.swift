//
//  Router.swift
//  Router
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

public protocol RoutableDestination: Hashable {}
public protocol RoutableSheet: Hashable, Identifiable {}
public protocol RoutableError: Hashable, Identifiable {}

public protocol RoutableSheetViewModifier: ViewModifier {}
public protocol RoutableDestinationViewModifier: ViewModifier {}
public protocol RoutableErrorViewModifier: ViewModifier {}

@MainActor
public protocol RouterProtocol: AnyObject, Observation.Observable {
	associatedtype Destination: RoutableDestination
	associatedtype Sheet: RoutableSheet
	associatedtype Error: RoutableError

	var path: [Destination] { get set }
	var presentedSheet: Sheet? { get set }
	var presentedError: Error? { get set }
	var parent: (any RouterProtocol)? { get }

	init(_ parent: (any RouterProtocol)?)

	func push(_ destination: Destination)
	@discardableResult func pop() -> Destination?
	func popToRoot()
	func presentSheet(_ sheet: Sheet)
	func presentError(_ error: Error)
	func dismissSheet(withParent: Bool)
	func dismissError()
	func reset(withParent: Bool)
}

extension RouterProtocol {
	public func push(_ destination: Destination) {
		path.append(destination)
	}

	@discardableResult
	public func pop() -> Destination? {
		path.popLast()
	}

	public func popToRoot() {
		path.removeAll()
	}

	public func presentSheet(_ sheet: Sheet) {
		presentedSheet = sheet
	}

	public func presentError(_ error: Error) {
		presentedError = error
	}

	public func dismissSheet(withParent: Bool = false) {
		presentedSheet = nil
		if withParent {
			parent?.dismissSheet()
		}
	}

	public func dismissError() {
		presentedError = nil
	}

	public func reset(withParent: Bool = false) {
		presentedSheet = nil
		presentedError = nil
		popToRoot()
		if withParent {
			parent?.reset()
		}
	}
}
