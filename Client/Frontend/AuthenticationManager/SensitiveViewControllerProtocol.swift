/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

protocol SensitiveViewControllerProtocol {
    func addBlurredContent() -> UIImageView?
}

extension SensitiveViewControllerProtocol where Self: UIViewController {
    func addBlurredContent() -> UIImageView? {
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
