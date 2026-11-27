import XCTest

@MainActor
final class SpeechSetupUITests: XCTestCase {
    func testExplicitDownloadShowsProgressThenReadyWithoutResumingExchange() throws {
        let app = try launch(scenario: "download")
        let ask = app.buttons["Ask aloud"]
        let download = app.buttons["Download speech model"]
        let back = app.navigationBars.buttons["Check-in"]

        XCTAssertTrue(ask.exists)
        XCTAssertFalse(download.exists)
        ask.tap()
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["General suggestion"].exists)
        XCTAssertTrue(download.isEnabled)
        download.tap()

        assertDownloadInProgress(in: app)
        XCTAssertFalse(download.exists)
        XCTAssertTrue(back.isHittable)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["General suggestion"].exists)
        XCTAssertFalse(app.staticTexts["Listening…"].exists)
        back.tap()
        XCTAssertTrue(ask.exists)
        ask.tap()
        // The fixture has installed assets but no simulated audio pipeline.
        XCTAssertTrue(app.staticTexts["Pause couldn’t complete the spoken exchange. You can go back to check-in and try again."].waitForExistence(timeout: 5))
        XCTAssertFalse(download.exists)
    }

    func testFailedDownloadCanBeRetriedFromGeneralSuggestion() throws {
        let app = try launch(scenario: "retry")
        app.buttons["Ask aloud"].tap()
        let download = app.buttons["Download speech model"]
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        download.tap()

        let retry = app.buttons["Retry download"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Couldn’t download the speech model. Check your connection and try again."].exists)
        XCTAssertTrue(app.navigationBars.buttons["Check-in"].isHittable)
        retry.tap()

        assertDownloadInProgress(in: app)
        XCTAssertFalse(retry.exists)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
    }

    func testBackToCheckInDuringDownloadStaysOnCheckIn() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        app.navigationBars.buttons["Check-in"].tap()
        assertStaysOnCheckIn(in: app)
    }

    func testAskingAgainDuringDownloadShowsTheExistingDownloadThroughCompletion() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        app.navigationBars.buttons["Check-in"].tap()
        app.buttons["Ask aloud"].tap()

        assertDownloadInProgress(in: app)
        XCTAssertFalse(app.buttons["Download speech model"].exists)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
    }

    func testLeavingDuringDownloadStaysOnCheckInAfterReopen() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertStaysOnCheckIn(in: app)
    }

    func testUnsupportedAssetsDoNotOfferDownload() throws {
        let app = try launch(scenario: "unsupported")
        app.buttons["Ask aloud"].tap()
        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Download speech model"].exists)
        XCTAssertTrue(app.navigationBars.buttons["Check-in"].isHittable)
    }

    private func startDownload(in app: XCUIApplication) {
        app.buttons["Ask aloud"].tap()
        let download = app.buttons["Download speech model"]
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        download.tap()
        assertDownloadInProgress(in: app)
    }

    private func assertDownloadInProgress(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let progress = app.staticTexts["Downloading US English speech-to-text model…"]
        XCTAssertTrue(progress.waitForExistence(timeout: 3), app.debugDescription, file: file, line: line)
    }

    private func assertStaysOnCheckIn(in app: XCUIApplication) {
        let ask = app.buttons["Ask aloud"]
        XCTAssertTrue(ask.exists)
        // Wait longer than the fixture's in-flight download.
        XCTAssertFalse(app.staticTexts["General suggestion"].waitForExistence(timeout: 7))
        XCTAssertTrue(ask.exists)
    }

    private func launch(scenario: String) throws -> XCUIApplication {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Speech setup UI fixtures are simulator-only.")
        #else
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["PAUSE_UI_TEST_SPEECH_ASSETS"] = scenario
        app.launchArguments = ["-speakOpeningCue", "NO"]
        app.launch()
        return app
        #endif
    }
}
