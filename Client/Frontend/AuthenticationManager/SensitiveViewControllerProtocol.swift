/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

protocol SensitiveViewControllerProtocol: class, PasscodeEntryDelegate {
    var promptingForTouchID: Bool { get set }
    var backgroundedBlur: UIImageView? { get set }

    func registerObserversForSensitiveVCNotifications()
    func removeObserversForSensitiveVCNotifications()

    func checkIfUserRequiresValidation()
    func blurContents()
    func removeBackgroundedBlur()
}

extension SensitiveViewControllerProtocol where Self: UIViewController {
    func registerObserversForSensitiveVCNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.checkIfUserRequiresValidation()
        }
        notificationCenter.addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: nil) { notification in
            self.blurContents()
        }
        notificationCenter.addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { notification in
            self.removeBackgroundedBlur()
        }
    }

    func removeObserversForSensitiveVCNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    func checkIfUserRequiresValidation() {
        guard let authInfo = KeychainWrapper.authenticationInfo() where authInfo.requiresValidation() else {
            removeBackgroundedBlur()
            return
        }

        promptingForTouchID = true
        AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            success: {
                self.promptingForTouchID = false
                self.removeBackgroundedBlur()
            },
            cancel: {
                self.promptingForTouchID = false
                self.navigationController?.popToRootViewControllerAnimated(true)
            },
            fallback: {
                self.promptingForTouchID = false
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self)
            }
        )
    }

    func blurContents() {
        if backgroundedBlur == nil {
            backgroundedBlur = addBlurredContent()
        }
    }

    func removeBackgroundedBlur() {
        if !promptingForTouchID {
            backgroundedBlur?.removeFromSuperview()
            backgroundedBlur = nil
        }
    }

    private func addBlurredContent() -> UIImageView? {
        guard let snapshot = view.screenshot() else {
            return nil
        }

        let blurredSnapshot = snapshot.applyBlurWithRadius(10, blurType: BOXFILTER, tintColor: UIColor.init(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
        let blurView = UIImageView(image: blurredSnapshot)
        view.addSubview(blurView)
        blurView.snp_makeConstraints { $0.edges.equalTo(self.view) }
        view.layoutIfNeeded()

        return blurView
    }
}

// MARK: - PasscodeEntryDelegate Defaults
extension SensitiveViewControllerProtocol where Self: UIViewController {
    func passcodeValidationDidSucceed() {
        removeBackgroundedBlur()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func userDidCancelValidation() {
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
}

