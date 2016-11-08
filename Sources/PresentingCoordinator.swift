//
//  PresentingCoordinator.swift
//  Cordux
//
//  Created by Ian Terrell on 11/2/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import UIKit

public protocol PresentingCoordinator: Coordinator {
    var rootCoordinator: AnyCoordinator { get }
    var presented: Scene? { get set }

    var presentables: [GeneratingScene] { get }
    func parsePresentableRoute(_ route: Route) -> (rootRoute: Route, presentedRoute: Route?, presentable: GeneratingScene?)

    func present(presentable: GeneratingScene, route: Route, completionHandler: @escaping () -> Void)
    func dismiss(completionHandler: @escaping () -> Void)
}

public extension PresentingCoordinator  {
    public var rootViewController: UIViewController {
        return rootCoordinator.rootViewController
    }

    public var route: Route {
        var route: Route = []
        #if swift(>=3)
            route.append(contentsOf: rootCoordinator.route)
        #else
            route.appendContentsOf(rootCoordinator.route)
        #endif
        if let presented = presented {
            #if swift(>=3)
                route.append(contentsOf: presented.route())
            #else
                route.appendContentsOf(presented.route())
            #endif
        }
        return route
    }

    public func prepareForRoute(_ newValue: Route?, completionHandler: @escaping () -> Void) {
        guard let route = newValue else {
            dismiss(completionHandler: completionHandler)
            return
        }

        withGroup(completionHandler) { group in
            let (rootRoute, presentedRoute, _) = parsePresentableRoute(route)

            group.enter()
            rootCoordinator.prepareForRoute(rootRoute) {
                group.leave()
            }

            if let presented = self.presented {
                group.enter()
                if let presentedRoute = presentedRoute {
                    presented.coordinator.prepareForRoute(presentedRoute) {
                        group.leave()
                    }
                } else {
                    dismiss() {
                        group.leave()
                    }
                }

            }
        }
    }

    public func setRoute(_ newValue: Route?, completionHandler: @escaping () -> Void) {
        guard let newValue = newValue else {
            dismiss(completionHandler: completionHandler)
            return
        }

        guard newValue != route else {
            completionHandler()
            return
        }

        withGroup(completionHandler) { group in
            let (rootRoute, presentedRoute, presentable) = parsePresentableRoute(newValue)

            group.enter()
            rootCoordinator.setRoute(rootRoute) {
                group.leave()
            }

            group.enter()
            if let presentable = presentable, let presentedRoute = presentedRoute {
                present(presentable: presentable, route: presentedRoute) {
                    group.leave()
                }
            } else {
                dismiss() {
                    group.leave()
                }
            }
        }
    }

    func start(route: Route?) {
        rootCoordinator.start(route: route)
    }

    func parsePresentableRoute(_ route: Route) -> (rootRoute: Route, presentedRoute: Route?, presentable: GeneratingScene?) {
        for presentable in presentables {
            let parts = route.components.split(separator: presentable.tag,
                                               maxSplits: 2,
                                               omittingEmptySubsequences: false)
            if parts.count == 2 {
                return (Route(parts[0]), Route(parts[1]), presentable)
            }
        }
        return (route, nil, nil)
    }

    /// Presents the presentable coordinator.
    /// If it is already presented, this method merely adjusts the route.
    /// If a different presentable is currently presented, this method dismisses it first.
    func present(presentable: GeneratingScene, route: Route, completionHandler: @escaping () -> Void) {
        if let presented = presented {
            if presentable.tag != presented.tag {
                dismiss() {
                    DispatchQueue.main.async {
                        self.present(presentable: presentable, route: route, completionHandler: completionHandler)
                    }
                }
            } else {
                presented.coordinator.setRoute(route, completionHandler: completionHandler)
            }
            return
        }

        let coordinator = presentable.buildCoordinator()
        coordinator.start(route: route)
        rootViewController.present(coordinator.rootViewController, animated: true) {
            self.presented = Scene(tag: presentable.tag, coordinator: coordinator)
            completionHandler()
        }
    }

    /// Dismisses the currently presented coordinator if present. Noop if there isn't one.
    func dismiss(completionHandler: @escaping () -> Void) {
        guard let presented = presented else {
            completionHandler()
            return
        }

        presented.coordinator.prepareForRoute(nil) {
            presented.coordinator.rootViewController.dismiss(animated: true) {
                self.presented = nil
                completionHandler()
            }
        }
    }

    /// Helper method for synchronizing activities with a DispatchGroup
    ///
    /// - Parameter perform: Callback to do work with the group
    func withGroup(_ completionHandler: @escaping () -> Void, perform: (DispatchGroup) -> Void) {
        let group = DispatchGroup()
        perform(group)
        let queue = DispatchQueue(label: "PresentingCoordinatorSync")
        queue.async {
            group.wait()
            DispatchQueue.main.async(execute: completionHandler)
        }
    }
}
