/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class RoundedToolbar: UIToolbar {

    private var layerBackgroundColor: UIColor?

    override var backgroundColor: UIColor? {
        get { return layerBackgroundColor }

        set {
            layerBackgroundColor = newValue
        }
    }

    var cornerRadius: CGSize = CGSizeZero

    var cornersToRound: UIRectCorner = [.AllCorners]

    /**
     * The toolbar on the menu requires rounded corners on the top and bottom so we need a custom
     * view to do this
     */
    override func drawRect(rect: CGRect) {
        // Drawing code
        let maskPath = UIBezierPath(roundedRect: rect, byRoundingCorners: cornersToRound, cornerRadii: cornerRadius)

        // Create the shape layer and set its path
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.CGPath

        let roundedLayer = CALayer()
        roundedLayer.backgroundColor = layerBackgroundColor?.CGColor ?? UIColor.whiteColor().CGColor
        roundedLayer.frame = rect
        roundedLayer.mask = maskLayer

        layer.insertSublayer(roundedLayer, atIndex: 0)
    }


}
