//
//  LoginViewController.swift
//  Whereno
//
//  Created by Kyle Bashour on 4/28/16.
//  Copyright © 2016 Kyle Bashour. All rights reserved.
//

import UIKit
import CoreLocation
import SafariServices

class LoginViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var imageConstraints: [NSLayoutConstraint]!

    let locationManager = CLLocationManager()
    let imageTime = 6.0
    let fadeTime = 1.0
    let images = [R.image.login1(), R.image.login2(), R.image.login3(), R.image.login4(), R.image.login5()]

    var currentImage = 0
    var timer: NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()

        requestLocationPermissionIfNeeded()
        setUpNotificationCenter()
        setUpCycleImage()

        doKenBurnsEffect()

        timer = NSTimer.scheduledTimerWithTimeInterval(imageTime, target: self, selector: #selector(cycleImage), userInfo: nil, repeats: true)
    }

    func setUpNotificationCenter() {

        NSNotificationCenter.defaultCenter()
            .addObserver(self, selector: #selector(login), name: AppDelegate.loginNotification, object: nil)
        NSNotificationCenter.defaultCenter()
            .addObserver(self, selector: #selector(loginFailed), name: AppDelegate.loginNotification, object: nil)
    }

    @IBAction func facebookButtonTapped(sender: UIButton) {
        let vc = SFSafariViewController(URL: NSURL(string: "https://grove-api.herokuapp.com/login/facebook")!)
        presentViewController(vc, animated: true, completion: nil)
    }

    @objc func login() {
        dismissViewControllerAnimated(true, completion: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }

    @objc func loginFailed() {
        dismissViewControllerAnimated(true, completion: nil)
        showNetworkErrorAlert()
    }

    // Ask for location use permission if not granted
    func requestLocationPermissionIfNeeded() {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func setUpCycleImage() {
        changeCycleImageConstraints()
        view.layoutIfNeeded()
    }

    func cycleImage() {

        doKenBurnsEffect()

        currentImage += 1

        UIView.transitionWithView(imageView, duration: fadeTime, options: .TransitionCrossDissolve,
            animations: { _ in
                self.imageView.image = self.images[self.currentImage % self.images.count]
            }, completion: nil
        )
    }

    func doKenBurnsEffect() {

        UIView.animateWithDuration(imageTime + fadeTime, delay: 0, options: [.BeginFromCurrentState, .CurveEaseInOut],
            animations: { _ in
                self.changeCycleImageConstraints()
                self.view.layoutIfNeeded()
            }, completion: nil
        )
    }

    func changeCycleImageConstraints() {
        imageConstraints.forEach {
            $0.constant = CGFloat((rand() % 40) + 20)
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
