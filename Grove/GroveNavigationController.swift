//
//  GroveNavigationController.swift
//  Whereno
//
//  Created by Kyle Bashour on 4/28/16.
//  Copyright © 2016 Kyle Bashour. All rights reserved.
//

import UIKit
import RealmSwift
import MessageUI

class GroveNavigationController: UINavigationController {


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        navigationBar.addGestureRecognizer(longPressRecognizer)
    }


    // MARK: Helpers

    // Listen for the long press
    @objc func longPressed(sender: UILongPressGestureRecognizer) {

        // We only want the beginning state!
        if sender.state == .Began {

            // Show alert with log out and feeback buttons
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let logOut = UIAlertAction(title: "Log Out", style: .Destructive) { [weak self] _ in
                User.authenticatedUser?.logOut()
                self?.presentViewController(R.storyboard.login.loginViewController()!, animated: true, completion: nil)
            }
            let feedback = UIAlertAction(title: "Send Feedback", style: .Default) { [weak self] _ in
                self?.presentFeedback()
            }
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

            alert.addAction(logOut)
            alert.addAction(feedback)
            alert.addAction(cancel)

            presentViewController(alert, animated: true, completion: nil)
        }
    }

    // Presents an email sheet for feedback
    func presentFeedback() {

        let mailComposeViewController = MFMailComposeViewController()

        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients(["kylebshr@me.com"])
        mailComposeViewController.setSubject("Grove Feedback")

        if MFMailComposeViewController.canSendMail() {
            presentViewController(mailComposeViewController, animated: true, completion: nil)
        }
        else {
            showAlert("No Email Configured!", message: "Please make sure you have an email account set up in your settings")
        }
    }
}

extension GroveNavigationController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
