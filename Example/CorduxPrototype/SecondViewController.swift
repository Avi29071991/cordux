//
//  SecondViewController.swift
//  CorduxPrototype
//
//  Created by Ian Terrell on 7/21/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import UIKit

protocol SecondHandler {
    func performAction()
    func signOut()
}

class SecondViewController: UIViewController {
    var handler: SecondHandler!

    func inject(handler: SecondHandler) {
        self.handler = handler
    }

    @IBAction func performAction(_ sender: AnyObject) {
        handler.performAction()
    }

    @IBAction func signOut(_ sender: AnyObject) {
        handler.signOut()
    }
}

