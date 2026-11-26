import XCTest

@MainActor
final class ChildReplyUITests: XCTestCase {
    func testDoneShowsOneReplyUntilBackToReset() throws {
        let app = try launch(scenario: "reply")
        let done = startListening(in: app)
        let reply = app.staticTexts["“You wanted another turn.”"]
        XCTAssertFalse(reply.exists)
        XCTAssertFalse(app.staticTexts["General suggestion"].exists)
        done.tap()

        XCTAssertTrue(reply.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Listening…"].exists)
        XCTAssertFalse(done.exists)
        app.buttons["Back to reset"].tap()
        XCTAssertTrue(app.buttons["Ask how they’re feeling"].exists)
        XCTAssertFalse(reply.exists)
    }

    func testUnsuitableReplyShowsLabeledGeneralSuggestion() throws {
        let app = try launch(scenario: "unsuitable")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["“I’m here. You can tell me when you’re ready.”"].exists)
        XCTAssertFalse(app.staticTexts["“Tell me more?”"].exists)
    }

    func testDoneWithoutAnAnswerShowsGeneralSuggestion() throws {
        let app = try launch(scenario: "silence")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["You can say"].exists)
    }

    func testLeavingDuringGenerationDiscardsALateReply() throws {
        let app = try launch(scenario: "slow")
        startListening(in: app).tap()
        XCTAssertTrue(app.staticTexts["Finding a reply…"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()

        let ask = app.buttons["Ask how they’re feeling"]
        XCTAssertTrue(ask.waitForExistence(timeout: 5))
        // Wait longer than the simulated model, which returns even after cancellation.
        XCTAssertFalse(app.buttons["Back to reset"].waitForExistence(timeout: 9))
        XCTAssertTrue(ask.exists)
    }

    private func startListening(in app: XCUIApplication) -> XCUIElement {
        app.buttons["Ask how they’re feeling"].tap()
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        return done
    }

    private func launch(scenario: String) throws -> XCUIApplication {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Child reply UI fixtures are simulator-only.")
        #else
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["PAUSE_UI_TEST_REPLY"] = scenario
        app.launchArguments = ["-speakOpeningCue", "NO"]
        app.launch()
        return app
        #endif
    }
}
