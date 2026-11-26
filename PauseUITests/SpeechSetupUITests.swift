import XCTest

@MainActor
final class SpeechSetupUITests: XCTestCase {
    func testExplicitDownloadShowsProgressThenReadyWithoutResumingExchange() throws {
        let app = try launch(scenario: "download")
        let ask = app.buttons["Ask how they’re feeling"]
        let download = app.buttons["Download speech model"]
        let back = app.buttons["Back to reset"]

        XCTAssertTrue(ask.exists)
        XCTAssertFalse(download.exists)
        ask.tap()
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["General suggestion"].exists)
        XCTAssertTrue(download.isEnabled)
        download.tap()

        XCTAssertTrue(app.staticTexts["Downloading US English speech-to-text model…"].exists)
        XCTAssertFalse(download.exists)
        XCTAssertTrue(back.isEnabled)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["General suggestion"].exists)
        XCTAssertFalse(app.staticTexts["Listening…"].exists)
        back.tap()
        XCTAssertTrue(ask.exists)
        ask.tap()
        // The fixture has installed assets but no simulated audio pipeline.
        XCTAssertTrue(app.staticTexts["Pause couldn’t complete the spoken exchange. You can go back to reset and try again."].waitForExistence(timeout: 5))
        XCTAssertFalse(download.exists)
    }

    func testFailedDownloadCanBeRetriedFromGeneralSuggestion() throws {
        let app = try launch(scenario: "retry")
        app.buttons["Ask how they’re feeling"].tap()
        let download = app.buttons["Download speech model"]
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        download.tap()

        let retry = app.buttons["Retry download"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Couldn’t download the speech model. Check your connection and try again."].exists)
        XCTAssertTrue(app.buttons["Back to reset"].isEnabled)
        retry.tap()

        XCTAssertFalse(retry.exists)
        XCTAssertTrue(app.staticTexts["Downloading US English speech-to-text model…"].exists)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
    }

    func testBackToResetDuringDownloadStaysOnReset() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        app.buttons["Back to reset"].tap()
        assertStaysOnReset(in: app)
    }

    func testAskingAgainDuringDownloadShowsTheExistingDownloadThroughCompletion() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        app.buttons["Back to reset"].tap()
        app.buttons["Ask how they’re feeling"].tap()

        XCTAssertTrue(app.staticTexts["Downloading US English speech-to-text model…"].exists)
        XCTAssertFalse(app.buttons["Download speech model"].exists)
        XCTAssertTrue(app.staticTexts["Speech model ready."].waitForExistence(timeout: 10))
    }

    func testLeavingDuringDownloadStaysOnResetAfterReopen() throws {
        let app = try launch(scenario: "download")
        startDownload(in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertStaysOnReset(in: app)
    }

    func testUnsupportedAssetsDoNotOfferDownload() throws {
        let app = try launch(scenario: "unsupported")
        app.buttons["Ask how they’re feeling"].tap()
        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Download speech model"].exists)
        XCTAssertTrue(app.buttons["Back to reset"].isEnabled)
    }

    private func startDownload(in app: XCUIApplication) {
        app.buttons["Ask how they’re feeling"].tap()
        let download = app.buttons["Download speech model"]
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        download.tap()
        XCTAssertTrue(app.staticTexts["Downloading US English speech-to-text model…"].exists)
    }

    private func assertStaysOnReset(in app: XCUIApplication) {
        let ask = app.buttons["Ask how they’re feeling"]
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
