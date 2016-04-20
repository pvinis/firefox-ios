/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import NotificationCenter
import Shared
import SnapKit

private let log = Logger.browserLogger



struct TodayUX {
    static let privateBrowsingColor = UIColor(colorString: "CE6EFC")
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)

    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0

    static let buttonContainerHeight = 88

    static let verticalWidgetMargin: CGFloat = 10
    static let horizontalWidgetMargin: CGFloat = 10

    static let buttonContainerMultipleOfScreen = 0.6
    static let copiedLinkHeightOfButtonMultple = 0.5
}

@objc (TodayViewController)
class TodayViewController: UIViewController, NCWidgetProviding {

    private lazy var newTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewTab), forControlEvents: .TouchUpInside)

        let button = imageButton.button
        button.setImage(UIImage(named: "new_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_tab_button_highlight"), forState: .Highlighted)

        let label = imageButton.label
        label.text = NSLocalizedString("TodayWidget.NewTabButtonLabel", value: "New Tab", tableName: "Today", comment: "New Tab button label")
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(TodayUX.imageButtonTextSize)

        imageButton.sizeToFit()
        return imageButton
    }()

    private lazy var newPrivateTabButton: ImageButtonWithLabel = {
        let imageButton = ImageButtonWithLabel()
        imageButton.addTarget(self, action: #selector(onPressNewPrivateTab), forControlEvents: .TouchUpInside)

        let button = imageButton.button
        button.setImage(UIImage(named: "new_private_tab_button_normal"), forState: .Normal)
        button.setImage(UIImage(named: "new_private_tab_button_highlight"), forState: .Highlighted)

        let label = imageButton.label
        label.text = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", value: "New Private Tab", tableName: "Today", comment: "New Private Tab button label")
        label.textColor = TodayUX.privateBrowsingColor
        label.font = UIFont.systemFontOfSize(TodayUX.imageButtonTextSize)

        return imageButton
    }()

    private lazy var openCopiedLinkButton: ButtonWithSublabel = {
        let button = ButtonWithSublabel()
        
        button.setTitle(NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", value: "Go to copied link", tableName: "Today", comment: "Go to link on clipboard"), forState: .Normal)
        button.addTarget(self, action: #selector(onPressOpenClibpoard), forControlEvents: .TouchUpInside)
        button.setBackgroundColor(TodayUX.backgroundHightlightColor, forState: .Highlighted)

        button.label.font = UIFont.systemFontOfSize(TodayUX.labelTextSize)
        button.setImage(UIImage(named: "copy_link_icon"), forState: .Normal)

        button.subtitleLabel.font = UIFont.systemFontOfSize(TodayUX.linkTextSize)

        return button
    }()

    private lazy var buttonContainer: UIView = UIView()

    private var copiedURL: NSURL? {
        if let string = UIPasteboard.generalPasteboard().string,
            url = NSURL(string: string) where url.isWebPage() {
            return url
        } else {
            return nil
        }
    }

    private var hasCopiedURL: Bool {
        return copiedURL != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(buttonContainer)

        // New tab button and label.
        buttonContainer.addSubview(newTabButton)
        newTabButton.snp_makeConstraints { make in
            make.top.equalTo(buttonContainer)
            make.left.equalTo(buttonContainer)
        }

        // New private tab button and label.
        buttonContainer.addSubview(newPrivateTabButton)
        newPrivateTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(newTabButton.snp_centerY)
            make.right.equalTo(buttonContainer.snp_right)
        }

        buttonContainer.snp_makeConstraints { make in
            make.width.equalTo(view.snp_width).multipliedBy(TodayUX.buttonContainerMultipleOfScreen)
            make.centerX.equalTo(view.snp_centerX)
            make.top.equalTo(view.snp_top).offset(10)
            make.height.equalTo(TodayUX.buttonContainerHeight).priorityLow()
        }

        view.addSubview(openCopiedLinkButton)

        openCopiedLinkButton.snp_makeConstraints { make in
            make.bottom.equalTo(view.snp_bottom)
            make.width.equalTo(view.snp_width)
            make.centerX.equalTo(view.snp_centerX)
            make.height.equalTo(buttonContainer.snp_height).multipliedBy(TodayUX.copiedLinkHeightOfButtonMultple)
        }

        view.snp_makeConstraints { make in
            let multiple = !hasCopiedURL ? 1.0 : (1.0 + TodayUX.copiedLinkHeightOfButtonMultple)
            make.height.equalTo(self.buttonContainer.snp_height).multipliedBy(multiple)
        }
    }

    func updateCopiedLink() {
        if let url = self.copiedURL {
            self.openCopiedLinkButton.hidden = false
            self.openCopiedLinkButton.subtitleLabel.hidden = SystemUtils.isDeviceLocked()
            self.openCopiedLinkButton.subtitleLabel.text = url.absoluteString
        } else {
            self.openCopiedLinkButton.hidden = true
        }

        self.view.setNeedsLayout()
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, TodayUX.verticalWidgetMargin, TodayUX.horizontalWidgetMargin)
    }

    private func alignButton(leftButton: ImageButtonWithLabel, rightButton: ImageButtonWithLabel) {
        rightButton.label.snp_makeConstraints { make in
            make.centerY.equalTo(leftButton.label.snp_centerY)
            make.left.equalTo(leftButton.label.snp_right).offset(44).priorityLow()
        }
    }

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        dispatch_async(dispatch_get_main_queue()) {
            // updates need to be made on the main thread
            self.updateCopiedLink()
            // and we need to call the completion handler in every branch.
            completionHandler(NCUpdateResult.NewData)
        }
    }

    // MARK: Button and label creation

    private func createButtonLabel(text: String, color: UIColor = UIColor.whiteColor()) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = UIFont.systemFontOfSize(14.0)
        return label
    }

    // MARK: Button behaviour

    @objc func onPressNewTab(view: UIView) {
        openContainingApp("firefox://")
    }

    @objc func onPressNewPrivateTab(view: UIView) {
        openContainingApp("firefox://?private=true")
    }

    private func openContainingApp(urlString: String) {
        self.extensionContext?.openURL(NSURL(string: urlString)!) { success in
            log.info("Extension opened containing app: \(success)")
        }
    }

    @objc func onPressOpenClibpoard(view: UIView) {
        if let urlString = UIPasteboard.generalPasteboard().string,
            _ = NSURL(string: urlString) {
            let encodedString =
                urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            openContainingApp("firefox://?url=\(encodedString)")
        }
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState state: UIControlState) {
        let colorView = UIView(frame: CGRectMake(0, 0, 1, 1))
        colorView.backgroundColor = color

        UIGraphicsBeginImageContext(colorView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            colorView.layer.renderInContext(context)
        }
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, forState: state)
    }
}

