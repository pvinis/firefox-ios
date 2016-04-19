/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
@testable import Storage
@testable import Client

/**
 * WARNING: top sites deletion tests are flaky and sometimes fail.
 * Bug raised for this https://bugzilla.mozilla.org/show_bug.cgi?id=1264286
 */
class TopSitesTests: KIFTestCase {
    private var webRoot: String!
    private var profile: Profile!

    override func setUp() {
        profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        profile.prefs.setObject([], forKey: "topSites.deletedSuggestedSites")
        webRoot = SimplePageServer.start()
    }

    private func extractTextSizeFromThumbnail(thumbnail: ThumbnailCell) -> CGFloat? {
        return thumbnail.textLabel.font.pointSize
    }

    private func accessibilityLabelsForAllTopSites(collection: UICollectionView) -> [String] {
        return collection.visibleCells().reduce([], combine: { arr, cell in
            if let label = cell.accessibilityLabel {
                return arr + [label]
            }
            return arr
        })
    }

    func testChangingDyamicFontOnTopSites() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let thumbnail = collection.visibleCells().first as! ThumbnailCell

        let size = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = extractTextSizeFromThumbnail(thumbnail)

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }

    func testRemovingSite() {
        // Switch to the Bookmarks panel so we can later reload Top Sites.
        tester().tapViewWithAccessibilityLabel("Bookmarks")

        // Load a set of dummy domains.
        for i in 1...10 {
            BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://test\(i).com")!)
        }

        // Switch back to the Top Sites panel.
        tester().tapViewWithAccessibilityLabel("Top sites")

        // Remove the first site and verify that all other sites shift to replace it.
        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView

        // Get the first cell (test10.com).
        let cell = collection.visibleCells().first!

        // Each thumbnail will have a remove button with the "Remove site" accessibility label, so
        // we can't uniquely identify which remove button we want. Instead, just verify that "Remove site"
        // labels are visible, and click the thumbnail at the top left (where the remove button is).
        let cellToDeleteLabel = cell.accessibilityLabel
        cell.longPressAtPoint(CGPointZero, duration: 1)
        tester().waitForViewWithAccessibilityLabel("Remove page")
        cell.tapAtPoint(CGPointZero)

        // Close editing mode.
        tester().tapViewWithAccessibilityLabel("Done")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Remove page")

        let postDeletedLabels = accessibilityLabelsForAllTopSites(collection)
        XCTAssertFalse(postDeletedLabels.contains(cellToDeleteLabel!))

        // Remove our dummy sites.
        // TODO: This is painfully slow...let's find a better way to reset (bug 1191476).
        BrowserUtils.clearHistoryItems(tester())
    }

    func testRemovingSuggestedSites() {
        // Delete the first three suggested tiles from top sites
        tester().waitForTimeInterval(5)
        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let firstCell = collection.visibleCells().first!
        let cellToDeleteLabel = firstCell.accessibilityLabel
        firstCell.longPressAtPoint(CGPointZero, duration: 3)
        tester().tapViewWithAccessibilityLabel("Remove page")
        tester().waitForAnimationsToFinish()

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Verify that the tile we removed is removed
        XCTAssertFalse(accessibilityLabelsForAllTopSites(collection).contains(cellToDeleteLabel!))
    }

    func testEmptyState() {
        // Delete all of the suggested tiles
        var collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        repeat {
            let firstCell = collection.visibleCells().first!
            firstCell.longPressAtPoint(CGPointZero, duration: 3)
            tester().tapViewWithAccessibilityLabel("Remove page")
            tester().waitForAnimationsToFinish()
        } while collection.visibleCells().count > 0

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Check for empty state
        XCTAssertTrue(tester().viewExistsWithLabel("Welcome to Top Sites"))

        // Add a new history item

        // Verify that empty state no longer appears
        BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://mozilla.org")!)

        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().tapViewWithAccessibilityLabel("Top sites")

        collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        XCTAssertEqual(collection.visibleCells().count, 1)
        XCTAssertFalse(tester().viewExistsWithLabel("Welcome to Top Sites"))

        BrowserUtils.clearHistoryItems(tester())
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.resetToAboutHome(tester())
    }
}
