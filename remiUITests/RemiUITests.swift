import XCTest

final class RemiUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launchArguments.append("UITesting")
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
        app.terminate()
    }
}
