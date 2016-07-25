//
//  AppCoordinator.swift
//  CorduxPrototype
//
//  Created by Ian Terrell on 7/21/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import UIKit

final class AppCoordinator: SceneCoordinator, SubscriberType {
    enum RouteSegment: String, RouteConvertible {
        case auth
        case catalog
    }
    var scenePrefix: RouteSegment = .auth

    let store: Store
    let container: UIViewController

    var currentScene: Coordinator?

    var rootViewController: UIViewController {
        return container
    }

    init(store: Store, container: UIViewController) {
        self.store = store
        self.container = container
    }

    func start() {
        store.subscribe(self, RouteSubscription.init)
        changeScene(RouteSegment.auth.route())
    }

    func newState(state: RouteSubscription) {
        self.route = state.route
    }

    func changeScene(route: Route) {
        guard let segment = RouteSegment(rawValue: route.first ?? "") else {
            return
        }

        let old = currentScene?.rootViewController
        let coordinator: Coordinator
        switch segment {
        case .auth:
            coordinator = AuthenticationCoordinator(store: store)
        case .catalog:
            coordinator = CatalogCoordinator(store: store)
        }

        coordinator.start()
        currentScene = coordinator
        scenePrefix = segment

        let container = self.container
        let new = coordinator.rootViewController

        old?.willMoveToParentViewController(nil)
        container.addChildViewController(new)
        container.view.addSubview(new.view)

        var constraints: [NSLayoutConstraint] = []
        constraints.append(new.view.leftAnchor.constraintEqualToAnchor(container.view.leftAnchor))
        constraints.append(new.view.rightAnchor.constraintEqualToAnchor(container.view.rightAnchor))
        constraints.append(new.view.topAnchor.constraintEqualToAnchor(container.view.topAnchor))
        constraints.append(new.view.bottomAnchor.constraintEqualToAnchor(container.view.bottomAnchor))
        NSLayoutConstraint.activateConstraints(constraints)

        new.view.alpha = 0
        UIView.animateWithDuration(0.3, animations: { 
            old?.view.alpha = 0
            new.view.alpha = 1
        }, completion: { _ in
            old?.view.removeFromSuperview()
            old?.removeFromParentViewController()
            new.didMoveToParentViewController(container)
        })
    }
}
