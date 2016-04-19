/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private let SectionSettings = 1
private let SectionURLTextView = 0
private let NumberOfSections = 2
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
private let SectionSettingsIdentifier = "SectionSettingsIdentifier"

private let log = Logger.browserLogger

class HomePageSettingsViewController: UITableViewController {
    private var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    private var settings: [Setting] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if AppConstants.MOZ_MENU {
            settings.append(BoolSetting(prefs: profile.prefs, prefKey: "homepage.buttonOnMenu", defaultValue: true,
                        titleText: Strings.SettingsHomePageUIPositionTitle))
        }

        settings += [
            BoolSetting(prefs: profile.prefs, prefKey: "homepage.useForNewTab", defaultValue: false,
                titleText: Strings.SettingsHomePageUseForNewTab),
        ]

        title = Strings.SettingsHomePageTitle

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: SectionSettingsIdentifier)
        tableView.registerClass(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: UIConstants.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == SectionSettings {
            let setting = settings[indexPath.row]
            var cell: UITableViewCell!
            if let _ = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = UITableViewCell(style: setting.style, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(SectionSettingsIdentifier, forIndexPath: indexPath)
            }
            setting.onConfigureCell(cell)
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            assert(indexPath.section == SectionURLTextView)
            cell.textLabel?.text = Strings.SettingsHomePageURLSectionTitle
            cell.textLabel?.textAlignment = NSTextAlignment.Natural
            cell.textLabel?.textColor = UIConstants.TableViewRowTextColor
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.textLabel?.text = UIConstants.DefaultHomePage.absoluteDisplayString()
            cell.accessibilityIdentifier = "HomePage"
            clearButton = cell
            return cell
        }

    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionSettings {
            return settings.count
        }

        assert(section == SectionURLTextView)
        return 1
    }

    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard indexPath.section == SectionURLTextView else { return false }

        // Highlight the button only if it's enabled.
        return false
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
        let title: String?
        switch section {
        case SectionURLTextView:
            title = Strings.SettingsHomePageURLSectionTitle
        default:
            title = nil
        }
        headerView.titleLabel.text = title

        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        return headerView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIConstants.TableViewHeaderFooterHeight
    }
}