//
//  AuthenticationCoordinator.swift
//  CorduxPrototype
//
//  Created by Ian Terrell on 7/21/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import UIKit

final class AuthenticationCoordinator: NavigationControllerCoordinator {
    let store: Store

    let storyboard = UIStoryboard(name: "Authentication", bundle: nil)
    let navigationController: UINavigationController
    var rootViewController: UIViewController { return navigationController }

    let signInViewController: SignInViewController

    init(store: Store) {
        self.store = store

        signInViewController = storyboard.instantiateInitialViewController() as! SignInViewController
        navigationController = UINavigationController(rootViewController: signInViewController)
    }

    func start() {
        signInViewController.inject(handler: self)
        signInViewController.lifecycleDelegate = self
        store.setRoute(.push(segment: ["signIn"]))
    }

    func updateRoute(route: Route) {
        if route.last == "fp" {
            let forgotPasswordViewController = storyboard.instantiateViewControllerWithIdentifier("ForgotPassword") as! ForgotPasswordViewController
            forgotPasswordViewController.inject(self)
            forgotPasswordViewController.lifecycleDelegate = self
            navigationController.pushViewController(forgotPasswordViewController, animated: true)
        }
    }
}

//extension AuthenticationCoordinator {x
//    enum RouteSegment: String {
//        case signIn
//        case fp
//    }
//}

extension AuthenticationCoordinator: ViewControllerLifecycleDelegate {
    @objc func viewDidLoad(viewController viewController: UIViewController) {
        if viewController === signInViewController {
            store.subscribe(signInViewController, SignInViewModel.init)
        }
    }

    @objc func didMoveToParentViewController(parentViewController: UIViewController?, viewController: UIViewController) {
        if parentViewController == nil && viewController is ForgotPasswordViewController {
            store.setRoute(.pop(segment: ["fp"]))
        }
    }
}

extension AuthenticationCoordinator: SignInHandler {
    func signIn() {
        store.dispatch(AuthenticationAction.signIn)
    }

    func forgotPassword() {
        store.route(.push(segment: ["fp"]))
    }
}

extension SignInViewController: Renderer, LifecycleDelegatingViewController {}
extension ForgotPasswordViewController: LifecycleDelegatingViewController {}

extension SignInViewController: Routable {
    var route: Route { return ["signIn"] }
}

extension SignInViewModel {
    init(_ state: AppState) {
        name = state.name
    }
}

extension AuthenticationCoordinator: ForgotPasswordHandler {
    func emailPassword() {

    }
}

extension ForgotPasswordViewController: Routable {
    var route: Route { return ["fp"] }
}

