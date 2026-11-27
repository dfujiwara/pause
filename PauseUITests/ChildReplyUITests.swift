import XCTest

@MainActor
final class ChildReplyUITests: XCTestCase {
    func testLaunchShowsCheckInAndKeepsQuickResetAvailable() throws {
        let app = try launch(scenario: "reply")
        XCTAssertTrue(app.staticTexts["How are you feeling?"].exists)
        XCTAssertTrue(app.buttons["Ask aloud"].exists)
        XCTAssertFalse(app.staticTexts["Listening…"].exists)
        XCTAssertFalse(app.buttons["Done"].exists)

        app.buttons["Quick reset"].tap()
        XCTAssertTrue(app.staticTexts["Let one breath out before you answer."].exists)
        XCTAssertTrue(app.buttons["I’ve asked three times"].exists)
        let resetBar = app.navigationBars["Quick reset"]
        resetBar.buttons["Check-in"].tap()
        XCTAssertTrue(resetBar.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Ask aloud"].isHittable)
    }

    func testSwipeBackFromQuickResetOpensFreshNextTime() throws {
        let app = try launch(scenario: "reply")
        let quickReset = app.buttons["Quick reset"]
        let opening = app.staticTexts["Let one breath out before you answer."]
        let situation = app.buttons["We’re running late"]
        quickReset.tap()
        situation.tap()
        XCTAssertFalse(opening.exists)

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(quickReset.wait(for: \.isHittable, toEqual: true, timeout: 5))
        quickReset.tap()
        XCTAssertTrue(opening.exists)
        XCTAssertFalse(situation.isSelected)
    }

    func testBackFromListeningDiscardsTheExchange() throws {
        let app = try launch(scenario: "reply")
        let done = startListening(in: app)
        app.navigationBars.buttons["Check-in"].tap()

        XCTAssertTrue(app.buttons["Ask aloud"].exists)
        XCTAssertFalse(done.exists)
        XCTAssertFalse(app.staticTexts["Finding replies…"].exists)
        XCTAssertFalse(app.staticTexts["You can say"].exists)
        XCTAssertTrue(startListening(in: app).exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Ask aloud"].exists)
        XCTAssertFalse(done.exists)
    }

    func testDoneShowsThreeReplyOptionsUntilBackToCheckIn() throws {
        let app = try launch(scenario: "reply")
        let done = startListening(in: app)
        let reflection = app.staticTexts["“I heard you say ‘I wanted another turn.’”"]
        let support = app.staticTexts["“I’m here with you.”"]
        let invitation = app.staticTexts["“Do you want to tell me more?”"]
        XCTAssertFalse(reflection.exists)
        XCTAssertFalse(app.staticTexts["General suggestion"].exists)
        done.tap()

        XCTAssertTrue(reflection.waitForExistence(timeout: 5))
        XCTAssertTrue(support.exists)
        XCTAssertTrue(invitation.exists)
        XCTAssertFalse(app.staticTexts["Listening…"].exists)
        XCTAssertFalse(done.exists)
        app.navigationBars.buttons["Check-in"].tap()
        XCTAssertTrue(app.buttons["Ask aloud"].exists)
        XCTAssertFalse(reflection.exists)
        XCTAssertFalse(support.exists)
        XCTAssertFalse(invitation.exists)
    }

    func testUngroundedAdviceShowsLabeledGeneralSuggestion() throws {
        let app = try launch(scenario: "unsuitable")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["“I’m here. You can tell me when you’re ready.”"].exists)
        XCTAssertFalse(app.staticTexts["“You should share next time.”"].exists)
    }

    func testReplyCannotDropTheChildsQualifier() throws {
        let app = try launch(scenario: "qualifier")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
    }

    func testReplyCannotQuoteAnEarlierRetractedStatement() throws {
        let app = try launch(scenario: "retracted")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
    }

    func testDoneWithoutAnAnswerShowsGeneralSuggestion() throws {
        let app = try launch(scenario: "silence")
        startListening(in: app).tap()

        XCTAssertTrue(app.staticTexts["General suggestion"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["You can say"].exists)
    }

    func testLeavingDuringGenerationDiscardsALateReply() throws {
        let app = try launch(scenario: "lateReply")
        startListening(in: app).tap()
        XCTAssertTrue(app.staticTexts["Finding replies…"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()

        let ask = app.buttons["Ask aloud"]
        XCTAssertTrue(ask.waitForExistence(timeout: 5))
        // Wait longer than the simulated model, which returns even after cancellation.
        XCTAssertFalse(app.navigationBars.buttons["Check-in"].waitForExistence(timeout: 9))
        XCTAssertTrue(ask.exists)
    }

    private func startListening(in app: XCUIApplication) -> XCUIElement {
        app.buttons["Ask aloud"].tap()
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