class ImageButtonWithLabel: UIView {

    lazy var button = UIButton()

    lazy var label = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: CGRectZero)
        performLayout()
    }

    func performLayout() {
        addSubview(button)
        addSubview(label)
        userInteractionEnabled = true

        button.snp_makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.centerX.equalTo(self)
        }

        snp_makeConstraints { make in
            make.width.equalTo(button)
            make.height.equalTo(button)
        }

        label.snp_makeConstraints { make in
            make.centerX.equalTo(button.snp_centerX)
            make.centerY.equalTo(button.snp_centerY).offset(39)
        }
    }

    func addTarget(target: AnyObject?, action: Selector, forControlEvents events: UIControlEvents) {
        button.addTarget(target, action: action, forControlEvents: events)
    }
}

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel: UILabel = UILabel()

    lazy var label: UILabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    private func performLayout() {
        self.snp_removeConstraints()

        let titleLabel = self.label
        titleLabel.textColor = UIColor.whiteColor()

        self.titleLabel?.removeFromSuperview()
        addSubview(titleLabel)

        let imageView = self.imageView!

        let subtitleLabel = self.subtitleLabel
        subtitleLabel.textColor = UIColor.whiteColor()
        self.addSubview(subtitleLabel)

        imageView.snp_remakeConstraints { make in
            make.centerY.equalTo(titleLabel.snp_centerY)
            make.left.equalTo(self.snp_left).offset(22)
        }

        titleLabel.snp_remakeConstraints { make in
            make.top.equalTo(self.snp_top).offset(10)
            make.left.equalTo(imageView.snp_right).offset(10).priorityLow()
        }

        subtitleLabel.snp_makeConstraints { make in
            make.left.equalTo(titleLabel.snp_left)
            make.top.equalTo(titleLabel.snp_bottom)
        }
    }

    override func setTitle(text: String?, forState state: UIControlState) {
        self.label.text = text
        super.setTitle(text, forState: state)
    }
}
