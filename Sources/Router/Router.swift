//
//  Routable.swift
//  Routable
//
//  Created by ninji on 10/05/2025.
//

import Observation
import SwiftUI

/// An 'entry' point into a Routable-based navigation system.
public protocol Flow<Router>: View {
	associatedtype Router: Routable

	/// The router for the flow.
	var router: Router { get }
}

/// A destination that can be pushed onto the navigation stack.
public protocol RoutableDestination: Hashable {}
/// A sheet that can be presented.
public protocol RoutableSheet: Hashable, Identifiable {}
/// An error that can be presented.
public protocol RoutableError: Hashable, Identifiable {}

/// A view modifier that adds sheets to a view
public protocol RoutableSheetViewModifier: ViewModifier {}
/// A view modifier that adds destinations to a view
public protocol RoutableDestinationViewModifier: ViewModifier {}
/// A view modifier that adds errors to a view
public protocol RoutableErrorViewModifier: ViewModifier {}

/// A router that manages the navigation state for a feature.
@MainActor
public protocol Routable: AnyObject, Observation.Observable {
	/// The type of destinations that can be pushed onto the navigation stack.
	associatedtype Destination: RoutableDestination

	/// The type of sheets that can be presented.
	associatedtype Sheet: RoutableSheet

	/// The type of errors that can be presented.
	associatedtype Error: RoutableError

	/// The current path of destinations.
	var path: [Destination] { get set }

	/// The currently presented sheet.
	var presentedSheet: Sheet? { get set }

	/// The currently presented error.
	var presentedError: Error? { get set }

	/// The parent router, if any.
	var parent: (any Routable)? { get }

	/// Initializes a new router with an optional parent router.
	init(_ parent: (any Routable)?)

	/// Pushes a destination onto the navigation stack.
	func push(_ destination: Destination)

	/// Pops the last destination from the navigation stack.
	@discardableResult func pop() -> Destination?

	/// Pops to the root destination from the navigation stack.
	func popToRoot()

	/// Presents a sheet.
	func presentSheet(_ sheet: Sheet)

	/// Presents an error.
	func presentError(_ error: Error)

	/// Dismisses the currently presented sheet, optionally dismissing any sheet presented by the parent router.
	func dismissSheet(withParent: Bool)

	/// Dismisses the currently presented error.
	func dismissError()

	/// Resets the router, optionally resetting the parent router.
	func reset(withParent: Bool)
}

extension Routable {
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
